# SeaweedFS on HPE Private Cloud AI — Deployment Guide

Chart: `seaweedfs` v0.1.7 · Image: `chrislusf/seaweedfs:4.55` · Namespace: `seaweedfs` · Site: SE G2

Deploying, upgrading and uninstalling the release, plus the failure modes that were actually hit while bringing it up. For the *why* behind the objects, read [ARCHITECTURE.md](ARCHITECTURE.md); for day-2 procedures, [OPERATIONS.md](OPERATIONS.md); for the layer-by-layer proof that a deployment works, [VERIFICATION.md](VERIFICATION.md).

---

## 1. Architecture

Three StatefulSets own persistent storage; the S3 gateway is stateless. Three volume servers with `001` replication keep two copies of every volume, on two different servers in the same rack.

| Workload | Kind | Replicas | Ports | PVC | Holds |
|---|---|---|---|---|---|
| `seaweedfs-master` | StatefulSet | 1 | 9333 / 19333 | `data-seaweedfs-master-0` (5Gi) | Volume registry / raft metadata |
| `seaweedfs-volume` | StatefulSet | 3 | 8080 / 18080 | `data-seaweedfs-volume-{0,1,2}` (100Gi each) | **The actual bytes** (needles) |
| `seaweedfs-filer` | StatefulSet | 1 | 8888 / 18888 | `data-seaweedfs-filer-0` (10Gi) | Namespace + LevelDB metadata |
| `seaweedfs-s3` | Deployment | 1 (chart default 2) | 8333 | **none** | Nothing — stateless translator |

Request path for a single `put_object`:

```
client -> VirtualService seaweedfs-s3 -> Service :8333 -> s3 pod
   s3 -> filer-client :8888/:18888   (writes path->fileID into LevelDB)
   s3 -> master :9333                (which volume holds the fileID?)
   s3 -> volume :8080                (writes the bytes to /data)
```

**Durability.** The volume and filer PVCs are the two load-bearing claims. Losing the volume claims loses bytes (except where a replicated copy survives on another volume server); losing the filer claim loses the namespace, which makes every needle unaddressable even though the bytes are intact. The master PVC is the least critical — volume servers re-register on startup. With `001` there are two copies per volume, which protects against a volume *server* failure but not against losing the filer claim, and not against losing the namespace. The full failure matrix is in [ARCHITECTURE.md § 5](ARCHITECTURE.md#5-failure-matrix).

---

## 2. Deploying

### Prerequisites

| Requirement | Detail |
|---|---|
| RWO storage class | `gl4f-filesystem` (VAST) is the PCAI default; override with `storageClass` |
| Istio gateway | `istio-system/ezaf-gateway` — both VirtualServices attach to it |
| oauth2-proxy provider | in `istio-system`; the UI `AuthorizationPolicy` names it |
| Write access to `istio-system` | the `AuthorizationPolicy` is created **there**, not in the release namespace |
| Kyverno | **not required.** The `hpe-ezua` vendor labels are applied by the chart's label helper; a platform ClusterPolicy that patches them is a no-op here |
| DNS + certificate for both hosts | `seaweedfs.<domain>` and `seaweedfs-s3.<domain>` |

### CLI

```bash
cd helm
export DOMAIN_NAME=pcai-se-ai-application.hst.rdlabs.hpecorp.net
export S3_SECRET_KEY=$(openssl rand -hex 32)
envsubst '${DOMAIN_NAME}' < local/values.g2.yaml > /tmp/values.g2.rendered.yaml
helm upgrade --install seaweedfs . -n seaweedfs --create-namespace \
  -f /tmp/values.g2.rendered.yaml --set-string s3.auth.secretKey="$S3_SECRET_KEY"
```

`envsubst` is restricted to `${DOMAIN_NAME}` on purpose — an unrestricted `envsubst` also substitutes every other `${...}` it finds. `--set-string` is deliberate: `--set` coerces and would mangle a numeric-looking key, and it keeps the real key out of any file.

### PCAI UI

Import the packaged chart via **AI Essentials → Tools & Frameworks → Import Framework**, then paste `local/values.g2.yaml` **as-is** — the PCAI values editor resolves `${DOMAIN_NAME}` itself. Do **not** `envsubst` for the UI path; only the CLI path needs it. Replace the `s3.auth.secretKey` placeholder by hand before pasting.

On PCAI the pasted values **replace** the chart's `values.yaml` entirely rather than overlaying it, which is why the site file is a complete document. Keep it complete: a paste that drops a key silently reverts that key to the chart default.

### Packaging the artifact

```bash
helm package helm --destination .
mv seaweedfs-0.1.7.tgz seaweedfs-0.1.7.tar.gz && chmod 775 seaweedfs-0.1.7.tar.gz
```

The artifact must be `.tar.gz` with mode 775. `helm/.helmignore` excludes `local/` and `PORTING.md`, so site values — including the S3 secret key — cannot enter the tarball. Verify after packaging, before the file leaves the machine:

```bash
tar tzf seaweedfs-0.1.7.tar.gz | grep -E 'local/|PORTING' || echo 'clean'
```

Bump `Chart.yaml` `version` and `appVersion` together whenever the tree changes, otherwise a rebuilt artifact is indistinguishable from the one already imported. Both are consistent as of 0.1.7 (`0.1.7` / `4.55`), and `appVersion` matters twice: it feeds the `app.kubernetes.io/version` label **and** it is the fallback when `image.tag` is empty.

### First-deploy checks

- **Filer LevelDB on the PVC.** Confirm the metadata store landed on the claim, not the container filesystem: `kubectl exec -n seaweedfs seaweedfs-filer-0 -- ls -la /data`. If the leveldb directory is not under `/data`, pin it with a `filer.toml` (`[leveldb2] enabled = true`, `dir = /data/filerldb2`) before putting data in.
- **Both filer ports published.** `kubectl get endpoints -n seaweedfs seaweedfs-filer-client` must show `8888` **and** `18888`. The second is what silently breaks the S3 gateway (§ 6).
- **Path-style addressing is mandatory.** The S3 endpoint is a single host with no wildcard DNS or certificate, so virtual-hosted-style (`bucket.host`) addressing cannot work: boto3 `Config(s3={'addressing_style': 'path'})`, rclone `force_path_style = true`, Spark `fs.s3a.path.style.access: true`. See [CLIENTS.md](CLIENTS.md).
- **Upload size.** The S3 route timeout is disabled, but confirm whatever sits in front of the ezua gateway (load balancer, proxy) does not impose its own body-size or idle-timeout limit before promising large uploads.

---

## 3. Endpoints

| Purpose | URL | Auth | Observed 2026-11-24 |
|---|---|---|---|
| Filer UI (browser) | `https://seaweedfs.${DOMAIN_NAME}` | PCAI SSO (oauth2-proxy) | `302` → Keycloak `UA` realm |
| S3 API (external uploads) | `https://seaweedfs-s3.${DOMAIN_NAME}` | SigV4 access key | `403 AccessDenied` for an unsigned request |
| S3 API (in-cluster) | `http://seaweedfs-s3.seaweedfs.svc.cluster.local:8333` | SigV4 | — |
| Filer (in-cluster) | `http://seaweedfs-filer-client.seaweedfs.svc.cluster.local:8888` | — | — |
| PCAI s3-proxy (apps) | `http://seaweed-fs-service.ezdata-system.svc.cluster.local:30000` | JWT (`AUTH_TOKEN`) | optional path, § 4 |

The S3 host is deliberately **not** behind oauth2-proxy: SigV4 clients cannot follow an OIDC redirect. Its only authentication is the access key in the `s3-config` Secret. `ezua.s3VirtualService.allowList.enabled=true` narrows the source range with a host-scoped `DENY` policy when the client egress is known.

---

## 4. Registering with PCAI as an Object Store data source

Data Sources registers **endpoints, not buckets**. Individual buckets are then granted per user.

1. **Data Engineering → Data Sources → Object Store Data → Add New Object Store**
2. Choose the **MinIO** tile (closest S3-compatible fit; there is no SeaweedFS tile).
3. Fill in:

| Field | Value |
|---|---|
| Name | `seaweed-fs` — no underscores, EzPresto rejects them |
| Endpoint | `http://seaweedfs-s3.seaweedfs.svc.cluster.local:8333` |
| Access Key | `seaweedfs` |
| Secret Key | the deployed key |
| Insecure | **tick** — the in-cluster endpoint is plain HTTP |

4. Click **Add**. A tile appears showing `<name>-service.ezdata-system.svc.cluster.local:30000`.
5. **Access model (admin vs member):**
   - **Admin** — unrestricted access to all data sources; no explicit grant needed. The IAM *Add Privileges* dialog states this directly: *"An admin user has unrestricted access to all data sources."*
   - **Member** — needs explicit per-bucket grants via Identity and Access Management → **Object Store Data** tab.

   There is **no bucket browser** in the Data Sources UI: the page lists endpoints only. A bucket therefore has no UI "home" even when you have full access to it. The real test of access is an API call through the proxy, not whether the bucket is listed anywhere.

### Consuming it from an app

```python
import os, boto3
from botocore.config import Config

s3 = boto3.client('s3',
    endpoint_url='http://seaweed-fs-service.ezdata-system.svc.cluster.local:30000',
    aws_access_key_id=os.environ['AUTH_TOKEN'],   # JWT, not a static key
    aws_secret_access_key='s3',
    region_name='us-east-1',
    config=Config(signature_version='s3v4', s3={'addressing_style': 'path'}),
)
```

This is a **second auth path** to the same data: static SigV4 key for external uploads, JWT-proxied for in-cluster apps. Bucket access therefore has two control planes — the `s3-config` identity file, and PCAI IAM grants. Granting one does not grant the other. Treat the MinIO-tile registration as unvalidated until it has been exercised on a test install: SeaweedFS is not a documented data-source backend.

---

## 5. Verification

The full ladder — render check, pods, PVCs, ports, identity, end-to-end S3, SSO redirect — with expected outputs is in [VERIFICATION.md](VERIFICATION.md). The short version:

```bash
kubectl get pods -n seaweedfs
kubectl get pvc -n seaweedfs
kubectl get endpoints -n seaweedfs      # filer-client must show 8888 AND 18888
```

End-to-end with boto3 (exercises create_bucket, put/get with byte verification, list, a 12 MiB multipart upload, presigned URLs and cleanup):

```bash
cd <repo>
export S3_SECRET_KEY='<key>'
export S3_CA_BUNDLE=~/.dsh/certs/pcai-aie-root-ca.crt   # the gateway cert is signed by the AIE Root CA
python3 test_s3_boto3.py
```

---

## 6. Troubleshooting — issues actually hit

| Symptom | Cause | Fix |
|---|---|---|
| s3 pod runs, never binds 8333, **zero logs**, exit 0 on SIGTERM | Filer gRPC port 18888 not published on `filer-client`, so the gateway blocks in IAM/bucket init before binding | Publish `grpc` (18888) on the `filer-client` Service — **this was the real bug** |
| `flag provided but not defined: -logtostderr`, all pods crashloop, exit 2 | SeaweedFS is not glog-based; those flags do not exist | Never add glog flags. SeaweedFS logs to stdout normally |
| `flag provided but not defined: -ip.bind` / `-metricsPort` on the s3 container | `weed s3` takes a much smaller flag set than master/volume/filer | s3 accepts only `-port`, `-filer`, `-config` |
| `exec: no such file or directory` for the container binary | Overriding `command` with a path that may not exist | Do not set `command:`; the image ENTRYPOINT is already `weed` and appends args |
| `VirtualService ... timeout: must be a valid duration greater than 1ms` | `timeout: 0s` is rejected by Istio | Omit `timeout` entirely — omitted means disabled |
| PVCs stuck `Pending`, `Quota name must be unique per tenant` | VAST CSI truncates quota names at 64 chars; stale quotas collide on reinstall | Use a fresh namespace per cycle, or clear stale VAST quotas |
| Pod `Pending`, event `Multi-Attach error for volume ... already used by pod(s)` | The claim is ReadWriteOnce and the old node has not detached yet | Expected after a drain or node loss — wait for the detach; do not force-delete the pod |
| `SSL: CERTIFICATE_VERIFY_FAILED` from boto3 | PCAI gateway cert signed by the cluster-internal AIE Root CA | `verify=<ca.pem>` or `AWS_CA_BUNDLE=<ca.pem>` |
| boto3 DNS error / wrong host | Virtual-hosted-style addressing against a single-host endpoint | `Config(s3={'addressing_style': 'path'})` — mandatory |
| S3 key stopped working after an upgrade | `s3.auth.secretKey` was empty, so the chart generated a new key | Set the key explicitly, or manage the Secret with `s3.existingConfigSecret` — [OPERATIONS.md § 5](OPERATIONS.md#5-key-rotation) |

### Diagnostic commands that paid off

```bash
# the flag set for a subcommand (settles most argument questions immediately)
kubectl run swdiag -n seaweedfs --rm -it --restart=Never \
  --image=chrislusf/seaweedfs:4.55 -- s3 -h 2>&1 | head -40

# port reachability between services, without guessing
kubectl run netdiag -n seaweedfs --rm -it --restart=Never --image=busybox:1.36 -- \
  sh -c 'nc -z -w3 seaweedfs-filer-client 8888 && echo 8888 OK; \
         nc -z -w3 seaweedfs-filer-client 18888 && echo 18888 OK'
```

Note the `-- s3 -h` form: the image ENTRYPOINT is `weed`, so args are appended to it. Passing `/usr/bin/weed s3 -h` yields `weed: unknown subcommand /usr/bin/weed`.

---

## 7. Known limitations

- **Single master and single filer.** One master is a write-path single point of failure (it holds no irreplaceable data — volume servers re-register). One filer with embedded LevelDB means the metadata store has no second copy: losing the filer claim makes every needle unaddressable. Both are the HA work in [ROADMAP.md](ROADMAP.md).
- **`001` is two copies, not two sites.** It survives losing one volume server. It does not survive losing the filer claim, and it does not survive a rack or data-center loss — `010`/`100` cannot be placed on a single-rack cluster.
- **Writes are `W = N`.** Both copies must be written for a write to succeed, so a lost volume server does not lose data but does fail writes to volumes that expected the missing copy until `volume.fix.replication` runs.
- **No backup.** Nothing snapshots the volume or filer PVCs. See [OPERATIONS.md § 6](OPERATIONS.md#6-backup-and-restore) for what to snapshot manually.
- **STS temporary credentials do not work.** The gateway logs `no signing key found for STS service` — static access keys only. Enabling STS needs `jwt.filer_signing.key` in `security.toml`.
- **One identity for the whole deployment.** No per-bucket IAM and no multi-tenant identities; handing out scoped access today means a second deployment.
- **The public S3 endpoint is not SSO-protected.** That is deliberate (SigV4 cannot follow an OIDC redirect), so the access key is internet-facing credentials. Use `ezua.s3VirtualService.allowList.enabled=true` with known egress CIDRs, and rotate on exposure.
- **Metrics are not scrapeable.** `-metricsPort=9327` is passed to master/volume/filer and they listen, but no Service publishes the port and nothing scrapes it. The S3 gateway has no metrics port in this flag set.
- **Filer UI assets are `go:embed`ed** — no runtime override; customising means forking SeaweedFS. A custom uploader should drive the filer HTTP contract instead: `POST /dir/` multipart (field `file`) or `PUT /dir/name` to upload; `POST /dir/newdir/` with an **empty body and no Content-Type** to mkdir. There is no `?op=mkdir`.
- **A deployment installed from an older artifact reports an older `app.kubernetes.io/version`.** `appVersion` feeds that label and is the fallback for an empty `image.tag`; since 0.1.7 both read `4.55`, but a release installed from 0.1.6 still carries `4.23` on its pods. Read the running image, not the label.

---

## 8. Where to read next

| Question | Document |
|---|---|
| What is this package, in one page? | [../README.md](../README.md) |
| How do the components cooperate, and what does each failure cost? | [ARCHITECTURE.md](ARCHITECTURE.md) |
| What is this knob and what does it change? | [CONFIGURATION.md](CONFIGURATION.md) |
| How do I run it day 2? | [OPERATIONS.md](OPERATIONS.md) |
| How do I connect a client? | [CLIENTS.md](CLIENTS.md) |
| How do I prove it works? | [VERIFICATION.md](VERIFICATION.md) |
| What is not built yet? | [ROADMAP.md](ROADMAP.md) |
| Why is the chart scaffolded, and how were the flags verified? | [../helm/PORTING.md](../helm/PORTING.md) |
