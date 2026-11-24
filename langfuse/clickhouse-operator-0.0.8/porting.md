# Porting

## values.yaml

Add PCAI labels to the operator pod so the platform recognises it as a vendor
component:

```yaml
manager:
  pod:
    labels:
      hpe-ezua/app: clickhouse-operator
      hpe-ezua/type: vendor
```

Raise the controller memory limit. The chart default is 128Mi, which is not
enough on clusters with a few hundred namespaces — the controller is OOMKilled
(exit 137) seconds after starting and the pod sits in CrashLoopBackOff.

```yaml
manager:
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 50m
      memory: 128Mi
```

## VirtualService

VirtualService is not necessary for this framework. The operator has no user
interface — it is a cluster-wide controller consumed by the Langfuse chart.

## Prerequisites

- **cert-manager must already be installed.** The chart creates a self-signed
  `Issuer` plus `Certificate` resources for its webhook and metrics TLS. PCAI
  ships cert-manager, so this is normally already satisfied.
- **Install once per cluster.** The operator watches `ClickHouseCluster` and
  `KeeperCluster` objects in every namespace. Importing the framework twice
  gives you two controllers reconciling the same resources.

## Why Langfuse needs this

Langfuse Helm chart **v2.0.0** stopped bundling ClickHouse. Instead of a
StatefulSet, it renders a `ClickHouseCluster` custom resource. This operator is
what turns that resource into the real ClickHouse pods, services and PVCs.

The Langfuse chart fails its own preflight when the CRDs are absent:

```
ClickHouse operator CRDs not found (clickhouse.com/v1alpha1/ClickHouseCluster)
```

Install order is therefore: **clickhouse-operator → langfuse**.

## Known issue: version-probe Job can hang

Before creating ClickHouse the operator runs a "version probe" Job. On clusters
with a mutating admission webhook that sets `schedulerName` on pod **updates**,
that Job never reaches `Complete` — `schedulerName` is immutable, so the Job
controller cannot remove its `batch.kubernetes.io/job-tracking` finalizer. The
operator then blocks indefinitely and no ClickHouse server is created.

Symptom — the Job stays incomplete even though its pod finished:

```
NAME                                      STATUS    COMPLETIONS
langfuse-clickhouse-version-probe-xxxxx   Running   0/1
```

Workaround — mark the Job complete manually:

```bash
kubectl patch job -n <namespace> <job-name> --subresource=status --type=json -p '[
  {"op":"replace","path":"/status/uncountedTerminatedPods","value":{"succeeded":[],"failed":[]}},
  {"op":"add","path":"/status/succeeded","value":1},
  {"op":"add","path":"/status/completionTime","value":"2026-01-01T00:00:00Z"},
  {"op":"add","path":"/status/conditions/-","value":{
    "type":"Complete","status":"True","reason":"CompletionsReached",
    "lastTransitionTime":"2026-01-01T00:00:00Z"}}
]'
```

The real fix belongs to the platform: scope the `schedulerName` mutation to
`CREATE` only.

## Notes

Download the original chart:

```bash
helm pull oci://ghcr.io/clickhouse/clickhouse-operator-helm --version 0.0.8
```

Repackage after editing `0.0.8/values.yaml`:

```bash
helm package 0.0.8 -d .
```
