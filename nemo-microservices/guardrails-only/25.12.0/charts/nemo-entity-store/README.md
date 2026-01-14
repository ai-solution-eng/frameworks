# NeMo Entity Store Microservice Helm Chart

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

For deployment guide, see [Admin Setup](https://docs.nvidia.com/nemo/microservices/latest/set-up/index.html) in the NeMo Microservices documentation.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Additional affinity for the deployment. |
| appConfig | object | `{}` | Additional NeMo Entity Store API server specific configs. |
| autoscaling.enabled | bool | `false` | Whether to enable autoscaling. |
| autoscaling.maxReplicas | int | `100` | The maximum number of replicas. |
| autoscaling.minReplicas | int | `1` | The minimum number of replicas. |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | The target CPU utilization percentage for autoscaling. |
| env | object | `{}` | Additional environment variables to pass to the NeMo Entity Store container. Format should be `NAME: value` or `NAME: valueFrom: {object}`. |
| externalDatabase.database | string | `"entity-store"` | The name of the database for the NeMo Entity Store service. |
| externalDatabase.existingSecret | string | `""` | The name of an existing secret resource containing the database credentials. |
| externalDatabase.existingSecretPasswordKey | string | `""` | The name of an existing secret key containing the database credentials. |
| externalDatabase.host | string | `"localhost"` | The database host. |
| externalDatabase.port | int | `5432` | The database port number. |
| externalDatabase.uriSecret.key | string | `""` | The key within the existing secret that includes a full database URI. |
| externalDatabase.uriSecret.name | string | `""` | The name of an existing secret that includes a full database URI. |
| externalDatabase.user | string | `"user"` | The username for the NeMo Entity Store service. |
| fullnameOverride | string | `""` | String to fully override name on resulting Kubernetes objects when deployed. |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy to pull the NeMo Entity Store image |
| image.repository | string | `"nvcr.io/nvidia/nemo-microservices/entity-store"` | The NeMo Entity Store image repository. |
| image.tag | string | `""` | Specifies the image tag. |
| imagePullSecrets | list | `[{"name":"nvcrimagepullsecret"}]` | List of image pull secrets. You can add multiple secrets to the list. |
| livenessProbe.failureThreshold | int | `10` | The failure threshold for the liveness probe. |
| livenessProbe.httpGet | object | `{"path":"/health","port":"http"}` | The path for the liveness probe. |
| livenessProbe.initialDelaySeconds | int | `3` | The initial delay seconds for the Kubernetes liveness probe. |
| livenessProbe.periodSeconds | int | `10` | The period seconds for the liveness probe. |
| livenessProbe.timeoutSeconds | int | `20` | The timeout seconds for the liveness probe. |
| nameOverride | string | `""` | String to partially override name on resulting Kubernetes objects when deployed. |
| nodeSelector | object | `{}` | Additional node selector configuration for the deployment. |
| openTelemetry.enabled | bool | `false` | Whether to enable OpenTelemetry integration. |
| podAnnotations | object | `{}` | Additional annotations for the NeMo Entity Store pods. |
| podLabels | object | `{}` | Additional labels for the NeMo Entity Store pods. |
| podSecurityContext | object | `{}` | The pod security context for the NeMo Entity Store pods. |
| postgresWaitImage.repository | string | `"busybox"` | The repository location of the image used to wait for postgres to start. |
| postgresWaitImage.tag | string | `"latest"` | The tag of the image used when waiting. |
| postgresql.architecture | string | `"standalone"` | The PostgreSQL architecture. Available options are `standalone` or `replication`. |
| postgresql.auth.database | string | `"entity-store"` | The name for a custom database to create. |
| postgresql.auth.enablePostgresUser | bool | `true` | Whether to assign a password to the "postgres" admin user. If disabled, remote access is blocked for this user. |
| postgresql.auth.existingSecret | string | `""` | The name of an existing secret to use for PostgreSQL credentials. |
| postgresql.auth.password | string | `"pass"` | The password for the PostgreSQL user. |
| postgresql.auth.username | string | `"user"` | The user name to use for the PostgreSQL database. |
| postgresql.enabled | bool | `true` | Whether to install the default PostgreSQL Helm chart. If enabled, the NeMo Entity Store microservice Helm chart uses the [PostgreSQL Helm chart from Bitnami](https://github.com/bitnami/charts/blob/main/bitnami/postgresql/values.yaml) to create a PostgreSQL database. |
| readinessProbe.failureThreshold | int | `20` | The failure threshold for the readiness probe. |
| readinessProbe.httpGet | object | `{"path":"/health","port":"http"}` | The path for the readiness probe. |
| readinessProbe.initialDelaySeconds | int | `10` | The initial delay seconds for the readiness probe. |
| readinessProbe.periodSeconds | int | `10` | The period seconds for the readiness probe. |
| readinessProbe.timeoutSeconds | int | `20` | The timeout seconds for the readiness probe. |
| replicaCount | int | `1` | The number of NeMo Entity Store replicas to deploy. |
| resources | object | `{}` | Requests and limits for underlying Kubernetes deployment for NeMo Entity Store. |
| securityContext | object | `{}` | The security context for the NeMo Entity Store pods. |
| service.port | int | `8000` | The service port for the NeMo Entity Store microservice. |
| service.type | string | `"ClusterIP"` | The Kubernetes service type of the NeMo Entity Store microservice. |
| serviceAccount.annotations | object | `{}` | Additional custom annotations for the service account. |
| serviceAccount.automount | bool | `true` | Whether to automatically mount the service account's API credentials. |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| tolerations | list | `[]` | Additional tolerations for the deployment. |
| volumeMounts | list | `[]` | Additional volume mounts for the deployment. |
| volumes | list | `[]` | Additional volumes for the deployment. |