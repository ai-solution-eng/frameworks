# Porting authentik to PCAI
authentik is an open-source Identity Provider (IdP) for modern SSO. It supports SAML, OAuth2/OIDC, LDAP, RADIUS, and more, designed for self-hosting from small labs to large production clusters. [github](https://github.com/goauthentik/authentik)

## Changes in Helm chart
- Add PCAI's virtual service section to Values.yaml.
```yaml
ezua:
  virtualService:
    endpoint: "authentik.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
```
- add HPE EzUA label for pod monitoring
```yaml
# General configuration shared across resources
global:
...
  # Add PCAI specific labels
  podLabels: 
    hpe-ezua/app: authentik
    hpe-ezua/type: vendor-service 
```

- Add virtualservice ( templates/ezua/virtualService.yaml )
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: {{ printf "%s-%s-virtual-service" .Release.Name .Chart.Name }}
spec:
  gateways:
    - istio-system/ezaf-gateway
  hosts:
    - {{ .Values.ezua.virtualService.endpoint | required ".Values.ezua.virtualService.endpoint is required !\n" }}
  http:
    - match:
        - uri:
            prefix: /
      rewrite:
        uri: /
      route:
        - destination:
            # Insert target service name here
            host: {{ include "authentik.server.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
            port:
              # Insert target service port number here
              number: {{ .Values.server.service.servicePortHttp }}
```

## For Separate Postgresql Instance
The PostgreSQL database is created by default during installation. To use separate PostgreSQL Instance, User must deploy postgresql separately and create User/Database for Authentik at first.
- Configure Authentik for separate Postgresql Instance
```yaml
authentik:
...
  postgresql:
    # -- set the postgresql hostname to talk to
    # if unset and .Values.postgresql.enabled == true, will generate the default
    # @default -- `{{ .Release.Name }}-postgresql`
    host: "postgresql.postgresql.svc.cluster.local"
    # -- postgresql Database name
    # @default -- `authentik`
    name: "authentik"
    # -- postgresql Username
    # @default -- `authentik`
    user: "postgres"
    # -- postgresql password
    password: "postgres"
    # -- postgresql port
    port: 5432
```
- Disable Postgresql deployment in Values.yaml
```yaml
# General configuration shared across resources
global:
...
postgresql:
  # -- enable the Bitnami PostgreSQL chart. Refer to https://github.com/bitnami/charts/blob/main/bitnami/postgresql/ for possible values.
  enabled: false
```

## Notes
To Download the original Chart
```bash
helm repo add authentik https://charts.goauthentik.io
helm repo update
helm pull authentik/authentik
```