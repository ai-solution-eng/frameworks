# Release Notes

## Chart Version

| Field        | 2.0.47 (AIE) | 2.0.47 (Upstream) |
|--------------|---------------|-------------------|
| `version`    | `2.0.47`      | `2.0.47`          |
| `appVersion` | `2.0.47`      | `2.0.47`          |



## Added Files in `2.0.47` (AIE) (not in upstream)

| File                        | Purpose |
|-----------------------------|---------|
| `templates/kyverno.yaml`    | Kyverno `ClusterPolicy` that mutates pods/services to add HPE Ezmeral labels (`hpe-ezua/type`, `hpe-ezua/app`) via a pre-install hook. |
| `templates/virtualservice.yaml` | Istio `VirtualService` routing traffic through the Ezmeral gateway (`ezua.virtualService.istioGateway`) to the frontend service. |



## Template Changes

### Scheduler Support
All four templates gained `schedulerName` injection using the new top-level `schedulerName` value, so pods land on `scheduler-plugins-scheduler`:

- `templates/deployment.yaml` — all component deployments
- `templates/chart-pre-upgrade-migration-job.yaml`
- `templates/clickhouse-backup-cronjob.yaml`
- `templates/demo-data-generator-job.yaml`

### `_helpers.tpl`
- `2.0.47` is missing three label lines present in the upstream:
  - `helm.sh/chart`
  - `app.kubernetes.io/version`
- The upstream version has richer standard Kubernetes labels.



## `values.yaml`

| Setting | 2.0.47 (AIE) | 2.0.47 (Upstream) |
|---|---|---|
| `schedulerName` | Added (`scheduler-plugins-scheduler`) | Not present |
| `ezua:` block | Added (domain, VirtualService, gateway, auth policy, self-signed certs) | Not present |
| `demoDataJob.enabled` | `false` | `true` |
| `clickhouse.adminUser` | Inline comments added for clarity | No comments |


## `charts/altinity-clickhouse-operator/values.yaml`

| Setting | 2.0.47 (AIE) | 2.0.47 (Upstream) |
|---|---|---|
| `username` / `password` | Inline comments added | No comments |


## Net Effect

`2.0.47` (AIE) extends the upstream chart with AIE customizations:

- **Kyverno policy** for label mutation on pods and services.
- **Istio VirtualService** for Ezmeral gateway traffic routing.
- **Scheduler support** via `schedulerName` across all workload templates.
- **EZUA configuration block** for domain, gateway, authorization, and certificate settings.
- **Safer defaults**: demo data and the ClickHouse operator are disabled out of the box.
- **Trade-off**: some standard upstream Kubernetes labels (`helm.sh/chart`, `app.kubernetes.io/version`) are missing in `_helpers.tpl`.