# Porting guide
Objective: Highlight key steps/solutions to import Penpot to PCAI.

## What is Penpot?
Penpot is the first open-source design and prototyping platform for design and code collaboration. It is web-based, works with open standards (SVG, CSS, HTML), and is self-hostable.
[Github (chart)](https://github.com/penpot/penpot-helm) | [Website](https://penpot.app)

## What changes required?
- Download the official Penpot helm chart via tag `penpot-1.9.0` (chart version `1.9.0`, app version `2.17.2`) from the upstream repository and vendor it under `penpot/1.9.0/`.
```sh
curl -LO https://github.com/penpot/penpot-helm/archive/refs/tags/penpot-1.9.0.tar.gz
```

- Refer to this [instruction](https://github.com/HPEEzmeral/byoa-tutorials/tree/main/tutorial#configuring-hpe-ezua-labels) to integrate application helm chart to deploy on PCAI via Bring Your Own Application feature.

Make sure to:
- Update application helm chart values.yaml file with ezua.virtualService section.
- Configure Application istio VirtualService
- Add _hpe-ezua.tpl to your helm chart template
- Use hpe-ezua.labels in the helm chart workloads

In values.yaml, make the following changes.

```yaml
ezua:
  domainName: "${DOMAIN_NAME}"
  # configure the application endpoint
  virtualService:
    endpoint: "penpot.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
  # configure the authorization policy
  authorizationPolicy:
    namespace: "istio-system"
    providerName: "oauth2-proxy"
    enabled: true
```

### Bundled database and cache
The upstream chart ships **no** PostgreSQL or Redis dependencies — Penpot requires both externally. To make a single **Import Framework** install work on PCAI, the Bitnami subcharts are vendored into `charts/` (the same versions appsmith already proved on PCAI) and declared as dependencies with enable conditions. Their images point at the **`bitnamilegacy`** Docker Hub organization: Broadcom removed old Bitnami images from `docker.io/bitnami` (Aug 2025), and this chart version's tags only survive there — `bitnamilegacy/postgresql:14.5.0-debian-11-r21` and `bitnamilegacy/redis:6.2.9-debian-11-r0`. The Penpot app images (`penpotapp/*:2.17.2`) are unaffected.

```yaml
dependencies:
  - name: postgresql
    version: 11.9.5
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
  - name: redis
    version: 16.11.2
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
```

The subchart services are pinned with `fullnameOverride` so `config.postgresql.host` / `config.redis.host` stay valid regardless of the release name chosen in the import wizard:

```yaml
config:
  postgresql:
    host: "penpot-postgresql"
  redis:
    host: "penpot-redis-master"

postgresql:
  enabled: true
  fullnameOverride: "penpot-postgresql"
  auth:
    enablePostgresUser: true
    postgresPassword: "penpot"
    username: "penpot"
    password: "penpot"
    database: "penpot"
  primary:
    persistence:
      storageClass: ""
      size: 8Gi

redis:
  enabled: true
  fullnameOverride: "penpot-redis"
  architecture: standalone
  auth:
    enabled: false
  master:
    persistence:
      storageClass: ""
      size: 8Gi
```

- Redis uses `architecture: standalone` (the Bitnami default replication would add a second StatefulSet) and has auth disabled for the in-cluster demo topology.
- Set `postgresql.enabled: false` and `redis.enabled: false` to point `config.postgresql.*` / `config.redis.*` at external services instead.

### Application endpoint and secrets

```yaml
config:
  # The externally visible URL — must match the ezua.virtualService.endpoint above (https).
  publicUri: "https://penpot.${DOMAIN_NAME}"
  # Session secret — a fresh value was generated for this port; replace it or
  # use config.existingSecret for production.
  apiSecretKey: "SfrXWjDdjxEMQOiVd_zlqfEZQIzD1QvrLGwOvj-oKJyEZ6V2nY-EzHt_Q4FzCyENWVWQ-e9Mcw_63kPVUiugTg"
  flags: "enable-registration enable-login-with-password disable-email-verification enable-smtp enable-mcp enable-login-with-oidc enable-oidc-registration"
```

### Resources
To avoid EzLicense capacity issues that prevent pods from being scheduled, every container must specify `resources.limits.cpu`. The upstream chart ships empty resources everywhere, so requests/limits are set for all four Penpot components and both subcharts:

```yaml
frontend:
  resources:
    requests: { cpu: 250m, memory: 512Mi }
    limits: { cpu: 1, memory: 2Gi }
backend:
  resources:
    requests: { cpu: 500m, memory: 1Gi }
    limits: { cpu: 2, memory: 3Gi }
exporter:
  resources:
    requests: { cpu: 250m, memory: 512Mi }
    limits: { cpu: 1, memory: 2Gi }
mcp:
  resources:
    requests: { cpu: 100m, memory: 256Mi }
    limits: { cpu: 500m, memory: 512Mi }
```

Total footprint: ~6 pods with ~5.5 vCPU of limits — suitable for S/M/L clusters; tight on Dev Kit.

### Large-node nginx worker fix
The `penpotapp/frontend` image ships `worker_processes auto;` in its nginx config. nginx resolves `auto` against the **host** CPU count (the CFS quota does not change the CPU affinity mask), so on PCAI's 343-vCPU nodes it spawns ~343 workers and the container is OOM-killed within seconds, regardless of the memory limit. The frontend Deployment therefore overrides the container command to render the image's real nginx config (the Penpot vhost lives in `/etc/nginx/overrides/*`, generated by the entrypoint from `/tmp/nginx.conf.template`), rewrite the worker count, and start nginx from the patched copy:

```yaml
frontend:
  command: ["/bin/bash", "-c"]
  args:
    - |-
      bash /entrypoint.sh true && sed "s/worker_processes.*/worker_processes  4;/" /etc/nginx/nginx.conf > /tmp/nginx.conf && exec nginx -c /tmp/nginx.conf -g "daemon off;"
```

- The entrypoint must be invoked as `bash /entrypoint.sh` (it is not directly executable for the non-root `penpot` user).
- **Do not** patch the shipped `/etc/nginx/nginx.conf` placeholder and start nginx from it — that config only includes the stock `conf.d/default.conf`, which serves the default "Welcome to nginx" page instead of Penpot.
- The generic `frontend.command` / `frontend.args` passthrough was added to the Deployment template to support this; remove both values to restore image defaults on nodes with a normal CPU count.

### Corporate CA certificates and proxy
For clusters behind corporate proxies / TLS interception (same treatment as osm-seed), three independently gated value blocks are added and wired into all four Penpot deployments (frontend, backend, exporter, MCP):

- `certificatesPolicy` — an init container copies the CA bundle baked into the init image (use a corporate-baked `alpine`) into a shared `combined-certs` emptyDir that every container mounts at `/tmp/certs`; `SSL_CERT_FILE` points the apps at it.
- `proxy` — injects `HTTP_PROXY` / `HTTPS_PROXY` (and lowercase variants) into the app containers **and** the CA-copy init container.
- `no_proxy` — injects `NO_PROXY` covering cluster-internal traffic (`.svc.cluster.local`, RFC1918 ranges, HPE API/registry hosts) so Postgres/Redis/backend communication bypasses the proxy.

Both `proxy` and `no_proxy` ship **enabled with HPE corporate defaults** in this chart; set them to `false` (and `certificatesPolicy.enabled: false`) for clusters without a corporate wall.

### SSO via Keycloak OIDC (shared `ua` client)
Penpot natively supports OIDC (callback `https://<domain>/api/auth/oidc/callback`). SSO uses the PCAI platform Keycloak (realm `UA`) and the **shared `ua` client**, exactly like open-webui. In addition to `enable-login-with-oidc`, the flags include `enable-oidc-registration`, which lets a first-time SSO user get an account auto-created (no prior password registration needed). Email/password login is kept as break-glass access.

Keycloak pins its hostname to the gateway URL, so every discovery document returns **public HTTPS** endpoints whose certificate is issued by the cluster-private `AIE Root CA` — which the backend JVM would reject. Instead of TLS surgery, all three OIDC endpoints are set explicitly, which makes Penpot **skip discovery entirely** (verified in `backend/src/app/auth/oidc.clj`: when `authURI`, `tokenURI` and `userURI` are all set, discovery is bypassed) — the browser gets the public authorization endpoint while the backend exchanges tokens in-cluster over plain HTTP:

```yaml
config:
  providers:
    oidc:
      enabled: true
      # MUST end with a trailing slash: Penpot resolves .well-known/openid-configuration
      # as a relative URI, and a base without one drops the realm segment.
      # Unused while the three endpoints below are set (discovery is skipped).
      baseURI: "https://keycloak.${DOMAIN_NAME}/realms/UA/"
      clientID: "ua"
      # PLACEHOLDER — run configure_oidc.sh (in this folder) from a kubeconfig-configured
      # terminal: it adds the Penpot callback URL to the `ua` client's redirect URIs and
      # prints the secret to paste into the Import Framework values override box.
      clientSecret: "CHANGE_ME_paste-in-wizard"
      scopes: "openid profile email"   # Penpot requires `name` and `email` in the userinfo
      authURI: "https://keycloak.${DOMAIN_NAME}/realms/UA/protocol/openid-connect/auth"    # browser-facing, public
      tokenURI: "http://keycloak.keycloak.svc.cluster.local/realms/UA/protocol/openid-connect/token"   # in-cluster, plain HTTP
      userURI: "http://keycloak.keycloak.svc.cluster.local/realms/UA/protocol/openid-connect/userinfo" # in-cluster, plain HTTP
frontend:
  extraEnvs:
    - name: PENPOT_OIDC_NAME     # label on the login button (matches open-webui's providerName)
      value: "SSO"
backend:
  extraEnvs:
    # Penpot's SSRF protection would otherwise block the in-cluster and gateway-facing
    # Keycloak hostnames during OIDC flows.
    - name: PENPOT_SSRF_ALLOWED_HOSTS
      value: "keycloak.keycloak.svc.cluster.local keycloak.${DOMAIN_NAME}"
    # Keeps id-token signature verification active in-cluster (without an explicit
    # jwks-uri the provider initializes without keys and falls back to userinfo).
    - name: PENPOT_OIDC_JWKS_URI
      value: "http://keycloak.keycloak.svc.cluster.local/realms/UA/protocol/openid-connect/certs"
```

- Penpot performs **no issuer validation** on the id_token (only signature verification), so mixing the public auth URI with in-cluster token/userinfo/JWKS URIs is safe.
- Two OIDC gotchas worth knowing: the `baseURI` must end with a trailing slash (Penpot resolves `.well-known/openid-configuration` as a relative URI — without it the realm segment is dropped), and the `ezaf-root-ca` ConfigMap bundle contains public roots only, so it cannot validate the cluster-private gateway certificate (ruling out a JVM truststore approach).

### HPE EZUA labels
- Added **_hpe-ezua.tpl** under the **templates** folder:

```yaml
{{- define "penpot.hpeEzuaLabels" -}}
hpe-ezua/app: {{ .Chart.Name }}
hpe-ezua/type: vendor-service
{{- end -}}
```

- Wired the helper into `penpot.selectorLabels` (and the per-component selector labels) so every Pod, Deployment, Service, PVC and the VirtualService carry the labels natively — no Kyverno ClusterPolicy is needed.
- The bundled Bitnami subcharts get the same labels via `commonLabels`; redis 16.x does not propagate `commonLabels` to the pod template, so `redis.master.podLabels` repeats them.

### VirtualService
- Added **virtualservice.yaml** under the **templates** folder, routing to the Penpot frontend service (`<fullname>`, port **8080** — the only user-facing entry; the backend 6060, exporter 6061 and MCP 4401/4402 services stay cluster-internal).

### AuthorizationPolicy
- Added **authorizationpolicy.yaml** under the **templates** folder with the `oauth2-proxy` provider in `istio-system`, gated by `ezua.authorizationPolicy.enabled: true` so PCAI SSO is required in front of Penpot. Set it to `false` to expose Penpot behind its own login only.

### Chart version
- Version number in **Chart.yaml** has been kept at `1.9.0` (matching upstream) to indicate the customised port. As PCAI does not allow reuploading helm charts for the same application name and version (in case the first uploads led to import failures), you need to change the version in **Chart.yaml** (e.g. append a suffix) on any re-import.

## Verification
- `helm lint penpot/1.9.0/` — passes with 0 failures.
- `helm template penpot penpot/1.9.0/ --set ezua.virtualService.endpoint=penpot.example.com` renders: 1 VirtualService, 1 AuthorizationPolicy, 4 Deployments (frontend/backend/exporter/mcp), 2 StatefulSets (PostgreSQL primary, Redis master), 1 PVC (assets 20Gi), 9 Services, 1 Secret, 2 ServiceAccounts, 3 ConfigMaps. An automated check confirmed `hpe-ezua` labels on every resource, consistent selectors, `limits.cpu` on every container, the corporate CA/proxy env wiring, the legacy Bitnami images, and the OIDC endpoint configuration.
- External-DB mode (`postgresql.enabled=false`, `redis.enabled=false`) also renders cleanly without the subchart resources.

## Import to PCAI
1. Open the PCAI AI Essentials homepage → **Tools & Frameworks** → **Import Framework**.
2. Run `configure_oidc.sh` once from a kubeconfig-configured terminal — it registers the Penpot callback URL on the shared `ua` client and prints the client secret.
3. Fill in Name (`penpot`), Version, logo file (`penpot.png`), the chart archive (`penpot-1.9.0.tgz`) and the target Namespace.
4. In the Framework Values override box, set the endpoint and the OIDC secret:
```yaml
ezua:
  virtualService:
    endpoint: "penpot.<your-pcai-domain>"
config:
  publicUri: "https://penpot.<your-pcai-domain>"
  providers:
    oidc:
      clientSecret: "<secret printed by configure_oidc.sh>"
```
5. Complete the import and wait for the 6 pods to become ready.
6. Open Penpot from the AI Essentials tile or directly at `https://penpot.<your-pcai-domain>` — log in via the **SSO** button (accounts are auto-created on first login) or register with email/password.

Note: `${DOMAIN_NAME}` is substituted by the import wizard; if you install with raw `helm install` instead, substitute it yourself (e.g. `envsubst < values.yaml`) and set the endpoint explicitly.

# HPE notes
- Port performed 2026-09-14 in the `ai-solution-eng/frameworks` repository; chart vendored from upstream tag `penpot-1.9.0` (chart 1.9.0, Penpot 2.17.2).
- PostgreSQL 11.9.5 and Redis 16.11.2 Bitnami subcharts were reused verbatim from `frameworks/appsmith/3.6.4/charts/` — versions already validated on PCAI clusters; no `kubeVersion` constraints to trip on HPE's `v1.33.4-hpe1` kubelet string.
- The `configure_oidc.sh` script's PUT replaces only clientId/name/redirectUris on the `ua` client — the same partial-update pattern proven with open-webui; keep the client secret out of git by pasting it in the wizard override box.
- Storage classes intentionally default to the cluster default provisioner; for PCAI override `persistence.assets.storageClass`, `postgresql.primary.persistence.storageClass` and `redis.master.persistence.storageClass` with `nfs-csi` (Dev Kit) or `gl4f-filesystem` (S/M/L clusters).
- Telemetry is left enabled (upstream default, `config.telemetryEnabled`); set it to `false` for restricted networks.
- SMTP is disabled in the config (`config.smtp.enabled: false`) while the default flags still contain `enable-smtp`; without an SMTP server, email-verification/invites are non-functional but the app works (`disable-email-verification` is already set).
- MCP server (`penpotapp/mcp`) is enabled via the `enable-mcp` flag; remove the flag from `config.flags` to disable it.
