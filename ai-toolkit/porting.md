
make sure in values.yaml, cpu and memory limits have been defined:
resources:
```
  limits:
    cpu: 8
    memory: 30Gi
    nvidia.com/gpu: 1
  requests:
    cpu: 4
    memory: 1Gi
    nvidia.com/gpu: 1
```

## For the version 0.1.3
AIE 1.12 introduce a few changes in kverno permissions, impacting in the resources managment, specifically when requesting GPU resources, usually we can find this error:

```text
admission webhook "validate.kyverno.svc-fail" denied the request: resource Pod/saucedo-test/comfyui-589666658-mfsq4 was blocked due to the following policies gpu-resource-validation: validate-ezua-labels: The `hpe-ezua/app` and `hpe-ezua/component` labels must be present and non-empty in the Pod spec of GPU workloads.
```

#### Fix it
add the next lines in the  `framework/templates/deployment.yaml` file, in the `spec.template.metadata.labels` section:

```yaml
        hpe-ezua/app: {{ .Chart.Name }}
        hpe-ezua/component: {{ .Chart.Name }}
        hpe-ezua/type: vendor-service
```

it should look like this:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "comfyui.fullname" . }}
  labels:
    {{- include "comfyui.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "comfyui.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "comfyui.labels" . | nindent 8 }}
        hpe-ezua/app: {{ .Chart.Name }}
        hpe-ezua/component: {{ .Chart.Name }}
        hpe-ezua/type: vendor-service
        {{- with .Values.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
...
```

Thats it now you can request GPU resources as normal in previous AIE versions.

## For the version 0.1.5
Added persistent storage. Before this, AI Toolkit stored everything on the
container filesystem, so a pod restart/reschedule lost the job database, uploaded
datasets, trained models, configs and the downloaded base-model cache.

### How AI Toolkit stores data
Based on the upstream `docker-compose.yml`
(https://github.com/ostris/ai-toolkit), these paths hold all of the state:

| Path | Contents |
| ---- | -------- |
| `/app/ai-toolkit/aitk_db.db` | SQLite DB: jobs, training queue and settings (single file) |
| `/app/ai-toolkit/datasets` | Datasets uploaded through the UI |
| `/app/ai-toolkit/output` | Checkpoints, LoRAs and samples (grows the most) |
| `/app/ai-toolkit/config` | Job config files (plus the bundled `examples/`) |
| `/root/.cache/huggingface/hub` | Downloaded base models (large) |

### What was implemented
- One PVC per path, each toggleable under `persistence.*` in `values.yaml`
  (`data`, `datasets`, `output`, `config`, `huggingface`) with `enabled`, `size`,
  `accessMode` and optional `storageClass`.
- The database is a single file whose schema is applied at image **build** time
  (`prisma db push`); the runtime start command never creates it. An empty volume
  would therefore leave the app with no tables. An `init-persistence` init
  container seeds `aitk_db.db` (and the example configs) from the image into the
  volumes on first start only, then the DB is mounted into the container with
  `subPath: aitk_db.db`. `persistence.data` is `ReadWriteOnce` because SQLite must
  only ever be written by one pod.
- `updateStrategy.type: Recreate` is set so the old pod fully releases the volumes
  before the new pod starts — this avoids two pods writing the SQLite database and
  avoids ReadWriteOnce mount conflicts during upgrades.

Disabling any `persistence.<name>.enabled` removes that PVC, its mount and (for
`data`/`config`) the matching seeding step. To use ReadWriteOnce storage for the
large volumes too, set each `accessMode` to `ReadWriteOnce` — `Recreate` keeps
that working across node reschedules.