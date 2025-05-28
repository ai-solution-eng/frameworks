# Porting guide
Objective: Highlight key steps/solutions to import Harbor private registry to PCAI.

## What is Harbor?
Harbor is an open source trusted cloud native registry project that stores, signs, and scans content. 
[Github](https://github.com/goharbor/harbor)

## Why is Harbor on PCAI?
Below are main benefits of deploying Harbor on-premises

- Security & Compliance: Keep container images within your infrastructure to meet data sovereignty and compliance needs (e.g., HIPAA, GDPR)
- Performance: Faster image pulls and pushes without relying on external networks. Improves CI/CD speed with local image availability.
- Full Control: Customize storage, authentication (e.g., LDAP/AD), TLS, replication, and image scanning to fit internal policies.
- Air-gapped Support: Desired for disconnected or restricted environments. Harbor can replicate from external sources and operate offline.
- Enterprise Integration: Integrates with LDAP, internal CI/CD tools (Jenkins, GitLab), and local security scanners like Trivy.
- Multi-Tenancy: Supports project-based isolation with separate access controls, quotas, and logs for teams or departments.
- Cost Savings: No cloud egress fees or vendor lock-in. Uses your existing on-prem infrastructure efficiently.

## What changes required?
- Download the latest helm chart via this [link](https://helm.goharbor.io/harbor-1.17.0.tgz)
```sh
wget https://helm.goharbor.io/harbor-1.17.0.tgz
```

- Refer to this [instruction](https://github.com/HPEEzmeral/byoa-tutorials/tree/main/tutorial#configuring-hpe-ezua-labels) to integrate application helm chart to deploy on PCAI via Bring Your Own Application feature. 

Make sure to:
- Update application helm chart values.yaml file with ezua.virtualService section.
- Configure Application istio VirtualService
- Add _hpe-ezua.tpl to your helm chart template
- Use hpe-ezua.labels in the helm chart workloads

In values.yaml, make the following changes.

```yaml
ezua:
  #Use next options in order to configure the application endpoint.
  virtualService:
    endpoint: "harbor.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
  authorizationPolicy:
    namespace: "istio-system"
    providerName: "oauth2-proxy"
    matchLabels:
      istio: "ingressgateway"
```
```yaml
  type: ingress
  tls:
    # Enable TLS or not.
    # Delete the "ssl-redirect" annotations in "expose.ingress.annotations" when TLS is disabled and "expose.type" is "ingress"
    # Note: if the "expose.type" is "ingress" and TLS is disabled,
    # the port must be included in the command when pulling/pushing images.
    # Refer to https://github.com/goharbor/harbor/issues/5291 for details.
    enabled: false
```
```yaml
  ingress:
    hosts:
      core: harbor.ingress.${DOMAIN_NAME}
```
```yaml
    annotations:
      kubernetes.io/ingress.class: istio
      networking.istio.io/ingress-class: istio
      # ingress.kubernetes.io/force-ssl-redirect: "true"
      # note different ingress controllers may require a different ssl-redirect annotation
      # for Envoy, use ingress.kubernetes.io/force-ssl-redirect: "true" and remove the nginx lines below
      #ingress.kubernetes.io/ssl-redirect: "true"
      #ingress.kubernetes.io/proxy-body-size: "0"
      #nginx.ingress.kubernetes.io/ssl-redirect: "true"
      #nginx.ingress.kubernetes.io/proxy-body-size: "0"
```
```yaml
externalURL: https://harbor.ingress.${DOMAIN_NAME}
```
```yaml
  portal:
    tls:
      enabled: false
```
```yaml
portal:
  image:
    repository: goharbor/harbor-portal
    tag: v2.13.0
  # set the service account to be used, default if left empty
  serviceAccountName: ""
  # mount the service account token
  automountServiceAccountToken: false
  replicas: 1
  revisionHistoryLimit: 10
  resources:
    limits:
      memory: 512Mi
      cpu: 250m
    requests:
      memory: 256Mi
      cpu: 100m
```
```yaml
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi
  extraEnvVars:
  - name: HARBOR_AUTH_MODE
    value: db_auth
```
```yaml
jobservice:
  image:
    repository: goharbor/harbor-jobservice
    tag: v2.13.0
  # set the service account to be used, default if left empty
  serviceAccountName: ""
  # mount the service account token
  automountServiceAccountToken: false
  replicas: 1
  revisionHistoryLimit: 10
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi
```
```yaml
registry:
  registry:
    image:
      repository: goharbor/registry-photon
      tag: v2.13.0
    resources:
      limits:
        memory: 512Mi
        cpu: 250m
      requests:
        memory: 256Mi
        cpu: 100m
    extraEnvVars: []
  controller:
    image:
      repository: goharbor/harbor-registryctl
      tag: v2.13.0
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 250m
        memory: 256Mi
```
```yaml
database:
  # if external database is used, set "type" to "external"
  # and fill the connection information in "external" section
  type: internal
  internal:
    image:
      repository: goharbor/harbor-db
      tag: v2.13.0
    # set the service account to be used, default if left empty
    serviceAccountName: ""
    # mount the service account token
    automountServiceAccountToken: false
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 250m
        memory: 256Mi
```
```yaml
    shmSizeLimit: 512Mi
    initContainer:
      migrator: {}
      resources:
        limits:
          cpu: 500m
          memory: 512Mi
        requests:
          cpu: 100m
          memory: 128Mi
      permissions: {}
      resources:
        limits:
          cpu: 500m
          memory: 512Mi
        requests:
          cpu: 250m
          memory: 256Mi
```
```yaml
redis:
  # if external Redis is used, set "type" to "external"
  # and fill the connection information in "external" section
  type: internal
  internal:
    image:
      repository: goharbor/redis-photon
      tag: v2.13.0
    # set the service account to be used, default if left empty
    serviceAccountName: ""
    # mount the service account token
    automountServiceAccountToken: false
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 250m
        memory: 256Mi
```
```yaml
exporter:
  image:
    repository: goharbor/harbor-exporter
    tag: v2.13.0
  serviceAccountName: ""
  # mount the service account token
  automountServiceAccountToken: false
  replicas: 1
  revisionHistoryLimit: 10
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi
```

## Notes
- Redirect URL into keycloak is optional and not added yet
- TLS is not enabled