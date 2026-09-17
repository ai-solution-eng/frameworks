# Logbook

Helm chart for **Logbook 0.1.0** - centralised pod log retention for HPE AI Essentials
(Grafana Alloy 1.x → Grafana Loki 3.x on MinIO → platform Grafana).

Unlike most entries in this repository, Logbook is not a port of a single upstream chart.
It is an umbrella chart that wraps two upstream Grafana charts and adds the PCAI-specific
glue so the whole thing imports with the **Import Framework** button.

The following has been done:

- **Upstream dependencies** (`Chart.yaml`): `grafana/loki` (^6.0.0) and `grafana/alloy` (^1.0.0)
  from `https://grafana.github.io/helm-charts`. Run `helm dependency update` before packaging;
  the `charts/` directory is not committed.

- Following [instructions from the documentation page](https://support.hpe.com/hpesc/public/docDisplay?docId=a00aie112hen_us&page=Administration/preparing-framework-helm-chart.html), we added:
  * **templates/ezua/virtualService.yaml**: Loki has no UI of its own, so the tile endpoint
    `logbook.${DOMAIN_NAME}` is a 302 **redirect to the platform Grafana** (`grafana.host`).
    Loki's API is never exposed outside the cluster. **templates/ezua/authpolicy.yaml** exists
    but is off by default - a redirect needs no oauth2-proxy gate; Grafana enforces login.
  * **templates/_hpe-ezua.tpl** for resources rendered by the umbrella chart.
  * The `ezua` section in **values.yaml**:

```
ezua:
  autoHelm: false
  domainName: "${DOMAIN_NAME}"
  virtualService:
    enabled: false
    endpoint: "logbook.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
  authorizationPolicy:
    enabled: true
    namespace: "istio-system"
    providerName: "oauth2-proxy"
    matchLabels:
      istio: "ingressgateway"
```

- **hpe-ezua labels** are pushed into the subchart pods through their own `podLabels` values
  (`loki.loki.podLabels`, `loki.gateway.podLabels`, `alloy.controller.podLabels`) using a YAML
  anchor, so no Kyverno mutate policy is needed and the tile reports health.

- **Istio sidecar injection is disabled per pod** (`sidecar.istio.io/inject: "false"` via
  `podAnnotations`) because the chart cannot label the platform-created namespace.

- **Alloy tails through the kubelet API** (`loki.source.kubernetes`) instead of mounting
  `/var/log` - no hostPath, no privileged pod, no Kyverno exception. It runs as uid 473,
  read-only root FS, all capabilities dropped.

- **Loki runs in SingleBinary mode** with chunks and index on MinIO (`storage.type: s3`,
  `s3ForcePathStyle: true`); the only PVC is a 20Gi WAL/cache. The chart's bundled MinIO,
  canary, caches, and self-monitoring are disabled.

- To avoid EzLicense capacity issues that prevent pods from being scheduled, every pod
  specifies `resources.limits.cpu` (Loki 2, gateway 500m, Alloy 500m).

- Added **templates/networkpolicy.yaml**: Loki has `auth_enabled: false`, so ingress to the
  Loki pods is restricted to Alloy, the gateway, the Grafana namespace and the Prometheus
  namespace.

- Added **templates/grafana-datasource.yaml**: a ConfigMap labelled `grafana_datasource: "1"`
  in the platform Grafana namespace so the Loki data source appears automatically where the
  Grafana datasource sidecar is present.

- Added **templates/loki-s3-secret.yaml** (optional, `minio.createSecret`) for the MinIO
  credentials. Preferred: create the Secret out of band and set `createSecret: false` so the
  keys never land in `EzAppConfig.Spec.Values`.

- Added **templates/grafana-dashboard.yaml** + **dashboards/pod-logs.json**: a "Pod Logs
  (Logbook)" dashboard (namespace/pod/search variables, volume, error rate, logs panel)
  delivered through the Grafana dashboard sidecar, or importable by hand.

- **Alloy gets an `emptyDir` (1Gi cap) at `/tmp/alloy`**: with `readOnlyRootFilesystem: true`
  the storage path must be a mount, otherwise Alloy fails with
  `mkdir /tmp/alloy: read-only file system`.

- **Alloy config style**: one attribute per line inside `rule { }` blocks - the Alloy syntax
  does not accept `;` as a separator (fails with `expected TERMINATOR, got ILLEGAL`).

## Notes

- Upstream charts: [grafana/loki](https://github.com/grafana/loki/tree/main/production/helm/loki)
  and [grafana/alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy).
- The MinIO bucket (`loki`) and a scoped user must exist before import - see README.
- `minio.endpoint` and `loki.loki.storage.s3.endpoint` must be set to the same value; Helm
  cannot reference one value from another in a subchart block.
- Service names are pinned with `fullnameOverride` (`logbook`, `logbook-gateway`, `logbook-alloy`)
  and the endpoint is fixed to `logbook.${DOMAIN_NAME}`, so nothing depends on the release name
  PCAI assigns. Only `${NAMESPACE}` (Alloy push URL) is substituted on import; for a direct
  `helm install`, override `alloy.alloy.extraEnv[1].value`.
- Verify `podLabels`/`podAnnotations` keys still exist in the Loki/Alloy chart versions pulled
  by `helm dependency update` (`helm template … | grep -B2 hpe-ezua/type` must hit the
  StatefulSet, gateway Deployment and DaemonSet). If a key moved, fall back to a scoped
  Kyverno mutate policy.
- Images to mirror for air-gapped clusters: `grafana/loki`, `grafana/alloy`,
  `nginxinc/nginx-unprivileged`.
- On first start Alloy reads each container log from the beginning; Loki rejects lines older
  than `reject_old_samples_max_age` (7 days) with HTTP 400 "timestamp too old". This is a
  one-time burst and harmless - the last 7 days and everything new is ingested.
- PCAI does not allow re-uploading a chart with the same name and version; bump `version`
  in Chart.yaml (e.g. `0.1.1`) after a failed import.
