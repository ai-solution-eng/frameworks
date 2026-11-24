# SeaweedFS on HPE Private Cloud AI

A **distributed object store with an S3-compatible gateway, a hierarchical file namespace and a browser UI, packaged as one Helm chart for HPE Private Cloud AI** — `seaweedfs` 0.1.7 running SeaweedFS 4.55: one master, **three volume servers with `001` replication (two copies of every volume)**, one filer and a stateless S3 gateway.

<div align="center"><img src="./seaweed.png" width="200" alt="SeaweedFS"></div>

| Endpoint | What it serves | Auth |
|---|---|---|
| `https://seaweedfs.<domain>` | Filer web UI (browse, upload, download) | PCAI SSO via oauth2-proxy |
| `https://seaweedfs-s3.<domain>` | S3 API for clients outside the cluster | SigV4 access key only — **no SSO, by design** |
| `http://seaweedfs-s3.<ns>.svc.cluster.local:8333` | S3 API for in-cluster apps | SigV4 |
| `http://seaweedfs-filer-client.<ns>.svc.cluster.local:8888` | Filer HTTP API | none (cluster-internal) |

## What it is

SeaweedFS splits object storage into four cooperating processes. The **master** keeps the volume registry — which volume exists, which volume server holds it, and what its replication placement is. The **volume servers** hold the bytes: a file becomes one or more *needles* appended to a *volume*, and a volume is an append-only file that grows to `volumeSizeLimitMB` before the next one is allocated. The **filer** layers a hierarchical namespace (`/buckets/...`) on top, storing path → file-id mappings in a metadata store — here an embedded LevelDB database on the filer's own PVC. The **S3 gateway** (`weed s3`) is a stateless translator from the S3 API to the filer's gRPC/HTTP API: it holds no data and can be scaled or restarted at will.

What this package adds on top of upstream SeaweedFS is the PCAI contract: a scaffolded Helm chart, two VirtualServices with **two different auth models**, the `hpe-ezua` vendor labels the platform catalog discovers services by, an S3 identity Secret in the upstream schema, and a values surface sized for a lab that can be moved to a replicated topology without re-importing the chart.

## The problem it solves

- **You need object storage inside your own namespace, on your own storage class.** The platform's object-store data source is a shared, platform-owned service. This chart gives you an S3 endpoint per namespace, backed by the same VAST `gl4f-filesystem` class everything else on the cluster uses, with no extra subscription and no shared bucket. *Why it matters:* per-team isolation and per-team capacity are the two things a shared platform store cannot give you.
- **Machines and humans need the same data through different doors.** boto3, Spark, rclone and backup jobs want S3; a person who wants to look at a directory tree wants a file browser. Both read the same filer namespace, so there is no export/sync job and no second copy of the truth. *Why it matters:* the alternative — an S3 store plus an rsync'd mirror for humans — doubles storage and drifts.
- **The volume servers shard the data; replication is what copies it.** `volume.replicas: 3` is three storage servers with their own PVCs that *together* hold the data — not three copies of it. The second copy comes from `master.defaultReplication: 001`, which places each volume on a different server in the same rack, so any one volume server can be lost and the data is still readable. *Why it matters:* the two knobs are independent, and only the second one is durability — a 3-server deployment at `000` has 750Gi of space and still loses a third of the data to one pod restart. See [ARCHITECTURE.md § 3](documentation/ARCHITECTURE.md#3-where-the-bytes-live).
- **PCAI publishes everything behind oauth2-proxy, and S3 clients cannot follow an OIDC redirect.** The chart therefore publishes two hosts with two auth models: SSO on the UI, SigV4 on the API, with an opt-in source-IP DENY policy for the public one. *Why it matters:* the obvious port — one host behind SSO — produces an endpoint that boto3, aws-cli, rclone and Spark cannot use at all.
- **The bytes have to land on a PersistentVolume, not in a container.** Every replica gets its own RWO PVC from the platform storage class. *Why it matters:* `emptyDir`-backed object storage silently loses everything on a reschedule, which is exactly when you are looking at it.
- **"The pods are Running" is not "the object store works".** A committed boto3 script exercises bucket create, put/get with byte verification, listing, a 12 MiB multipart upload, presigned URLs and cleanup. *Why it matters:* the hardest failure in this port produced zero logs and a healthy-looking pod — see [Known failures](#known-failures-worth-remembering).

## How it fits in PCAI

| Layer | Component | This package's part |
|---|---|---|
| Ingress | Istio `ezaf-gateway` + oauth2-proxy | Renders **two** VirtualServices (filer UI, S3 API) and a `CUSTOM` AuthorizationPolicy that covers the **UI host only** |
| Catalog | PCAI catalog + `hpe-ezua` vendor labels | Applied **natively** in `helm/templates/_helpers.tpl`, so the chart needs no Kyverno ClusterPolicy and no post-install patching |
| Storage | VAST `gl4f-filesystem` (ReadWriteOnce) | Owns five PVCs: master 5Gi, filer 10Gi, and one 100Gi claim per volume server |
| Identity | Keycloak `UA` realm | A **client** of it, for the filer UI only. The S3 host uses static SigV4 keys from the `s3-config` Secret |
| Object store consumers | Apps, Spark, backup jobs, PCAI Data Sources | Provides the S3 endpoint; optionally registered as a PCAI *Object Store Data* source so in-cluster apps get JWT + OPA auth through the platform proxy |

**Depends on:** a ReadWriteOnce storage class (default `gl4f-filesystem`), `istio-system/ezaf-gateway`, and an oauth2-proxy provider in `istio-system` for the UI host. **Depended on by:** anything in the namespace that needs an S3 endpoint — the intended consumers are applications that treat S3 as a primitive (Spark/`s3a`, `rclone`, backup tooling) and the PCAI object-store proxy.

## Architecture in one screen

```
  browser    --PCAI SSO-->  https://seaweedfs.<domain>     --VS -filer--> filer-client:8888
  S3 client  --SigV4----->  https://seaweedfs-s3.<domain>  --VS -s3-----> s3:8333
                                                                              |
                                                                              v
  1. filer  :8888 / :18888   path -> fileId, in LevelDB on the filer PVC
  2. master :9333            which volume server holds that fileId
  3. volume :8080            append the needle to /data on the volume PVC
```

| Workload | Kind | Replicas | Ports | PVC | Holds |
|---|---|---|---|---|---|
| `seaweedfs-master` | StatefulSet | 1 | 9333 / 19333 | `data-seaweedfs-master-0` (5Gi) | Volume registry and raft metadata |
| `seaweedfs-volume` | StatefulSet | **3** | 8080 / 18080 | `data-seaweedfs-volume-{0,1,2}` (100Gi each) | **The bytes** |
| `seaweedfs-filer` | StatefulSet | 1 | 8888 / 18888 | `data-seaweedfs-filer-0` (10Gi) | Namespace + LevelDB metadata |
| `seaweedfs-s3` | Deployment | 1 (chart default 2) | 8333 | none | Nothing — stateless translator |

Request path for one `put_object`:

```
client → VirtualService seaweedfs-s3 → Service :8333 → s3 pod
   s3 → filer-client :8888/:18888   (write path → fileId into LevelDB)
   s3 → master :9333                (which volume holds the fileId?)
   s3 → volume :8080                (append the needle to /data)
```

**Durability, stated plainly.** Two PVCs are load-bearing: losing the **volume** PVCs loses bytes, losing the **filer** PVC loses the namespace (the needles still exist, but nothing can address them). The master PVC is the least critical — volume servers re-register on startup. With `001` each volume also has a second copy on another volume server, which protects against a *server* failure but not against a *namespace* loss. Depth, including the replication arithmetic and the failure matrix: [documentation/ARCHITECTURE.md](documentation/ARCHITECTURE.md).

## Capabilities, by theme

Each line carries the decision, because the decision is the feature. The full reference for every knob is in [documentation/CONFIGURATION.md](documentation/CONFIGURATION.md).

### Storage and replication

- **Three volume servers, `001` placement, two copies per volume** — the digits are `x` = other data centers, `y` = other racks, `z` = other servers in the same rack, so `001` is "one extra copy on a different server in this rack" and it is the strongest placement a single-rack cluster can satisfy. *Why:* `010` needs a second rack and `100` a second data center; both fail to place on a one-rack PCAI cluster and then **writes fail**. See [OPERATIONS.md § Replication](documentation/OPERATIONS.md#2-replication).
- **Existing data is not retro-replicated.** `defaultReplication` is applied when a volume is created; volumes written before the change keep their old placement until you run `volume.configure.replication` + `volume.fix.replication`. *Why:* the runbook is in [OPERATIONS.md](documentation/OPERATIONS.md#2-replication) precisely because "I set 001" and "my data has two copies" are different statements.
- **Volume sizing is a storage decision, not a performance one** — a new volume is allocated each time one reaches `volumeSizeLimitMB` (1000 MB), `maxVolumes: 0` means unlimited, and `minFreeSpacePercent: 1` stops writes before the PVC fills. *Why:* 1 GiB volumes keep `volume.fix.replication` cheap; the cost is more volumes in the master's index.
- **RWO PVC per replica, immutable claim templates** — every volume server gets its own claim from `gl4f-filesystem`. *Why:* RWO is what the platform storage class offers; the consequence (a rescheduled pod waits for the old node to detach) is documented rather than worked around.

### The S3 gateway

- **Path-style addressing only** — the endpoint is one host with no wildcard DNS or wildcard certificate, so `bucket.host` addressing cannot resolve. Every recipe in [CLIENTS.md](documentation/CLIENTS.md) sets path style. *Why:* virtual-hosted style is the default in several SDKs and fails as a DNS error, not an auth error.
- **Stateless and safe to scale** — the gateway is a Deployment with no PVC; `s3.replicas` can be raised at any time. *Why:* the gateway does no caching that matters, so there is no rebalancing step.
- **Autoscaling for the request path (opt-in)** — `s3.autoscaling` renders an `autoscaling/v2` HPA on the gateway only (default 2→8 pods, 70% CPU, immediate scale-up, 5-minute scale-down window) and removes `spec.replicas` from the Deployment so Helm cannot fight it. *Why:* the gateway is the one component that only serves requests — it verifies SigV4, terminates TLS, translates S3 to the filer and streams bytes, and stores nothing. It fires on **many concurrent requests or many small objects** (CPU per request); a few very large objects are streaming work with low CPU per byte, so expect it to stay near `minReplicas` during a bulk copy. It cannot raise the ceiling — the single-replica filer and the volume servers' disks are that ceiling — and a CPU target with no CPU request **fails the render** rather than shipping an HPA that never scales.
- **Only three flags are passed, deliberately** — `-port`, `-filer`, `-config`. `weed s3` defines a much smaller flag set than master/volume/filer; carrying over `-ip.bind` or `-metricsPort` aborts the process during flag parsing. *Why:* this is the second-hardest failure in the port — the pod CrashLoops with `flag provided but not defined`, and it looks like a chart bug rather than a CLI mismatch.
- **Forgiving probes** — readiness 15s/6 failures, liveness 120s/6 failures. *Why:* the first attempt restart-looped before the gateway ever bound 8333, destroying the evidence; a lenient liveness probe keeps a stuck gateway inspectable with `kubectl logs`.
- **No Envoy retries on the S3 route** (`retries.attempts: 0`). *Why:* a retried `PUT` or multipart `CompleteMultipartUpload` can duplicate an upload or corrupt a completion — a silent data bug that only appears under network flakiness.

### Two endpoints, two auth models

- **The filer UI is behind PCAI SSO** — a `CUSTOM` AuthorizationPolicy naming the `oauth2-proxy` provider, scoped to the UI host. Verified 2026-11-24: an unauthenticated request gets `302` to the Keycloak `UA` realm.
- **The S3 host is deliberately not behind SSO** — SigV4 clients sign the request and cannot complete an OIDC login, so oauth2-proxy on that host would make it unusable by every real client. Its authentication is the S3 identity in the `s3-config` Secret. *Why this is safe to publish:* the gateway rejects unsigned requests (verified: `403 AccessDenied`), and the opt-in allowlist narrows the source range further.
- **The source-IP allowlist is a DENY policy, not an ALLOW policy** — a `DENY` scoped by host affects only that host, whereas an `ALLOW` on the shared `ingressgateway` workload would change authorisation semantics for every other host on the gateway, including the SSO-protected UI. *Why:* the blast radius of the security control must not exceed the thing it protects.
- **The route timeout is omitted, never `0s`** — an omitted Istio `HTTPRoute.timeout` means *disabled*, which is what large and multipart uploads need; `0s` is rejected at admission (`must be a valid duration greater than 1ms`) and fails the whole release.

### Security, disruption and operations

- **Pod security is on by default** — `securityContext` runs every pod as uid/gid 1000 with `fsGroup`, `seccompProfile: RuntimeDefault`, no privilege escalation and every capability dropped. *Why this is safe to default:* the workloads bind only unprivileged ports, so nothing needs root; the single dependency is the storage driver applying `fsGroup` to the claim, and a driver that ignores it fails visibly in the first minute (`Running`, never Ready, `permission denied` on `/data`) with a one-flag rollback. The render **fails** if `runAsNonRoot` is set without a `runAsUser`, because the container would abort at start. See [OPERATIONS.md § 12](documentation/OPERATIONS.md#12-pod-security).
- **PodDisruptionBudgets on by default** — `maxUnavailable: 1` for the volume servers and the gateway, so a node drain takes one volume server at a time and cannot make `001` placement unsatisfiable. Master and filer are deliberately excluded: a PDB on a single replica blocks every drain.
- **Metrics that are finally reachable** — `metrics.enabled` publishes the existing `-metricsPort` on the master, volume and filer Services (it was bound inside the pods and reachable from nowhere), and `metrics.serviceMonitor.enabled` renders a ServiceMonitor. *Why the second one is opt-in:* it needs the Prometheus Operator CRDs, and the release would fail to install without them. The S3 gateway has no metrics listener in this build.
- **NetworkPolicy, opt-in** — a default-deny plus explicit allows for intra-release traffic, DNS, the ezua gateway and whatever namespaces/CIDRs you list. *Why opt-in:* it only helps in a namespace that already enforces default-deny, and in a permissive namespace it adds a failure mode without removing one. Calico applies policy to kubelet probes, so `nodeCIDRs` exists for that case.
- **Backup, opt-in** — a CronJob runs `rclone sync` against this deployment's own S3 API and copies every bucket to a remote you own, keeping replaced and deleted objects under `_versions/<timestamp>`. *Why logical and not a PVC snapshot:* it is the only copy that can be verified and restored with the S3 tooling already in use. See [OPERATIONS.md § 13](documentation/OPERATIONS.md#13-backup-and-restore).

### PCAI integration

- **Native `hpe-ezua` labels** — `hpe-ezua/type: vendor-service` and `hpe-ezua/app: seaweedfs` come from the chart's label helper and land on every resource and every pod template. *Why:* the chart is scaffolded, so the labels did not need a Kyverno ClusterPolicy to retrofit them onto third-party templates.
- **Air-gap ready** — `image.registry` prefixes the image reference so the release can pull from the internal mirror (e.g. `172.28.1.64/ezmeral-common`).
- **`NOTES.txt` prints working client commands** — the post-install notes contain an aws-cli and a boto3 example with the real endpoint substituted, so the first integration test does not start from a blank editor.

## Which topology

One chart, three topologies — and **the choice is a values decision, not a different package**, except for the last row, which is not built.

| | Lab / smoke test | Replicated (**deployed on G2**) | HA (not built) |
|---|---|---|---|
| Volume servers | 1 | **3** | 3+ |
| `master.defaultReplication` | `000` | **`001`** (2 copies) | `001` or `010` |
| Masters | 1 | 1 | 3 (raft quorum) |
| Filer metadata | embedded LevelDB | embedded LevelDB | external store (Postgres/Redis/etcd) |
| Survives a volume server loss | no | **yes, reads; writes need repair** | yes |
| Survives a filer PVC loss | no | no | yes |

Two of these are packaged as paste-ready files for a customer trial: [helm/values-examples/values.hosted-trial-ingest.yaml](helm/values-examples/values.hosted-trial-ingest.yaml) (3 × 250Gi, `001`, gateway HPA armed, public S3 host open) and [...-locked.yaml](helm/values-examples/values.hosted-trial-locked.yaml) — byte-identical except the one line that closes the public route. Runbook: [OPERATIONS.md § 11](documentation/OPERATIONS.md#11-ingest-window-open--ingest--lock--rotate).

The lab row is the minimum that works. The replicated row is what runs on SE G2 today and is the recommended floor for anything whose data matters. The HA row requires an external metadata store and a second/third master, which this chart does not wire up — see [ROADMAP.md](documentation/ROADMAP.md).

**Raising the replication level on a live release is two edits and one runbook:** `volume.replicas: 3` + `master.defaultReplication: 001`, then `volume.fix.replication` for the data that already exists. Do **not** change `volume.persistence.size` in the same update — `volumeClaimTemplates` are immutable and the release fails outright.

## Deploy on PCAI (one screen)

1. **Create the S3 identity Secret, then point the release at it** — the recommended path, and the one the trial profiles use:

   ```bash
   kubectl create secret generic seaweedfs-s3-config -n <ns> \
     --from-literal=seaweedfs_s3_config="$(cat s3-config.json)"   # {"identities":[...]}
   ```

   then set `s3.existingConfigSecret: seaweedfs-s3-config` and leave `s3.auth.secretKey` empty. *Why preferred:* the credential never enters a values document (so it cannot be pasted into a ticket, a chat or a packaged chart), rotation is `kubectl apply` + `kubectl rollout restart` with no Helm involvement, and the values editor cannot silently regenerate it. The inline `s3.auth.secretKey` remains as a fallback — but an empty one is generated at install and **regenerated on every upgrade**, breaking every existing client.
2. **Package the chart** — `.tar.gz` with mode 775:

   ```bash
   helm package helm --destination .
   mv seaweedfs-0.1.7.tgz seaweedfs-0.1.7.tar.gz && chmod 775 seaweedfs-0.1.7.tar.gz
   ```

3. **Import** it in PCAI: *AI Essentials → Tools & Frameworks → Import Framework*.
4. **Paste and edit the values** in the PCAI *Helm Values* editor — start from `helm/local/values.g2.yaml` (complete file, not a sparse overlay), and let the editor resolve `${DOMAIN_NAME}`.
5. **Apply**, then verify in the order in [VERIFICATION.md](documentation/VERIFICATION.md): pods Ready → `filer-client` publishes **both** 8888 and 18888 → `test_s3_boto3.py` passes → the UI host redirects to SSO.

CLI instead of the UI (first smoke test, or a cluster you can reach with `helm`):

```bash
cd helm
export DOMAIN_NAME=<cluster-domain>
export S3_SECRET_KEY=$(openssl rand -hex 32)
envsubst '${DOMAIN_NAME}' < local/values.g2.yaml > /tmp/values.rendered.yaml
helm upgrade --install seaweedfs . -n seaweedfs --create-namespace \
  -f /tmp/values.rendered.yaml --set-string s3.auth.secretKey="$S3_SECRET_KEY"
```

`envsubst` is restricted to `${DOMAIN_NAME}` on purpose — an unrestricted `envsubst` also eats every other `${...}` in the file. `--set-string` is used so the key never lands in a file.

## Prerequisites at a glance

Everything here is either a Secret you create or a cluster object that must already exist. Full procedure and failure modes: [documentation/DEPLOYMENT.md](documentation/DEPLOYMENT.md#2-deploying).

**Secrets**

| Secret | Keys | Required? | If missing |
|---|---|---|---|
| `s3.existingConfigSecret` — **you create it, recommended** | `seaweedfs_s3_config` (identity JSON) | recommended | the pod fails to start on the missing mount (fast, obvious) |
| `<fullname>-s3-config` — chart-created fallback | same key | fallback when no Secret is named | the gateway has no identity and every request is `403`; with an empty `s3.auth.secretKey` the key is regenerated on every upgrade |

**Cluster objects and platform dependencies**

| Object | Why it must exist | If missing |
|---|---|---|
| RWO storage class `gl4f-filesystem` (VAST) | the five PVCs | PVCs stay `Pending`, pods never schedule |
| Istio gateway `istio-system/ezaf-gateway` | both VirtualServices attach to it | endpoints unreachable |
| oauth2-proxy provider in `istio-system` | the UI AuthorizationPolicy names it | UI host returns 500/503 from the ext-authz filter |
| Kyverno (EzAF) | **not required** — the chart applies the `hpe-ezua` labels itself; the platform policy, where present, is a no-op for this chart | nothing, unlike a ported chart whose labels had to be retrofitted |
| DNS + TLS for both hosts | the platform certificate covers `<domain>` | certificate errors in every client |
| metrics-server | **only** when `s3.autoscaling.enabled` | the HPA reports `<unknown>` and parks at `minReplicas` |
| Prometheus Operator CRDs | **only** when `metrics.serviceMonitor.enabled` | the release fails to install (unknown kind) |
| A CNI that enforces NetworkPolicy | **only** when `networkPolicy.enabled` | the policies are created but ignored |
| Destination S3 + an `rclone.conf` Secret | **only** when `backup.enabled` | the CronJob cannot start; the render fails without the Secret names |

**External dependencies: none at runtime.** The image is self-contained, the metadata store is embedded, and nothing calls out of the cluster — the only external need is the image pull (or the internal mirror via `image.registry`).

## Verified state (2026-11-24)

Observed on the SE G2 deployment (`namespace seaweedfs`, chart 0.1.6 at the time, image 4.55). Re-run the same checks with [VERIFICATION.md](documentation/VERIFICATION.md).

| Check | Result |
|---|---|
| Workloads | master 1/1, volume **3/3** (two nodes), filer 1/1, s3 1/1 — all Ready |
| PVCs | 5/5 `Bound` on `gl4f-filesystem` (5Gi, 10Gi, 3×100Gi) |
| `filer-client` ports | 8888 **and** 18888 published |
| S3 end-to-end (`test_s3_boto3.py`) | create bucket, put/get verified, list, 12 MiB multipart, presigned URL, cleanup — **all passed** |
| UI host without a session | `302` → Keycloak `UA` realm |
| S3 host, unsigned request | `403` `<Code>AccessDenied</Code>` |
| Replication | master running `-defaultReplication=001`; per-volume placement is checked with `volume.list` ([OPERATIONS.md](documentation/OPERATIONS.md#2-replication)) |
| Chart render | `helm lint` 0 failed; `helm template` with the site values → 15 objects |

**Packaged as `seaweedfs-0.1.7.tar.gz`, built from this tree** — image 4.55, `appVersion` 4.55, and `helm/.helmignore` keeping site values out. The superseded **0.1.5/0.1.6 artifacts pin image 4.23, predate every feature added since (PDBs, HPA, securityContext, metrics ports, network policy, backup), and contain `local/values.g2.yaml` including the S3 key** — do not import them, and if one has left the machine rotate that key ([OPERATIONS.md § 5](documentation/OPERATIONS.md#5-key-rotation)).

## Known failures worth remembering

The three failures that cost the most time in this port, because none of them produced a useful error:

| Symptom | Real cause |
|---|---|
| s3 pod runs, never binds 8333, **zero logs**, exits 0 | `filer-client` did not publish gRPC **18888**; `weed s3` defaults to `-iam=true`, dials `<filer port>+10000`, blocks on IAM init before binding |
| Every component CrashLoops with `flag provided but not defined: -logtostderr` | SeaweedFS is not glog-based; those flags do not exist in this build |
| s3 CrashLoops with `flag provided but not defined: -ip.bind` | `weed s3` accepts only `-port`, `-filer`, `-config` |

Every field-tested failure mode, with causes and fixes, is in [DEPLOYMENT.md § 6 Troubleshooting](documentation/DEPLOYMENT.md#6-troubleshooting--issues-actually-hit).

## Day-2

- **Health** — pods Ready, `filer-client` 8888 + 18888, `volume.list` shows every volume with the expected `ReplicaPlacement`. The metrics listeners are bound inside the pods but published by no Service, so nothing scrapes them yet.
- **Scale** — raise `volume.replicas` to add capacity and replication targets (one new PVC per replica); raise `s3.replicas` freely. Never change `volume.persistence.size` in place.
- **Repair replication** — after losing a volume server: `volume.configure.replication` then `volume.fix.replication -apply` from `weed shell`. Runbook: [OPERATIONS.md § 2](documentation/OPERATIONS.md#2-replication).
- **Rotate the S3 key** — edit the `s3-config` Secret (or your `existingConfigSecret`) and roll the gateway; every client must be updated in the same window. [OPERATIONS.md § 5](documentation/OPERATIONS.md#5-key-rotation).
- **Backup** — there is none built in. The volume and filer PVCs are the only copy of the truth; see [ROADMAP.md](documentation/ROADMAP.md) for the intended shape and [OPERATIONS.md § 6](documentation/OPERATIONS.md#6-backup-and-restore) for what to snapshot today.
- **Uninstall** — `helm uninstall` removes the workloads but **not** the PVCs created by the StatefulSets; the data survives until you delete the claims yourself.

## Documentation map

| File | The question it answers |
|---|---|
| [documentation/ARCHITECTURE.md](documentation/ARCHITECTURE.md) | How do the four components cooperate, where do the bytes actually live, and what does each failure cost? |
| [documentation/DEPLOYMENT.md](documentation/DEPLOYMENT.md) | How do I deploy, upgrade and uninstall it on PCAI, and what does each error mean? |
| [documentation/CONFIGURATION.md](documentation/CONFIGURATION.md) | What is this knob, what is its default, and what does changing it do? Including the exact argv each component runs. |
| [documentation/OPERATIONS.md](documentation/OPERATIONS.md) | How do I run it day 2 — replication repair, scaling, key rotation, backups, node drains? |
| [documentation/CLIENTS.md](documentation/CLIENTS.md) | How do I connect boto3, aws-cli, rclone or Spark, and why does my client fail? |
| [documentation/VERIFICATION.md](documentation/VERIFICATION.md) | How do I prove a deployment works, layer by layer, and what does a failed check mean? |
| [documentation/ROADMAP.md](documentation/ROADMAP.md) | What is deliberately not built yet? |
| [documentation/CHANGELOG.md](documentation/CHANGELOG.md) | What shipped when, and which bug drove it? |
| [helm/PORTING.md](helm/PORTING.md) | Why was the chart scaffolded rather than ported, and which flags were verified how? |
| [helm/values-examples/README.md](helm/values-examples/README.md) | Which paste-ready profile do I start from — ingest window, locked down, or the lab? |
| [helm/local/README.md](helm/local/README.md) | Where do real site values live, and what must never be committed? |
| [s3_helper.py](s3_helper.py) | How do I create a bucket and move files in and out without writing boto3 boilerplate? |

## Developing locally

**This is not the deployment path.** PCAI operators import the packaged chart and edit values; these commands exist for changing the package.

```bash
helm lint helm --set ezua.virtualService.endpoint=seaweedfs.example.com \
  --set ezua.s3VirtualService.endpoint=seaweedfs-s3.example.com
helm template sw helm --set ezua.virtualService.endpoint=seaweedfs.example.com \
  --set ezua.s3VirtualService.endpoint=seaweedfs-s3.example.com   # 15 objects, no install
python3 test_s3_boto3.py        # end-to-end against a live deployment (needs S3_SECRET_KEY)
```

The chart needs no build step and no local dependencies — it is templates plus values. `helm/templates/_helpers.tpl` is kept Helm-3 compatible on purpose, because PCAI ships an older Helm than this workspace (verified with Helm 4.3.0 locally). Site values live in `helm/local/` and are never packaged; see [helm/local/README.md](helm/local/README.md).

## Known limitations

Single master and single filer; embedded LevelDB metadata; no STS temporary credentials; no per-bucket identities; the public S3 host is not SSO-protected; the S3 gateway exposes no metrics. Backup, ServiceMonitor scraping and NetworkPolicy exist but are **opt-in and off by default**; pod security context is off until validated on the target cluster. Each one is a deliberate scope decision with the work it would take, in [ROADMAP.md](documentation/ROADMAP.md).
