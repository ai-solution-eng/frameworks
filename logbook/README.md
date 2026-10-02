# Logbook:  centralised pod logs for HPE AI Essentials

**Alloy** (DaemonSet) → **Loki** (single-binary, MinIO) → platform **Grafana**.

Every pod's stdout/stderr on every node is shipped continuously, retained (30 days by
default), and searchable with LogQL — no node SSH, no shared admin account, and logs survive
pod restarts and deletion.

| | |
|---|---|
| Chart | `logbook` 0.1.0 (umbrella: grafana/loki ^6, grafana/alloy ^1) |
| Runs on | every node (Alloy, non-privileged) + 1 Loki pod + 1 gateway pod |
| Storage | MinIO bucket `loki` + 20Gi PVC |
| UI | platform Grafana → Explore → Loki |
| Node privileges | none (no hostPath / hostNetwork / privileged; kubelet API read only) |

## Quick start

### 1. MinIO — bucket and credentials (MinIO console)

Open the MinIO tile (Tools & Frameworks → MinIO → Open) and:

1. **Buckets → Create Bucket** → name `loki` → Create (versioning/locking off).
2. **Policies → Create Policy** → name `loki-bucket-rw` → paste:
   ```json
   {"Version":"2012-10-17","Statement":[
     {"Effect":"Allow","Action":["s3:ListBucket","s3:GetBucketLocation"],"Resource":["arn:aws:s3:::loki"]},
     {"Effect":"Allow","Action":["s3:GetObject","s3:PutObject","s3:DeleteObject"],"Resource":["arn:aws:s3:::loki/*"]}]}
   ```
3. **Identity → Users → Create User** → Access Key `loki-user`, Secret Key `<STRONG_SECRET>`,
   assign policy `loki-bucket-rw` → Save. Copy the secret now; it is not shown again.

Note the S3 API endpoint for values.yaml — the in-cluster service on port 9000, **not** the
console URL you just used: `kubectl get svc -A | grep -i minio`.

<details><summary>CLI equivalent (mc)</summary>

```bash
mc alias set pcai http://<minio-svc>.<ns>.svc.cluster.local:9000 <ROOT_KEY> <ROOT_SECRET>
mc mb pcai/loki
mc admin policy create pcai loki-bucket-rw loki-bucket-rw.json
mc admin user add pcai loki-user <STRONG_SECRET>
mc admin policy attach pcai loki-bucket-rw --user loki-user
```
</details>

### 2. Build the chart

Note: This step will not be required if you are not making any changes in the chart.

Logbook is an umbrella chart: `Chart.yaml` declares `grafana/loki` and `grafana/alloy` as
dependencies, and `helm dependency update` downloads those two subcharts into `charts/`.
`helm repo add grafana …` only registers where to download them from — it does **not**
install Grafana or anything else on the cluster. (Grafana itself is not part of Logbook;
the platform Grafana is reused.)

```bash
helm repo add grafana https://grafana.github.io/helm-charts   # once per workstation
helm dependency update ./logbook                                # pulls loki + alloy into charts/
#   edit values.yaml: minio.endpoint (x2), minio.accessKey/secretKey, grafana.namespace
helm lint ./logbook
tar czf logbook.tar.gz logbook/
```

Air-gapped? Mirror the two charts into Harbor (`helm pull grafana/loki grafana/alloy`,
`helm push … oci://harbor/…`) and point `Chart.yaml` `repository:` at the OCI path.

### 3. Import

PCAI → **Tools & Frameworks → Import Framework** → upload `logbook.tar.gz` → namespace `logbook`.

In values.yaml check all the REQUIRED fields by searching REQUIRED.
Please add minio access key and secret key.
Verify grafana namesapce and domainname is correct or not.

Grafana data source (if not auto-created by the sidecar): Connections → Data sources →
Loki → URL `http://logbook-gateway.<namespace>.svc.cluster.local` → Save & test.
Dashboard: **Dashboards → Pod Logs (Logbook)** (or import `dashboards/pod-logs.json`).

Then in Grafana → Explore → Loki:

```logql
{namespace="logbook"}                       # Logbook's own logs — proves the pipeline
{namespace="minio"} |= "error"
{framework="ezpresto"} |~ "(?i)timeout"
```

Full setup, operations, security review and troubleshooting: **docs/logbook-guide.md**.
Changes relative to upstream charts: **porting.md**.


# Logbook: `values.yaml` reference

What to change, when, and what happens if you don't. Keys are grouped by how often you
touch them. "Line" refers to the shipped `values.yaml` (0.1.4) and may drift.

## 1. Must set before every import

| Key | Line | Set to | If wrong |
|---|---|---|---|
| `minio.endpoint` | 26 | `http://<minio-svc>.<ns>.svc.cluster.local:9000` — the S3 **API** service (not the console URL). Find it: `kubectl get svc -A \| grep -i minio`. Operator tenants may use port 80/443. | Loki logs `dial tcp … connection refused` / `no such host`; nothing is stored |
| `loki.loki.storage.s3.endpoint` | 80 | **Same value** as above — Helm can't reference one value from another inside a subchart block | same as above |
| `minio.accessKey` / `minio.secretKey` | 35–36 | The bucket user's key/secret (e.g. `loki-user` / your password). Only when `createSecret: true`. | Loki logs `SignatureDoesNotMatch` / `AccessDenied` |
| `grafana.namespace` | 45 | Namespace of the platform Grafana: `kubectl get deploy -A \| grep -i grafana`| Data source & dashboard ConfigMaps land in the wrong namespace (no auto-registration); NetworkPolicy blocks Grafana → "Save & test" fails |
| `grafana.host` | 46 | External Grafana hostname as seen in the browser, e.g. `grafana.<domain>`; `${DOMAIN_NAME}` is filled in on import | Tile's Open button redirects to a dead host |

## 2. Set once per environment

| Key | Line | Default | Change when |
|---|---|---|---|
| `minio.insecure` **and** `loki.loki.storage.s3.insecure` | 28, 83 | `true` | MinIO is HTTPS → set both `false` and use `https://` in both endpoints; mount `ezaf-root-ca` into Loki if the cert is platform-signed |
| `minio.bucket` + the three `loki.loki.storage.bucketNames.*` | 27, 74–76 | `loki` | You named the bucket differently — change all four |
| `minio.createSecret` | 33 | `true` | Production: set `false`, create Secret `loki-s3` by hand (see comment in file) so credentials never enter `EzAppConfig.Spec.Values` |
| `minio.secretName` | 34 | `loki-s3` | Only if your pre-created Secret has another name; also update `loki.singleBinary.extraEnvFrom[0].secretRef.name` |
| `storageClass` **and** `loki.singleBinary.persistence.storageClass` | 56, 108 | `""` (cluster default) | Cluster default isn't expandable or is the wrong tier |
| `networkPolicy.prometheusNamespace` | 41 | `monitoring` | Prometheus runs elsewhere (e.g. `prometheus`) — otherwise the Loki ServiceMonitor scrapes fail |
| `ezua.virtualService.endpoint` | 15 | `logbook.${DOMAIN_NAME}` | Hostname clash, or a second Logbook on the same cluster |
| `grafana.datasource.uid` | 50 | `pcai-loki` | Only if it clashes with an existing data source UID; the dashboard JSON is rewritten to match automatically |

## 3. Tune after the first week

| Key | Line | Default | Guidance |
|---|---|---|---|
| `retentionHours` **and** `loki.loki.limits_config.retention_period` | 55, 87 | `720` / `720h` (30 d) | Set to what the bucket can hold: `mc du pcai/loki` ÷ days running × target days. Keep both in sync. |
| `loki.loki.limits_config.ingestion_rate_mb` / `ingestion_burst_size_mb` | 88–89 | `20` / `40` | Raise if `loki_write_dropped_entries_total` > 0 with Loki healthy |
| `loki.loki.limits_config.reject_old_samples_max_age` | 92 | `168h` | Raise (≤ retention) if you want more history on first start; lowers the one-time "timestamp too old" 400s |
| `loki.singleBinary.resources` | 116–118 | req 500m/1Gi, lim 2/4Gi | `requests.cpu` may drop to 100m on small clusters; **keep `limits.cpu`** (EzLicense scheduling) |
| `loki.singleBinary.persistence.size` | 107 | `20Gi` | WAL/cache only; grow only if Loki logs disk-pressure warnings |
| `alloy.alloy.resources` | ~190 | req 100m/128Mi, lim 500m/512Mi | Per node. Raise memory on nodes with very chatty pods |
| `alloy.controller.volumes.extra[0].emptyDir.sizeLimit` | ~163 | `1Gi` | Buffer while Loki is unreachable; raise for long expected outages |

## 4. Leave alone unless you know why

| Key | Why it's set this way |
|---|---|
| `loki.fullnameOverride: logbook`, `alloy.fullnameOverride: logbook-alloy` | Pins service names (`logbook`, `logbook-gateway`, `logbook-alloy`) so nothing depends on the release name PCAI assigns |
| `loki.loki.podLabels` / `gateway.podLabels` / `alloy.controller.podLabels` (`hpe-ezua/*`) | Tile health. `hpe-ezua/app` must stay `${RELEASE_NAME}` |
| `*.podAnnotations` → `sidecar.istio.io/inject: "false"` | Push traffic is node-local; sidecars add failure modes |
| `loki.deploymentMode: SingleBinary`, `read/write/backend.replicas: 0` | Single-binary mode. For > ~100 GB/day switch to `SimpleScalable` (guide §12) |
| `loki.loki.auth_enabled: false` + `networkPolicy.enabled: true` | Loki has no auth; the NetworkPolicy is the access control. Disable the policy only for debugging, never in production |
| `loki.minio.enabled: false`, caches, canary, test, selfMonitoring | Don't let the subchart deploy its own MinIO or memcached |
| `loki.loki.schemaConfig` | TSDB v13. Changing it on an existing store requires a new `from` date, never an edit |
| `loki.loki.compactor.retention_enabled: true` | Without this retention is never enforced and MinIO grows forever |
| `alloy.alloy.securityContext` (non-root, RO root FS, no caps) + `mounts.extra` / `volumes.extra` for `/tmp/alloy` | Security posture; the emptyDir is required by the read-only root FS |
| `alloy.alloy.extraEnv[NODE_NAME]` | Makes each Alloy pod tail only its own node |
| `alloy.alloy.extraEnv[LOKI_GATEWAY]` = `logbook-gateway.${NAMESPACE}.svc.cluster.local` | Push target. `${NAMESPACE}` is substituted on tile import; direct `helm install` needs `--set 'alloy.alloy.extraEnv[1].value=logbook-gateway.<ns>.svc.cluster.local'` |
| `alloy.alloy.configMap.content` | One attribute per line — Alloy syntax rejects `;` |
| `ezua.authorizationPolicy.enabled: false` | The endpoint is a redirect to Grafana; Grafana enforces login |

## 5. Optional switches

| Key | Default | Effect |
|---|---|---|
| `ezua.virtualService.enabled` | `true` | `false` → no tile endpoint; Open button inactive |
| `grafana.datasource.enabled` | `true` | `false` → add the Loki data source by hand |
| `grafana.dashboard.enabled` | `true` | `false` → import `dashboards/pod-logs.json` by hand |
| `networkPolicy.enabled` | `true` | `false` → Loki reachable from any pod (debug only) |
| `loki.monitoring.serviceMonitor.enabled` | `true` | `false` if there is no Prometheus operator |
| `alloy.controller.tolerations` | `operator: Exists` | Narrow it to skip specific node pools |

## 6. Per-namespace retention (optional)

Add under `loki.loki.limits_config` to keep noisy or low-value namespaces shorter:

```yaml
    retention_stream:
      - selector: '{namespace="kube-system"}'
        priority: 1
        period: 168h
```

## 7. Keep-in-sync pairs

Helm cannot cross-reference values inside a subchart block, so these must be edited together:

| Top-level (documentation) | Inside `loki.*` (what Loki actually reads) |
|---|---|
| `minio.endpoint` | `loki.loki.storage.s3.endpoint` |
| `minio.insecure` | `loki.loki.storage.s3.insecure` |
| `minio.bucket` | `loki.loki.storage.bucketNames.{chunks,ruler,admin}` |
| `minio.secretName` | `loki.singleBinary.extraEnvFrom[0].secretRef.name` |
| `retentionHours` | `loki.loki.limits_config.retention_period` |
| `storageClass` | `loki.singleBinary.persistence.storageClass` |
