# A Helm chart for NeMo Core service

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

For deployment guide, see [Admin Setup](https://docs.nvidia.com/nemo/microservices/latest/set-up/index.html) in the NeMo Microservices documentation.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| api.affinity | object | `{}` |  |
| api.annotations | object | `{}` |  |
| api.autoscaling.enabled | bool | `false` |  |
| api.autoscaling.maxReplicas | int | `2` |  |
| api.autoscaling.minReplicas | int | `2` |  |
| api.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| api.env | object | `{}` |  |
| api.livenessProbe.failureThreshold | int | `3` |  |
| api.livenessProbe.httpGet.path | string | `"/health"` |  |
| api.livenessProbe.httpGet.port | string | `"http"` |  |
| api.livenessProbe.periodSeconds | int | `10` |  |
| api.livenessProbe.timeoutSeconds | int | `5` |  |
| api.nodeSelector | object | `{}` |  |
| api.podAnnotations | object | `{}` |  |
| api.podLabels | object | `{}` |  |
| api.podSecurityContext.fsGroup | int | `1000` |  |
| api.readinessProbe.failureThreshold | int | `3` |  |
| api.readinessProbe.httpGet.path | string | `"/health"` |  |
| api.readinessProbe.httpGet.port | string | `"http"` |  |
| api.readinessProbe.periodSeconds | int | `10` |  |
| api.readinessProbe.timeoutSeconds | int | `5` |  |
| api.replicaCount | int | `2` |  |
| api.resources | object | `{}` |  |
| api.securityContext | object | `{}` |  |
| api.service.port | int | `8000` |  |
| api.service.type | string | `"ClusterIP"` |  |
| api.serviceAccount.annotations | object | `{}` |  |
| api.serviceAccount.automount | bool | `true` |  |
| api.serviceAccount.create | bool | `true` |  |
| api.serviceAccount.name | string | `""` |  |
| api.tolerations | list | `[]` |  |
| config.inference_gateway | object | `{"host":"0.0.0.0","port":8000,"refresh_model_cache_interval_sec":3}` | inference_gateway is the configuration specific to inference request routing |
| config.inference_gateway.host | string | `"0.0.0.0"` | host is the host the inference gateway service will listen on |
| config.inference_gateway.port | int | `8000` | port is the port the inference gateway service will listen on |
| config.inference_gateway.refresh_model_cache_interval_sec | int | `3` | refresh_model_cache_interval_sec is how frequently to refresh the internal model cache |
| config.jobs | object | `{"enabled_backends":{"volcano":false},"executors":[{"backend":"kubernetes_job","profile":"default","provider":"cpu"},{"backend":"kubernetes_job","profile":"default","provider":"gpu"}],"port":8000,"storage":{"accessModes":["ReadWriteMany"],"existingPersistentVolumeName":"","size":"200Gi","storageClass":"","volumePermissionsImage":"busybox"},"ttl_seconds_after_finished":10800}` | jobs is the configuration specific to executing jobs on the platform |
| config.jobs.enabled_backends | object | `{"volcano":false}` | enabled_backends is the configuration for enabling job execution backends. On Kubernetes, kubernetes_job is always enabled, while other backends can be optionally enabled in this section. |
| config.jobs.enabled_backends.volcano | bool | `false` | Enable Volcano jobs backend |
| config.jobs.port | int | `8000` | port is the port the jobs service will listen on |
| config.jobs.storage | object | `{"accessModes":["ReadWriteMany"],"existingPersistentVolumeName":"","size":"200Gi","storageClass":"","volumePermissionsImage":"busybox"}` | storage config for the persistent volume claim that is shared by jobs on the platform |
| config.jobs.storage.accessModes | list | `["ReadWriteMany"]` | accessModes for the persistent volume claim. This should include `ReadWriteMany` to ensure multiple job pods can write to the volume concurrently. |
| config.jobs.storage.existingPersistentVolumeName | string | `""` | If set, pods will mount this persistent volume for job-scoped storage and we will not create a new persistent volume claim. |
| config.jobs.storage.size | string | `"200Gi"` | size of the persistent volume claim used for jobs storage |
| config.jobs.storage.storageClass | string | `""` | Which storageClass to use when creating a new persistent volume claim. Leaving as empty string will use the cluster's default storageClass. |
| config.jobs.storage.volumePermissionsImage | string | `"busybox"` | volumePermissionsImage is the image used to set permissions on the volume |
| config.jobs.ttl_seconds_after_finished | int | `10800` | ttl_seconds_after_finished is the time to live in seconds for finished jobs before they are cleaned up |
| config.models | object | `{"controller":{"interval_seconds":10,"sleep_seconds":5},"database":{"host":"","name":"","password":"","passwordExistingSecret":{"key":"","name":""},"port":"","user":""},"host":"0.0.0.0","port":8000}` | models is the configuration specific to model management on the platform |
| config.models.controller | object | `{"interval_seconds":10,"sleep_seconds":5}` | controller configuration for the models service |
| config.models.database | object | `{"host":"","name":"","password":"","passwordExistingSecret":{"key":"","name":""},"port":"","user":""}` | override database configuration for the models service |
| config.models.host | string | `"0.0.0.0"` | host is the host the models service will listen on |
| config.models.port | int | `8000` | port is the port the models service will listen on |
| config.platform | object | `{"base_url":"","enable_service_account_auth":true,"host":"0.0.0.0","port":8000}` | platform is the global platform configuration which is shared across all services |
| config.platform.base_url | string | `""` | base_url is the base URL for the platform. If not set, it will default to the core service URL |
| config.platform.enable_service_account_auth | bool | `true` | enable_service_account_auth enables service account token authentication in-between services |
| config.platform.host | string | `"0.0.0.0"` | host is the host the consolidated core API server will listen on |
| config.platform.port | int | `8000` | port is the port the consolidated core API server will listen on |
| controller.affinity | object | `{}` |  |
| controller.annotations | object | `{}` |  |
| controller.env | object | `{}` |  |
| controller.livenessProbe.failureThreshold | int | `3` |  |
| controller.livenessProbe.httpGet.path | string | `"/health/live"` |  |
| controller.livenessProbe.httpGet.port | string | `"http"` |  |
| controller.livenessProbe.periodSeconds | int | `10` |  |
| controller.livenessProbe.timeoutSeconds | int | `5` |  |
| controller.nodeSelector | object | `{}` |  |
| controller.podAnnotations | object | `{}` |  |
| controller.podLabels | object | `{}` |  |
| controller.podSecurityContext.fsGroup | int | `1000` |  |
| controller.readinessProbe.failureThreshold | int | `3` |  |
| controller.readinessProbe.httpGet.path | string | `"/health/ready"` |  |
| controller.readinessProbe.httpGet.port | string | `"http"` |  |
| controller.readinessProbe.periodSeconds | int | `10` |  |
| controller.readinessProbe.timeoutSeconds | int | `5` |  |
| controller.resources | object | `{}` |  |
| controller.securityContext | object | `{}` |  |
| controller.serviceAccount.annotations | object | `{}` |  |
| controller.serviceAccount.automount | bool | `true` |  |
| controller.serviceAccount.create | bool | `true` |  |
| controller.serviceAccount.name | string | `""` |  |
| controller.tolerations | list | `[]` |  |
| databaseMigrations.affinity | object | `{}` |  |
| databaseMigrations.annotations | object | `{}` |  |
| databaseMigrations.enabled | bool | `true` | Enable or disable database migrations job |
| databaseMigrations.nodeSelector | object | `{}` |  |
| databaseMigrations.podAnnotations | object | `{}` |  |
| databaseMigrations.podLabels | object | `{}` |  |
| databaseMigrations.podSecurityContext.fsGroup | int | `1000` |  |
| databaseMigrations.resources | object | `{}` |  |
| databaseMigrations.restartPolicy | string | `"OnFailure"` |  |
| databaseMigrations.securityContext | object | `{}` |  |
| databaseMigrations.tolerations | list | `[]` |  |
| externalDatabase.database | string | `"jobs"` | The database for the external database. |
| externalDatabase.existingSecret | string | `""` | The existing secret for the external database. |
| externalDatabase.existingSecretPasswordKey | string | `""` | The existing secret password key for the external database. |
| externalDatabase.host | string | `"localhost"` | The host for an external database. |
| externalDatabase.port | int | `5432` | The port for the external database. |
| externalDatabase.uriSecret | object | `{"key":"","name":""}` | The name for the external database secret. |
| externalDatabase.user | string | `"nemo"` | The user for the external database. |
| global.imagePullSecrets | list | `[]` |  |
| global.platformConfigmapName | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"nvcr.io/nvidia/nemo-microservices/nmp-core"` |  |
| image.tag | string | `""` |  |
| imagePullSecrets | list | `[]` | Specifies the list of secret names that are needed |
| logcollector.affinity | object | `{}` |  |
| logcollector.annotations | object | `{}` |  |
| logcollector.autoscaling.enabled | bool | `false` |  |
| logcollector.autoscaling.maxReplicas | int | `1` |  |
| logcollector.autoscaling.minReplicas | int | `1` |  |
| logcollector.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| logcollector.command[0] | string | `"/fluent-bit/bin/fluent-bit"` |  |
| logcollector.command[1] | string | `"-c"` |  |
| logcollector.command[2] | string | `"/fluent-bit/etc/fluent-bit.yaml"` |  |
| logcollector.env | object | `{}` |  |
| logcollector.image.pullPolicy | string | `"IfNotPresent"` |  |
| logcollector.image.repository | string | `"fluent/fluent-bit"` |  |
| logcollector.image.tag | string | `"4.0.7"` |  |
| logcollector.livenessProbe.failureThreshold | int | `3` |  |
| logcollector.livenessProbe.initialDelaySeconds | int | `5` |  |
| logcollector.livenessProbe.periodSeconds | int | `10` |  |
| logcollector.livenessProbe.tcpSocket.port | int | `4318` |  |
| logcollector.livenessProbe.timeoutSeconds | int | `5` |  |
| logcollector.nodeSelector | object | `{}` |  |
| logcollector.podAnnotations | object | `{}` |  |
| logcollector.podLabels | object | `{}` |  |
| logcollector.podSecurityContext.fsGroup | int | `1000` |  |
| logcollector.readinessProbe.failureThreshold | int | `3` |  |
| logcollector.readinessProbe.httpGet.path | string | `"/api/v1/health"` |  |
| logcollector.readinessProbe.httpGet.port | int | `2020` |  |
| logcollector.readinessProbe.initialDelaySeconds | int | `5` |  |
| logcollector.readinessProbe.periodSeconds | int | `5` |  |
| logcollector.readinessProbe.timeoutSeconds | int | `3` |  |
| logcollector.replicaCount | int | `1` |  |
| logcollector.resources | object | `{}` |  |
| logcollector.securityContext | object | `{}` |  |
| logcollector.service.port | int | `4318` |  |
| logcollector.service.type | string | `"ClusterIP"` |  |
| logcollector.serviceAccount.annotations | object | `{}` |  |
| logcollector.serviceAccount.automount | bool | `true` |  |
| logcollector.serviceAccount.create | bool | `true` |  |
| logcollector.serviceAccount.name | string | `""` |  |
| logcollector.tolerations | list | `[]` |  |
| logging.sidecar.enabled | bool | `true` |  |
| logging.sidecar.image.repository | string | `"fluent/fluent-bit"` |  |
| logging.sidecar.image.tag | string | `"4.0.7"` |  |
| platformConfigmapName | string | `"nemo-platform-config"` |  |
| postgresql.auth.database | string | `"jobs"` |  |
| postgresql.auth.password | string | `"nemo"` |  |
| postgresql.auth.postgresPassword | string | `"nemo"` |  |
| postgresql.auth.username | string | `"nemo"` |  |
| postgresql.enabled | bool | `true` |  |
| postgresql.persistence.enabled | bool | `true` |  |
| postgresql.persistence.size | string | `"10Gi"` |  |
| postgresql.service.ports.postgresql | int | `5432` |  |