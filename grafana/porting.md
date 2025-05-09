# Porting

## Chart.yaml

Changed:

```
name: grafana
```

to: 

```
name: grafana-aie
```

as *grafana* is a reserved name for AI Essentials.

## values.yaml

Uncommented **podLabels** and set to:

```
podLabels:
  hpe-ezua/app: grafana-aie
  hpe-ezua/type: vendor-service
```

Uncommented **resources** and set to:

```
resources:
  limits:
    cpu: 1000m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

Added at the end of the file:

```
ezua:
  virtualService:
    endpoint: "grafana.${DOMAIN_NAME}"
```

## templates/virtualService.yaml

Added file.


# HPE notes

Chart has been downloaded from [here](https://github.com/grafana/helm-charts/releases/tag/grafana-8.15.0) 
and refers to v8.15.0 (Grafana version 11.6.1).

During import, you can set the password uncommenting line 493 of the values.yaml file.
