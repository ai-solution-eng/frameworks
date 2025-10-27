# Open WebUI

When you plan to have a lot of users (talking like more than 10) and several documents in there, consider either using an external database and link it (values.yaml databaseUrl line 338) or bumping up the default value of Persistence from 2Gi to something larger (values.yaml line 226). If you don't do that you might hit weird error messages in the pod logs regarding the sqlite.  

## PCAI with Self-signed Certificate

When adding Open WebUI as an additional Framework in a AI Essentials environment that uses self-signed certificates additional steps are required in order to interact with other frameworks within AIE seamlessly, for example models deployed via MLIS.

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

### Edit values file of Open WebUI

You will want to edit the values and
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
    - name: AIOHTTP_CLIENT_SESSION_SSL
      value: /etc/ssl/certs/ca-certificates.crt
```

