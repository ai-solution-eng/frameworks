# LibreChat — PCAI Porting Notes

LibreChat (https://github.com/danny-avila/LibreChat) is an open-source,
multi-provider AI chat UI. This document describes how the application was
ported to run on **HPE Private Cloud AI (PCAI)** via the **BYOA
(Bring-Your-Own-Application)** feature, following the
[byoa-tutorials guidance](https://github.com/HPEEzmeral/byoa-tutorials/blob/main/tutorial/README.md).

Version **1.0.7** incorporates every fix validated on a live PCAI cluster:
SSO login, model access via LiteLLM, RAG over uploaded documents (verified
end-to-end), and SearXNG web search (verified end-to-end).

## What the chart deploys

| Component | Purpose | Enabled by default |
|---|---|---|
| `librechat` | Chat UI / API server (port 3080) | yes |
| `mongodb` | User/conversation/file store (PVC) | yes |
| `pgvector` | Vector store for RAG | required by ragApi |
| `meilisearch` | Message search backend | no |
| `rag-api` | RAG / document ingestion API | no |
| `searxng` | Private web search (JSON API) | no |

All workloads carry `hpe-ezua/app` + `hpe-ezua/type: vendor-service` labels
(templates/_hpe-ezua.tpl, included via the shared label helpers) so the EZUA
**Resource Management** and **Pod Health** monitoring features see them.

## PCAI / EZUA integration

### 1. Application endpoint (Istio VirtualService)

`ezua.virtualService` → `templates/ezua/virtualService.yaml` routes the
`ezaf-gateway` to `<release>-api:3080`. The Kubernetes Ingress is kept but
disabled — PCAI routes through Istio, not a generic ingress controller.
`DOMAIN_CLIENT` / `DOMAIN_SERVER` derive from `ezua.virtualService.endpoint`.

### 2. SSO / Authorization

**Gateway SSO** (`ezua.authorizationPolicy.enabled=true`): Istio
AuthorizationPolicy (oauth2-proxy) in `istio-system` enforces platform login
before traffic reaches LibreChat.

**Native OIDC** (`librechat.oidc.enabled=true`): LibreChat's own OpenID
strategy against the platform Keycloak — renders a "Continue with HPE SSO"
button; env vars `OPENID_ISSUER/CLIENT_ID/CLIENT_SECRET/SCOPE/CALLBACK_URL/
BUTTON_LABEL` + `ALLOW_SOCIAL_LOGIN=true` are set automatically. Register the
redirect URI `https://<endpoint>/oauth/openid/callback` on the Keycloak client
(realm segment in the issuer is **case-sensitive**, e.g. `/realms/UA`).

**Known pitfall (validated on-cluster):** do NOT enable both gateway SSO and
native OIDC without registering both redirect URIs — the gateway
AuthorizationPolicy intercepts the OIDC callback flow and login breaks with a
generic "Unable to login" banner while the server logs show successful
authentication. For native-OIDC-only deployments set
`ezua.authorizationPolicy.enabled=false`.

### 3. EzAppConfig CR

`ezappconfig-librechat-template.yaml`: `hpe-ezua/imported-app: "true"`,
`spec.name`/`chartVersion` matching Chart.yaml, `category: dataScience`, and
`${DOMAIN_NAME}`/`${NAMESPACE}`/`${RELEASE_NAME}` placeholders in
`spec.values` (substitution happens only for keys present in
`EzAppConfig.Spec.Values`).

## Security hardening

- **Credentials are never in values.yaml or the ConfigMap.** JWT/CREDS keys,
  pgvector/Meilisearch passwords, the model API key and an OIDC session secret
  are generated at install time into `<fullname>-credentials` and injected via
  `envFrom` / `secretKeyRef`. Generated values are **reused across upgrades**
  (`lookup`) — otherwise every `helm upgrade` rotates JWT secrets and breaks
  issued tokens/logins. `HPE_MODEL_API_KEY` intentionally always follows
  values.yaml so key rotation takes effect.
- LibreChat image pinned to `v0.8.7` (the `v0.8.8` final was never pushed to
  ghcr — only rc tags exist there; verified against the registry tag list).
- `global.imageRegistry` prefixes every image for air-gapped mirrors.

## Persistence & pod security

- MongoDB/pgvector/meilisearch use PVCs (`persistence.enabled: true`).
- **`fsGroup: 1000` on every workload** (podSecurityContext): PCAI namespaces
  run containers under a restricted SCC with arbitrary non-root UIDs; without
  fsGroup the app crashes at boot with
  `EACCES: permission denied, open '/app/logs/error-*.log'`, and stateful data
  dirs on fresh PVCs are not writable. The chart also mounts an `emptyDir` at
  `/app/logs` on the api pod.
- Probes use `/health` (LibreChat's actual endpoint — `/api/health` returns
  404 in v0.8.7) with generous grace periods for first-boot Mongo connection.

## Model endpoint (LiteLLM recommended)

`hpeModel.*` renders a custom endpoint in `librechat.yaml` pointing at an
OpenAI-compatible gateway — **LiteLLM in front of MLIS is recommended** (one
virtual key, model discovery via `fetchModels`). The API key lives in the
credentials Secret (`HPE_MODEL_API_KEY`) and is referenced from
`librechat.yaml` as `${HPE_MODEL_API_KEY}` — never in plaintext config.

Notes from the field:
- MLIS serves on **8080**, not 8000; `baseURL` must end at `/v1` with no
  trailing slash.
- `defaultModel` must EXACTLY match a model id the gateway serves
  (`/v1/models`).
- **After changing any credential/model env, restart the consuming
  deployments** — env vars are baked in at container start
  (`kubectl rollout restart deploy/<release>-api deploy/<release>-rag`).
  A pod keeps running with the old key otherwise, producing LiteLLM 401
  `token_not_found_in_db` errors that look like a config problem.

## RAG (document intelligence)

`ragApi.enabled=true` (requires `pgvector.enabled=true`) wires:

- api pod: `RAG_API_URL`
- rag pod: pgvector connection + embeddings env
- `librechat.yaml`: `fileConfig.fileStrategy: "rag"` — **critical**: without
  it, uploaded PDFs are sent inline as `file`-type message parts, which
  vLLM/SGLang-served models reject (400 "role must be ... / Input should be a
  valid string"). With the strategy, files embed into pgvector and the model
  receives retrieved text. Note: embedding happens **at message-send time**,
  not at upload; and files uploaded *before* enabling the strategy must be
  deleted and re-uploaded (their Mongo records carry the old inline strategy).

Embeddings requirements (all validated by failure on-cluster):
- `provider: "openai"` — `"nvidia_nim"` is not a valid
  `EMBEDDINGS_PROVIDER` value in rag-api (startup ValueError).
- `model: BAAI/bge-m3` or another **symmetric** embedding model. Asymmetric
  NIM models (nv-embedqa-*) require an `input_type` parameter that rag-api's
  OpenAI-style client never sends → 400 `input_type parameter is required
  for asymmetric models`.
- The model id must exist as a route in the gateway; verify embeddings
  directly: `POST <gateway>/v1/embeddings {"model":...,"input":"hello"}`.
- When switching embedding models, delete previously indexed documents and
  re-upload (vectors from different models must not be mixed).

The smoke test scripts (`test-rag.sh`, `test-nim-embed.sh`) validate the rag
pipeline and NIM endpoints from a disposable curl pod.

## Web search (SearXNG)

`searxng.enabled=true` deploys SearXNG with a **settings ConfigMap** mounted
at `/etc/searxng/settings.yml` and auto-configures LibreChat. Two settings are
**mandatory** for the integration (both validated by on-cluster 403s):

1. `server.limiter: false` — SearXNG's bot detection rejects server-to-server
   calls that lack browser/proxy headers (`X-Forwarded-For nor X-Real-IP
   header is set!` → 403 Forbidden).
2. `search.formats: [html, json]` — JSON output must be explicitly enabled.
   **`formats` lives under the `search:` key, NOT at top level** — a top-level
   `formats:` block is silently ignored and `format=json` keeps returning 403.

Also: `server.secret_key` must be a fixed non-empty string (template
regeneration rotates it on every restart otherwise).

LibreChat wiring (**both** halves required):
- `librechat.yaml`: `webSearch.searchProvider: searxng` and
  `searxngInstanceUrl: "${SEARXNG_INSTANCE_URL}"` — LibreChat **rejects a
  literal URL** in this key ("contains an actual value instead of an
  environment variable reference" warning; the tool then falls back to Serper
  and fails with `SERPER_API_KEY is required`).
- api pod env: `SEARXNG_INSTANCE_URL=http://<release>-searxng:8080` (set
  automatically by the chart).

**Usage:** web search runs through the **Agents** pipeline. Create an agent
(Agent Builder) on your model with Web Search enabled. If the model backend
exposes the OpenAI **Responses API** but rejects LibreChat's tool schemas
(e.g. SGLang 400 `tools[N].strict ... Input should be a valid boolean`), turn
**"Use Responses API" OFF** in the agent's Model Parameters — the
chat-completions path accepts the tools. The search tool URL is configured
in Settings → Web Search (`http://<release>-searxng:8080`, no key).

## Login troubleshooting

The generic "Unable to login with the information provided" banner maps to
any 4xx from the login endpoint. Diagnostic sequence proven on-cluster:

1. Backend check (bypasses gateway/browser):
   `kubectl run curl-test --rm -it --image=curlimages/curl -n <ns> -- curl -s -X POST http://<release>-api.<ns>.svc.cluster.local:3080/api/auth/login -H "Content-Type: application/json" -d '{"email":"...","password":"..."}'`
   A `{"token":...,"user":...}` response proves the API/DB/auth path.
2. `[Login] [Login successful]` in api logs + browser still failing ⇒
   session-cookie/flow issue (iframe embedding, gateway SSO interference) —
   see section 2.
3. First registered account becomes ADMIN; later accounts via
   `db.users.updateOne({email:"..."},{$set:{role:"ADMIN"}})` in MongoDB.
4. New namespace = fresh MongoDB = old accounts don't exist there.

## Deployment (import via EzAppConfig)

1. Fill the `CHANGEME`/`REPLACE-ME` values (LiteLLM URL + key + model id,
   Keycloak OIDC, SearXNG secret key).
2. Package/push: `helm package` + Chartmuseum, or the byoa
   `api/tooling/bootstrap.sh install` flow with `CHART_PATH` at the chart.
3. Apply the EzAppConfig template; watch `kubectl get ezappconfigs -w`.
4. Post-install: register the intended admin immediately, then set
   `librechat.allowRegistration: false` and upgrade.

### Smoke tests after deploy

```bash
# SearXNG JSON API
kubectl -n <ns> run t --rm -it --image=curlimages/curl --restart=Never -- \
  sh -c 'curl -s "http://<release>-searxng:8080/search?q=test&format=json" | head -c 200'

# RAG pipeline (test-rag.sh: health, embed-upload, query)
./test-rag.sh <ns> <release>

# Model endpoint
kubectl -n <ns> run t --rm -it --image=curlimages/curl --restart=Never -- \
  sh -c 'curl -s <litellm>/v1/models -H "Authorization: Bearer <key>" | head -c 200'
```
