# Porting OpenBao to HPE AI Essentials

This file records how the upstream OpenBao Helm chart was turned into a PCAI-compliant framework
tile, why each change was made, and how to repeat the work when upstream releases a new
version. It follows HPE's *Preparing the Framework Helm Chart* guide (manual method).

| | |
|---|---|
| Upstream chart | `openbao/openbao-helm`, chart `openbao` **0.30.8** |
| Application | OpenBao **2.7.3** (`quay.io/openbao/openbao`) |
| Wrapper chart | `openbao` **0.1.0** |
| Import method | Manual (not AutoHelm) |

---

## 1. Approach: a wrapper chart around the vendored upstream chart

```
openbao/                         # wrapper chart (what you import)
├── Chart.yaml                   # depends on openbao 0.30.8
├── values.yaml                  # ezua section + overrides under "openbao:"
├── files/selfinit.hcl           # declarative initialization profile
├── templates/
│   ├── _hpe-ezua.tpl            # HPE label template (from the guide)
│   ├── _helpers.tpl             # openbao-pcai.* helpers
│   ├── ezua/virtualService.yaml
│   ├── ezua/authpolicy.yaml
│   ├── seal-secret.yaml
│   ├── admin-password-secret.yaml
│   ├── admin-serviceaccount.yaml
│   ├── selfinit-configmap.yaml
│   └── NOTES.txt
└── charts/openbao/              # upstream chart, unmodified except tests removed
```

**Why a wrapper instead of editing upstream templates:**
- Upstream stays unmodified, so upgrading means replacing `charts/openbao` and re-checking values (section 6).
- All PCAI-specific logic lives in a small number of files that are easy to review.
- The dependency is **vendored**, so the `.tgz` imports on air-gapped clusters without reaching the Helm repository.

**Why the manual method, not AutoHelm:** the guide says AutoHelm suits charts with a single
service on port 80. OpenBao serves on 8200 and runs as a 3-node StatefulSet with several
Services (`openbao`, `-active`, `-standby`, `-internal`), and the endpoint has to target the
leader specifically.

**Naming rules learned along the way:**
- Helm template names are global across parent and subcharts. Wrapper helpers use the
  `openbao-pcai.*` prefix, never `openbao.*`, to avoid overriding upstream definitions.
- Upstream names resources `<release>-openbao` unless the release name contains "openbao".
  An early build imported as `openbao-aie` produced `openbao-aie-active`. Setting
  `openbao.fullnameOverride: openbao` makes the names independent of the release name.

## 2. AIE compliance mapping

| Guide section | Requirement | Implementation |
|---|---|---|
| Creating the Helm Chart | `templates/ezua/`, `ezua:` section in values | Done |
| Configuring the Application Endpoint | VirtualService on `istio-system/ezaf-gateway`, host `<app>.${DOMAIN_NAME}` | `templates/ezua/virtualService.yaml` → `openbao-active:8200` (leader; standbys would forward anyway) |
| Configuring SSO and Authorization Policy | `CUSTOM` AuthorizationPolicy with provider `oauth2-proxy` on the ingress gateway | `templates/ezua/authpolicy.yaml`, **plus an added `paths` filter** (see 3.4) |
| Keycloak redirect URL | `https://<app>.${DOMAIN_NAME}/oauth2/callback` on client UA | Manual post-install step (README) |
| hpe-ezua labels | `hpe-ezua/app`, `hpe-ezua/type: vendor-service`, at least one `hpe-ezua/component` | `openbao.server.extraLabels` (`component: server`). `_hpe-ezua.tpl` is included as the guide asks |
| GPU workloads / PriorityClass | Only for GPU components | Not applicable (CPU only) |
| Kyverno label policy scope | Must not match all pods in project namespaces | No Kyverno policy is used; labels are set directly on the pod template |
| Placeholders | Use `${DOMAIN_NAME}`, `${AIRGAP_REGISTRY}`… in EzAppConfig values | `${DOMAIN_NAME}` in the endpoint; `${AIRGAP_REGISTRY}` documented for images |

**Known limitation:** upstream's `server.extraLabels` isn't passed through `tpl`, so
`hpe-ezua/app` is the literal `openbao`, not `{{ .Release.Name }}`. Import with release name
`openbao`, or change the value. Otherwise the tile's health shows *Unknown*, because the
EzAppConfig controller selects pods by `hpe-ezua/app=<release>`.

## 3. Changes and design decisions

### 3.1 Disabled upstream components

| Component | Setting | Reason |
|---|---|---|
| Agent injector | `injector.enabled: false` | Consumption is through External Secrets Operator. Injector sidecars on many short-lived Spark executors load OpenBao and complicate Istio start-up ordering |
| CSI provider | `csi.enabled: false` | Same; not required |
| Separate UI Service | `ui.enabled: false` | The UI is served by the server on 8200 and exposed through the VirtualService |
| Chart tests | `templates/tests` removed | Not used by AIE; keeps the import clean |

### 3.2 HA Raft with soft anti-affinity

- `ha.enabled: true`, `replicas: 3`, integrated Raft storage on the default StorageClass.
- Upstream's default **required** pod anti-affinity is replaced with **preferred**. PCAI
  clusters can have fewer than three schedulable workers, and a hard rule would leave pods
  Pending.
- `retry_join` lists `openbao-0/1/2` via `{{ template "openbao.fullname" . }}`, which
  respects `fullnameOverride`.
- The upstream entrypoint `sed`-replaces the literal words `HOSTNAME`, `POD_IP`, `HOST_IP` and
  `API_ADDR` in the config. Don't use these words in comments or values inside
  `ha.raft.config`.

### 3.3 Istio

- TLS is disabled on the OpenBao listener (`global.tlsDisable: true`). External TLS ends at
  `ezaf-gateway`, and in-mesh traffic is protected by Istio mTLS.
- **Port 8201 (Raft/cluster) is excluded from the sidecar** with
  `traffic.sidecar.istio.io/exclude{Inbound,Outbound}Ports: "8201"`. Raft runs its own mutual
  TLS on that port, and intercepting it can stop the cluster from forming.

### 3.4 SSO only on the UI

The guide's AuthorizationPolicy gates the whole host through oauth2-proxy. That would break
every machine client calling `https://openbao.<domain>/v1/*` (the `bao` CLI, external ESO,
CI), because they send OpenBao tokens, not browser SSO cookies. The policy therefore adds
`paths: ["/ui", "/ui/*", "/"]`, so the UI is SSO-gated and the API relies on OpenBao's own
authentication. Set `ezua.authorizationPolicy.paths: []` to restore the guide's
gate-everything behaviour.

In-cluster clients (ESO, Spark, Airflow) use `openbao-active.<ns>.svc:8200` directly and don't
pass through the gateway.

### 3.5 Auto-unseal with the static seal

Manual Shamir unsealing after every pod restart doesn't work for a platform service, and
self-initialization (3.6) **requires** an auto-unseal seal.

- OpenBao's built-in `static` seal uses a 32-byte AES key. `templates/seal-secret.yaml`
  generates it with `randBytes 32` (Helm returns it base64-encoded, so the mounted file holds
  raw bytes, as the static seal expects) and reuses it on upgrade via `lookup`.
- `helm.sh/resource-policy: keep`: uninstalling must never delete the key, or the Raft data
  becomes unrecoverable.
- `lookup` returns nothing under `helm template` and most GitOps renderers, which would rotate
  the key. Those setups must use `seal.static.create: false` with a pre-created Secret.
- Mounted with `defaultMode: 0440`. With `fsGroup`, 0400 would make the file unreadable by
  the `openbao` user.
- Production should migrate to `pkcs11`, `kmip` or `transit` (see README).

### 3.6 Declarative self-initialization (OpenBao ≥ 2.4)

`files/selfinit.hcl` replaces a bootstrap Job. It runs on first start, as the root token,
which is revoked afterwards. It creates admin access, KV v2, Kubernetes auth, snapshot
access, and the per-namespace policy and role.

**It must run on exactly one node.** OpenBao's documentation warns that several
uninitialized nodes self-initializing in parallel cause split-brain, because each would
create its own cluster. The config is therefore a separate file in a ConfigMap
(`openbao-selfinit`), and only pod `-0` loads it:

```yaml
server:
  extraArgs: >-
    $(if [ "${HOSTNAME##*-}" = "0" ]; then echo "-config=/openbao/selfinit/selfinit.hcl"; fi)
```

This works because upstream runs `bao server` inside `sh -ec`, so shell expansion applies.
With `podManagementPolicy: OrderedReady`, `-1` and `-2` start only after `-0` is
initialized and Ready, then join through `retry_join` and auto-unseal.

Other details:
- The HCL is loaded with `.Files.Get` and simple `replace` of `__PLACEHOLDER__` tokens, **not**
  `tpl`. This avoids escaping the `{{identity...}}` ACL templating syntax through Helm and
  Go templates.
- The admin password is read with `eval_source = "file"` from the mounted Secret, so it never
  appears in config or environment variables.
- Audit is configured declaratively (`audit "file" "stdout"` in the server config), because
  OpenBao disables audit-device creation through the API by default.

### 3.7 Namespace-scoped access with one role

Instead of one role per project, a single Kubernetes auth role, `pcai-namespace`, accepts
SA `openbao-reader` from any namespace (`bound_service_account_namespaces=["*"]`). Its
policy is templated on the caller's namespace:

```hcl
path "kv/data/pcai/{{identity.entity.aliases.<k8s-accessor>.metadata.service_account_namespace}}/*" {
  capabilities = ["read"]
}
```

The mount accessor isn't known until the auth method exists, so self-init reads
`sys/auth/kubernetes` and builds the policy string with a **CEL** expression
(`responses.k8s.read_mount.data.accessor`). That request is `allow_failure = true`. If the
response shape differs in a future OpenBao release, initialization still completes, and the
policy can be created by hand (README → Troubleshooting).

This fits PCAI's model, where user (`project-user-<name>`) and shared (`project-<name>`)
namespaces are created dynamically. No OpenBao change is needed per project.

## 4. Validation performed

| Check | Result |
|---|---|
| `values.yaml` YAML parse | OK |
| `ha.raft.config` HCL parse (pyhcl, after substituting the template) | OK |
| `files/selfinit.hcl` HCL parse after placeholder substitution | OK |
| CEL policy expression, evaluated with a sample accessor | Produces the expected two-path ACL |
| Wrapper templates rendered with a stub Go templater for release names `openbao`, `openbao-aie`, `bao` | Valid YAML. VirtualService → `openbao-active`, snapshot SA `openbao-snapshot` |
| `helm lint` / full `helm template` incl. upstream | **Not run in the build environment.** Run before import |
| Live install on PCAI | Pending. Use the checklist below |

### Install test checklist

- [ ] `helm lint openbao` clean; `helm template` renders; the StatefulSet command includes the `extraArgs` self-init snippet (it only takes effect on pod `-0`)
- [ ] Imported with release `openbao`; tile health `ok`; **Open** goes to the UI after SSO
- [ ] `openbao-0` log shows self-initialization completed; `bao status` → `Seal Type static`, unsealed
- [ ] `openbao-1/2` joined (`bao operator raft list-peers` shows 3 voters)
- [ ] Delete `openbao-0`: it comes back unsealed, and a new leader is elected meanwhile
- [ ] UI login with Username `admin`
- [ ] `bao policy read pcai-namespace-read` shows the templated paths
- [ ] ESO in a project namespace syncs `kv/pcai/<ns>/minio`; reading another namespace's path is denied
- [ ] Audit lines appear in `kubectl logs openbao-0`
- [ ] Uninstall keeps `openbao-seal-key`; reinstall reuses the data

## 5. Licensing

- Vault moved to the Business Source License (BSL 1.1) in 2023. Internal customer use is
  permitted, but HPE shipping it as part of a product would need legal review.
- OpenBao is **MPL-2.0**, API-compatible with Vault for these use cases, and ESO's `vault`
  provider and `hvac` work unchanged. This is why OpenBao was chosen for the tile.
- When redistributing, keep `charts/openbao/LICENSE`.

## 6. Upgrading to a new upstream release

1. Fetch the new chart:
   ```bash
   helm repo add openbao https://openbao.github.io/openbao-helm && helm repo update
   helm pull openbao/openbao --version <NEW> --untar -d /tmp/up
   ```
2. Compare values and templates with the vendored copy:
   ```bash
   diff -ru charts/openbao /tmp/up/openbao | less
   ```
   Pay particular attention to:
   - `server.extraArgs`, `extraLabels`, `annotations`, `volumes`/`volumeMounts`, `affinity` (still a `tpl` string?)
   - the `openbao.fullname` / `openbao.name` helpers, `fullnameOverride` handling, and the `-active` Service
   - the entrypoint `sed` substitutions and the `sh -ec` command wrapper, which the self-init `extraArgs` trick relies on
   - `values.schema.json` changes that could reject the wrapper's overrides
3. Replace the vendored chart: `rm -rf charts/openbao && cp -r /tmp/up/openbao charts/ && rm -rf charts/openbao/templates/tests`.
4. Bump `dependencies[0].version` and `appVersion` in `Chart.yaml`, and the wrapper `version`.
5. Read OpenBao release notes for changes to self-init/profiles, the static seal, audit configuration, and the Kubernetes auth response fields.
6. Run the validation and install checklist (section 4) on a test cluster.
7. Upgrade an existing install, standbys first (the StatefulSet uses `OnDelete`): `openbao-2`, `openbao-1`, then `openbao-0`.

## 7. Open items

- Template `hpe-ezua/app` from the release name, for example with a small post-renderer or a Kyverno mutate rule scoped to `app.kubernetes.io/name=openbao` pods only.
- Optional OIDC auth method against Keycloak, using `${OIDC_CLIENT_ID}` / `${OIDC_CLIENT_SECRET}`, to replace userpass.
- Optional `values-production.yaml` with a pkcs11/transit seal and the snapshot agent enabled.
