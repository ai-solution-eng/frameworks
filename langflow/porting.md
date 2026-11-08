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

# 0.1.13-sso — Langflow 1.13.0 (2026-11)

Chart `0.1.13`, appVersion `1.13.0`. Folder `0.1.13-sso/`, artifact
`langflow-ide-sso-0.1.13.tgz`. Deployed namespace at HPE: `langflow-1-13`.

## This is not a rebase onto a newer upstream chart

`langflow-ai/langflow-helm-charts` is stagnant: last release `langflow-ide-0.1.2`
with `appVersion: latest`, and `main` is byte-identical to that release. The
`0.1.x` series in this repo is HPE-authored, tracking Langflow app releases.

Note also that `1.10.0/` is **not** pristine upstream — it is the pre-SSO HPE
chart. `templates/authpolicy.yaml`, `templates/ezua/*`, the `ezua:` values block
and the frontend nginx rework exist in neither upstream nor 0.1.2. Diffing
`1.10.0` against `0.1.10-sso` therefore understates the PCAI surface.

The upgrade is: appVersion + image tags + SSO-plugin compatibility + the items
below.

## Changes vs 0.1.10-sso

| Change | Why |
|---|---|
| `appVersion: 1.13.0`; 3 image tags → 1.13.0 | `appVersion` is a label; the tags are what actually ship |
| `ezua.authorizationPolicy.enabled` + `{{- if }}` wrapper in `templates/authpolicy.yaml` | on/off switch for the platform SSO gate, modelled on the multimodal-rag chart |
| SSO plugin: removed `_install_oauth2_login()` | its premise ("stock Langflow ships no oauth2_login") was never true; in 1.13 the symbol is a real FastAPI security scheme whose cookie name derives from `auth_cookie_name()` |
| SSO plugin: `except Exception` → `except (InvalidTokenError, TokenExpiredError)` | 1.13 added `AuthBackendUnavailableError` (503); swallowing it reports an outage as "invalid token" |
| CA trust: `SSL_CERT_FILE` / `REQUESTS_CA_BUNDLE` / `NODE_EXTRA_CA_CERTS` → single-file mount of `ezaf-root-ca` | Langflow's MCP client trusts certifi only → "unable to get local issuer certificate" on PCAI HTTPS endpoints |
| `proxy:` block rendered into the backend env | verified on the lab cluster: direct egress `000`, via hpeproxy `404` |
| `templates/mcp-virtualservice.yaml` (was `extras/`) | the hand-applied copy hardcoded namespace `langflow-sso` + the production hostname |
| removed `templates/nginx-configmap.yaml` | mounted at `/etc/nginx/templates/…`; the image entrypoint reads `/etc/nginx/conf.d/default.conf.template`, so it never took effect. Upload cap now via `langflow.frontend.maxFileSizeUpload` |
| removed dead values keys (`backend.command`, `backend.podAnnotations`, `frontend.env/volumes/volumeMounts`, `ezua.oidc`) | the templates hardcode or never read them |
| frontend: restored `imagePullSecrets` | 0.1.10-sso dropped it, so it only applied to the backend (air-gap/private registry) |
| dropped `charts/postgresql-15.5.38.tgz` | duplicate of `charts/postgresql/`; Helm used the directory but `helm package` shipped both (170 KB → 67 KB) |

## Deliberately NOT adopted

**Langflow 1.13's built-in external auth** (`LANGFLOW_EXTERNAL_AUTH_*`) would
replace the `pcai_keycloak` plugin, but it hard-rejects a plain-http JWKS URL
(the chart's split-horizon JWKS is `http://keycloak.keycloak.svc…`) and requires
an audience claim. `LANGFLOW_SSO_*` is foundations only — no OIDC
redirect/callback route exists yet. Revisit when Keycloak is served over
in-cluster TLS and an audience is registered.

**The chart's `ezua.selfSignedCert: true` path** builds an `emptyDir` from an
alpine bundle and mounts it over the whole `/etc/ssl/certs` directory. On the new
**UBI 10** backend base that hides the distro trust store, and it additionally
requires Kyverno plus `secret/istio-system/ingress-cert`. The CA block above is
narrower and does not depend on either.

## Base-image change to watch

1.13.0's backend image moved from Debian to `ubi10/python-314-minimal`
(Python 3.14, uid 1000 / gid 0, `HOME=/app/data`, Node 24 installed for npx-based
MCP servers). Re-verify `readOnlyRootFilesystem`, mounted emptyDirs and anything
that assumed Debian paths (`/etc/ssl/certs/ca-certificates.crt`).

## Verify

```bash
helm lint 0.1.13-sso
helm template lf 0.1.13-sso | grep -c '^kind:'                                  # 18
helm template lf 0.1.13-sso --set ezua.authorizationPolicy.enabled=false \
  | grep -c 'kind: AuthorizationPolicy'                                         # 0
helm template lf 0.1.13-sso --set proxy.noProxy="" 2>&1 | head -1               # refuses
```
