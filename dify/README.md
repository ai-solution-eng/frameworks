# Porting Dify to HPE Private Cloud AI (PCAI / AIE 1.12.x) — BYOA

Ports the upstream **BorisPolonsky/dify-helm** chart to PCAI via the BYOA / Import Framework
**Manual** method (Dify is multi-service, so AutoHelm does not apply). Self-contained middleware
(built-in PostgreSQL, Redis, Weaviate). The local LLM (Qwen3-30B on MLIS) is wired post-deploy.

**Package:** `dify-0.39.0-pcai2.tgz` (chart 0.39.0-pcai2, Dify appVersion 1.17.0)
**Status of this guide:** reflects a validated deployment — Dify running (all pods), OpenAI-API-compatible
provider installed, Qwen3-30B wired, chat app validated via UI and API. Durable S3 object storage is
**not** usable on this cluster (see Storage); the validated default is PVC + emptyDir.

## 1. What the overlay adds (PCAI-specific)

- `templates/ezua/virtualService.yaml` — exposes Dify's nginx proxy (chart fullname service, port 80) as the tile endpoint
- `templates/ezua/authorizationPolicy.yaml` — platform ext-authz (CUSTOM) on the proxy service
- `templates/_hpe-ezua.tpl` + `.Values.labels` — `hpe-ezua` labels on all workloads (via `dify.ud.labels`)
- `templates/vast-ca-configmap.yaml` — optional CA ConfigMap (only if durable S3 is pursued; see Storage)
- `values-pcai.yaml` — the overlay applied with `-f` (ezua, storage, CA mounts)

## 2. Prerequisites

- Target namespace: `dify`
- MLIS Qwen endpoint URL (`.../v1`) + its **per-deployment** API key
- Cluster Istio ext-authz provider name (for the AuthorizationPolicy)
- helm 3.14+ with access to chart repos (or an internal mirror) to vendor subcharts — see Build

## 3. Storage 

### Issues & Solution
**S3 is the documented alternative** (object keys allow colons), but on this cluster it is blocked by TLS:
   - `local-s3` is an **s3proxy** fronting VAST. Static keys live in secret `ezdata-system/local-s3-secret`
     (`access-key`, `secret-key`, `endpoint`, `insecure=true`). Those keys authenticate against the secret's
     **VAST endpoint**, NOT the in-cluster `:30000` proxy (proxy + keys -> 401).
   - Dify's S3 client enforces **CA trust AND hostname match**, with no skip-verify option:
     - **CA trust** is fixable by mounting the VAST CA via `AWS_CA_BUNDLE` (this chart supports it).
     - **Hostname match is NOT fixable from Dify:** the VAST cert SANs are `*.vastdata.com`,
       `vms.vastdata.com`, `*` — none match the access host `...hpecolo.net`. Result:
       `hostname '...hpecolo.net' doesn't match ...`. A CA bundle cannot fix a hostname the cert
       never covered.

### DEFAULT (validated) — Option 2: PVC + emptyDir, no S3
This is the config that gets all pods Running.
- `externalS3.enabled: false`  -> Dify app uploads go to the NFS PVC (fine; those files are not colon-named).
- Patch the plugin daemon to **emptyDir** (the chart has no toggle):
      kubectl -n dify patch deploy dify-plugin-daemon --type=json \
        -p='[{"op":"replace","path":"/spec/template/spec/volumes","value":[{"name":"app-data","emptyDir":{}}]}]'
- Apply:
      helm upgrade dify ./dify -n dify -f values-pcai.yaml
      kubectl -n dify rollout status deploy/dify-api
- Tradeoff: plugin packages live in emptyDir -> **reinstall the provider if the plugin-daemon pod restarts**.
  Acceptable for a trial/demo; keep the pod warm during the demo.

### Durable S3 — Option 1 (only if a covered hostname exists)
Set `externalS3.enabled: true`, fill `accessKey`/`secretKey` from `local-s3-secret`, set the CA (below),
AND point `externalS3.endpoint` at a **`*.vastdata.com`** hostname the VAST S3 actually answers on in-cluster
(verify with nslookup/curl from a pod first). Only then do both TLS layers pass. If no such hostname exists,
this option is not achievable — use Option 2.

Retrieve S3 keys / CA (admin-namespace; may be Forbidden on a scoped account):
```sh
      kubectl -n ezdata-system get secret local-s3-secret -o jsonpath='{.data.access-key}' | base64 -d; echo
      kubectl -n ezdata-system get secret local-s3-secret -o jsonpath='{.data.secret-key}' | base64 -d; echo
```
CA (recommended: kubectl ConfigMap, leave vastCA.pem empty in values):
```sh
      # extract from a healthy pod (api may be crashing):
      kubectl -n dify run certgrab --rm -it --image=alpine/openssl --restart=Never -- \
        s_client -connect <vast-host>:443 -showcerts </dev/null 2>/dev/null \
        | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' > vast-ca.pem
      kubectl -n dify create configmap vast-ca --from-file=vast-ca.pem=vast-ca.pem \
        --dry-run=client -o yaml | kubectl -n dify apply -f -
```

## 4. Build the package (vendor subcharts)

The shipped tgz declares postgresql/redis/weaviate as subcharts but may not vendor them (build-env limits).
A chart with declared-but-unvendored deps FAILS at import. Vendor + repackage:
```sh
      tar -xzf dify-0.39.0-pcai.tgz            # -> ./dify
      helm repo add bitnami  https://charts.bitnami.com/bitnami
      helm repo add weaviate https://weaviate.github.io/weaviate-helm
      helm repo update
      helm dependency update ./dify             # regenerates Chart.lock + charts/  (use 'update', not 'build')
      helm package ./dify --dependency-update    # -> dify-0.39.0-pcai.tgz WITH charts/ vendored
      tar -tzf dify-0.39.0-pcai.tgz | grep 'dify/charts/'   # must list postgresql, redis, weaviate
```
## 5. Import

- Tools & Frameworks -> Import Framework -> upload the vendored tgz + a logo -> namespace `dify`.
- Fill values (or paste `values-pcai.yaml`). `${DOMAIN_NAME}` is substituted at import.
- Confirm `ezua.authorizationPolicy.providerName` = the cluster's ext-authz provider.

## 6. Post-deploy bring-up (validated sequence)

1. Wait for pods Ready. DB migration runs automatically (`api.migration: true`).
2. **Log in:** Dify uses its **own** email/password auth (separate from PCAI SSO). First access ->
   **create the admin account**.
3. **Install the model provider:** Settings -> Model Provider -> Marketplace -> install
   **OpenAI-API-compatible**. (Needs egress to the Dify Marketplace; on emptyDir it now persists.
   If it fails on egress, install offline via a `.difypkg`.)
4. **Wire Qwen:** add an OpenAI-API-compatible model:
   - Model Name: `Qwen/Qwen3-30B-A3B-Instruct-2507` (must match the endpoint's `/v1/models` exactly)
   - API Base: `https://<qwen-endpoint>/v1`  (https; the MLIS **per-deployment** key — a wrong key -> 403
     "failed to verify token")
   - Model context size: set to the served `max_model_len` (query `/v1/models`; likely ~32K, NOT the
     256K native) — 32768 is a safe value
   - Set it as the **default system model**.
5. **Build an app:**
   - Chat app -> API path `/v1/chat-messages` (matches the D1 smoke test).
   - Workflow app -> API path `/v1/workflows/run`, and it **must be Published**; output is under `data.outputs`.
6. **Validate = a message returns an answer via Qwen** (UI and/or API).

## 7. Validate via API

Use `d1_dify_smoketest_notebook.py`. Fill:
- `DIFY_API_BASE = https://dify.<domain>/v1`  (**https** — http returns 404)
- `DIFY_APP_KEY  = app-...`  (the per-APP key from the app's **API Access** page; not the console login)

## 8. Known issues / caveats (consolidated)

- **Plugin storage vs NFS colons** -> emptyDir default (Option 2). Ephemeral: reinstall provider on daemon restart.
- **S3 unusable** -> VAST cert hostname mismatch (see Storage). Production needs a fixed cert or covered hostname.
- **API scheme** -> the Dify app API only answers over **https**; http 404s.
- **API key type** -> app API needs the `app-` key; the model provider needs the MLIS **per-deployment** key.
- **App type** -> chat vs workflow changes the API path and whether Publish is required.
- **Sandbox** runs arbitrary code with no gVisor RuntimeClass on the trial -> unsandboxed at container level.
  Acceptable for a demo; note as a security caveat.
- **Footprint** ~16 CPU pods (incl. embedded postgres/redis/weaviate), no GPU -> confirm namespace quota.
- **Subcharts must be vendored** before import (see Build).

## 9. values.yaml — what changes

New keys (add): `ezua`, `labels`, `vastCA`.
Modify existing: `externalS3` (default: `enabled: false`), and for Option 1 only, `api`/`worker`/`beat`
`extraEnv`+`extraVolumes`+`extraVolumeMounts` (AWS_CA_BUNDLE mount). Leave built-in postgres/redis/weaviate
and `api.migration: true` at defaults. Full block is in `values-pcai.yaml`.
Refer to the [original repo](https://github.com/BorisPolonsky/dify-helm/blob/master/charts/dify/values.yaml) to find and replace the $APP_SECRET_KEY in the PCAI's values-pcai.yaml.