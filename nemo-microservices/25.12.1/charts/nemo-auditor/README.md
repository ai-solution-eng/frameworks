# A Helm chart for NeMo Auditor service

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

For deployment guide, see [Admin Setup](https://docs.nvidia.com/nemo/microservices/latest/set-up/index.html) in the NeMo Microservices documentation.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| auditorApiKeysSecretName | string | `"auditor-api-keys"` |  |
| autoscaling.enabled | bool | `false` |  |
| autoscaling.maxReplicas | int | `1` |  |
| autoscaling.minReplicas | int | `1` |  |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| config | object | `{}` | Service configuration for NeMo Auditor microservice. |
| env | object | `{}` |  |
| externalDatabase | object | `{"database":"auditor","existingSecret":"","existingSecretPasswordKey":"","host":"","port":5432,"uriSecret":{"key":"","name":""},"user":"nemo"}` | External PostgreSQL configuration. |
| externalDatabase.database | string | `"auditor"` | The database name. |
| externalDatabase.existingSecret | string | `""` | The name of an existing secret to use for PostgreSQL credentials. |
| externalDatabase.existingSecretPasswordKey | string | `""` | The name of an existing secret key to use for PostgreSQL credentials. |
| externalDatabase.host | string | `""` | The database host. |
| externalDatabase.port | int | `5432` | The database port. |
| externalDatabase.user | string | `"nemo"` | The database user. |
| global.platformConfigmapName | string | `""` | Set to an empty string in the component chart |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"nvcr.io/nvidia/nemo-microservices/auditor"` |  |
| image.tag | string | `""` |  |
| livenessProbe.failureThreshold | int | `100` |  |
| livenessProbe.httpGet.path | string | `"/health/live"` |  |
| livenessProbe.httpGet.port | string | `"http"` |  |
| livenessProbe.initialDelaySeconds | int | `0` |  |
| livenessProbe.periodSeconds | int | `10` |  |
| livenessProbe.timeoutSeconds | int | `600` |  |
| nodeSelector | object | `{}` |  |
| platformConfigmapName | string | `"nemo-platform-config"` | The name of the ConfigMap that contains platform configuration. This is only used in the subcomponent chart. |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext.fsGroup | int | `1000` |  |
| postgresql.auth.database | string | `"auditor"` |  |
| postgresql.auth.password | string | `"nemo"` |  |
| postgresql.auth.postgresPassword | string | `"nemo"` |  |
| postgresql.auth.username | string | `"nemo"` |  |
| postgresql.enabled | bool | `true` |  |
| postgresql.nameOverride | string | `"auditdb"` |  |
| postgresql.persistence.enabled | bool | `true` |  |
| postgresql.persistence.size | string | `"10Gi"` |  |
| postgresql.service.ports.postgresql | int | `5432` |  |
| readinessProbe.failureThreshold | int | `100` |  |
| readinessProbe.httpGet.path | string | `"/health/ready"` |  |
| readinessProbe.httpGet.port | string | `"http"` |  |
| readinessProbe.initialDelaySeconds | int | `0` |  |
| readinessProbe.periodSeconds | int | `10` |  |
| readinessProbe.timeoutSeconds | int | `600` |  |
| replicaCount | int | `1` |  |
| resources | object | `{}` |  |
| securityContext | object | `{}` |  |
| service.port | int | `5000` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automount | bool | `true` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |