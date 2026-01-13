# NeMo Microservices Helm Chart

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

For deployment guide, see [Admin Setup](https://docs.nvidia.com/nemo/microservices/latest/set-up/index.html) in the NeMo Microservices documentation.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| auditor.affinity | object | `{}` | Affinity rules for pod assignment. |
| auditor.auditorApiKeysSecretName | string | `"auditor-api-keys"` | Name of secret which holds mapping from api key names to the keys themselves |
| auditor.autoscaling | object | `{"enabled":false,"maxReplicas":1,"minReplicas":1,"targetCPUUtilizationPercentage":80}` | Autoscaling configuration. |
| auditor.env | object | `{}` | Environment variables to pass to containers. This is an object formatted like NAME: value or NAME: valueFrom: {object} |
| auditor.externalDatabase | object | `{"database":"auditor","existingSecret":"","existingSecretPasswordKey":"","host":"","port":5432,"user":"nemo"}` | External PostgreSQL configuration. |
| auditor.externalDatabase.database | string | `"auditor"` | The database name. |
| auditor.externalDatabase.existingSecret | string | `""` | The name of an existing secret to use for PostgreSQL credentials. |
| auditor.externalDatabase.existingSecretPasswordKey | string | `""` | The name of an existing secret key to use for PostgreSQL credentials. |
| auditor.externalDatabase.host | string | `""` | The database host. |
| auditor.externalDatabase.port | int | `5432` | The database port. |
| auditor.externalDatabase.user | string | `"nemo"` | The database user. |
| auditor.image | object | `{"pullPolicy":"IfNotPresent","repository":"nvcr.io/nvidia/nemo-microservices/auditor","tag":""}` | Container image configuration. |
| auditor.livenessProbe | object | `{"failureThreshold":100,"httpGet":{"path":"/health/live","port":"http"},"initialDelaySeconds":0,"periodSeconds":10,"timeoutSeconds":600}` | Liveness probe configuration. |
| auditor.nodeSelector | object | `{}` | Node selector for pod assignment. |
| auditor.podAnnotations | object | `{}` | Annotations to add to pods. |
| auditor.podLabels | object | `{}` | Labels to add to pods. |
| auditor.podSecurityContext | object | `{"fsGroup":1000}` | Security context for the pod. |
| auditor.postgresql | object | `{"architecture":"standalone","auth":{"database":"auditor","enablePostgresUser":true,"existingSecret":"","password":"nemo","username":"nemo"},"enabled":true,"image":{"repository":"bitnamilegacy/postgresql"},"metrics":{"image":{"repository":"bitnamilegacy/postgres-exporter"}},"nameOverride":"auditdb","persistence":{"enabled":true,"size":"10Gi"},"service":{"ports":{"postgresql":5432}},"serviceAccount":{"create":true,"name":"auditor-postgresql"},"volumePermissions":{"image":{"repository":"bitnamilegacy/os-shell"}}}` | PostgreSQL configuration for the NeMo Auditor microservice. |
| auditor.postgresql.architecture | string | `"standalone"` | The architecture for the default PostgreSQL service. |
| auditor.postgresql.auth.database | string | `"auditor"` | The name for a custom database to create. |
| auditor.postgresql.auth.enablePostgresUser | bool | `true` | Whether to assign a password to the "postgres" admin user. If disabled, remote access is blocked for this user. |
| auditor.postgresql.auth.existingSecret | string | `""` | The name of an existing secret to use for PostgreSQL credentials. |
| auditor.postgresql.auth.password | string | `"nemo"` | The password for the PostgreSQL user. |
| auditor.postgresql.auth.username | string | `"nemo"` | The user name to use for the PostgreSQL database. |
| auditor.postgresql.enabled | bool | `true` | Whether to install the default PostgreSQL Helm chart. If enabled, the NeMo Auditor microservice Helm chart uses the [PostgreSQL Helm chart from Bitnami](https://github.com/bitnami/charts/blob/main/bitnami/postgresql/values.yaml) to create a PostgreSQL database. |
| auditor.postgresql.nameOverride | string | `"auditdb"` | The name override for the Auditor PostgreSQL database. |
| auditor.postgresql.serviceAccount.create | bool | `true` | Specifies whether to create a new service account for PostgreSQL. |
| auditor.postgresql.serviceAccount.name | string | `"auditor-postgresql"` | The name of the service account for PostgreSQL. |
| auditor.readinessProbe | object | `{"failureThreshold":100,"httpGet":{"path":"/health/ready","port":"http"},"initialDelaySeconds":0,"periodSeconds":10,"timeoutSeconds":600}` | Readiness probe configuration. |
| auditor.replicaCount | int | `1` | Number of replicas for the Auditor deployment. |
| auditor.resources | object | `{}` | Resource requests and limits. |
| auditor.securityContext | object | `{}` | Security context for the container. |
| auditor.service | object | `{"port":5000,"type":"ClusterIP"}` | Service configuration. |
| auditor.serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | Service account configuration. |
| auditor.serviceAccount.annotations | object | `{}` | Annotations to add to the service account. |
| auditor.serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials. |
| auditor.serviceAccount.create | bool | `true` | Specifies whether a service account should be created. |
| auditor.serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template. |
| auditor.serviceName | string | `"nemo-auditor"` | Specifies whether to install the NeMo Auditor microservice. |
| auditor.tolerations | list | `[]` | Tolerations for pod assignment. |
| auditor.volumeMounts | list | `[]` | Additional volume mounts on the output Deployment definition. |
| auditor.volumes | list | `[]` | Additional volumes on the output Deployment definition. |
| core.api | object | This object has the following default values for the API configuration. | API service configuration for the NeMo Core microservice. |
| core.api.annotations | object | `{}` | Annotations to add to the API service deployment. |
| core.api.autoscaling | object | `{"enabled":false,"maxReplicas":100,"minReplicas":1,"targetCPUUtilizationPercentage":80}` | Specifies autoscaling configurations for the deployment. |
| core.api.autoscaling.enabled | bool | `false` | Whether to enable horizontal pod autoscaler. |
| core.api.autoscaling.maxReplicas | int | `100` | The maximum number of replicas for the deployment. |
| core.api.autoscaling.minReplicas | int | `1` | The minimum number of replicas for the deployment. |
| core.api.autoscaling.targetCPUUtilizationPercentage | int | `80` | The target CPU utilization percentage. |
| core.api.extraArgs | list | `[]` | Additional arguments to pass to the Core API service |
| core.api.livenessProbe | object | This object has the following default values for the liveness probe configuration. | Liveness probe configuration for the api service. |
| core.api.livenessProbe.failureThreshold | int | `3` | The failure threshold for the readiness probe. |
| core.api.livenessProbe.httpGet | object | `{"path":"/health","port":"http"}` | The HTTP GET request to use for the readiness probe. |
| core.api.livenessProbe.periodSeconds | int | `10` | The frequency in seconds to perform the readiness probe. |
| core.api.livenessProbe.timeoutSeconds | int | `5` | The timeout in seconds for the readiness probe. |
| core.api.podAnnotations | object | `{}` | Annotations to add to the API service pod. |
| core.api.podLabels | object | `{}` | Labels for the API service pod. |
| core.api.podSecurityContext | object | This object has the following default values for the pod security context. | Pod-level security context settings for the API service. |
| core.api.podSecurityContext.fsGroup | int | `1000` | The file system group ID to use for all containers. |
| core.api.readinessProbe | object | This object has the following default values for the readiness probe configuration. | Readiness probe configuration for the api service. |
| core.api.readinessProbe.failureThreshold | int | `3` | The failure threshold for the readiness probe. |
| core.api.readinessProbe.httpGet | object | `{"path":"/health","port":"http"}` | The HTTP GET request to use for the readiness probe. |
| core.api.readinessProbe.periodSeconds | int | `10` | The frequency in seconds to perform the readiness probe. |
| core.api.readinessProbe.timeoutSeconds | int | `5` | The timeout in seconds for the readiness probe. |
| core.api.replicaCount | int | `1` | Number of replicas for the API service. |
| core.api.securityContext | object | `{}` | Container-level security context settings for the API service. |
| core.api.service | object | This object has the following default values for the service configuration. | Service configuration for the API service. |
| core.api.service.port | int | `8000` | The port number to expose for the service. |
| core.api.service.type | string | `"ClusterIP"` | The Kubernetes service type to create. |
| core.api.serviceAccount | object | This object has the following default values for the service account configuration. | Service account configuration for the API service. |
| core.api.serviceAccount.annotations | object | `{}` | Annotations to add to the service account. |
| core.api.serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials. |
| core.api.serviceAccount.create | bool | `true` | Specifies whether a service account should be created. |
| core.api.serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template. |
| core.config.inference_gateway | object | `{"host":"0.0.0.0","port":8000,"refresh_model_cache_interval_sec":3}` | inference_gateway is the configuration specific to inference request routing |
| core.config.inference_gateway.host | string | `"0.0.0.0"` | host is the host the inference gateway service will listen on |
| core.config.inference_gateway.port | int | `8000` | port is the port the inference gateway service will listen on |
| core.config.inference_gateway.refresh_model_cache_interval_sec | int | `3` | refresh_model_cache_interval_sec is how frequently to refresh the internal model cache |
| core.config.jobs | object | `{"enabled_backends":{"volcano":false},"executors":[{"backend":"kubernetes_job","profile":"default","provider":"cpu"},{"backend":"kubernetes_job","profile":"default","provider":"gpu"}],"port":8000,"reconcile_interval_seconds":5,"schedule_interval_seconds":10,"storage":{"accessModes":["ReadWriteMany"],"existingPersistentVolumeName":"","size":"200Gi","storageClass":"","volumePermissionsImage":"busybox"},"ttl_seconds_after_finished":10800}` | jobs is the configuration specific to executing jobs on the platform |
| core.config.jobs.enabled_backends | object | `{"volcano":false}` | enabled_backends is the configuration for enabling job execution backends. On Kubernetes, kubernetes_job is always enabled, while other backends can be optionally enabled in this section. |
| core.config.jobs.enabled_backends.volcano | bool | `false` | Enable Volcano jobs backend |
| core.config.jobs.port | int | `8000` | port is the port the jobs service will listen on |
| core.config.jobs.reconcile_interval_seconds | int | `5` | reconcile_interval_seconds is how frequently to reconcile jobs |
| core.config.jobs.schedule_interval_seconds | int | `10` | schedule_interval_seconds is how frequently to schedule created jobs |
| core.config.jobs.storage | object | `{"accessModes":["ReadWriteMany"],"existingPersistentVolumeName":"","size":"200Gi","storageClass":"","volumePermissionsImage":"busybox"}` | storage config for the persistent volume claim that is shared by jobs on the platform |
| core.config.jobs.storage.accessModes | list | `["ReadWriteMany"]` | accessModes for the persistent volume claim. This should include `ReadWriteMany` to ensure multiple job pods can write to the volume concurrently. |
| core.config.jobs.storage.existingPersistentVolumeName | string | `""` | If set, pods will mount this persistent volume for job-scoped storage and we will not create a new persistent volume claim. |
| core.config.jobs.storage.size | string | `"200Gi"` | size of the persistent volume claim used for jobs storage |
| core.config.jobs.storage.storageClass | string | `""` | Which storageClass to use when creating a new persistent volume claim. Leaving as empty string will use the cluster's default storageClass. |
| core.config.jobs.storage.volumePermissionsImage | string | `"busybox"` | volumePermissionsImage is the image used to set permissions on the volume |
| core.config.jobs.ttl_seconds_after_finished | int | `10800` | ttl_seconds_after_finished is the time to live in seconds for finished jobs before they are cleaned up |
| core.config.models | object | `{"controller":{"backends":{"k8s-nim-operator":{"config":{"auth_secret":"ngc-api","datastore_auth_secret":"nemo-models-datastore-token","default_group_id":null,"default_nimservice_image":"nvcr.io/nim/nvidia/llm-nim","default_nimservice_image_tag":"1.14.1","default_node_selector":null,"default_pvc_size":"200Gi","default_resources":null,"default_startup_probe_grace_period_seconds":600,"default_storage_class":"","default_tolerations":null,"default_user_id":null,"huggingface_model_puller_image_pull_secret":"nvcrimagepullsecret","namespace":"","nim_guided_decoding_backend":"outlines","peft_refresh_interval":30,"peft_source":"http://nemo-entity-store:8000"},"enabled":true}},"interval_seconds":10,"model_deployment_garbage_collection_ttl_seconds":30},"database":{"host":"nemo-entity-storedb","name":"entity-store","password":"pass","passwordExistingSecret":{"key":"","name":""},"port":5432,"user":"user"},"datastore_secret":{"create":true,"name":"nemo-models-datastore-token"},"host":"0.0.0.0","huggingface_model_puller":{"registry":"nvcr.io","repository":"nvidia/nemo-microservices/nds-v2-huggingface-cli","tag":""},"port":8000}` | models is the configuration specific to model management on the platform |
| core.config.models.controller | object | `{"backends":{"k8s-nim-operator":{"config":{"auth_secret":"ngc-api","datastore_auth_secret":"nemo-models-datastore-token","default_group_id":null,"default_nimservice_image":"nvcr.io/nim/nvidia/llm-nim","default_nimservice_image_tag":"1.14.1","default_node_selector":null,"default_pvc_size":"200Gi","default_resources":null,"default_startup_probe_grace_period_seconds":600,"default_storage_class":"","default_tolerations":null,"default_user_id":null,"huggingface_model_puller_image_pull_secret":"nvcrimagepullsecret","namespace":"","nim_guided_decoding_backend":"outlines","peft_refresh_interval":30,"peft_source":"http://nemo-entity-store:8000"},"enabled":true}},"interval_seconds":10,"model_deployment_garbage_collection_ttl_seconds":30}` | controller configuration for the models service |
| core.config.models.controller.backends | object | `{"k8s-nim-operator":{"config":{"auth_secret":"ngc-api","datastore_auth_secret":"nemo-models-datastore-token","default_group_id":null,"default_nimservice_image":"nvcr.io/nim/nvidia/llm-nim","default_nimservice_image_tag":"1.14.1","default_node_selector":null,"default_pvc_size":"200Gi","default_resources":null,"default_startup_probe_grace_period_seconds":600,"default_storage_class":"","default_tolerations":null,"default_user_id":null,"huggingface_model_puller_image_pull_secret":"nvcrimagepullsecret","namespace":"","nim_guided_decoding_backend":"outlines","peft_refresh_interval":30,"peft_source":"http://nemo-entity-store:8000"},"enabled":true}}` | backends configuration for the models controller The backends define how model deployments are executed |
| core.config.models.controller.backends.k8s-nim-operator.config.auth_secret | string | `"ngc-api"` | NGC API key secret name for pulling NIM images |
| core.config.models.controller.backends.k8s-nim-operator.config.datastore_auth_secret | string | `"nemo-models-datastore-token"` | Existing Kubernetes secret name for DataStore authentication (HF_TOKEN) |
| core.config.models.controller.backends.k8s-nim-operator.config.default_group_id | string | `nil` | Default group ID for NIM containers (security context, optional) |
| core.config.models.controller.backends.k8s-nim-operator.config.default_nimservice_image | string | `"nvcr.io/nim/nvidia/llm-nim"` | Default NIMService image repository (used if not specified in deployment config) |
| core.config.models.controller.backends.k8s-nim-operator.config.default_nimservice_image_tag | string | `"1.14.1"` | Default NIMService image tag (used if not specified in deployment config) |
| core.config.models.controller.backends.k8s-nim-operator.config.default_node_selector | string | `nil` | Default Kubernetes node selector for all NIM deployments (optional) default_node_selector:   node-type: "gpu-node"   zone: "us-west1-a" |
| core.config.models.controller.backends.k8s-nim-operator.config.default_pvc_size | string | `"200Gi"` | Default PVC size for model storage (used if not specified in deployment config) |
| core.config.models.controller.backends.k8s-nim-operator.config.default_resources | string | `nil` | Default Kubernetes resource requirements for all NIM deployments (optional) default_resources:   requests:     cpu: "2"     memory: "8Gi"   limits:     memory: "16Gi" |
| core.config.models.controller.backends.k8s-nim-operator.config.default_startup_probe_grace_period_seconds | int | `600` | Default grace period in seconds for NIM startup probe (optional, defaults to 600) Set higher for large models that take longer to load (e.g., 1200 for 20 minutes) |
| core.config.models.controller.backends.k8s-nim-operator.config.default_storage_class | string | `""` | Default storage class for PVCs created by NIM deployments |
| core.config.models.controller.backends.k8s-nim-operator.config.default_tolerations | string | `nil` | Default Kubernetes tolerations for all NIM deployments (optional) default_tolerations:   - key: "nvidia.com/gpu"     operator: "Exists"     effect: "NoSchedule" |
| core.config.models.controller.backends.k8s-nim-operator.config.default_user_id | string | `nil` | Default user ID for NIM containers (security context, optional) |
| core.config.models.controller.backends.k8s-nim-operator.config.huggingface_model_puller_image_pull_secret | string | `"nvcrimagepullsecret"` | The name of the image pull secret for the modelPuller image |
| core.config.models.controller.backends.k8s-nim-operator.config.namespace | string | `""` | Kubernetes namespace for NIM deployments (defaults to controller's namespace if not set) |
| core.config.models.controller.backends.k8s-nim-operator.config.nim_guided_decoding_backend | string | `"outlines"` | Default guided decoding backend for NIM (e.g., 'outlines', 'auto', 'lm-format-enforcer') |
| core.config.models.controller.backends.k8s-nim-operator.config.peft_refresh_interval | int | `30` | PEFT refresh interval in seconds (only used when lora_enabled is true) |
| core.config.models.controller.backends.k8s-nim-operator.config.peft_source | string | `"http://nemo-entity-store:8000"` | LoRA/PEFT source endpoint (only used when lora_enabled is true) |
| core.config.models.controller.interval_seconds | int | `10` | interval in seconds for the models controller to reconcile deployments |
| core.config.models.controller.model_deployment_garbage_collection_ttl_seconds | int | `30` | model_deployment_garbage_collection_ttl_seconds is the time-to-live in seconds for DELETED deployments before they are permanently removed from the database |
| core.config.models.database | object | `{"host":"nemo-entity-storedb","name":"entity-store","password":"pass","passwordExistingSecret":{"key":"","name":""},"port":5432,"user":"user"}` | override database configuration for the models service |
| core.config.models.database.host | string | `"nemo-entity-storedb"` | Database host override (if empty, use value from externalDatabase or postgresql, whichever is set) |
| core.config.models.database.name | string | `"entity-store"` | Database name override (if empty, use value from externalDatabase or postgresql, whichever is set) |
| core.config.models.database.password | string | `"pass"` | Note: This will be stored in a Kubernetes secret. Mutually exclusive with passwordExistingSecret |
| core.config.models.database.passwordExistingSecret | object | `{"key":"","name":""}` | Use an existing secret for the database password (mutually exclusive with password) |
| core.config.models.database.passwordExistingSecret.key | string | `""` | Key in the secret that contains the password |
| core.config.models.database.passwordExistingSecret.name | string | `""` | Name of the existing secret containing the password |
| core.config.models.database.port | int | `5432` | Database port override (if empty, use value from externalDatabase or postgresql, whichever is set) |
| core.config.models.database.user | string | `"user"` | Database user override (if empty, use value from externalDatabase or postgresql, whichever is set) |
| core.config.models.datastore_secret | object | `{"create":true,"name":"nemo-models-datastore-token"}` | DataStore authentication secret configuration |
| core.config.models.datastore_secret.create | bool | `true` | Whether to create the datastore secret for api authentication (HF_TOKEN) |
| core.config.models.datastore_secret.name | string | `"nemo-models-datastore-token"` | The name of the secret to be created |
| core.config.models.host | string | `"0.0.0.0"` | host is the host the models service will listen on |
| core.config.models.huggingface_model_puller | object | `{"registry":"nvcr.io","repository":"nvidia/nemo-microservices/nds-v2-huggingface-cli","tag":""}` | HuggingFace model puller image for weights in data store or huggingface |
| core.config.models.huggingface_model_puller.registry | string | `"nvcr.io"` | Registry for the HuggingFace model puller image |
| core.config.models.huggingface_model_puller.repository | string | `"nvidia/nemo-microservices/nds-v2-huggingface-cli"` | Repository for the HuggingFace model puller image |
| core.config.models.huggingface_model_puller.tag | string | `""` | Tag for the HuggingFace model puller image (defaults to Chart.appVersion) |
| core.config.models.port | int | `8000` | port is the port the models service will listen on |
| core.config.platform | object | `{"base_url":"","enable_service_account_auth":true}` | platform is the global platform configuration which is shared across all services |
| core.config.platform.base_url | string | `""` | base_url is the base URL for the platform. If not set, it will default to the core service URL |
| core.config.platform.enable_service_account_auth | bool | `true` | enable_service_account_auth enables service account token authentication in-between services |
| core.controller.affinity | object | `{}` | Affinity configuration for the controller service. |
| core.controller.annotations | object | `{}` | Annotations to add to the controller service deployment. |
| core.controller.env | object | `{}` | Additional environment variables to pass to containers. This is an object formatted like NAME: value or NAME: valueFrom: {object}. |
| core.controller.extraArgs | list | `[]` | Additional arguments to pass to the Core Controller service |
| core.controller.livenessProbe | object | This object has the following default values for the liveness probe configuration. | Liveness probe configuration for the controller service. |
| core.controller.livenessProbe.failureThreshold | int | `3` | The failure threshold for the readiness probe. |
| core.controller.livenessProbe.httpGet | object | `{"path":"/health/live","port":"http"}` | The HTTP GET request to use for the readiness probe. |
| core.controller.livenessProbe.periodSeconds | int | `10` | The frequency in seconds to perform the readiness probe. |
| core.controller.livenessProbe.timeoutSeconds | int | `5` | The timeout in seconds for the readiness probe. |
| core.controller.nodeSelector | object | `{}` | Node selector configuration for the controller service. |
| core.controller.podAnnotations | object | `{}` | Annotations to add to the controller service pod. |
| core.controller.podLabels | object | `{}` | Labels for the controller service pod. |
| core.controller.podSecurityContext | object | This object has the following default values for the pod security context. | Pod-level security context settings for the controller service. |
| core.controller.podSecurityContext.fsGroup | int | `1000` | The file system group ID to use for all containers. |
| core.controller.readinessProbe | object | This object has the following default values for the readiness probe configuration. | Readiness probe configuration for the controller service. |
| core.controller.readinessProbe.failureThreshold | int | `3` | The failure threshold for the readiness probe. |
| core.controller.readinessProbe.httpGet | object | `{"path":"/health/ready","port":"http"}` | The HTTP GET request to use for the readiness probe. |
| core.controller.readinessProbe.periodSeconds | int | `10` | The frequency in seconds to perform the readiness probe. |
| core.controller.readinessProbe.timeoutSeconds | int | `5` | The timeout in seconds for the readiness probe. |
| core.controller.resources | object | `{}` | Kubernetes deployment resources configuration for the controller service. It is recommended to not specify default resources and to leave this as a conscious choice. This also increases chances that the chart will run on environments with little resources, such as minikube. If you want to specify resources, use the following example, adjust the values as necessary, and remove the empty curly braces `{}`. `limits:   cpu: 100m   memory: 128Mi requests:   cpu: 100m   memory: 128Mi` |
| core.controller.securityContext | object | `{}` | Container-level security context settings for the controller service. |
| core.controller.serviceAccount | object | This object has the following default values for the service account configuration. | Service account configuration for the controller service. |
| core.controller.serviceAccount.annotations | object | `{}` | Annotations to add to the service account. |
| core.controller.serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials. |
| core.controller.serviceAccount.create | bool | `true` | Specifies whether a service account should be created. |
| core.controller.serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template. |
| core.controller.tolerations | list | `[]` |  |
| core.databaseMigrations.affinity | object | `{}` |  |
| core.databaseMigrations.annotations | object | `{}` | Annotations to add to the database migration job. |
| core.databaseMigrations.enabled | bool | `true` | Enable or disable database migrations job |
| core.databaseMigrations.extraArgs | list | `[]` | Additional arguments to pass to the database migration jobs |
| core.databaseMigrations.nodeSelector | object | `{}` |  |
| core.databaseMigrations.podAnnotations | object | `{}` | Annotations to add to the database migration job pods. |
| core.databaseMigrations.podLabels | object | `{}` | Labels for the database migration job pods. |
| core.databaseMigrations.podSecurityContext.fsGroup | int | `1000` |  |
| core.databaseMigrations.resources | object | `{}` |  |
| core.databaseMigrations.restartPolicy | string | `"OnFailure"` |  |
| core.databaseMigrations.securityContext | object | `{}` |  |
| core.databaseMigrations.tolerations | list | `[]` |  |
| core.externalDatabase | object | This object has the following default values for the external PostgreSQL configuration. | External PostgreSQL configuration settings. These values are only used when postgresql.enabled is set to false. |
| core.externalDatabase.database | string | `"jobs"` | Jobs database name. |
| core.externalDatabase.existingSecret | string | `""` | Name of an existing secret resource containing the database credentials. |
| core.externalDatabase.existingSecretPasswordKey | string | `""` | Name of an existing secret key containing the database credentials. |
| core.externalDatabase.host | string | `"localhost"` | External database host address. |
| core.externalDatabase.port | int | `5432` | External database port number. |
| core.externalDatabase.uriSecret | object | This object has the following default values for the URI secret configuration. | URI secret configuration for external database. |
| core.externalDatabase.uriSecret.key | string | `""` | Key in the URI secret containing the database URI. |
| core.externalDatabase.uriSecret.name | string | `""` | Name of the URI secret. |
| core.externalDatabase.user | string | `"nemo"` | Database username for Jobs service. |
| core.image | object | This object has the following default values for the image configuration. | Container image configuration for the NeMo Core microservice. |
| core.image.pullPolicy | string | `"IfNotPresent"` | The image pull policy determining when to pull new images. |
| core.image.repository | string | `"nvcr.io/nvidia/nemo-microservices/nmp-core"` | The registry where the NeMo Core image is located. |
| core.image.tag | string | `""` | The image tag to use. |
| core.logcollector.affinity | object | `{}` | Affinity configuration for the log collector. |
| core.logcollector.annotations | object | `{}` | Annotations to add to the log collector deployment. |
| core.logcollector.autoscaling | object | This object has the following default values for the autoscaling configuration. | Autoscaling configuration for the log collector. |
| core.logcollector.autoscaling.enabled | bool | `false` | Whether to enable horizontal pod autoscaler. |
| core.logcollector.autoscaling.maxReplicas | int | `1` | The maximum number of replicas for the deployment. |
| core.logcollector.autoscaling.minReplicas | int | `1` | The minimum number of replicas for the deployment. |
| core.logcollector.autoscaling.targetCPUUtilizationPercentage | int | `80` | The target CPU utilization percentage. |
| core.logcollector.command | list | `["/fluent-bit/bin/fluent-bit","-c","/fluent-bit/etc/fluent-bit.yaml"]` | The command to run in the log collector container. |
| core.logcollector.env | object | `{}` | Additional environment variables to pass to containers. This is an object formatted like NAME: value or NAME: valueFrom: {object}. |
| core.logcollector.image | object | This object has the following default values for the image configuration. | Container image configuration for the log collector. |
| core.logcollector.image.pullPolicy | string | `"IfNotPresent"` | The image pull policy determining when to pull new images. |
| core.logcollector.image.repository | string | `"fluent/fluent-bit"` | The registry where the log collector image is located. |
| core.logcollector.image.tag | string | `"4.0.7"` | The image tag to use. |
| core.logcollector.livenessProbe | object | This object has the following default values for the liveness probe configuration. | Liveness probe configuration for the log collector. |
| core.logcollector.livenessProbe.failureThreshold | int | `3` | Failure threshold for liveness probe. |
| core.logcollector.livenessProbe.initialDelaySeconds | int | `5` | Initial delay in seconds before liveness probe is initiated. |
| core.logcollector.livenessProbe.periodSeconds | int | `10` | Period in seconds for liveness probe. |
| core.logcollector.livenessProbe.tcpSocket | object | `{"port":4318}` | TCP socket configuration for liveness probe. |
| core.logcollector.livenessProbe.tcpSocket.port | int | `4318` | Port for TCP socket liveness probe. |
| core.logcollector.livenessProbe.timeoutSeconds | int | `5` | Timeout in seconds for liveness probe. |
| core.logcollector.nodeSelector | object | `{}` | Node selector configuration for the log collector. |
| core.logcollector.podAnnotations | object | `{}` | Annotations to add to the log collector pods. |
| core.logcollector.podLabels | object | `{}` | Labels for the log collector pod. |
| core.logcollector.podSecurityContext | object | This object has the following default values for the pod security context. | Pod-level security context settings for the log collector. |
| core.logcollector.podSecurityContext.fsGroup | int | `1000` | The file system group ID to use for all containers. |
| core.logcollector.readinessProbe | object | This object has the following default values for the readiness probe configuration. | Readiness probe configuration for the log collector. |
| core.logcollector.readinessProbe.failureThreshold | int | `3` | Failure threshold for readiness probe. |
| core.logcollector.readinessProbe.httpGet | object | `{"path":"/api/v1/health","port":2020}` | HTTP GET request configuration for readiness probe. |
| core.logcollector.readinessProbe.httpGet.path | string | `"/api/v1/health"` | The HTTP path for the readiness probe. |
| core.logcollector.readinessProbe.httpGet.port | int | `2020` | The port name for the readiness probe. |
| core.logcollector.readinessProbe.initialDelaySeconds | int | `5` | Initial delay in seconds before readiness probe is initiated. |
| core.logcollector.readinessProbe.periodSeconds | int | `5` | Period in seconds for readiness probe. |
| core.logcollector.readinessProbe.timeoutSeconds | int | `3` | Timeout in seconds for readiness probe. |
| core.logcollector.replicaCount | int | `1` | The number of replicas for the log collector. |
| core.logcollector.resources | object | `{}` | Kubernetes deployment resources configuration for the log collector. It is recommended to not specify default resources and to leave this as a conscious choice. This also increases chances that the chart will run on environments with little resources, such as minikube. If you want to specify resources, use the following example, adjust the values as necessary, and remove the empty curly braces `{}`. `limits:   cpu: 100m   memory: 128Mi requests:   cpu: 100m   memory: 128Mi` |
| core.logcollector.securityContext | object | `{}` | Container-level security context settings for the log collector. |
| core.logcollector.service | object | This object has the following default values for the service configuration. | Service configuration for the log collector. |
| core.logcollector.service.port | int | `4318` | The port number to expose for the service. |
| core.logcollector.service.type | string | `"ClusterIP"` | The Kubernetes service type to create. |
| core.logcollector.serviceAccount | object | This object has the following default values for the service account configuration. | Service account configuration for the log collector. |
| core.logcollector.serviceAccount.annotations | object | `{}` | Annotations to add to the service account. |
| core.logcollector.serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials. |
| core.logcollector.serviceAccount.create | bool | `true` | Specifies whether a service account should be created. |
| core.logcollector.serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template. |
| core.logcollector.tolerations | list | `[]` |  |
| core.logging.sidecar | object | This object has the following default values for the sidecar configuration. | Sidecar configuration for the log collector sidecar. |
| core.logging.sidecar.enabled | bool | `true` | Whether to enable the logging sidecar. Set to false to disable logging sidecars being attached to jobs. |
| core.logging.sidecar.image | object | This object has the following default values for the image configuration. | Container image configuration for the log collector sidecar. |
| core.logging.sidecar.image.repository | string | `"fluent/fluent-bit"` | The registry where the log collector sidecar image is located. |
| core.logging.sidecar.image.tag | string | `"4.0.7"` | The image tag to use. |
| core.postgresql | object | This object has the following default values for the PostgreSQL configuration. | PostgreSQL configuration for the NeMo Jobs microservice. |
| core.postgresql.architecture | string | `"standalone"` | The PostgreSQL architecture. Available options are `standalone` or `replication`. |
| core.postgresql.auth | object | This object has the following default values for the authentication configuration. | Authentication configuration for PostgreSQL. |
| core.postgresql.auth.database | string | `"jobs"` | The name for a custom database to create. |
| core.postgresql.auth.enablePostgresUser | bool | `true` | Whether to assign a password to the "postgres" admin user. If disabled, remote access is blocked for this user. |
| core.postgresql.auth.existingSecret | string | `""` | The name of an existing secret to use for PostgreSQL credentials. |
| core.postgresql.auth.password | string | `"nemo"` | The password for the PostgreSQL user. |
| core.postgresql.auth.username | string | `"nemo"` | The user name to use for the PostgreSQL database. |
| core.postgresql.enabled | bool | `true` | Whether to install the default PostgreSQL Helm chart. If enabled, the NeMo Jobs microservice Helm chart uses the [PostgreSQL Helm chart from Bitnami](https://github.com/bitnami/charts/blob/main/bitnami/postgresql/values.yaml) to create a PostgreSQL database. |
| core.postgresql.nameOverride | string | `"jobsdb"` | The name override for the PostgreSQL database. |
| core.postgresql.persistence | object | This object has the following default values for the persistence configuration. | Persistence configuration for PostgreSQL. |
| core.postgresql.persistence.enabled | bool | `true` | Whether to enable persistent volume. |
| core.postgresql.persistence.size | string | `"10Gi"` | Size of the persistent volume. |
| core.postgresql.service | object | This object has the following default values for the service configuration. | Service configuration for PostgreSQL. |
| core.postgresql.service.ports | object | `{"postgresql":5432}` | Port configuration for PostgreSQL service. |
| core.postgresql.service.ports.postgresql | int | `5432` | Port number for PostgreSQL service. |
| core.postgresql.serviceAccount | object | This object has the following default values for the service account configuration. | Service account configuration for PostgreSQL. |
| core.postgresql.serviceAccount.create | bool | `true` | Specifies whether to create a new service account for PostgreSQL. |
| core.postgresql.serviceAccount.name | string | `"jobs-postgresql"` | The service account name for PostgreSQL. |
| core.serviceName | string | `"nemo-core"` | Sets predictable name for the NeMo Core service |
| customizer.apiImage | object | This object has the following default values for the NeMo Customizer API only image. | Customizer API only image configuration. |
| customizer.apiImage.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for the NeMo Customizer API image. |
| customizer.apiImage.registry | string | `"nvcr.io"` | Registry for the NeMo Customizer API image. |
| customizer.apiImage.repository | string | `"nvidia/nemo-microservices/customizer-api"` | Repository for the NeMo Customizer API image. |
| customizer.automodelImage | object | This object has the following default values for the NeMo Customizer AutoModel microservice image. | NeMo Customizer image that supports training for HuggingFace models using NeMo AutoModel |
| customizer.automodelImage.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for the NeMo Customizer AutoModel image. |
| customizer.automodelImage.registry | string | `"nvcr.io"` | Registry for the NeMo Customizer AutoModel image. |
| customizer.automodelImage.repository | string | `"nvidia/nemo-microservices/customizer-automodel"` | Repository for the NeMo Customizer AutoModel image. |
| customizer.awsDeploy | object | `{"efaDevicesPerGPU":4,"enabled":false}` | Deployment configurations for AWS |
| customizer.awsDeploy.efaDevicesPerGPU | int | `4` | EFA number of devices per GPU |
| customizer.awsDeploy.enabled | bool | `false` | Switch on if using AWS and kyverno is installed |
| customizer.customizationConfigTemplates | object | This object has the following default values. | List of customization configuration template supported by the Customizer. |
| customizer.customizationConfigTemplates.overrideExistingTemplates | bool | `true` | Whether to have this values file override templates in the database on application start |
| customizer.customizationConfigTemplates.templates | object | This object has the following default values. | The default templates to populate the database with |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+40GB" | object | This object has the following default values for the Llama 3.1 70B Instruct model. | Llama 3.1 70B Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+40GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+40GB".name | string | `"llama-3.1-70b-instruct@v1.0.0+40GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+40GB".namespace | string | `"meta"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+40GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+40GB".target | string | `"meta/llama-3.1-70b-instruct@2.0"` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+40GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":2,"pipeline_parallel_size":2,"tensor_parallel_size":4,"training_type":"sft"}]` | Training options for different fine-tuning methods. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+40GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":2,"pipeline_parallel_size":2,"tensor_parallel_size":4,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+40GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+40GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+40GB".training_options[0].num_gpus | int | `4` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+40GB".training_options[0].num_nodes | int | `2` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+40GB".training_options[0].pipeline_parallel_size | int | `2` | The number of GPUs among which the model’s layers are distributed. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+40GB".training_options[0].tensor_parallel_size | int | `4` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+80GB" | object | This object has the following default values for the Llama 3.1 70B Instruct model. | Llama 3.1 70B Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+80GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+80GB".name | string | `"llama-3.1-70b-instruct@v1.0.0+80GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+80GB".namespace | string | `"meta"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+80GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+80GB".target | string | `"meta/llama-3.1-70b-instruct@2.0"` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+80GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":1,"tensor_parallel_size":4,"training_type":"sft"}]` | Training options for different fine-tuning methods. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+80GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":1,"tensor_parallel_size":4,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+80GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+80GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+80GB".training_options[0].num_gpus | int | `4` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+80GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-70b-instruct@v1.0.0+80GB".training_options[0].tensor_parallel_size | int | `4` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB" | object | This object has the following default values for the Llama 3.1 8B Instruct model. | Llama 3.1 8B Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".name | string | `"llama-3.1-8b-instruct@v1.0.0+40GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".namespace | string | `"meta"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".target | string | `"meta/llama-3.1-8b-instruct@2.0"` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":2,"tensor_parallel_size":2,"training_type":"sft"},{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":4,"num_nodes":2,"pipeline_parallel_size":2,"tensor_parallel_size":4,"training_type":"sft"},{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":4,"num_nodes":2,"tensor_parallel_size":8,"training_type":"dpo"}]` | Training options for different fine-tuning methods. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":2,"tensor_parallel_size":2,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".training_options[0].num_gpus | int | `2` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".training_options[0].tensor_parallel_size | int | `2` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".training_options[1].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".training_options[1].num_gpus | int | `4` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".training_options[1].num_nodes | int | `2` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".training_options[1].pipeline_parallel_size | int | `2` | The number of GPUs among which the model’s layers are distributed. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".training_options[1].tensor_parallel_size | int | `4` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".training_options[2].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".training_options[2].num_gpus | int | `4` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".training_options[2].num_nodes | int | `2` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+40GB".training_options[2].tensor_parallel_size | int | `8` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB" | object | This object has the following default values for the Llama 3.1 8B Instruct model. | Llama 3.1 8B Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".name | string | `"llama-3.1-8b-instruct@v1.0.0+80GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".namespace | string | `"meta"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".target | string | `"meta/llama-3.1-8b-instruct@2.0"` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"training_type":"sft"},{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":8,"num_nodes":1,"pipeline_parallel_size":2,"tensor_parallel_size":4,"training_type":"sft"},{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":8,"num_nodes":1,"tensor_parallel_size":8,"training_type":"dpo"}]` | Training options for different fine-tuning methods. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".training_options[0].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".training_options[1].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".training_options[1].num_gpus | int | `8` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".training_options[1].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".training_options[1].pipeline_parallel_size | int | `2` | The number of GPUs among which the model’s layers are distributed. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".training_options[1].tensor_parallel_size | int | `4` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".training_options[2].finetuning_type | string | `"all_weights"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".training_options[2].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".training_options[2].num_gpus | int | `8` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".training_options[2].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.1-8b-instruct@v1.0.0+80GB".training_options[2].tensor_parallel_size | int | `8` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB" | object | This object has the following default values for the Llama 3.2 1B Instruct model. | Llama 3.2 1B Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".name | string | `"llama-3.2-1b-instruct@v1.0.0+40GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".namespace | string | `"meta"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".target | string | `"meta/llama-3.2-1b-instruct@2.0"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"},{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"},{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":2,"num_nodes":1,"tensor_parallel_size":2,"training_type":"dpo"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".training_options[0].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".training_options[0].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".training_options[1].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".training_options[1].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".training_options[1].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".training_options[1].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".training_options[2].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".training_options[2].num_gpus | int | `2` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".training_options[2].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+40GB".training_options[2].tensor_parallel_size | int | `2` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB" | object | This object has the following default values for the Llama 3.2 1B Instruct model. | Llama 3.2 1B Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".name | string | `"llama-3.2-1b-instruct@v1.0.0+80GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".namespace | string | `"meta"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".target | string | `"meta/llama-3.2-1b-instruct@2.0"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"},{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"},{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"dpo"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".training_options[0].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".training_options[0].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".training_options[1].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".training_options[1].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".training_options[1].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".training_options[1].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".training_options[2].finetuning_type | string | `"all_weights"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".training_options[2].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".training_options[2].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".training_options[2].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b-instruct@v1.0.0+80GB".training_options[2].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB" | object | This object has the following default values for the Llama 3.2 1B model. | Llama 3.2 1B model configuration. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB".name | string | `"llama-3.2-1b@v1.0.0+40GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB".namespace | string | `"meta"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB".target | string | `"meta/llama-3.2-1b@2.0"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"},{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB".training_options[0].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB".training_options[0].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB".training_options[1].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB".training_options[1].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB".training_options[1].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+40GB".training_options[1].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB" | object | This object has the following default values for the Llama 3.2 1B model. | Llama 3.2 1B model configuration. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB".name | string | `"llama-3.2-1b@v1.0.0+80GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB".namespace | string | `"meta"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB".target | string | `"meta/llama-3.2-1b@2.0"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"},{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB".training_options[0].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB".training_options[0].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB".training_options[1].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB".training_options[1].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB".training_options[1].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-1b@v1.0.0+80GB".training_options[1].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+40GB" | object | This object has the following default values for the Llama 3.2 3B Instruct model. | Llama 3.2 3B Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+40GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+40GB".name | string | `"llama-3.2-3b-instruct@v1.0.0+40GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+40GB".namespace | string | `"meta"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+40GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+40GB".target | string | `"meta/llama-3.2-3b-instruct@2.0"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+40GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+40GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+40GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+40GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+40GB".training_options[0].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+40GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+40GB".training_options[0].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+80GB" | object | This object has the following default values for the Llama 3.2 3B Instruct model. | Llama 3.2 3B Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+80GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+80GB".name | string | `"llama-3.2-3b-instruct@v1.0.0+80GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+80GB".namespace | string | `"meta"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+80GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+80GB".target | string | `"meta/llama-3.2-3b-instruct@2.0"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+80GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+80GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+80GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+80GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+80GB".training_options[0].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+80GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+80GB".training_options[0].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+40GB" | object | This object has the following default values for the Llama 3.3 70B Instruct model. | Llama 3.3 70B Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+40GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+40GB".name | string | `"llama-3.3-70b-instruct@v1.0.0+40GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+40GB".namespace | string | `"meta"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+40GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+40GB".target | string | `"meta/llama-3.3-70b-instruct@2.0"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+40GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":2,"pipeline_parallel_size":2,"tensor_parallel_size":4,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+40GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":2,"pipeline_parallel_size":2,"tensor_parallel_size":4,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+40GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+40GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+40GB".training_options[0].num_gpus | int | `4` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+40GB".training_options[0].num_nodes | int | `2` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+40GB".training_options[0].pipeline_parallel_size | int | `2` | The number of GPUs among which the model’s layers are distributed. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+40GB".training_options[0].tensor_parallel_size | int | `4` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+80GB" | object | This object has the following default values for the Llama 3.3 70B Instruct model. | Llama 3.3 70B Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+80GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+80GB".name | string | `"llama-3.3-70b-instruct@v1.0.0+80GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+80GB".namespace | string | `"meta"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+80GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+80GB".target | string | `"meta/llama-3.3-70b-instruct@2.0"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+80GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":1,"tensor_parallel_size":4,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+80GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":1,"tensor_parallel_size":4,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+80GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+80GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+80GB".training_options[0].num_gpus | int | `4` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+80GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama-3.3-70b-instruct@v1.0.0+80GB".training_options[0].tensor_parallel_size | int | `4` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+40GB" | object | This object has the following default values for the Llama 3 70B Instruct model. | Llama 3 70B Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+40GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+40GB".name | string | `"llama3-70b-instruct@v1.0.0+40GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+40GB".namespace | string | `"meta"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+40GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+40GB".target | string | `"meta/llama3-70b-instruct@2.0"` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+40GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":2,"pipeline_parallel_size":2,"tensor_parallel_size":4,"training_type":"sft"}]` | Training options for different fine-tuning methods. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+40GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":2,"pipeline_parallel_size":2,"tensor_parallel_size":4,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+40GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+40GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+40GB".training_options[0].num_gpus | int | `4` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+40GB".training_options[0].num_nodes | int | `2` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+40GB".training_options[0].pipeline_parallel_size | int | `2` | The number of GPUs among which the model’s layers are distributed. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+40GB".training_options[0].tensor_parallel_size | int | `4` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+80GB" | object | This object has the following default values for the Llama 3 70B Instruct model. | Llama 3 70B Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+80GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+80GB".name | string | `"llama3-70b-instruct@v1.0.0+80GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+80GB".namespace | string | `"meta"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+80GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+80GB".target | string | `"meta/llama3-70b-instruct@2.0"` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+80GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":1,"tensor_parallel_size":4,"training_type":"sft"}]` | Training options for different fine-tuning methods. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+80GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":1,"tensor_parallel_size":4,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+80GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+80GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+80GB".training_options[0].num_gpus | int | `4` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+80GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."meta/llama3-70b-instruct@v1.0.0+80GB".training_options[0].tensor_parallel_size | int | `4` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+40GB" | object | This object has the following default values for the Phi-4. | Phi-4 model configuration. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+40GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+40GB".name | string | `"phi-4@v1.0.0+40GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+40GB".namespace | string | `"microsoft"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+40GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+40GB".target | string | `"microsoft/phi-4@1.0"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+40GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":2,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+40GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":2,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+40GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+40GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+40GB".training_options[0].num_gpus | int | `2` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+40GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+40GB".training_options[0].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+80GB" | object | This object has the following default values for the Phi-4. | Phi-4 model configuration. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+80GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+80GB".name | string | `"phi-4@v1.0.0+80GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+80GB".namespace | string | `"microsoft"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+80GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+80GB".target | string | `"microsoft/phi-4@1.0"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+80GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+80GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+80GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+80GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+80GB".training_options[0].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."microsoft/phi-4@v1.0.0+80GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB" | object | This object has the following default values for the Mistral 3.3B Reasoning 2512 model. | Mistral 3.3B Reasoning 2512 model configuration. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB".name | string | `"ministral-3-3B-reasoning-2512@v1.0.0+80GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB".namespace | string | `"mistralai"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB".target | string | `"mistralai/ministral-3-3B-reasoning-2512@v1"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"},{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB".training_options[0].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB".training_options[0].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB".training_options[1].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB".training_options[1].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB".training_options[1].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."mistralai/ministral-3-3B-reasoning-2512@v1.0.0+80GB".training_options[1].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+40GB".max_seq_length | int | `2048` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+40GB".name | string | `"llama-3.2-nv-embedqa-1b@v2+40GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+40GB".namespace | string | `"nvidia"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+40GB".target | string | `"nvidia/llama-3.2-nv-embedqa-1b@v2"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+40GB".training_options | list | `[{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+40GB".training_options[0] | object | `{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+40GB".training_options[0].finetuning_type | string | `"all_weights"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+40GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+40GB".training_options[0].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+40GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+40GB".training_options[0].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".max_seq_length | int | `2048` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".name | string | `"llama-3.2-nv-embedqa-1b@v2+80GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".namespace | string | `"nvidia"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".target | string | `"nvidia/llama-3.2-nv-embedqa-1b@v2"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".training_options | list | `[{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"},{"finetuning_type":"lora_merged","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".training_options[0] | object | `{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".training_options[0].finetuning_type | string | `"all_weights"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".training_options[0].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".training_options[0].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".training_options[1].finetuning_type | string | `"lora_merged"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".training_options[1].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".training_options[1].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".training_options[1].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/llama-3.2-nv-embedqa-1b@v2+80GB".training_options[1].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-9b-v2@v1.0.0+80GB" | object | This object has the following default values for the NVIDIA nemotron-nano-9b-v2 model. | NVIDIA Nemotron-Nano-V2 9b model configuration. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-9b-v2@v1.0.0+80GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-9b-v2@v1.0.0+80GB".name | string | `"nemotron-nano-9b-v2@v1.0.0+80GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-9b-v2@v1.0.0+80GB".namespace | string | `"nvidia"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-9b-v2@v1.0.0+80GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-9b-v2@v1.0.0+80GB".target | string | `"nvidia/nemotron-nano-9b-v2@v1"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-9b-v2@v1.0.0+80GB".training_options | list | `[{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":8,"num_nodes":1,"pipeline_parallel_size":1,"tensor_parallel_size":1,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-9b-v2@v1.0.0+80GB".training_options[0] | object | `{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":8,"num_nodes":1,"pipeline_parallel_size":1,"tensor_parallel_size":1,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-9b-v2@v1.0.0+80GB".training_options[0].finetuning_type | string | `"all_weights"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-9b-v2@v1.0.0+80GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-9b-v2@v1.0.0+80GB".training_options[0].num_gpus | int | `8` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-9b-v2@v1.0.0+80GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-9b-v2@v1.0.0+80GB".training_options[0].pipeline_parallel_size | int | `1` | The number of GPUs among which the model’s layers are distributed. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-9b-v2@v1.0.0+80GB".training_options[0].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB" | object | This object has the following default values for the Nemotron Nano Llama 3.1 8B Instruct model. | Nemotron Nano Llama 3.1 8B Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".name | string | `"nemotron-nano-llama-3.1-8b@v1.0.0+40GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".namespace | string | `"nvidia"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".target | string | `"nvidia/nemotron-nano-llama-3.1-8b@1.0"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":2,"num_nodes":1,"tensor_parallel_size":2,"training_type":"sft"},{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":4,"num_nodes":2,"pipeline_parallel_size":2,"tensor_parallel_size":4,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":2,"num_nodes":1,"tensor_parallel_size":2,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".training_options[0].num_gpus | int | `2` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".training_options[0].tensor_parallel_size | int | `2` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".training_options[1] | object | `{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":4,"num_nodes":2,"pipeline_parallel_size":2,"tensor_parallel_size":4,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".training_options[1].finetuning_type | string | `"all_weights"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".training_options[1].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".training_options[1].num_gpus | int | `4` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".training_options[1].num_nodes | int | `2` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".training_options[1].pipeline_parallel_size | int | `2` | The number of GPUs among which the model’s layers are distributed. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+40GB".training_options[1].tensor_parallel_size | int | `4` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB" | object | This object has the following default values for the Nemotron Nano Llama 3.1 8B Instruct model. | Nemotron Nano Llama 3.1 8B Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".name | string | `"nemotron-nano-llama-3.1-8b@v1.0.0+80GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".namespace | string | `"nvidia"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".target | string | `"nvidia/nemotron-nano-llama-3.1-8b@1.0"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"},{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":8,"num_nodes":1,"pipeline_parallel_size":2,"tensor_parallel_size":4,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".training_options[0].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".training_options[0].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".training_options[1] | object | `{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":8,"num_nodes":1,"pipeline_parallel_size":2,"tensor_parallel_size":4,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".training_options[1].finetuning_type | string | `"all_weights"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".training_options[1].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".training_options[1].num_gpus | int | `8` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".training_options[1].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".training_options[1].pipeline_parallel_size | int | `2` | The number of GPUs among which the model’s layers are distributed. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-nano-llama-3.1-8b@v1.0.0+80GB".training_options[1].tensor_parallel_size | int | `4` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+40GB" | object | This object has the following default values for the Nemotron Super Llama 3.3 49B Instruct model. | Nemotron Super Llama 3.3 49B Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+40GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+40GB".name | string | `"nemotron-super-llama-3.3-49b@v1.0.0+40GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+40GB".namespace | string | `"nvidia"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+40GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+40GB".target | string | `"nvidia/nemotron-super-llama-3.3-49b@1.0"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+40GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":2,"pipeline_parallel_size":2,"tensor_parallel_size":4,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+40GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":2,"pipeline_parallel_size":2,"tensor_parallel_size":4,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+40GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+40GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+40GB".training_options[0].num_gpus | int | `4` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+40GB".training_options[0].num_nodes | int | `2` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+40GB".training_options[0].pipeline_parallel_size | int | `2` | The number of GPUs among which the model’s layers are distributed. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+40GB".training_options[0].tensor_parallel_size | int | `4` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+80GB" | object | This object has the following default values for the Nemotron Super Llama 3.3 49B Instruct model. | Nemotron Super Llama 3.3 49B Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+80GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+80GB".name | string | `"nemotron-super-llama-3.3-49b@v1.0.0+80GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+80GB".namespace | string | `"nvidia"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+80GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+80GB".target | string | `"nvidia/nemotron-super-llama-3.3-49b@1.0"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+80GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":1,"tensor_parallel_size":4,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+80GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":1,"tensor_parallel_size":4,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+80GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+80GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+80GB".training_options[0].num_gpus | int | `4` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+80GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.0.0+80GB".training_options[0].tensor_parallel_size | int | `4` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.5+80GB" | object | This object has the following default values for the Nemotron Super Llama 3.3 49B v1.5 Instruct model. | Nemotron Super Llama 3.3 49B v1.5 Instruct model configuration. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.5+80GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.5+80GB".name | string | `"nemotron-super-llama-3.3-49b@v1.5+80GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.5+80GB".namespace | string | `"nvidia"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.5+80GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.5+80GB".target | string | `"nvidia/nemotron-super-llama-3.3-49b@1.5"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.5+80GB".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":1,"tensor_parallel_size":4,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.5+80GB".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":4,"num_nodes":1,"tensor_parallel_size":4,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.5+80GB".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.5+80GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.5+80GB".training_options[0].num_gpus | int | `4` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.5+80GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."nvidia/nemotron-super-llama-3.3-49b@v1.5+80GB".training_options[0].tensor_parallel_size | int | `4` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB" | object | This object has the following default values for the OpenAI gpt-oss 20b model. | Openai gpt-oss 20B model configuration. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".name | string | `"gpt-oss-20b@v1.0.0+80GB"` | The name for training config template. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".namespace | string | `"openai"` | The namespace for training config template. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".target | string | `"openai/gpt-oss-20b@v1"` | The target to perform the customization on. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options | list | `[{"expert_model_parallel_size":8,"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":8,"num_nodes":1,"pipeline_parallel_size":1,"tensor_parallel_size":1,"training_type":"sft"},{"expert_model_parallel_size":1,"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"pipeline_parallel_size":1,"tensor_parallel_size":1,"training_type":"sft"}]` | Resource configuration for each training option for the target model. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options[0] | object | `{"expert_model_parallel_size":8,"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":8,"num_nodes":1,"pipeline_parallel_size":1,"tensor_parallel_size":1,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options[0].expert_model_parallel_size | int | `8` | Number of GPUs used to parallelize expert (MoE) components of the model. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options[0].finetuning_type | string | `"all_weights"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options[0].num_gpus | int | `8` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options[0].pipeline_parallel_size | int | `1` | Number of GPUs used to split the model across layers for pipeline model. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options[0].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options[1] | object | `{"expert_model_parallel_size":1,"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"pipeline_parallel_size":1,"tensor_parallel_size":1,"training_type":"sft"}` | Training method. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options[1].expert_model_parallel_size | int | `1` | Number of GPUs used to parallelize expert (MoE) components of the model. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options[1].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options[1].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options[1].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options[1].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options[1].pipeline_parallel_size | int | `1` | Number of GPUs used to split the model across layers for pipeline model. |
| customizer.customizationConfigTemplates.templates."openai/gpt-oss-20b@v1.0.0+80GB".training_options[1].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizer.customizationTargets | object | This object has the following default values. | List of model configurations supported by the Customizer. |
| customizer.customizationTargets.hfTargetDownload.allowedHfOrgs | list | `[]` | List of allowed organizations for model downloads from Hugging Face. Empty list allows all organizations. Example: allowedHfOrgs:   - "nvidia" |
| customizer.customizationTargets.hfTargetDownload.enabled | bool | `false` | set this to true to allow model downloads from Hugging Face. If enabled=false, models are not allwed to be downloaded from any Hugging Face org and allowedHfOrgs is disregarded |
| customizer.customizationTargets.overrideExistingTargets | bool | `true` | Whether to have this values file override targets in the database on application start |
| customizer.customizationTargets.targets | object | This object has the following default values. | The default targets to populate the database with |
| customizer.customizationTargets.targets."meta/llama-3.1-70b-instruct@2.0" | object | This object has the following default values for the Llama 3.1 70B Instruct model. | Llama 3.1 70B Instruct model target configuration. |
| customizer.customizationTargets.targets."meta/llama-3.1-70b-instruct@2.0".base_model | string | `"meta/llama-3.1-70b-instruct"` | Mapping to the model name in NIM and Recipe Selection in Customizer. Defaults to being the same as the the configuration entry namespace/name. |
| customizer.customizationTargets.targets."meta/llama-3.1-70b-instruct@2.0".enabled | bool | `false` | Whether to enable the model. |
| customizer.customizationTargets.targets."meta/llama-3.1-70b-instruct@2.0".model_path | string | `"llama-3_1-70b-instruct_2_0"` | Path where model files are stored. |
| customizer.customizationTargets.targets."meta/llama-3.1-70b-instruct@2.0".model_uri | string | `"ngc://nvidia/nemo/llama-3_1-70b-instruct-nemo:2.0"` | NGC model URI for Llama 3.1 70B Instruct model. |
| customizer.customizationTargets.targets."meta/llama-3.1-70b-instruct@2.0".name | string | `"llama-3.1-70b-instruct@2.0"` | The name for target model. |
| customizer.customizationTargets.targets."meta/llama-3.1-70b-instruct@2.0".namespace | string | `"meta"` | The namespace for target model. |
| customizer.customizationTargets.targets."meta/llama-3.1-70b-instruct@2.0".num_parameters | int | `70000000000` | Number of model parameters. |
| customizer.customizationTargets.targets."meta/llama-3.1-70b-instruct@2.0".precision | string | `"bf16-mixed"` | Model precision format. |
| customizer.customizationTargets.targets."meta/llama-3.1-8b-instruct@2.0" | object | This object has the following default values for the Llama 3.1 8B Instruct model. | Llama 3.1 8B Instruct model target configuration. |
| customizer.customizationTargets.targets."meta/llama-3.1-8b-instruct@2.0".base_model | string | `"meta/llama-3.1-8b-instruct"` | Mapping to the model name in NIM and Recipe Selection in Customizer. Defaults to being the same as the the configuration entry namespace/name. |
| customizer.customizationTargets.targets."meta/llama-3.1-8b-instruct@2.0".enabled | bool | `true` | Whether to enable the model. |
| customizer.customizationTargets.targets."meta/llama-3.1-8b-instruct@2.0".model_path | string | `"llama-3_1-8b-instruct_2_0"` | Path where model files are stored. |
| customizer.customizationTargets.targets."meta/llama-3.1-8b-instruct@2.0".model_uri | string | `"ngc://nvidia/nemo/llama-3_1-8b-instruct-nemo:2.0"` | NGC model URI for Llama 3.1 8B Instruct model. |
| customizer.customizationTargets.targets."meta/llama-3.1-8b-instruct@2.0".name | string | `"llama-3.1-8b-instruct@2.0"` | The name for target model. |
| customizer.customizationTargets.targets."meta/llama-3.1-8b-instruct@2.0".namespace | string | `"meta"` | The namespace for target model. |
| customizer.customizationTargets.targets."meta/llama-3.1-8b-instruct@2.0".num_parameters | int | `8000000000` | Number of model parameters. |
| customizer.customizationTargets.targets."meta/llama-3.1-8b-instruct@2.0".precision | string | `"bf16-mixed"` | Model precision format. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b-instruct@2.0" | object | This object has the following default values for the Llama 3.2 1B Instruct model. | Llama 3.2 1B Instruct model target configuration. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b-instruct@2.0".base_model | string | `"meta/llama-3.2-1b-instruct"` | Mapping to the model name in NIM and Recipe Selection in Customizer. Defaults to being the same as the the configuration entry namespace/name. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b-instruct@2.0".enabled | bool | `true` | Whether to enable the model. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b-instruct@2.0".model_path | string | `"llama32_1b-instruct_2_0"` | Path where model files are stored. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b-instruct@2.0".model_uri | string | `"ngc://nvidia/nemo/llama-3_2-1b-instruct:2.0"` | NGC model URI |
| customizer.customizationTargets.targets."meta/llama-3.2-1b-instruct@2.0".name | string | `"llama-3.2-1b-instruct@2.0"` | The name for target model. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b-instruct@2.0".namespace | string | `"meta"` | The namespace for target model. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b-instruct@2.0".num_parameters | int | `1000000000` | Number of model parameters. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b-instruct@2.0".precision | string | `"bf16-mixed"` | Model precision format. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b@2.0" | object | This object has the following default values for the Llama 3.2 1B model. | Llama 3.2 1B target model configuration. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b@2.0".base_model | string | `"meta/llama-3.2-1b"` | Mapping to the model name in NIM and Recipe Selection in Customizer. Defaults to being the same as the the configuration entry namespace/name. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b@2.0".enabled | bool | `false` | Whether to enable the model. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b@2.0".model_path | string | `"llama32_1b_2_0"` | Path where model files are stored. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b@2.0".model_uri | string | `"ngc://nvidia/nemo/llama-3_2-1b:2.0"` | NGC model URI for Llama 3.2 1B model. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b@2.0".name | string | `"llama-3.2-1b@2.0"` | The name for target model. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b@2.0".namespace | string | `"meta"` | The namespace for target model. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b@2.0".num_parameters | int | `1000000000` | Number of model parameters. |
| customizer.customizationTargets.targets."meta/llama-3.2-1b@2.0".precision | string | `"bf16-mixed"` | Model precision format. |
| customizer.customizationTargets.targets."meta/llama-3.2-3b-instruct@2.0" | object | This object has the following default values for the Llama 3.2 3B Instruct model. | Llama 3.2 3B Instruct model target configuration. |
| customizer.customizationTargets.targets."meta/llama-3.2-3b-instruct@2.0".base_model | string | `"meta/llama-3.2-3b-instruct"` | Mapping to the model name in NIM and Recipe Selection in Customizer. Defaults to being the same as the the configuration entry namespace/name. |
| customizer.customizationTargets.targets."meta/llama-3.2-3b-instruct@2.0".enabled | bool | `false` | Whether to enable the model. |
| customizer.customizationTargets.targets."meta/llama-3.2-3b-instruct@2.0".model_path | string | `"llama32_3b-instruct_2_0"` | Path where model files are stored. |
| customizer.customizationTargets.targets."meta/llama-3.2-3b-instruct@2.0".model_uri | string | `"ngc://nvidia/nemo/llama-3_2-3b-instruct:2.0"` | NGC model URI. |
| customizer.customizationTargets.targets."meta/llama-3.2-3b-instruct@2.0".name | string | `"llama-3.2-3b-instruct@2.0"` | The name for target model. |
| customizer.customizationTargets.targets."meta/llama-3.2-3b-instruct@2.0".namespace | string | `"meta"` | The namespace for target model. |
| customizer.customizationTargets.targets."meta/llama-3.2-3b-instruct@2.0".num_parameters | int | `3000000000` | Number of model parameters. |
| customizer.customizationTargets.targets."meta/llama-3.2-3b-instruct@2.0".precision | string | `"bf16-mixed"` | Model precision format. |
| customizer.customizationTargets.targets."meta/llama-3.3-70b-instruct@2.0" | object | This object has the following default values for the Llama 3.3 70B Instruct model. | Llama 3.3 70B Instruct model target configuration. |
| customizer.customizationTargets.targets."meta/llama-3.3-70b-instruct@2.0".base_model | string | `"meta/llama-3.3-70b-instruct"` | Mapping to the model name in NIM and Recipe Selection in Customizer. Defaults to being the same as the the configuration entry namespace/name. |
| customizer.customizationTargets.targets."meta/llama-3.3-70b-instruct@2.0".enabled | bool | `false` | Whether to enable the model. |
| customizer.customizationTargets.targets."meta/llama-3.3-70b-instruct@2.0".model_path | string | `"llama-3_3-70b-instruct_2_0"` | Path where model files are stored. |
| customizer.customizationTargets.targets."meta/llama-3.3-70b-instruct@2.0".model_uri | string | `"ngc://nvidia/nemo/llama-3_3-70b-instruct:2.0"` | NGC model URI for Llama 3.3 70B Instruct model. |
| customizer.customizationTargets.targets."meta/llama-3.3-70b-instruct@2.0".name | string | `"llama-3.3-70b-instruct@2.0"` | The name for target model. |
| customizer.customizationTargets.targets."meta/llama-3.3-70b-instruct@2.0".namespace | string | `"meta"` | The namespace for target model. |
| customizer.customizationTargets.targets."meta/llama-3.3-70b-instruct@2.0".num_parameters | int | `70000000000` | Number of model parameters. |
| customizer.customizationTargets.targets."meta/llama-3.3-70b-instruct@2.0".precision | string | `"bf16-mixed"` | Model precision format. |
| customizer.customizationTargets.targets."meta/llama3-70b-instruct@2.0" | object | This object has the following default values for the Llama 3 70B Instruct model. | Llama 3 70B Instruct model target configuration. |
| customizer.customizationTargets.targets."meta/llama3-70b-instruct@2.0".base_model | string | `"meta/llama3-70b-instruct"` | Mapping to the model name in NIM and Recipe Selection in Customizer. Defaults to being the same as the the configuration entry namespace/name. |
| customizer.customizationTargets.targets."meta/llama3-70b-instruct@2.0".enabled | bool | `false` | Whether to enable the model. |
| customizer.customizationTargets.targets."meta/llama3-70b-instruct@2.0".model_path | string | `"llama-3-70b-bf16_2_0"` | Path where model files are stored. |
| customizer.customizationTargets.targets."meta/llama3-70b-instruct@2.0".model_uri | string | `"ngc://nvidia/nemo/llama-3-70b-instruct-nemo:2.0"` | NGC model URI for Llama 3 70B Instruct model. |
| customizer.customizationTargets.targets."meta/llama3-70b-instruct@2.0".name | string | `"llama3-70b-instruct@2.0"` | The name for target model. |
| customizer.customizationTargets.targets."meta/llama3-70b-instruct@2.0".namespace | string | `"meta"` | The namespace for target model. |
| customizer.customizationTargets.targets."meta/llama3-70b-instruct@2.0".num_parameters | int | `70000000000` | Number of model parameters. |
| customizer.customizationTargets.targets."meta/llama3-70b-instruct@2.0".precision | string | `"bf16-mixed"` | Model precision format. |
| customizer.customizationTargets.targets."microsoft/phi-4@1.0" | object | This object has the following default values for the Phi-4. | Phi-4 model target configuration. |
| customizer.customizationTargets.targets."microsoft/phi-4@1.0".base_model | string | `"microsoft/phi-4"` | Mapping to the model name in NIM and Recipe Selection in Customizer. Defaults to being the same as the the configuration entry namespace/name. |
| customizer.customizationTargets.targets."microsoft/phi-4@1.0".enabled | bool | `false` | Whether to enable the model. |
| customizer.customizationTargets.targets."microsoft/phi-4@1.0".model_path | string | `"phi-4_1_0"` | Path where model files are stored. |
| customizer.customizationTargets.targets."microsoft/phi-4@1.0".model_uri | string | `"ngc://nvidia/nemo/phi-4:1.0"` | NGC model URI for Phi-4 model. |
| customizer.customizationTargets.targets."microsoft/phi-4@1.0".name | string | `"phi-4@1.0"` | The name for target model. |
| customizer.customizationTargets.targets."microsoft/phi-4@1.0".namespace | string | `"microsoft"` | The namespace for target model. |
| customizer.customizationTargets.targets."microsoft/phi-4@1.0".num_parameters | int | `14659507200` | Number of model parameters. |
| customizer.customizationTargets.targets."microsoft/phi-4@1.0".precision | string | `"bf16"` | Model precision format. |
| customizer.customizationTargets.targets."microsoft/phi-4@1.0".version | string | `"1.0"` | The version for target model. |
| customizer.customizationTargets.targets."nvidia/llama-3.2-nv-embedqa-1b@v2" | object | This object has the following default values for the Llama 3.2 1B embedding model. | Llama 3.2 1B embedding target model configuration. |
| customizer.customizationTargets.targets."nvidia/llama-3.2-nv-embedqa-1b@v2".base_model | string | `"nvidia/llama-3.2-nv-embedqa-1b-v2"` | Mapping to the model name to the optimized llama embedding training script and NIM |
| customizer.customizationTargets.targets."nvidia/llama-3.2-nv-embedqa-1b@v2".enabled | bool | `false` | Whether to enable the model. |
| customizer.customizationTargets.targets."nvidia/llama-3.2-nv-embedqa-1b@v2".model_path | string | `"llama32_1b-embedding"` | Path where model files are stored. |
| customizer.customizationTargets.targets."nvidia/llama-3.2-nv-embedqa-1b@v2".model_uri | string | `"ngc://nvidia/nemo/llama-3_2-1b-embedding-base:0.0.1"` | NGC model URI |
| customizer.customizationTargets.targets."nvidia/llama-3.2-nv-embedqa-1b@v2".name | string | `"llama-3.2-nv-embedqa-1b@v2"` | The name for target model. |
| customizer.customizationTargets.targets."nvidia/llama-3.2-nv-embedqa-1b@v2".namespace | string | `"nvidia"` | The namespace for target model. |
| customizer.customizationTargets.targets."nvidia/llama-3.2-nv-embedqa-1b@v2".num_parameters | int | `1000000000` | Number of model parameters. |
| customizer.customizationTargets.targets."nvidia/llama-3.2-nv-embedqa-1b@v2".precision | string | `"bf16-mixed"` | Model precision format. |
| customizer.customizationTargets.targets."nvidia/nemotron-nano-llama-3.1-8b@1.0" | object | This object has the following default values for the Nemotron Nano Llama 3.1 8B Instruct model. | Nemotron Nano Llama 3.1 8B Instruct model target configuration. |
| customizer.customizationTargets.targets."nvidia/nemotron-nano-llama-3.1-8b@1.0".base_model | string | `"nvidia/llama-3.1-nemotron-nano-8b-v1"` | Mapping to the model name in NIM and Recipe Selection in Customizer. Defaults to being the same as the the configuration entry namespace/name. |
| customizer.customizationTargets.targets."nvidia/nemotron-nano-llama-3.1-8b@1.0".enabled | bool | `false` | Whether to enable the model. |
| customizer.customizationTargets.targets."nvidia/nemotron-nano-llama-3.1-8b@1.0".model_path | string | `"nemotron-nano-3_1-8b_0_0_1"` | Path where model files are stored. |
| customizer.customizationTargets.targets."nvidia/nemotron-nano-llama-3.1-8b@1.0".model_uri | string | `"ngc://nvidia/nemo/nemotron-nano-3_1-8b:0.0.1"` | NGC model URI |
| customizer.customizationTargets.targets."nvidia/nemotron-nano-llama-3.1-8b@1.0".name | string | `"nemotron-nano-llama-3.1-8b@1.0"` | The name for target model. |
| customizer.customizationTargets.targets."nvidia/nemotron-nano-llama-3.1-8b@1.0".namespace | string | `"nvidia"` | The namespace for target model. |
| customizer.customizationTargets.targets."nvidia/nemotron-nano-llama-3.1-8b@1.0".num_parameters | int | `8000000000` | Number of model parameters. |
| customizer.customizationTargets.targets."nvidia/nemotron-nano-llama-3.1-8b@1.0".precision | string | `"bf16-mixed"` | Model precision format. |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.0" | object | This object has the following default values for the Nemotron Super Llama 3.3 49B Instruct model. | Nemotron Super Llama 3.3 49B Instruct model target configuration. |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.0".base_model | string | `"nvidia/llama-3.3-nemotron-super-49b-v1"` | Mapping to the model name in NIM and Recipe Selection in Customizer. Defaults to being the same as the the configuration entry namespace/name. |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.0".enabled | bool | `false` | Whether to enable the model. |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.0".model_path | string | `"nemotron-super-3_3-49b_v1"` | Path where model files are stored. |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.0".model_uri | string | `"ngc://nvidia/nemo/nemotron-super-3_3-49b:v1"` | NGC model URI |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.0".name | string | `"nemotron-super-llama-3.3-49b@1.0"` | The name for target model. |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.0".namespace | string | `"nvidia"` | The namespace for target model. |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.0".num_parameters | int | `4900000000` | Number of model parameters. |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.0".precision | string | `"bf16-mixed"` | Model precision format. |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.5" | object | This object has the following default values for the Nemotron Super Llama 3.3 49B v1.5 Instruct model. | Nemotron Super Llama 3.3 49B v1.5 Instruct model target configuration. |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.5".base_model | string | `"nvidia/llama-3.3-nemotron-super-49b-v1.5"` | Mapping to the model name in NIM and Recipe Selection in Customizer. Defaults to being the same as the the configuration entry namespace/name. |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.5".enabled | bool | `false` | Whether to enable the model. |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.5".hf_endpoint | string | `"https://huggingface.co"` | Endpoint for where to find this model |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.5".model_path | string | `"nemotron-super-3_3-49b_v1_5"` | Path where model files are stored. |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.5".model_uri | string | `"hf://nvidia/Llama-3_3-Nemotron-Super-49B-v1_5"` | NGC model URI |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.5".name | string | `"nemotron-super-llama-3.3-49b@1.5"` | The name for target model. |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.5".namespace | string | `"nvidia"` | The namespace for target model. |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.5".num_parameters | int | `4900000000` | Number of model parameters. |
| customizer.customizationTargets.targets."nvidia/nemotron-super-llama-3.3-49b@1.5".precision | string | `"bf16-mixed"` | Model precision format. |
| customizer.customizationTargets.targets.mistralai/ministral-3-3B-reasoning-2512@v1 | object | This object has the following default values for the mistralai/Ministral-3-3B-Reasoning-2512. | mistralai/Ministral-3-3B-Reasoning-2512 target model configuration. |
| customizer.customizationTargets.targets.mistralai/ministral-3-3B-reasoning-2512@v1.base_model | string | `"mistralai/Ministral-3-3B-Reasoning-2512"` | Mapping to the model name to the optimized llama embedding training script and NIM |
| customizer.customizationTargets.targets.mistralai/ministral-3-3B-reasoning-2512@v1.enabled | bool | `false` | Whether to enable the model. |
| customizer.customizationTargets.targets.mistralai/ministral-3-3B-reasoning-2512@v1.hf_endpoint | string | `"https://huggingface.co"` | HF endpoint |
| customizer.customizationTargets.targets.mistralai/ministral-3-3B-reasoning-2512@v1.model_path | string | `"mistral-3-3b-reasoning-2512"` | Path where model files are stored. |
| customizer.customizationTargets.targets.mistralai/ministral-3-3B-reasoning-2512@v1.model_uri | string | `"hf://mistralai/Ministral-3-3B-Reasoning-2512"` | HF model URI |
| customizer.customizationTargets.targets.mistralai/ministral-3-3B-reasoning-2512@v1.name | string | `"ministral-3-3B-reasoning-2512@v1"` | The name for target model. |
| customizer.customizationTargets.targets.mistralai/ministral-3-3B-reasoning-2512@v1.namespace | string | `"mistralai"` | The namespace for target model. |
| customizer.customizationTargets.targets.mistralai/ministral-3-3B-reasoning-2512@v1.num_parameters | int | `3400000000` | Number of model parameters. |
| customizer.customizationTargets.targets.mistralai/ministral-3-3B-reasoning-2512@v1.precision | string | `"bf16-mixed"` | Model precision format. |
| customizer.customizationTargets.targets.nvidia/nemotron-nano-9b-v2@v1 | object | This object has the following default values for the nvidia/nemotron-nano-9b-v2 model. | nvidia/nemotron-nano-9b-v2 target model configuration. |
| customizer.customizationTargets.targets.nvidia/nemotron-nano-9b-v2@v1.base_model | string | `"nvidia/nemotron-nano-9b-v2"` | Mapping to the model name to the optimized llama embedding training script and NIM |
| customizer.customizationTargets.targets.nvidia/nemotron-nano-9b-v2@v1.enabled | bool | `false` | Whether to enable the model. |
| customizer.customizationTargets.targets.nvidia/nemotron-nano-9b-v2@v1.hf_endpoint | string | `"https://huggingface.co"` | HF endpoint |
| customizer.customizationTargets.targets.nvidia/nemotron-nano-9b-v2@v1.model_path | string | `"nemotron_nano_9b_v2"` | Path where model files are stored. |
| customizer.customizationTargets.targets.nvidia/nemotron-nano-9b-v2@v1.model_uri | string | `"hf://nvidia/NVIDIA-Nemotron-Nano-9B-v2"` | HF model URI |
| customizer.customizationTargets.targets.nvidia/nemotron-nano-9b-v2@v1.name | string | `"nemotron-nano-9b-v2@v1"` | The name for target model. |
| customizer.customizationTargets.targets.nvidia/nemotron-nano-9b-v2@v1.namespace | string | `"nvidia"` | The namespace for target model. |
| customizer.customizationTargets.targets.nvidia/nemotron-nano-9b-v2@v1.num_parameters | int | `9000000000` | Number of model parameters. |
| customizer.customizationTargets.targets.nvidia/nemotron-nano-9b-v2@v1.precision | string | `"bf16-mixed"` | Model precision format. |
| customizer.customizationTargets.targets.openai/gpt-oss-20b@v1 | object | This object has the following default values for the openai/gpt-oss-20b model. | openai/gpt-oss-20b target model configuration. |
| customizer.customizationTargets.targets.openai/gpt-oss-20b@v1.base_model | string | `"openai/gpt-oss-20b"` | Mapping to the model name to the optimized llama embedding training script and NIM |
| customizer.customizationTargets.targets.openai/gpt-oss-20b@v1.enabled | bool | `false` | Whether to enable the model. |
| customizer.customizationTargets.targets.openai/gpt-oss-20b@v1.hf_endpoint | string | `"https://huggingface.co"` | HF endpoint |
| customizer.customizationTargets.targets.openai/gpt-oss-20b@v1.model_path | string | `"gpt_oss_20b"` | Path where model files are stored. |
| customizer.customizationTargets.targets.openai/gpt-oss-20b@v1.model_uri | string | `"hf://openai/gpt-oss-20b"` | HF model URI |
| customizer.customizationTargets.targets.openai/gpt-oss-20b@v1.name | string | `"gpt-oss-20b@v1"` | The name for target model. |
| customizer.customizationTargets.targets.openai/gpt-oss-20b@v1.namespace | string | `"openai"` | The namespace for target model. |
| customizer.customizationTargets.targets.openai/gpt-oss-20b@v1.num_parameters | int | `21000000000` | Number of model parameters. |
| customizer.customizationTargets.targets.openai/gpt-oss-20b@v1.precision | string | `"bf16-mixed"` | Model precision format. |
| customizer.customizerConfig | object | This object has default values for the following fields. | Configuration for the NeMo Customizer microservice. |
| customizer.customizerConfig.entityStoreURL | string | `"http://nemo-entity-store:8000"` | Specifies the internal K8s DNS record for the NeMo Entity Store service. |
| customizer.customizerConfig.mlflowURL | string | `""` | URL for the MLflow tracking server. |
| customizer.customizerConfig.nemoDataStoreURL | string | `"http://nemo-data-store:3000"` | Specifies the internal K8s DNS record for the NeMo Data Store service. |
| customizer.customizerConfig.openTelemetry | object | This object has the following default values for the OpenTelemetry settings. | OpenTelemetry settings. |
| customizer.customizerConfig.openTelemetry.enabled | bool | `true` | Whether to enable OpenTelemetry. |
| customizer.customizerConfig.openTelemetry.exporterOtlpEndpoint | string | `""` | Endpoint to access a custom OTLP collector listening on port 4317. Example: "http://$(HOST_IP):4317". |
| customizer.customizerConfig.openTelemetry.logsExporter | string | `"otlp"` | Sets the logs exporter type (otlp, console, none). |
| customizer.customizerConfig.openTelemetry.metricsExporter | string | `"otlp"` | Sets the metrics exporter type (otlp, console, none). |
| customizer.customizerConfig.openTelemetry.tracesExporter | string | `"otlp"` | Sets the traces exporter type (otlp, console, none). |
| customizer.customizerConfig.tolerations | list | `[]` | Tolerations on the customization job pods. |
| customizer.customizerConfig.training | object | This object has the following default values for the training configuration. | Training configuration for customization jobs. |
| customizer.customizerConfig.training.container_defaults | object | `{"env":null,"imagePullPolicy":"IfNotPresent","securityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}}` | Default container configuration for training jobs. |
| customizer.customizerConfig.training.container_defaults.env | string | `nil` | Environment variables for the training container. Cannot override env variables reserved by NeMo Customizer. |
| customizer.customizerConfig.training.poll_interval_seconds | int | `10` | Interval in seconds to poll for monitoring jobs. Defaults to 10s. poll_interval_seconds with a 30 second pad must be less than ttl_seconds_after_finished. |
| customizer.customizerConfig.training.pvc.name | string | `nil` | The name of a single PVC to be used for training. If null, create a separate PVC per training job for isolation. If provided, it will create this PVC. |
| customizer.customizerConfig.training.pvc.size | string | `"5Gi"` | Size of the training job PVC. |
| customizer.customizerConfig.training.pvc.storageClass | string | `""` | Storage class for the training job PVC. |
| customizer.customizerConfig.training.pvc.volumeAccessMode | string | `"ReadWriteOnce"` | Volume access mode for the training job PVC. |
| customizer.customizerConfig.training.queue | string | `"default"` | Queue name used by the underlying scheduler of NemoTrainingJob. Maps to "resourceGroup" in NemoTrainingJob. |
| customizer.customizerConfig.training.ttl_seconds_after_finished | int | `3600` | Time to live in seconds after the training job pod completes. Defaults to 1h. Take precautions when setting ttl_seconds_after_finished to 0 which disables automatic clean up for jobs. When disabled, jobs will persist and hold on to resources like PVCs and will require manual or external clean up. ttl_seconds_after_finished must be greater than poll_interval_seconds with a 30 second pad. |
| customizer.customizerConfig.training.workspace_dir | string | `"/pvc/workspace"` | Directory path for training workspace. |
| customizer.customizerConfig.trainingNetworking | list | `[{"name":"NCCL_IB_SL","value":0},{"name":"NCCL_IB_TC","value":41},{"name":"NCCL_IB_QPS_PER_CONNECTION","value":4},{"name":"UCX_TLS","value":"TCP"},{"name":"UCX_NET_DEVICES","value":"eth0"},{"name":"HCOLL_ENABLE_MCAST_ALL","value":0},{"name":"NCCL_IB_GID_INDEX","value":3}]` | Network configuration for training jobs on Oracle Kubernetes Engine (OKE) on Oracle Cloud Infrastructure (OCI). |
| customizer.customizerConfig.wandb | object | `{"entity":null,"project":"nvidia-nemo-customizer"}` | Weights and Biases (WandB) Python SDK intialization configuration for logging and monitoring training jobs in WandB. |
| customizer.customizerConfig.wandb.entity | string | `nil` | Reference: https://docs.wandb.ai/ref/python/init/ |
| customizer.env | object | `{"JOB_CLEANUP_TTL_SEC":"3600","JOB_LOGS_POLLING_INTERVAL":"600","JOB_STATUS_POLLING_INTERVAL":"15","MAX_PENDING_JOB_MINUTES":"30","MAX_TRAINING_JOB_STATUS_FAILURES":"10","TRAINING_JOB_CREATION_FAILURE_SLEEP_INTERVAL":"15"}` | A map of environment variables to inject into the NeMo Customizer app container. Example:  `{HOST_IP:   valueFrom:     fieldRef:       fieldPath: status.hostIP OTEL_EXPORTER_OTLP_ENDPOINT: "http://$(HOST_IP):4317"}` |
| customizer.externalDatabase | object | This object has the following default values for the external PostgreSQL configuration. | External PostgreSQL configuration. |
| customizer.externalDatabase.database | string | `"finetuning"` | Name of the database to use. |
| customizer.externalDatabase.existingSecret | string | `""` | Name of an existing secret resource containing the database credentials. |
| customizer.externalDatabase.existingSecretPasswordKey | string | `""` | Name of an existing secret key containing the database credentials. |
| customizer.externalDatabase.host | string | `"localhost"` | External database host address. |
| customizer.externalDatabase.port | int | `5432` | External database port number. |
| customizer.externalDatabase.user | string | `"nemo"` | Database username for the NeMo Customizer microservice. |
| customizer.fullnameOverride | string | `""` | String to fully override the chart and release name on resulting objects when deployed. |
| customizer.hfAPISecret | string | `nil` | The K8s Secret containing the HuggingFace API token. |
| customizer.hfAPISecretKey | string | `"HF_TOKEN"` | The key in the hfAPISecret containing the actual secret's value. Defaults to HF_TOKEN |
| customizer.image | object | This object has the following default values for the NeMo Customizer microservice image. | NeMo Customizer image that supports training and standalone mode. |
| customizer.image.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for the NeMo Customizer image. |
| customizer.image.registry | string | `"nvcr.io"` | Registry for the NeMo Customizer image. |
| customizer.image.repository | string | `"nvidia/nemo-microservices/customizer"` | Repository for the NeMo Customizer image. |
| customizer.imagePullSecrets | list | `[{"name":"nvcrimagepullsecret"}]` | Image pull secrets configuration. |
| customizer.livenessProbe.failureThreshold | int | `15` |  |
| customizer.livenessProbe.initialDelaySeconds | int | `30` |  |
| customizer.livenessProbe.timeoutSeconds | int | `15` |  |
| customizer.logging | object | `{"logHealthEndpoints":false,"logLevel":"INFO"}` | Logging configuration. |
| customizer.logging.logHealthEndpoints | bool | `false` | Enable logging for health endpoints. |
| customizer.logging.logLevel | string | `"INFO"` | Log level for the application. |
| customizer.modelDownloader | object | This object has the following default values for the model downloader. | Download models to PVC model cache configuration. |
| customizer.modelDownloader.securityContext | object | `{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}` | Security context for the model downloader. |
| customizer.modelDownloader.ttlSecondsAfterFinished | int | `1800` | Time to live in seconds after the job finishes. |
| customizer.modelsStorage | object | `{"accessModes":["ReadWriteOnce"],"enabled":true,"size":"100Gi","storageClassName":""}` | Configure the PVC for models mount, where we store the parent/base models. |
| customizer.modelsStorage.accessModes | list | `["ReadWriteOnce"]` | Access modes for the persistent volume. |
| customizer.modelsStorage.enabled | bool | `true` | Enable persistent volume for model storage. |
| customizer.modelsStorage.size | string | `"100Gi"` | Size of the persistent volume. |
| customizer.modelsStorage.storageClassName | string | `""` | Storage class name for the models PVC. Empty string uses the default storage class. |
| customizer.nameOverride | string | `""` | String to override chart name on resulting objects when deployed. |
| customizer.nemoDataStoreTools | object | This object has the following default values for the NeMo Data Store tools image. | Tools configuration for downloading and uploading entities to NeMo Data Store. |
| customizer.nemoDataStoreTools.imagePullSecret | string | `"nvcrimagepullsecret"` | Image pull secret for the NeMo Data Store tools image. |
| customizer.nemoDataStoreTools.registry | string | `"nvcr.io"` | Registry for the NeMo Data Store tools image. |
| customizer.nemoDataStoreTools.repository | string | `"nvidia/nemo-microservices/nds-v2-huggingface-cli"` | Repository for the NeMo Data Store tools image. |
| customizer.nemoDataStoreTools.tag | string | `""` | Tag for the NeMo Data Store tools image. |
| customizer.nemoRlImage | object | This object has the following default values for the NeMo Customizer RL image. | NeMo Customizer RL image that provides alignment training functionality for the NeMo Customizer ecosystem. |
| customizer.nemoRlImage.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for the NeMo Customizer training image used for alignment. |
| customizer.nemoRlImage.registry | string | `"nvcr.io"` | Registry for the NeMo Customizer training image used for alignment. |
| customizer.nemoRlImage.repository | string | `"nvidia/nemo-microservices/customizer-rl"` | Repository for the NeMo Customizer training image used for alignment. |
| customizer.ngcAPISecret | string | `"ngc-api"` | Secret used for auto hydrating the model cache from NGC for enabled models. |
| customizer.ngcAPISecretKey | string | `"NGC_API_KEY"` | Key in the NGC API secret containing the API key. |
| customizer.opentelemetry-collector | object | This object has the following default values for the Open Telemetry Collector configuration. | Open Telemetry Collector configuration. |
| customizer.opentelemetry-collector.config | object | `{"exporters":{"debug":{"verbosity":"detailed"}},"extensions":{"health_check":{},"zpages":{"endpoint":"0.0.0.0:55679"}},"processors":{"batch":{}},"receivers":{"otlp":{"protocols":{"grpc":{},"http":{"cors":{"allowed_origins":["*"]}}}}},"service":{"extensions":["zpages","health_check"],"pipelines":{"logs":{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]},"metrics":{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]},"traces":{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]}}}}` | Base collector configuration for Open Telemetry Collector. |
| customizer.opentelemetry-collector.enabled | bool | `true` | Switch to enable or disable Open Telemetry Collector. |
| customizer.opentelemetry-collector.image.repository | string | `"otel/opentelemetry-collector-k8s"` | Repository for Open Telemetry Collector image. |
| customizer.opentelemetry-collector.image.tag | string | `"0.102.1"` | Overrides the image tag whose default is the chart appVersion. |
| customizer.opentelemetry-collector.mode | string | `"deployment"` | Deployment mode for Open Telemetry Collector. Valid values are "daemonset", "deployment", and "statefulset". |
| customizer.postgresql | object | This object has the following default values for the PostgreSQL configuration. | PostgreSQL configuration for the NeMo Customizer microservice. |
| customizer.postgresql.architecture | string | `"standalone"` | PostgreSQL architecture (`standalone` or `replication`). |
| customizer.postgresql.auth.database | string | `"finetuning"` | Name for a custom database to create. |
| customizer.postgresql.auth.enablePostgresUser | bool | `true` | Whether to assign a password to the "postgres" admin user. Otherwise, remote access will be blocked for this user. |
| customizer.postgresql.auth.existingSecret | string | `""` | Name of existing secret to use for PostgreSQL credentials. |
| customizer.postgresql.auth.password | string | `"nemo"` | Password for the custom user to create. |
| customizer.postgresql.auth.username | string | `"nemo"` | Name for a custom user to create. |
| customizer.postgresql.enabled | bool | `true` | Whether to enable or disable the PostgreSQL helm chart. |
| customizer.postgresql.nameOverride | string | `"customizerdb"` | The name override for the Customizer PostgreSQL database. |
| customizer.postgresql.serviceAccount.create | bool | `true` | Specifies whether to create a new service account for PostgreSQL. |
| customizer.readinessProbe.failureThreshold | int | `15` |  |
| customizer.readinessProbe.initialDelaySeconds | int | `30` |  |
| customizer.readinessProbe.timeoutSeconds | int | `15` |  |
| customizer.replicaCount | int | `1` | Number of replicas to deploy. |
| customizer.service | object | `{"internalPort":9009,"port":8000,"type":"ClusterIP"}` | Service configuration. |
| customizer.service.internalPort | int | `9009` | Internal port for the service. |
| customizer.service.port | int | `8000` | External port for the service. |
| customizer.service.type | string | `"ClusterIP"` | Type of Kubernetes service to create. |
| customizer.serviceAccount | object | `{"annotations":{},"automountServiceAccountToken":true,"create":true,"name":""}` | Service account configuration. |
| customizer.serviceAccount.annotations | object | `{}` | Annotations to add to the service account. |
| customizer.serviceAccount.automountServiceAccountToken | bool | `true` | Automatically mount a ServiceAccount's API credentials. |
| customizer.serviceAccount.create | bool | `true` | Specifies whether a service account should be created. |
| customizer.serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated. |
| customizer.serviceName | string | `"nemo-customizer"` | Sets predictable name for the NeMo Customizer Kubernetes service |
| customizer.useRunAIExecutor | bool | `false` | Enable or disable RunAI executor. |
| customizer.wandb | object | This object has the following default values for the WandB configuration. | WandB configuration. |
| customizer.wandb.existingSecret | string | `""` | Name of an existing Kubernetes secret resource for the WandB encryption secret. |
| customizer.wandb.existingSecretKey | string | `""` | Name of the key in the existing WandB secret containing the secret value. The secret value must be exactly 32 alphanumeric characters: ^[a-zA-Z0-9]{32}$ |
| customizer.wandb.secretValue | string | `"ec60d96b639764ccf9859bc10d4363d1"` | WandB secret value. Must contain exactly 32 alphanumeric characters. Creates a new Kubernetes secret named "wandb-secret" with key-value pair "encryption_key=<wandb.secretValue>". Ignored if wandb.existingSecret is set. |
| data-designer.affinity | object | `{}` | Affinity configuration for the deployment. |
| data-designer.autoscaling | object | `{"enabled":false,"maxReplicas":10,"minReplicas":1,"targetCPUUtilizationPercentage":80}` | Autoscaling configuration. |
| data-designer.config | object | `{"default_model_configs":[],"log_level":"INFO","model_provider_registry":{"default":"nimproxy","providers":[{"endpoint":"http://nemo-nim-proxy:8000/v1","name":"nimproxy"}]},"port":8000,"preview_num_records":{"default":10,"max":10},"seed_dataset_source_registry":{"sources":[{"endpoint":"http://nemo-data-store:3000/v1/hf"}]}}` | Data Designer application settings |
| data-designer.config.default_model_configs | list | `[]` | A list of default model configs available in all dataset generation requests |
| data-designer.config.model_provider_registry | object | `{"default":"nimproxy","providers":[{"endpoint":"http://nemo-nim-proxy:8000/v1","name":"nimproxy"}]}` | The configuration for supported model providers |
| data-designer.config.preview_num_records.default | int | `10` | The default number of records to return when generating a preview dataset |
| data-designer.config.preview_num_records.max | int | `10` | The maximum number of records to allow when generating a preview dataset |
| data-designer.config.seed_dataset_source_registry | object | `{"sources":[{"endpoint":"http://nemo-data-store:3000/v1/hf"}]}` | The configuration for supported seed dataset sources |
| data-designer.env | object | `{}` | Environment variables for the Data Designer container. |
| data-designer.fullnameOverride | string | `""` | Overrides the full chart name. |
| data-designer.image.pullPolicy | string | `"IfNotPresent"` | The image pull policy for the NeMo Data Designer container image. |
| data-designer.image.repository | string | `"nvcr.io/nvidia/nemo-microservices/data-designer"` | The repository location of the NeMo Data Designer container image. |
| data-designer.image.tag | string | `""` | The tag of the NeMo Data Designer container image. |
| data-designer.imagePullSecrets | list | `[]` | Specifies the list of secret names that are needed for the main container and any init containers. |
| data-designer.livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/health","port":"http"},"initialDelaySeconds":30,"periodSeconds":10,"timeoutSeconds":5}` | Liveness probe configuration. |
| data-designer.nameOverride | string | `""` | Overrides the chart name. |
| data-designer.nodeSelector | object | `{}` | Additional node selector configuration for the deployment. |
| data-designer.podAnnotations | object | `{}` | Specifies additional annotations to the main deployment pods. |
| data-designer.podLabels | object | `{}` | Specifies additional labels to the main deployment pods. |
| data-designer.podSecurityContext | object | `{"fsGroup":1000}` | Specifies privilege and access control settings for the pod. |
| data-designer.podSecurityContext.fsGroup | int | `1000` | Specifies the file system owner group id. |
| data-designer.readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/health","port":"http"},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3}` | Readiness probe configuration. |
| data-designer.replicaCount | int | `1` | Number of replicas for the NeMo Data Designer deployment. |
| data-designer.resources | object | `{}` | Resource requests and limits. |
| data-designer.securityContext | string | `nil` | Specifies security context for the container. |
| data-designer.service | object | `{"port":8000,"type":"ClusterIP"}` | Specifies the service type and the port for the deployment. |
| data-designer.serviceAccount.annotations | object | `{}` | Annotations to be added to the service account. |
| data-designer.serviceAccount.automount | bool | `true` | Whether to automatically mount the service account token. |
| data-designer.serviceAccount.create | bool | `true` | Whether to create a service account for the NeMo Data Designer microservice. |
| data-designer.serviceAccount.name | string | `""` | The name of the service account to use. |
| data-designer.serviceName | string | `"nemo-data-designer"` | The service name for the NeMo Data Designer microservice. |
| data-designer.tolerations | list | `[]` | Additional tolerations for the deployment. |
| data-designer.volumeMounts | list | `[]` | Additional volume mounts for the deployment. |
| data-designer.volumes | list | `[]` | Additional volumes for the deployment. |
| data-store.additionalConfigFromEnvs | list | `[]` | Additional configuration sources from environment variables. |
| data-store.additionalConfigSources | list | `[]` | Additional configuration from secret or configmap. |
| data-store.admin | object | `{"email":"datastore@local.domain","existingSecret":null,"password":"s3aJPHD9!bt6d0I","username":"datastore_admin"}` | Admin user configuration settings. |
| data-store.admin.email | string | `"datastore@local.domain"` | Email for the NeMo Data Store admin user. |
| data-store.admin.existingSecret | string | `nil` | Use an existing secret to store admin user credentials. For example, `datastore-admin-secret`. |
| data-store.admin.password | string | `"s3aJPHD9!bt6d0I"` | Password for the NeMo Data Store admin user. |
| data-store.admin.username | string | `"datastore_admin"` | Username for the NeMo Data Store admin user. |
| data-store.affinity | object | `{}` | Affinity configuration for the deployment. |
| data-store.checkDeprecation | bool | `true` | Set to false to skip the basic validation check. |
| data-store.clusterDomain | string | `"cluster.local"` | Kubernetes cluster domain name. |
| data-store.config | object | This object has the following default values for the NeMo Data Store configuration. | NeMo Data Store configuration. |
| data-store.config."cron.GIT_GC_REPOS".enabled | bool | `false` | Enable git garbage collection. |
| data-store.config.APP_NAME | string | `"Datastore"` | Application name. |
| data-store.config.RUN_MODE | string | `"prod"` | Runtime mode (prod/dev). |
| data-store.config.cache.ADAPTER | string | `"memory"` | Cache adapter type. |
| data-store.config.database.DB_TYPE | string | `"postgres"` | Database type. |
| data-store.config.lfs.STORAGE_TYPE | string | `"local"` | Storage type for LFS (local/s3). |
| data-store.config.queue.TYPE | string | `"dummy"` | Queue type. |
| data-store.config.server.HTTP_PORT | int | `3000` | HTTP port for web interface. |
| data-store.config.server.LFS_START_SERVER | bool | `true` | Enable LFS server. |
| data-store.config.server.START_SSH_SERVER | bool | `false` | Enable SSH server. |
| data-store.config.session.PROVIDER | string | `"memory"` | Session provider type. |
| data-store.containerSecurityContext | object | `{}` | Container-level security context settings |
| data-store.demo | object | This object has the following default values for the demo parameters. | Parameters for the demo mode. |
| data-store.demo.enabled | bool | `false` | Enable or disable the demo mode. |
| data-store.demo.ngcApiKey | string | `""` | NGC API key. |
| data-store.demo.ngcImagePullSecret | string | `"ngc-image-pull-secret"` | Name of the secret containing the NGC image pull secret. |
| data-store.deployment | object | `{"annotations":{},"labels":{},"terminationGracePeriodSeconds":60}` | Deployment configuration. |
| data-store.deployment.annotations | object | `{}` | Annotations for the Datastore deployment to be created. |
| data-store.deployment.labels | object | `{}` | Labels for the deployment. |
| data-store.deployment.terminationGracePeriodSeconds | int | `60` | How long to wait until forcefully kill the pod. |
| data-store.dnsConfig | object | `{}` | dnsConfig configuration for the deployment. |
| data-store.env | object | `{}` | Additional environment variables to pass to containers. This is an object formatted like NAME: value or NAME: valueFrom: {object}. |
| data-store.external | object | `{"domain":"data-store.test","rootUrl":"http://data-store.test"}` | External URL configuration for the NeMo Data Store microservice. |
| data-store.external.domain | string | `"data-store.test"` | The external URL's domain name. |
| data-store.external.rootUrl | string | `"http://data-store.test"` | The external URL where users will access the NeMo Data Store microservice. |
| data-store.externalDatabase | object | This object has the following default values for the external PostgreSQL configuration. | External PostgreSQL configuration settings. These values are only used when postgresql.enabled is set to false. |
| data-store.externalDatabase.database | string | `""` | Datastore database name. |
| data-store.externalDatabase.existingSecret | string | `""` | Name of an existing secret resource containing the database credentials. |
| data-store.externalDatabase.existingSecretPasswordKey | string | `""` | Name of an existing secret key containing the database credentials. |
| data-store.externalDatabase.host | string | `""` | External database host address. |
| data-store.externalDatabase.port | int | `5432` | External database port number. |
| data-store.externalDatabase.sslMode | string | `"disable"` | SSL mode for external database connection. |
| data-store.externalDatabase.user | string | `""` | Database username for Datastore service. |
| data-store.extraContainerVolumeMounts | list | `[]` | Mounts that are only mapped into the Datastore runtime/main container, to e.g. override custom templates. |
| data-store.extraDeploy | list | `[]` | Array of extra objects to deploy with the release. |
| data-store.extraInitVolumeMounts | list | `[]` | Mounts that are only mapped into the init-containers. Can be used for additional preconfiguration. |
| data-store.extraVolumeMounts | list | `[]` | **DEPRECATED** Additional volume mounts for init containers and the Datastore main container. This value is split into the following two variables: `extraContainerVolumeMounts` and `extraInitVolumeMounts`. |
| data-store.extraVolumes | list | `[]` | Additional volumes to mount to the Datastore deployment. |
| data-store.global | object | `{"hostAliases":[],"imagePullSecrets":[],"imageRegistry":"","storageClass":""}` | Global parameters to override the same settings in all subcharts of the data-store Helm chart. |
| data-store.global.hostAliases | list | `[]` | Global host aliases which will be added to the pod's hosts files. |
| data-store.global.imagePullSecrets | list | `[]` | Global image pull secrets. |
| data-store.global.imageRegistry | string | `""` | Global image registry. |
| data-store.global.storageClass | string | `""` | Global storage class that applies to persistent volumes. |
| data-store.image | object | This object has the following default values for the image configuration. | Container image configuration settings |
| data-store.image.digest | string | `""` | The image digest to use for more precise version control. |
| data-store.image.fullOverride | string | `""` | Complete override string for the image specification. |
| data-store.image.pullPolicy | string | `"IfNotPresent"` | The image pull policy determining when to pull new images. |
| data-store.image.registry | string | `"nvcr.io"` | The registry where the NeMo Data Store image is located. |
| data-store.image.repository | string | `"nvidia/nemo-microservices/datastore"` | The repository path of the NeMo Data Store image. |
| data-store.image.rootless | bool | `true` | Whether to run the container with rootless security context. |
| data-store.image.tag | string | `""` | The image tag to use. |
| data-store.imagePullSecrets | list | `[{"name":"nvcrimagepullsecret"}]` | Configuration for image pull secrets to access private registries. |
| data-store.imagePullSecrets[0] | object | `{"name":"nvcrimagepullsecret"}` | Name of the secret containing registry credentials. |
| data-store.initContainers | object | `{"resources":{"limits":{},"requests":{"cpu":"100m","memory":"128Mi"}}}` | Kubernetes resource limits for init containers. |
| data-store.initContainers.resources.limits | object | `{}` | Kubernetes resource limits for init containers. |
| data-store.initContainers.resources.requests | object | `{"cpu":"100m","memory":"128Mi"}` | Kubernetes cpu resource limits for init containers. |
| data-store.initPreScript | string | `""` | Init container Bash shell scripts. For example, to mount a client certificate when connecting to an external Postgres server, you might add commands similar to the following:   `mkdir -p /data/git/.postgresql`,   `cp /pg-ssl/* /data/git/.postgresql/`,   `chown -R git:git /data/git/.postgresql/`,   `chmod 400 /data/git/.postgresql/postgresql.key` |
| data-store.jwtSecret | object | This object has the following default values for the JWT secret configuration. | JWT secret configuration settings. |
| data-store.jwtSecret.existingSecret | string | `""` | Name of an existing secret resource containing the LFS JWT secret. |
| data-store.jwtSecret.existingSecretKey | string | `""` | Key in existing secret containing the LFS JWT secret. |
| data-store.jwtSecret.value | string | `""` | User specified LFS JWT secret - this will be stored in a secret. |
| data-store.ldap | list | `[]` | LDAP configuration. |
| data-store.livenessProbe | object | This object has the following default values for the liveness probe configuration. | Liveness probe configuration. |
| data-store.livenessProbe.enabled | bool | `true` | Enable liveness probe. |
| data-store.livenessProbe.failureThreshold | int | `20` | Failure threshold for liveness probe. |
| data-store.livenessProbe.httpGet.path | string | `"/v1/health"` | HTTP path for liveness probe. |
| data-store.livenessProbe.httpGet.port | string | `"http"` | Port for liveness probe. |
| data-store.livenessProbe.initialDelaySeconds | int | `10` | Initial delay before liveness probe is initiated. |
| data-store.livenessProbe.periodSeconds | int | `30` | Period for liveness probe. |
| data-store.livenessProbe.successThreshold | int | `1` | Success threshold for liveness probe. |
| data-store.livenessProbe.timeoutSeconds | int | `5` | Timeout for liveness probe. |
| data-store.metrics.enabled | bool | `false` | Enable NeMo Data Store metrics. Also requires setting env variable GITEA__metrics__ENABLED: "true" |
| data-store.metrics.serviceMonitor.enabled | bool | `false` | Enable NeMo Data Store metrics service monitor. |
| data-store.nodeSelector | object | `{}` | NodeSelector configuration for the deployment. |
| data-store.oauth | list | `[]` | OAuth configuration. |
| data-store.objectStore | object | This object has the following default values for the object store configuration. | Object Store configuration settings for accessing external Object Storage. |
| data-store.objectStore.accessKey | string | `""` | Access key credential for object storage authentication. |
| data-store.objectStore.accessSecret | string | `""` | Secret key credential for object storage authentication. |
| data-store.objectStore.bucketName | string | `"datastore"` | Name of the bucket to use for object storage. |
| data-store.objectStore.enabled | bool | `false` | Enable or disable object storage integration. |
| data-store.objectStore.endpoint | string | `""` | Object storage service endpoint URL. |
| data-store.objectStore.existingSecret | string | `""` | Name of existing Kubernetes secret containing object storage credentials. |
| data-store.objectStore.existingSecretAccessKey | string | `""` | Key in existing secret that contains the access key. |
| data-store.objectStore.existingSecretAccessSecret | string | `""` | Key in existing secret that contains the secret key. |
| data-store.objectStore.region | string | `""` | Geographic region for the object storage service. |
| data-store.objectStore.ssl | bool | `false` | Enable or disable SSL/TLS for object storage connections. |
| data-store.persistence | object | This object has the following default values for the persistence volume configuration. | Persistence volume configuration. |
| data-store.persistence.accessModes | list | `["ReadWriteOnce"]` | Access modes for the persistent volume. |
| data-store.persistence.annotations | object | `{"helm.sh/resource-policy":"keep"}` | Annotations for the persistence volume claim. |
| data-store.persistence.claimName | string | `"datastore-shared-storage"` | Name of the persistent volume claim. You can use an existing claim to store repository information. |
| data-store.persistence.create | bool | `true` | Whether to create the persistent volume claim for shared storage. |
| data-store.persistence.enabled | bool | `true` | Whether to enable persistent volume. |
| data-store.persistence.labels | object | `{}` | Labels for the persistence volume claim. |
| data-store.persistence.mount | bool | `true` | Whether to mount the persistent volume claim. |
| data-store.persistence.size | string | `"100Gi"` | The size of the persistent volume. |
| data-store.persistence.storageClass | string | `nil` | Name of the storage class to use. |
| data-store.persistence.subPath | string | `nil` | Subdirectory of the volume to mount at. |
| data-store.persistence.volumeName | string | `""` | Name of persistent volume in PVC. |
| data-store.podAnnotations | object | `{}` | Annotations for the Datastore pod. |
| data-store.podDisruptionBudget | object | `{}` | Pod disruption budget configuration. |
| data-store.podSecurityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"}` | Pod-level security context settings |
| data-store.podSecurityContext.fsGroup | int | `1000` | The file system group ID to use for all containers. |
| data-store.podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` | Set the permission change policy for mounted PVCs. |
| data-store.postgresql-ha | object | This object has the following default values for the PostgreSQL HA configuration. | PostgreSQL high availability (HA) configuration. |
| data-store.postgresql-ha.enabled | bool | `false` | Enable PostgreSQL HA. If enabled, configures PostgreSQL HA using the [bitnami/postgresql-ha](https://github.com/bitnami/charts/tree/main/bitnami/postgresql-ha) chart. |
| data-store.postgresql-ha.global.postgresql.database | string | `"datastore"` | Global PostgreSQL database name. |
| data-store.postgresql-ha.global.postgresql.password | string | `"datastore"` | Global password for the `datastore` user. |
| data-store.postgresql-ha.global.postgresql.username | string | `"datastore"` | Global username for the `datastore` user. |
| data-store.postgresql-ha.pgpool.adminPassword | string | `"changeme3"` | Pgpool admin password. |
| data-store.postgresql-ha.postgresql.password | string | `"changeme4"` | Password for the `datastore` user. |
| data-store.postgresql-ha.postgresql.postgresPassword | string | `"changeme1"` | Postgres password for the `datastore` user. |
| data-store.postgresql-ha.postgresql.repmgrPassword | string | `"changeme2"` | Repmgr password for the `datastore` user. |
| data-store.postgresql-ha.primary.persistence | object | `{"size":"10Gi"}` | PVC storage request for PostgreSQL HA volume. |
| data-store.postgresql-ha.service.ports | object | `{"postgresql":5432}` | PostgreSQL service port. |
| data-store.postgresql.enabled | bool | `true` | Enable or disable the built-in PostgreSQL database. |
| data-store.postgresql.global.postgresql.auth.database | string | `"datastore"` | Name of the database to create. |
| data-store.postgresql.global.postgresql.auth.password | string | `"datastore"` | Password for the datastore database user. |
| data-store.postgresql.global.postgresql.auth.username | string | `"datastore"` | Username for the database user. |
| data-store.postgresql.global.postgresql.service.ports.postgresql | int | `5432` | Port number for PostgreSQL service. |
| data-store.postgresql.image.repository | string | `"bitnamilegacy/postgresql"` |  |
| data-store.postgresql.metrics.image.repository | string | `"bitnamilegacy/postgres-exporter"` |  |
| data-store.postgresql.primary.persistence.size | string | `"10Gi"` | Storage size request for the PostgreSQL persistent volume. |
| data-store.postgresql.volumePermissions.image.repository | string | `"bitnamilegacy/os-shell"` |  |
| data-store.priorityClassName | string | `""` | priorityClassName configuration for the deployment. |
| data-store.readinessProbe | object | This object has the following default values for the readiness probe configuration. | Readiness probe configuration. |
| data-store.readinessProbe.enabled | bool | `true` | Enable readiness probe. |
| data-store.readinessProbe.failureThreshold | int | `40` | Failure threshold for readiness probe. |
| data-store.readinessProbe.httpGet.path | string | `"/v1/health"` | HTTP path for readiness probe. |
| data-store.readinessProbe.httpGet.port | string | `"http"` | Port for readiness probe. |
| data-store.readinessProbe.initialDelaySeconds | int | `30` | Initial delay before readiness probe is initiated. |
| data-store.readinessProbe.periodSeconds | int | `20` | Period for readiness probe. |
| data-store.readinessProbe.successThreshold | int | `1` | Success threshold for readiness probe. |
| data-store.readinessProbe.timeoutSeconds | int | `30` | Timeout for readiness probe. |
| data-store.redis-cluster | object | This object has the following default values for the Redis cluster configuration. | Redis cluster configuration. |
| data-store.redis-cluster.cluster | object | `{"nodes":3,"replicas":0}` | Number of redis cluster master nodes. |
| data-store.redis-cluster.enabled | bool | `false` | Enable Redis cluster. |
| data-store.redis-cluster.usePassword | bool | `false` | Whether to use password authentication. |
| data-store.replicaCount | int | `1` | Number of replicas for the deployment. |
| data-store.resources | object | `{}` | Kubernetes deployment resources configuration. It is recommended to not specify default resources and to leave this as a conscious choice. This also increases chances that the chart will run on environments with little resources, such as minikube. If you want to specify resources, use the following example, adjust the values as necessary, and remove the empty curly braces `{}`. `limits:   cpu: 100m   memory: 128Mi requests:   cpu: 100m   memory: 128Mi` |
| data-store.schedulerName | string | `""` | The name of the alternate scheduler to use. For more information, see [Configure Multiple Schedulers](https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/). |
| data-store.securityContext | object | `{}` | **DEPRECATED** Run init and NeMo Data Store containers as a specific securityContext. The securityContext variable has been split two: `containerSecurityContext` and `podSecurityContext`. |
| data-store.serveDirect | bool | `true` | Whether to serve traffic directly from an object storage service. |
| data-store.service | object | This object has the following default values for the service configuration. | Service configuration for exposing the application. |
| data-store.service.http | object | `{"annotations":{},"clusterIP":"","externalIPs":null,"externalTrafficPolicy":null,"ipFamilies":null,"ipFamilyPolicy":null,"labels":{},"loadBalancerIP":null,"loadBalancerSourceRanges":[],"nodePort":null,"port":3000,"type":"ClusterIP"}` | HTTP service configuration. |
| data-store.service.http.annotations | object | `{}` | Additional annotations for the HTTP service |
| data-store.service.http.clusterIP | string | `""` | The cluster IP address to assign to the service. |
| data-store.service.http.externalIPs | string | `nil` | List of external IP addresses to assign to the service |
| data-store.service.http.externalTrafficPolicy | string | `nil` | External traffic policy for controlling source IP preservation |
| data-store.service.http.ipFamilies | string | `nil` | List of IP families to use for the service |
| data-store.service.http.ipFamilyPolicy | string | `nil` | IP family policy for dual-stack support |
| data-store.service.http.labels | object | `{}` | Additional labels for the HTTP service |
| data-store.service.http.loadBalancerIP | string | `nil` | The static IP address for LoadBalancer service type. |
| data-store.service.http.loadBalancerSourceRanges | list | `[]` | List of CIDR ranges allowed to access the LoadBalancer |
| data-store.service.http.nodePort | string | `nil` | The node port number when using NodePort service type |
| data-store.service.http.port | int | `3000` | The port number to expose for HTTP traffic. |
| data-store.service.http.type | string | `"ClusterIP"` | The Kubernetes service type to create for HTTP traffic. |
| data-store.service.ssh | object | This object has the following default values for the SSH service configuration. | SSH service configuration. |
| data-store.service.ssh.annotations | object | `{}` | Additional annotations for the SSH service. |
| data-store.service.ssh.clusterIP | string | `"None"` | The cluster IP address to assign to the service. |
| data-store.service.ssh.enabled | bool | `false` | Whether to enable SSH service. |
| data-store.service.ssh.externalIPs | string | `nil` | List of external IP addresses to assign to the service. |
| data-store.service.ssh.externalTrafficPolicy | string | `nil` | The external traffic policy for controlling source IP preservation. |
| data-store.service.ssh.hostPort | string | `nil` | The host port number when using HostPort service type. |
| data-store.service.ssh.ipFamilies | string | `nil` | List of IP families to use for the service. |
| data-store.service.ssh.ipFamilyPolicy | string | `nil` | IP family policy for dual-stack support. |
| data-store.service.ssh.labels | object | `{}` | Additional labels for the SSH service. |
| data-store.service.ssh.loadBalancerIP | string | `nil` | The static IP address for LoadBalancer service type. |
| data-store.service.ssh.loadBalancerSourceRanges | list | `[]` | List of CIDR ranges allowed to access the LoadBalancer. |
| data-store.service.ssh.nodePort | string | `nil` | The node port number when using NodePort service type. |
| data-store.service.ssh.port | int | `22` | The port number to expose for SSH traffic. |
| data-store.service.ssh.type | string | `"ClusterIP"` | The Kubernetes service type to create for SSH traffic. |
| data-store.serviceAccount | object | `{"annotations":{},"automountServiceAccountToken":false,"create":true,"imagePullSecrets":[],"labels":{},"name":"gitea"}` | Service account configuration. |
| data-store.serviceAccount.annotations | object | `{}` | Custom annotations for the service account. |
| data-store.serviceAccount.automountServiceAccountToken | bool | `false` | Enable/disable auto mounting of the service account token. |
| data-store.serviceAccount.create | bool | `true` | Whether to create a service account. |
| data-store.serviceAccount.imagePullSecrets | list | `[]` | Image pull secrets, available to the service account. To add a list of image pull secrets, remove `[]`use the following format: - name: private-registry-access. |
| data-store.serviceAccount.labels | object | `{}` | Custom labels for the service account. |
| data-store.serviceAccount.name | string | `"gitea"` | Name of the created service account, defaults to release name. Can also link to an externally provided service account that should be used. |
| data-store.serviceName | string | `"nemo-data-store"` | The service name for the NeMo Data Store microservice. |
| data-store.signing | object | `{"enabled":false,"existingSecret":"","gpgHome":"/data/git/.gnupg","privateKey":""}` | Signing configuration. |
| data-store.signing.enabled | bool | `false` | Enable commit/action signing. |
| data-store.signing.existingSecret | string | `""` | Use an existing secret to store the value of `signing.privateKey`. |
| data-store.signing.gpgHome | string | `"/data/git/.gnupg"` | GPG home directory. |
| data-store.signing.privateKey | string | `""` | Inline private GPG key for signed NeMo Data Store actions. |
| data-store.ssh | object | `{"logLevel":"INFO"}` | Configure OpenSSH's log level. Only available for root-based Datastore image. |
| data-store.startupProbe | object | This object has the following default values for the start-up probe configuration. | Start-up probe configuration. |
| data-store.startupProbe.enabled | bool | `false` | Enable start-up probe. |
| data-store.startupProbe.failureThreshold | int | `10` | Failure threshold for start-up probe. |
| data-store.startupProbe.initialDelaySeconds | int | `60` | Initial delay before start-up probe is initiated. |
| data-store.startupProbe.periodSeconds | int | `10` | Period for start-up probe. |
| data-store.startupProbe.successThreshold | int | `1` | Success threshold for start-up probe. |
| data-store.startupProbe.tcpSocket | object | `{"port":"http"}` | TCP socket configuration for start-up probe. |
| data-store.startupProbe.timeoutSeconds | int | `1` | Timeout for start-up probe. |
| data-store.strategy | object | This object has the following default values for the strategy configuration. | Strategy configuration for controlling how pod updates are performed. |
| data-store.strategy.rollingUpdate.maxSurge | string | `"100%"` | Maximum number of pods that can be created above the desired amount during an update. |
| data-store.strategy.rollingUpdate.maxUnavailable | int | `0` | Maximum number of pods that can be unavailable during an update. |
| data-store.strategy.type | string | `"Recreate"` | The strategy type for pod updates. Use `RollingUpdate` if you use `ReadWriteMany` persistent storage or deploying on a single node. Otherwise, use `Recreate` to allow upgrades, although it causes downtime during the upgrade process. |
| data-store.test.enabled | bool | `false` | Enable or disable the test-connection Pod. |
| data-store.test.image.name | string | `"busybox"` | Image name for the wget container used in the test-connection Pod. |
| data-store.test.image.tag | string | `"latest"` | Image tag for the wget container used in the test-connection Pod. |
| data-store.tolerations | list | `[]` | Tolerations configuration for the deployment. |
| data-store.topologySpreadConstraints | list | `[]` | TopologySpreadConstraints configuration for the deployment. |
| deployment-management.affinity | object | `{}` | Specifies affinity settings for the deployment. To learn more, refer to the [Affinity and Anti-Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity) in the Kubernetes documentation. |
| deployment-management.autoscaling.enabled | bool | `false` | Whether to enable autoscaling for the NeMo Deployment Management microservice. |
| deployment-management.autoscaling.maxReplicas | int | `100` | The maximum number of replicas. |
| deployment-management.autoscaling.minReplicas | int | `1` | The minimum number of replicas. |
| deployment-management.autoscaling.targetCPUUtilizationPercentage | int | `80` | The target CPU utilization percentage. |
| deployment-management.dataStore.secret.create | bool | `true` | Whether to create a secret for the data store huggingface token. If false, the secret must be created manually. |
| deployment-management.dataStore.secret.name | string | `"nemo-deployment-management-service-ds-hf-token"` | The name of the secret that will be created. If create is false, a secret with this name must be created manually and have the HF_TOKEN key set. |
| deployment-management.dataStore.url | string | `"http://nemo-data-store:3000"` | The URL for the NeMo Data Store service. |
| deployment-management.deployments | object | `{"autoscaling":{"enabled":false,"spec":{"maxReplicas":5,"metrics":[{"pods":{"metric":{"name":"gpu_cache_usage_perc"},"target":{"averageValue":"750m","type":"AverageValue"}},"type":"Pods"}],"minReplicas":1}},"defaultStorageClass":"","entityStoreUrl":"http://nemo-entity-store:8000","metrics":{"enabled":false},"modelPullerImage":"nvcr.io/nvidia/nemo-microservices/nds-v2-huggingface-cli:25.06","modelPullerPullSecret":"nvcrimagepullsecret","modelSyncPeriod":"30","nimImagePullSecrets":["nvcrimagepullsecret"],"nimPeftSource":"http://nemo-entity-store:8000","nimPvcSize":"200Gi"}` | Properties to configure NIM deployments for the NeMo Deployment Management microservice. |
| deployment-management.deployments.autoscaling.enabled | bool | `false` | Whether to enable autoscaling for the NIM deployments. |
| deployment-management.deployments.autoscaling.spec | object | `{"maxReplicas":5,"metrics":[{"pods":{"metric":{"name":"gpu_cache_usage_perc"},"target":{"averageValue":"750m","type":"AverageValue"}},"type":"Pods"}],"minReplicas":1}` | Autoscaling specification for the NIM deployments. |
| deployment-management.deployments.defaultStorageClass | string | `""` | Storage classes utilizing NFSv3+ may encounter issues with huggingface-cli file locking. |
| deployment-management.deployments.entityStoreUrl | string | `"http://nemo-entity-store:8000"` | The URL for the NeMo Entity Store service. |
| deployment-management.deployments.metrics.enabled | bool | `false` | Whether to enable metrics collection for the NIM deployments. |
| deployment-management.deployments.modelPullerImage | string | `"nvcr.io/nvidia/nemo-microservices/nds-v2-huggingface-cli:25.06"` | The image to use for pulling models from NeMo Data Store. Must have the huggingface-cli binary installed. |
| deployment-management.deployments.modelPullerPullSecret | string | `"nvcrimagepullsecret"` | The pull secret used to pull the model puller image. |
| deployment-management.deployments.modelSyncPeriod | string | `"30"` | The period in seconds for model synchronization. |
| deployment-management.deployments.nimImagePullSecrets | list | `["nvcrimagepullsecret"]` | List of image pull secrets for the NIM deployments. |
| deployment-management.deployments.nimPeftSource | string | `"http://nemo-entity-store:8000"` | The URL for PEFT model sources (typically points to NeMo Entity Store) |
| deployment-management.deployments.nimPvcSize | string | `"200Gi"` | The size of the PVC for the NIM deployments. |
| deployment-management.env | object | `{}` | Additional environment variables to pass to the NeMo Deployment Management microservice container. The format is `NAME: value` or `NAME: valueFrom: {object}`. |
| deployment-management.fullnameOverride | string | `""` | String to fully override the name on resulting Kubernetes objects when the NeMo Deployment Management microservice is deployed. |
| deployment-management.image.pullPolicy | string | `"IfNotPresent"` | The container image pull policy for the NeMo Deployment Management container. |
| deployment-management.image.repository | string | `"nvcr.io/nvidia/nemo-microservices/deployment-management"` | The repository of the NeMo Deployment Management container image. |
| deployment-management.image.tag | string | `""` | The container image tag. If not set, the default value is `appVersion` from the `Chart.yaml` file. |
| deployment-management.imagePullSecrets | list | `[{"name":"nvcrimagepullsecret"}]` | Image pull secrets for accessing the NGC container registry. |
| deployment-management.livenessProbe.httpGet.path | string | `"/health"` | The HTTP path for the Kubernetes liveness probe. Do not change this. |
| deployment-management.livenessProbe.httpGet.port | string | `"http"` | The port name for the Kubernetes liveness probe. Do not change this. |
| deployment-management.monitoring | object | `{"enabled":false}` | Prometheus metrics collection configuration for monitoring the NeMo Deployment Management microservice. To enable this, you should install the Prometheus operator before deploying the NeMo Deployment Management microservice. |
| deployment-management.monitoring.enabled | bool | `false` | Whether to enable monitoring for the NeMo Deployment Management microservice. |
| deployment-management.nameOverride | string | `""` | String to partially override name on resulting Kubernetes objects when the NeMo Deployment Management microservice is deployed. |
| deployment-management.nimNamespace | string | `""` | Specifies a namespace to restrict the NeMo Deployment Management microservice to watch NIMs in. Leave it empty to watch all namespaces. |
| deployment-management.nodeSelector | object | `{}` | Specifies labels to ensure that the microservice is deployed only on certain nodes. To learn more, refer to the [Node Selector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector) in the Kubernetes documentation. |
| deployment-management.podAnnotations | object | `{}` | Pod annotations. |
| deployment-management.podLabels | object | `{}` | Pod labels. |
| deployment-management.podSecurityContext | object | `{}` | Pod security context settings. Use the default settings, unless you understand what changes in the pod security context settings you want to apply. |
| deployment-management.readinessProbe.httpGet.path | string | `"/health"` | The HTTP path for the Kubernetes readiness probe. Do not change this. |
| deployment-management.readinessProbe.httpGet.port | string | `"http"` | The port name for the Kubernetes readiness probe. Do not change this. |
| deployment-management.replicaCount | int | `1` | The number of replicas for the NeMo Deployment Management service. |
| deployment-management.resources | object | `{}` | Configures Kubernetes resource requests and limits for the NeMo Deployment Management microservice. Use the default settings and leave it with the empty object as is, unless you understand what changes you want to make. |
| deployment-management.securityContext | object | `{"readOnlyRootFilesystem":true}` | Security context settings. Use the default settings, unless you understand what changes in the security context settings you want to apply. |
| deployment-management.securityContext.readOnlyRootFilesystem | bool | `true` | Enable read-only root filesystem. You can also add any values for [Kubernetes security context](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#securitycontext-v1-core) in this field. |
| deployment-management.service.deploymentPort.port | int | `8000` | The port number for the service. |
| deployment-management.service.deploymentPort.type | string | `"ClusterIP"` | The service type of the deployment port. |
| deployment-management.serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | Configures service account for RBAC for the NeMo Deployment Management microservice. Use the default setup, unless you understand what changes in RBAC settings you want to apply to the service. |
| deployment-management.serviceAccount.annotations | object | `{}` | Annotations to add to the service account. |
| deployment-management.serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials. |
| deployment-management.serviceAccount.create | bool | `true` | Whether to create a service account for the NeMo Deployment Management microservice. This is for setting RBAC up. |
| deployment-management.serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template. |
| deployment-management.serviceName | string | `"nemo-deployment-management"` | The service name for the NeMo Deployment Management microservice. |
| deployment-management.tolerations | list | `[]` | Specifies tolerations for pod assignment. To learn more, refer to the [Taint and Toleration](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) in the Kubernetes documentation. |
| deployment-management.volumeMounts | list | `[]` | Additional volume mounts for the NeMo Deployment Management microservice. Use the default settings and leave it with the empty list as is, unless you understand what changes you want to make. |
| deployment-management.volumes | list | `[]` | Additional volumes for the NeMo Deployment Management microservice. Use the default settings and leave it with the empty list as is, unless you understand what changes you want to make. |
| entity-store.affinity | object | `{}` | Additional affinity for the deployment. |
| entity-store.appConfig | object | `{"BASE_URL_DATASTORE":"http://nemo-data-store:3000/v1/hf","BASE_URL_NIM":"http://nemo-nim-proxy:8000"}` | Additional NeMo Entity Store API server specific configs. |
| entity-store.appConfig.BASE_URL_DATASTORE | string | `"http://nemo-data-store:3000/v1/hf"` | The base URL for the NeMo Data Store microservice. |
| entity-store.appConfig.BASE_URL_NIM | string | `"http://nemo-nim-proxy:8000"` | The base URL for the NIM service used by the NeMo Entity Store microservice. |
| entity-store.autoscaling.enabled | bool | `false` | Whether to enable autoscaling. |
| entity-store.autoscaling.maxReplicas | int | `100` | The maximum number of replicas. |
| entity-store.autoscaling.minReplicas | int | `1` | The minimum number of replicas. |
| entity-store.autoscaling.targetCPUUtilizationPercentage | int | `80` | The target CPU utilization percentage for autoscaling. |
| entity-store.demo.enabled | bool | `false` | Whether to enable demo mode. |
| entity-store.demo.ngcApiKey | string | `""` | The NGC API key for demo mode. |
| entity-store.demo.ngcImagePullSecret | string | `"nvcrimagepullsecret"` | The name of the NGC image pull secret for demo mode. |
| entity-store.env | object | `{}` | Additional environment variables to pass to the NeMo Entity Store container. Format should be `NAME: value` or `NAME: valueFrom: {object}`. |
| entity-store.externalDatabase.database | string | `"entity-store"` | The name of the database for the NeMo Entity Store service. |
| entity-store.externalDatabase.existingSecret | string | `""` | The name of an existing secret resource containing the database credentials. |
| entity-store.externalDatabase.existingSecretPasswordKey | string | `""` | The name of an existing secret key containing the database credentials. |
| entity-store.externalDatabase.host | string | `"localhost"` | The database host. |
| entity-store.externalDatabase.port | int | `5432` | The database port number. |
| entity-store.externalDatabase.uriSecret.key | string | `""` | The key within the existing secret that includes a full database URI. |
| entity-store.externalDatabase.uriSecret.name | string | `""` | The name of an existing secret that includes a full database URI. |
| entity-store.externalDatabase.user | string | `"user"` | The database username for the NeMo Entity Store service. |
| entity-store.fullnameOverride | string | `""` | String to fully override name on resulting Kubernetes objects when deployed. |
| entity-store.image.pullPolicy | string | `"IfNotPresent"` | The image pull policy to pull the NeMo Entity Store image |
| entity-store.image.repository | string | `"nvcr.io/nvidia/nemo-microservices/entity-store"` | The NeMo Entity Store image repository. |
| entity-store.image.tag | string | `""` | Specifies the image tag. |
| entity-store.imagePullSecrets | list | `[{"name":"nvcrimagepullsecret"}]` | List of image pull secrets. You can add multiple secrets to the list. |
| entity-store.livenessProbe.failureThreshold | int | `10` | The failure threshold for the liveness probe. |
| entity-store.livenessProbe.httpGet | object | `{"path":"/health","port":"http"}` | The path for the liveness probe. |
| entity-store.livenessProbe.initialDelaySeconds | int | `3` | The initial delay seconds for the Kubernetes liveness probe. |
| entity-store.livenessProbe.periodSeconds | int | `10` | The period seconds for the liveness probe. |
| entity-store.livenessProbe.timeoutSeconds | int | `20` | The timeout seconds for the liveness probe. |
| entity-store.nameOverride | string | `""` | String to partially override name on resulting Kubernetes objects when deployed. |
| entity-store.nodeSelector | object | `{}` | Additional node selector configuration for the deployment. |
| entity-store.openTelemetry.enabled | bool | `false` | Whether to enable OpenTelemetry integration. |
| entity-store.podAnnotations | object | `{}` | Additional annotations for the NeMo Entity Store pods. |
| entity-store.podLabels | object | `{}` | Additional labels for the NeMo Entity Store pods. |
| entity-store.podSecurityContext | object | `{}` | The pod security context for the NeMo Entity Store pods. |
| entity-store.postgresWaitImage.repository | string | `"busybox"` | The repository location of the image used to wait for postgres to start. |
| entity-store.postgresWaitImage.tag | string | `"latest"` | The tag of the image used when waiting. |
| entity-store.postgresql.architecture | string | `"standalone"` | The PostgreSQL architecture. Available options are `standalone` or `replication`. |
| entity-store.postgresql.auth.database | string | `"entity-store"` | The name for a custom database to create. |
| entity-store.postgresql.auth.enablePostgresUser | bool | `true` | Whether to assign a password to the "postgres" admin user. If disabled, remote access is blocked for this user. |
| entity-store.postgresql.auth.existingSecret | string | `""` | The name of an existing secret to use for PostgreSQL credentials. |
| entity-store.postgresql.auth.password | string | `"pass"` | The password for the PostgreSQL user. |
| entity-store.postgresql.auth.username | string | `"user"` | The user name to use for the PostgreSQL database. |
| entity-store.postgresql.enabled | bool | `true` | Whether to install the default PostgreSQL Helm chart. If enabled, the NeMo Entity Store microservice Helm chart uses the [PostgreSQL Helm chart from Bitnami](https://github.com/bitnami/charts/blob/main/bitnami/postgresql/values.yaml) to create a PostgreSQL database. |
| entity-store.postgresql.image.repository | string | `"bitnamilegacy/postgresql"` |  |
| entity-store.postgresql.metrics.image.repository | string | `"bitnamilegacy/postgres-exporter"` |  |
| entity-store.postgresql.nameOverride | string | `"entity-storedb"` | The name override for the PostgreSQL database. |
| entity-store.postgresql.serviceAccount.create | bool | `true` | Specifies whether to create a new service account for PostgreSQL. |
| entity-store.postgresql.serviceAccount.name | string | `"entity-store-postgresql"` | The service account name for PostgreSQL. |
| entity-store.postgresql.volumePermissions.image.repository | string | `"bitnamilegacy/os-shell"` |  |
| entity-store.readinessProbe.failureThreshold | int | `20` | The failure threshold for the readiness probe. |
| entity-store.readinessProbe.httpGet | object | `{"path":"/health","port":"http"}` | The path for the readiness probe. |
| entity-store.readinessProbe.initialDelaySeconds | int | `10` | The initial delay seconds for the readiness probe. |
| entity-store.readinessProbe.periodSeconds | int | `10` | The period seconds for the readiness probe. |
| entity-store.readinessProbe.timeoutSeconds | int | `20` | The timeout seconds for the readiness probe. |
| entity-store.replicaCount | int | `1` | The number of NeMo Entity Store replicas to deploy. |
| entity-store.resources | object | `{}` | Requests and limits for underlying Kubernetes deployment for NeMo Entity Store. |
| entity-store.securityContext | object | `{}` | The security context for the NeMo Entity Store pods. |
| entity-store.service.port | int | `8000` | The service port for the NeMo Entity Store microservice. |
| entity-store.service.type | string | `"ClusterIP"` | The Kubernetes service type of the NeMo Entity Store microservice. |
| entity-store.serviceAccount.annotations | object | `{}` | Additional custom annotations for the service account. |
| entity-store.serviceAccount.automount | bool | `true` | Whether to automatically mount the service account's API credentials. |
| entity-store.serviceAccount.name | string | `""` | The name of the service account to use. |
| entity-store.serviceName | string | `"nemo-entity-store"` | The service name for the NeMo Entity Store microservice. |
| entity-store.tolerations | list | `[]` | Additional tolerations for the deployment. |
| entity-store.volumeMounts | list | `[]` | Additional volume mounts for the deployment. |
| entity-store.volumes | list | `[]` | Additional volumes for the deployment. |
| evaluator.affinity | object | `{}` | Affinity for the NeMo Evaluator microservice. |
| evaluator.autoscaling.enabled | bool | `false` | Whether to enable autoscaling for the NeMo Evaluator microservice. |
| evaluator.autoscaling.maxReplicas | int | `100` | The maximum number of replicas for the NeMo Evaluator microservice. |
| evaluator.autoscaling.minReplicas | int | `1` | The minimum number of replicas for the NeMo Evaluator microservice. |
| evaluator.autoscaling.targetCPUUtilizationPercentage | int | `80` | The target CPU utilization percentage for the NeMo Evaluator microservice. |
| evaluator.dbMigration.resources.limits.cpu | int | `1` | The CPU resource limit for the DB Migration service. |
| evaluator.dbMigration.resources.limits.memory | string | `"1Gi"` | The memory resource limit for the DB Migration service. |
| evaluator.env | object | `{}` | Additional environment variables to pass to containers. The format is `NAME: value` or `NAME: valueFrom: {object}`. |
| evaluator.evalFactory.job.restartPolicy | string | `"Never"` | Restart policy for the pods of the core eval jobs. |
| evaluator.evalFactory.job.ttlSecondsAfterFinished | int | `172800` | Time-to-live after completion for the core eval jobs. |
| evaluator.evaluationImages | object | `{"AGENTIC_EVAL":"","BFCL":"","BIGCODE_EVALUATION_HARNESS":"","LM_EVAL_HARNESS":"","RAG":"","RETRIEVER":"","SAFETY_HARNESS":"","SIMPLE_EVALS":""}` | Optional override for evaluation images. |
| evaluator.evaluationImages.AGENTIC_EVAL | string | `""` | The image for the Agentic evaluation: nvcr.io/nvidia/eval-factory/agentic_eval |
| evaluator.evaluationImages.BFCL | string | `""` | The image for the BFCL evaluation: nvcr.io/nvidia/eval-factory/bfcl |
| evaluator.evaluationImages.BIGCODE_EVALUATION_HARNESS | string | `""` | The image for the bigcode evaluation harness evaluation: nvcr.io/nvidia/eval-factory/bigcode-evaluation-harness |
| evaluator.evaluationImages.LM_EVAL_HARNESS | string | `""` | The image for the language model evaluation harness evaluation: nvcr.io/nvidia/eval-factory/lm-evaluation-harness |
| evaluator.evaluationImages.RAG | string | `""` | The image for the RAG evaluation: nvcr.io/nvidia/eval-factory/rag_retriever_eval |
| evaluator.evaluationImages.RETRIEVER | string | `""` | The image for the retriever evaluation: nvcr.io/nvidia/eval-factory/rag_retriever_eval |
| evaluator.evaluationImages.SAFETY_HARNESS | string | `""` | The image for the model safety evaluation: nvcr.io/nvidia/eval-factory/safety-harness |
| evaluator.evaluationImages.SIMPLE_EVALS | string | `""` | The image for the Simple-Evals evaluation: nvcr.io/nvidia/eval-factory/simple-evals |
| evaluator.evaluationJob.monitoringInterval | int | `5` | Monitoring interval checking evaluation job status (in seconds). |
| evaluator.evaluationJob.monitoringTimeout | int | `36000` | Monitoring timeout for checking evaluation job status (in seconds). |
| evaluator.evaluator | object | `{"host":"0.0.0.0"}` | Host for the NeMo Evaluator microservice. |
| evaluator.external.dataStore.endpoint | string | `"http://nemo-data-store:3000/v1/hf"` | The external URL of the NeMo Data Store microservice. |
| evaluator.external.entityStore.endpoint | string | `"http://nemo-entity-store:8000"` | The external URL of the NeMo Entity Store microservice. |
| evaluator.external.jobs.endpoint | string | `"http://nemo-core-api:8000"` | The external URL of the Jobs microservice. |
| evaluator.external.milvus.endpoint | string | `""` | The external URL of your own Milvus service. |
| evaluator.external.nimProxy.endpoint | string | `"http://nemo-nim-proxy:8000"` | The external URL of the NeMo NIM Proxy microservice. |
| evaluator.external.nimProxy.endpoint_internal | string | `""` | The internal cluster URL of the NeMo NIM Proxy microservice. This is used to remap model URLs from evaluation jobs that match external.nimProxy.endpoint to the internal URL when cluster ingress is not supported for the external address. |
| evaluator.externalDatabase.database | string | `"evaluation"` | The database for the external database. |
| evaluator.externalDatabase.existingSecret | string | `""` | The existing secret for the external database. |
| evaluator.externalDatabase.existingSecretPasswordKey | string | `""` | The existing secret password key for the external database. |
| evaluator.externalDatabase.host | string | `"localhost"` | The host for an external database. |
| evaluator.externalDatabase.port | int | `5432` | The port for the external database. |
| evaluator.externalDatabase.uriSecret | object | `{"key":"","name":""}` | The name for the external database secret. |
| evaluator.externalDatabase.user | string | `"nemo"` | The user for the external database. |
| evaluator.fullnameOverride | string | `""` | The full name override for the NeMo Evaluator microservice. |
| evaluator.image.pullPolicy | string | `"IfNotPresent"` | The image pull policy for the NeMo Evaluator microservice image. |
| evaluator.image.repository | string | `"nvcr.io/nvidia/nemo-microservices/evaluator"` | The repository where the NeMo Evaluator microservice image is located. |
| evaluator.image.tag | string | `""` | Specifies the version of the NeMo Evaluator microservice image. |
| evaluator.imagePullSecrets | list | `[{"name":"nvcrimagepullsecret"}]` | The image pull secrets for accessing the container registry. |
| evaluator.livenessProbe.httpGet | object | `{"path":"/health","port":"http"}` | Configures the liveness probe for the NeMo Evaluator microservice. The liveness probe checks if the container is running. The probe sends an HTTP GET request to the `/health` endpoint on the container's `http` port. |
| evaluator.logLevel | string | `"INFO"` | Log level for the NeMo Evaluator microservice. |
| evaluator.milvus.cluster.enabled | bool | `false` | Whether to enable the default Milvus cluster. |
| evaluator.milvus.enabled | bool | `false` | Whether to enable the default Milvus service. Enable this for RAG and Retriever pipelines. For more information about setting up a Milvus service, see the [Milvus setup guide](https://docs.nvidia.com/nemo/microservices/latest/set-up/deploy-as-microservices/evaluator.html#configure-milvus). |
| evaluator.milvus.etcd.enabled | bool | `false` | Whether to enable the etcd for the default Milvus service. |
| evaluator.milvus.extraConfigFiles | object | `{"user.yaml":"etcd:\n  use:\n    embed: true\n  data:\n    dir: /var/lib/milvus/etcd\ncommon:\n  storageType: local\n\n"}` | Extra configuration files for the default Milvus service. |
| evaluator.milvus.minio.enabled | bool | `false` | Whether to enable the Minio for the default Milvus service. |
| evaluator.milvus.minio.tls | object | `{"enabled":false}` | Whether to enable the TLS for the Minio service. |
| evaluator.milvus.pulsar.enabled | bool | `false` | Whether to enable the Pulsar for the default Milvus service. |
| evaluator.milvus.service.port | int | `19121` | The service port for the default Milvus service. |
| evaluator.milvus.serviceName | string | `"milvus"` | The service name for the default Milvus service. |
| evaluator.milvus.standalone.extraEnv | list | `[{"name":"LOG_LEVEL","value":"error"}]` | Extra environment variables for the default Milvus service. |
| evaluator.milvus.standalone.persistence | object | `{"enabled":true,"persistentVolumeClaim":{"size":"50Gi","storageClass":""}}` | Whether to enable the standalone for the default Milvus service. |
| evaluator.milvus.standalone.persistence.enabled | bool | `true` | Whether to enable the persistence for the default Milvus service. |
| evaluator.milvus.standalone.persistence.persistentVolumeClaim | object | `{"size":"50Gi","storageClass":""}` | The persistent volume claim for the default Milvus service. |
| evaluator.milvus.standalone.persistence.persistentVolumeClaim.size | string | `"50Gi"` | The size for the persistent volume claim for the default Milvus service. |
| evaluator.milvus.standalone.persistence.persistentVolumeClaim.storageClass | string | `""` | The storage class for the persistent volume claim for the default Milvus service. |
| evaluator.nameOverride | string | `""` | The name override for the NeMo Evaluator microservice. |
| evaluator.nodeSelector | object | `{}` | Node selector for the NeMo Evaluator microservice. |
| evaluator.opentelemetry-collector.config.exporters.debug | object | `{"verbosity":"detailed"}` | Debugging verbosity for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.exporters.zipkin | object | `{"endpoint":"http://zipkin:9411/api/v2/spans"}` | The Zipkin exporter for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.processors.batch | object | `{}` | The batch processor for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.processors.tail_sampling | object | `{"policies":[{"name":"drop_noisy_traces_url","string_attribute":{"enabled_regex_matching":true,"invert_match":true,"key":"http.target","values":["\\/health"]},"type":"string_attribute"}]}` | The tail sampling processor for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.processors.tail_sampling.policies | list | `[{"name":"drop_noisy_traces_url","string_attribute":{"enabled_regex_matching":true,"invert_match":true,"key":"http.target","values":["\\/health"]},"type":"string_attribute"}]` | The policies for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.processors.transform | object | `{"trace_statements":[{"context":"span","statements":["set(status.code, 1) where attributes[\"http.path\"] == \"/health\""]}]}` | The transform processor configuration for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.processors.transform.trace_statements | list | `[{"context":"span","statements":["set(status.code, 1) where attributes[\"http.path\"] == \"/health\""]}]` | The trace statements for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.receivers.otlp | object | `{"protocols":{"grpc":null,"http":{"cors":{"allowed_origins":["*"]}}}}` | The OTLP receiver for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.service.pipelines.logs | object | `{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]}` | The logs pipeline for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.service.pipelines.logs.exporters | list | `["debug"]` | The exporters for the logs pipeline for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.service.pipelines.logs.processors | list | `["batch"]` | The processors for the logs pipeline for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.service.pipelines.logs.receivers | list | `["otlp"]` | The receivers for the logs pipeline for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.service.pipelines.metrics | object | `{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]}` | The metrics pipeline for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.service.pipelines.metrics.exporters | list | `["debug"]` | The exporters for the metrics pipeline for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.service.pipelines.metrics.processors | list | `["batch"]` | The processors for the metrics pipeline for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.service.pipelines.metrics.receivers | list | `["otlp"]` | The receivers for the metrics pipeline for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.service.pipelines.traces | object | `{"exporters":["debug","zipkin"],"processors":["tail_sampling","transform"],"receivers":["otlp"]}` | The traces pipeline for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.service.pipelines.traces.exporters | list | `["debug","zipkin"]` | The exporters for the traces pipeline for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.service.pipelines.traces.processors | list | `["tail_sampling","transform"]` | The processors for the traces pipeline for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.config.service.pipelines.traces.receivers | list | `["otlp"]` | The receivers for the traces pipeline for the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.enabled | bool | `false` | Whether to enable the OpenTelemetry Collector service. |
| evaluator.opentelemetry-collector.mode | string | `"deployment"` | The mode for the OpenTelemetry Collector service. |
| evaluator.otelEnvVars | object | `{"OTEL_LOGS_EXPORTER":"otlp","OTEL_METRICS_EXPORTER":"otlp","OTEL_PROPAGATORS":"tracecontext,baggage","OTEL_PYTHON_EXCLUDED_URLS":"health","OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED":"true","OTEL_RESOURCE_ATTRIBUTES":"deployment.environment=$(NAMESPACE)","OTEL_SERVICE_NAME":"nemo-evaluator","OTEL_TRACES_EXPORTER":"otlp"}` | OpenTelemetry environment configuration variables for the NeMo Evaluator microservice. |
| evaluator.otelExporterEnabled | bool | `false` | Whether to enable the OpenTelemetry exporter for the NeMo Evaluator microservice. |
| evaluator.podAnnotations | object | `{}` | Annotations for the service pod. |
| evaluator.podLabels | object | `{}` | Labels for the service pod. |
| evaluator.podSecurityContext | object | `{}` | Security context for the service pod. |
| evaluator.postgresWaitImage.repository | string | `"busybox"` | The repository location of the image used to wait for postgres to start. |
| evaluator.postgresWaitImage.tag | string | `"latest"` | The tag of the image used when waiting. |
| evaluator.postgresql.architecture | string | `"standalone"` | The architecture for the default PostgreSQL service. |
| evaluator.postgresql.auth.database | string | `"evaluation"` | The database for the PostgreSQL service. |
| evaluator.postgresql.auth.enablePostgresUser | bool | `true` | Whether to enable the PostgreSQL user. |
| evaluator.postgresql.auth.existingSecret | string | `""` | The existing secret you want to use for the PostgreSQL service. |
| evaluator.postgresql.auth.password | string | `"nemo"` | The password for the PostgreSQL service. |
| evaluator.postgresql.auth.username | string | `"nemo"` | The username for the PostgreSQL service. |
| evaluator.postgresql.enabled | bool | `true` | Whether to enable the default PostgreSQL service. For more information about setting up a PostgreSQL service, see the [PostgreSQL setup guide](https://docs.nvidia.com/nemo/microservices/latest/set-up/manage-storage/database/postgres.html). |
| evaluator.postgresql.global.size | string | `"10Gi"` | The storage size for the default PostgreSQL service. |
| evaluator.postgresql.global.storageClass | string | `""` | The storage class for the default PostgreSQL service. |
| evaluator.postgresql.image.repository | string | `"bitnamilegacy/postgresql"` |  |
| evaluator.postgresql.metrics.image.repository | string | `"bitnamilegacy/postgres-exporter"` |  |
| evaluator.postgresql.nameOverride | string | `"evaluatordb"` | The name override for the default PostgreSQL database. |
| evaluator.postgresql.primary.networkPolicy.enabled | bool | `false` | Specifies whether to enable the network policy for the PostgreSQL service. |
| evaluator.postgresql.primary.service.ports.postgresql | int | `5432` | The primary service port for the PostgreSQL service. |
| evaluator.postgresql.serviceAccount.name | string | `"evaluator-postgresql"` | The name of the service account for PostgreSQL. |
| evaluator.postgresql.volumePermissions.image.repository | string | `"bitnamilegacy/os-shell"` |  |
| evaluator.readinessProbe.httpGet | object | `{"path":"/health","port":"http"}` | Configures the readiness probe for the NeMo Evaluator microservice. The readiness probe checks if the container is ready to receive traffic. The probe sends an HTTP GET request to the `/health` endpoint on the container's `http` port. |
| evaluator.replicaCount | int | `1` | The number of replicas for the NeMo Evaluator microservice. |
| evaluator.resources | object | `{}` | Resources for the NeMo Evaluator service. |
| evaluator.securityContext | object | `{}` | Security context for the service container. |
| evaluator.service.internalPort | int | `7332` | Internal port of the NeMo Evaluator microservice. |
| evaluator.service.port | int | `7331` | External port of the NeMo Evaluator microservice. |
| evaluator.service.type | string | `"ClusterIP"` | The type of the NeMo Evaluator microservice. |
| evaluator.serviceAccount.annotations | object | `{}` | Annotations for the service account. |
| evaluator.serviceAccount.automount | bool | `true` | Whether to automatically mount the service account token. |
| evaluator.serviceAccount.create | bool | `true` | Whether to create a service account for the NeMo Evaluator microservice. |
| evaluator.serviceAccount.name | string | `""` | A name for the service account. |
| evaluator.serviceName | string | `"nemo-evaluator"` | Sets a predictable name for the NeMo Evaluator Kubernetes service |
| evaluator.tolerations | list | `[]` | Tolerations for the NeMo Evaluator microservice. |
| evaluator.volumeMounts | list | `[]` | Volume mounts for the NeMo Evaluator microservice. |
| evaluator.volumes | list | `[]` | Volumes for the NeMo Evaluator microservice. |
| evaluator.zipkin.enabled | bool | `false` | Whether to enable the default Zipkin service. |
| evaluator.zipkin.fullnameOverride | string | `"evaluator-zipkin"` | The full name override for the default Zipkin service. |
| existingImagePullSecret | string | `"nvcrimagepullsecret"` | You can specify an existing Kubernetes image pull secret for pulling images from the NGC container registry. The chart uses the `ngcAPIKey` value to generate the secret if you set this to an empty string. |
| existingSecret | string | `"ngc-api"` | You can use an existing Kubernetes secret for communicating with the NGC API for downloading models. The chart uses the `ngcAPIKey` value to generate the secret if you set this to an empty string. |
| global.imagePullSecrets | list | `[{"name":"nvcrimagepullsecret"}]` | The name of the image pull secret to use globally across all services. |
| global.platformConfigmapName | string | `"nemo-platform-config"` | The name of the config map to use for global platform configuration. |
| global.security | object | `{"allowInsecureImages":true}` | A value needed for bitnamilegacy images used in postgresql subcharts |
| guardrails.affinity | object | `{}` | Specifies affinity settings for the deployment. To learn more, refer to the [Affinity and Anti-Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity) in the Kubernetes documentation. |
| guardrails.autoscaling | object | `{"enabled":false,"maxReplicas":100,"minReplicas":1,"targetCPUUtilizationPercentage":80}` | Specifies autoscaling configurations for the deployment. |
| guardrails.autoscaling.enabled | bool | `false` | Whether to enable horizontal pod autoscaler. |
| guardrails.autoscaling.maxReplicas | int | `100` | The maximum number of replicas for the deployment. |
| guardrails.autoscaling.minReplicas | int | `1` | The minimum number of replicas for the deployment. |
| guardrails.autoscaling.targetCPUUtilizationPercentage | int | `80` | The target CPU utilization percentage. |
| guardrails.configStore.nfs.enabled | bool | `false` | Whether to enable the use of an NFS persistent volume for the configuration store. |
| guardrails.configStore.nfs.mountPath | string | `"/config-store"` | The path where the NFS volume will be mounted inside the container. |
| guardrails.configStore.nfs.path | string | `"/path/to/nfs/share"` | The path to the root of the Configuration Store folder. |
| guardrails.configStore.nfs.server | string | `"nfs-server.example.com"` | The address of the NFS server. |
| guardrails.configStore.nfs.storageClass | string | `"standard"` | The storage class for the PV and PVC. |
| guardrails.env | object | `{"CONFIG_STORE_PATH":"/app/services/guardrails/config-store","DEFAULT_CONFIG_ID":"self-check","DEFAULT_LLM_PROVIDER":"nim","DEMO":"True","FETCH_NIM_APP_MODELS":"True","GUARDRAILS_HOST":"0.0.0.0","GUARDRAILS_PORT":"7331","NEMO_GUARDRAILS_SERVER_ALLOWED_ORIGINS":"*","NEMO_GUARDRAILS_SERVER_ENABLE_CORS":"False","NIM_ENDPOINT_URL":"http://nemo-nim-proxy:8000/v1","OTEL_SERVICE_NAME":"nemo-guardrails"}` | Environment variables for the container. |
| guardrails.env.NIM_ENDPOINT_URL | string | `"http://nemo-nim-proxy:8000/v1"` | The NIM endpoint URL for the NeMo Guardrails microservice. |
| guardrails.external | object | `{"entityStore":{"endpoint":"http://nemo-entity-store:8000"}}` | External service endpoints configuration. |
| guardrails.external.entityStore.endpoint | string | `"http://nemo-entity-store:8000"` | The external URL of the NeMo Entity Store microservice. |
| guardrails.externalDatabase | object | `{"database":"","existingSecret":"","existingSecretPasswordKey":"","host":"","port":"","uriSecret":{"key":"","name":""},"user":""}` | External PostgreSQL configuration. |
| guardrails.externalDatabase.database | string | `""` | The name of the database for the NeMo Guardrails service. |
| guardrails.externalDatabase.existingSecret | string | `""` | The name of an existing secret resource containing the database credentials. |
| guardrails.externalDatabase.existingSecretPasswordKey | string | `""` | The name of an existing secret key containing the database credentials. |
| guardrails.externalDatabase.host | string | `""` | The database host. |
| guardrails.externalDatabase.port | string | `""` | The database port number. |
| guardrails.externalDatabase.uriSecret.key | string | `""` | The key within the existing secret that includes a full database URI. |
| guardrails.externalDatabase.uriSecret.name | string | `""` | The name of an existing secret that includes a full database URI. |
| guardrails.externalDatabase.user | string | `""` | The username for the NeMo Guardrails external database. |
| guardrails.fsGroup | string | `""` | Specifies the file system owner group id. |
| guardrails.fullnameOverride | string | `""` | Overrides the full chart name. |
| guardrails.guardrails | object | `{"nvcfAPIKeySecretName":""}` | Kubernetes secret containing NVIDIA_API_KEY for Guardrails to use Nemoguard NIMS on NVCF |
| guardrails.guardrailsExtProc.enabled | bool | `false` |  |
| guardrails.guardrailsExtProc.env.GRPC_GO_LOG_SEVERITY_LEVEL | string | `"INFO"` |  |
| guardrails.guardrailsExtProc.env.GR_GRPC__TLS__CERT_FILE | string | `"/ssl_creds/server.crt"` |  |
| guardrails.guardrailsExtProc.env.GR_GRPC__TLS__ENABLED | string | `"true"` |  |
| guardrails.guardrailsExtProc.env.GR_GRPC__TLS__KEY_FILE | string | `"/ssl_creds/server.key"` |  |
| guardrails.guardrailsExtProc.env.OTEL_EXPORTER_OTLP_INSECURE | string | `"true"` |  |
| guardrails.guardrailsExtProc.env.OTEL_EXPORTER_OTLP_PROTOCOL | string | `"grpc"` |  |
| guardrails.guardrailsExtProc.env.OTEL_SERVICE_NAME | string | `"guardrails-ext-proc-service"` |  |
| guardrails.guardrailsExtProc.extProcImage.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for Guardrails Callout server image. |
| guardrails.guardrailsExtProc.extProcImage.repository | string | `"nvcr.io/nvidia/nemo-microservices/guardrails-callout"` | Repository for Guardrails Callout server image. |
| guardrails.guardrailsExtProc.extProcImage.tag | string | `""` | The tag of the NeMo Guardrails Callout server image. |
| guardrails.image.pullPolicy | string | `"IfNotPresent"` | The image pull policy for the NeMo Guardrails container image. |
| guardrails.image.repository | string | `"nvcr.io/nvidia/nemo-microservices/guardrails"` | The repository location of the NeMo Guardrails container image. |
| guardrails.image.tag | string | `""` | The tag of the NeMo Guardrails container image. |
| guardrails.imagePullSecrets | list | `[{"name":"nvcrimagepullsecret"}]` | Specifies the list of secret names that are needed for the main container and any init containers. |
| guardrails.livenessProbe.httpGet | object | `{"path":"/v1/health","port":7331}` | The HTTP GET request to use for the liveness probe. |
| guardrails.livenessProbe.initialDelaySeconds | int | `5` | The initial delay seconds for the liveness probe. |
| guardrails.livenessProbe.timeoutSeconds | int | `30` | The timeout in seconds for the liveness probe. |
| guardrails.logLevel | string | `"INFO"` | Log level for the NeMo Guardrails microservice. |
| guardrails.nameOverride | string | `""` | Overrides the chart name. |
| guardrails.nodeSelector | object | `{}` | Specifies labels to ensure that the NeMo Guardrails microservice is deployed only on certain nodes. To learn more, refer to the [Node Selector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector) in the Kubernetes documentation. |
| guardrails.opentelemetry-collector | object | `{"config":{"exporters":{"debug":{"verbosity":"detailed"}},"processors":{"batch":{}},"receivers":{"otlp":{"protocols":{"grpc":{},"http":{"cors":{"allowed_origins":["*"]}}}}},"service":{"pipelines":{"logs":{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]},"metrics":{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]},"traces":{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]}}}},"enabled":false,"mode":"deployment"}` | Configuration for the "opentelemetry-collector" service. |
| guardrails.opentelemetry-collector.config | object | `{"exporters":{"debug":{"verbosity":"detailed"}},"processors":{"batch":{}},"receivers":{"otlp":{"protocols":{"grpc":{},"http":{"cors":{"allowed_origins":["*"]}}}}},"service":{"pipelines":{"logs":{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]},"metrics":{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]},"traces":{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]}}}}` | The configuration used by the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.config.exporters.debug | object | `{"verbosity":"detailed"}` | Debugging verbosity for the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.config.processors.batch | object | `{}` | The batch processor for the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.config.receivers.otlp | object | `{"protocols":{"grpc":{},"http":{"cors":{"allowed_origins":["*"]}}}}` | The OTLP receiver for the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.config.service.pipelines.logs | object | `{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]}` | The logs pipeline for the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.config.service.pipelines.logs.exporters | list | `["debug"]` | The exporters for the logs pipeline for the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.config.service.pipelines.logs.processors | list | `["batch"]` | The processors for the logs pipeline for the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.config.service.pipelines.logs.receivers | list | `["otlp"]` | The receivers for the logs pipeline for the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.config.service.pipelines.metrics | object | `{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]}` | The metrics pipeline for the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.config.service.pipelines.metrics.exporters | list | `["debug"]` | The exporters for the metrics pipeline for the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.config.service.pipelines.metrics.processors | list | `["batch"]` | The processors for the metrics pipeline for the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.config.service.pipelines.metrics.receivers | list | `["otlp"]` | The receivers for the metrics pipeline for the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.config.service.pipelines.traces | object | `{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]}` | The traces pipeline for the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.config.service.pipelines.traces.exporters | list | `["debug"]` | The exporters for the traces pipeline for the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.config.service.pipelines.traces.processors | list | `["batch"]` | The processors for the traces pipeline for the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.config.service.pipelines.traces.receivers | list | `["otlp"]` | The receivers for the traces pipeline for the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.enabled | bool | `false` | Whether to enable the OpenTelemetry Collector service. |
| guardrails.opentelemetry-collector.mode | string | `"deployment"` | The mode for the OpenTelemetry Collector service. |
| guardrails.otelEnvVars | object | `{"OTEL_LOGS_EXPORTER":"otlp","OTEL_METRICS_EXPORTER":"otlp","OTEL_PROPAGATORS":"tracecontext,baggage","OTEL_PYTHON_EXCLUDED_URLS":"health","OTEL_RESOURCE_ATTRIBUTES":"deployment.environment=$(NAMESPACE),service.namespace=$(NAMESPACE)","OTEL_TRACES_EXPORTER":"otlp"}` | OpenTelemetry environment configuration variables for the NeMo Guardrails microservice. |
| guardrails.otelExporterEnabled | bool | `false` | Whether to enable the OpenTelemetry exporter for the NeMo Guardrails microservice. |
| guardrails.podAnnotations | object | `{}` | Specifies additional annotations to the main deployment pods. |
| guardrails.podLabels | object | `{}` | Specifies additional labels to the main deployment pods. |
| guardrails.podSecurityContext | object | `{}` | Specifies privilege and access control settings for the pod. |
| guardrails.postgresWaitImage.repository | string | `"busybox"` | The repository location of the image used to wait for postgres to start. |
| guardrails.postgresWaitImage.tag | string | `"latest"` | The tag of the image used when waiting. |
| guardrails.postgresql.architecture | string | `"standalone"` | The architecture for the default PostgreSQL service. |
| guardrails.postgresql.auth.database | string | `"nemo-guardrails"` | The name for a custom database to create. |
| guardrails.postgresql.auth.enablePostgresUser | bool | `true` | Whether to assign a password to the "postgres" admin user. If disabled, remote access is blocked for this user. |
| guardrails.postgresql.auth.existingSecret | string | `""` | The name of an existing secret to use for PostgreSQL credentials. |
| guardrails.postgresql.auth.password | string | `"guardrails"` | The password for the PostgreSQL user. |
| guardrails.postgresql.auth.username | string | `"guardrails"` | The user name to use for the PostgreSQL database. |
| guardrails.postgresql.enabled | bool | `true` | Whether to install the default PostgreSQL Helm chart. If enabled, the NeMo Guardrails microservice Helm chart uses the [PostgreSQL Helm chart from Bitnami](https://github.com/bitnami/charts/blob/main/bitnami/postgresql/values.yaml) to create a PostgreSQL database. |
| guardrails.postgresql.image.repository | string | `"bitnamilegacy/postgresql"` |  |
| guardrails.postgresql.metrics.image.repository | string | `"bitnamilegacy/postgres-exporter"` |  |
| guardrails.postgresql.nameOverride | string | `"guardrailsdb"` | The name override for the Guardrails PostgreSQL database. |
| guardrails.postgresql.serviceAccount.create | bool | `true` | Specifies whether to create a new service account for PostgreSQL. |
| guardrails.postgresql.serviceAccount.name | string | `"guardrails-postgresql"` | The name of the service account for PostgreSQL. |
| guardrails.postgresql.volumePermissions.image.repository | string | `"bitnamilegacy/os-shell"` |  |
| guardrails.readinessProbe.httpGet | object | `{"path":"/v1/health","port":7331}` | The HTTP GET request to use for the readiness probe. |
| guardrails.readinessProbe.initialDelaySeconds | int | `5` | The initial delay seconds for the readiness probe. |
| guardrails.readinessProbe.timeoutSeconds | int | `30` | The timeout in seconds for the readiness probe. |
| guardrails.replicaCount | int | `1` | Number of replicas for the NeMo Guardrails microservice deployment. |
| guardrails.resources | object | `{}` | Specifies resource configurations for the deployment. |
| guardrails.runAsGroup | string | `""` | Specifies the group ID for the pod. |
| guardrails.securityContext | object | `{}` | Specifies security context for the container. |
| guardrails.service | object | `{"port":7331,"type":"ClusterIP"}` | Specifies the service type and the port for the deployment. |
| guardrails.serviceAccount.annotations | object | `{}` | Annotations to be added to the service account. |
| guardrails.serviceAccount.automount | bool | `true` | Whether to automatically mount the service account token. |
| guardrails.serviceAccount.create | bool | `true` | Whether to create a service account for the NeMo Guardrails microservice. |
| guardrails.serviceAccount.name | string | `""` | The name of the service account to use. |
| guardrails.serviceName | string | `"nemo-guardrails"` | The service name for the NeMo Guardrails microservice. |
| guardrails.tolerations | list | `[]` | Specifies tolerations for pod assignment. To learn more, refer to the [Taint and Toleration](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) in the Kubernetes documentation. |
| imagePullSecrets | list | `[{"name":"nvcrimagepullsecret","password":"YOUR-NGC-API-KEY","registry":"nvcr.io","username":"$$oauthtoken"}]` | List of image pull secrets. Existing secrets override these values if you specify them. Use this only for experimentation when you want to hardcode a secret in your values file. |
| ingress.annotations | object | `{"ingress.kubernetes.io/proxy-body-size":"50g","nginx.ingress.kubernetes.io/proxy-body-size":"50g"}` | Annotations for the ingress resource. |
| ingress.className | string | `""` | The ingress class to use if your cluster has more than one class. |
| ingress.enabled | bool | `true` | Specifies whether to enable the ingress. |
| ingress.hosts | object | `{"dataStore":{"name":"data-store.test","paths":[{"path":"/","pathType":"Prefix","port":3000,"service":"nemo-data-store"}]},"default":{"name":"","paths":[{"path":"/v1/namespaces","pathType":"Prefix","port":8000,"service":"nemo-entity-store"},{"path":"/v1/projects","pathType":"Prefix","port":8000,"service":"nemo-entity-store"},{"path":"/v1/datasets","pathType":"Prefix","port":8000,"service":"nemo-entity-store"},{"path":"/v1/repos","pathType":"Prefix","port":8000,"service":"nemo-entity-store"},{"path":"/v1/models","pathType":"Prefix","port":8000,"service":"nemo-entity-store"},{"path":"/v1/customization","pathType":"Prefix","port":8000,"service":"nemo-customizer"},{"path":"/v1/evaluation","pathType":"Prefix","port":7331,"service":"nemo-evaluator"},{"path":"/v2/evaluation","pathType":"Prefix","port":7331,"service":"nemo-evaluator"},{"path":"/v1/guardrail","pathType":"Prefix","port":7331,"service":"nemo-guardrails"},{"path":"/v1/deployment","pathType":"Prefix","port":8000,"service":"nemo-deployment-management"},{"path":"/v1/data-designer","pathType":"Prefix","port":8000,"service":"nemo-data-designer"},{"path":"/v1beta1/audit","pathType":"Prefix","port":5000,"service":"nemo-auditor"},{"path":"/v1beta1/safe-synthesizer","pathType":"Prefix","port":8000,"service":"nemo-safe-synthesizer"},{"path":"/v1/jobs","pathType":"Prefix","port":8000,"service":"nemo-core-api"},{"path":"/v2/inference/gateway","pathType":"Prefix","port":8000,"service":"nemo-core-api"},{"path":"/v2/inference","pathType":"Prefix","port":8000,"service":"nemo-core-api"},{"path":"/v2/models","pathType":"Prefix","port":8000,"service":"nemo-core-api"},{"path":"/v1/intake","pathType":"Prefix","port":8000,"service":"nemo-intake"},{"path":"/studio","pathType":"Prefix","port":3000,"service":"nemo-studio"}]},"nimProxy":{"name":"nim.test","paths":[{"path":"/v1/completions","pathType":"Prefix","port":8000,"service":"nemo-nim-proxy"},{"path":"/v1/chat","pathType":"Prefix","port":8000,"service":"nemo-nim-proxy"},{"path":"/v1/embeddings","pathType":"Prefix","port":8000,"service":"nemo-nim-proxy"},{"path":"/v1/classify","pathType":"Prefix","port":8000,"service":"nemo-nim-proxy"},{"path":"/v1/models","pathType":"Prefix","port":8000,"service":"nemo-nim-proxy"}]}}` | A map of hosts and their corresponding paths for the ingress. |
| ingress.hosts.dataStore.name | string | `"data-store.test"` | The host name for the third ingress host for the NeMo Data Store microservice. |
| ingress.hosts.dataStore.paths | list | `[{"path":"/","pathType":"Prefix","port":3000,"service":"nemo-data-store"}]` | The path rules for the third ingress host. |
| ingress.hosts.default.name | string | `""` | The host name for the default ingress host. |
| ingress.hosts.default.paths | list | `[{"path":"/v1/namespaces","pathType":"Prefix","port":8000,"service":"nemo-entity-store"},{"path":"/v1/projects","pathType":"Prefix","port":8000,"service":"nemo-entity-store"},{"path":"/v1/datasets","pathType":"Prefix","port":8000,"service":"nemo-entity-store"},{"path":"/v1/repos","pathType":"Prefix","port":8000,"service":"nemo-entity-store"},{"path":"/v1/models","pathType":"Prefix","port":8000,"service":"nemo-entity-store"},{"path":"/v1/customization","pathType":"Prefix","port":8000,"service":"nemo-customizer"},{"path":"/v1/evaluation","pathType":"Prefix","port":7331,"service":"nemo-evaluator"},{"path":"/v2/evaluation","pathType":"Prefix","port":7331,"service":"nemo-evaluator"},{"path":"/v1/guardrail","pathType":"Prefix","port":7331,"service":"nemo-guardrails"},{"path":"/v1/deployment","pathType":"Prefix","port":8000,"service":"nemo-deployment-management"},{"path":"/v1/data-designer","pathType":"Prefix","port":8000,"service":"nemo-data-designer"},{"path":"/v1beta1/audit","pathType":"Prefix","port":5000,"service":"nemo-auditor"},{"path":"/v1beta1/safe-synthesizer","pathType":"Prefix","port":8000,"service":"nemo-safe-synthesizer"},{"path":"/v1/jobs","pathType":"Prefix","port":8000,"service":"nemo-core-api"},{"path":"/v2/inference/gateway","pathType":"Prefix","port":8000,"service":"nemo-core-api"},{"path":"/v2/inference","pathType":"Prefix","port":8000,"service":"nemo-core-api"},{"path":"/v2/models","pathType":"Prefix","port":8000,"service":"nemo-core-api"},{"path":"/v1/intake","pathType":"Prefix","port":8000,"service":"nemo-intake"},{"path":"/studio","pathType":"Prefix","port":3000,"service":"nemo-studio"}]` | The path rules for the default ingress host. |
| ingress.hosts.nimProxy.name | string | `"nim.test"` | The host name for the second ingress host for the NIM Proxy microservice. |
| ingress.hosts.nimProxy.paths | list | `[{"path":"/v1/completions","pathType":"Prefix","port":8000,"service":"nemo-nim-proxy"},{"path":"/v1/chat","pathType":"Prefix","port":8000,"service":"nemo-nim-proxy"},{"path":"/v1/embeddings","pathType":"Prefix","port":8000,"service":"nemo-nim-proxy"},{"path":"/v1/classify","pathType":"Prefix","port":8000,"service":"nemo-nim-proxy"},{"path":"/v1/models","pathType":"Prefix","port":8000,"service":"nemo-nim-proxy"}]` | The path rules for the second ingress host. |
| ingress.tls | list | `[]` | TLS configurations. |
| intake.affinity | object | `{}` |  |
| intake.autoscaling.enabled | bool | `false` |  |
| intake.autoscaling.maxReplicas | int | `1` |  |
| intake.autoscaling.minReplicas | int | `1` |  |
| intake.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| intake.env.NIM_URI | string | `"http://nemo-nim-proxy:8000/v1"` |  |
| intake.env.POSTGRES_URI | string | `"postgresql://postgres:password@nemo-intakedb:5432/postgres"` |  |
| intake.env.REDACT_COMPLETIONS | string | `"true"` |  |
| intake.fullnameOverride | string | `""` |  |
| intake.image.pullPolicy | string | `"IfNotPresent"` |  |
| intake.image.repository | string | `"nvcr.io/nvidia/nemo-microservices/intake"` |  |
| intake.image.tag | string | `""` |  |
| intake.imagePullSecrets[0].name | string | `"gitlab-imagepull"` |  |
| intake.livenessProbe.failureThreshold | int | `100` |  |
| intake.livenessProbe.httpGet.path | string | `"/health"` |  |
| intake.livenessProbe.httpGet.port | string | `"http"` |  |
| intake.livenessProbe.initialDelaySeconds | int | `0` |  |
| intake.livenessProbe.periodSeconds | int | `10` |  |
| intake.livenessProbe.timeoutSeconds | int | `600` |  |
| intake.nameOverride | string | `""` |  |
| intake.nodeSelector | object | `{}` |  |
| intake.podLabels | object | `{}` |  |
| intake.podSecurityContext.fsGroup | int | `1000` |  |
| intake.postgresql.auth.password | string | `"password"` |  |
| intake.postgresql.auth.postgresPassword | string | `"password"` |  |
| intake.postgresql.auth.username | string | `"user"` |  |
| intake.postgresql.enabled | bool | `true` |  |
| intake.postgresql.image.repository | string | `"bitnamilegacy/postgresql"` |  |
| intake.postgresql.metrics.image.repository | string | `"bitnamilegacy/postgres-exporter"` |  |
| intake.postgresql.nameOverride | string | `"intakedb"` |  |
| intake.postgresql.primary.passwordUpdateJob.enabled | bool | `true` |  |
| intake.postgresql.primary.persistence.enabled | bool | `true` |  |
| intake.postgresql.primary.persistence.size | string | `"50Gi"` |  |
| intake.postgresql.volumePermissions.image.repository | string | `"bitnamilegacy/os-shell"` |  |
| intake.readinessProbe.failureThreshold | int | `100` |  |
| intake.readinessProbe.httpGet.path | string | `"/health"` |  |
| intake.readinessProbe.httpGet.port | string | `"http"` |  |
| intake.readinessProbe.initialDelaySeconds | int | `0` |  |
| intake.readinessProbe.periodSeconds | int | `10` |  |
| intake.readinessProbe.timeoutSeconds | int | `600` |  |
| intake.replicaCount | int | `1` |  |
| intake.resources | object | `{}` |  |
| intake.securityContext | object | `{}` |  |
| intake.service.port | int | `8000` |  |
| intake.service.type | string | `"ClusterIP"` |  |
| intake.serviceAccount.annotations | object | `{}` |  |
| intake.serviceAccount.automount | bool | `true` |  |
| intake.serviceAccount.create | bool | `true` |  |
| intake.serviceAccount.name | string | `""` |  |
| intake.serviceName | string | `"nemo-intake"` |  |
| nemo-operator.controllerManager.kubeRbacProxy.args | list | `["--secure-listen-address=0.0.0.0:8443","--upstream=http://127.0.0.1:8080/","--logtostderr=true","--v=0"]` | Arguments to pass to the `kube-rbac-proxy` container. |
| nemo-operator.controllerManager.kubeRbacProxy.containerSecurityContext.allowPrivilegeEscalation | bool | `false` | Whether to allow container privilege escalation. |
| nemo-operator.controllerManager.kubeRbacProxy.containerSecurityContext.capabilities.drop | list | `["ALL"]` | List of capabilities to drop. |
| nemo-operator.controllerManager.kubeRbacProxy.image.repository | string | `"gcr.io/kubebuilder/kube-rbac-proxy"` | The repository for the `kube-rbac-proxy` image. |
| nemo-operator.controllerManager.kubeRbacProxy.image.tag | string | `"v0.15.0"` | The tag for the `kube-rbac-proxy` image. |
| nemo-operator.controllerManager.kubeRbacProxy.resources.limits.cpu | string | `"500m"` | The CPU limit for the `kube-rbac-proxy` container. |
| nemo-operator.controllerManager.kubeRbacProxy.resources.limits.memory | string | `"128Mi"` | The memory limit for the `kube-rbac-proxy` container. |
| nemo-operator.controllerManager.kubeRbacProxy.resources.requests.cpu | string | `"5m"` | The CPU request for the `kube-rbac-proxy` container. |
| nemo-operator.controllerManager.kubeRbacProxy.resources.requests.memory | string | `"64Mi"` | The memory request for the `kube-rbac-proxy` container. |
| nemo-operator.controllerManager.manager.args | list | `["--health-probe-bind-address=:8081","--metrics-bind-address=127.0.0.1:8080","--leader-elect","--leader-election-id=nemo.nko.nvidia.com"]` | Arguments to pass to the manager container. |
| nemo-operator.controllerManager.manager.containerSecurityContext.allowPrivilegeEscalation | bool | `false` | Whether to allow container privilege escalation. |
| nemo-operator.controllerManager.manager.containerSecurityContext.capabilities.drop | list | `["ALL"]` | List of capabilities to drop. |
| nemo-operator.controllerManager.manager.image.repository | string | `"nvcr.io/nvidia/nemo-microservices/nemo-operator"` | The repository for the NeMo Operator microservice image. |
| nemo-operator.controllerManager.manager.image.tag | string | `""` | The tag for the NeMo Operator microservice image. The default value is `appVersion` from the `Chart.yaml` file. |
| nemo-operator.controllerManager.manager.resources.limits.cpu | string | `"1024m"` | The CPU limit for the operator manager container. |
| nemo-operator.controllerManager.manager.resources.limits.memory | string | `"2Gi"` | The memory limit for the operator manager container. |
| nemo-operator.controllerManager.manager.resources.requests.cpu | string | `"512m"` | The CPU request for the operator manager container. |
| nemo-operator.controllerManager.manager.resources.requests.memory | string | `"1Gi"` | The memory request for the operator manager container. |
| nemo-operator.controllerManager.manager.scheduler | string | `"volcano"` | The scheduler to use for the controller manager. |
| nemo-operator.controllerManager.replicas | int | `1` | The number of operator replicas to run. |
| nemo-operator.controllerManager.serviceAccount.annotations | object | `{}` | Annotations to add to the service account. |
| nemo-operator.env | object | `{}` | Additional environment variables to pass to controller manager. The format is `NAME: value` or `NAME: valueFrom: {object}`. |
| nemo-operator.imagePullSecrets | list | `[{"name":"nvcrimagepullsecret"}]` | Image pull secrets for accessing the NGC container registry. |
| nemo-operator.kubernetesClusterDomain | string | `"cluster.local"` | The Kubernetes cluster domain. |
| nemo-operator.metricsService.enabled | bool | `true` | Whether to enable the metrics service for the NeMo Operator microservice. If you enable it, the microservice exposes a metrics endpoint for Prometheus. Before installing this chart, you should have Prometheus installed in your environment. |
| nemo-operator.metricsService.ports | list | `[{"name":"https","port":8443,"protocol":"TCP","targetPort":"https"}]` | The metrics service ports configuration. |
| nemo-operator.metricsService.type | string | `"ClusterIP"` | The type of the metrics service. |
| nemo-operator.watchAllNamespaces | bool | `false` | Whether to watch all namespaces, default is to restrict the NeMo Operator microservice to watch resources in the NMP deployment namespace. |
| ngcAPIKey | string | `"YOUR-NGC-API-KEY"` | Your NVIDIA GPU Cloud (NGC) API key authenticates and enables pulling images from the NGC container registry. The existing secret overrides this key if you provide one to the `existingSecret` key. |
| nim-operator.nfd.nodeFeatureRules.deviceID | bool | `false` | Specifies whether to enable device ID feature rules. |
| nim-proxy.affinity | object | `{}` | Specifies affinity settings for the deployment. To learn more, refer to [Affinity and Anti-Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity) in the Kubernetes documentation. |
| nim-proxy.autoscaling.enabled | bool | `false` | Whether to enable horizontal pod autoscaling for the NIM Proxy microservice. |
| nim-proxy.autoscaling.maxReplicas | int | `100` | The maximum number of replicas for the NIM Proxy microservice. |
| nim-proxy.autoscaling.minReplicas | int | `1` | The minimum number of replicas for the NIM Proxy microservice. |
| nim-proxy.autoscaling.targetCPUUtilizationPercentage | int | `80` | The target CPU utilization percentage for the NIM Proxy microservice. |
| nim-proxy.env | object | `{}` | Additional environment variables to pass to containers. The format is `NAME: value` or `NAME: valueFrom: {object}`. |
| nim-proxy.fullnameOverride | string | `""` | String to fully override the name on resulting Kubernetes objects when the NIM Proxy microservice is deployed. |
| nim-proxy.image.pullPolicy | string | `"IfNotPresent"` | The container image pull policy for the NIM Proxy container. |
| nim-proxy.image.repository | string | `"nvcr.io/nvidia/nemo-microservices/nim-proxy"` | The repository of the NIM Proxy container image. |
| nim-proxy.image.tag | string | `""` | The container image tag. If not set, the default value is `appVersion` from the `Chart.yaml` file. |
| nim-proxy.imagePullSecrets | list | `[]` | Image pull secrets for accessing the NGC container registry. |
| nim-proxy.livenessProbe.httpGet.path | string | `"/health"` | The HTTP path for the Kubernetes liveness probe. Do not change this. |
| nim-proxy.livenessProbe.httpGet.port | string | `"http"` | The port name for the Kubernetes liveness probe. Do not change this. |
| nim-proxy.monitoring | object | `{"enabled":false,"interval":"30s","path":"/v1/metrics","scheme":"http"}` | Prometheus metrics collection configuration for monitoring the NIM Proxy microservice. To enable this, you should install the Prometheus operator before deploying the NIM Proxy microservice. |
| nim-proxy.monitoring.enabled | bool | `false` | Whether to enable monitoring for the NIM Proxy microservice. |
| nim-proxy.monitoring.interval | string | `"30s"` | The scrape interval for monitoring. |
| nim-proxy.monitoring.path | string | `"/v1/metrics"` | The metrics path for monitoring. |
| nim-proxy.monitoring.scheme | string | `"http"` | The scheme for monitoring. |
| nim-proxy.nameOverride | string | `""` | String to partially override name on resulting Kubernetes objects when the NIM Proxy microservice is deployed. |
| nim-proxy.nimNamespace | string | `""` | Specifies a namespace to restrict the NIM Proxy microservice to watch NIMs in. Leave it empty to watch all namespaces. |
| nim-proxy.nodeSelector | object | `{}` | Specifies labels to ensure that the microservice is deployed only on certain nodes. To learn more, refer to [Node Selector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector) in the Kubernetes documentation. |
| nim-proxy.podAnnotations | object | `{}` | Pod annotations. |
| nim-proxy.podDisruptionBudget | object | `{"enabled":false,"maxUnavailable":"","minAvailable":""}` | Pod Disruption Budget configuration for the NIM Proxy microservice. This helps maintain high availability during voluntary disruptions like node drains or upgrades. To learn more, refer to [Pod Disruption Budget](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/) in the Kubernetes documentation. |
| nim-proxy.podDisruptionBudget.enabled | bool | `false` | Whether to enable the Pod Disruption Budget for the NIM Proxy microservice. |
| nim-proxy.podDisruptionBudget.maxUnavailable | string | `""` | The maximum number of pods that can be unavailable during a disruption. Cannot be used simultaneously with minAvailable. |
| nim-proxy.podDisruptionBudget.minAvailable | string | `""` | The minimum number of pods that must be available during a disruption. Cannot be used simultaneously with maxUnavailable. |
| nim-proxy.podLabels | object | `{}` | Pod labels. |
| nim-proxy.podSecurityContext | object | `{}` | Pod security context. Use the default settings, unless you understand what changes in the pod security context settings you want to apply. |
| nim-proxy.readinessProbe.httpGet.path | string | `"/health"` | The HTTP path for the Kubernetes readiness probe. Do not change this. |
| nim-proxy.readinessProbe.httpGet.port | string | `"http"` | The port name for the Kubernetes readiness probe. Do not change this. |
| nim-proxy.replicaCount | int | `1` | The number of replicas for the NeMo NIM Proxy service. |
| nim-proxy.resources | object | `{}` | Configures Kubernetes resource requests and limits for the NIM Proxy microservice. Use the default settings and leave it with the empty object as is, unless you understand what changes you want to make. |
| nim-proxy.securityContext | object | `{"readOnlyRootFilesystem":true}` | Security context. Use the default settings, unless you understand what changes in the security context settings you want to apply. |
| nim-proxy.securityContext.readOnlyRootFilesystem | bool | `true` | Whether to run with a read-only root filesystem. |
| nim-proxy.service.main.port | int | `8000` | The port of the main service. |
| nim-proxy.service.main.type | string | `"ClusterIP"` | The type of the main service. |
| nim-proxy.service.metricsPort.port | int | `8001` | The port of the metrics service. |
| nim-proxy.service.metricsPort.type | string | `"ClusterIP"` | The type of the metrics service. |
| nim-proxy.serviceAccount.annotations | object | `{}` | Annotations to add to the service account. |
| nim-proxy.serviceAccount.automount | bool | `true` | Whether to automatically mount a ServiceAccount's API credentials. |
| nim-proxy.serviceAccount.create | bool | `true` | Whether to create a service account for the NIM Proxy microservice. |
| nim-proxy.serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is `true`, a name is generated using the full name template. |
| nim-proxy.serviceName | string | `"nemo-nim-proxy"` | The service name for the NIM Proxy microservice. |
| nim-proxy.tolerations | list | `[]` | Specifies tolerations for pod assignment. To learn more, refer to [Taint and Toleration](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) in the Kubernetes documentation. |
| nim-proxy.volumeMounts | list | `[]` | Additional volume mounts for the NIM Proxy microservice. Use the default settings and leave it with the empty list as is, unless you understand what changes you want to make. |
| nim-proxy.volumes | list | `[]` | Additional volumes for the NIM Proxy microservice. Use the default settings and leave it with the empty list as is, unless you understand what changes you want to make. |
| nim.enabled | bool | `false` | Specifies whether to deploy a NIM for LLM during the Helm installation of the chart. You can deploy a single static NIM by enabling this object and its values. When enabled, the chart deploys `meta/llama-3.1-8b-instruct` as the default NIM. |
| nim.env | list | `[{"name":"NIM_PEFT_SOURCE","value":"http://nemo-entity-store:8000"},{"name":"NIM_PEFT_REFRESH_INTERVAL","value":"30"},{"name":"NIM_MAX_CPU_LORAS","value":"16"},{"name":"NIM_MAX_GPU_LORAS","value":"8"}]` | Environment variables for the NIM service. |
| nim.image.repository | string | `"nvcr.io/nim/meta/llama-3.1-8b-instruct"` |  |
| nim.image.tag | string | `"1.8"` |  |
| nim.imagePullSecrets[0].name | string | `"nvcrimagepullsecret"` |  |
| nim.model.name | string | `"meta/llama-3.1-8b-instruct"` | The name of the model to deploy as NIM. |
| nim.model.ngcAPISecret | string | `"ngc-api"` | The NGC API secret for model access. |
| nim.persistence.annotations | object | `{"helm.sh/resource-policy":"keep"}` | Annotations for the PVC. |
| nim.persistence.enabled | bool | `true` | Specifies whether to enable persistence volume claim (PVC) for the NIM service. |
| nim.persistence.storageClass | string | `""` | Specifies the storage class to use for the PVC. |
| nim.resources | object | `{"limits":{"nvidia.com/gpu":1},"requests":{"nvidia.com/gpu":1}}` | Specifies resources for the NIM service. |
| nim.resources.requests | object | `{"nvidia.com/gpu":1}` | Specifies requests for the NIM service. |
| nim.service.labels | object | `{"app.nvidia.com/nim-type":"inference"}` | Labels for the NIM service. |
| nim.statefulSet.enabled | bool | `false` | Specifies whether to enable a stateful set for the NIM service. |
| safe-synthesizer.affinity | object | `{}` |  |
| safe-synthesizer.autoscaling.enabled | bool | `false` |  |
| safe-synthesizer.autoscaling.maxReplicas | int | `10` |  |
| safe-synthesizer.autoscaling.minReplicas | int | `1` |  |
| safe-synthesizer.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| safe-synthesizer.classify.apiKey | string | `""` |  |
| safe-synthesizer.config.classify_llm_endpoint_url | string | `"https://integrate.api.nvidia.com/v1"` |  |
| safe-synthesizer.config.classify_llm_model_id | string | `"qwen/qwen2.5-coder-32b-instruct"` |  |
| safe-synthesizer.env.HOST_IP.valueFrom.fieldRef.fieldPath | string | `"status.hostIP"` |  |
| safe-synthesizer.env.LOG_LEVEL | string | `"INFO"` |  |
| safe-synthesizer.env.NEMO_SAFE_SYNTHESIZER_PORT | int | `8000` |  |
| safe-synthesizer.fullnameOverride | string | `""` |  |
| safe-synthesizer.image.pullPolicy | string | `"IfNotPresent"` |  |
| safe-synthesizer.image.repository | string | `"nvcr.io/nvidia/nemo-microservices/safe-synthesizer-api"` |  |
| safe-synthesizer.image.tag | string | `""` |  |
| safe-synthesizer.imagePullSecrets | list | `[]` |  |
| safe-synthesizer.jobsImage.pullPolicy | string | `"IfNotPresent"` |  |
| safe-synthesizer.jobsImage.repository | string | `"nvcr.io/nvidia/nemo-microservices/safe-synthesizer"` |  |
| safe-synthesizer.jobsImage.tag | string | `""` |  |
| safe-synthesizer.livenessProbe.failureThreshold | int | `3` |  |
| safe-synthesizer.livenessProbe.httpGet.path | string | `"/health"` |  |
| safe-synthesizer.livenessProbe.httpGet.port | string | `"http"` |  |
| safe-synthesizer.livenessProbe.initialDelaySeconds | int | `30` |  |
| safe-synthesizer.livenessProbe.periodSeconds | int | `10` |  |
| safe-synthesizer.livenessProbe.timeoutSeconds | int | `5` |  |
| safe-synthesizer.nameOverride | string | `""` |  |
| safe-synthesizer.nodeSelector | object | `{}` |  |
| safe-synthesizer.podAnnotations | object | `{}` |  |
| safe-synthesizer.podLabels | object | `{}` |  |
| safe-synthesizer.podSecurityContext.fsGroup | int | `1000` |  |
| safe-synthesizer.readinessProbe.failureThreshold | int | `3` |  |
| safe-synthesizer.readinessProbe.httpGet.path | string | `"/health"` |  |
| safe-synthesizer.readinessProbe.httpGet.port | string | `"http"` |  |
| safe-synthesizer.readinessProbe.initialDelaySeconds | int | `5` |  |
| safe-synthesizer.readinessProbe.periodSeconds | int | `5` |  |
| safe-synthesizer.readinessProbe.timeoutSeconds | int | `3` |  |
| safe-synthesizer.replicaCount | int | `1` |  |
| safe-synthesizer.resources | object | `{}` |  |
| safe-synthesizer.securityContext | string | `nil` |  |
| safe-synthesizer.service.port | int | `8000` |  |
| safe-synthesizer.service.type | string | `"ClusterIP"` |  |
| safe-synthesizer.serviceAccount.annotations | object | `{}` |  |
| safe-synthesizer.serviceAccount.automount | bool | `true` |  |
| safe-synthesizer.serviceAccount.create | bool | `true` |  |
| safe-synthesizer.serviceAccount.name | string | `""` |  |
| safe-synthesizer.serviceName | string | `"nemo-safe-synthesizer"` |  |
| safe-synthesizer.tolerations | list | `[]` |  |
| safe-synthesizer.volumeMounts | list | `[]` |  |
| safe-synthesizer.volumes | list | `[]` |  |
| studio.affinity | object | `{}` |  |
| studio.autoscaling.enabled | bool | `false` |  |
| studio.autoscaling.maxReplicas | int | `10` |  |
| studio.autoscaling.minReplicas | int | `1` |  |
| studio.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| studio.baseRoute | string | `"studio"` | Specifies a base url or path (e.g. studio for https://domain.com/studio) |
| studio.customizerUrl | string | `""` | The external URL of the NeMo Customizer microservice (if different from the platform base url). |
| studio.dataStoreUrl | string | `"http://data-store.test:3000"` | The external URL of the NeMo Data Store microservice. |
| studio.entityStoreUrl | string | `""` | The external URL of the NeMo Entity Store microservice (if different from the platform base url). |
| studio.env | object | `{}` |  |
| studio.evaluatorUrl | string | `""` | The external URL of the NeMo Evaluator microservice (if different from the platform base url). |
| studio.fullnameOverride | string | `""` |  |
| studio.image.pullPolicy | string | `"IfNotPresent"` |  |
| studio.image.repository | string | `"nvcr.io/nvidia/nemo-microservices/nemo-studio-ui"` |  |
| studio.image.tag | string | `""` |  |
| studio.imagePullSecrets | list | `[]` |  |
| studio.livenessProbe.httpGet.path | string | `"/health"` |  |
| studio.livenessProbe.httpGet.port | string | `"http"` |  |
| studio.nameOverride | string | `""` |  |
| studio.nimProxyInternalUrl | string | `"http://nemo-nim-proxy:8000"` | The internal URL of the NeMo NIM Proxy microservice. |
| studio.nimProxyUrl | string | `"http://nim.test:3000"` | The external URL of the NeMo NIM Proxy microservice. |
| studio.nodeSelector | object | `{}` |  |
| studio.openTelemetry | object | `{"collectorURL":"","enabled":false,"proxyURL":"","serviceName":"nemo-studio-ui"}` | OpenTelemetry environment configuration variables for the Studio UI |
| studio.platformBaseUrl | string | `"http://nemo.test:3000"` | The base url for platform endpoints |
| studio.podAnnotations | object | `{}` |  |
| studio.podLabels | object | `{}` |  |
| studio.podSecurityContext | object | `{}` |  |
| studio.readinessProbe.httpGet.path | string | `"/ready"` |  |
| studio.readinessProbe.httpGet.port | string | `"http"` |  |
| studio.replicaCount | int | `1` |  |
| studio.resources | object | `{}` |  |
| studio.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| studio.service.port | int | `3000` |  |
| studio.service.type | string | `"ClusterIP"` |  |
| studio.serviceAccount.annotations | object | `{}` |  |
| studio.serviceAccount.automount | bool | `true` |  |
| studio.serviceAccount.create | bool | `true` |  |
| studio.serviceAccount.name | string | `""` |  |
| studio.serviceName | string | `"nemo-studio"` | The service name for the NeMo Studio UI microservice. |
| studio.tolerations | list | `[]` |  |
| studio.volumeMounts[0].mountPath | string | `"/usr/share/nginx/html"` |  |
| studio.volumeMounts[0].name | string | `"html"` |  |
| studio.volumeMounts[1].mountPath | string | `"/var/run"` |  |
| studio.volumeMounts[1].name | string | `"run"` |  |
| studio.volumeMounts[2].mountPath | string | `"/tmp"` |  |
| studio.volumeMounts[2].name | string | `"temp"` |  |
| studio.volumes[0].emptyDir | object | `{}` |  |
| studio.volumes[0].name | string | `"html"` |  |
| studio.volumes[1].emptyDir | object | `{}` |  |
| studio.volumes[1].name | string | `"run"` |  |
| studio.volumes[2].emptyDir | object | `{}` |  |
| studio.volumes[2].name | string | `"temp"` |  |
| tags.auditor | bool | `false` | Specifies whether to install the NeMo Auditor microservice. |
| tags.intake | bool | `false` | Specifies whether to install the NeMo Intake microservice. |
| tags.platform | bool | `true` | When set to `true`, installs the primary NeMo microservices platform. To install individual microservices, set `platform` to `false` and configure the `tags` key with values for each individual microservice. For more information, refer to [Tag-Based Installation](https://docs.nvidia.com/nemo/microservices/latest/set-up/deployment-options.html#tag-based-installation). |
| tags.safe-synthesizer | bool | `false` | Specifies whether to install the NeMo Safe Synthesizer microservice. |
| tags.studio | bool | `false` | Specifies whether to install the NeMo Studio UI microservice. |
| virtualService | object | A virtual service configuration template. | Specifies whether to enable the virtual service. If you are not using istio and virtualservices, it can be useful to create some virtual services for the NeMo Microservices system. Don't enable unless you use istio. |
| virtualService.additional.data-store | object | `{"entries":{"data-store":{"corsPolicy":{},"match":[{"uri":{"prefix":"/"}}],"route":[{"destination":{"host":"nemo-data-store","port":{"number":3000}}}]}},"gateways":[],"hosts":[]}` | Additional virtual service configurations. |
| virtualService.additional.data-store.entries | object | `{"data-store":{"corsPolicy":{},"match":[{"uri":{"prefix":"/"}}],"route":[{"destination":{"host":"nemo-data-store","port":{"number":3000}}}]}}` | The entries for the virtual NeMo Data Store service. |
| virtualService.additional.data-store.entries.data-store.corsPolicy | object | `{}` | The CORS policy for the virtual NeMo Data Store service. |
| virtualService.additional.data-store.entries.data-store.match | list | `[{"uri":{"prefix":"/"}}]` | The match for the virtual NeMo Data Store service. |
| virtualService.additional.data-store.entries.data-store.route | list | `[{"destination":{"host":"nemo-data-store","port":{"number":3000}}}]` | The route for the virtual NeMo Data Store service. |
| virtualService.additional.data-store.gateways | list | `[]` | The gateways for the virtual NeMo Data Store service. |
| virtualService.additional.data-store.hosts | list | `[]` | The hosts for the virtual NeMo Data Store service. |
| virtualService.additional.nim-proxy.entries.nim-proxy.corsPolicy | object | `{}` | The CORS policy for the virtual NIM Proxy service. |
| virtualService.additional.nim-proxy.entries.nim-proxy.match | list | `[{"uri":{"prefix":"/"}}]` | The match for the virtual NIM Proxy service. |
| virtualService.additional.nim-proxy.entries.nim-proxy.route | list | `[{"destination":{"host":"nemo-nim-proxy","port":{"number":8000}}}]` | The route for the virtual NIM Proxy service. |
| virtualService.additional.nim-proxy.gateways | list | `[]` | The gateways for the virtual NIM Proxy service. |
| virtualService.additional.nim-proxy.hosts | list | `[]` | The hosts for the virtual NIM Proxy service. |
| virtualService.annotations | object | `{}` | Annotations for the virtual service. |
| virtualService.enabled | bool | `false` | Specifies whether to enable the virtual service. |
| virtualService.labels | object | `{}` | Labels for the virtual service. |
| virtualService.main.entries.auditor.corsPolicy | object | `{}` | The CORS policy for the virtual NeMo Auditor service. |
| virtualService.main.entries.auditor.match | list | `[{"uri":{"prefix":"/v1beta1/audit"}}]` | The match for the virtual NeMo Auditor service. |
| virtualService.main.entries.auditor.route | list | `[{"destination":{"host":"nemo-auditor","port":{"number":5000}}}]` | The route for the virtual NeMo Auditor service. |
| virtualService.main.entries.core.corsPolicy | object | `{}` | The CORS policy for the virtual NeMo Core service. |
| virtualService.main.entries.core.match | list | `[{"uri":{"prefix":"/v1/jobs"}},{"uri":{"prefix":"/v2/inference/gateway"}},{"uri":{"prefix":"/v2/inference"}},{"uri":{"prefix":"/v2/models"}}]` | The match for the virtual NeMo Core service. |
| virtualService.main.entries.core.route | list | `[{"destination":{"host":"nemo-core-api","port":{"number":8000}}}]` | The route for the virtual NeMo Core service. |
| virtualService.main.entries.customizer.corsPolicy | object | `{}` | The CORS policy for the virtual NeMo Customizer service. |
| virtualService.main.entries.customizer.match | list | `[{"uri":{"prefix":"/v1/customization"}}]` | The match for the virtual NeMo Customizer service. |
| virtualService.main.entries.customizer.route | list | `[{"destination":{"host":"nemo-customizer","port":{"number":8000}}}]` | The route for the virtual NeMo Customizer service. |
| virtualService.main.entries.deployment-management.corsPolicy | object | `{}` | The CORS policy for the virtual NeMo Deployment Management service. |
| virtualService.main.entries.deployment-management.match | list | `[{"uri":{"prefix":"/v1/deployment"}}]` | The match for the virtual NeMo Deployment Management service. |
| virtualService.main.entries.deployment-management.route | list | `[{"destination":{"host":"nemo-deployment-management","port":{"number":8000}}}]` | The route for the virtual NeMo Deployment Management service. |
| virtualService.main.entries.entity-store.corsPolicy | object | `{}` | The CORS policy for the virtual NeMo Entity Store service. |
| virtualService.main.entries.entity-store.match | list | `[{"uri":{"prefix":"/v1/namespaces"}},{"uri":{"prefix":"/v1/projects"}},{"uri":{"prefix":"/v1/datasets"}},{"uri":{"prefix":"/v1/repos"}},{"uri":{"prefix":"/v1/models"}}]` | The match for the virtual NeMo Entity Store service. |
| virtualService.main.entries.entity-store.route | list | `[{"destination":{"host":"nemo-entity-store","port":{"number":8000}}}]` | The route for the virtual NeMo Entity Store service. |
| virtualService.main.entries.evaluator.corsPolicy | object | `{}` | The CORS policy for the virtual NeMo Evaluator service. |
| virtualService.main.entries.evaluator.match | list | `[{"uri":{"prefix":"/v1/evaluation"}},{"uri":{"prefix":"/v2/evaluation"}}]` | The match for the virtual NeMo Evaluator service. |
| virtualService.main.entries.evaluator.route | list | `[{"destination":{"host":"nemo-evaluator","port":{"number":7331}}}]` | The route for the virtual NeMo Evaluator service. |
| virtualService.main.entries.guardrails.corsPolicy | object | `{}` | The CORS policy for the virtual NeMo Guardrails service. |
| virtualService.main.entries.guardrails.match | list | `[{"uri":{"prefix":"/v1/guardrail"}}]` | The match for the virtual NeMo Guardrails service. |
| virtualService.main.entries.guardrails.route | list | `[{"destination":{"host":"nemo-guardrails","port":{"number":7331}}}]` | The route for the virtual NeMo Guardrails service. |
| virtualService.main.entries.intake.corsPolicy | object | `{}` | The CORS policy for the virtual NeMo Intake service. |
| virtualService.main.entries.intake.match | list | `[{"uri":{"prefix":"/v1/intake"}}]` | The match for the virtual NeMo Intake service. |
| virtualService.main.entries.intake.route | list | `[{"destination":{"host":"nemo-intake","port":{"number":8000}}}]` | The route for the virtual NeMo Intake service. |
| virtualService.main.entries.safe-synthesizer.corsPolicy | object | `{}` | The CORS policy for the virtual NeMo Safe Synthesizer service. |
| virtualService.main.entries.safe-synthesizer.match | list | `[{"uri":{"prefix":"/v1beta1/safe-synthesizer"}}]` | The match for the virtual NeMo Safe Synthesizer service. |
| virtualService.main.entries.safe-synthesizer.route | list | `[{"destination":{"host":"nemo-safe-synthesizer","port":{"number":8000}}}]` | The route for the virtual NeMo Safe Synthesizer service. |
| virtualService.main.gateways | list | `[]` | A list of gateways for the virtual service. |
| virtualService.main.hosts | list | `[]` | A list of hosts for the virtual service. |
| volcano.enabled | bool | `false` | Specifies whether to enable the default Volcano scheduler installation. To learn more, see [Volcano](https://docs.nvidia.com/nemo/microservices/latest/set-up/deploy-as-microservices/customizer.html#volcano). |