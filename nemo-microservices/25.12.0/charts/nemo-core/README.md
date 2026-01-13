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
| api.extraArgs | list | `[]` |  |
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
| config.jobs | object | `{"enabled_backends":{"volcano":false},"executors":[{"backend":"kubernetes_job","profile":"default","provider":"cpu"},{"backend":"kubernetes_job","profile":"default","provider":"gpu"}],"port":8000,"reconcile_interval_seconds":5,"schedule_interval_seconds":10,"storage":{"accessModes":["ReadWriteMany"],"existingPersistentVolumeName":"","size":"200Gi","storageClass":"","volumePermissionsImage":"busybox"},"ttl_seconds_after_finished":10800}` | jobs is the configuration specific to executing jobs on the platform |
| config.jobs.enabled_backends | object | `{"volcano":false}` | enabled_backends is the configuration for enabling job execution backends. On Kubernetes, kubernetes_job is always enabled, while other backends can be optionally enabled in this section. |
| config.jobs.enabled_backends.volcano | bool | `false` | Enable Volcano jobs backend |
| config.jobs.port | int | `8000` | port is the port the jobs service will listen on |
| config.jobs.reconcile_interval_seconds | int | `5` | reconcile_interval_seconds is how frequently to reconcile jobs |
| config.jobs.schedule_interval_seconds | int | `10` | schedule_interval_seconds is how frequently to schedule created jobs |
| config.jobs.storage | object | `{"accessModes":["ReadWriteMany"],"existingPersistentVolumeName":"","size":"200Gi","storageClass":"","volumePermissionsImage":"busybox"}` | storage config for the persistent volume claim that is shared by jobs on the platform |
| config.jobs.storage.accessModes | list | `["ReadWriteMany"]` | accessModes for the persistent volume claim. This should include `ReadWriteMany` to ensure multiple job pods can write to the volume concurrently. |
| config.jobs.storage.existingPersistentVolumeName | string | `""` | If set, pods will mount this persistent volume for job-scoped storage and we will not create a new persistent volume claim. |
| config.jobs.storage.size | string | `"200Gi"` | size of the persistent volume claim used for jobs storage |
| config.jobs.storage.storageClass | string | `""` | Which storageClass to use when creating a new persistent volume claim. Leaving as empty string will use the cluster's default storageClass. |
| config.jobs.storage.volumePermissionsImage | string | `"busybox"` | volumePermissionsImage is the image used to set permissions on the volume |
| config.jobs.ttl_seconds_after_finished | int | `10800` | ttl_seconds_after_finished is the time to live in seconds for finished jobs before they are cleaned up |
| config.models | object | `{"controller":{"backends":{"k8s-nim-operator":{"config":{"auth_secret":"ngc-api","datastore_auth_secret":"nemo-models-datastore-token","default_group_id":null,"default_nimservice_image":"nvcr.io/nim/nvidia/llm-nim","default_nimservice_image_tag":"1.14.1","default_node_selector":null,"default_pvc_size":"200Gi","default_resources":null,"default_startup_probe_grace_period_seconds":600,"default_storage_class":"","default_tolerations":null,"default_user_id":null,"huggingface_model_puller_image_pull_secret":"nvcrimagepullsecret","namespace":"","nim_guided_decoding_backend":"outlines","peft_refresh_interval":30,"peft_source":"http://nemo-entity-store:8000"},"enabled":true}},"interval_seconds":10,"model_deployment_garbage_collection_ttl_seconds":30},"database":{"host":"","name":"","password":"","passwordExistingSecret":{"key":"","name":""},"port":"","user":""},"datastore_secret":{"create":true,"name":"nemo-models-datastore-token"},"host":"0.0.0.0","huggingface_model_puller":{"registry":"nvcr.io","repository":"nvidia/nemo-microservices/nds-v2-huggingface-cli","tag":""},"port":8000}` | models is the configuration specific to model management on the platform |
| config.models.controller | object | `{"backends":{"k8s-nim-operator":{"config":{"auth_secret":"ngc-api","datastore_auth_secret":"nemo-models-datastore-token","default_group_id":null,"default_nimservice_image":"nvcr.io/nim/nvidia/llm-nim","default_nimservice_image_tag":"1.14.1","default_node_selector":null,"default_pvc_size":"200Gi","default_resources":null,"default_startup_probe_grace_period_seconds":600,"default_storage_class":"","default_tolerations":null,"default_user_id":null,"huggingface_model_puller_image_pull_secret":"nvcrimagepullsecret","namespace":"","nim_guided_decoding_backend":"outlines","peft_refresh_interval":30,"peft_source":"http://nemo-entity-store:8000"},"enabled":true}},"interval_seconds":10,"model_deployment_garbage_collection_ttl_seconds":30}` | controller configuration for the models service |
| config.models.controller.backends | object | `{"k8s-nim-operator":{"config":{"auth_secret":"ngc-api","datastore_auth_secret":"nemo-models-datastore-token","default_group_id":null,"default_nimservice_image":"nvcr.io/nim/nvidia/llm-nim","default_nimservice_image_tag":"1.14.1","default_node_selector":null,"default_pvc_size":"200Gi","default_resources":null,"default_startup_probe_grace_period_seconds":600,"default_storage_class":"","default_tolerations":null,"default_user_id":null,"huggingface_model_puller_image_pull_secret":"nvcrimagepullsecret","namespace":"","nim_guided_decoding_backend":"outlines","peft_refresh_interval":30,"peft_source":"http://nemo-entity-store:8000"},"enabled":true}}` | backends configuration for the models controller The backends define how model deployments are executed |
| config.models.controller.backends.k8s-nim-operator.config.auth_secret | string | `"ngc-api"` | NGC API key secret name for pulling NIM images |
| config.models.controller.backends.k8s-nim-operator.config.datastore_auth_secret | string | `"nemo-models-datastore-token"` | Existing Kubernetes secret name for DataStore authentication (HF_TOKEN) |
| config.models.controller.backends.k8s-nim-operator.config.default_group_id | string | `nil` | Default group ID for NIM containers (security context, optional) |
| config.models.controller.backends.k8s-nim-operator.config.default_nimservice_image | string | `"nvcr.io/nim/nvidia/llm-nim"` | Default NIMService image repository (used if not specified in deployment config) |
| config.models.controller.backends.k8s-nim-operator.config.default_nimservice_image_tag | string | `"1.14.1"` | Default NIMService image tag (used if not specified in deployment config) |
| config.models.controller.backends.k8s-nim-operator.config.default_node_selector | string | `nil` | Default Kubernetes node selector for all NIM deployments (optional) default_node_selector:   node-type: "gpu-node"   zone: "us-west1-a" |
| config.models.controller.backends.k8s-nim-operator.config.default_pvc_size | string | `"200Gi"` | Default PVC size for model storage (used if not specified in deployment config) |
| config.models.controller.backends.k8s-nim-operator.config.default_resources | string | `nil` | Default Kubernetes resource requirements for all NIM deployments (optional) default_resources:   requests:     cpu: "2"     memory: "8Gi"   limits:     memory: "16Gi" |
| config.models.controller.backends.k8s-nim-operator.config.default_startup_probe_grace_period_seconds | int | `600` | Default grace period in seconds for NIM startup probe (optional, defaults to 600) Set higher for large models that take longer to load (e.g., 1200 for 20 minutes) |
| config.models.controller.backends.k8s-nim-operator.config.default_storage_class | string | `""` | Default storage class for PVCs created by NIM deployments |
| config.models.controller.backends.k8s-nim-operator.config.default_tolerations | string | `nil` | Default Kubernetes tolerations for all NIM deployments (optional) default_tolerations:   - key: "nvidia.com/gpu"     operator: "Exists"     effect: "NoSchedule" |
| config.models.controller.backends.k8s-nim-operator.config.default_user_id | string | `nil` | Default user ID for NIM containers (security context, optional) |
| config.models.controller.backends.k8s-nim-operator.config.huggingface_model_puller_image_pull_secret | string | `"nvcrimagepullsecret"` | The name of the image pull secret for the modelPuller image |
| config.models.controller.backends.k8s-nim-operator.config.namespace | string | `""` | Kubernetes namespace for NIM deployments (defaults to controller's namespace if not set) |
| config.models.controller.backends.k8s-nim-operator.config.nim_guided_decoding_backend | string | `"outlines"` | Default guided decoding backend for NIM (e.g., 'outlines', 'auto', 'lm-format-enforcer') |
| config.models.controller.backends.k8s-nim-operator.config.peft_refresh_interval | int | `30` | PEFT refresh interval in seconds (only used by models that support LoRA) |
| config.models.controller.backends.k8s-nim-operator.config.peft_source | string | `"http://nemo-entity-store:8000"` | LoRA/PEFT source endpoint (only used by models that support LoRA) |
| config.models.controller.backends.k8s-nim-operator.enabled | bool | `true` | Whether this backend is enabled |
| config.models.controller.interval_seconds | int | `10` | interval in seconds for the models controller to reconcile deployments |
| config.models.controller.model_deployment_garbage_collection_ttl_seconds | int | `30` | model_deployment_garbage_collection_ttl_seconds is the time-to-live in seconds for DELETED deployments before they are permanently removed from the database |
| config.models.database | object | `{"host":"","name":"","password":"","passwordExistingSecret":{"key":"","name":""},"port":"","user":""}` | override database configuration for the models service |
| config.models.datastore_secret | object | `{"create":true,"name":"nemo-models-datastore-token"}` | DataStore authentication secret configuration |
| config.models.datastore_secret.create | bool | `true` | Whether to create the datastore secret for api authentication (HF_TOKEN) |
| config.models.datastore_secret.name | string | `"nemo-models-datastore-token"` | The name of the secret to be created |
| config.models.host | string | `"0.0.0.0"` | host is the host the models service will listen on |
| config.models.huggingface_model_puller | object | `{"registry":"nvcr.io","repository":"nvidia/nemo-microservices/nds-v2-huggingface-cli","tag":""}` | HuggingFace model puller image for weights in data store or huggingface |
| config.models.huggingface_model_puller.registry | string | `"nvcr.io"` | Registry for the HuggingFace model puller image |
| config.models.huggingface_model_puller.repository | string | `"nvidia/nemo-microservices/nds-v2-huggingface-cli"` | Repository for the HuggingFace model puller image |
| config.models.huggingface_model_puller.tag | string | `""` | Tag for the HuggingFace model puller image (defaults to Chart.appVersion) |
| config.models.port | int | `8000` | port is the port the models service will listen on |
| config.platform | object | `{"base_url":"","enable_service_account_auth":true,"host":"0.0.0.0","port":8000}` | platform is the global platform configuration which is shared across all services |
| config.platform.base_url | string | `""` | base_url is the base URL for the platform. If not set, it will default to the core service URL |
| config.platform.enable_service_account_auth | bool | `true` | enable_service_account_auth enables service account token authentication in-between services |
| config.platform.host | string | `"0.0.0.0"` | host is the host the consolidated core API server will listen on |
| config.platform.port | int | `8000` | port is the port the consolidated core API server will listen on |
| controller.affinity | object | `{}` |  |
| controller.annotations | object | `{}` |  |
| controller.env | object | `{}` |  |
| controller.extraArgs | list | `[]` |  |
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
| databaseMigrations.extraArgs | list | `[]` | Additional arguments to pass to the database migrations jobs |
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