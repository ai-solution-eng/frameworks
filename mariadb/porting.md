# Porting

## values.yaml

Added at the top of the file:

```
ezua:
  #Use next options in order to configure the application endpoint.
  virtualService:
    endpoint: "mariadb.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
  authorizationPolicy:
    namespace: "istio-system"
    providerName: "oauth2-proxy"
    matchLabels:
      istio: "ingressgateway"
```


## New files

These files have been added:
- templates/virtualservice.yaml


# HPE notes

Chart has been downloaded from [here](https://artifacthub.io/packages/helm/bitnami/mariadb).
