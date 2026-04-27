# A Helm chart to install NeMo Studio UI

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
| baseRoute | string | `"studio"` | Specifies a base url or path (e.g. studio for https://domain.com/studio) |
| customizerUrl | string | `""` | The external URL of the NeMo Customizer microservice (if different from the platform base url). |
| dataStoreUrl | string | `"http://data-store.test:3000"` | The external URL of the NeMo Data Store microservice. |
| entityStoreUrl | string | `""` | The external URL of the NeMo Entity Store microservice (if different from the platform base url). |
| env | object | `{}` |  |
| evaluatorUrl | string | `""` | The external URL of the NeMo Evaluator microservice (if different from the platform base url). |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"nvcr.io/nvidian/nemo-llm/nemo-studio-ui"` |  |
| image.tag | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| livenessProbe.httpGet.path | string | `"/health"` |  |
| livenessProbe.httpGet.port | string | `"http"` |  |
| nameOverride | string | `""` |  |
| nimProxyInternalUrl | string | `"http://nemo-nim-proxy:8000"` | The internal URL of the NeMo NIM Proxy microservice. |
| nimProxyUrl | string | `"http://nim.test:3000"` | The external URL of the NeMo NIM Proxy microservice. |
| nodeSelector | object | `{}` |  |
| openTelemetry | object | `{"collectorURL":"","enabled":false,"proxyURL":"","serviceName":"nemo-studio-ui"}` | OpenTelemetry environment configuration variables for the Studio UI |
| platformBaseUrl | string | `"http://nemo.test:3000"` | The base url for platform endpoints |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| readinessProbe.httpGet.path | string | `"/ready"` |  |
| readinessProbe.httpGet.port | string | `"http"` |  |
| replicaCount | int | `1` |  |
| resources | object | `{}` |  |
| securityContext.readOnlyRootFilesystem | bool | `true` |  |
| service.port | int | `3000` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automount | bool | `true` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |
| volumeMounts[0].mountPath | string | `"/usr/share/nginx/html"` |  |
| volumeMounts[0].name | string | `"html"` |  |
| volumeMounts[1].mountPath | string | `"/var/run"` |  |
| volumeMounts[1].name | string | `"run"` |  |
| volumeMounts[2].mountPath | string | `"/tmp"` |  |
| volumeMounts[2].name | string | `"temp"` |  |
| volumes[0].emptyDir | object | `{}` |  |
| volumes[0].name | string | `"html"` |  |
| volumes[1].emptyDir | object | `{}` |  |
| volumes[1].name | string | `"run"` |  |
| volumes[2].emptyDir | object | `{}` |  |
| volumes[2].name | string | `"temp"` |  |