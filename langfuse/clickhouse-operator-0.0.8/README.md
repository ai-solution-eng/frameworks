# ClickHouse Kubernetes Operator

Cluster-wide prerequisite for **Langfuse chart v2.x**. Install once per cluster.

- **Chart:** `oci://ghcr.io/clickhouse/clickhouse-operator-helm`
- **Version:** `0.0.8`
- **Namespace:** `clickhouse-operator` (its own)
- **Scope:** cluster-wide (ClusterRole)

## Why this is needed

Langfuse chart **v2.0.0** replaced every bundled Bitnami sub-chart. ClickHouse
stopped being a StatefulSet that the chart builds itself, and became a
**Custom Resource** (`ClickHouseCluster`) that this operator fulfils.

Without the operator installed, the Langfuse chart fails its own preflight:

```
ClickHouse operator CRDs not found (clickhouse.com/v1alpha1/ClickHouseCluster).
```

## Install

```bash
helm install clickhouse-operator \
  oci://ghcr.io/clickhouse/clickhouse-operator-helm \
  --version 0.0.8 \
  --namespace clickhouse-operator --create-namespace \
  -f values.yaml

# verify
kubectl wait --for=condition=Established \
  crd/clickhouseclusters.clickhouse.com crd/keeperclusters.clickhouse.com \
  --timeout=120s

kubectl get pods -n clickhouse-operator
```

## What it does NOT touch

- Your existing `langfuse` namespace — the Bitnami ClickHouse keeps running untouched.
- Other applications. The operator only watches `clickhouse.com` objects.
- Its admission webhooks are scoped to `clickhouse.com` only and use
  `failurePolicy: Ignore`, so a broken operator cannot block other workloads.

It is inert until a `ClickHouseCluster` object appears.

## Upgrade

```bash
helm upgrade clickhouse-operator \
  oci://ghcr.io/clickhouse/clickhouse-operator-helm \
  --version <new> --namespace clickhouse-operator
```

Pin the version explicitly. The operator is described upstream as alpha-quality;
read its release notes before bumping.
