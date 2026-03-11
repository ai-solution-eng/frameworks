# Langflow

## PCAI with Self-signed Certificate

When adding Langflow as an additional Framework in a AI Essentials environment that uses self-signed certificates additional steps are required in order to interact with other frameworks within AIE seamlessly, for example models deployed via MLIS.

### Edit trust bundle resource

This step is required only once per cluster! If you have imported additional frameworks before this might have been done already.

Ensure the useDefaultCAs: true flag is added to the spec: section of your bundle. This collects all standard public CAs and cluster custom CAs into a single configmap.

Run the following command in order to edit the trust bundle
```
kubectl edit bundle ezaf-root-ca
```
Add the following section:

```
spec:
  sources:
  - useDefaultCAs: true
  - secret:
      key: ca.crt
      name: ingress-cert
  target:
    configMap:
      key: ezaf-root-ca.crt
```


Note: By default, useDefaultCAs is often not set. Once you edit the bundle, the ezaf-root-ca configmap is automatically updated in every namespace.

### Edit values file of Langflow

You will want to edit the **backend** section and
* add the volume
```
  - configMap:
      defaultMode: 420
      items:
      - key: ezaf-root-ca.crt
        path: ca-certificates.crt
      name: ezaf-root-ca
    name: ezaf-root-ca
```

* add the volume mount
```
    - mountPath: /etc/ssl/certs/ca-certificates.crt
      name: ezaf-root-ca
      readOnly: true
      subPath: ca-certificates.crt
```

* add the environment variables
```
    - name: REQUESTS_CA_BUNDLE
      value: /etc/ssl/certs/ca-certificates.crt
    - name: SSL_CERT_FILE
      value: /etc/ssl/certs/ca-certificates.crt
```

## Troubleshooting: Langflow Pod Stuck During Startup

In some environments, Langflow may fail to start and appear to be stuck during the initialization phase. The pod logs may show messages similar to:

- Failed to fetch NVIDIA models during initialization
- HTTPSConnectionPool(host='integrate.api.nvidia.com', port=443)
- ConnectTimeoutError: Connection timed out

### What was happening

During startup, Langflow attempts to retrieve the list of available NVIDIA models from `integrate.api.nvidia.com`.  
In restricted enterprise environments, the Kubernetes cluster may not have a direct route to external domains, causing this request to hang indefinitely and preventing Langflow from completing the startup process.

### Workaround Applied

To resolve this, the following adjustments were made.

#### 1. Disable telemetry and enable lazy component loading

Some environment variables were added to reduce external calls and unnecessary initialization during startup:

```yaml
- name: LANGFLOW_SKIP_AUTH_AUTO_LOGIN
  value: "true"
- name: LANGFLOW_LAZY_LOAD_COMPONENTS
  value: "true"
- name: DO_NOT_TRACK
  value: "true"
```
  
### What was happening

During startup, Langflow attempts to retrieve the list of available NVIDIA models from `integrate.api.nvidia.com`.  
In restricted enterprise environments, the Kubernetes cluster may not have a direct route to external domains, causing this request to hang indefinitely and preventing Langflow from completing the startup process.

### Workaround Applied

To resolve this, the following adjustments were made.

#### 1. Disable telemetry and enable lazy component loading

Some environment variables were added to reduce external calls and unnecessary initialization during startup:

```yaml
- name: LANGFLOW_SKIP_AUTH_AUTO_LOGIN
  value: "true"
- name: LANGFLOW_LAZY_LOAD_COMPONENTS
  value: "true"
- name: DO_NOT_TRACK
  value: "true"
```
  These settings help Langflow start faster and avoid optional initialization steps.

#### 2. Configure outbound proxy access

Since the cluster requires a corporate proxy to reach external services, proxy environment variables were added to the Langflow backend container:

```
- name: HTTPS_PROXY
  value: "http://hpeproxy.its.hpecorp.net:8080"
- name: HTTP_PROXY
  value: "http://hpeproxy.its.hpecorp.net:8080"
- name: NO_PROXY
  value: ".cluster.local,.svc,.svc.cluster,.svc.cluster.local,10.0.0.0/8,10.96.0.1,127.0.0.1,172.0.0.0/8,192.0.0.0/8,localhost"
```
  Lowercase versions were also included since some libraries only read those variables:

```
  - name: https_proxy
  value: "http://hpeproxy.its.hpecorp.net:8080"
- name: http_proxy
  value: "http://hpeproxy.its.hpecorp.net:8080"
- name: no_proxy
  value: ".cluster.local,.svc,.svc.cluster,.svc.cluster.local,10.0.0.0/8,10.96.0.1,127.0.0.1,172.0.0.0/8,192.0.0.0/8,localhost"
```

  #### 3. Add a host alias for the NVIDIA endpoint


In some cases DNS resolution from the pod may still fail.
To avoid this, a hostAliases entry was added to the Langflow StatefulSet:

```
hostAliases:
- ip: "75.2.113.119"
  hostnames:
  - "integrate.api.nvidia.com"
```

  This ensures the hostname resolves correctly inside the pod.

#### 4. Restart the StatefulSet

After applying the changes, restart Langflow:

```
kubectl rollout restart statefulset/langflow-service
```

Then check the logs to confirm the service starts correctly:

```
kubectl logs -f langflow-service-0 -c langflow-ide
```

If the startup completes successfully, Langflow should become available at the configured endpoint.

