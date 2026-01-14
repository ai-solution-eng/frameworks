# A Helm chart for NeMo Data Designer service

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

For deployment guide, see [Admin Setup](https://docs.nvidia.com/nemo/microservices/latest/set-up/index.html) in the NeMo Microservices documentation.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity configuration for the deployment. |
| autoscaling | object | `{"enabled":false,"maxReplicas":10,"minReplicas":1,"targetCPUUtilizationPercentage":80}` | Autoscaling configuration. |
| config | object | `{"default_model_configs":[],"log_level":"INFO","model_provider_registry":{"default":"nimproxy","providers":[{"endpoint":"http://nemo-nim-proxy:8000/v1","name":"nimproxy"}]},"port":8000,"preview_num_records":{"default":10,"max":10},"seed_dataset_source_registry":{"sources":[{"endpoint":"http://nemo-data-store:3000/v1/hf"}]}}` | Data Designer application settings |
| config.default_model_configs | list | `[]` | A list of default model configs available in all dataset generation requests |
| config.model_provider_registry | object | `{"default":"nimproxy","providers":[{"endpoint":"http://nemo-nim-proxy:8000/v1","name":"nimproxy"}]}` | The configuration for supported model providers |
| config.preview_num_records.default | int | `10` | The default number of records to return when generating a preview dataset |
| config.preview_num_records.max | int | `10` | The maximum number of records to allow when generating a preview dataset |
| config.seed_dataset_source_registry | object | `{"sources":[{"endpoint":"http://nemo-data-store:3000/v1/hf"}]}` | The configuration for supported seed dataset sources |
| env | object | `{}` | Environment variables for the Data Designer container. |
| fullnameOverride | string | `""` | Overrides the full chart name. |
| global.platformConfigmapName | string | `""` | Set to an empty string in the component chart |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy for the NeMo Data Designer container image. |
| image.repository | string | `"nvcr.io/nvidia/nemo-microservices/data-designer"` | The repository location of the NeMo Data Designer container image. |
| image.tag | string | `""` | The tag of the NeMo Data Designer container image. |
| imagePullSecrets | list | `[]` | Specifies the list of secret names that are needed for the main container and any init containers. |
| livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/health","port":"http"},"initialDelaySeconds":30,"periodSeconds":10,"timeoutSeconds":5}` | Liveness probe configuration. |
| nameOverride | string | `""` | Overrides the chart name. |
| nodeSelector | object | `{}` | Additional node selector configuration for the deployment. |
| platformConfigmapName | string | `"nemo-platform-config"` | The name of the ConfigMap that contains platform configuration. This is only used in the subcomponent chart. |
| podAnnotations | object | `{}` | Specifies additional annotations to the main deployment pods. |
| podLabels | object | `{}` | Specifies additional labels to the main deployment pods. |
| podSecurityContext | object | `{"fsGroup":1000}` | Specifies privilege and access control settings for the pod. |
| podSecurityContext.fsGroup | int | `1000` | Specifies the file system owner group id. |
| readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/health","port":"http"},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3}` | Readiness probe configuration. |
| replicaCount | int | `1` | Number of replicas for the NeMo Data Designer deployment. |
| resources | object | `{}` | Resource requests and limits. |
| securityContext | string | `nil` | Specifies security context for the container. |
| service | object | `{"port":8000,"type":"ClusterIP"}` | Specifies the service type and the port for the deployment. |
| serviceAccount.annotations | object | `{}` | Annotations to be added to the service account. |
| serviceAccount.automount | bool | `true` | Whether to automatically mount the service account token. |
| serviceAccount.create | bool | `true` | Whether to create a service account for the NeMo Data Designer microservice. |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| serviceName | string | `"nemo-data-designer"` | The service name for the NeMo Data Designer microservice. |
| tolerations | list | `[]` | Additional tolerations for the deployment. |
| volumeMounts | list | `[]` | Additional volume mounts for the deployment. |
| volumes | list | `[]` | Additional volumes for the deployment. |