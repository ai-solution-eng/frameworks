# OpenBao for HPE AI Essentials (PCAI)

Chart: `openbao` 0.1.0 · OpenBao 2.7.3 · upstream chart `openbao` 0.30.8 (vendored)

This chart imports [OpenBao](https://openbao.org), the MPL-2.0, Linux Foundation-governed fork of
HashiCorp Vault, into HPE AI Essentials as a framework tile. It gives PCAI one place to manage
workload credentials (MinIO or SeaweedFS S3 keys for Spark and Airflow, model-registry tokens, LLM provider
keys) instead of creating Kubernetes Secrets by hand in each project namespace.

For how this chart was built from the upstream chart and how to upgrade it, see
[PORTING.md](PORTING.md).

---

## Contents

- [Architecture](#architecture)
- [What is configured automatically](#what-is-configured-automatically)
- [Prerequisites](#prerequisites)
- [Import into AI Essentials](#import-into-ai-essentials)
- [First login](#first-login)
- [Consuming secrets from a PCAI namespace](#consuming-secrets-from-a-pcai-namespace)
- [S3 back ends: MinIO or SeaweedFS](#s3-back-ends-minio-or-seaweedfs)
- [Values reference](#values-reference)
- [Operations](#operations)
- [Production hardening](#production-hardening)
- [Troubleshooting](#troubleshooting)
- [Licence](#licence)

---

## Architecture

```
                         ezaf-gateway (TLS, *.DOMAIN_NAME)
  browser ──platform SSO (oauth2-proxy, /ui only)──► VirtualService ──► openbao-active:8200
  bao CLI / ESO / apps ──── /v1/* (OpenBao token auth) ──┘                      │
                                                                                 │
        openbao-0 (runs self-init once) ◄── raft :8201 ──► openbao-1, openbao-2
        auto-unseal: static key in Secret "openbao-seal-key"
        audit log: stdout of each pod

  PCAI project namespace (project-<name> or project-user-<user>)
    SA openbao-reader ─► SecretStore (ESO) ─► ExternalSecret ─► Kubernetes Secret ─► workloads
```

Resource names don't depend on the release name (`fullnameOverride: openbao`):

| Resource | Name |
|---|---|
| Pods | `openbao-0`, `openbao-1`, `openbao-2` |
| In-cluster API (leader) | `http://openbao-active.<namespace>.svc.cluster.local:8200` |
| Headless (Raft peers) | `openbao-internal` |
| External URL | `https://openbao.<DOMAIN_NAME>` |

## What is configured automatically

On its first start, `openbao-0` loads `files/selfinit.hcl` and initializes OpenBao
declaratively. No one handles unseal keys or a root token, and the root token is revoked when
self-init completes. `openbao-1/2` join the cluster through `retry_join` and auto-unseal with
the same static key.

| Item | Details |
|---|---|
| Admin login | userpass user `admin`, policy `aie-admin`; password in Secret `openbao-admin-password` |
| Automation admin | Kubernetes auth role `aie-admin` → SA `openbao-admin` in the OpenBao namespace |
| Secrets store | KV v2 mount `kv`; workload secrets at `kv/pcai/<namespace>/<name>` |
| Workload identity | Kubernetes auth method (TokenReview against the in-cluster API server) |
| Per-project access | Policy `pcai-namespace-read` + role `pcai-namespace`. Any namespace with SA `openbao-reader` can read **only** `kv/pcai/<its own namespace>/*`. New projects need no OpenBao change |
| Backups | Policy and role `snapshot` for the optional snapshot CronJob |
| Audit | File audit device to stdout, collected by PCAI logging |

## Prerequisites

| Requirement | Notes |
|---|---|
| HPE AI Essentials with Import Framework | Tested design against AIE 1.x import rules (manual method) |
| PCAI admin access | Import Framework, Keycloak (optional SSO redirect) |
| Default StorageClass | 3 × 10 Gi PVCs |
| Images reachable or mirrored | `quay.io/openbao/openbao:2.7.3`; optional `ghcr.io/openbao/openbao-snapshot-agent:0.4.5` |
| External Secrets Operator | Needed to consume secrets from Spark, Airflow and KServe. Import it as a separate tile (cluster-scoped CRDs) |
| Helm 3.8+ locally | To lint and package |

## Import into AI Essentials

1. **Air-gapped clusters:** mirror the images and set `openbao.server.image.registry` (for
   example `"${AIRGAP_REGISTRY}"`).
2. **Lint and package:**
   ```bash
   helm lint openbao
   helm template openbao openbao -n openbao > /tmp/render.yaml   # optional review
   helm package openbao                                          # -> openbao-0.1.0.tgz
   ```
3. **Import:** go to *Tools & Frameworks → Import Framework*.
   - Upload `openbao-0.1.0.tgz`.
   - Release name: **`openbao`**. It must equal the pod label `hpe-ezua/app`, or the tile's health shows *Unknown*.
   - Namespace: **`openbao`**.
   - Review values. `${DOMAIN_NAME}` is substituted by AIE.
4. **Optional, seamless SSO:** in Keycloak, go to *Unified Analytics realm → Clients → UA →
   Settings → Valid redirect URIs*, and add `https://openbao.<DOMAIN_NAME>/oauth2/callback`.
5. **Verify:**
   ```bash
   kubectl -n openbao get pods                        # openbao-0..2 Running/Ready
   kubectl -n openbao exec openbao-0 -- bao status    # Initialized true, Sealed false, Seal Type static
   kubectl -n openbao logs openbao-0 | grep -i initializ
   kubectl get svc -n openbao openbao-active
   ```
6. **Back up the seal key outside the cluster.** Without it the data cannot be recovered:
   ```bash
   kubectl -n openbao get secret openbao-seal-key -o yaml > openbao-seal-key.backup.yaml
   ```

## First login

Open the tile (or `https://openbao.<DOMAIN_NAME>`):

| Field | Value |
|---|---|
| Namespace | leave empty (`/ (Root)`) |
| Method | **Username** (not Token) |
| Username | `admin` |
| Password | `kubectl -n openbao get secret openbao-admin-password -o jsonpath='{.data.password}' \| base64 -d` |

**Token alternative** (one-hour admin token):
```bash
JWT=$(kubectl -n openbao create token openbao-admin)
kubectl -n openbao exec openbao-0 -- bao write -field=token auth/kubernetes/login role=aie-admin jwt="$JWT"
```

CLI from a workstation:
```bash
export BAO_ADDR=https://openbao.<DOMAIN_NAME>
bao login -method=userpass username=admin
```

## Consuming secrets from a PCAI namespace

Workloads don't talk to OpenBao directly. External Secrets Operator (ESO, a separate tile) syncs
OpenBao entries into Kubernetes Secrets in each namespace.

1. An admin stores the secret at `kv/pcai/<namespace>/<name>` (UI: **Secrets Engines → kv → Create secret**).
2. In that namespace, create SA `openbao-reader`, a `SecretStore` and an `ExternalSecret`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata: { name: openbao-reader }           # exact name required by role pcai-namespace
---
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata: { name: openbao }
spec:
  provider:
    vault:
      server: http://openbao-active.openbao.svc.cluster.local:8200
      path: kv
      version: v2
      auth:
        kubernetes:
          mountPath: kubernetes
          role: pcai-namespace
          serviceAccountRef: { name: openbao-reader }
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata: { name: <secret-name> }
spec:
  refreshInterval: 1h
  secretStoreRef: { name: openbao, kind: SecretStore }
  target: { name: <secret-name> }
  dataFrom:
    - extract: { key: pcai/<namespace>/<name> }    # all keys of the OpenBao entry
```

3. Workloads consume the resulting Kubernetes Secret as usual (`envFrom`, `secretKeyRef`, volume).

A namespace can only read its own `kv/pcai/<namespace>/*` path. Rotate a credential by saving a
new version in OpenBao; ESO updates the Kubernetes Secret within `refreshInterval`.

## S3 back ends: MinIO or SeaweedFS

OpenBao only stores the credential, so any S3-compatible store works. Store the same three keys
at `kv/pcai/<namespace>/<name>`; only the values differ.

| | MinIO | SeaweedFS |
|---|---|---|
| S3 endpoint (in-cluster) | `http://minio.minio.svc.cluster.local:9000` | `http://seaweedfs-s3.seaweedfs.svc.cluster.local:8333` (check `kubectl get svc -A \| grep -i s3`) |
| Create identity | Console **Identity → Users**, or `mc admin user add` + `mc admin policy attach` | `weed shell` → `s3.configure -user <name> -access_key <ak> -secret_key <sk> -buckets <bucket> -actions Read,Write,List -apply`, or the identities in `s3.json` |
| Create bucket | Console or `mc mb` | `weed shell` → `s3.bucket.create -name <bucket>`, or `aws --endpoint-url ... s3 mb` |
| OpenBao keys | `access_key`, `secret_key`, `endpoint` | same |
| Spark / S3A settings | `fs.s3a.endpoint`, `path.style.access=true`, `ssl.enabled=false` for HTTP | same (path-style is required) |
| Rotation | Change the user's secret, save a new version in OpenBao | Re-run `s3.configure` with a new `-secret_key`, save a new version in OpenBao |
| Snapshot agent (`openbao.snapshotAgent.config`) | `s3Host: minio...:9000` | `s3Host: seaweedfs-s3...:8333`, `s3cmdExtraFlag: "--no-ssl"`; set `s3ExpireDays: ""` if lifecycle rules aren't supported |

Workloads, ExternalSecrets and Spark manifests don't change when you switch back ends. Only the
values stored in OpenBao change.

## Values reference

| Key | Default | Description |
|---|---|---|
| `ezua.virtualService.endpoint` | `openbao.${DOMAIN_NAME}` | External hostname |
| `ezua.virtualService.istioGateway` | `istio-system/ezaf-gateway` | AIE ingress gateway |
| `ezua.authorizationPolicy.paths` | `["/ui","/ui/*","/"]` | Paths behind platform SSO. `[]` = everything, which blocks external CLI/API clients |
| `seal.static.create` | `true` | Generate the seal key Secret (Helm `lookup` keeps it on upgrade). `false` = pre-create it |
| `seal.static.secretName` | `openbao-seal-key` | Must match `openbao.server.volumes` |
| `selfInit.admin.username` | `admin` | userpass admin |
| `selfInit.admin.createPasswordSecret` | `true` | Generate `openbao-admin-password` |
| `selfInit.kvMount` / `kvPrefix` | `kv` / `pcai` | Secret path `kv/pcai/<namespace>/...` |
| `selfInit.readerServiceAccount` | `openbao-reader` | SA name each namespace creates |
| `selfInit.tokenTTL` / `tokenMaxTTL` | `1h` / `4h` | Token lifetimes |
| `openbao.fullnameOverride` | `openbao` | Fixes resource names |
| `openbao.server.ha.replicas` | `3` | Update the `retry_join` blocks if changed |
| `openbao.server.dataStorage.size` | `10Gi` | Raft volume per pod |
| `openbao.server.extraLabels` | `hpe-ezua/*` | `hpe-ezua/app` must equal the release name |
| `openbao.snapshotAgent.enabled` | `false` | Raft snapshots to S3 (MinIO, SeaweedFS) |
| `openbao.serverTelemetry.serviceMonitor.enabled` | `false` | Prometheus scraping |

Self-init settings only take effect on the **first** start. After that, change OpenBao
configuration through the UI, CLI or OpenTofu.

## Operations

| Task | Command |
|---|---|
| Status | `kubectl -n openbao exec openbao-0 -- bao status` |
| Raft peers | `bao operator raft list-peers` (as admin) |
| Audit log | `kubectl -n openbao logs openbao-0 \| grep pcai/<ns>` |
| Restart safely | Delete standbys first (`openbao-2`, `openbao-1`), then `openbao-0`; each auto-unseals |
| Manual snapshot | `bao operator raft snapshot save backup.snap` |
| Restore | `bao operator raft snapshot restore backup.snap` (requires the **same seal key**) |
| Uninstall | Remove the framework. `openbao-seal-key`, `openbao-admin-password` and the PVCs remain; delete them manually only if the data is no longer needed |

## Production hardening

- **Seal:** replace `seal "static"` with `pkcs11` (HSM), `kmip` or `transit`, and run
  OpenBao seal migration. If you deploy with GitOps or `helm template`, set
  `seal.static.create: false` and pre-create the Secret, because `lookup` can't see the
  cluster there and would generate a new key on every render.
- **Recovery keys:** `bao operator rotate-keys -init -key-shares=5 -key-threshold=3 -target=recovery`.
- **Admin:** rotate the admin password after first login, or replace userpass with OIDC (Keycloak).
- **Backups:** enable `snapshotAgent` with a dedicated MinIO or SeaweedFS bucket.
- **Monitoring:** enable the ServiceMonitor; alert on `vault_core_unsealed == 0` and on Raft leadership changes.
- **Least privilege:** keep project S3 identities (MinIO or SeaweedFS) bucket-scoped, one per namespace.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Login page asks for a token | Switch Method to **Username** |
| Tile **Open** inactive | Check `ezua.virtualService` in EzAppConfig; `kubectl logs -n ezapp-system -l control-plane=controller-manager` |
| Tile health *Unknown* | Release name ≠ `hpe-ezua/app` label; fix `openbao.server.extraLabels` and restart the pods |
| `openbao-0` not Ready, log `self-initialization failed` | The failing request is named in the log. Fix it with the CLI as admin. Self-init doesn't re-run |
| Policy `pcai-namespace-read` missing | That request is `allow_failure`. Recreate it from `files/selfinit.hcl` with the accessor from `bao auth list -format=json` |
| `openbao-1/2` not joining | Port 8201 must bypass the Istio sidecar (pod annotations); check `retry_join` errors in the logs |
| SecretStore `InvalidProviderConfig` / 403 | SA isn't named `openbao-reader`, wrong `server` URL, or the namespace is reading another namespace's path |
| `curl .../v1/sys/health` hangs from a project | NetworkPolicy or Istio policy between namespaces |
| `openbao-0` PVC lost, peers intact | Remove `extraArgs` before restarting so it re-joins instead of self-initializing a new cluster |

## Licence

The wrapper templates belong to the chart's authors. The vendored `charts/openbao` and OpenBao
itself are MPL-2.0 (see `charts/openbao/LICENSE`).
