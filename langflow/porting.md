# Porting

## Chart.yaml

Changed:

```
appVersion: latest
```

to: 

```
appVersion: 1.4.2
```

because we are targeting a specific version. Also, the patched image refers to LangFlow v1.4.2.

## values.yaml

Changed the container image from **langflowai/langflow** to a custom one. There is no easy way to patch LangFlow without a custom image as the file system where **uv** is located is read-olny:

```
    image:
      repository: acarboni/langflow-ide
      imagePullPolicy: IfNotPresent
      tag: 1.4.2
```

The langflow.backend section has been changed to include CPU limits and to increase the timeout. From this code:
```
    resources:
      requests:
        cpu: 2
        memory: 2Gi
      limits:
        cpu: 4
        memory: 4Gi
    probe:
      failureThreshold: 3
      periodSeconds: 10
      timeoutSeconds: 10
      initialDelaySeconds: 30
```

PostgreSQL has been configured as an external database, changing this one:
```
    externalDatabase:
      enabled: false
```

to this one:
```
    externalDatabase:
      enabled: true
      driver:
        value: "postgresql"
      host:
        value: "langflow-ide-postgresql-service"
      port:
        value: "5432"
      database:
        value: "langflow-db"
      user:
        value: "langflow"
      password:
        valueFrom:
          secretKeyRef:
            key: "password"
            name: "langflow-ide-postgresql-service"
```

At the end of the file, we also enabled the embedded PostgreSQL database, as we want to use the one provided by LangFlw itself:
```
postgresql:
  enabled: true
  fullnameOverride: "langflow-ide-postgresql-service"
  auth:
    username: "langflow"
    password: "langflow-postgres"
    database: "langflow-db"
```

and, of course, the internal SqlLite DB has been disabled:
```
    sqlite:
      enabled: false
```

The **langflow.frontend** has been changed too, in order to add resource limits:
```
    resources:
      requests:
        cpu: 1
        memory: 512Mi
      limits:
        cpu: 2
        memory: 4Gi
```

We also had to add some pod annotations:
```
  podAnnotations:
    sidecar.istio.io/inject: "false"
```

and, at the end of the file, we added the usual **ezua** block of code to specify the virtual service (with also the configuration for the SSO):
```
ezua:
  domainName: "${DOMAIN_NAME}"
  virtualService:
    endpoint: "langflow.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"

  authorizationPolicy:
    namespace: "istio-system"
    providerName: "oauth2-proxy"
    matchLabels:
      app: "langflow-service"
```


## New files

The following new files has been added to complete the configuration:

- templates/authpolicy.yaml
- templates/kyverno.yaml
- templates/virtualService.yaml


# HPE notes

Chart has been downloaded from [here](https://github.com/langflow-ai/langflow-helm-charts/releases/download/langflow-runtime-0.1.1/langflow-runtime-0.1.1.tgz).

The documentation on how to configure LangFlow with PostgreSQL is [here]
(https://github.com/langflow-ai/langflow-helm-charts/blob/main/examples/langflow-ide/dev-values-postgres.yaml)

