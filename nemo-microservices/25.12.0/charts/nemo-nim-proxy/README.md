# NeMo NIM Proxy Microservice Helm Chart

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

For deployment guide, see [Admin Setup](https://docs.nvidia.com/nemo/microservices/latest/set-up/index.html) in the NeMo Microservices documentation.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Specifies affinity settings for the deployment. To learn more, refer to [Affinity and Anti-Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity) in the Kubernetes documentation. |
| autoscaling.enabled | bool | `false` | Whether to enable horizontal pod autoscaling for the NIM Proxy microservice. |
| autoscaling.maxReplicas | int | `100` | The maximum number of replicas for the NIM Proxy microservice. |
| autoscaling.minReplicas | int | `1` | The minimum number of replicas for the NIM Proxy microservice. |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | The target CPU utilization percentage for the NIM Proxy microservice. |
| env | object | `{}` | Additional environment variables to pass to containers. The format is `NAME: value` or `NAME: valueFrom: {object}`. |
| fullnameOverride | string | `""` | String to fully override the name on resulting Kubernetes objects when the NIM Proxy microservice is deployed. |
| image.pullPolicy | string | `"IfNotPresent"` | The container image pull policy for the NIM Proxy container. |
| image.repository | string | `"nvcr.io/nvidia/nemo-microservices/nim-proxy"` | The repository of the NIM Proxy container image. |
| image.tag | string | `""` | The container image tag. If not set, the default value is `appVersion` from the `Chart.yaml` file. |
| imagePullSecrets | list | `[]` | Image pull secrets for accessing the NGC container registry. |
| livenessProbe.httpGet.path | string | `"/health"` | The HTTP path for the Kubernetes liveness probe. Do not change this. |
| livenessProbe.httpGet.port | string | `"http"` | The port name for the Kubernetes liveness probe. Do not change this. |
| monitoring | object | `{"enabled":true,"interval":"30s","path":"/v1/metrics","scheme":"http"}` | Prometheus metrics collection configuration for monitoring the NIM Proxy microservice. To enable this, you should install the Prometheus operator before deploying the NIM Proxy microservice. |
| monitoring.enabled | bool | `true` | Whether to enable monitoring for the NIM Proxy microservice. |
| monitoring.interval | string | `"30s"` | The scrape interval for monitoring. |
| monitoring.path | string | `"/v1/metrics"` | The metrics path for monitoring. |
| monitoring.scheme | string | `"http"` | The scheme for monitoring. |
| nameOverride | string | `""` | String to partially override name on resulting Kubernetes objects when the NIM Proxy microservice is deployed. |
| nimNamespace | string | `""` | Specifies a namespace to restrict the NIM Proxy microservice to watch NIMs in. Leave it empty to watch all namespaces. |
| nodeSelector | object | `{}` | Specifies labels to ensure that the microservice is deployed only on certain nodes. To learn more, refer to [Node Selector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector) in the Kubernetes documentation. |
| podAnnotations | object | `{}` | Pod annotations. |
| podDisruptionBudget | object | `{"enabled":false,"maxUnavailable":"","minAvailable":""}` | Pod Disruption Budget configuration for the NIM Proxy microservice. This helps maintain high availability during voluntary disruptions like node drains or upgrades. To learn more, refer to [Pod Disruption Budget](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/) in the Kubernetes documentation. |
| podDisruptionBudget.enabled | bool | `false` | Whether to enable the Pod Disruption Budget for the NIM Proxy microservice. |
| podDisruptionBudget.maxUnavailable | string | `""` | The maximum number of pods that can be unavailable during a disruption. Cannot be used simultaneously with minAvailable. |
| podDisruptionBudget.minAvailable | string | `""` | The minimum number of pods that must be available during a disruption. Cannot be used simultaneously with maxUnavailable. |
| podLabels | object | `{}` | Pod labels. |
| podSecurityContext | object | `{}` | Pod security context. Use the default settings, unless you understand what changes in the pod security context settings you want to apply. |
| readinessProbe.httpGet.path | string | `"/health"` | The HTTP path for the Kubernetes readiness probe. Do not change this. |
| readinessProbe.httpGet.port | string | `"http"` | The port name for the Kubernetes readiness probe. Do not change this. |
| replicaCount | int | `1` | The number of replicas for the NeMo NIM Proxy service. |
| resources | object | `{}` | Configures Kubernetes resource requests and limits for the NIM Proxy microservice. Use the default settings and leave it with the empty object as is, unless you understand what changes you want to make. |
| securityContext | object | `{"readOnlyRootFilesystem":true}` | Security context. Use the default settings, unless you understand what changes in the security context settings you want to apply. |
| securityContext.readOnlyRootFilesystem | bool | `true` | Whether to run with a read-only root filesystem. |
| service.main.port | int | `8000` | The port of the main service. |
| service.main.type | string | `"ClusterIP"` | The type of the main service. |
| service.metricsPort.port | int | `8001` | The port of the metrics service. |
| service.metricsPort.type | string | `"ClusterIP"` | The type of the metrics service. |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account. |
| serviceAccount.automount | bool | `true` | Whether to automatically mount a ServiceAccount's API credentials. |
| serviceAccount.create | bool | `true` | Whether to create a service account for the NIM Proxy microservice. |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is `true`, a name is generated using the full name template. |
| tolerations | list | `[]` | Specifies tolerations for pod assignment. To learn more, refer to [Taint and Toleration](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) in the Kubernetes documentation. |
| volumeMounts | list | `[]` | Additional volume mounts for the NIM Proxy microservice. Use the default settings and leave it with the empty list as is, unless you understand what changes you want to make. |
| volumes | list | `[]` | Additional volumes for the NIM Proxy microservice. Use the default settings and leave it with the empty list as is, unless you understand what changes you want to make. |