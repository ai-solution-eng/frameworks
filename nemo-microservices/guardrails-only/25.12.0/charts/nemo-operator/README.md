# NeMo Operator Microservice Helm Chart

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

For deployment guide, see [Admin Setup](https://docs.nvidia.com/nemo/microservices/latest/set-up/index.html) in the NeMo Microservices documentation.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controllerManager.kubeRbacProxy.args | list | `["--secure-listen-address=0.0.0.0:8443","--upstream=http://127.0.0.1:8080/","--logtostderr=true","--v=0"]` | Arguments to pass to the `kube-rbac-proxy` container. |
| controllerManager.kubeRbacProxy.containerSecurityContext.allowPrivilegeEscalation | bool | `false` | Whether to allow container privilege escalation. |
| controllerManager.kubeRbacProxy.containerSecurityContext.capabilities.drop | list | `["ALL"]` | List of capabilities to drop. |
| controllerManager.kubeRbacProxy.image.repository | string | `"gcr.io/kubebuilder/kube-rbac-proxy"` | The repository for the `kube-rbac-proxy` image. |
| controllerManager.kubeRbacProxy.image.tag | string | `"v0.15.0"` | The tag for the `kube-rbac-proxy` image. |
| controllerManager.kubeRbacProxy.resources.limits.cpu | string | `"500m"` | The CPU limit for the `kube-rbac-proxy` container. |
| controllerManager.kubeRbacProxy.resources.limits.memory | string | `"128Mi"` | The memory limit for the `kube-rbac-proxy` container. |
| controllerManager.kubeRbacProxy.resources.requests.cpu | string | `"5m"` | The CPU request for the `kube-rbac-proxy` container. |
| controllerManager.kubeRbacProxy.resources.requests.memory | string | `"64Mi"` | The memory request for the `kube-rbac-proxy` container. |
| controllerManager.manager.args | list | `["--health-probe-bind-address=:8081","--metrics-bind-address=127.0.0.1:8080","--leader-elect","--leader-election-id=nemo.nko.nvidia.com"]` | Arguments to pass to the manager container. |
| controllerManager.manager.containerSecurityContext.allowPrivilegeEscalation | bool | `false` | Whether to allow container privilege escalation. |
| controllerManager.manager.containerSecurityContext.capabilities.drop | list | `["ALL"]` | List of capabilities to drop. |
| controllerManager.manager.image.repository | string | `"nvcr.io/nvidia/nemo-microservices/nemo-operator"` | The repository for the NeMo Operator microservice image. |
| controllerManager.manager.image.tag | string | `""` | The tag for the NeMo Operator microservice image. The default value is `appVersion` from the `Chart.yaml` file. |
| controllerManager.manager.resources.limits.cpu | string | `"1024m"` | The CPU limit for the operator manager container. |
| controllerManager.manager.resources.limits.memory | string | `"2Gi"` | The memory limit for the operator manager container. |
| controllerManager.manager.resources.requests.cpu | string | `"512m"` | The CPU request for the operator manager container. |
| controllerManager.manager.resources.requests.memory | string | `"1Gi"` | The memory request for the operator manager container. |
| controllerManager.manager.scheduler | string | `"volcano"` | The scheduler to use for the controller manager. |
| controllerManager.replicas | int | `1` | The number of operator replicas to run. |
| controllerManager.serviceAccount.annotations | object | `{}` | Annotations to add to the service account. |
| env | object | `{}` | Additional environment variables to pass to controller manager. The format is `NAME: value` or `NAME: valueFrom: {object}`. |
| imagePullSecrets | list | `[{"name":"nvcrimagepullsecret"}]` | Image pull secrets for accessing the NGC container registry. |
| kubernetesClusterDomain | string | `"cluster.local"` | The Kubernetes cluster domain. |
| metricsService.enabled | bool | `true` | Whether to enable the metrics service for the NeMo Operator microservice. If you enable it, the microservice exposes a metrics endpoint for Prometheus. Before installing this chart, you should have Prometheus installed in your environment. |
| metricsService.ports | list | `[{"name":"https","port":8443,"protocol":"TCP","targetPort":"https"}]` | The metrics service ports configuration. |
| metricsService.type | string | `"ClusterIP"` | The type of the metrics service. |
| restrictedNamespace | string | `""` | Namespace to restrict the NeMo Operator microservice to watch resources in. Leave it empty to watch all namespaces. |