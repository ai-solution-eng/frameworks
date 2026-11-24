# PCAI Porting Notes — seaweedfs

## Summary

| | |
|---|---|
| Chart | `seaweedfs` v`0.1.7` (appVersion `4.55`, running image `4.55`) |
| Source | **Scaffolded from scratch.** Not ported from the upstream chart — see *Why scaffolded* below |
| Packaged | `seaweedfs-0.1.7.tar.gz` — built from this tree; supersedes 0.1.6 (see § 6) |
| Date | `2026-11-24` |
| Docs | [../README.md](../README.md), [../documentation/ARCHITECTURE.md](../documentation/ARCHITECTURE.md), [../documentation/CONFIGURATION.md](../documentation/CONFIGURATION.md) |

### Why scaffolded rather than ported

The upstream chart (`https://seaweedfs.github.io/seaweedfs/helm`, currently chart 4.55.0) could not be
fetched: this environment has no outbound egress and no vendored `.tgz` or Helm repo cache. Rather than
guess at a subchart we could not inspect, the chart was scaffolded using **flags and conventions verified
against the upstream chart's own templates** (`templates/{master,volume,filer,s3}/*-{statefulset,deployment}.yaml`
on the `master` branch) so that it stays recognisable to anyone who later moves to the upstream chart.

Version choice: **4.23** was selected because it is the version the in-house PCAI Langfuse port already
runs (`pcai-solutions/frameworks/langfuse`, chart `4.23.0`), so it is proven on this platform. Every flag
below was verified against `chrislusf/seaweedfs:4.23`.

The running image was later moved to **4.55** (`values.yaml` `image.tag`) and the argv was re-verified
unchanged on it — the S3 gateway still accepts only `-port`, `-filer`, `-config`. Chart 0.1.7 moved
`Chart.yaml` `appVersion` to `4.55` as well, so the label, the fallback for an empty `image.tag`, and
the image all agree. Treat a future tag bump as "re-verify the argv", not "change the number".

## Changes made

### 1. `values.yaml` — `ezua` block

| Key | Value | Why |
|---|---|---|
| `ezua.domainName` | `${DOMAIN_NAME}` | Substituted by PCAI at deploy time; kept verbatim |
| `ezua.virtualService.endpoint` | `seaweedfs.${DOMAIN_NAME}` | Public URL for the **filer UI** |
| `ezua.virtualService.istioGateway` | `istio-system/ezaf-gateway` | Platform gateway (fixed value) |
| `ezua.s3VirtualService.enabled` | `true` | Required: data must be uploadable from outside the cluster |
| `ezua.s3VirtualService.endpoint` | `seaweedfs-s3.${DOMAIN_NAME}` | Public URL for the **S3 API** |
| `ezua.s3VirtualService.istioGateway` | `istio-system/ezaf-gateway` | Platform gateway (fixed value) |
| `ezua.s3VirtualService.timeout` | `""` (omitted) | No route timeout, so large/multipart uploads are not cut off. **Must not be `0s`** — see note below |
| `ezua.s3VirtualService.allowList.enabled` | `false` | Opt-in source-IP restriction (see §3) |
| `ezua.authorizationPolicy.namespace` | `istio-system` | Fixed value |
| `ezua.authorizationPolicy.providerName` | `oauth2-proxy` | Fixed value |
| `ezua.authorizationPolicy.enabled` | `true` | Requested by the user |

### 2. `templates/virtualservice.yaml` and `templates/virtualservice-s3.yaml` — new files

**Two VirtualServices, deliberately separate:**

| | Filer UI | S3 API |
|---|---|---|
| Template | `virtualservice.yaml` | `virtualservice-s3.yaml` |
| Host | `.Values.ezua.virtualService.endpoint` | `.Values.ezua.s3VirtualService.endpoint` |
| Destination | `<fullname>-filer.<ns>.svc.cluster.local` | `<fullname>-s3.<ns>.svc.cluster.local` |
| Port | `8888` — from `filer.port`, the port the `-filer-client` Service listens on | `8333` — from `s3.port`, the port `weed s3` binds |
| Behind oauth2? | **Yes** | **No** |

**Why the S3 route is not behind oauth2-proxy.** This is the most important design decision in the port.
S3 clients (boto3, aws-cli, rclone, mc) authenticate with SigV4 signatures. They cannot follow an OIDC
login redirect, so putting the `oauth2-proxy` `CUSTOM` AuthorizationPolicy in front of the S3 host would
make it unusable by every real S3 client. Auth on the public S3 route is therefore the S3 identity config
only. The AuthorizationPolicy's `rules[].to[].operation.hosts` lists the **UI host alone**, so it does not
intercept the S3 host even though both share the gateway.

Also set on the S3 route: `retries.attempts: 0`. Envoy retrying an S3 write can duplicate an upload or
corrupt a multipart completion, so retries are disabled rather than left at the gateway default.

**`timeout` must be omitted, not zeroed.** The first revision of this chart set `timeout: "0s"` to disable
the route timeout. That is invalid: Istio validates `HTTPRoute.timeout` as a duration **greater than 1ms**,
and admission rejects it with `spec.http[0].timeout: Invalid value: "string": must be a valid duration
greater than 1ms`, which fails the whole Helm release. An **omitted** timeout is already documented as
"disabled" in the Istio API, which is the desired behaviour. The template now renders `timeout` only when a
non-empty value is supplied, so a real cap (e.g. `3600s`) is still possible.

### 3. AuthorizationPolicy

**Included (user opted in)** — `templates/authorizationPolicy.yaml`, gated on
`ezua.authorizationPolicy.enabled`, `action: CUSTOM` with provider `oauth2-proxy`, host = the filer UI.

A **second, optional** policy is provided: `templates/authorizationPolicy-s3-allowlist.yaml`, gated on
`ezua.s3VirtualService.allowList.enabled` (default `false`). It restricts the public S3 host to a set of
source CIDRs. It is implemented as **DENY** with `notRemoteIpBlocks`, not as an ALLOW policy, on purpose:
introducing an ALLOW policy on the shared `ingressgateway` workload would change authorisation semantics
for every other host on the gateway, including the SSO-protected filer UI. A DENY scoped by host affects
only that host.

### 4. `hpe-ezua` labels

- `hpe-ezua/type: vendor-service`
- `hpe-ezua/app: seaweedfs`
- Applied **natively** via the `seaweedfs.labels` helper in `templates/_helpers.tpl`, which is included on
  every resource's `metadata.labels` **and** on every pod template's labels. No Kyverno policy was needed
  because this chart was scaffolded and its templates are fully under our control — unlike a ported
  third-party chart, where restructuring templates is undesirable.
- The labels are intentionally **not** in `selectorLabels`: selectors are immutable on StatefulSets, so
  keeping them minimal avoids a stuck upgrade if chart naming ever changes.

### 5. Other changes

- **Scaffolded components**: `master`, `volume` and `filer` as StatefulSets with `volumeClaimTemplates`
  (one PVC per replica, `ReadWriteOnce`); `s3` as a stateless Deployment; headless Services for the three
  StatefulSets plus a `-filer-client` ClusterIP Service (name mirrors upstream) and a `-s3` ClusterIP.
- **Storage class** defaults to `gl4f-filesystem`, the PCAI default (VAST-backed, RWO). Overridable via
  `storageClass`.
- **Image registry override** (`image.registry`) exists so the image can be mirrored to the internal
  registry for air-gapped PCAI installs (e.g. `172.28.1.64/ezmeral-common`).
- **S3 identity Secret** (`templates/s3-secret.yaml`) uses the upstream key name `seaweedfs_s3_config`
  mounted at `/etc/sw/seaweedfs_s3_config`, and the upstream JSON schema
  (`identities[]` → `{name, credentials[]{accessKey,secretKey}, actions[]}`).
- **CLI flags were taken from the upstream templates, not memory.** Notably `weed volume` uses
  `-master=` (not `-mserver=`), and `-dir` / `-max` are passed as separate argv items rather than `=`-joined.
- **The `s3` subcommand takes a much smaller flag set than the others.** Verified against
  `kubectl run --image=chrislusf/seaweedfs:4.23 -- s3 -h`:
  `Example: weed s3 [-port=8333] [-filer=<ip:port>[,<ip:port>]...] [-config=</path/to/config.json>]`.
  The chart therefore passes only `-port`, `-filer`, `-config` to the gateway. Do **not** assume the
  master/volume/filer flags apply here — `-ip.bind` and `-metricsPort` are used by the other three
  components but are not part of the documented s3 invocation, and carrying them over is how the
  gateway failed to start in the first attempt.
- **No `command:` override is needed.** The image ENTRYPOINT is `weed` and appends the chart's `args`,
  so `args: [s3, ...]` correctly becomes `weed s3 ...`. This was confirmed empirically: passing
  `/usr/bin/weed s3 -h` as the container args produced `weed: unknown subcommand "/usr/bin/weed"`.
- **Logging flags do not exist in this build.** `-logtostderr` / `-v` are glog flags; SeaweedFS 4.23
  rejects them with `flag provided but not defined: -logtostderr` and exits 2. Adding them crash-looped
  every component. SeaweedFS logs to stdout normally (see the filer), so no flag is required to get logs.
- **Filer metadata store**: the upstream chart enables the embedded LevelDB store via env
  `WEED_LEVELDB2_ENABLED=true` with the PVC mounted at `/data`; that is mirrored exactly. There is no
  `-defaultStoreDir` flag — it does not exist on `weed filer`.
- **Probes**: `tcpSocket` on the HTTP port for every component. Deliberately conservative — SeaweedFS HTTP
  health endpoints vary by component and version, and a wrong path would make pods restart-loop.
- **Master HA**: `master.replicas` defaults to `1`. Setting `>1` automatically renders a `-peers` list built
  from the headless Service DNS names. 3 masters are required for a real quorum; 1 master is a single
  point of failure. This is called out rather than defaulted to 3 because a misconfigured peer set fails
  to elect and looks like a hang.

### 6. After 0.1.0 — what changed in 0.1.5/0.1.6 and the working tree

| Change | Why |
|---|---|
| **`filer-client` publishes gRPC 18888** (0.1.6) | `weed s3` runs `-iam=true` and dials the filer at `<filer port>+10000`. With only 8888 published the gateway blocked in IAM init before binding 8333: Running pod, zero logs, exit 0 on SIGTERM. This was the hardest bug in the port |
| Image tag 4.23 → **4.55** (tree) | newer build, argv re-verified unchanged |
| `defaultReplication` guidance 010 → **001** (tree) | `010` needs a second *rack* and `100` a second *data center*; neither places on a single-rack PCAI cluster, and an unplaceable placement makes **writes fail**. `001` is one extra copy on a different volume server in the same rack |
| `helm/.helmignore` added (tree) | `helm package` was shipping `local/values.g2.yaml` — including the real S3 secret key — inside every tarball |
| Pod security, metrics, PDBs, network policy, backup (tree) | the four gaps that needed template work rather than a value: a `restricted` namespace rejects root pods, a default-deny namespace blocks the components from each other, the metrics listeners were bound but unpublished, and there was no backup path at all |
| S3 gateway HPA + hosted-trial profiles (tree) | the gateway is the only stateless component, so it is the only one an HPA can scale; the ingest/locked pair makes closing external access a one-line values change instead of a rewrite |
| `s3.existingConfigSecret` wired to the mounted Secret name (tree) | the `seaweedfs.s3SecretName` helper read `s3.existingSecret`, which no template sets, so a bring-your-own identity Secret was never mounted under the name the operator chose |
| `README.md` + `documentation/` set (tree) | the package had a porting record but no front door and no operational reference |

## Verification

- `helm lint helm --set ezua.virtualService.endpoint=seaweedfs.example.com --set ezua.s3VirtualService.endpoint=seaweedfs-s3.example.com` → **pass**, 0 failed (Helm 4.3.0 locally; the templates are kept Helm-3 compatible because PCAI ships an older Helm).
  Also passes with `master.replicas=3`, `volume.replicas=3` and the S3 allowlist enabled.
- `helm template` → renders **13 resources**:
  `Secret/sw-seaweedfs-s3-config`;
  `Service/{sw-seaweedfs-master, sw-seaweedfs-volume, sw-seaweedfs-filer, sw-seaweedfs-filer-client, sw-seaweedfs-s3}`;
  `StatefulSet/{sw-seaweedfs-master, sw-seaweedfs-volume, sw-seaweedfs-filer}`;
  `Deployment/sw-seaweedfs-s3`;
  `AuthorizationPolicy/sw-auth-policy`;
  `VirtualService/{sw-seaweedfs-filer, sw-seaweedfs-s3}`.
- **Verified live on SE G2 (2026-11-24):** all four workloads Ready, 5/5 PVCs Bound, S3 end-to-end smoke test
  green (bucket create, put/get, list, 12 MiB multipart, presigned URL, cleanup), UI host `302` → Keycloak,
  S3 host `403 AccessDenied` unsigned. Record: [../documentation/VERIFICATION.md](../documentation/VERIFICATION.md).
- Verified in rendered output: UI VirtualService → `-filer-client:8888` with host `seaweedfs.example.com`;
  S3 VirtualService → `-s3:8333` with `attempts: 0` and **no `timeout` key**; the AuthorizationPolicy hosts list
  contains the UI host **only**; `-peers` renders three correct master addresses at `replicas=3`; the
  `hpe-ezua` labels appear 17 times across resources and pod templates; the optional DENY policy renders
  its CIDRs correctly.

## Deploying on PCAI

1. Open the PCAI **AI Essentials** homepage → **Tools & Frameworks** → **Import Framework**.
2. Upload `seaweedfs-0.1.7.tar.gz` (mode 775) and follow the prompts. Repackage first if the tree has moved:
   `helm package helm --destination . && mv seaweedfs-0.1.7.tgz seaweedfs-0.1.7.tar.gz && chmod 775 seaweedfs-0.1.7.tar.gz`.
3. Values likely to need attention before install:
   - `s3.auth.secretKey` — **set this explicitly.** If left empty a random key is generated, and it is
     **regenerated on every `helm upgrade`**, which breaks every existing client.
   - `image.registry` — point at the internal mirror for an air-gapped cluster.
   - `volume.replicas` / `volume.persistence.size` — capacity planning.
   - `master.defaultReplication` — `000` is no replication; use `010` with 3+ volume servers for one copy.
   - `ezua.s3VirtualService.allowList.*` — strongly recommended if the gateway is internet-facing.
4. Resulting URLs:
   - Filer UI (SSO): `https://seaweedfs.${DOMAIN_NAME}`
   - S3 API (SigV4): `https://seaweedfs-s3.${DOMAIN_NAME}`

### First-deploy checks

- **Filer LevelDB on the PVC.** Confirm the metadata store actually landed on the PVC, not the container
  filesystem: `kubectl exec -n <ns> <fullname>-filer-0 -- ls -la /data`. If the store is not under `/data`,
  pin it with a `filer.toml` (`[leveldb2] enabled = true`, `dir = /data/filerldb2`) before putting any data in.
- **Path-style addressing is mandatory.** The S3 endpoint is a single host with no wildcard DNS or
  wildcard certificate, so virtual-hosted-style (`bucket.host`) addressing will not work. Clients must set
  path style: boto3 `Config(s3={'addressing_style': 'path'})`, aws-cli `--endpoint-url` (path style is the
  default for custom endpoints), Spark `fs.s3a.path.style.access: true`, rclone `force_path_style = true`.
  This is also why `s3.domainName` is left empty.
- **Upload size.** The route timeout is disabled, but confirm your ingress/load balancer in front of the
  ezua gateway does not impose its own body-size or idle-timeout limit before promising large uploads.

### Optional: also expose it to in-cluster apps via the PCAI s3-proxy

Registering this endpoint as a PCAI object store data source (Data Engineering → Data Sources → Object
Store Data, **MinIO** tile, endpoint `http://<fullname>-s3.<ns>.svc.cluster.local:8333`, access/secret key
from the `s3-config` Secret) gives in-cluster consumers the platform JWT + OPA model and the same boto3
pattern as external S3. **Caveat:** SeaweedFS is not a documented data-source backend — the MinIO tile is
the closest fit and this path should be validated on a test install before being relied on.

## Security notes for the public S3 route

- The S3 host is reachable from outside the cluster and is **not** protected by PCAI SSO. Its only
  authentication is the SigV4 access key in the `s3-config` Secret. Treat that key as internet-facing
  credentials: long random secret, rotated, and never the chart default.
- Set `ezua.s3VirtualService.allowList.enabled=true` with the customer's egress CIDRs wherever the source
  range is known.
- Note this diverges from the usual PCAI posture where every published endpoint sits behind `oauth2-proxy`.
  That divergence is intentional and unavoidable for S3, but it should be a conscious, reviewed decision
  for any environment holding sensitive data.
