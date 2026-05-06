# Porting - Mongo Express

## values.yaml

Changed:
```
- Set `mongodbServer` to `mongodb.mongodb.svc.cluster.local` (cross-namespace FQDN pointing to the MongoDB service in the `mongodb` namespace).
- Set `mongodbPort: 27017`.
- Set `mongodbEnableAdmin: true` to connect as administrator.
- Set `mongodbAdminUsername: root` to match MongoDB chart's `auth.rootUser`.
- Set `mongodbAdminPassword` to match the password set in the MongoDB chart's `auth.rootPassword`.
- Set `siteCookieSecret` to a random 32-character alphanumeric string.
- Set `siteSessionSecret` to a random 32-character alphanumeric string.
- Set `existingSecret: ""` (cleared) so the chart generates its own Secret with all required keys (mongodb-admin-password, site-cookie-secret, site-session-secret).
- Changed `existingSecretKeyMongodbAdminPassword` from `mongodb-admin-password` to `mongodb-root-password` to match the MongoDB chart's Secret key naming.
```

Added `commonLabels` for PCAI resource identification and monitoring:
```yaml
commonLabels:
  hpe-ezua/app: mongo-express
  hpe-ezua/type: vendor-service
  hpe-ezua/component: ui
```

Added `ezua` section at the end of the file for PCAI integration:
```yaml
ezua:
  virtualService:
    endpoint: "mongo-express.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
  authorizationPolicy:
    namespace: "istio-system"
    providerName: "oauth2-proxy"
    matchLabels:
      istio: "ingressgateway"
```

## templates/ezua/virtualService.yaml

Added file. Configures an Istio VirtualService to expose Mongo Express through the PCAI ingress gateway at `mongo-express.${DOMAIN_NAME}`. Routes traffic to the Mongo Express ClusterIP service on port 8081.

## templates/ezua/authpolicy.yaml

Added file. Configures an Istio AuthorizationPolicy in the `istio-system` namespace to enable SSO via `oauth2-proxy` for the Mongo Express endpoint.

## Key Decisions

- **Why not use `existingSecret` pointing to MongoDB's Secret?** The Mongo Express chart uses `existingSecret` for all secret values (admin password, cookie secret, session secret). The MongoDB Secret only contains `mongodb-root-password`, so referencing it causes `CreateContainerConfigError` for the missing `site-cookie-secret` and `site-session-secret` keys. Instead, the chart generates its own Secret with all required keys.
- **Why set `mongodbEnableAdmin: true`?** Without this, Mongo Express expects a regular user/database pair instead of root admin access, and won't have visibility into all databases.
- **Cross-namespace connectivity:** The `mongodbServer` uses the full FQDN `mongodb.mongodb.svc.cluster.local` because Mongo Express is deployed in the `mongo-express` namespace while MongoDB is in the `mongodb` namespace. If both were in the same namespace, the short name `mongodb` would suffice.
- **Password consistency:** The `mongodbAdminPassword` in this chart must match `auth.rootPassword` in the MongoDB chart. If the MongoDB password changes, this value must be updated and Mongo Express redeployed.

# HPE Notes

Chart has been downloaded from the [Cowboy Sysop Helm repository](https://artifacthub.io/packages/helm/cowboysysop/mongo-express) and refers to v7.0.0 (Mongo Express 1.0.2).

```
helm repo add cowboysysop https://cowboysysop.github.io/charts/
helm pull cowboysysop/mongo-express
```