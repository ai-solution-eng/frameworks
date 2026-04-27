# Porting NeMo Microservices from 25.8.0 to 25.12.1 on PCAI

This document describes the steps taken to port the NeMo Microservices Helm chart from version 25.8.0 to 25.12.1 for deployment on HPE AI Essentials (AIE) / PCAI.

## Prerequisites

### Source Charts

- **25.8.0** (original): Downloaded from NGC
  ```bash
  helm fetch https://helm.ngc.nvidia.com/nvidia/nemo-microservices/charts/nemo-microservices-helm-chart-25.8.0.tgz \
    --username='$oauthtoken' --password=<NGC_API_KEY>
  ```

- **25.12.1** (new): Downloaded from NGC
  ```bash
  helm pull nmp/nemo-microservices-helm-chart --version 25.12.1
  ```
  Requires Helm CLI with the NGC repo configured:
  ```bash
  helm repo add nmp https://helm.ngc.nvidia.com/nvidia/nemo-microservices \
    --username='$oauthtoken' --password=<NGC_API_KEY>
  ```

### Cluster Requirements

- HPE AI Essentials (AIE) 1.9.1+
- Istio service mesh (provided by AIE)
- GPU nodes with NVIDIA drivers
- Volcano scheduler (must be installed separately — see below)

### 25.12.1 Single Change from 25.12.0

Version 25.12.1 contains exactly one change from 25.12.0: the `kube-rbac-proxy` image repository moved from `gcr.io/kubebuilder/kube-rbac-proxy` to `registry.k8s.io/kubebuilder/kube-rbac-proxy` due to Google Container Registry deprecation.

---

## Key Technical Differences: 25.8.0 → 25.12.1

### Subcharts Added and Removed

| Change | Subchart | Purpose |
|---|---|---|
| Added | `nemo-core` | Centralized Jobs API and controller (scheduler, reconciler, log collector) |
| Added | `nemo-studio-ui` | Web UI for managing projects, models, datasets, customizations, evaluations |
| Added | `nemo-data-designer` | Synthetic data generation service |
| Added | `nemo-safe-synthesizer` | Safety-focused synthetic data generation |
| Added | `nemo-intake` | Data ingestion service |
| Removed | `dgxc-admission-controller` | DGX Cloud admission webhook (not applicable to PCAI) |

### Helm Template Helper Renames

All template helpers were renamed from `nemo-microservices.*` to `nemo-platform.*`:

| 25.8.0 | 25.12.1 |
|---|---|
| `nemo-microservices.name` | `nemo-platform.name` |
| `nemo-microservices.chart` | `nemo-platform.chart` |
| `nemo-microservices.labels` | `nemo-platform.labels` |
| `nemo-microservices.fullname` | `nemo-platform.selectorLabels` |
| `nemo-microservices.selectorLabels` | `nemo-platform.selectorLabels` |

The helper `nemo-microservices.fullname` was removed entirely in 25.12.x. Any custom templates referencing it (such as the PCAI VirtualService) must be updated.

### Configuration Template Suffix Rename

GPU tier suffixes in customization config template names changed:

| 25.8.0 | 25.12.1 |
|---|---|
| `+L40` | `+40GB` |
| `+A100` | `+80GB` |

This affects the `BASE_MODEL_VERSION` parameter used in fine-tuning jobs. For example:
- 25.8.0: `v1.0.0+L40`
- 25.12.1: `v1.0.0+40GB` (L40S) or `v1.0.0+80GB` (H200/A100)

### PostgreSQL Image Changes

PostgreSQL subchart images moved from `bitnami/*` to `bitnamilegacy/*`, requiring the global setting:
```yaml
global:
  security:
    allowInsecureImages: true
```

### kube-rbac-proxy Image Registry

The `kube-rbac-proxy` image moved from `gcr.io` to `registry.k8s.io`:
- 25.8.0: `gcr.io/kubebuilder/kube-rbac-proxy:v0.15.0`
- 25.12.1: `registry.k8s.io/kubebuilder/kube-rbac-proxy:v0.15.0`

### New: Database Migration Hook

The `nemo-core` subchart introduces an Alembic database migration Job as a Helm `post-install,post-upgrade` hook. This creates the `platformjob`, `platformjobstep`, and `platformjobattempt` tables in the jobs database. The hook has `hook-delete-policy: before-hook-creation,hook-succeeded`, meaning the Job is cleaned up after success.

On PCAI, this hook may not execute reliably — manual migration is documented as a fallback in `troubleshoot_deployment.md` Issue 3.

### New: NIM Operator Default Tag

The NIM Operator default image tag is `1.14.1` in 25.12.1.

### Evaluator Image Key Renames

Evaluator image configuration keys changed from camelCase to SCREAMING_SNAKE_CASE in the evaluator subchart values.

---

## PCAI Packaging Changes

### Chart Name

Changed from `nemo-microservices` to `nemo-microservices-25121` to avoid conflicts with the PCAI admission controller when an existing NeMo deployment is present on the cluster. The admission controller (`vezappconfig.kb.io`) tracks apps by chart name — deploying two charts with the same name is rejected.

### Subchart Repository Paths

The upstream chart uses `repository: file://components/<name>` for subchart dependencies. These paths were updated to match the extracted archive structure:
```yaml
# 25.8.0 PCAI
repository: file://charts/nemo-customizer

# Upstream 25.12.1 (before fix)
repository: file://components/customizer
```

### VirtualService: Single Route → Path-Based Routing

The most significant PCAI change. The 25.8.0 VirtualService used a single catch-all route:

```yaml
# 25.8.0 — single route
http:
  - match:
      - uri:
          prefix: /
    route:
      - destination:
          host: {{ include "nemo-microservices.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
          port:
            number: 80
```

This does not work in 25.12.1 because NeMo Microservices is a multi-service architecture — each service runs as a separate Kubernetes Service with different ports. The 25.12.1 VirtualService uses path-based routing to direct traffic to the correct service:

```yaml
# 25.12.1 — path-based routing (15 routes)
http:
  - match: [{uri: {prefix: /studio}}]           → nemo-studio:3000
  - match: [{uri: {prefix: /v1/namespaces}}]    → nemo-entity-store:8000
  - match: [{uri: {prefix: /v1/projects}}]      → nemo-entity-store:8000
  - match: [{uri: {prefix: /v1/datasets}}]      → nemo-entity-store:8000
  - match: [{uri: {prefix: /v1/models}}]        → nemo-entity-store:8000
  - match: [{uri: {prefix: /v1/datastore}}]     → nemo-data-store:3000
  - match: [{uri: {prefix: /v1/hf}}]            → nemo-data-store:3000
  - match: [{uri: {regex: "/.+\\.git/.*"}}]     → nemo-data-store:3000
  - match: [{uri: {prefix: /v1/customization}}] → nemo-customizer:8000
  - match: [{uri: {prefix: /v1/evaluation}}]    → nemo-evaluator:7331
  - match: [{uri: {prefix: /v1/guardrail}}]     → nemo-guardrails:7331
  - match: [{uri: {prefix: /v1/deployment}}]    → nemo-deployment-management:8000
  - match: [{uri: {prefix: /v1/jobs}}]          → nemo-core-api:8000
  - match: [{uri: {prefix: /v2/}}]              → nemo-core-api:8000
  - match: [{uri: {prefix: /}}]                 → nemo-nim-proxy:8000 (catch-all)
```

**Route order matters.** Istio evaluates rules top-to-bottom. Specific prefixes must appear before the catch-all `/` route at the bottom.

**Routes not in the Helm chart (added manually after NIMService deployment):**

When a NIM inference endpoint is deployed via NIMService, the following routes should be added to the VirtualService manually:

| Route | Rewrite | Destination | Purpose |
|---|---|---|---|
| `/v1/models/nim` | → `/v1/models` | `<nim-service>:8000` | NIM model list (inference-ready models) |
| `/v1/chat` | (none) | `<nim-service>:8000` | Chat completions |
| `/v1/completions` | (none) | `<nim-service>:8000` | Text completions |

The `/v1/models/nim` route must come before `/v1/models` to avoid being caught by the Entity Store route.

### VirtualService Helper Reference Fix

The 25.8.0 PCAI VirtualService template referenced `{{ include "nemo-microservices.fullname" . }}`, which no longer exists in 25.12.1. Updated to use `nemo-platform.name` and explicit service hostnames.

### hpe-ezua Pod Labels

Added `hpe-ezua/app` and `hpe-ezua/type` labels to all subchart pod templates via the `podLabels` value. This enables AIE health monitoring so the app status shows "Ready" instead of "Unknown" on the AIE portal.

```yaml
# Applied to each subchart's podLabels in values.yaml
podLabels:
  hpe-ezua/app: nemo-microservices-25121
  hpe-ezua/type: vendor-service
```

### Liveness/Readiness Probe Adjustments

The default probe settings are too aggressive for the customizer and evaluator on PCAI:

| Component | Default | PCAI Setting | Reason |
|---|---|---|---|
| Customizer liveness | 30s delay, 15 failures | 300s delay, 60 failures | NGC filemap fetch takes 4-9 minutes per model |
| Customizer readiness | 30s delay, 15 failures | 300s delay, 60 failures | Same as above |
| Evaluator liveness | (default) | 120s delay, 30 failures | Startup dependencies on core services |

### Operator Configuration

The `nemo-operator` and `nim-operator` subcharts create cluster-scoped resources (ClusterRoles, CRDs). On clusters with an existing NeMo deployment, these must be disabled to avoid Helm ownership conflicts:

```yaml
# Shared cluster (existing NeMo deployment)
nim-operator:
  enabled: false
nemo-operator:
  enabled: false

# Clean cluster (no existing NeMo)
nim-operator:
  enabled: true
nemo-operator:
  enabled: true
```

### Volcano Prerequisite

In 25.8.0, Volcano was bundled as a subchart but disabled by default (`volcano.enabled: false`). In 25.12.1, the same applies. On clean clusters, Volcano must be installed manually before deploying the chart:

```bash
kubectl apply -f https://raw.githubusercontent.com/volcano-sh/volcano/v1.9.0/installer/volcano-development.yaml
```

Without Volcano, the NeMo Operator will crash with: `no matches for kind "PodGroup" in version "scheduling.volcano.sh/v1beta1"`.

---

## Post-Deploy Steps

### 1. Database Migrations

If the Helm post-install hook does not run (observable as `nemo-core-controller` in CrashLoopBackOff with `relation "platformjob" does not exist`), run migrations manually:

```bash
kubectl exec <core-api-pod> -n nemo-microservices-25121 -- \
  python -c "
from alembic.config import Config
from alembic import command
cfg = Config('/app/services/core/infrastructure/jobs/alembic.ini')
command.upgrade(cfg, 'head')
cfg2 = Config('/app/services/core/infrastructure/models/alembic.ini')
command.upgrade(cfg2, 'head')
print('Migrations complete')
"
```

The core-api container is distroless — only `python` is available (no `bash`, `sh`, or `alembic` CLI).

### 2. NIMService Deployment

NIM inference endpoints are deployed separately from the Helm chart via the `NIMService` custom resource. Key configuration points discovered during porting:

- `authSecret` must reference an Opaque secret with key `NGC_API_KEY` (e.g., `ngc-api`), not a Docker pull secret
- `NIM_PEFT_SOURCE` must include the `http://` scheme prefix for LoRA adapter auto-discovery
- The NIM training image is 18.4GB — first pull takes ~23 minutes
- `storage.pvc.volumeAccessMode` is required when `create: true`

### 3. Entity Store Model Registration

The evaluator requires models to be registered in the Entity Store with an `api_endpoint` pointing to the NIM service. This is done via the SDK after NIMService deployment.

---

## Files Modified from Upstream 25.12.1

| File | Change | Reason |
|---|---|---|
| `Chart.yaml` | `name: nemo-microservices-25121` | Unique PCAI app identity |
| `Chart.yaml` | `repository: file://charts/*` paths | Match extracted archive structure |
| `values.yaml` | `ezua:` block added | Istio VirtualService config |
| `values.yaml` | `nim-operator.enabled` / `nemo-operator.enabled` | Configurable per cluster type |
| `values.yaml` | Customizer probe overrides | Prevent CrashLoopBackOff during NGC fetch |
| `values.yaml` | Evaluator probe overrides | Prevent CrashLoopBackOff during startup |
| `values.yaml` | `podLabels` with `hpe-ezua/*` | AIE health monitoring |
| `values.yaml` | Studio `platformBaseUrl` / `nimProxyUrl` | PCAI Istio hostname |
| `templates/_hpe-ezua.tpl` | Added (from 25.8.0) | HPE ezua label helper |
| `templates/ezua/virtualService.yaml` | Rewritten | Path-based routing for multi-service architecture |
