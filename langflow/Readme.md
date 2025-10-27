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


