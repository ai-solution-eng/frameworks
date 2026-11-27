# Porting External Secrets Operator to HPE AI Essentials

| | |
|---|---|
| Upstream source | `github.com/external-secrets/external-secrets`, tag **v2.15.0**, `deploy/charts/external-secrets` |
| Application image | `ghcr.io/external-secrets/external-secrets:v2.15.0` |
| Wrapper chart | `external-secrets` **0.1.0** |
| Import method | Manual (no endpoint; AutoHelm not applicable) |

## 1. Layout

```
external-secrets/
├── Chart.yaml                 # depends on external-secrets 2.15.0 (vendored)
├── values.yaml                # empty ezua section + overrides under "external-secrets:"
├── templates/
│   ├── _hpe-ezua.tpl          # HPE label template (from the guide)
│   └── NOTES.txt
└── charts/external-secrets/   # upstream chart, prepared as described below
```

The approach matches the OpenBao tile: a thin wrapper around a vendored upstream chart, with
all PCAI specifics in `values.yaml`.

## 2. How the vendored chart was prepared

The chart in the git tag isn't release-ready. The release pipeline generates the CRD
templates and bumps versions. The following was done by hand, mirroring
`hack/helm.generate.sh`:

1. **CRDs generated from `deploy/crds/bundle.yaml`:** 25 CRDs written to
   `templates/crds/<singular>.yaml`.
   - Wrapped in `{{- if .Values.installCRDs }}`. Cluster-scoped kinds and PushSecret use
     `and .Values.installCRDs .Values.crds.create<Kind>`.
   - `served: false` on `v1beta1` of ExternalSecret, SecretStore and the Cluster variants
     became `served: {{ .Values.crds.unsafeServeV1Beta1 }}`.
   - The `crds.annotations` and cert-manager inject block was added under `metadata.annotations`.
   - The bundle contains no `{{`, so no escaping was needed.
2. **`Chart.yaml` pinned** to `version: 2.15.0`, `appVersion: v2.15.0` (the tag carried
   2.14.0).
3. **Optional dependency removed.** `bitwarden-sdk-server` (OCI, `condition:
   bitwarden-sdk-server.enabled`, off by default) was dropped from `Chart.yaml`, and
   `Chart.lock` was deleted. Helm fails on dependencies listed but missing from `charts/`,
   even when they're disabled, and the OCI registry isn't reachable from air-gapped clusters.
4. **Removed:** `tests/`, `ci/`, `README.md.gotmpl` and **`templates/crds/README.md`**. Kept: `LICENSE`.
   Upstream excludes the CRD README through `.helmignore`, but a `.tgz` built with plain `tar`
   doesn't apply `.helmignore`. Helm then parses every file under `templates/` and fails with
   `YAML parse error on .../templates/crds/README.md`. Removing the file makes the chart safe
   however it's packaged.

> **Packaging rule:** build the import `.tgz` with `helm package`, which applies
> `.helmignore` and validates the chart. If you package with `tar`, make sure `templates/`
> (including subcharts) contains only `*.yaml`, `*.yml`, `*.tpl` and `NOTES.txt`:
> ```bash
> find . -path '*/templates/*' -type f ! -name '*.yaml' ! -name '*.yml' ! -name '*.tpl' ! -name NOTES.txt
> ```

## 3. AIE compliance mapping

| Guide section | Implementation |
|---|---|
| `ezua` section | Present and empty. There's no endpoint because ESO has no UI |
| Application endpoint / VirtualService | Not applicable; the tile's **Open** stays inactive |
| SSO / AuthorizationPolicy | Not applicable |
| hpe-ezua labels + component | `podLabels` on the controller, `webhook.podLabels` and `certController.podLabels`, with components `controller`, `webhook` and `cert-controller`. Upstream uses component-specific labels **instead of** `global.podLabels` (if/else), so each is set in full |
| Kyverno scope | No Kyverno policy is used |
| Placeholders | `${AIRGAP_REGISTRY}` documented for `global.repository` |

## 4. Design decisions

- **Istio:** all three pods have `sidecar.istio.io/inject: "false"`. The API server calls the
  webhook directly, and an injected sidecar with STRICT mTLS breaks admission calls. The
  controller doesn't need the mesh to reach OpenBao: plain HTTP to `openbao-active:8200`
  works, and a mesh-enforced STRICT PeerAuthentication on the OpenBao namespace would need a
  matching exception.
- **RBAC aggregation on** (upstream default, kept explicitly). PCAI project members hold
  `edit`-like roles in their namespaces, so they can create SecretStores and ExternalSecrets
  without a cluster admin.
- **Namespaced `SecretStore`, not `ClusterSecretStore`,** in the examples. With the OpenBao
  tile's `pcai-namespace` role, each namespace authenticates as itself, which keeps tenant
  isolation.
- **No cert-manager dependency:** the built-in cert controller manages the webhook certificate.
- **Fixed names** via `fullnameOverride: external-secrets`.

## 5. Validation performed

| Check | Result |
|---|---|
| Wrapper `values.yaml` keys against upstream `values.schema.json` | All keys present |
| 25 generated CRD templates, YAML-parsed with template lines removed | OK |
| No non-template files under `templates/` (find check above) | OK after removing `templates/crds/README.md` |
| `helm lint` / `helm template` | **Not run in the build environment.** Run before import |
| First AIE import | Failed on `templates/crds/README.md` (fixed in this build) |
| Live install | Pending |

### Install checklist
- [ ] `helm lint external-secrets`; `helm template external-secrets external-secrets -n external-secrets | kubectl apply --dry-run=server -f -`
- [ ] Three pods Running, tile health `ok`
- [ ] `kubectl api-resources | grep external-secrets.io` shows `v1`
- [ ] A project user can create an ExternalSecret in their namespace
- [ ] SecretStore against OpenBao is `Valid`; ExternalSecret is `SecretSynced`
- [ ] Reading another namespace's OpenBao path fails with 403

## 6. Upgrading

1. Pick a release tag: `git ls-remote --tags https://github.com/external-secrets/external-secrets.git`.
2. Use the published chart if you can reach it (`helm pull external-secrets/external-secrets --version X --untar`). It already contains the CRD templates, so only step 3 of section 2 is needed. Otherwise repeat section 2 from the tag.
3. Replace `charts/external-secrets`. Update the dependency version and `appVersion` in `Chart.yaml`, and bump the wrapper version.
4. Read the upstream release notes for API version removals (v1beta1 serving is scheduled to be removed upstream entirely) and changes to the Vault provider.
5. Re-run the checklist.

## 7. Licence

ESO is Apache-2.0. Keep `charts/external-secrets/LICENSE` when redistributing.
