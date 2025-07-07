# Porting

## Chart.yaml

Changed:

```
- Set recource requests/limits.
- Changed the PVC size.
```

Added at the end of the file:

```
ezua:
  virtualService:
    endpoint: "flowise.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
```

## templates/ezua/virtualService.yaml

Added file.

## templates/ezua/kyverno.yaml

Added file.

# HPE notes

Chart has been downloaded from [here](https://artifacthub.io/packages/helm/cowboysysop/flowise) 
and refers to v5.1.1.
