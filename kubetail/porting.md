# Porting

## values.yaml

- **resource**: added requests and limits
- **global.labels**: added **hpe-ezua/app** , **hpe-ezua/type** labels
- **ezua**: added virtualservice for dashboard UI

```
ezua:
  virtualService:
    endpoint: "kubetail.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
```

## templates/ezua/virtualService.yaml
Added file.


# Notes

To download the original Chart
```bash
helm repo add kubetail https://kubetail-org.github.io/helm-charts/
helm pull kubetail/kubetail
```
