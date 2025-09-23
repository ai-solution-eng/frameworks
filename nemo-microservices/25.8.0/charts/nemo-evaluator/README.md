# NeMo Evaluator Microservice Helm Chart

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

For deployment guide, see [Admin Setup](https://docs.nvidia.com/nemo/microservices/latest/set-up/index.html) in the NeMo Microservices documentation.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity for the NeMo Evaluator microservice. |
| autoscaling.enabled | bool | `false` | Whether to enable autoscaling for the NeMo Evaluator microservice. |
| autoscaling.maxReplicas | int | `100` | The maximum number of replicas for the NeMo Evaluator microservice. |
| autoscaling.minReplicas | int | `1` | The minimum number of replicas for the NeMo Evaluator microservice. |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | The target CPU utilization percentage for the NeMo Evaluator microservice. |
| dbMigration.resources.limits.cpu | int | `1` | The CPU resource limit for the DB Migration service. |
| dbMigration.resources.limits.memory | string | `"1Gi"` | The memory resource limit for the DB Migration service. |
| env | object | `{}` | Additional environment variables to pass to containers. The format is `NAME: value` or `NAME: valueFrom: {object}`. |
| evalFactory.job.restartPolicy | string | `"Never"` | Restart policy for the pods of the core eval jobs. |
| evalFactory.job.ttlSecondsAfterFinished | int | `172800` | Time-to-live after completion for the core eval jobs. |
| evaluationImages | object | `{}` |  |
| evaluationJob.monitoringInterval | int | `5` | Monitoring interval checking evaluation job status (in seconds). |
| evaluationJob.monitoringTimeout | int | `36000` | Monitoring timeout for checking evaluation job status (in seconds). |
| evaluator | object | `{"host":"0.0.0.0"}` | Host for the NeMo Evaluator microservice. |
| external.dataStore.endpoint | string | `"http://nemo-data-store:3000/v1/hf"` | The external URL of the NeMo Data Store microservice. |
| external.entityStore.endpoint | string | `"http://nemo-entity-store:8000"` | The external URL of the NeMo Entity Store microservice. |
| external.milvus.endpoint | string | `""` | The external URL of your own Milvus service. |
| external.nimProxy.endpoint | string | `"http://nemo-nim-proxy:8000"` | The external URL of the NeMo Nim Proxy microservice. |
| externalDatabase.database | string | `"evaluation"` | The database for the external database. |
| externalDatabase.existingSecret | string | `""` | The existing secret for the external database. |
| externalDatabase.existingSecretPasswordKey | string | `""` | The existing secret password key for the external database. |
| externalDatabase.host | string | `"localhost"` | The host for an external database. |
| externalDatabase.port | int | `5432` | The port for the external database. |
| externalDatabase.uriSecret | object | `{"key":"","name":""}` | The name for the external database secret. |
| externalDatabase.user | string | `"nemo"` | The user for the external database. |
| fullnameOverride | string | `""` | The full name override for the NeMo Evaluator microservice. |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy for the NeMo Evaluator microservice image. |
| image.repository | string | `"nvcr.io/nvidia/nemo-microservices/evaluator"` | The repository where the NeMo Evaluator microservice image is located. |
| image.tag | string | `""` | Specifies the version of the NeMo Evaluator microservice image. |
| imagePullSecrets | list | `[{"name":"nvcrimagepullsecret"}]` | The image pull secrets for accessing the container registry. |
| ingress.annotations | object | `{}` | Annotations for the ingress resource. |
| ingress.className | string | `""` | The ingress class name. |
| ingress.enabled | bool | `false` | Whether to enable the ingress for the NeMo Evaluator service. |
| ingress.hosts | list | [] | A list of maps, each containing the keys `host` and `paths` for the ingress resource. Specify hosts and paths as a list to configure ingress for the NeMo Evaluator service. |
| ingress.tls | list | `[]` | TLS configuration for the ingress resource. |
| livenessProbe.httpGet | object | `{"path":"/health","port":"http"}` | Configures the liveness probe for the NeMo Evaluator microservice. The liveness probe checks if the container is running. The probe sends an HTTP GET request to the `/health` endpoint on the container's `http` port. |
| logLevel | string | `"INFO"` | Log level for the NeMo Evaluator microservice. |
| milvus.cluster.enabled | bool | `false` | Whether to enable the default Milvus cluster. |
| milvus.enabled | bool | `true` | Whether to enable the default Milvus service. Enable this for RAG and Retriever pipelines. For more information about setting up a Milvus service, see the [Milvus setup guide](https://docs.nvidia.com/nemo/microservices/latest/set-up/deploy-as-microservices/evaluator.html#configure-milvus). |
| milvus.etcd.enabled | bool | `false` | Whether to enable the etcd for the default Milvus service. |
| milvus.extraConfigFiles | object | `{"user.yaml":"etcd:\n  use:\n    embed: true\n  data:\n    dir: /var/lib/milvus/etcd\ncommon:\n  storageType: local\n"}` | Extra configuration files for the default Milvus service. |
| milvus.minio.enabled | bool | `false` | Whether to enable the Minio for the default Milvus service. |
| milvus.minio.gcsgateway | object | `{"enabled":false}` | Whether to enable gcsgateway in Minio service |
| milvus.minio.tls | object | `{"enabled":false}` | Whether to enable the TLS for the Minio service. |
| milvus.pulsar.enabled | bool | `false` | Whether to enable the Pulsar for the default Milvus service. |
| milvus.service.port | int | `19121` | The service port for the default Milvus service. |
| milvus.serviceName | string | `"milvus"` | The service name for the default Milvus service. |
| milvus.standalone.extraEnv | list | `[{"name":"LOG_LEVEL","value":"error"}]` | Extra environment variables for the default Milvus service. |
| milvus.standalone.persistence | object | `{"enabled":true,"persistentVolumeClaim":{"size":"50Gi","storageClass":""}}` | Whether to enable the standalone for the default Milvus service. |
| milvus.standalone.persistence.enabled | bool | `true` | Whether to enable the persistence for the default Milvus service. |
| milvus.standalone.persistence.persistentVolumeClaim | object | `{"size":"50Gi","storageClass":""}` | The persistent volume claim for the default Milvus service. |
| milvus.standalone.persistence.persistentVolumeClaim.size | string | `"50Gi"` | The size for the persistent volume claim for the default Milvus service. |
| milvus.standalone.persistence.persistentVolumeClaim.storageClass | string | `""` | The storage class for the persistent volume claim for the default Milvus service. |
| nameOverride | string | `""` | The name override for the NeMo Evaluator microservice. |
| nodeSelector | object | `{}` | Node selector for the NeMo Evaluator microservice. |
| opentelemetry-collector.config.exporters.debug | object | `{"verbosity":"detailed"}` | Debugging verbosity for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.exporters.zipkin | object | `{"endpoint":"http://zipkin:9411/api/v2/spans"}` | The Zipkin exporter for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.processors.batch | object | `{}` | The batch processor for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.processors.tail_sampling | object | `{"policies":[{"name":"drop_noisy_traces_url","string_attribute":{"enabled_regex_matching":true,"invert_match":true,"key":"http.target","values":["\\/health"]},"type":"string_attribute"}]}` | The tail sampling processor for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.processors.tail_sampling.policies | list | `[{"name":"drop_noisy_traces_url","string_attribute":{"enabled_regex_matching":true,"invert_match":true,"key":"http.target","values":["\\/health"]},"type":"string_attribute"}]` | The policies for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.processors.transform | object | `{"trace_statements":[{"context":"span","statements":["set(status.code, 1) where attributes[\"http.path\"] == \"/health\""]}]}` | The transform processor configuration for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.processors.transform.trace_statements | list | `[{"context":"span","statements":["set(status.code, 1) where attributes[\"http.path\"] == \"/health\""]}]` | The trace statements for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.receivers.otlp | object | `{"protocols":{"grpc":null,"http":{"cors":{"allowed_origins":["*"]}}}}` | The OTLP receiver for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.service.pipelines.logs | object | `{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]}` | The logs pipeline for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.service.pipelines.logs.exporters | list | `["debug"]` | The exporters for the logs pipeline for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.service.pipelines.logs.processors | list | `["batch"]` | The processors for the logs pipeline for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.service.pipelines.logs.receivers | list | `["otlp"]` | The receivers for the logs pipeline for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.service.pipelines.metrics | object | `{"exporters":["debug"],"processors":["batch"],"receivers":["otlp"]}` | The metrics pipeline for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.service.pipelines.metrics.exporters | list | `["debug"]` | The exporters for the metrics pipeline for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.service.pipelines.metrics.processors | list | `["batch"]` | The processors for the metrics pipeline for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.service.pipelines.metrics.receivers | list | `["otlp"]` | The receivers for the metrics pipeline for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.service.pipelines.traces | object | `{"exporters":["debug","zipkin"],"processors":["tail_sampling","transform"],"receivers":["otlp"]}` | The traces pipeline for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.service.pipelines.traces.exporters | list | `["debug","zipkin"]` | The exporters for the traces pipeline for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.service.pipelines.traces.processors | list | `["tail_sampling","transform"]` | The processors for the traces pipeline for the OpenTelemetry Collector service. |
| opentelemetry-collector.config.service.pipelines.traces.receivers | list | `["otlp"]` | The receivers for the traces pipeline for the OpenTelemetry Collector service. |
| opentelemetry-collector.enabled | bool | `false` | Whether to enable the OpenTelemetry Collector service. |
| opentelemetry-collector.mode | string | `"deployment"` | The mode for the OpenTelemetry Collector service. |
| otelEnvVars | object | `{"OTEL_LOGS_EXPORTER":"otlp","OTEL_METRICS_EXPORTER":"otlp","OTEL_PROPAGATORS":"tracecontext,baggage","OTEL_PYTHON_EXCLUDED_URLS":"health","OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED":"true","OTEL_RESOURCE_ATTRIBUTES":"deployment.environment=$(NAMESPACE)","OTEL_SERVICE_NAME":"nemo-evaluator","OTEL_TRACES_EXPORTER":"otlp"}` | OpenTelemetry environment configuration variables for the NeMo Evaluator microservice. |
| otelExporterEnabled | bool | `false` | Whether to enable the OpenTelemetry exporter for the NeMo Evaluator microservice. |
| podAnnotations | object | `{}` | Annotations for the service pod. |
| podLabels | object | `{}` | Labels for the service pod. |
| podSecurityContext | object | `{}` | Security context for the service pod. |
| postgresql.architecture | string | `"standalone"` | The architecture for the default PostgreSQL service. |
| postgresql.auth.database | string | `"evaluation"` | The database for the PostgreSQL service. |
| postgresql.auth.enablePostgresUser | bool | `true` | Whether to enable the PostgreSQL user. |
| postgresql.auth.existingSecret | string | `""` | The existing secret you want to use for the PostgreSQL service. |
| postgresql.auth.password | string | `"nemo"` | The password for the PostgreSQL service. |
| postgresql.auth.username | string | `"nemo"` | The username for the PostgreSQL service. |
| postgresql.enabled | bool | `true` | Whether to enable the default PostgreSQL service. For more information about setting up a PostgreSQL service, see the [PostgreSQL setup guide](https://docs.nvidia.com/nemo/microservices/latest/set-up/manage-storage/database/postgres.html). |
| postgresql.global.size | string | `"10Gi"` | The storage size for the default PostgreSQL service. |
| postgresql.global.storageClass | string | `""` | The storage class for the default PostgreSQL service. |
| postgresql.primary.service.ports.postgresql | int | `5432` | The primary service port for the PostgreSQL service. |
| readinessProbe.httpGet | object | `{"path":"/health","port":"http"}` | Configures the readiness probe for the NeMo Evaluator microservice. The readiness probe checks if the container is ready to receive traffic. The probe sends an HTTP GET request to the `/health` endpoint on the container's `http` port. |
| replicaCount | int | `1` | The number of replicas for the NeMo Evaluator microservice. |
| resources | object | `{}` | Resources for the NeMo Evaluator service. |
| securityContext | object | `{}` | Security context for the service container. |
| service.internalPort | int | `7332` | Internal port of the NeMo Evaluator microservice. |
| service.port | int | `7331` | External port of the NeMo Evaluator microservice. |
| service.type | string | `"ClusterIP"` | The type of the NeMo Evaluator microservice. |
| serviceAccount.annotations | object | `{}` | Annotations for the service account. |
| serviceAccount.automount | bool | `true` | Whether to automatically mount the service account token. |
| serviceAccount.create | bool | `true` | Whether to create a service account for the NeMo Evaluator microservice. |
| serviceAccount.name | string | `""` | A name for the service account. |
| tolerations | list | `[]` | Tolerations for the NeMo Evaluator microservice. |
| volumeMounts | list | `[]` | Volume mounts for the NeMo Evaluator microservice. |
| volumes | list | `[]` | Volumes for the NeMo Evaluator microservice. |
| zipkin.enabled | bool | `false` | Whether to enable the default Zipkin service. |
| zipkin.fullnameOverride | string | `"zipkin"` | The full name override for the default Zipkin service. |