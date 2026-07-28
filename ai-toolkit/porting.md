
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