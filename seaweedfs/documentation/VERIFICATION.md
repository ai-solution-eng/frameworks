# SeaweedFS on HPE Private Cloud AI — Verification

Chart `seaweedfs` v0.1.7 · Image `chrislusf/seaweedfs:4.55` · Namespace `seaweedfs` · Site SE G2

How to prove this deployment works, layer by layer, in the order that isolates a failure fastest. Each step is a command plus the output that means "this layer is fine"; the ladder was run against the live deployment on 2026-11-24 (§ 10). A release that installed without error is not evidence that the stack works. Assumes a `kubectl` context on the cluster, namespace `seaweedfs`, release `seaweedfs` ([DEPLOYMENT.md](DEPLOYMENT.md) § 2), and the package root for the render check; steps 6 and 7 also need a copy of the AIE Root CA ([CLIENTS.md](CLIENTS.md) § 4).

## 1. Render check — the chart produces what you expect

Two read-only commands, safe before an upgrade. The `icon` line is an INFO, not a failure:

```bash
helm lint helm
# ==> Linting helm
# [INFO] Chart.yaml: icon is recommended
# 1 chart(s) linted, 0 chart(s) failed

helm template seaweedfs helm -n seaweedfs | grep -c '^kind:'
# 15
```

The 15 objects, by name:

| Kind | Name |
|---|---|
| Secret | `seaweedfs-s3-config` |
| Service | `seaweedfs-master`, `seaweedfs-volume`, `seaweedfs-filer`, `seaweedfs-filer-client`, `seaweedfs-s3` |
| StatefulSet | `seaweedfs-master`, `seaweedfs-volume`, `seaweedfs-filer` |
| Deployment | `seaweedfs-s3` |
| VirtualService | `seaweedfs-filer`, `seaweedfs-s3` |
| AuthorizationPolicy | `seaweedfs-auth-policy` — in `istio-system`, not the release namespace |
| PodDisruptionBudget | `seaweedfs-volume`, `seaweedfs-s3` |

**A count other than 15 is a values difference, not a broken chart:** `s3.existingConfigSecret` suppresses the Secret (−1); `ezua.s3VirtualService.allowList.enabled=true` adds the DENY policy (+1); `s3.autoscaling.enabled=true` adds the HPA (+1); `metrics.serviceMonitor.enabled=true` adds the ServiceMonitor (+1); `networkPolicy.enabled=true` adds three policies (+3, +4 with allowlists); `backup.enabled=true` adds the CronJob (+1); `ezua.s3VirtualService.enabled=false` removes the S3 VirtualService and, with it, the DENY policy (−1) — [s3-secret.yaml](../helm/templates/s3-secret.yaml), [authorizationPolicy-s3-allowlist.yaml](../helm/templates/authorizationPolicy-s3-allowlist.yaml), [hpa-s3.yaml](../helm/templates/hpa-s3.yaml). The hosted-trial profiles render 15 (ingest window) and 14 (locked): autoscaling on, and the chart Secret suppressed because they use `s3.existingConfigSecret`.

Two values to spot-check in the same render: `grep -c 'timeout:'` must return `0` and `grep -A1 'retries:'` must show `attempts: 0` — a values edit can silently restore a route timeout or proxy retries ([virtualservice-s3.yaml](../helm/templates/virtualservice-s3.yaml)).

**A release installed from 0.1.6 reports `app.kubernetes.io/version: 4.23` while the pod runs `4.55`** — `appVersion` feeds that label (and is the fallback when `image.tag` is empty), while the image comes from `image.tag`. Both read `4.55` since chart 0.1.7, so after a reinstall the label and the image agree; on an older release read the running image in step 2, never the label.

## 2. Pods and PVCs

```bash
kubectl get pods -n seaweedfs -o wide
kubectl get pvc -n seaweedfs
# which image is actually running - the version label does not answer this
kubectl get pods -n seaweedfs -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
```

| Object | Expected |
|---|---|
| `seaweedfs-master-0`, `-filer-0`, `-s3-<hash>` | one pod each, `1/1 Running`, 0 restarts (site values set `s3.replicas: 1`; the chart default is 2) |
| `seaweedfs-volume-0`, `-1`, `-2` | three pods, each `1/1 Running`, 0 restarts |
| `data-seaweedfs-master-0`, `-filer-0`, `-volume-0/1/2` | all `Bound` on `gl4f-filesystem`: 5Gi, 10Gi, and 100Gi each |

A PVC stuck `Pending` with `Quota name must be unique per tenant` is the VAST CSI quota-name collision on reinstall, not a scheduling problem — use a fresh namespace or clear the stale quota ([DEPLOYMENT.md](DEPLOYMENT.md) § 6).

## 3. Services and ports

```bash
kubectl get svc -n seaweedfs
```

| Service | Type | Ports |
|---|---|---|
| `seaweedfs-master`, `-volume`, `-filer` | headless | 9333/19333, 8080/18080, 8888/18888 |
| `seaweedfs-filer-client` | ClusterIP | **8888 and 18888** |
| `seaweedfs-s3` | ClusterIP | 8333 |

**The check that matters is both ports on `seaweedfs-filer-client`:**

```bash
kubectl get svc -n seaweedfs seaweedfs-filer-client \
  -o jsonpath='{range .spec.ports[*]}{.name}={.port}{"\n"}{end}'
# http=8888
# grpc=18888
```

18888 is the filer gRPC port, which `weed s3` derives as the filer port + 10000 ([filer.yaml](../helm/templates/filer.yaml)). With only 8888 published the gateway dials `:18888`, blocks in IAM/bucket init before it ever binds 8333, logs nothing useful and exits 0 on SIGTERM — the failure that cost the most time in this port ([DEPLOYMENT.md](DEPLOYMENT.md) § 6). Prove the ports are reachable, not merely declared, with the in-cluster probe from that same section:

```bash
kubectl run netdiag -n seaweedfs --rm -it --restart=Never --image=busybox:1.36 -- \
  sh -c 'nc -z -w3 seaweedfs-filer-client 8888 && echo 8888 OK; \
         nc -z -w3 seaweedfs-filer-client 18888 && echo 18888 OK'
# 8888 OK
# 18888 OK
```

## 4. The filer metadata store is on the PVC

The filer keeps its namespace in an embedded LevelDB store on `/data`, enabled with `WEED_LEVELDB2_ENABLED=true` ([filer.yaml](../helm/templates/filer.yaml)). If that store lands on the container filesystem instead, the namespace disappears with the pod and every object becomes unreachable while the volume PVCs still look healthy.

```bash
kubectl exec -n seaweedfs seaweedfs-filer-0 -- ls -la /data    # a LevelDB store dir, under /data
kubectl exec -n seaweedfs seaweedfs-filer-0 -- du -sh /data
```

Expected: a store directory under `/data` holding `CURRENT`, `MANIFEST-*` and `*.ldb` files, and a size that grows after step 6 writes objects. If `/data` is empty while the filer has been up for minutes, pin the store with a `filer.toml` (`[leveldb2] enabled = true`, `dir = /data/filerldb2`) before putting data in ([helm/local/values.g2.yaml](../helm/local/values.g2.yaml) gotcha 2, [PORTING.md](../helm/PORTING.md) "First-deploy checks").

## 5. The S3 identity is what you think it is

The gateway authenticates against one JSON document in the `s3-config` Secret ([s3-secret.yaml](../helm/templates/s3-secret.yaml)). Read it back without printing the secret key:

```bash
kubectl get secret seaweedfs-s3-config -n seaweedfs \
  -o jsonpath='{.data.seaweedfs_s3_config}' | base64 -d \
  | jq '.identities[] | {name, accessKey: .credentials[0].accessKey, actions}'
# { "name": "admin", "accessKey": "seaweedfs", "actions": ["Admin","Read","Write"] }
```

Then compare the deployed key with the one your client uses, without echoing either:

```bash
kubectl get secret seaweedfs-s3-config -n seaweedfs \
  -o jsonpath='{.data.seaweedfs_s3_config}' | base64 -d \
  | jq -r '.identities[0].credentials[0].secretKey' | sha256sum
printf '%s' "$S3_SECRET_KEY" | sha256sum      # identical hash = identical key
```

A hash mismatch is the most common cause of `SignatureDoesNotMatch` against an otherwise healthy deployment. If `s3.auth.secretKey` was left empty at install, the key was generated and is regenerated on every upgrade ([values.yaml](../helm/values.yaml)).

## 6. End-to-end S3

```bash
cd seaweedfs
export S3_SECRET_KEY='<the key in the s3-config Secret>'
export S3_CA_BUNDLE=/home/andrew/.dsh/certs/pcai-aie-root-ca.crt   # public host, CLIENTS.md § 4
python3 test_s3_boto3.py
```

Seven steps, each one a different layer:

| Step | Operation | What it proves |
|---|---|---|
| 1 | `create_bucket` | the gateway writes namespace metadata through the filer |
| 2 | `put_object` | bytes reach a volume server and the fileID is registered |
| 3 | `get_object` + byte compare | the read path returns the same bytes, not just a 200 |
| 4 | `list_objects_v2` | the LevelDB namespace lists what was written |
| 5 | 12 MiB multipart (5 MiB threshold and chunk) + `head_object` length check | multipart create/upload/complete survives a multi-chunk upload through the no-timeout, no-retry route |
| 6 | presigned GET URL | the client can sign a URL against the public host |
| 7 | `delete_object` x2 + `delete_bucket` | cleanup works and the run is repeatable |

Observed on 2026-11-24 with `S3_CA_BUNDLE=/home/andrew/.dsh/certs/pcai-aie-root-ca.crt`: **all seven steps passed**, ending on the script's own success line, `ALL CHECKS PASSED` ([test_s3_boto3.py](../test_s3_boto3.py) line 126). Failures print a four-code decoder (lines 137-140); the full table is [CLIENTS.md](CLIENTS.md) § 8.

## 7. SSO on the UI host, and none on the S3 host

Two hosts, two policies, one request each:

```bash
CA=~/.dsh/certs/pcai-aie-root-ca.crt
curl -sS --cacert "$CA" -o /dev/null -w '%{http_code} %{redirect_url}\n' \
  https://seaweedfs.pcai-se-ai-application.hst.rdlabs.hpecorp.net
# 302 https://<keycloak>/realms/UA/...
# the S3 host must not redirect: unsigned means 403
curl -sS --cacert "$CA" -o /dev/null -w '%{http_code}\n' \
  https://seaweedfs-s3.pcai-se-ai-application.hst.rdlabs.hpecorp.net/
# 403
```

A `200` on the first means the oauth2-proxy policy is not being applied — it must sit in `istio-system` and name the UI host ([authorizationPolicy.yaml](../helm/templates/authorizationPolicy.yaml)). A `302` on the second is the reverse failure: SSO was put in front of the S3 host and every S3 client is now broken ([CLIENTS.md](CLIENTS.md) § 2.2).

## 8. Reachability from an app pod

The layer an application actually uses: the ClusterIP Services, from a pod, with no gateway and no CA.

```bash
kubectl run netdiag -n seaweedfs --rm -it --restart=Never --image=busybox:1.36 -- \
  sh -c 'nc -z -w3 seaweedfs-s3 8333 && echo "s3 8333 OK"; \
         nc -z -w3 seaweedfs-filer-client 8888 && echo "filer 8888 OK"; \
         nc -z -w3 seaweedfs-filer-client 18888 && echo "filer-grpc 18888 OK"'
# s3 8333 OK / filer 8888 OK / filer-grpc 18888 OK
```

Then run the same smoke test against the in-cluster endpoint from a pod that has boto3 — no CA bundle, because this path is plain HTTP:

```bash
S3_ENDPOINT=http://seaweedfs-s3.seaweedfs.svc.cluster.local:8333 \
S3_SECRET_KEY='<key>' python3 test_s3_boto3.py
```

## 9. What each check proves

| Check | Proves | A failure means |
|---|---|---|
| 1 render | the chart produces the intended 15 objects | the values or templates differ from this document; nothing below will match |
| 2 pods, PVCs | workloads scheduled, storage bound | scheduling, image pull or VAST quota problem, not an S3 problem ([DEPLOYMENT.md](DEPLOYMENT.md) § 6) |
| 3 services, ports | the gateway-to-filer contract exists and is reachable | the gateway cannot reach filer gRPC and hangs instead of erroring ([DEPLOYMENT.md](DEPLOYMENT.md) § 6) |
| 4 store on `/data` | the namespace survives a pod restart | the metadata store is ephemeral; a restart makes every object unreachable |
| 5 identity Secret | the credential the gateway actually loads | `SignatureDoesNotMatch` or `InvalidAccessKeyId` against a healthy deployment |
| 6 end-to-end S3 | the whole write path: gateway, filer, master, volume | the failing step number names the broken layer |
| 7 SSO split | both hosts carry the policies the chart intends | SSO missing on the UI, or SSO wrongly in front of S3 — every client breaks |
| 8 in-cluster | what an application sees | DNS or Service problem, or a NetworkPolicy the chart does not create |

Deployment-side symptoms — a gateway that never binds 8333, unknown flags, PVCs pending — stay in [DEPLOYMENT.md](DEPLOYMENT.md) § 6 rather than being duplicated here.

## 10. What a green deployment looks like

Observed on **2026-11-24**, HPE PCAI SE G2. An observation for this cluster, not a guarantee for another.

| Item | Observed 2026-11-24 |
|---|---|
| Cluster / domain | `pcai-se-ai-application.hst.rdlabs.hpecorp.net` |
| Namespace / release / chart / image | `seaweedfs` / `seaweedfs` / `0.1.6` (now 0.1.7) / `chrislusf/seaweedfs:4.55` |
| master, filer, s3 | one replica each, all Running on `scs05` |
| volume | 3 replicas: `volume-0` on `scs05`, `volume-1` and `volume-2` on `scs04` |
| Replication | `-defaultReplication=001` — one extra copy on a different volume server in the same rack, 2 copies total |
| PVCs | 5, all Bound on `gl4f-filesystem` (VAST-backed, ReadWriteOnce) |
| Filer UI | `https://seaweedfs.<domain>` returns `302` to keycloak `/realms/UA` |
| S3 host | `https://seaweedfs-s3.<domain>` returns `403 AccessDenied` on an unsigned GET; SigV4 only, path-style |
| Smoke test | `test_s3_boto3.py`: all seven steps passed |
| Chart metadata | installed from 0.1.6, so `appVersion` (label) reads `4.23` while the image runs `4.55`; chart 0.1.7 makes both `4.55` |

## 11. Verify after a change

The full ladder is for a new deployment. After a change, re-run the subset that can be affected.

| Change | Re-run | Why |
|---|---|---|
| Values (replicas, sizes, resources, allowList) | 1, 2, 3, 6 | the rendered objects and the S3 path change; the CA and the SSO split do not. `volume.persistence.size` cannot change on an existing StatefulSet — the upgrade is rejected ([DEPLOYMENT.md](DEPLOYMENT.md) § 2) |
| Image bump (`image.tag`) | 2, 3, 6 | a new image can change the flag set and the filer gRPC behavior; that is what broke the gateway twice ([DEPLOYMENT.md](DEPLOYMENT.md) § 6) |
| Namespace move | 1-8 | every in-cluster DNS name embeds the namespace, and the AuthorizationPolicy is named after the release but lives in `istio-system` — the same release name in a second namespace collides on it ([authorizationPolicy.yaml](../helm/templates/authorizationPolicy.yaml)) |
| Key rotation | 5, 6, 7 | the identity is the change; clients and outstanding presigned URLs break at cutover. A Secret edit does not roll the s3 pod, so restart it and confirm the step 5 hashes match |
