# Porting - MongoDB

## values.yaml

Changed:
```
- Set image tag to `latest` for all images (mongodb, nginx, kubectl, os-shell).
- Set architecture to `standalone`.
- Set `replicaCount: 2`.
- Set `resourcesPreset: "small"` for main container.
- Set `auth.rootPassword` to an explicit password for consistency across dependent charts.
```

Added `commonLabels` for PCAI resource identification and monitoring:
```yaml
commonLabels:
  hpe-ezua/app: mongodb
  hpe-ezua/type: vendor-service
  hpe-ezua/component: database
```

Added `ezua` section at the end of the file for PCAI integration:
```yaml
ezua:
  virtualService:
    endpoint: "mongodb.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
  authorizationPolicy:
    namespace: "istio-system"
    providerName: "oauth2-proxy"
    matchLabels:
      istio: "ingressgateway"
```

## templates/ezua/virtualService.yaml

Added file. Configures an Istio VirtualService to expose MongoDB through the PCAI ingress gateway at `mongodb.${DOMAIN_NAME}`. Routes traffic to the MongoDB ClusterIP service on port 27017.

## templates/ezua/authpolicy.yaml

Added file. Configures an Istio AuthorizationPolicy in the `istio-system` namespace to enable SSO via `oauth2-proxy` for the MongoDB endpoint.

## Notes

- MongoDB is a backend database with no web UI. The VirtualService and AuthorizationPolicy are only needed if you want an app tile on the PCAI dashboard. If MongoDB is used purely as an internal service consumed by other apps, the `ezua` section and both template files can be removed — only `commonLabels` are required for PCAI monitoring and metering.
- For air-gapped deployments, set `global.imageRegistry: "${AIRGAP_REGISTRY}"` to pull images from the private registry.
- The `auth.rootPassword` should be set explicitly to ensure dependent charts (e.g., Mongo Express) can use a consistent, known password.

# HPE Notes

Chart has been downloaded from the [Bitnami Helm repository](https://artifacthub.io/packages/helm/bitnami/mongodb) and refers to v18.6.31 (MongoDB 8.2.7).

```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm pull bitnami/mongodb
```