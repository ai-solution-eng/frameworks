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

Changed:

```
version: 0.1.1
```

to 

```
version: 0.1.1-pcai
```

to indicate that this chart is configured for deployment in HPE Private Cloud AI environment.


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

PostgreSQL has been configured as an external database, so changing this one:
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

At the end of the file, we also enabled the embedded PostgreSQL database, as we want to use the one provided by LangFlow itself:
```
postgresql:
  enabled: true
  fullnameOverride: "langflow-ide-postgresql-service"
  auth:
    username: "langflow"
    password: "langflow-postgres"
    database: "langflow-db"
```

And, of course, the internal SqlLite DB has been disabled:
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

If the cluster is using self-signed certificate, we let the user to adopt this and require them to copy the secret containing the `ca.crt` to the namespace that this chart will be installed. Use this command to copy the secret from `istio-system` to the 'new namespace' (this must match the namespace given in Import Framework wizard, code provided below assumes chart will be installed to `langflow` namespace):

```bash
RELEASE_NAMESPACE=langflow
kubectl create ns ${RELEASE_NAMESPACE}
kubectl get secret ingress-cert \
  --namespace=istio-system \
  -o yaml | \
  grep -v "namespace: istio-system" | \
  kubectl apply --namespace=${RELEASE_NAMESPACE} -f -
```
  <!-- sed "s/namespace: istio-system/namespace: ${RELEASE_NAMESPACE}/" | \ -->

Finally, we've added following to the `ezua` section to indicate self-signed certificate is used by the cluster. Change this to `false` if no need for self-signed certificate injection.

```yaml
ezua:
  selfSignedCert: true
```

## backend-statefulset.yaml

Following changes are mode to the StatefulSet to enable copied secret for Self-signed Certificate to be used if required. This will let this app to access endpoints deployed within the platform using their public URLs.

At line 50, following code is added to attach the copied secret as a volume:

```yaml
        # Private CA certificate should be copied from istio-system namespace to release namespace
        {{- if .Values.ezua.selfSignedCert }}
        - name: ingress-cert
          secret:
            secretName: platform-ingress-cert
        - name: ca-certs
          emptyDir: {}
        {{- end }}

```

And deployed initContainer to copy the certificate onto system ca-certificates.crt file:

```
      {{- if .Values.ezua.selfSignedCert }}
      initContainers:
        - name: copy-ca-certs
          image: alpine:latest
          volumeMounts:
            - name: ca-certs
              mountPath: /certs
            - name: ingress-cert
              mountPath: /usr/local/share/ca-certificates/ca.crt
              subPath: ca.crt
              readOnly: true
          command: ["/bin/sh", "-c"]
          args:
            - cat /etc/ssl/certs/ca-certificates.crt /usr/local/share/ca-certificates/ca.crt >> /certs/ca-certificates.crt
      {{- end }}
```

At line 109, following code is added to mount the certificates into `/etc/ssl/certs` folder:

```yaml
            {{- if .Values.ezua.selfSignedCert }}
            - name: ca-certs
              mountPath: /etc/ssl/certs
              readOnly: true
            {{- end }}
```

## New files

The following new files has been added to complete the configuration:

- templates/ezua/authpolicy.yaml
- templates/ezua/kyverno.yaml
- templates/ezua/virtualService.yaml
- templates/ezua/cert-copy.yaml


# HPE notes

Chart has been downloaded from [here](https://github.com/langflow-ai/langflow-helm-charts/releases/download/langflow-runtime-0.1.1/langflow-runtime-0.1.1.tgz).

The documentation on how to configure LangFlow with PostgreSQL is [here](https://github.com/langflow-ai/langflow-helm-charts/blob/main/examples/langflow-ide/dev-values-postgres.yaml)

To build the patched image, use the following commands:

```
podman build --tag docker.io/acarboni/langflow-ide:1.5.1 .
podman push docker.io/acarboni/langflow-ide:1.5.1
```
