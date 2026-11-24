# Operations

Day-2 procedures for a deployed SeaweedFS release on PCAI: proving it is healthy, repairing replication, scaling, rotating the S3 key, backing up, draining a node, and removing it without losing data. Deployment itself is in [DEPLOYMENT.md](DEPLOYMENT.md); the reasoning behind each component is in [ARCHITECTURE.md](ARCHITECTURE.md).

All examples assume the release is `seaweedfs` in namespace `seaweedfs`.

---

## 1. Health baseline

Five checks, in this order. Anything that fails here makes the rest of this document guesswork.

```bash
# 1. all four workloads Ready
kubectl get pods -n seaweedfs -o wide

# 2. every claim Bound on the platform storage class
kubectl get pvc -n seaweedfs

# 3. the filer Service publishes BOTH ports - 18888 is the one that breaks the S3 gateway
kubectl get endpoints -n seaweedfs seaweedfs-filer-client \
  -o jsonpath='{range .subsets[0].ports[*]}{.name}={.port} {end}{"\n"}'

# 4. the S3 gateway is listening (from inside the cluster)
kubectl run netdiag -n seaweedfs --rm -it --restart=Never --image=busybox:1.36 -- \
  sh -c 'nc -z -w3 seaweedfs-filer-client 8888 && echo 8888 OK; \
         nc -z -w3 seaweedfs-filer-client 18888 && echo 18888 OK; \
         nc -z -w3 seaweedfs-s3 8333 && echo 8333 OK'

# 5. end to end, from a host that can reach the gateway
cd <repo> && export S3_SECRET_KEY=<key> && export S3_CA_BUNDLE=<aie-root-ca.pem>
python3 test_s3_boto3.py
```

Expected: `8888 OK`, `18888 OK`, `8333 OK`, then `ALL CHECKS PASSED`. The observed 2026-11-24 state is recorded in [VERIFICATION.md](VERIFICATION.md).

What to look at when it is not healthy: `kubectl logs -n seaweedfs deploy/seaweedfs-s3` (a gateway that logs only ring updates and never binds 8333 has the missing-18888 problem), `kubectl describe pod` for `Multi-Attach error` (RWO claim still attached to another node), and the failure table in [DEPLOYMENT.md § 6](DEPLOYMENT.md#6-troubleshooting--issues-actually-hit).

## 2. Replication

`master.defaultReplication` is applied **when a volume is created**. Setting `001` on a running release therefore does not give the data you already wrote a second copy — it only governs new volumes. This section is how you verify the placement and how you repair the difference.

### Verify the placement

```bash
kubectl exec -it -n seaweedfs seaweedfs-master-0 -- \
  /usr/bin/weed shell -master=localhost:9333
```

```
> volume.list
```

Each volume line carries a `ReplicaPlacement` field. `001` is the desired value on this deployment; `000` means the volume predates the change and has exactly one copy.

### Configure replication for existing volumes

```
> lock                                   # stop the master from allocating while you work
> volume.configure.replication -replication=001
> unlock
```

`volume.configure.replication` rewrites the placement metadata. It does **not** copy anything yet.

### Copy the data to match

```
> volume.fix.replication                 # dry run - prints what it would copy and delete
> volume.fix.replication -apply          # do it
> volume.list                           # every volume should now read ReplicaPlacement:001
```

Notes that matter before running `-apply`:

- **It is a data-moving operation.** `001` doubles the bytes for the affected volumes; check free space on the volume PVCs first (`kubectl exec -n seaweedfs seaweedfs-volume-0 -- df -h /data`).
- **Writes are `W = N`.** With two copies configured, both must be written for a write to succeed. If a volume server is down, writes to volumes that expected a copy there fail until repair finishes — so repair during a quiet window, not during an incident.
- **It needs somewhere to place the copy.** `001` requires at least two healthy volume servers in the same rack. With `volume.replicas: 1` there is nowhere to put the second copy and the fix will not converge.

### After losing a volume server

1. Confirm the surviving copies: `volume.list` and `cluster.check` from `weed shell`.
2. Get the volume server back (a pod restart is usually enough — the PVC is the state).
3. Run `volume.fix.replication` (dry run), then `-apply`.
4. Re-run the health baseline in § 1. Reads recovered as soon as the surviving copy was reachable; writes recover when the topology is repaired.

## 3. Capacity and scaling

| What you want | Change | Effect |
|---|---|---|
| More raw space and more replica targets | `volume.replicas: 3 → 4` (or more) | StatefulSet scales; one new PVC per new replica; no data is rebalanced automatically |
| More S3 throughput | `s3.replicas` up | Stateless gateway — safe at any time |
| Bigger volumes (fewer per server) | `master.volumeSizeLimitMB` | Applies to newly allocated volumes only |
| Bigger PVCs | **Not an in-place change** | `volumeClaimTemplates` are immutable; a Helm upgrade that changes `volume.persistence.size` fails outright. Grow the PVCs out of band (if the storage class supports expansion) or re-provision |

**Capacity arithmetic:** usable payload ≈ (sum of volume PVCs) / 2 with `001`, minus the 1% free-space reserve and compaction headroom. Three 100Gi claims are ~150Gi of usable data, not 300Gi. Compaction headroom matters most for delete-heavy workloads: compaction rewrites a volume to reclaim deleted needles, and a volume being rewritten needs temporary space.

Adding a volume server does not rebalance existing data. To spread it, use `volume.balance` from `weed shell` (dry run first) — that is a data-moving operation and belongs in a maintenance window.

## 4. Upgrades

### Values-only change

Edit the values in the PCAI *Helm Values* editor (or `helm upgrade -f`) and apply. The pods that consume the changed values roll; the PVCs are untouched.

### Image / chart version change

1. Check the target tag's argv before you deploy it — the flag set is the part that moves between SeaweedFS releases. `kubectl run swdiag -n seaweedfs --rm -it --restart=Never --image=chrislusf/seaweedfs:<tag> -- s3 -h` prints the accepted flags for the S3 subcommand in about five seconds.
2. Roll the S3 gateway first (stateless, cheapest to reverse), then the filer, then the volume servers, then the master. That order keeps the write path up at every step; the reverse order would take the metadata store down under live traffic.
3. Re-run the health baseline in § 1.

The chart's `Chart.yaml` and the image tag can drift apart — `appVersion` is a label, `image.tag` is what runs. Set `image.tag` explicitly and treat `appVersion` as documentation.

## 5. Key rotation

The S3 identity lives in the `<fullname>-s3-config` Secret under key `seaweedfs_s3_config` (JSON: `identities[] → {name, credentials[], actions[]}`), mounted read-only at `/etc/sw/seaweedfs_s3_config`. The gateway reads it **at startup**, so a Secret change alone does not take effect.

**Preferred — and the pattern to deploy with, not just to rotate with: manage the Secret out of band.**

```bash
# 1. write the new identity JSON to a file you do not commit, then
kubectl create secret generic seaweedfs-s3-config -n seaweedfs \
  --from-file=seaweedfs_s3_config=./s3-config.json \
  --dry-run=client -o yaml | kubectl apply -f -

# 2. roll the gateway so it re-reads the config
kubectl rollout restart deployment/seaweedfs-s3 -n seaweedfs
kubectl rollout status deployment/seaweedfs-s3 -n seaweedfs
```

Point the chart at it with `s3.existingConfigSecret: <secret-name>` — the chart then stops creating its own Secret and mounts yours, so a later `helm upgrade` never overwrites your credentials.

**Chart-managed instead:** set `s3.auth.secretKey` and run `helm upgrade`; the Secret is re-rendered and then you still need the rollout restart. Leaving `s3.auth.secretKey` empty is the trap: the chart generates a random key at install **and regenerates it on every upgrade**, breaking every client.

Rotation is a coordinated change — there is one identity per deployment, so every client breaks at the moment the gateway restarts with the new key. Either add the new credential alongside the old one in the `credentials[]` array first, rotate clients, then remove the old entry; or accept a short outage and update all clients in the same window.

## 6. Backup and restore

**There is no backup mechanism in this chart, and nothing snapshots the PVCs.** What exists is the data on two kinds of claim:

| Claim | Contents | Loss means |
|---|---|---|
| `data-seaweedfs-volume-{0,1,2}` | the needles (the bytes) | data loss for volumes without a surviving copy |
| `data-seaweedfs-filer-0` | the namespace (`path → fileId`) | **everything becomes unaddressable** — the most dangerous single object in the release |
| `data-seaweedfs-master-0` | volume index | nothing permanent; rebuilt from volume server heartbeats |

Two viable approaches today, neither of them built in:

1. **Storage-level snapshots.** If the VAST CSI driver exposes a `VolumeSnapshotClass`, snapshot the filer and volume claims together — they must be from the same instant or the namespace will point at needles that are not in the volume snapshot. Confirm the driver's snapshot support on your cluster before relying on this.
2. **S3-level copy.** The deployment is an S3 endpoint, so an S3-to-S3 sync to a second target (another SeaweedFS, MinIO, cloud S3) is the one mechanism this package actually exercises end to end. It re-reads every byte, so it is a throughput problem, not a correctness problem. Test it against a scratch bucket before trusting it, and remember it only copies what the namespace exposes — an orphaned needle is invisible to it.

**Restore** is the reverse: the volume claims and the filer claim must be restored **together**, from the same point in time. Restoring volumes without the filer gives you unaddressable bytes; restoring the filer without the volumes gives you a namespace pointing at nothing.

## 7. Node drains and maintenance

Every SeaweedFS claim is **ReadWriteOnce**. A pod cannot start on a new node until the old node has detached the volume, so a drain produces a `Pending` pod and a `Multi-Attach error for volume ... Volume is already used by pod(s)` event — that is expected, not a broken release.

```bash
# drain the node that hosts a volume server, and keep watching the replacement
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
kubectl get pods -n seaweedfs -o wide -w
```

Rules that keep this boring:

- **Drain one node at a time**, and wait for the volume pods to be `Running` on their new node before draining the next. Two volume servers Pending at once reduces `001` placement to an unsatisfiable target and writes start failing. The `volume` and `s3` PodDisruptionBudgets (`maxUnavailable: 1`) enforce the one-at-a-time part for voluntary evictions — if a drain hangs on a PDB, that is the budget doing its job, not a stuck node.
- **Never drain the node holding `seaweedfs-filer-0` and a volume server at the same time.** The filer is a single replica: while it is down, every S3 operation fails even though the bytes are fine.
- `kubectl cordon` + a planned restart beats an unplanned eviction — the detach is the slow part, and a planned move has no in-flight multipart uploads to corrupt.

## 8. Uninstall and data retention

```bash
helm uninstall seaweedfs -n seaweedfs
kubectl get pvc -n seaweedfs          # the claims survive
```

Helm does not delete PVCs created from `volumeClaimTemplates`, so an uninstall is reversible: reinstall the chart with the same release name and namespace and the new pods adopt the existing claims. The data survives; the workloads, Services, VirtualServices, the `AuthorizationPolicy` in `istio-system` and the chart-created Secret do not.

To actually destroy the data, delete the claims explicitly:

```bash
kubectl delete pvc -n seaweedfs -l app.kubernetes.io/name=seaweedfs
```

Two cautions: the `AuthorizationPolicy` is created in `istio-system`, so the identity that installs (and uninstalls) the release needs write access there; and a reinstall into a **different** namespace does not adopt the old claims — it provisions new, empty ones.

## 9. Monitoring and metrics

The chart passes `-metricsPort=9327` to the master, volume and filer processes, and `metrics.enabled` (default **true**) publishes that port on their Services as a port named `metrics`. What is still missing is a scraper: set `metrics.serviceMonitor.enabled=true` on a cluster running the Prometheus Operator, or point an existing Prometheus at the Services' `metrics` port. With `networkPolicy.enabled`, the scraping namespace must also be in `networkPolicy.allowMetricsFromNamespaces` — a narrower door than `allowFromNamespaces`.

The S3 gateway has no metrics port at all: `weed s3` in this build accepts only `-port`, `-filer` and `-config`.

What to watch without metrics:

| Signal | Where |
|---|---|
| Write path latency and errors | the client's own metrics; the gateway does not log requests |
| Gateway replica count / HPA state | `kubectl get hpa -n seaweedfs` — `TARGETS: <unknown>` means metrics-server is absent and the HPA is parked at `minReplicas` |
| Volume fill level | `df -h /data` inside a volume pod, and `volume.list` volume counts |
| Free-space refusals | volume server logs (`no space` / `minFreeSpacePercent`) |
| Namespace health | filer logs; a `leveldb` error here is an incident |
| Gateway restart count | `kubectl get pods -n seaweedfs` — a restarting gateway means the probes are the only thing that noticed |

## 10. Routine checklist

| Cadence | Check |
|---|---|
| Daily | Pods Ready; no new `Multi-Attach` events; S3 smoke test green |
| Weekly | `volume.list` placement still `001`; PVC usage trend; gateway restart count |
| Monthly | Free-space headroom on the volume claims; verify a restore path exists (even if manual) |
| On every change | [VERIFICATION.md](VERIFICATION.md) § *Verify after a change* |
| On any credential exposure | [§ 5](#5-key-rotation) — rotate, roll, update clients |

---

## 12. Pod security

`securityContext.enabled` applies a `restricted`-profile security context to all four workloads: `runAsNonRoot`, a fixed `runAsUser`/`runAsGroup`, `fsGroup`, `seccompProfile: RuntimeDefault`, `allowPrivilegeEscalation: false`, and every capability dropped.

**It is on by default.** The upstream image runs as root, so this changes the identity of every pod: the processes run as uid/gid 1000 and rely on the storage driver applying `fsGroup: 1000` to the claim so they can write `/data`. Nothing in the chart needs root — every port it binds is unprivileged — so the only question is the driver.

**The failure mode, and it shows up in under a minute:** the pods start, never become Ready, and the logs say `permission denied` on `/data`. That means the driver did not apply `fsGroup`. Roll back with one flag:

```bash
helm upgrade --install seaweedfs helm -n seaweedfs -f <your values> --set securityContext.enabled=false
```

**Verified on SE G2 (2026-11-24):** the platform's VAST drivers declare `fsGroupPolicy: ReadWriteOnceWithFSType`, which means kubelet applies `fsGroup` to **ReadWriteOnce filesystem** volumes — exactly the claims this chart creates (`accessModes: [ReadWriteOnce]`, no `volumeMode`, so `Filesystem`). The check, and the two cases where it would stop applying:

```bash
kubectl get csidriver -o custom-columns=NAME:.metadata.name,FSGROUP:.spec.fsGroupPolicy
```

`File` and `ReadWriteOnceWithFSType` both work for these claims. `None` does not, and neither does `ReadWriteOnceWithFSType` on a **block**-mode volume.

**Existing PVCs written by a root-owned deployment stay root-owned.** `fsGroupChangePolicy: OnRootMismatch` only re-chowns the volume root, so switching an existing deployment in place can fail even on a driver that does support `fsGroup`. Either install fresh, or delete the claims so they are recreated under the new group (this destroys the data), or `chown -R` from inside a root pod before flipping the flag.

### Validate on a scratch namespace

```bash
# 1. a scratch namespace with the same storage class
helm upgrade --install sw-test helm -n sw-sec-test --create-namespace \
  -f <your values>

# 2. do the pods start, and can they write to the claim?
kubectl get pods -n sw-sec-test
kubectl exec -n sw-sec-test <fullname>-volume-0 -- sh -c 'id && touch /data/.probe && ls -l /data/.probe'

# 3. does the whole stack still work?
S3_ENDPOINT=http://<fullname>-s3.sw-sec-test.svc.cluster.local:8333 \
S3_SECRET_KEY=<key> python3 test_s3_boto3.py
```

If step 2 fails with `Permission denied`, the driver is not applying `fsGroup`; stop here and leave the value off.

**Switching a live deployment is harder than installing with it on.** Existing files on the PVCs are owned by root; `fsGroupChangePolicy: OnRootMismatch` only re-chowns the volume root, so a running deployment switched from root to uid 1000 can start failing to write its own data. Prefer enabling this at install time, or plan a recursive `chown` inside the pod before flipping it.

**The render fails fast** if `runAsNonRoot` is true and `runAsUser` is empty — the container would otherwise abort at start with no useful error.

---

## 13. Backup and restore

`backup.enabled` renders a CronJob that runs `rclone sync` against this release's **own S3 API** and copies every bucket to a remote you configure. It is a **logical** backup: object keys and bytes, no volume layout. Restore is a sync back, and it can be verified with the same S3 tooling you already use.

### What it needs

```bash
# 1. the S3 identity as two discrete keys (the chart's s3-config Secret holds them
#    inside JSON, which cannot be referenced key-by-key)
kubectl create secret generic seaweedfs-s3-keys -n <ns> \
  --from-literal=accessKey=seaweedfs \
  --from-literal=secretKey="$(kubectl get secret <fullname>-s3-config -n <ns> \
      -o jsonpath='{.data.seaweedfs_s3_config}' | base64 -d \
      | jq -r '.identities[0].credentials[0].secretKey')"

# 2. an rclone config for the destination
kubectl create secret generic offsite-rclone -n <ns> --from-file=rclone.conf=./rclone.conf
```

```ini
# rclone.conf - the destination only; the source remote is injected by the chart
[offsite]
type = s3
provider = Other
endpoint = https://s3.example.com
access_key_id = <key>
secret_access_key = <secret>
region = us-east-1
force_path_style = true
```

```yaml
backup:
  enabled: true
  source:
    existingSecret: seaweedfs-s3-keys
  destination:
    configSecret: offsite-rclone
    remote: offsite:seaweedfs-backup
```

### Verify, don't assume

```bash
# run one now instead of waiting for the schedule
kubectl create job -n <ns> --from=cronjob/<fullname>-backup backup-manual
kubectl logs -n <ns> -l app.kubernetes.io/component=backup --tail=50

# the destination should now hold one directory per bucket
rclone --config ./rclone.conf lsf offsite:seaweedfs-backup/current
```

### Restore

```bash
# put a bucket's objects back through the same S3 API
rclone --config ./rclone.conf copy offsite:seaweedfs-backup/current/<bucket> src:<bucket> --checksum
```

Restoring the **filer** is not a separate step: the namespace is rebuilt from the object keys as they are written back. That is why the logical backup is sufficient for this architecture and a volume-PVC snapshot is not required to get a working deployment.

### Costs and caveats

- **It reads through the gateway**, so a full sync costs gateway CPU and a long tail of S3 requests. Schedule it off-peak; `backup.activeDeadlineSeconds` (6 h default) stops a runaway.
- **`backup.versioning` keeps replaced and deleted objects** under `<remote>/_versions/<timestamp>`. That is what makes a bad sync recoverable, and it also means the destination grows without bound — prune it deliberately.
- **One remote, one credential.** The backup identity is the same one clients use; if it is rotated ([§ 5](#5-key-rotation)), update the Secret from step 1 in the same window.

---

## 11. Ingest window: open → ingest → lock → rotate

The hosted-trial pattern: the customer brings their data in through the public S3 host, then external access is closed. It is implemented as **two values files that differ by exactly one line** — [../helm/values-examples/values.hosted-trial-ingest.yaml](../helm/values-examples/values.hosted-trial-ingest.yaml) and [...-locked.yaml](../helm/values-examples/values.hosted-trial-locked.yaml) — so the flip cannot carry an accidental revert of `s3.auth.secretKey` or `volume.persistence.size` with it.

### 11.1 Open the window

```bash
# paste the ingest profile in the PCAI values editor, or on the CLI:
helm upgrade --install seaweedfs helm -n seaweedfs -f helm/values-examples/values.hosted-trial-ingest.yaml
kubectl get virtualservice -n seaweedfs seaweedfs-s3      # the public route exists
kubectl get hpa -n seaweedfs                              # TARGETS must not be <unknown>
```

- **Prefer the allowlist over a timed window.** If the customer can name their egress CIDRs, set `ezua.s3VirtualService.allowList.enabled: true` with those ranges in *both* profile files and skip the deadline entirely.
- **The key is a public credential for the duration.** Fresh per trial, `--set-string` on the CLI, never in a file that leaves the machine.
- **The gateway HPA is armed** (`s3.autoscaling`, 2→4 pods in the trial profile and on G2, CPU 70%). It serves requests — it adds no capacity and no copies — and the single-replica filer and the volume servers' disks remain the ceiling.
- **Watch capacity as it fills:** `kubectl exec -n seaweedfs seaweedfs-volume-0 -- df -h /data`. With `001` every byte is written twice, so the usable payload is half the raw claims.

### 11.2 Close it out — before locking, because afterwards the customer cannot resume

1. **Abort incomplete multipart uploads.** Verified on this deployment: an abandoned upload does **not** appear in `list_objects_v2` (so the customer's own check says "nothing landed") but still occupies disk.

   ```python
   ups = s3.list_multipart_uploads(Bucket="uploads").get("Uploads", [])
   for u in ups:
       s3.abort_multipart_upload(Bucket="uploads", Key=u["Key"], UploadId=u["UploadId"])
   print(f"aborted {len(ups)} incomplete uploads")
   ```

2. **Reconcile** object count and total bytes against the customer's manifest.
3. **`volume.fix.replication`** (dry run, then `-apply`) if replication was changed mid-window — see [§ 2](#2-replication).
4. **Record** the bucket/prefix inventory; it is the trial's "before" state.

### 11.3 Lock

```bash
helm upgrade --install seaweedfs helm -n seaweedfs -f helm/values-examples/values.hosted-trial-locked.yaml
```

- The S3 **VirtualService** and its companion `DENY` policy are removed (15 objects → 14). The S3 **Service**, the gateway pods and in-cluster access stay, and **no pod restarts** — only Istio objects change.
- Presigned URLs issued during the window die with the route: they are signed for that host and the host no longer has one.
- The host may still answer `404` at the gateway (DNS resolves, no route). That is the edge refusing, not a data path — do not "fix" it.
- **This does not close every external door.** The filer UI stays up behind SSO and it is a full file browser: it uploads and downloads. If the trial must be read-only externally, that is a separate decision the chart cannot express.

### 11.4 Rotate

The static SigV4 key **survives the lock** — it stays valid for in-cluster callers and for the next re-enable, and it spent the window in shell histories and notebooks. Rotate it as part of the close-out: [§ 5](#5-key-rotation), then update the in-cluster consumers in the same window.

### 11.5 Re-opening later

Every re-enable is a new exposure. Repeat 11.1 → 11.4 in full, rotate the key again, and record the end state in writing ("ingest complete <date>, key rotated, external S3 closed") so a later re-open is a decision rather than a habit.
