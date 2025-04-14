# Porting

## values.yaml

- **resource**: added requests and limits
- replicated **port:80** because it will be used in the service
- changed service type from **LoadBalancer** to **NodePort** (the former is not supported)
- set **startupProbe.enabled: true** 

Added at the end of the file:

```
ezua:
  virtualService:
    endpoint: "weaviate.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
```

## templates/weaviateStatefulset.yaml

Added the following labels to both **metadata.labels** and **spec.template.metadata.labels**:

```
hpe-ezua/app: weaviate
hpe-ezua/type: vendor-service
```

## templates/virtualService.yaml

Added file.


# HPE notes

Chart has been downloaded from [here](https://github.com/weaviate/weaviate-helm/releases/download/v17.4.2/weaviate.tgz) 
and refers to v17.4.2 (Weaviate version 1.28.4).

Version 17.4.5 has Weaviate 1.30.0.
