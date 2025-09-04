# NeMo Guardrails Microservice Helm Chart

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

For deployment guide, see [Admin Setup](https://docs.nvidia.com/nemo/microservices/latest/set-up/index.html) in the NeMo Microservices documentation.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Specifies affinity settings for the deployment. To learn more, refer to the [Affinity and Anti-Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity) in the Kubernetes documentation. |
| autoscaling | object | `{"enabled":false,"maxReplicas":100,"minReplicas":1,"targetCPUUtilizationPercentage":80}` | Specifies autoscaling configurations for the deployment. |
| autoscaling.enabled | bool | `false` | Whether to enable horizontal pod autoscaler. |
| autoscaling.maxReplicas | int | `100` | The maximum number of replicas for the deployment. |
| autoscaling.minReplicas | int | `1` | The minimum number of replicas for the deployment. |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | The target CPU utilization percentage. |
| configStore.nfs.enabled | bool | `false` | Whether to enable the use of an NFS persistent volume for the configuration store. |
| configStore.nfs.mountPath | string | `"/config-store"` | The path where the NFS volume will be mounted inside the container. |
| configStore.nfs.path | string | `"/path/to/nfs/share"` | The path to the root of the Configuration Store folder. |
| configStore.nfs.server | string | `"nfs-server.example.com"` | The address of the NFS server. |
| configStore.nfs.storageClass | string | `"standard"` | The storage class for the PV and PVC. |
| env | object | `{"CONFIG_STORE_PATH":"/app/services/guardrails/config-store","DEFAULT_CONFIG_ID":"default","DEFAULT_LLM_PROVIDER":"nim","DEMO":"False","GUARDRAILS_HOST":"0.0.0.0","GUARDRAILS_PORT":"7331","NEMO_GUARDRAILS_SERVER_ALLOWED_ORIGINS":"*","NEMO_GUARDRAILS_SERVER_ENABLE_CORS":"False","NIM_ENDPOINT_URL":"https://integrate.api.nvidia.com/v1"}` | Environment variables for the container. |
| external.entityStore.endpoint | string | `"http://nemo-entity-store:8000"` | The external URL of the NeMo Entity Store microservice. |
| externalDatabase | object | `{"database":"","existingSecret":"","existingSecretPasswordKey":"","host":"","port":"","uriSecret":{"key":"","name":""},"user":""}` | External PostgreSQL configuration. |
| externalDatabase.database | string | `""` | The name of the database for the NeMo Guardrails service. |
| externalDatabase.existingSecret | string | `""` | The name of an existing secret resource containing the database credentials. |
| externalDatabase.existingSecretPasswordKey | string | `""` | The name of an existing secret key containing the database credentials. |
| externalDatabase.host | string | `""` | The database host. |
| externalDatabase.port | string | `""` | The database port number. |
| externalDatabase.uriSecret.key | string | `""` | The key within the existing secret that includes a full database URI. |
| externalDatabase.uriSecret.name | string | `""` | The name of an existing secret that includes a full database URI. |
| externalDatabase.user | string | `""` | The username for the NeMo Guardrails service. |
| fsGroup | string | `""` | Specifies the file system owner group id. |
| fullnameOverride | string | `""` | Overrides the full chart name. |
| guardrails | object | `{"nvcfAPIKeySecretName":""}` | Kubernetes secret containing NVIDIA_API_KEY for Guardrails to use Nemoguard NIMS on NVCF |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy for the NeMo Guardrails container image. |
| image.repository | string | `"nvcr.io/nvidia/nemo-microservices/guardrails"` | The repository location of the NeMo Guardrails container image. |
| image.tag | string | `""` | The tag of the NeMo Guardrails container image. |
| imagePullSecrets | list | `[{"name":"nvcrimagepullsecret"}]` | Specifies the list of secret names that are needed for the main container and any init containers. |
| ingress.annotations | object | `{}` | Additional annotations for the ingress resource. |
| ingress.className | string | `""` | The class name for the ingress resource. |
| ingress.enabled | bool | `false` | Whether to enable the ingress resource. |
| ingress.hosts | list | [] | A list of maps, each containing the keys `host` and `paths` for the ingress resource. You must specify a list for configuring ingress for the microservice. |
| ingress.tls | list | `[]` | TLS configuration for the ingress resource. |
| livenessProbe.httpGet | object | `{"path":"/v1/health","port":7331}` | The HTTP GET request to use for the liveness probe. |
| livenessProbe.initialDelaySeconds | int | `5` | The initial delay seconds for the liveness probe. |
| livenessProbe.timeoutSeconds | int | `30` | The timeout in seconds for the liveness probe. |
| nameOverride | string | `""` | Overrides the chart name. |
| nodeSelector | object | `{}` | Specifies labels to ensure that the NeMo Guardrails microservice is deployed only on certain nodes. To learn more, refer to the [Node Selector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector) in the Kubernetes documentation. |
| podAnnotations | object | `{}` | Specifies additional annotations to the main deployment pods. |
| podLabels | object | `{}` | Specifies additional labels to the main deployment pods. |
| podSecurityContext | object | `{}` | Specifies privilege and access control settings for the pod. |
| postgresql | object | `{"architecture":"standalone","auth":{"database":"nemo-guardrails","enablePostgresUser":true,"existingSecret":"","password":"guardrails","username":"guardrails"},"enabled":true,"nameOverride":"guardrailsdb","serviceAccount":{"create":true,"name":"guardrails-postgresql"}}` | PostgreSQL configuration for the NeMo Guardrails microservice. |
| postgresql.architecture | string | `"standalone"` | The architecture for the default PostgreSQL service. |
| postgresql.auth.database | string | `"nemo-guardrails"` | The name for a custom database to create. |
| postgresql.auth.enablePostgresUser | bool | `true` | Whether to assign a password to the "postgres" admin user. If disabled, remote access is blocked for this user. |
| postgresql.auth.existingSecret | string | `""` | The name of an existing secret to use for PostgreSQL credentials. |
| postgresql.auth.password | string | `"guardrails"` | The password for the PostgreSQL user. |
| postgresql.auth.username | string | `"guardrails"` | The user name to use for the PostgreSQL database. |
| postgresql.enabled | bool | `true` | Whether to install the default PostgreSQL Helm chart. If enabled, the NeMo Guardrails microservice Helm chart uses the [PostgreSQL Helm chart from Bitnami](https://github.com/bitnami/charts/blob/main/bitnami/postgresql/values.yaml) to create a PostgreSQL database. |
| postgresql.nameOverride | string | `"guardrailsdb"` | The name override for the Guardrails PostgreSQL database. |
| postgresql.serviceAccount.create | bool | `true` | Specifies whether to create a new service account for PostgreSQL. |
| postgresql.serviceAccount.name | string | `"guardrails-postgresql"` | The name of the service account for PostgreSQL. |
| readinessProbe.httpGet | object | `{"path":"/v1/health/ready","port":7331}` | The HTTP GET request to use for the readiness probe. |
| readinessProbe.initialDelaySeconds | int | `5` | The initial delay seconds for the readiness probe. |
| readinessProbe.timeoutSeconds | int | `30` | The timeout in seconds for the readiness probe. |
| replicaCount | int | `1` | The number of replicas for the NeMo Guardrails microservice deployment. |
| resources | object | `{}` | Specifies resource configurations for the deployment. |
| runAsGroup | string | `""` | Specifies the group ID for the pod. |
| securityContext | object | `{}` | Specifies security context for the container. |
| service | object | `{"port":7331,"type":"ClusterIP"}` | Specifies the service type and the port for the deployment. |
| serviceAccount.annotations | object | `{}` | Annotations to be added to the service account. |
| serviceAccount.automount | bool | `true` | Whether to automatically mount the service account token. |
| serviceAccount.create | bool | `true` | Whether to create a service account for the NeMo Guardrails microservice. |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| tolerations | list | `[]` | Specifies tolerations for pod assignment. To learn more, refer to the [Taint and Toleration](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) in the Kubernetes documentation. |