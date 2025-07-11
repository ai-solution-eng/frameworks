# Porting

## values.yaml

- **resource**: added requests and limits

Added at the end of the file:

```
ezua:
  virtualService:
    endpoint    : "minio.${DOMAIN_NAME}"
    endpointApi : "minio-api.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
```


## New files

These files have been added:
- templates/virtualService.yaml
- templates/virtualService2.yaml

The second service exposes the REST API to external clients. The url is https://minio-api.${DOMAIN_NAME}

# HPE notes

Chart has been downloaded from [here](https://github.com/minio/minio/tree/master/helm-releases) and refers to v5.4.0 (MinIO version RELEASE.2024-12-18T13-15-44Z).

The installation will create an account with:
- username: **admin-io**
- password: **MinIO$2K**
