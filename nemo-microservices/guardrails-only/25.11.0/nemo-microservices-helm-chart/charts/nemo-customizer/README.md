# NeMo Customizer Microservice Helm Chart

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

For deployment guide, see [Admin Setup](https://docs.nvidia.com/nemo/microservices/latest/set-up/index.html) in the NeMo Microservices documentation.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| apiImage | object | This object has the following default values for the NeMo Customizer API only image. | Customizer API only image configuration. |
| apiImage.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for the NeMo Customizer API image. |
| apiImage.registry | string | `"nvcr.io"` | Registry for the NeMo Customizer API image. |
| apiImage.repository | string | `"nvidia/nemo-microservices/customizer-api"` | Repository for the NeMo Customizer API image. |
| awsDeploy | object | `{"efaDevicesPerGPU":4,"enabled":false}` | Deployment configurations for AWS |
| awsDeploy.efaDevicesPerGPU | int | `4` | EFA number of devices per GPU |
| awsDeploy.enabled | bool | `false` | Switch on if using AWS and kyverno is installed |
| azureDeploy | object | `{"enabled":false,"rdmaDeviceName":"rdma_shared_device_a","rdmaDevicesPerGPU":2}` | Deployment configurations for Azure |
| azureDeploy.enabled | bool | `false` | Switch on if using Azure and kyverno is installed |
| azureDeploy.rdmaDeviceName | string | `"rdma_shared_device_a"` | RDMA device name, examples include: - rdma_shared_device - rdma_shared_device_a - rdma_shared_device_b |
| azureDeploy.rdmaDevicesPerGPU | int | `2` | RDMA number of devices per GPU |
| customizationConfigTemplates | object | This object has the following default values. | List of customization configuration template supported by the Customizer. |
| customizationConfigTemplates.overrideExistingTemplates | bool | `true` | Whether to have this values file override templates in the database on application start |
| customizationConfigTemplates.templates | object | This object has the following default values. | The default templates to populate the database with |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100" | object | This object has the following default values for the Llama 3.2 3B Instruct model. | Llama 3.2 3B Instruct model configuration. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".max_seq_length | int | `4096` | The largest context used for training. Datasets are truncated based on the maximum sequence length. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".name | string | `"llama-3.2-3b-instruct@v1.0.0+A100"` | The name for training config template. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".namespace | string | `"meta"` | The namespace for training config template. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".prompt_template | string | `"{prompt} {completion}"` | Prompt template used to extract keys from the dataset. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".target | string | `"meta/llama-3.2-3b-instruct@2.0"` | The target to perform the customization on. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".training_options | list | `[{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"},{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":2,"num_nodes":1,"tensor_parallel_size":1,"training_type":"distillation"}]` | Resource configuration for each training option for the target model. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".training_options[0] | object | `{"finetuning_type":"lora","micro_batch_size":1,"num_gpus":1,"num_nodes":1,"tensor_parallel_size":1,"training_type":"sft"}` | Training method. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".training_options[0].finetuning_type | string | `"lora"` | The type of fine-tuning method. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".training_options[0].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".training_options[0].num_gpus | int | `1` | The number of GPUs per node to use for the specified training. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".training_options[0].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".training_options[0].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".training_options[1] | object | `{"finetuning_type":"all_weights","micro_batch_size":1,"num_gpus":2,"num_nodes":1,"tensor_parallel_size":1,"training_type":"distillation"}` | Training method.1 |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".training_options[1].finetuning_type | string | `"all_weights"` | The type of fine-tuning method. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".training_options[1].micro_batch_size | int | `1` | The number of training examples processed in parallel by each individual GPU. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".training_options[1].num_gpus | int | `2` | The number of GPUs per node to use for the specified training. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".training_options[1].num_nodes | int | `1` | The number of nodes to use for the specified training. |
| customizationConfigTemplates.templates."meta/llama-3.2-3b-instruct@v1.0.0+A100".training_options[1].tensor_parallel_size | int | `1` | The number of GPUs among which the model’s tensors are partitioned. |
| customizationTargets | object | This object has the following default values. | List of model configurations supported by the Customizer. |
| customizationTargets.hfTargetDownload.allowedHfOrgs | list | `[]` | List of allowed organizations for model downloads from Hugging Face. Empty list allows all organizations. Example: allowedHfOrgs:   - "nvidia" |
| customizationTargets.hfTargetDownload.enabled | bool | `false` | set this to true to allow model downloads from Hugging Face. If enabled=false, models are not allwed to be downloaded from any Hugging Face org and allowedHfOrgs is disregarded |
| customizationTargets.overrideExistingTargets | bool | `false` | Whether to have this values file override targets in the database on application start |
| customizationTargets.targets | object | This object has the following default values. | The default targets to populate the database with |
| customizationTargets.targets."meta/llama-3.2-1b@2.0" | object | This object has the following default values for the Llama 3.2 1B model. | Llama 3.2 1B target model configuration. |
| customizationTargets.targets."meta/llama-3.2-1b@2.0".base_model | string | `"meta/llama-3.2-1b"` | Mapping to the model name in NIM. Defaults to being the same as the the configuration entry namespace/name. |
| customizationTargets.targets."meta/llama-3.2-1b@2.0".enabled | bool | `false` | Whether to enable the model. |
| customizationTargets.targets."meta/llama-3.2-1b@2.0".model_path | string | `"llama32_1b_2_0"` | Path where model files are stored. |
| customizationTargets.targets."meta/llama-3.2-1b@2.0".model_uri | string | `"ngc://nvidia/nemo/llama-3_2-1b:2.0"` | NGC model URI for Llama 3.2 1B model. |
| customizationTargets.targets."meta/llama-3.2-1b@2.0".name | string | `"llama-3.2-1b@2.0"` | The name for target model. |
| customizationTargets.targets."meta/llama-3.2-1b@2.0".namespace | string | `"meta"` | The namespace for target model. |
| customizationTargets.targets."meta/llama-3.2-1b@2.0".num_parameters | int | `1000000000` | Number of model parameters. |
| customizationTargets.targets."meta/llama-3.2-1b@2.0".precision | string | `"bf16-mixed"` | Model precision format. |
| customizerConfig | object | This object has default values for the following fields. | Configuration for the NeMo Customizer microservice. |
| customizerConfig.entityStoreURL | string | `"http://nemo-gateway.nemo-gateway.svc.cluster.local:8000"` | URL for the NeMo Entity Store microservice. |
| customizerConfig.mlflowURL | string | `""` | URL for the MLflow tracking server. |
| customizerConfig.nemoDataStoreURL | string | `"http://nds-datastore-http.nds-v2.svc.cluster.local:3000"` | URL for the NeMo Data Store microservice. |
| customizerConfig.nodeSelectors | object | `{}` | Default node selectors on the customization job pods. Can be extended via customizationConfigTemplates.templates[i].pod_spec.nodeSelectors. |
| customizerConfig.openTelemetry | object | This object has the following default values for the OpenTelemetry settings. | OpenTelemetry settings. |
| customizerConfig.openTelemetry.enabled | bool | `true` | Whether to enable OpenTelemetry. |
| customizerConfig.openTelemetry.exporterOtlpEndpoint | string | `""` | Endpoint to access a custom OTLP collector listening on port 4317. Example: "http://$(HOST_IP):4317". |
| customizerConfig.openTelemetry.logsExporter | string | `"otlp"` | Sets the logs exporter type (otlp, console, none). |
| customizerConfig.openTelemetry.metricsExporter | string | `"otlp"` | Sets the metrics exporter type (otlp, console, none). |
| customizerConfig.openTelemetry.tracesExporter | string | `"otlp"` | Sets the traces exporter type (otlp, console, none). |
| customizerConfig.tolerations | list | `[]` | Default tolerations on the customization job pods. Can be extended via customizationConfigTemplates.templates[i].pod_spec.tolerations. |
| customizerConfig.training | object | This object has the following default values for the training configuration. | Training configuration for customization jobs. |
| customizerConfig.training.container_defaults | object | `{"env":null,"imagePullPolicy":"IfNotPresent"}` | Default container configuration for training jobs. |
| customizerConfig.training.container_defaults.env | string | `nil` | Environment variables for the training container. Cannot override env variables reserved by NeMo Customizer. |
| customizerConfig.training.poll_interval_seconds | int | `10` | Interval in seconds to poll for monitoring jobs. Defaults to 10s. poll_interval_seconds with a 30 second pad must be less than ttl_seconds_after_finished. |
| customizerConfig.training.pvc.name | string | `nil` | The name of a single PVC to be used for training. If null, create a separate PVC per training job for isolation. If provided, it will create this PVC. |
| customizerConfig.training.pvc.size | string | `"5Gi"` | Size of the training job PVC. |
| customizerConfig.training.pvc.storageClass | string | `"local-nfs"` | Storage class for the training job PVC. |
| customizerConfig.training.pvc.volumeAccessMode | string | `"ReadWriteMany"` | Volume access mode for the training job PVC. |
| customizerConfig.training.queue | string | `"default"` | Queue name used by the underlying scheduler of NemoTrainingJob. Maps to "resourceGroup" in NemoTrainingJob. |
| customizerConfig.training.ttl_seconds_after_finished | int | `3600` | Time to live in seconds after the training job pod completes. Defaults to 1h. Take precautions when setting ttl_seconds_after_finished to 0 which disables automatic clean up for jobs. When disabled, jobs will persist and hold on to resources like PVCs and will require manual or external clean up. ttl_seconds_after_finished must be greater than poll_interval_seconds with a 30 second pad. |
| customizerConfig.training.workspace_dir | string | `"/pvc/workspace"` | Directory path for training workspace. |
| customizerConfig.trainingNetworking | list | `[{"name":"NCCL_IB_SL","value":0},{"name":"NCCL_IB_TC","value":41},{"name":"NCCL_IB_QPS_PER_CONNECTION","value":4},{"name":"UCX_TLS","value":"TCP"},{"name":"UCX_NET_DEVICES","value":"eth0"},{"name":"HCOLL_ENABLE_MCAST_ALL","value":0},{"name":"NCCL_IB_GID_INDEX","value":3}]` | Network configuration for training jobs on Oracle Kubernetes Engine (OKE) on Oracle Cloud Infrastructure (OCI). |
| customizerConfig.wandb | object | `{"entity":null,"project":"nvidia-nemo-customizer"}` | Weights and Biases (WandB) Python SDK intialization configuration for logging and monitoring training jobs in WandB. |
| customizerConfig.wandb.entity | string | `nil` | Reference: https://docs.wandb.ai/ref/python/init/ |
| env | object | `{"JOB_CLEANUP_TTL_SEC":"3600","JOB_LOGS_POLLING_INTERVAL":"600","JOB_STATUS_POLLING_INTERVAL":"15","MAX_TRAINING_JOB_STATUS_FAILURES":"10","TRAINING_JOB_CREATION_FAILURE_SLEEP_INTERVAL":"15"}` | A map of environment variables to inject into the NeMo Customizer app container. Example:  `{HOST_IP:   valueFrom:     fieldRef:       fieldPath: status.hostIP OTEL_EXPORTER_OTLP_ENDPOINT: "http://$(HOST_IP):4317"}` |
| externalDatabase | object | This object has the following default values for the external PostgreSQL configuration. | External PostgreSQL configuration. |
| externalDatabase.database | string | `"finetuning"` | Name of the database to use. |
| externalDatabase.existingSecret | string | `""` | Name of an existing secret resource containing the database credentials. |
| externalDatabase.existingSecretPasswordKey | string | `""` | Name of an existing secret key containing the database credentials. |
| externalDatabase.host | string | `"localhost"` | External database host address. |
| externalDatabase.port | int | `5432` | External database port number. |
| externalDatabase.user | string | `"nemo"` | Non-root username for the NeMo Customizer microservice. |
| fullnameOverride | string | `""` | String to fully override the chart and release name on resulting objects when deployed. |
| gcpDeploy.enabled | bool | `false` | Switch on if using GCP and kyverno is installed |
| hfAPISecret | string | `nil` | The K8s Secret containing the HuggingFace API token. |
| hfAPISecretKey | string | `"HF_TOKEN"` | The key in the hfAPISecret containing the actual secret's value. Defaults to HF_TOKEN |
| image | object | This object has the following default values for the NeMo Customizer microservice image. | NeMo Customizer image that supports training and standalone mode. |
| image.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for the NeMo Customizer image. |
| image.registry | string | `"nvcr.io"` | Registry for the NeMo Customizer image. |
| image.repository | string | `"nvidia/nemo-microservices/customizer"` | Repository for the NeMo Customizer image. |
| imagePullSecrets | list | `[{"name":"nvcrimagepullsecret"}]` | Image pull secrets configuration. |
| ingress | object | This object has the following default values for the Ingress configuration. | Ingress configuration. |
| ingress.annotations | object | `{}` | Additional annotations for the Ingress resource. |
| ingress.className | string | `""` | Ingress class name. |
| ingress.enabled | bool | `false` | Whether to enable the ingress resource. |
| ingress.hostname | string | `""` | Hostname for the ingress resource. |
| ingress.hosts | list | [] | A list of maps, each containing the keys `host` and `paths` for the ingress resource. You must specify a list for configuring ingress for the microservice. |
| ingress.tls | list | `[]` | TLS configuration for the ingress resource. |
| livenessProbe.failureThreshold | int | `15` |  |
| livenessProbe.initialDelaySeconds | int | `30` |  |
| livenessProbe.timeoutSeconds | int | `15` |  |
| logging | object | `{"logHealthEndpoints":false,"logLevel":"INFO"}` | Logging configuration. |
| logging.logHealthEndpoints | bool | `false` | Enable logging for health endpoints. |
| logging.logLevel | string | `"INFO"` | Log level for the application. |
| modelDownloader | object | This object has the following default values for the model downloader. | Download models to PVC model cache configuration. |
| modelDownloader.securityContext | object | `{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}` | Security context for the model downloader. |
| modelDownloader.ttlSecondsAfterFinished | int | `7200` | Time to live in seconds after the job finishes. |
| modelsStorage | object | `{"accessModes":["ReadWriteMany"],"enabled":true,"size":"1Ti","storageClassName":""}` | Configure the PVC for models mount, where we store the parent/base models. |
| modelsStorage.accessModes | list | `["ReadWriteMany"]` | Access modes for the persistent volume. |
| modelsStorage.enabled | bool | `true` | Enable persistent volume for model storage. |
| modelsStorage.size | string | `"1Ti"` | Size of the persistent volume. |
| modelsStorage.storageClassName | string | `""` | Storage class name for the models PVC. Empty string uses the default storage class. |
| nameOverride | string | `""` | String to override chart name on resulting objects when deployed. |
| nemoDataStoreTools | object | This object has the following default values for the NeMo Data Store tools image. | Tools configuration for downloading and uploading entities to NeMo Data Store. |
| nemoDataStoreTools.imagePullSecret | string | `"nvcrimagepullsecret"` | Image pull secret for the NeMo Data Store tools image. |
| nemoDataStoreTools.registry | string | `"nvcr.io"` | Registry for the NeMo Data Store tools image. |
| nemoDataStoreTools.repository | string | `"nvidia/nemo-microservices/nds-v2-huggingface-cli"` | Repository for the NeMo Data Store tools image. |
| nemoDataStoreTools.tag | string | `""` | Tag for the NeMo Data Store tools image. |
| ngcAPISecret | string | `"ngc-api"` | Secret used for auto hydrating the model cache from NGC for enabled models. |
| ngcAPISecretKey | string | `"NGC_API_KEY"` | Key in the NGC API secret containing the API key. |
| ociDeploy.enabled | bool | `false` | Switch on if using OCI and kyverno is installed |
| ociDeploy.rdmaDevicesPerGPU | int | `2` | Number of RDMA networking resources to attach per node |
| opentelemetry-collector | object | This object has the following default values for the Open Telemetry Collector configuration. | Open Telemetry Collector configuration. |
| opentelemetry-collector.config | object | `{"exporters":{"debug":{"verbosity":"detailed"}},"extensions":{"health_check":{},"zpages":{"endpoint":"0.0.0.0:55679"}},"processors":{"batch":{}},"receivers":{"otlp":{"protocols":{"grpc":{},"http":{"cors":{"allowed_origins":["*"]}}}}},"service":{"extensions":["zpages","health_check"],"pipelines":{"logs":{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]},"metrics":{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]},"traces":{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]}}}}` | Base collector configuration for Open Telemetry Collector. |
| opentelemetry-collector.enabled | bool | `true` | Switch to enable or disable Open Telemetry Collector. |
| opentelemetry-collector.image.repository | string | `"otel/opentelemetry-collector-k8s"` | Repository for Open Telemetry Collector image. |
| opentelemetry-collector.image.tag | string | `"0.102.1"` | Overrides the image tag whose default is the chart appVersion. |
| opentelemetry-collector.mode | string | `"deployment"` | Deployment mode for Open Telemetry Collector. Valid values are "daemonset", "deployment", and "statefulset". |
| postgresql | object | This object has the following default values for the PostgreSQL configuration. | PostgreSQL configuration for the NeMo Customizer microservice. |
| postgresql.architecture | string | `"standalone"` | PostgreSQL architecture (`standalone` or `replication`). |
| postgresql.auth.database | string | `"finetuning"` | Name for a custom database to create. |
| postgresql.auth.enablePostgresUser | bool | `true` | Whether to assign a password to the "postgres" admin user. Otherwise, remote access will be blocked for this user. |
| postgresql.auth.existingSecret | string | `""` | Name of existing secret to use for PostgreSQL credentials. |
| postgresql.auth.password | string | `"nemo"` | Password for the custom user to create. |
| postgresql.auth.username | string | `"nemo"` | Name for a custom user to create. |
| postgresql.enabled | bool | `true` | Whether to enable or disable the PostgreSQL helm chart. |
| readinessProbe.failureThreshold | int | `15` |  |
| readinessProbe.initialDelaySeconds | int | `30` |  |
| readinessProbe.timeoutSeconds | int | `15` |  |
| replicaCount | int | `1` | Number of replicas to deploy. |
| service | object | `{"internalPort":9009,"port":8000,"type":"ClusterIP"}` | Service configuration. |
| service.internalPort | int | `9009` | Internal port for the service. |
| service.port | int | `8000` | External port for the service. |
| service.type | string | `"ClusterIP"` | Type of Kubernetes service to create. |
| serviceAccount | object | `{"annotations":{},"automountServiceAccountToken":true,"create":true,"name":""}` | Service account configuration. |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account. |
| serviceAccount.automountServiceAccountToken | bool | `true` | Automatically mount a ServiceAccount's API credentials. |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created. |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated. |
| useRunAIExecutor | bool | `false` | Enable or disable RunAI executor. |
| wandb | object | This object has the following default values for the WandB configuration. | WandB configuration. |
| wandb.existingSecret | string | `""` | Name of an existing Kubernetes secret resource for the WandB encryption secret. |
| wandb.existingSecretKey | string | `""` | Name of the key in the existing WandB secret containing the secret value. The secret value must be exactly 32 alphanumeric characters: ^[a-zA-Z0-9]{32}$ |
| wandb.secretValue | string | `"ec60d96b639764ccf9859bc10d4363d1"` | WandB secret value. Must contain exactly 32 alphanumeric characters. Creates a new Kubernetes secret named "wandb-secret" with key-value pair "encryption_key=<wandb.secretValue>". Ignored if wandb.existingSecret is set. |