# kubetail

Kubetail is a web-based, real-time log viewer for Kubernetes clusters

<a href="https://discord.gg/CmsmWAVkvX"><img src="https://img.shields.io/discord/1212031524216770650?logo=Discord&style=flat-square&logoColor=FFFFFF&labelColor=5B65F0&label=Discord&color=64B73A"></a>
[![slack](https://img.shields.io/badge/Slack-Join%20Our%20Community-364954?logo=slack&labelColor=4D1C51)](https://join.slack.com/t/kubetail/shared_invite/zt-2cq01cbm8-e1kbLT3EmcLPpHSeoFYm1w)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/kubetail)](https://artifacthub.io/packages/search?repo=kubetail)

## Install

Before you can install you will need to add the `kubetail` repo to Helm:

```console
helm repo add kubetail https://kubetail-org.github.io/helm-charts/
```

After you've installed the repo you can create a new release from the `kubetail/kubetail` chart:

```console
helm install kubetail kubetail/kubetail --namespace kubetail --create-namespace
```

By default, the chart will autogenerate the required secrets (`KUBETAIL_DASHBOARD_CSRF_SECRET`, `KUBETAIL_DASHBOARD_SESSION_SECRET`) and
store them in a Kubernetes Secret to be re-used on subsequent upgrades.

## Upgrade

First make sure helm has the latest version of the `kubetail` repo:

```console
helm repo update kubetail
```

Next use the `helm upgrade` command:

```console
helm upgrade kubetail kubetail/kubetail --namespace kubetail
```

## Uninstall

To uninstall, use the `helm uninstall` command:

```console
helm uninstall kubetail --namespace kubetail
```

## Configuration

These are the configurable parameters for the kubetail chart and their default values:

| Name                                                  | Datatype | Description                           | Default                         |
| ----------------------------------------------------- | -------- | ------------------------------------- | ------------------------------- |
| CHART:                                                |          |                                       |                                 |
| `fullnameOverride`                                    | string   | Override chart's computed fullname    | null                            |
| `nameOverride`                                        | string   | Override chart's name                 | null                            |
| `namespaceOverride`                                   | string   | Override release's namespace          | null                            |
|                                                       |          |                                       |                                 |
| KUBETAIL GENERAL:                                     |          |                                       |                                 |
| `kubetail.allowedNamespaces`                          | array    | Restricted namespaces                 | []                              |
| `kubetail.global.annotations`                         | map      | Annotations for all resources         | {}                              |
| `kubetail.global.labels`                              | map      | Labels for all resources              | {}                              |
| `kubetail.secrets.KUBETAIL_DASHBOARD_CSRF_SECRET`     | string   | B64-encoded value (autogen if null)   | null                            |
| `kubetail.secrets.KUBETAIL_DASHBOARD_SESSION_SECRET`  | string   | B64-encoded value (autogen if null)   | null                            |
| `kubetail.secrets.KUBETAIL_CLUSTER_API_CSRF_SECRET`   | string   | B64-encoded value (autogen if null)   | null                            |
|                                                       |          |                                       |                                 |
| KUBETAIL DASHBOARD:                                   |          |                                       |                                 |
| `kubetail.dashboard.enabled`                          | bool     | Enable/disable dashboard              | true                            |
| `kubetail.dashboard.authMode`                         | string   | Auth mode (auto, token)               | "auto"                          |
| `kubetail.dashboard.runtimeConfig`                    | map      | Dashboard runtime configuration       | *See values.yaml*               |
| `kubetail.dashboard.image.registry`                   | string   | Dashboard image registry              | docker.io                       |
| `kubetail.dashboard.image.repository`                 | string   | Dashboard image repository            | kubetail/kubetail-dashboard     |      
| `kubetail.dashboard.image.tag`                        | string   | Override image default tag            | *See values.yaml*               |
| `kubetail.dashboard.image.digest`                     | string   | Override image tag with digest        | null                            |
| `kubetail.dashboard.image.pullPolicy`                 | string   | Kubernetes image pull policy          | "IfNotPresent"                  |
| `kubetail.dashboard.container.name`                   | string   | Override chart's computed fullname    | null                            |
| `kubetail.dashboard.container.extraEnv`               | array    | Additional env                        | []                              |
| `kubetail.dashboard.container.extraEnvFrom`           | array    | Additional envFrom                    | []                              |
| `kubetail.dashboard.container.securityContext`        | map      | Dashboard container security context  | *See values.yaml*               |
| `kubetail.dashboard.container.resources`              | map      | Dashboard container resource limits   | {}                              |
| `kubetail.dashboard.podTemplate.annotations`          | map      | Additional annotations                | {}                              |
| `kubetail.dashboard.podTemplate.labels`               | map      | Additional labels                     | {}                              |
| `kubetail.dashboard.podTemplate.extraContainers`      | array    | Additional containers                 | []                              |
| `kubetail.dashboard.podTemplate.securityContext`      | map      | Dashboard pod security context        | {}                              |
| `kubetail.dashboard.podTemplate.env`                  | map      | Kubetail container additional env     | {}                              |
| `kubetail.dashboard.podTemplate.envFrom`              | map      | Kubetail container additional envFrom | {}                              |
| `kubetail.dashboard.podTemplate.affinity`             | map      | Pod affinity                          | {}                              |
| `kubetail.dashboard.podTemplate.nodeSelector`         | map      | Pod node selector                     | {}                              |
| `kubetail.dashboard.podTemplate.tolerations`          | array    | Pod tolerations                       | []                              |
| `kubetail.dashboard.configMap.name`                   | string   | Override chart's computed fullname    | null                            |
| `kubetail.dashboard.configMap.annotations`            | map      | Additional annotations                | {}                              |
| `kubetail.dashboard.configMap.labels`                 | map      | Additional labels                     | {}                              |
| `kubetail.dashboard.deployment.name`                  | string   | Override chart's computed fullname    | null                            |
| `kubetail.dashboard.deployment.annotations`           | map      | Additional annotations                | {}                              |
| `kubetail.dashboard.deployment.labels`                | map      | Additional labels                     | {}                              |
| `kubetail.dashboard.deployment.replicas`              | int      | Number of replicas                    | 1                               |
| `kubetail.dashboard.deployment.revisionHistoryLimit`  | int      | Revision history limit                | 5                               |
| `kubetail.dashboard.deployment.strategy`              | map      | Deployment strategy                   | *See values.yaml*               |
| `kubetail.dashboard.ingress.enabled`                  | bool     | If true, add Ingress resource         | false                           |
| `kubetail.dashboard.ingress.name`                     | string   | Override chart's computed fullname    | null                            |
| `kubetail.dashboard.ingress.annotations`              | map      | Additional annotations                | {}                              |
| `kubetail.dashboard.ingress.labels`                   | map      | Additional labels                     | {}                              |
| `kubetail.dashboard.ingress.rules`                    | array    | Ingress rules array                   | []                              |
| `kubetail.dashboard.ingress.tls`                      | array    | Ingress tls array                     | []                              |
| `kubetail.dashboard.ingress.className`                | string   | Ingress class name                    | null                            |
| `kubetail.dashboard.rbac.name`                        | string   | Override chart's computed fullname    | null                            |
| `kubetail.dashboard.rbac.annotations`                 | map      | Additional annotations                | {}                              |
| `kubetail.dashboard.rbac.labels`                      | map      | Additional labels                     | {}                              |
| `kubetail.dashboard.secret.enabled`                   | bool     | If true, add Secret resource          | true                            |
| `kubetail.dashboard.secret.name`                      | string   | Override chart's computed fullname    | null                            |
| `kubetail.dashboard.secret.annotations`               | map      | Additional annotations                | {}                              |
| `kubetail.dashboard.secret.labels`                    | map      | Additional labels                     | {}                              |
| `kubetail.dashboard.service.name`                     | string   | Override chart's computed fullname    | null                            |
| `kubetail.dashboard.service.annotations`              | map      | Additional annotations                | {}                              |
| `kubetail.dashboard.service.labels`                   | map      | Additional labels                     | {}                              |
| `kubetail.dashboard.service.ports.http`               | int      | Service external port number (http)   | 8080                            |
| `kubetail.dashboard.serviceAccount.name`              | string   | Override chart's computed fullname    | null                            |
| `kubetail.dashboard.serviceAccount.annotations`       | map      | Additional annotations                | {}                              |
| `kubetail.dashboard.serviceAccount.labels`            | map      | Additional labels                     | {}                              |
|                                                       |          |                                       |                                 |
| KUBETAIL CLUSTER API:                                 |          |                                       |                                 |
| `kubetail.clusterAPI.enabled`                         | bool     | Enable/disable API                    | true                            |
| `kubetail.clusterAPI.runtimeConfig`                   | map      | API runtime configuration             | *See values.yaml*               |
| `kubetail.clusterAPI.image.registry`                  | string   | API image registry                    | docker.io                       |
| `kubetail.clusterAPI.image.repository`                | string   | API image repository                  | kubetail/kubetail-cluster-api   |      
| `kubetail.clusterAPI.image.tag`                       | string   | Override image default tag            | *See values.yaml*               |
| `kubetail.clusterAPI.image.digest`                    | string   | Override image tag with digest        | null                            |
| `kubetail.clusterAPI.image.pullPolicy`                | string   | Kubernetes image pull policy          | "IfNotPresent"                  |
| `kubetail.clusterAPI.container.name`                  | string   | Override chart's computed fullname    | null                            |
| `kubetail.clusterAPI.container.extraEnv`              | array    | Additional env                        | []                              |
| `kubetail.clusterAPI.container.extraEnvFrom`          | array    | Additional envFrom                    | []                              |
| `kubetail.clusterAPI.container.securityContext`       | map      | API container security context        | *See values.yaml*               |
| `kubetail.clusterAPI.container.resources`             | map      | API container resource limits         | {}                              |
| `kubetail.clusterAPI.podTemplate.annotations`         | map      | Additional annotations                | {}                              |
| `kubetail.clusterAPI.podTemplate.labels`              | map      | Additional labels                     | {}                              |
| `kubetail.clusterAPI.podTemplate.extraContainers`     | array    | Additional containers                 | []                              |
| `kubetail.clusterAPI.podTemplate.securityContext`     | map      | API pod security context              | {}                              |
| `kubetail.clusterAPI.podTemplate.env`                 | map      | Kubetail container additional env     | {}                              |
| `kubetail.clusterAPI.podTemplate.envFrom`             | map      | Kubetail container additional envFrom | {}                              |
| `kubetail.clusterAPI.podTemplate.affinity`            | map      | Pod affinity                          | {}                              |
| `kubetail.clusterAPI.podTemplate.nodeSelector`        | map      | Pod node selector                     | {}                              |
| `kubetail.clusterAPI.podTemplate.tolerations`         | array    | Pod tolerations                       | *See values.yaml*               |
| `kubetail.clusterAPI.configMap.name`                  | string   | Override chart's computed fullname    | null                            |
| `kubetail.clusterAPI.configMap.annotations`           | map      | Additional annotations                | {}                              |
| `kubetail.clusterAPI.configMap.labels`                | map      | Additional labels                     | {}                              |
| `kubetail.clusterAPI.deployment.name`                 | string   | Override chart's computed fullname    | null                            |
| `kubetail.clusterAPI.deployment.annotations`          | map      | Additional annotations                | {}                              |
| `kubetail.clusterAPI.deployment.labels`               | map      | Additional labels                     | {}                              |
| `kubetail.clusterAPI.deployment.replicas`             | int      | Number of replicas                    | 1                               |
| `kubetail.clusterAPI.deployment.revisionHistoryLimit` | int      | Revision history limit                | 5                               |
| `kubetail.clusterAPI.deployment.strategy`             | map      | Deployment strategy                   | *See values.yaml*               |
| `kubetail.clusterAPI.rbac.name`                       | string   | Override chart's computed fullname    | null                            |
| `kubetail.clusterAPI.rbac.annotations`                | map      | Additional annotations                | {}                              |
| `kubetail.clusterAPI.rbac.labels`                     | map      | Additional labels                     | {}                              |
| `kubetail.clusterAPI.service.name`                    | string   | Override chart's computed fullname    | null                            |
| `kubetail.clusterAPI.service.annotations`             | map      | Additional annotations                | {}                              |
| `kubetail.clusterAPI.service.labels`                  | map      | Additional labels                     | {}                              |
| `kubetail.clusterAPI.service.ports.http`              | int      | Service external port number (http)   | 8080                            |
| `kubetail.clusterAPI.serviceAccount.name`             | string   | Override chart's computed fullname    | null                            |
| `kubetail.clusterAPI.serviceAccount.annotations`      | map      | Additional annotations                | {}                              |
| `kubetail.clusterAPI.serviceAccount.labels`           | map      | Additional labels                     | {}                              |
|                                                       |          |                                       |                                 |
| KUBETAIL CLUSTER AGENT:                               |          |                                       |                                 |
| `kubetail.clusterAgent.enabled`                       | bool     | Enable/disable agent                  | true                            |
| `kubetail.clusterAgent.runtimeConfig`                 | map      | Agent runtime configuration           | *See values.yaml*               |
| `kubetail.clusterAgent.image.registry`                | string   | Agent image registry                  | docker.io                       |
| `kubetail.clusterAgent.image.repository`              | string   | Agent image repository                | kubetail/kubetail-cluster-agent |      
| `kubetail.clusterAgent.image.tag`                     | string   | Override image default tag            | *See values.yaml*               |
| `kubetail.clusterAgent.image.digest`                  | string   | Override image tag with digest        | null                            |
| `kubetail.clusterAgent.image.pullPolicy`              | string   | Kubernetes image pull policy          | "IfNotPresent"                  |
| `kubetail.clusterAgent.container.name`                | string   | Override chart's computed fullname    | null                            |
| `kubetail.clusterAgent.container.extraEnv`            | array    | Additional env                        | []                              |
| `kubetail.clusterAgent.container.extraEnvFrom`        | array    | Additional envFrom                    | []                              |
| `kubetail.clusterAgent.container.securityContext`     | map      | Agent container security context      | *See values.yaml*               |
| `kubetail.clusterAgent.container.resources`           | map      | Agent container resource limits       | {}                              |
| `kubetail.clusterAgent.podTemplate.annotations`       | map      | Additional annotations                | {}                              |
| `kubetail.clusterAgent.podTemplate.labels`            | map      | Additional labels                     | {}                              |
| `kubetail.clusterAgent.podTemplate.extraContainers`   | array    | Additional containers                 | []                              |
| `kubetail.clusterAgent.podTemplate.securityContext`   | map      | Agent pod security context            | {}                              |
| `kubetail.clusterAgent.podTemplate.env`               | map      | Kubetail container additional env     | {}                              |
| `kubetail.clusterAgent.podTemplate.envFrom`           | map      | Kubetail container additional envFrom | {}                              |
| `kubetail.clusterAgent.podTemplate.affinity`          | map      | Pod affinity                          | {}                              |
| `kubetail.clusterAgent.podTemplate.nodeSelector`      | map      | Pod node selector                     | {}                              |
| `kubetail.clusterAgent.podTemplate.tolerations`       | array    | Pod tolerations                       | *See values.yaml*               |
| `kubetail.clusterAgent.configMap.name`                | string   | Override chart's computed fullname    | null                            |
| `kubetail.clusterAgent.configMap.annotations`         | map      | Additional annotations                | {}                              |
| `kubetail.clusterAgent.configMap.labels`              | map      | Additional labels                     | {}                              |
| `kubetail.clusterAgent.daemonset.name`                | string   | Override chart's computed fullname    | null                            |
| `kubetail.clusterAgent.daemonset.annotations`         | map      | Additional annotations                | {}                              |
| `kubetail.clusterAgent.daemonset.labels`              | map      | Additional labels                     | {}                              |
| `kubetail.clusterAgent.service.name`                  | string   | Override chart's computed fullname    | null                            |
| `kubetail.clusterAgent.service.annotations`           | map      | Additional annotations                | {}                              |
| `kubetail.clusterAgent.service.labels`                | map      | Additional labels                     | {}                              |
| `kubetail.clusterAgent.service.ports.grpc`            | int      | Service external port number (grpc)   | 50051                           |
| `kubetail.clusterAgent.serviceAccount.name`           | string   | Override chart's computed fullname    | null                            |
| `kubetail.clusterAgent.serviceAccount.annotations`    | map      | Additional annotations                | {}                              |
| `kubetail.clusterAgent.serviceAccount.labels`         | map      | Additional labels                     | {}                              |
|                                                       |          |                                       |                                 |
| KUBETAIL CLI:                                         |          |                                       |                                 |
| `kubetail.cli.enabled`                                | bool     | Enable/disable CLI resources          | true                            |
| `kubetail.cli.rbac.name`                              | string   | Override chart's computed fullname    | null                            |
| `kubetail.cli.rbac.annotations`                       | map      | Additional annotations                | {}                              |
| `kubetail.cli.rbac.labels`                            | map      | Additional labels                     | {}                              |
| `kubetail.cli.serviceAccount.name`                    | string   | Override chart's computed fullname    | null                            |
| `kubetail.cli.serviceAccount.annotations`             | map      | Additional annotations                | {}                              |
| `kubetail.cli.serviceAccount.labels`                  | map      | Additional labels                     | {}                              |
