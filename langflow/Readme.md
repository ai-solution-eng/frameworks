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

## Langflow Startup Fix

### Context

During startup, Langflow attempts to retrieve the list of available NVIDIA models from `integrate.api.nvidia.com`.

In restricted enterprise environments, the Kubernetes cluster may not have a direct route to external domains. When this happens, the request to the NVIDIA endpoint can hang indefinitely, preventing Langflow from completing the startup process.

### Change Applied

To mitigate this behavior and allow Langflow to start successfully in restricted environments, a small configuration change was applied.

The only modification made was adding a set of environment variables to the deployment configuration to reduce external calls and unnecessary initialization during startup.

### Configuration

```yaml
- name: LANGFLOW_SKIP_AUTH_AUTO_LOGIN
  value: "true"
- name: LANGFLOW_LAZY_LOAD_COMPONENTS
  value: "true"
- name: DO_NOT_TRACK
  value: "true"
```

### Purpose of the Change

These settings help Langflow start faster and avoid optional initialization steps that may require external connectivity.

- **LANGFLOW_SKIP_AUTH_AUTO_LOGIN**  
  Prevents automatic authentication initialization during startup.

- **LANGFLOW_LAZY_LOAD_COMPONENTS**  
  Loads components only when they are needed instead of loading all of them during startup.

- **DO_NOT_TRACK**  
  Disables telemetry calls.

### Expected Result

With these variables configured, Langflow should complete the startup process without waiting for external services.

Once the pod starts successfully, Langflow should become available at the configured endpoint.
