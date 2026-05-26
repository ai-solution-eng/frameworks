# Diff Summary

## Changed Files

- `_helpers.tpl`
- `application.yaml`
- `values.yaml`

## Added Files

The following files have been added to the original helm chart.

- `kyverno.yaml`
- `virtualservice.yaml`

## Detailed Changes

### `values.yaml`
- The entire `ezua:` configuration block has been removed.
- `replica.replicaCount` changed from `1` to `3`.

### `_helpers.tpl`
The following custom Redis helper template definitions were added:
- `redis.name`
- `redis.fullname`
- `redis.chart`
- `redis.labels`
- `redis.selectorLabels`

### `application.yaml`
- Two includes of `redis.labels` were added from metadata labels.


## Net Effect

- The newer `25.5.5` chart contained extra platform-specific customizations, including the `ezua` block, a Kyverno policy, an Istio VirtualService, and additional Redis label helpers — all of which are absent in the original Bitnami version.