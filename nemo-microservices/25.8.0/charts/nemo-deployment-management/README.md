# NeMo Deployment Management Microservice Helm Chart

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

For deployment guide, see [Admin Setup](https://docs.nvidia.com/nemo/microservices/latest/set-up/index.html) in the NeMo Microservices documentation.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Specifies affinity settings for the deployment. To learn more, refer to the [Affinity and Anti-Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity) in the Kubernetes documentation. |
| autoscaling.enabled | bool | `false` | Whether to enable autoscaling for the NeMo Deployment Management microservice. |
| autoscaling.maxReplicas | int | `100` | The maximum number of replicas. |
| autoscaling.minReplicas | int | `1` | The minimum number of replicas. |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | The target CPU utilization percentage. |
| dataStore.secret.create | bool | `true` | Whether to create a secret for the data store huggingface token. If false, the secret must be created manually. |
| dataStore.secret.name | string | `"nemo-deployment-management-service-ds-hf-token"` | The name of the secret that will be created. If create is false, a secret with this name must be created manually and have the HF_TOKEN key set. |
| dataStore.url | string | `"http://nemo-data-store:3000"` | The URL for the NeMo Data Store service. |
| deployments | object | `{"autoscaling":{"enabled":false,"spec":{"maxReplicas":5,"metrics":[{"pods":{"metric":{"name":"gpu_cache_usage_perc"},"target":{"averageValue":"750m","type":"AverageValue"}},"type":"Pods"}],"minReplicas":1}},"defaultStorageClass":"","entityStoreUrl":"http://nemo-entity-store:8000","metrics":{"enabled":false},"modelPullerImage":"nvcr.io/nvidia/nemo-microservices/nds-v2-huggingface-cli:25.06","modelPullerPullSecret":"nvcrimagepullsecret","modelSyncPeriod":"30","nimImagePullSecrets":[],"nimPeftSource":"http://nemo-entity-store:8000","nimPvcSize":"25Gi"}` | Properties to configure NIM deployments for the NeMo Deployment Management microservice. |
| deployments.autoscaling.enabled | bool | `false` | Whether to enable autoscaling for the NIM deployments. |
| deployments.autoscaling.spec | object | `{"maxReplicas":5,"metrics":[{"pods":{"metric":{"name":"gpu_cache_usage_perc"},"target":{"averageValue":"750m","type":"AverageValue"}},"type":"Pods"}],"minReplicas":1}` | Autoscaling specification for the NIM deployments. |
| deployments.defaultStorageClass | string | `""` | The default storage class for NIM deployments. |
| deployments.entityStoreUrl | string | `"http://nemo-entity-store:8000"` | The URL for the NeMo Entity Store service. |
| deployments.metrics.enabled | bool | `false` | Whether to enable metrics collection for the NIM deployments. |
| deployments.modelPullerImage | string | `"nvcr.io/nvidia/nemo-microservices/nds-v2-huggingface-cli:25.06"` | The image to use for pulling models from NeMo Data Store. Must have the huggingface-cli binary installed. |
| deployments.modelPullerPullSecret | string | `"nvcrimagepullsecret"` | The pull secret used to pull the model puller image. |
| deployments.modelSyncPeriod | string | `"30"` | The period in seconds for model synchronization. |
| deployments.nimImagePullSecrets | list | `[]` | List of image pull secrets for the NIM deployments. |
| deployments.nimPeftSource | string | `"http://nemo-entity-store:8000"` | The URL for PEFT model sources (typically points to NeMo Entity Store) |
| deployments.nimPvcSize | string | `"25Gi"` | The size of the PVC for the NIM deployments. |
| env | object | `{}` | Additional environment variables to pass to the NeMo Deployment Management microservice container. The format is `NAME: value` or `NAME: valueFrom: {object}`. |
| fullnameOverride | string | `""` | String to fully override the name on resulting Kubernetes objects when the NeMo Deployment Management microservice is deployed. |
| image.pullPolicy | string | `"IfNotPresent"` | The container image pull policy for the NeMo Deployment Management container. |
| image.repository | string | `"nvcr.io/nvidia/nemo-microservices/deployment-management"` | The repository of the NeMo Deployment Management container image. |
| image.tag | string | `""` | The container image tag. If not set, the default value is `appVersion` from the `Chart.yaml` file. |
| imagePullSecrets | list | `[{"name":"nvcrimagepullsecret"}]` | Image pull secrets for accessing the NGC container registry. |
| ingress.annotations | object | `{}` | Ingress annotations. |
| ingress.className | string | `""` | The ingress class to use. |
| ingress.enabled | bool | `false` | Whether to enable the ingress controller resource. |
| ingress.hosts | list | [] | A list of maps, each containing the keys `host` and `paths` for the ingress resource. You must specify a list for configuring ingress for the microservice. |
| ingress.tls | list | `[]` | Ingress TLS configuration. |
| livenessProbe.httpGet.path | string | `"/health"` | The HTTP path for the Kubernetes liveness probe. Do not change this. |
| livenessProbe.httpGet.port | string | `"http"` | The port name for the Kubernetes liveness probe. Do not change this. |
| monitoring | object | `{"enabled":false}` | Prometheus metrics collection configuration for monitoring the NeMo Deployment Management microservice. To enable this, you should install the Prometheus operator before deploying the NeMo Deployment Management microservice. |
| monitoring.enabled | bool | `false` | Whether to enable monitoring for the NeMo Deployment Management microservice. |
| nameOverride | string | `""` | String to partially override name on resulting Kubernetes objects when the NeMo Deployment Management microservice is deployed. |
| nimNamespace | string | `""` | Specifies a namespace to restrict the NeMo Deployment Management microservice to watch NIMs in. Leave it empty to watch all namespaces. |
| nodeSelector | object | `{}` | Specifies labels to ensure that the microservice is deployed only on certain nodes. To learn more, refer to the [Node Selector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector) in the Kubernetes documentation. |
| podAnnotations | object | `{}` | Pod annotations. |
| podLabels | object | `{}` | Pod labels. |
| podSecurityContext | object | `{}` | Pod security context settings. Use the default settings, unless you understand what changes in the pod security context settings you want to apply. |
| readinessProbe.httpGet.path | string | `"/health"` | The HTTP path for the Kubernetes readiness probe. Do not change this. |
| readinessProbe.httpGet.port | string | `"http"` | The port name for the Kubernetes readiness probe. Do not change this. |
| replicaCount | int | `1` | The number of replicas for the NeMo Deployment Management service. |
| resources | object | `{}` | Configures Kubernetes resource requests and limits for the NeMo Deployment Management microservice. Use the default settings and leave it with the empty object as is, unless you understand what changes you want to make. |
| securityContext | object | `{"readOnlyRootFilesystem":true}` | Security context settings. Use the default settings, unless you understand what changes in the security context settings you want to apply. |
| securityContext.readOnlyRootFilesystem | bool | `true` | Enable read-only root filesystem. You can also add any values for [Kubernetes security context](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#securitycontext-v1-core) in this field. |
| service.deploymentPort.port | int | `8000` | The port number for the service. |
| service.deploymentPort.type | string | `"ClusterIP"` | The service type of the deployment port. |
| serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | Configures service account for RBAC for the NeMo Deployment Management microservice. Use the default setup, unless you understand what changes in RBAC settings you want to apply to the service. |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account. |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials. |
| serviceAccount.create | bool | `true` | Whether to create a service account for the NeMo Deployment Management microservice. This is for setting RBAC up. |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template. |
| tolerations | list | `[]` | Specifies tolerations for pod assignment. To learn more, refer to the [Taint and Toleration](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) in the Kubernetes documentation. |
| volumeMounts | list | `[]` | Additional volume mounts for the NeMo Deployment Management microservice. Use the default settings and leave it with the empty list as is, unless you understand what changes you want to make. |
| volumes | list | `[]` | Additional volumes for the NeMo Deployment Management microservice. Use the default settings and leave it with the empty list as is, unless you understand what changes you want to make. |