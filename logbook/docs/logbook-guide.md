# Logbook - End-to-End Guide

Centralised pod log retention for HPE AI Essentials (PCAI).

1. [Why](#1-why)
2. [Architecture](#2-architecture)
3. [Prerequisites](#3-prerequisites)
4. [Build the chart](#4-build-the-chart)
5. [Import into PCAI](#5-import-into-pcai)
6. [Connect Grafana](#6-connect-grafana)
7. [Verify](#7-verify)
8. [Using it (from kubectl logs to LogQL)](#8-using-it)
9. [Operations](#9-operations)
10. [Security review](#10-security-review)
11. [Troubleshooting](#11-troubleshooting)
12. [Variants](#12-variants)
13. [Logbook vs Headlamp](#13-logbook-vs-headlamp)

---

## 1. Why

Before Logbook, pod logs on a PCAI cluster exist only in the kubelet's rotation window on
each node (~50 MB per container). Reading them meant `kubectl logs` with a kubeconfig, or -
in practice - SSH to the node with an admin account. Once a pod restarts or is deleted, its
logs are gone. There is no cross-pod search, no history, no alerting.

Logbook fixes the retention and access problem:

- logs from **every pod on every node** are copied off continuously;
- they are kept for a configurable **retention period** in **MinIO**;
- they are searchable across pods, namespaces and time in the **platform Grafana**;
- access is via **Keycloak SSO** and Grafana permissions - no node access, no admin account.

## 2. Architecture

```
 node-1            node-2            node-N
 ┌──────────┐      ┌──────────┐      ┌──────────┐
 │ alloy    │      │ alloy    │      │ alloy    │   DaemonSet, non-privileged
 │(kubelet  │      │(kubelet  │      │(kubelet  │   reads /pods/<pod>/log via
 │  API)    │      │  API)    │      │  API)    │   the kubelet API - no hostPath
 └────┬─────┘      └────┬─────┘      └────┬─────┘
      └──────────────────┼─────────────────┘   HTTP push
                         ▼
               ┌──────────────────┐
               │ logbook-gateway  │  nginx (unprivileged)
               └────────┬─────────┘
                        ▼
               ┌──────────────────┐        ┌───────────────┐
               │ loki (single-    │ ─────▶ │ MinIO bucket  │  chunks + index,
               │ binary, 20Gi WAL)│  s3    │   "loki"      │  retention via compactor
               └────────┬─────────┘        └───────────────┘
                        ▲ query
               ┌──────────────────┐
               │ platform Grafana │  Explore / dashboards / alerts, Keycloak SSO
               └──────────────────┘
```

Components and what each one is:

| Component | Kind | Purpose |
|---|---|---|
| Grafana Alloy | DaemonSet | Discovers pods on its node, tails their logs through the kubelet API, attaches `namespace/pod/container/app/framework` labels, pushes to Loki. |
| Loki gateway | Deployment (nginx) | Single stable HTTP entry point; routes push and query to Loki. |
| Loki | StatefulSet | Indexes by label, compresses log chunks, writes to MinIO, enforces retention. |
| MinIO bucket | existing PCAI MinIO | Durable store for chunks and index. |
| Platform Grafana | existing | UI: Explore, dashboards, alerting. Logbook adds a data source. |
| NetworkPolicy | chart | Restricts who can talk to Loki (it has no built-in auth). |

> **Note on the platform OTel collector.** PCAI already collects every pod's logs with
> its own OpenTelemetry DaemonSet, but only retains them as rotated files for 7 days (for
> support bundles) with no index or UI. Logbook adds the keeping-and-reading part. It can be
> fed either by its own Alloy DaemonSet (default, validated) or by the platform collector via
> the OTel Endpoint setting (§12, no extra collector) - the storage and Grafana layers are
> identical either way.

Design decisions specific to PCAI:

- **Kubelet API instead of hostPath.** Avoids Kyverno/PSA exceptions; the agent has no host
  access at all.
- **Sidecar injection off per pod.** Push traffic is node-local; Istio adds nothing but
  failure modes here. The chart cannot label the namespace, so it annotates the pods.
- **Chunks on MinIO, not a PVC.** No PVC-growth problem; capacity is a bucket quota.
- **`hpe-ezua/*` labels via `podLabels`.** The tile reports health without a Kyverno mutate
  policy.
- **No external endpoint by default.** Grafana is the UI. Exposing the Loki API would expose
  push/delete to every SSO user.

## 3. Prerequisites

| Item | How to get it |
|---|---|
| cluster-admin kubeconfig | PCAI user menu → Download kubeconfig (admin user) |
| `helm` 3.x, `mc` on your workstation | brew / apt / MinIO docs |
| MinIO S3 API endpoint | `kubectl get svc -A \| grep -i minio` → service exposing 9000 (or 80/443 for operator tenants) |
| MinIO root or admin credentials | from whoever installed the MinIO framework |
| Grafana namespace | `kubectl get deploy -A \| grep -i grafana` (usually `monitoring`) |
| Storage class | `kubectl get sc` (leave `""` in values for the default) |
| Internet or a Harbor proxy for `grafana.github.io` and the three images | needed once, at packaging time |

Create the bucket and a scoped user - in the MinIO console (MinIO tile → Open):

1. **Buckets → Create Bucket** → `loki`.
2. **Policies → Create Policy** → `loki-bucket-rw` (ListBucket/GetBucketLocation on
   `arn:aws:s3:::loki`; Get/Put/DeleteObject on `arn:aws:s3:::loki/*`). Loki needs
   DeleteObject for retention.
3. **Identity → Users → Create User** → `loki-user` + secret, policy `loki-bucket-rw`.
4. Optional: bucket → **Encryption** → enable SSE-S3.

CLI equivalent: `mc mb pcai/loki`, `mc admin policy create …`, `mc admin user add …`,
`mc admin policy attach …` (see README).

The S3 API endpoint for values.yaml is the in-cluster service on port 9000
(`kubectl get svc -A | grep -i minio`), not the console URL.

## 4. Build the chart

Logbook is an umbrella chart. `Chart.yaml` lists `grafana/loki` and `grafana/alloy` as
dependencies; `helm dependency update` downloads those subcharts into `charts/`. The
`helm repo add grafana` line only tells Helm where to fetch them - it installs nothing on
the cluster and has nothing to do with the Grafana *application* (which Logbook reuses,
not installs).

```bash
git clone <this repo> && cd logbook
helm repo add grafana https://grafana.github.io/helm-charts   # chart source, not an install
helm dependency update .                                        # vendors loki + alloy into charts/
```

Edit `values.yaml` - required fields:

| Key | Value |
|---|---|
| `minio.endpoint` **and** `loki.loki.storage.s3.endpoint` | `http://<minio-svc>.<ns>.svc.cluster.local:9000` |
| `minio.insecure` **and** `loki.loki.storage.s3.insecure` | `true` for plain HTTP; `false` + `https://` if MinIO has TLS |
| `minio.accessKey` / `minio.secretKey` | `loki-user` credentials (or `createSecret: false` and pre-create Secret `loki-s3`) |
| `grafana.namespace` | namespace of the platform Grafana |
| `retentionHours` **and** `loki.loki.limits_config.retention_period` | e.g. `720` / `720h` |

Validate:

```bash
helm lint .
helm template logbook . > /tmp/r.yaml
grep -c "kind: DaemonSet"    /tmp/r.yaml    # 1
grep -c "kind: StatefulSet"  /tmp/r.yaml    # 1
grep -c "kind: NetworkPolicy" /tmp/r.yaml   # 1
grep -B3 "hpe-ezua/type: vendor-service" /tmp/r.yaml | grep -c "labels:"   # ≥3 (loki, gateway, alloy)
grep -E "hostPath|privileged: true|hostNetwork: true" /tmp/r.yaml           # empty
grep -E "^\s+image:" /tmp/r.yaml | sort -u                                   # mirror list for airgap
cd .. && tar czf logbook.tar.gz logbook/
```

## 5. Import into PCAI

1. **Tools & Frameworks → Import Framework**.
2. Upload `logbook.tar.gz`; name `Logbook`; namespace `logbook` (any name; it is created for you).
3. Review the values screen - the `${RELEASE_NAME}` / `${NAMESPACE}` / `${DOMAIN_NAME}`
   placeholders are substituted here.
4. Import. Watch progress:

```bash
kubectl -n logbook get pods -w
# expected: logbook-0 (loki), logbook-gateway-xxx, logbook-alloy-xxx × (number of nodes)
kubectl get ezappconfig -A | grep logbook        # STATE ready, HEALTH ok
```

## 6. Connect Grafana

**Automatic.** The chart creates a ConfigMap labelled `grafana_datasource: "1"` in the
Grafana namespace. If the platform Grafana runs the datasource sidecar, Loki appears under
**Connections → Data sources** within a minute.

Check for the sidecar:
```bash
kubectl get deploy -n <grafana-ns> grafana -o jsonpath='{.spec.template.spec.containers[*].name}'
# contains grafana-sc-datasource → automatic works
```

**Dashboard.** The chart also ships a "Pod Logs (Logbook)" dashboard the same way
(`grafana_dashboard: "1"` ConfigMap). Without the sidecar: Dashboards → New → Import →
paste `dashboards/pod-logs.json`, pick the Loki data source. It has namespace / pod / search
variables, log volume and error-rate panels, and a logs panel - the `kubectl logs` replacement
for people who won't type LogQL.

**Manual** (no sidecar) - as a Grafana admin:
Connections → Data sources → Add → **Loki** →
URL `http://logbook-gateway.logbook.svc.cluster.local` (port 80, no auth) → **Save & test**.

## 7. Verify

```bash
# pipeline health
kubectl -n logbook logs ds/logbook-alloy | grep -iE "error|denied|refused"   # should be quiet
kubectl -n logbook logs sts/logbook      | grep -iE "error|s3"               # should be quiet
mc ls pcai/loki                                                               # index_/ and chunk dirs after a few minutes
```

In Grafana → Explore → Loki:

```logql
{namespace="logbook"}          # Logbook's own logs appear within seconds
```

Then the test that matters:

1. `kubectl -n minio exec deploy/<minio> -- sh -c 'echo LOGTEST-$(date +%s) >&2'`
2. Query `{namespace="minio"} |= "LOGTEST"` - the line appears.
3. Delete that pod, wait for it to come back, run the query again - **the line is still there**.

**Hot-fix without re-import** (dev clusters): edit the ConfigMap and restart the DaemonSet -
`kubectl -n <ns> create cm logbook-alloy --from-file=config.alloy=/tmp/config.alloy --dry-run=client -o yaml | kubectl apply -f -`
then `kubectl -n <ns> rollout restart ds/logbook-alloy`. Re-import the bumped chart afterwards
so the tile and the cluster agree.

## 8. Using it

For people who live in `kubectl logs`:

| Today | In Grafana → Explore → Loki |
|---|---|
| `kubectl logs -n minio minio-0` | `{namespace="minio", pod="minio-0"}` |
| `… -c sidecar` | `{namespace="minio", pod="minio-0", container="sidecar"}` |
| `… -l app=minio` | `{namespace="minio", app="minio"}` |
| `… \| grep -i error` | `{namespace="minio", pod="minio-0"} \|~ "(?i)error"` |
| `… \| grep -v health` | `… != "health"` |
| `… --since=2h` | same query, time picker → *Last 2 hours* |
| `… -f` | **Live** button (top right) |
| `… --previous` | same query, widen the time range |
| whole framework | `{framework="minio"}` (from the `hpe-ezua/app` label) |
| impossible | `{namespace=~".+"} \|= "OOMKilled"` - every pod in the cluster |

Filters: `|=` contains, `!=` excludes, `|~` regex (Go syntax; `(?i)` = case-insensitive).

Useful extras: click a label in a log line to filter/exclude; **Split** to put a pod's logs
next to its CPU/memory; `sum by (namespace) (rate({namespace=~".+"}[5m]))` for log volume;
the URL encodes query + time range - paste it into a ticket; **Inspector → Data → Download**
for CSV.

Recommended dashboard for non-LogQL users: a **Logs** panel with query
`{namespace="$namespace", pod=~"$pod"}` and two variables
(`label_values(namespace)`, `label_values({namespace="$namespace"}, pod)`) - two dropdowns,
no typing.

## 9. Operations

| Concern | Action |
|---|---|
| Retention | `loki.loki.limits_config.retention_period`; compactor deletes from MinIO. |
| Capacity | `mc du pcai/loki` weekly for the first month (≈ 1/10 of raw log volume), then set a bucket quota. |
| Loki health | ServiceMonitor is on; alert on `loki_ingester_memory_streams` growth (cardinality) and `loki_request_duration_seconds` p99. |
| Alloy health | `loki_write_dropped_entries_total > 0` → Loki refusing writes → raise `ingestion_rate_mb`. |
| Noisy framework | add `per_stream_rate_limit` in `limits_config`, or a `drop` rule in Alloy's `discovery.relabel`. |
| Apps logging to files | invisible to Alloy; fix the app chart (`--log-to-stdout`, console appender) or add a `tail -F` sidecar. |
| High cardinality | never add pod UID, request ID, or timestamps as labels. |
| Upgrade | bump `Chart.yaml` version, re-package, PCAI → framework → Upgrade. Loki data survives (it's in MinIO). |
| Uninstall | remove the framework; the MinIO bucket and 20Gi PVC are left behind on purpose - delete manually if wanted. |

## 10. Security review

**Node-level footprint: presence, not privilege.**

| Check | Alloy | Loki / gateway |
|---|---|---|
| Pod on every node | yes (by design) | no |
| hostPath / hostNetwork / hostPID / privileged | none | none |
| Runs as root | no - uid 473, read-only root FS, all caps dropped, seccomp RuntimeDefault | no - uid 10001 / nginx-unprivileged |
| Host filesystem writes | none | none |
| Pod Security *restricted* | passes | passes |

**Real exposure and the control for each:**

| Risk | Control |
|---|---|
| Alloy's ClusterRole reads `pods/log` cluster-wide; anything printed to stdout (tokens, PII) is stored 30 days | private bucket + SSE; Grafana data-source permissions; optional Alloy `drop` for sensitive namespaces; `loki.process` masking stage |
| Loki has no auth in-cluster | NetworkPolicy: only Alloy, gateway, Grafana ns, Prometheus ns |
| External endpoint would expose push/delete to all SSO users | `ezua.virtualService.enabled: false` by default; if enabled, restrict paths to `/loki/api/v1/query*`, `labels`, `series` |
| MinIO credentials in values → `EzAppConfig.Spec.Values` | `minio.createSecret: false` + pre-created Secret |
| Cross-namespace write (Grafana ConfigMap, AuthorizationPolicy) | documented; only when enabled |
| Ingest flooding | `ingestion_rate_mb`, `reject_old_samples`, per-stream limits |

One-liner for a security questionnaire: *the agent is a non-privileged, read-only consumer
of the Kubernetes logs API on each node with no host access; the sensitive asset is the
log store, whose access is restricted by network policy to the collector, the platform
Grafana and Prometheus, with credentials from a pre-created Secret and bounded retention.*

## 11. Troubleshooting

| Symptom | Check |
|---|---|
| Alloy pods `CrashLoopBackOff`, `mkdir /tmp/alloy: read-only file system` | storage path not writable - the chart mounts an `emptyDir` there (`alloy.alloy.mounts.extra` + `alloy.controller.volumes.extra`); make sure a value override didn't drop it |
| Alloy pods `CrashLoopBackOff`, `expected TERMINATOR, got ILLEGAL` | Alloy config syntax - one attribute per line, no `;`. Check the rendered ConfigMap: `kubectl -n <ns> get cm logbook-alloy -o jsonpath='{.data.config\.alloy}'` |
| Alloy logs `400 … timestamp too old` right after start | expected once: Alloy back-reads existing container logs; Loki rejects lines older than 7 days. Stops within minutes. |
| Alloy logs `403 Forbidden` | RBAC: `kubectl auth can-i get pods/log --as=system:serviceaccount:logbook:logbook-alloy` → add `pods/log`, `nodes/proxy` to the ClusterRole |
| Alloy logs `connection refused` on push | `LOKI_GATEWAY` env wrong → `kubectl -n logbook get svc`; on direct helm installs the placeholder was not substituted |
| Loki logs `NoSuchBucket` / `AccessDenied` / `SignatureDoesNotMatch` | bucket name, credentials, or `s3ForcePathStyle` |
| Loki logs `x509` | MinIO TLS: set `insecure: false`, `https://`, and mount `ezaf-root-ca` |
| Grafana "Save & test" fails | wrong service name/namespace; `curl http://logbook-gateway.logbook/ready` from another pod |
| Test passes, Explore empty | NetworkPolicy blocking Grafana's namespace → check `grafana.namespace` value; or Alloy not shipping (see above) |
| Tile health **Unknown** | `kubectl -n logbook get pods -l hpe-ezua/app=logbook` empty → `podLabels` key changed upstream; see porting.md |
| Import fails, re-upload rejected | bump `version` in Chart.yaml |
| Pods Pending, EzLicense message | every container needs `resources.limits.cpu` - all three do; check any value override |

Controller-level: `kubectl logs -n ezapp-system $(kubectl get pod -n ezapp-system -l control-plane=controller-manager -o jsonpath='{.items[0].metadata.name}')`.

## 12. Variants

**Using the platform's own OpenTelemetry collector instead of Alloy.** PCAI already runs
an OTel collector DaemonSet (`ez-otel` in `monitoring`) that tails every pod's log file and
tags each line with `k8s.namespace.name`, `k8s.pod.name`, `k8s.container.name`,
`k8s.node.name`, `app_name` (from `hpe-ezua/app`), `app_type` and `cluster_name`. Today it
forwards to `ez-otel-central`, whose `ezlogcollector` sidecar keeps rotated files on a PVC
for 7 days (support bundles), and sends platform/system logs plus metrics to the PCAI
management gateway. **Administration → Settings → Configurations → OTel Endpoint** adds a
customer destination to that pipeline (OTLP, `host:port`, HTTPS host).

Logbook can consume that instead of running Alloy - "OTel mode":

```
ez-otel (PCAI) ──OTLP──▶ logbook-otel (receiver) ──▶ Loki ──▶ Grafana
                                                ──▶ metrics: drop / remote-write / forward
```

- Replace the `alloy` dependency with `open-telemetry/opentelemetry-collector` in
  deployment mode: OTLP gRPC/HTTP receiver with a TLS cert from the platform issuer,
  `otlphttp` exporter to `http://logbook-gateway/otlp` for logs, and a separate metrics
  pipeline (the endpoint receives both signals).
- Add `limits_config.otlp_config.resource_attributes` to Loki to promote
  `k8s.namespace.name`, `k8s.pod.name`, `k8s.container.name`, `app_name` to index labels;
  queries become `{k8s_namespace_name="minio"}`.
- Set the OTel Endpoint to `logbook-otel.<ns>.svc.cluster.local:4317`.

Trade-offs vs Alloy: no extra DaemonSet, no cluster-wide `pods/log` RBAC for Logbook, and
it uses the HPE-documented interface; but ~30 s latency (platform `poll_interval`), no
backfill on first start (`start_at: end`), and coverage is whatever the platform routes to
the endpoint.

**Customer has a SIEM (Splunk / Elastic / OpenSearch / Datadog / OpsRamp).** Three ways,
in order of preference:

1. *Platform OTel Endpoint → their collector.* No Logbook at all. Point the endpoint at
   an OTel Collector (or native OTLP intake) on their side and use its exporter:
   `splunk_hec`, `elasticsearch`, `opensearch`, `datadog`, or OTLP to OpsRamp. Metrics
   ride along in the same stream. This is the HPE-supported integration.
2. *Logbook OTel mode as fan-out.* Logbook's receiver keeps a full-fidelity copy in Loki
   on-cluster and forwards a filtered subset (errors, selected namespaces) to the SIEM
   from a second exporter. One endpoint, two destinations; best for data-sovereign
   customers who still need NOC visibility.
3. *Alloy → SIEM.* Keep Alloy, drop Loki: `otelcol.receiver.loki` → `otelcol.exporter.*`
   in the Alloy config. Or the Fluent Bit chart with a native `[OUTPUT]` plugin - note
   Fluent Bit tails `/var/log/containers` via hostPath and needs a Kyverno exception.
   Use this only where the platform endpoint can't be used.

**Scaling beyond single-binary.** Above ~100 GB/day switch `deploymentMode:
SimpleScalable` (separate read/write/backend replicas); values are already laid out for
it - set the replica counts and drop `singleBinary.replicas` to 0. MinIO remains the
store. Put a quota on the bucket (`mc quota set pcai/loki --size <N>GiB`) so Logbook can
never fill the shared MinIO, and alert on `minio_bucket_usage_total_bytes{bucket="loki"}`
and `loki_write_dropped_entries_total`.

**Multi-tenancy.** For hard isolation between teams, set `auth_enabled: true`, have the
collector send `X-Scope-OrgID` per namespace (Alloy `loki.write` `tenant_id`, or the OTel
`headers_setter` extension keyed on `k8s.namespace.name`), and create one Grafana data
source per tenant.

