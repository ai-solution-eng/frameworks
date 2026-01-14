# NeMo Data Store Microservice Helm Chart

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

For deployment guide, see [Admin Setup](https://docs.nvidia.com/nemo/microservices/latest/set-up/index.html) in the NeMo Microservices documentation.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| additionalConfigFromEnvs | list | `[]` | Additional configuration sources from environment variables. |
| additionalConfigSources | list | `[]` | Additional configuration from secret or configmap. |
| admin | object | `{"email":"datastore@local.domain","existingSecret":null,"password":"s3aJPHD9!bt6d0I","username":"datastore_admin"}` | Admin user configuration settings. |
| admin.email | string | `"datastore@local.domain"` | Email for the NeMo Data Store admin user. |
| admin.existingSecret | string | `nil` | Use an existing secret to store admin user credentials. For example, `datastore-admin-secret`. |
| admin.password | string | `"s3aJPHD9!bt6d0I"` | Password for the NeMo Data Store admin user. |
| admin.username | string | `"datastore_admin"` | Username for the NeMo Data Store admin user. |
| affinity | object | `{}` | Affinity configuration for the deployment. |
| checkDeprecation | bool | `true` | Set to false to skip the basic validation check. |
| clusterDomain | string | `"cluster.local"` | Kubernetes cluster domain name. |
| config | object | This object has the following default values for the NeMo Data Store configuration. | NeMo Data Store configuration. |
| config."cron.GIT_GC_REPOS".enabled | bool | `false` | Enable git garbage collection. |
| config.APP_NAME | string | `"Datastore"` | Application name. |
| config.RUN_MODE | string | `"prod"` | Runtime mode (prod/dev). |
| config.cache.ADAPTER | string | `"memory"` | Cache adapter type. |
| config.database.DB_TYPE | string | `"postgres"` | Database type. |
| config.lfs.STORAGE_TYPE | string | `"local"` | Storage type for LFS (local/s3). |
| config.queue.TYPE | string | `"dummy"` | Queue type. |
| config.server.HTTP_PORT | int | `3000` | HTTP port for web interface. |
| config.server.LFS_START_SERVER | bool | `true` | Enable LFS server. |
| config.server.START_SSH_SERVER | bool | `false` | Enable SSH server. |
| config.session.PROVIDER | string | `"memory"` | Session provider type. |
| containerSecurityContext | object | `{}` | Container-level security context settings |
| demo | object | This object has the following default values for the demo parameters. | Parameters for the demo mode. |
| demo.enabled | bool | `false` | Enable or disable the demo mode. |
| demo.ngcApiKey | string | `""` | NGC API key. |
| demo.ngcImagePullSecret | string | `"ngc-image-pull-secret"` | Name of the secret containing the NGC image pull secret. |
| deployment | object | `{"annotations":{},"labels":{},"terminationGracePeriodSeconds":60}` | Deployment configuration. |
| deployment.annotations | object | `{}` | Annotations for the Datastore deployment to be created. |
| deployment.labels | object | `{}` | Labels for the deployment. |
| deployment.terminationGracePeriodSeconds | int | `60` | How long to wait until forcefully kill the pod. |
| dnsConfig | object | `{}` | dnsConfig configuration for the deployment. |
| env | object | `{}` | Additional environment variables to pass to containers. This is an object formatted like NAME: value or NAME: valueFrom: {object}. |
| external | object | `{"domain":"","rootUrl":""}` | External URL configuration for the NeMo Data Store microservice. |
| external.domain | string | `""` | The external URL's domain name. |
| external.rootUrl | string | `""` | The external URL where users will access the NeMo Data Store microservice. |
| externalDatabase | object | This object has the following default values for the external PostgreSQL configuration. | External PostgreSQL configuration settings. These values are only used when postgresql.enabled is set to false. |
| externalDatabase.database | string | `""` | Datastore database name. |
| externalDatabase.existingSecret | string | `""` | Name of an existing secret resource containing the database credentials. |
| externalDatabase.existingSecretPasswordKey | string | `""` | Name of an existing secret key containing the database credentials. |
| externalDatabase.host | string | `""` | External database host address. |
| externalDatabase.port | int | `5432` | External database port number. |
| externalDatabase.sslMode | string | `"disable"` | SSL mode for external database connection. |
| externalDatabase.user | string | `""` | Non-root username for Datastore service. |
| extraContainerVolumeMounts | list | `[]` | Mounts that are only mapped into the Datastore runtime/main container, to e.g. override custom templates. |
| extraDeploy | list | `[]` | Array of extra objects to deploy with the release. |
| extraInitVolumeMounts | list | `[]` | Mounts that are only mapped into the init-containers. Can be used for additional preconfiguration. |
| extraVolumeMounts | list | `[]` | **DEPRECATED** Additional volume mounts for init containers and the Datastore main container. This value is split into the following two variables: `extraContainerVolumeMounts` and `extraInitVolumeMounts`. |
| extraVolumes | list | `[]` | Additional volumes to mount to the Datastore deployment. |
| global | object | `{"hostAliases":[],"imagePullSecrets":[],"imageRegistry":"","storageClass":""}` | Global parameters to override the same settings in all subcharts of this Helm chart. |
| global.hostAliases | list | `[]` | Global host aliases which will be added to the pod's hosts files. |
| global.imagePullSecrets | list | `[]` | Global image pull secrets. |
| global.imageRegistry | string | `""` | Global image registry. |
| global.storageClass | string | `""` | Global storage class that applies to persistent volumes. |
| image | object | This object has the following default values for the image configuration. | Container image configuration settings |
| image.digest | string | `""` | The image digest to use for more precise version control. |
| image.fullOverride | string | `""` | Complete override string for the image specification. |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy determining when to pull new images. |
| image.registry | string | `"nvcr.io"` | The registry where the NeMo Data Store image is located. |
| image.repository | string | `"nvidia/nemo-microservices/datastore"` | The repository path of the NeMo Data Store image. |
| image.rootless | bool | `true` | Whether to run the container with rootless security context. |
| image.tag | string | `""` | The image tag to use. |
| imagePullSecrets | list | `[{"name":"nvcrimagepullsecret"}]` | Configuration for image pull secrets to access private registries. |
| imagePullSecrets[0] | object | `{"name":"nvcrimagepullsecret"}` | Name of the secret containing registry credentials. |
| initContainers | object | `{"resources":{"limits":{},"requests":{"cpu":"100m","memory":"128Mi"}}}` | Kubernetes resource limits for init containers. |
| initContainers.resources.limits | object | `{}` | Kubernetes resource limits for init containers. |
| initContainers.resources.requests | object | `{"cpu":"100m","memory":"128Mi"}` | Kubernetes cpu resource limits for init containers. |
| initPreScript | string | `""` | Init container Bash shell scripts. For example, to mount a client certificate when connecting to an external Postgres server, you might add commands similar to the following:   `mkdir -p /data/git/.postgresql`,   `cp /pg-ssl/* /data/git/.postgresql/`,   `chown -R git:git /data/git/.postgresql/`,   `chmod 400 /data/git/.postgresql/postgresql.key` |
| jwtSecret | object | This object has the following default values for the JWT secret configuration. | JWT secret configuration settings. |
| jwtSecret.existingSecret | string | `""` | Name of an existing secret resource containing the LFS JWT secret. |
| jwtSecret.existingSecretKey | string | `""` | Key in existing secret containing the LFS JWT secret. |
| jwtSecret.value | string | `""` | User specified LFS JWT secret - this will be stored in a secret. |
| ldap | list | `[]` | LDAP configuration. |
| livenessProbe | object | This object has the following default values for the liveness probe configuration. | Liveness probe configuration. |
| livenessProbe.enabled | bool | `true` | Enable liveness probe. |
| livenessProbe.failureThreshold | int | `20` | Failure threshold for liveness probe. |
| livenessProbe.httpGet.path | string | `"/v1/health"` | HTTP path for liveness probe. |
| livenessProbe.httpGet.port | string | `"http"` | Port for liveness probe. |
| livenessProbe.initialDelaySeconds | int | `10` | Initial delay before liveness probe is initiated. |
| livenessProbe.periodSeconds | int | `30` | Period for liveness probe. |
| livenessProbe.successThreshold | int | `1` | Success threshold for liveness probe. |
| livenessProbe.timeoutSeconds | int | `5` | Timeout for liveness probe. |
| metrics.enabled | bool | `false` | Enable NeMo Data Store metrics. Also requires setting env variable GITEA__metrics__ENABLED: "true" |
| metrics.serviceMonitor.enabled | bool | `false` | Enable NeMo Data Store metrics service monitor. |
| nodeSelector | object | `{}` | NodeSelector configuration for the deployment. |
| oauth | list | `[]` | OAuth configuration. |
| objectStore | object | This object has the following default values for the object store configuration. | Object Store configuration settings for accessing external Object Storage. |
| objectStore.accessKey | string | `""` | Access key credential for object storage authentication. |
| objectStore.accessSecret | string | `""` | Secret key credential for object storage authentication. |
| objectStore.bucketName | string | `"datastore"` | Name of the bucket to use for object storage. |
| objectStore.enabled | bool | `false` | Enable or disable object storage integration. |
| objectStore.endpoint | string | `""` | Object storage service endpoint URL. |
| objectStore.existingSecret | string | `""` | Name of existing Kubernetes secret containing object storage credentials. |
| objectStore.existingSecretAccessKey | string | `""` | Key in existing secret that contains the access key. |
| objectStore.existingSecretAccessSecret | string | `""` | Key in existing secret that contains the secret key. |
| objectStore.region | string | `""` | Geographic region for the object storage service. |
| objectStore.ssl | bool | `false` | Enable or disable SSL/TLS for object storage connections. |
| persistence | object | This object has the following default values for the persistence volume configuration. | Persistence volume configuration. |
| persistence.accessModes | list | `["ReadWriteOnce"]` | Access modes for the persistent volume. |
| persistence.annotations | object | `{"helm.sh/resource-policy":"keep"}` | Annotations for the persistence volume claim. |
| persistence.claimName | string | `"datastore-shared-storage"` | Name of the persistent volume claim. You can use an existing claim to store repository information. |
| persistence.create | bool | `true` | Whether to create the persistent volume claim for shared storage. |
| persistence.enabled | bool | `true` | Whether to enable persistent volume. |
| persistence.labels | object | `{}` | Labels for the persistence volume claim. |
| persistence.mount | bool | `true` | Whether to mount the persistent volume claim. |
| persistence.size | string | `"5Gi"` | Size of the persistent volume. |
| persistence.storageClass | string | `nil` | Name of the storage class to use. |
| persistence.subPath | string | `nil` | Subdirectory of the volume to mount at. |
| persistence.volumeName | string | `""` | Name of persistent volume in PVC. |
| podAnnotations | object | `{}` | Annotations for the Datastore pod. |
| podDisruptionBudget | object | `{}` | Pod disruption budget configuration. |
| podSecurityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"}` | Pod-level security context settings |
| podSecurityContext.fsGroup | int | `1000` | The file system group ID to use for all containers. |
| podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` | Set the permission change policy for mounted PVCs. |
| postgresql-ha | object | This object has the following default values for the PostgreSQL HA configuration. | PostgreSQL high availability (HA) configuration. |
| postgresql-ha.enabled | bool | `false` | Enable PostgreSQL HA. If enabled, configures PostgreSQL HA using the [bitnami/postgresql-ha](https://github.com/bitnami/charts/tree/main/bitnami/postgresql-ha) chart. |
| postgresql-ha.global.postgresql.database | string | `"datastore"` | Global PostgreSQL database name. |
| postgresql-ha.global.postgresql.password | string | `"datastore"` | Global password for the `datastore` user. |
| postgresql-ha.global.postgresql.username | string | `"datastore"` | Global username for the `datastore` user. |
| postgresql-ha.pgpool.adminPassword | string | `"changeme3"` | Pgpool admin password. |
| postgresql-ha.postgresql.password | string | `"changeme4"` | Password for the `datastore` user. |
| postgresql-ha.postgresql.postgresPassword | string | `"changeme1"` | Postgres password for the `datastore` user. |
| postgresql-ha.postgresql.repmgrPassword | string | `"changeme2"` | Repmgr password for the `datastore` user. |
| postgresql-ha.primary.persistence | object | `{"size":"10Gi"}` | PVC storage request for PostgreSQL HA volume. |
| postgresql-ha.service.ports | object | `{"postgresql":5432}` | PostgreSQL service port. |
| postgresql.enabled | bool | `true` | Enable or disable the built-in PostgreSQL database. |
| postgresql.global.postgresql.auth.database | string | `"datastore"` | Name of the database to create. |
| postgresql.global.postgresql.auth.password | string | `"datastore"` | Password for the datastore database user. |
| postgresql.global.postgresql.auth.username | string | `"datastore"` | Username for the database user. |
| postgresql.global.postgresql.service.ports.postgresql | int | `5432` | Port number for PostgreSQL service. |
| postgresql.primary.persistence.size | string | `"1Gi"` | Storage size request for the PostgreSQL persistent volume. |
| priorityClassName | string | `""` | priorityClassName configuration for the deployment. |
| readinessProbe | object | This object has the following default values for the readiness probe configuration. | Readiness probe configuration. |
| readinessProbe.enabled | bool | `true` | Enable readiness probe. |
| readinessProbe.failureThreshold | int | `40` | Failure threshold for readiness probe. |
| readinessProbe.httpGet.path | string | `"/v1/health"` | HTTP path for readiness probe. |
| readinessProbe.httpGet.port | string | `"http"` | Port for readiness probe. |
| readinessProbe.initialDelaySeconds | int | `30` | Initial delay before readiness probe is initiated. |
| readinessProbe.periodSeconds | int | `20` | Period for readiness probe. |
| readinessProbe.successThreshold | int | `1` | Success threshold for readiness probe. |
| readinessProbe.timeoutSeconds | int | `30` | Timeout for readiness probe. |
| redis-cluster | object | This object has the following default values for the Redis cluster configuration. | Redis cluster configuration. |
| redis-cluster.cluster | object | `{"nodes":3,"replicas":0}` | Number of redis cluster master nodes. |
| redis-cluster.enabled | bool | `false` | Enable Redis cluster. |
| redis-cluster.usePassword | bool | `false` | Whether to use password authentication. |
| replicaCount | int | `1` | Number of replicas for the deployment. |
| resources | object | `{}` | Kubernetes deployment resources configuration. It is recommended to not specify default resources and to leave this as a conscious choice. This also increases chances that the chart will run on environments with little resources, such as minikube. If you want to specify resources, use the following example, adjust the values as necessary, and remove the empty curly braces `{}`. `limits:   cpu: 100m   memory: 128Mi requests:   cpu: 100m   memory: 128Mi` |
| schedulerName | string | `""` | The name of the alternate scheduler to use. For more information, see [Configure Multiple Schedulers](https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/). |
| securityContext | object | `{}` | **DEPRECATED** Run init and NeMo Data Store containers as a specific securityContext. The securityContext variable has been split two: `containerSecurityContext` and `podSecurityContext`. |
| serveDirect | bool | `true` | Whether to serve traffic directly from an object storage service. |
| service | object | This object has the following default values for the service configuration. | Service configuration for exposing the application. |
| service.http | object | `{"annotations":{},"clusterIP":"","externalIPs":null,"externalTrafficPolicy":null,"ipFamilies":null,"ipFamilyPolicy":null,"labels":{},"loadBalancerIP":null,"loadBalancerSourceRanges":[],"nodePort":null,"port":3000,"type":"ClusterIP"}` | HTTP service configuration. |
| service.http.annotations | object | `{}` | Additional annotations for the HTTP service |
| service.http.clusterIP | string | `""` | The cluster IP address to assign to the service. |
| service.http.externalIPs | string | `nil` | List of external IP addresses to assign to the service |
| service.http.externalTrafficPolicy | string | `nil` | External traffic policy for controlling source IP preservation |
| service.http.ipFamilies | string | `nil` | List of IP families to use for the service |
| service.http.ipFamilyPolicy | string | `nil` | IP family policy for dual-stack support |
| service.http.labels | object | `{}` | Additional labels for the HTTP service |
| service.http.loadBalancerIP | string | `nil` | The static IP address for LoadBalancer service type. |
| service.http.loadBalancerSourceRanges | list | `[]` | List of CIDR ranges allowed to access the LoadBalancer |
| service.http.nodePort | string | `nil` | The node port number when using NodePort service type |
| service.http.port | int | `3000` | The port number to expose for HTTP traffic. |
| service.http.type | string | `"ClusterIP"` | The Kubernetes service type to create for HTTP traffic. |
| service.ssh | object | This object has the following default values for the SSH service configuration. | SSH service configuration. |
| service.ssh.annotations | object | `{}` | Additional annotations for the SSH service. |
| service.ssh.clusterIP | string | `"None"` | The cluster IP address to assign to the service. |
| service.ssh.enabled | bool | `false` | Whether to enable SSH service. |
| service.ssh.externalIPs | string | `nil` | List of external IP addresses to assign to the service. |
| service.ssh.externalTrafficPolicy | string | `nil` | The external traffic policy for controlling source IP preservation. |
| service.ssh.hostPort | string | `nil` | The host port number when using HostPort service type. |
| service.ssh.ipFamilies | string | `nil` | List of IP families to use for the service. |
| service.ssh.ipFamilyPolicy | string | `nil` | IP family policy for dual-stack support. |
| service.ssh.labels | object | `{}` | Additional labels for the SSH service. |
| service.ssh.loadBalancerIP | string | `nil` | The static IP address for LoadBalancer service type. |
| service.ssh.loadBalancerSourceRanges | list | `[]` | List of CIDR ranges allowed to access the LoadBalancer. |
| service.ssh.nodePort | string | `nil` | The node port number when using NodePort service type. |
| service.ssh.port | int | `22` | The port number to expose for SSH traffic. |
| service.ssh.type | string | `"ClusterIP"` | The Kubernetes service type to create for SSH traffic. |
| serviceAccount | object | `{"annotations":{},"automountServiceAccountToken":false,"create":false,"imagePullSecrets":[],"labels":{},"name":""}` | Service account configuration. |
| serviceAccount.annotations | object | `{}` | Custom annotations for the service account. |
| serviceAccount.automountServiceAccountToken | bool | `false` | Enable/disable auto mounting of the service account token. |
| serviceAccount.create | bool | `false` | Whether to create a service account. |
| serviceAccount.imagePullSecrets | list | `[]` | Image pull secrets, available to the service account. To add a list of image pull secrets, remove `[]`use the following format: - name: private-registry-access. |
| serviceAccount.labels | object | `{}` | Custom labels for the service account. |
| serviceAccount.name | string | `""` | Name of the created service account, defaults to release name. Can also link to an externally provided service account that should be used. |
| signing | object | `{"enabled":false,"existingSecret":"","gpgHome":"/data/git/.gnupg","privateKey":""}` | Signing configuration. |
| signing.enabled | bool | `false` | Enable commit/action signing. |
| signing.existingSecret | string | `""` | Use an existing secret to store the value of `signing.privateKey`. |
| signing.gpgHome | string | `"/data/git/.gnupg"` | GPG home directory. |
| signing.privateKey | string | `""` | Inline private GPG key for signed NeMo Data Store actions. |
| ssh | object | `{"logLevel":"INFO"}` | Configure OpenSSH's log level. Only available for root-based Datastore image. |
| startupProbe | object | This object has the following default values for the start-up probe configuration. | Start-up probe configuration. |
| startupProbe.enabled | bool | `false` | Enable start-up probe. |
| startupProbe.failureThreshold | int | `10` | Failure threshold for start-up probe. |
| startupProbe.initialDelaySeconds | int | `60` | Initial delay before start-up probe is initiated. |
| startupProbe.periodSeconds | int | `10` | Period for start-up probe. |
| startupProbe.successThreshold | int | `1` | Success threshold for start-up probe. |
| startupProbe.tcpSocket | object | `{"port":"http"}` | TCP socket configuration for start-up probe. |
| startupProbe.timeoutSeconds | int | `1` | Timeout for start-up probe. |
| strategy | object | This object has the following default values for the strategy configuration. | Strategy configuration for controlling how pod updates are performed. |
| strategy.rollingUpdate.maxSurge | string | `"100%"` | Maximum number of pods that can be created above the desired amount during an update. |
| strategy.rollingUpdate.maxUnavailable | int | `0` | Maximum number of pods that can be unavailable during an update. |
| strategy.type | string | `"RollingUpdate"` | The strategy type for pod updates. Use `RollingUpdate` if you use `ReadWriteMany` persistent storage or deploying on a single node. Otherwise, use `Recreate` to allow upgrades, although it causes downtime during the upgrade process. |
| test.enabled | bool | `false` | Enable or disable the test-connection Pod. |
| test.image.name | string | `"busybox"` | Image name for the wget container used in the test-connection Pod. |
| test.image.tag | string | `"latest"` | Image tag for the wget container used in the test-connection Pod. |
| tolerations | list | `[]` | Tolerations configuration for the deployment. |
| topologySpreadConstraints | list | `[]` | TopologySpreadConstraints configuration for the deployment. |