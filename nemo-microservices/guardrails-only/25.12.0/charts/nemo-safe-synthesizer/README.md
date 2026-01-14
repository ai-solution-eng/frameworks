# A Helm chart for NeMo Safe Synthesizer service

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

For deployment guide, see [Admin Setup](https://docs.nvidia.com/nemo/microservices/latest/set-up/index.html) in the NeMo Microservices documentation.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| autoscaling.enabled | bool | `false` |  |
| autoscaling.maxReplicas | int | `10` |  |
| autoscaling.minReplicas | int | `1` |  |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| classify.apiKey | string | `""` |  |
| config.classify_llm_endpoint_url | string | `"https://integrate.api.nvidia.com/v1"` |  |
| config.classify_llm_model_id | string | `"qwen/qwen2.5-coder-32b-instruct"` |  |
| env.HOST_IP.valueFrom.fieldRef.fieldPath | string | `"status.hostIP"` |  |
| env.LOG_LEVEL | string | `"INFO"` |  |
| env.NEMO_SAFE_SYNTHESIZER_PORT | int | `8000` |  |
| fullnameOverride | string | `""` |  |
| global.platformConfigmapName | string | `""` | Set to an empty string in the component chart |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"nvcr.io/nvidia/nemo-microservices/safe-synthesizer-api"` |  |
| image.tag | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| jobsImage.pullPolicy | string | `"IfNotPresent"` |  |
| jobsImage.repository | string | `"nvcr.io/nvidia/nemo-microservices/safe-synthesizer"` |  |
| jobsImage.tag | string | `""` |  |
| livenessProbe.failureThreshold | int | `3` |  |
| livenessProbe.httpGet.path | string | `"/health"` |  |
| livenessProbe.httpGet.port | string | `"http"` |  |
| livenessProbe.initialDelaySeconds | int | `30` |  |
| livenessProbe.periodSeconds | int | `10` |  |
| livenessProbe.timeoutSeconds | int | `5` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| platformConfigmapName | string | `"nemo-platform-config"` | The name of the ConfigMap that contains platform configuration. This is only used in the subcomponent chart. |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext.fsGroup | int | `1000` |  |
| readinessProbe.failureThreshold | int | `3` |  |
| readinessProbe.httpGet.path | string | `"/health"` |  |
| readinessProbe.httpGet.port | string | `"http"` |  |
| readinessProbe.initialDelaySeconds | int | `5` |  |
| readinessProbe.periodSeconds | int | `5` |  |
| readinessProbe.timeoutSeconds | int | `3` |  |
| replicaCount | int | `1` |  |
| resources | object | `{}` |  |
| securityContext | string | `nil` |  |
| service.port | int | `8000` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automount | bool | `true` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |
| volumeMounts | list | `[]` |  |
| volumes | list | `[]` |  |