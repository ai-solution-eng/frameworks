# Langflow IDE — PCAI chart (0.1.13, Langflow 1.13.0)

Helm chart for [Langflow](https://github.com/langflow-ai/langflow) as an IDE, adapted for
**HPE Private Cloud AI**: Istio route with an optional platform-SSO gate, external
PostgreSQL, Keycloak authentication through a pluggable `auth_service` (no custom
image), platform CA trust and corporate-proxy support.

| | |
|---|---|
| Chart version | `0.1.13` |
| appVersion (Langflow) | `1.13.0` |
| Images | `langflowai/langflow:1.13.0`, `langflowai/langflow-frontend:1.13.0` |

This is a **reference implementation** validated on an HPE lab PCAI cluster. It is meant
to be copied and adapted: everything site-specific is a value, and the table below lists
what to change.

---

## 1. Customize before installing

| Value | Default | Set it to |
|---|---|---|
| `ezua.domainName` | `${DOMAIN_NAME}` | your PCAI domain. The PCAI **Import Framework** substitutes it; with plain `helm` you must set it |
| `ezua.virtualService.endpoint` | `langflow.${DOMAIN_NAME}` | the browser hostname |
| `ezua.mcpVirtualService.endpoint` | `langflow-mcp.${DOMAIN_NAME}` | hostname for API-key/MCP clients |
| `ezua.authorizationPolicy.enabled` | `true` | `false` to drop the SSO gate |
| `langflow.backend.oidc.realm` | `UA` | your Keycloak realm — **case-sensitive** |
| `langflow.backend.oidc.keycloakNamespace` | `keycloak` | namespace of the in-cluster Keycloak |
| `langfuse.enabled` | `false` | `true` only if you run Langfuse and have its Secret |
| `proxy.enabled` | `false` | `true` if the cluster has no direct egress |
| `postgresql.auth.password` | dev default | **change it** |
| `langflow.backend.resources` | 4 CPU / 10 GiB req | size to your nodes |
| `postgresql.image` | `bitnamilegacy/postgresql` | your registry mirror if air-gapped |

### Prerequisites the chart does not create

**Secret `langflow-auth`** — three keys:

```bash
kubectl create secret generic langflow-auth -n <namespace> \
  --from-literal=secret-key="$(openssl rand -base64 32)" \
  --from-literal=superuser-password='<password>' \
  --from-literal=nvidia-api-key='<nvapi-key>'
```

> `secret-key` is the Fernet key that encrypts stored global variables and credentials.
> **It must never change** — re-keying makes existing encrypted data unreadable.

**Secret `langfuse-credentials`** — only when `langfuse.enabled: true` (keys `public-key`, `secret-key`).

**ConfigMap `ezaf-root-ca`** — present in every PCAI namespace once the `ezaf-root-ca`
bundle has `useDefaultCAs: true`. The backend mounts it for outbound TLS.

---

## 2. Install

**From the folder** (edit `values.yaml` in place):

```bash
helm install langflow-ide ./0.1.13-sso -n <namespace> --create-namespace
```

**From the packaged chart** (keep your own overrides):

```bash
helm show values langflow-ide-0.1.13.tgz > my-values.yaml   # comments included
$EDITOR my-values.yaml
helm install langflow-ide ./langflow-ide-0.1.13.tgz -n <namespace> -f my-values.yaml
```

**Through PCAI**: *Tools & Frameworks → Import Framework*, upload the `.tgz`, pick a
namespace, edit the values in the wizard. `${DOMAIN_NAME}` is substituted for you.

---

## 3. Authentication — two independent layers

```
  gate ON   browser → ezaf-gateway → oauth2-proxy → Keycloak → Langflow
            every request carries the SSO identity; Langflow's own login page is
            unreachable (use /oauth2/sign_out to end the session)

  gate OFF  browser → Langflow → its own login page (local accounts)
```

`ezua.authorizationPolicy.enabled` controls the gate. It does **not** touch Langflow's
internal auth (`LANGFLOW_AUTO_LOGIN=false` stays), the route, or the machine door.

**Never** pair "gate off" with `LANGFLOW_AUTO_LOGIN=true`: that gives anonymous
superuser access to anyone who can reach the service, including in-cluster callers.

### SSO plugin

`files/sso/pcai_keycloak` is delivered as a ConfigMap, mounted on `PYTHONPATH` and
registered through `lfx.toml` — no custom image. The StatefulSet renders its env vars
from `langflow.backend.oidc`; they are deliberately not in the user-editable env list,
because dropping one silently disables SSO.

```bash
kubectl logs -n <namespace> sts/langflow-service | grep -i "KeycloakAuthService active"
```

---

## 4. Machine door (MCP / API-key clients)

`ezua.mcpVirtualService` adds a second hostname routed to `/api/` only. Because the
AuthorizationPolicy matches a single host, this one is never delegated to oauth2-proxy:
no SSO, Langflow API keys only. Treat it as machine-only.

---

## 5. TLS trust

Langflow's MCP client uses `httpx` with `verify=True`, which trusts certifi's Mozilla
bundle only — HTTPS endpoints signed by the platform CA fail with *"unable to get local
issuer certificate"*.

```
SSL_CERT_FILE / REQUESTS_CA_BUNDLE / NODE_EXTRA_CA_CERTS
  -> /etc/ssl/certs/ezaf-ca-bundle.crt   (single-file mount of ezaf-root-ca)
```

The bundle is **merged** (public roots + cluster CA) on purpose: `SSL_CERT_FILE` replaces
the default store rather than extending it, so a CA-only file would break outbound public
HTTPS.

## 6. Corporate proxy

`proxy.enabled: true` injects `HTTP(S)_PROXY` / `NO_PROXY` into the backend. `noProxy`
**must** cover cluster DNS (`.svc.cluster.local`) or the Keycloak JWKS fetch and Langfuse
go through the proxy and break. The chart refuses to render with an empty `noProxy`.

## 7. File uploads

`langflow.frontend.maxFileSizeUpload` (MB) becomes `LANGFLOW_MAX_FILE_SIZE_UPLOAD`,
consumed by the frontend image's own nginx template.

---

## 8. Known limitations

- **`/app/data` is an `emptyDir`.** Langflow's local storage (uploaded files, anything
  written to the config dir) does not survive a pod restart. Flows are safe — they live in
  PostgreSQL. Mount a PVC at `/app/data` if uploaded files must persist.
- **`helm uninstall` does not delete the PostgreSQL PVC.** Delete it explicitly for a
  clean reinstall.
- The Kyverno vendor-label ClusterPolicy is a `pre-install` hook: not refreshed on
  upgrade, not removed on uninstall.

---

## 9. Verify after install

```bash
kubectl get pods -n <namespace>                       # backend, frontend, postgres
kubectl logs -n <namespace> sts/langflow-service | grep -i "KeycloakAuthService active"
kubectl exec -n <namespace> sts/langflow-service -- \
  python -c "import ssl; print(ssl.get_default_verify_paths().cafile)"
# expect: /etc/ssl/certs/ezaf-ca-bundle.crt
```
