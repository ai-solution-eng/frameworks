# Porting

## values.yaml

- **resource**: removed comments from requests and limits
- set **NEXUS_SECURITY_RANDOMPASSWORD** to **false** 

Removed line 31:
```
-XX:+UseCGroupMemoryLimitForHeap
```

Added at the end of the file:

```
ezua:
  virtualService:
    endpoint: "nexus.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
```

## templates/deployment.yaml

Added the following labels to **spec.template.metadata.labels**:

```
hpe-ezua/app: {{ .Chart.Name }}
hpe-ezua/type: vendor-service
```

## templates/virtualService.yaml

Added file.


# HPE notes

Chart has been downloaded from [here](https://github.com/sonatype/nxrm3-helm-repository/blob/main/docs/nexus-repository-manager-64.2.0.tgz) 
and refers to v64.2.0 (Nexus version 3.92.2).

The defaut **admin** password is **admin123**.
