# Configuration reference — every values key, its default, and what it changes

This chart has exactly one configuration surface: `helm/values.yaml`. Every site decision — hosts, storage, replicas, the S3 credential — is a value; there is no ConfigMap, no mounted tuning file and no `extraEnv` hook. The values are consumed either by the PCAI *Helm Values* editor or by `helm` on the CLI (procedure: [DEPLOYMENT.md](DEPLOYMENT.md)).

Two reference points are used below. **Default** is the value in `helm/values.yaml`. **G2** is the site values in `helm/local/values.g2.yaml`, which is what the live SE G2 release runs — chart 0.1.6 rendering image tag `4.55` (`appVersion` reads `4.55` since chart 0.1.7).

Read §1 for the knob, §2 for what the process actually receives, §4 before touching the credential, and §6 before changing anything on a live release.

---

## 1. The values surface

### ezua

| key | default | what it changes | when to change it |
|---|---|---|---|
| `ezua.domainName` | `${DOMAIN_NAME}` | Nothing rendered — no template reads it. It is the anchor that the PCAI import flow and the CLI `envsubst` step substitute into. | Only if the platform's expected `ezua` block shape changes. Changing this key alone changes no object. |
| `ezua.virtualService.endpoint` | `seaweedfs.${DOMAIN_NAME}` | Host on the filer-UI `VirtualService` **and** the host the oauth2-proxy `AuthorizationPolicy` matches. | When the UI hostname must differ; the new host needs DNS. |
| `ezua.virtualService.istioGateway` | `istio-system/ezaf-gateway` | Gateway the UI `VirtualService` attaches to. Rendered with `required`, so empty fails the render. | Only on a platform whose gateway is not `ezaf-gateway`. |
| `ezua.s3VirtualService.enabled` | `true` | Creates the public S3 `VirtualService`. `false` leaves the S3 API cluster-internal only. | Turn off where S3 is only ever consumed in-cluster. |
| `ezua.s3VirtualService.endpoint` | `seaweedfs-s3.${DOMAIN_NAME}` | Host on the S3 `VirtualService` and in the optional DENY policy. This is also the URL clients sign against. | When the S3 hostname must differ; DNS and every client config must follow. |
| `ezua.s3VirtualService.istioGateway` | `istio-system/ezaf-gateway` | Gateway the S3 `VirtualService` attaches to; `required`. | Same as the UI gateway. |
| `ezua.s3VirtualService.timeout` | `""` (key omitted) | Route timeout on the S3 route. Empty renders no `timeout` key, which Istio treats as disabled. | Set a duration such as `3600s` only to hard-cap uploads. Never `0s` (§5). |
| `ezua.s3VirtualService.allowList.enabled` | `false` | Adds the `DENY` `AuthorizationPolicy` that rejects sources outside `cidrs` on the S3 host only. | Any internet-facing S3 host with a known client egress range. |
| `ezua.s3VirtualService.allowList.cidrs` | `[]` | Source ranges the DENY policy exempts, rendered literally. An empty list with `enabled: true` renders a DENY rule that exempts nothing, so no source reaches the S3 host. | Together with `enabled: true`, and always with at least one CIDR. |
| `ezua.authorizationPolicy.enabled` | `true` | Creates the `CUSTOM` policy that routes the UI host through `oauth2-proxy`. The S3 host is not covered. | Only where SSO is terminated somewhere else. |
| `ezua.authorizationPolicy.namespace` | `istio-system` | Namespace the policy is created in; it must be the gateway's namespace. | Never, on PCAI. |
| `ezua.authorizationPolicy.providerName` | `oauth2-proxy` | `provider.name` in the CUSTOM policy; must match the provider registered on the gateway. | Only if the platform renames the provider. |

### name, image and storage class

| key | default | what it changes | when to change it |
|---|---|---|---|
| `nameOverride` | `""` | Replaces the chart name in `app.kubernetes.io/name` and in the computed fullname. | Rarely — it renames every object (§6). |
| `fullnameOverride` | `""` | Replaces the computed fullname outright; Services, StatefulSets, PVC prefixes and the S3 Secret name all follow. | Only before a first install. |
| `image.registry` | `""` | Prefixes the image reference as `<registry>/<repository>:<tag>`. Empty pulls from Docker Hub. | Air-gapped clusters: the internal mirror (e.g. `172.28.1.64/ezmeral-common`). |
| `image.repository` | `chrislusf/seaweedfs` | Image path. | Only when mirroring under a different repo path. |
| `image.tag` | `"4.55"` | Image tag. When empty the helper falls back to `Chart.AppVersion`. | When moving to a new SeaweedFS build; forces a rollout. |
| `image.pullPolicy` | `IfNotPresent` | Pull policy on every pod. | `Always` when a mutable tag must be re-pulled; `Never` on nodes with the image preloaded. |
| `storageClass` | `gl4f-filesystem` | `storageClassName` on all three `volumeClaimTemplates` (`ReadWriteOnce`, one PVC per replica). Empty leaves the cluster default. | Before first install; immutable afterwards (§6). |

### master

| key | default | what it changes | when to change it |
|---|---|---|---|
| `master.enabled` | `true` | Renders the master headless Service and StatefulSet. | Never in a working install. |
| `master.replicas` | `1` | Master pods. Above 1 the template also renders a `-peers` list for every replica. | 3 for a real quorum; 1 is a single point of failure. |
| `master.port` | `9333` | HTTP port: `-port`, the Service `http` port, and the `-master=` address volume and filer dial. | Only to resolve a port conflict; the gRPC port must move with it (§2). |
| `master.grpcPort` | `19333` | Service `grpc` port and the port in the `-peers` list. Never passed as a flag. | Keep at `port + 10000` (§2). |
| `master.metricsPort` | `9327` | `-metricsPort` on the master process. Nothing scrapes it (§5). | Only if 9327 collides inside the pod network namespace. |
| `master.defaultReplication` | `"000"` | `-defaultReplication` on the master **and** `-defaultReplicaPlacement` on the filer: **how many copies of each volume** exist, and where. Independent of `volume.replicas`, which counts servers. | `001` with 3 volume servers in one rack. Digit order is load-bearing (§5). |
| `master.volumeSizeLimitMB` | `1000` | Size, in MB, at which the master stops filling a volume and allocates a new one. | Larger for fewer, bigger volumes. Existing volumes are not resized. |
| `master.persistence.size` | `5Gi` | Size of `data-seaweedfs-master-0`, which holds `-mdir=/data`. | Before first install only (§6). |
| `master.resources` | `{}` | Container requests and limits. `{}` sets none. | Always, for anything beyond a smoke test. |

### volume

| key | default | what it changes | when to change it |
|---|---|---|---|
| `volume.enabled` | `true` | Renders the volume headless Service and StatefulSet. | Never in a working install. |
| `volume.replicas` | `3` | Volume servers, one PVC each. This is where the bytes live. **Not a replication factor**: the data is sharded across the servers, and the copies come from `master.defaultReplication` (see [ARCHITECTURE.md](ARCHITECTURE.md#3-where-the-bytes-live)). | Capacity and placement planning; new replicas get new PVCs, and scaling *down* removes a server's shard. |
| `volume.port` | `8080` | `-port` and the Service `http` port. | Only to resolve a port conflict; the gRPC port must move with it. |
| `volume.grpcPort` | `18080` | Service `grpc` port only; never a flag. | Keep at `port + 10000`. |
| `volume.metricsPort` | `9327` | `-metricsPort`. Nothing scrapes it (§5). | Rarely. |
| `volume.maxVolumes` | `0` | `-max`: volume slots per server; `0` means unlimited. | Cap volumes per server on small PVCs. |
| `volume.minFreeSpacePercent` | `1` | `-minFreeSpacePercent`: a volume server stops accepting writes below this percentage of free space on `/data`. | Raise to leave headroom for compaction; too high strands capacity. |
| `volume.compactionMBps` | `50` | `-compactionMBps`: throughput cap for needle compaction. | Lower on shared storage so compaction does not starve writes. |
| `volume.readMode` | `"proxy"` | `-readMode`: how a volume server serves a read for data it does not hold — `proxy` forwards it internally instead of redirecting the client. | Only with a network reason; `proxy` keeps the client on one host. |
| `volume.dataCenter` | `""` | `-dataCenter`: topology coordinate used by replication placement. Omitted from argv when empty. | Set when the cluster spans data centers and `100`-class replication must place. |
| `volume.rack` | `""` | `-rack`: the rack coordinate. Omitted from argv when empty. | Set so `010`-class replication can place. |
| `volume.persistence.size` | `100Gi` | Size of each `data-seaweedfs-volume-N`. | Before first install only (§6). |
| `volume.resources` | `{}` | Requests and limits; `{}` sets none. | Always, beyond a smoke test. |

### filer

| key | default | what it changes | when to change it |
|---|---|---|---|
| `filer.enabled` | `true` | Renders both filer Services and the filer StatefulSet. | Never in a working install. |
| `filer.replicas` | `1` | Filer pods, each with its own PVC and its own embedded LevelDB. | Keep at 1 unless the metadata store moves to a shared backend (§5). |
| `filer.port` | `8888` | `-port`, the Service `http` port on both filer Services, and the `-filer=` address the S3 gateway dials. | Only to resolve a port conflict; the gRPC port must move with it. |
| `filer.grpcPort` | `18888` | `grpc` port on both filer Services — the one whose absence hangs the S3 gateway. Never a flag. | Keep at `port + 10000`; never remove it from `filer-client`. |
| `filer.metricsPort` | `9327` | `-metricsPort`. Nothing scrapes it (§5). | Rarely. |
| `filer.persistence.size` | `10Gi` | Size of `data-seaweedfs-filer-0`, which holds the LevelDB namespace. | Before first install only (§6). |
| `filer.resources` | `{}` | Requests and limits; `{}` sets none. | Always, beyond a smoke test. |

### s3

| key | default | what it changes | when to change it |
|---|---|---|---|
| `s3.enabled` | `true` | Renders the S3 Service, Deployment and config Secret; also gates the S3 `VirtualService`. | Only to run storage without an S3 gateway. |
| `s3.replicas` | `2` | Gateway pods. The gateway is stateless, so this is a plain Deployment scale. G2 runs `1`. **Ignored while `s3.autoscaling.enabled` is true** — the Deployment then omits `spec.replicas` so a `helm upgrade` cannot fight the HPA. | Scale with client concurrency, or turn on autoscaling instead. |
| `s3.autoscaling.enabled` | `false` | Renders an `autoscaling/v2` HorizontalPodAutoscaler for the S3 Deployment. Only the gateway is autoscalable: the volume servers own PVCs and the filer embeds its metadata store. | Ingest bursts, or read concurrency that varies by orders of magnitude. |
| `s3.autoscaling.minReplicas` | `2` | HPA floor. | Keep ≥ 2 so a node drain cannot take the front door to zero. |
| `s3.autoscaling.maxReplicas` | `8` | HPA ceiling. Past a point more gateways only queue: the single-replica filer and the volume servers' disks are the real ceiling. | Raise for many concurrent clients, not for more throughput. |
| `s3.autoscaling.targetCPUUtilizationPercentage` | `70` | CPU target as a percentage of `s3.resources.requests.cpu`. **A target with no CPU request fails the render** — utilisation of nothing is unmeasurable. | Lower for latency headroom, higher to keep pods hot. |
| `s3.autoscaling.targetMemoryUtilizationPercentage` | `""` | Optional second metric; requires `s3.resources.requests.memory`, else the render fails. | Workloads with large in-flight buffers. |
| `s3.autoscaling.scaleDownStabilizationSeconds` | `300` | How long the HPA waits before removing a pod. Scale-up is immediate (`0s` window, +100%/30s or +2 pods/30s). | Longer for spiky ingest, shorter to reclaim capacity. |
| `s3.port` | `8333` | `-port`, the Service port, and the `VirtualService` destination port. | Only to resolve a port conflict; every client must follow. |
| `s3.domainName` | `""` | **Nothing.** Kept for documentation; `weed s3` has no `-domainName` and the value is never passed to the container (§5). | Never — it cannot take effect. |
| `s3.auth.accessKey` | `seaweedfs` | `accessKey` in the generated identity JSON. | Per site. Changing it breaks clients that hold the old key. |
| `s3.auth.secretKey` | `""` | `secretKey` in the chart-generated identity JSON. Empty means `randAlphaNum 32` at render time — a new key on every upgrade (§4). **Fallback path only:** prefer `s3.existingConfigSecret`. | Only when you cannot create a Secret yourself — and then set it explicitly, never leave it empty. |
| `s3.existingConfigSecret` | `""` | Suppresses the chart-created Secret and makes the s3 pod mount the Secret you name here, under that name. With it set, `s3.auth.*` renders nothing (§4). **The recommended path**: the credential never enters a values document and rotation needs no Helm. | Always, except throwaway deployments. |
| `s3.probes.livenessInitialDelaySeconds` | `120` | Liveness probe delay. With `periodSeconds: 20` and the failure threshold, the first kill is about four minutes after start. | Lower only if you do not need to read startup logs first. |
| `s3.probes.livenessFailureThreshold` | `6` | Consecutive failures before the container is killed. | Lower for faster self-heal; higher to preserve evidence. |
| `s3.resources` | `{}` | Requests and limits; `{}` sets none. | Always, beyond a smoke test. |

**`resources: {}` means the chart sets no requests and no limits.** `toYaml` of an empty map renders `{}`, so nothing reserves CPU or memory for the pod and there is no limit to hit. That is the default for all four components. The G2 site values are the example to copy:

| component | requests | limits |
|---|---|---|
| master | `cpu: 100m`, `memory: 256Mi` | `memory: 512Mi` |
| volume | `cpu: 200m`, `memory: 512Mi` | `memory: 1Gi` |
| filer | `cpu: 200m`, `memory: 512Mi` | `memory: 1Gi` |
| s3 | `cpu: 100m`, `memory: 256Mi` | `memory: 512Mi` |

Source: `helm/local/values.g2.yaml`. Only memory is limited there — no CPU limit, so a busy component may use spare CPU but is never throttled.

### securityContext

| key | default | what it changes | when to change it |
|---|---|---|---|
| `securityContext.enabled` | `true` | Applies the pod- and container-level blocks below to all four workloads (and the backup job). Every workload binds only unprivileged ports, so none of it needs root. **The one dependency is the storage driver applying `fsGroup`** — a driver that ignores it leaves the pods Running but never Ready, with `permission denied` writing `/data`. | Turn **off** only on a driver that does not support `fsGroup`. |
| `securityContext.pod.runAsNonRoot` | `true` | Sets `runAsNonRoot` on the pod. **The render fails if this is true and `runAsUser` is empty** — the image's default user is root, so the container would abort at start. | Rarely. |
| `securityContext.pod.runAsUser` / `runAsGroup` | `1000` | The uid/gid the process runs as. | Match the ownership of the files already on the PVCs. |
| `securityContext.pod.fsGroup` | `1000` | Makes the PVCs writable by `runAsUser`. Requires the CSI driver to apply it — check `kubectl get csidriver -o custom-columns=NAME:.metadata.name,FSGROUP:.spec.fsGroupPolicy`: `File` and `ReadWriteOnceWithFSType` both work for RWO filesystem claims (VAST on SE G2 is the latter), `None` does not. | Only on a driver that reports `None`. |
| `securityContext.pod.fsGroupChangePolicy` | `OnRootMismatch` | Chowns only when the volume root's group is wrong, instead of on every mount. | Never, unless a driver misbehaves. |
| `securityContext.pod.seccompProfile.type` | `RuntimeDefault` | The seccomp profile required by the `restricted` profile. | Never. |
| `securityContext.container.allowPrivilegeEscalation` | `false` | Blocks setuid escalation. | Never. |
| `securityContext.container.capabilities.drop` | `["ALL"]` | Drops every Linux capability. | Never — the processes bind high ports only. |
| `securityContext.container.readOnlyRootFilesystem` | `false` | Read-only container root. Left off because compaction may write scratch files outside `/data`. | Only after confirming the pods stay healthy with it on. |

### metrics

| key | default | what it changes | when to change it |
|---|---|---|---|
| `metrics.enabled` | `true` | Publishes the existing `-metricsPort` (9327) on the master, volume and filer **Services** and declares the container port. Before this, the listeners were bound inside the pods and reachable from nowhere. | Turn off only if something conflicts on 9327. |
| `metrics.serviceMonitor.enabled` | `false` | Renders a `monitoring.coreos.com/v1` ServiceMonitor. **Off because it needs the Prometheus Operator CRDs** — on a cluster without them the release fails to install. | Clusters running the Prometheus Operator. |
| `metrics.serviceMonitor.interval` | `30s` | Scrape interval. | Match your Prometheus. |
| `metrics.serviceMonitor.additionalLabels` | `{}` | Labels so an existing Prometheus selects the object (most operators select by label). | Almost always, on clusters that use one. |
| `metrics.serviceMonitor.namespace` | `""` | Namespace for the ServiceMonitor; empty = the release namespace. | When the Prometheus CR lives elsewhere. |

The S3 gateway is not covered: `weed s3` in this build accepts only `-port`, `-filer` and `-config`, so it has no metrics listener at all.

### podDisruptionBudget

| key | default | what it changes | when to change it |
|---|---|---|---|
| `podDisruptionBudget.volume.enabled` | `true` | A PDB for the volume servers. | Never — this is what keeps a node drain to one server at a time. |
| `podDisruptionBudget.s3.enabled` | `true` | A PDB for the S3 gateway. | Never. |
| `podDisruptionBudget.master.enabled` / `filer.enabled` | `false` | PDBs for the single-replica components. **Off on purpose**: with one replica a PDB blocks every drain and the node can never be emptied. | Only if you move the filer to a shared metadata store and raise its replicas. |
| `podDisruptionBudget.*.maxUnavailable` | `1` | How many pods may be evicted at once. `maxUnavailable` rather than `minAvailable` so the budget is safe at any replica count. | Rarely; `1` is the point. |

### networkPolicy

| key | default | what it changes | when to change it |
|---|---|---|---|
| `networkPolicy.enabled` | `false` | Renders a default-deny plus explicit allows for this release's pods. Off because it only helps in a namespace that already enforces default-deny, and enabling it in a permissive namespace adds a failure mode without removing one. | Namespaces with a default-deny posture. |
| `networkPolicy.ingressGatewayNamespace` | `istio-system` | Namespace allowed to reach the filer UI (8888) and the S3 API (8333). | If the ezua gateway lives elsewhere. |
| `networkPolicy.allowFromNamespaces` | `[]` | Extra namespaces allowed to reach the filer and S3 API (app namespaces, the backup job's callers). | Any in-cluster consumer outside this namespace. |
| `networkPolicy.allowFromCIDRs` | `[]` | Extra source ranges allowed to reach the S3 API. | A load balancer in front of the gateway, or a known client range. |
| `networkPolicy.nodeCIDRs` | `[]` | **Calico applies policy to kubelet health probes.** List the node subnet here if readiness probes go unhealthy after enabling. | When probes fail after turning the policy on. |
| `networkPolicy.allowMetricsFromNamespaces` | `[]` | Namespaces allowed to scrape 9327 — a narrower door than `allowFromNamespaces`. | The Prometheus namespace. |
| `networkPolicy.dnsNamespace` | `kube-system` | Where DNS egress is allowed. | Unusual DNS layouts. |

The backup CronJob is the one pod allowed general egress when the policy is on, because its destination can be anywhere.

### backup

| key | default | what it changes | when to change it |
|---|---|---|---|
| `backup.enabled` | `false` | Renders a CronJob that runs `rclone sync` against this release's own S3 API, copying **every bucket** to a remote you configure. | Any deployment whose data must survive the PVCs. |
| `backup.schedule` | `0 2 * * *` | Cron schedule. `concurrencyPolicy: Forbid` means a slow run blocks the next tick rather than overlapping it. | Match your RPO. |
| `backup.suspend` | `false` | Suspends the CronJob without removing it. | Pausing backups during a migration. |
| `backup.source.existingSecret` | `""` | **Required when enabled.** A Secret with keys `accessKey` and `secretKey` for this release's S3 identity. The chart's own `s3-config` Secret stores them inside JSON and cannot be referenced key-by-key, hence a second Secret. | Always. |
| `backup.destination.configSecret` | `""` | **Required when enabled.** A Secret with key `rclone.conf` defining the destination remote. | Always. |
| `backup.destination.remote` | `""` | **Required when enabled.** The destination, e.g. `offsite:seaweedfs-backup`. Objects land under `<remote>/current`. | Always. |
| `backup.transfers` | `8` | rclone parallelism. | Raise for large links, lower to be kind to the source. |
| `backup.checksum` | `true` | Compare by checksum rather than size+mtime. | Never turn off for a backup. |
| `backup.versioning` | `true` | Keeps replaced and deleted objects under `<remote>/_versions/<timestamp>` instead of removing them, so a bad sync is recoverable. | Turn off only if the destination cannot afford the space. |
| `backup.activeDeadlineSeconds` | `21600` | Hard cap on one run. | Raise if a full sync of your data takes longer than six hours. |
| `backup.resources` | `{}` | Job container requests/limits. | Large syncs benefit from a memory request. |

---

## 2. The exact argv each component is launched with

Every pod is started by the image ENTRYPOINT `weed` plus the `args` list in its template; the chart sets no `command:`, so `argv[1]` is the subcommand. Passing a path (`/usr/bin/weed s3`) makes `weed` treat the path as the subcommand and fail. The lists below are the rendered argv at chart defaults, with `<ns>` for the release namespace. Each flag's meaning is the one `weed <component> -h` prints on the running image; [DEPLOYMENT.md](DEPLOYMENT.md) §6 has the one-liner that prints it.

### master — `helm/templates/master.yaml`

```
weed master \
  -ip.bind=0.0.0.0 \
  -port=9333 \
  -mdir=/data \
  -ip=$(POD_NAME).seaweedfs-master.<ns>.svc.cluster.local \
  -defaultReplication=000 \
  -volumeSizeLimitMB=1000 \
  -metricsPort=9327
# when master.replicas > 1, one additional argument:
#   -peers=seaweedfs-master-0.seaweedfs-master.<ns>.svc.cluster.local:19333,...
```

- **`-ip.bind` versus `-ip`** — the first is the listener, the second is the address the master advertises to volume servers and filers. Master and volume advertise pod DNS from `POD_NAME`; the filer advertises `POD_IP`. Changing the advertised address breaks registration and peer discovery.
- **`-mdir=/data`** — raft and volume-registry state on the PVC. Without it that state would live in the container filesystem and vanish on restart.
- **`-defaultReplication` and `-volumeSizeLimitMB`** — defaults applied when a new volume is created, not a description of existing volumes.
- **`-metricsPort`** — binds a metrics listener; see §5 for why it is not reachable.
- **`-peers`** — only at `replicas > 1`, and it must be the complete set. A partial peer list fails to elect and looks like a hang.

### volume — `helm/templates/volume.yaml`

```
weed volume \
  -ip.bind=0.0.0.0 \
  -port=8080 \
  -dir \
  /data \
  -max \
  0 \
  -minFreeSpacePercent=1 \
  -compactionMBps=50 \
  -readMode=proxy \
  -ip=$(POD_NAME).seaweedfs-volume.<ns>.svc.cluster.local \
  -master=seaweedfs-master:9333 \
  -metricsPort=9327
# -dataCenter=... and -rack=... are appended only when the values are set
```

- **`-dir /data` and `-max 0` are two argv items each** — the template passes `-dir` and `/data` separately, same for `-max`. Dropping the `/data` item points the volume store at the container filesystem, which is the one mistake that loses data silently.
- **`-master=` is the flag name** — not `-mserver=`. The value is the master Service, not a pod name.
- **`-max`** — quoted by the template, so `0` arrives as a string but still means unlimited.
- **`-dataCenter` / `-rack`** — omitted when empty. They are the coordinates the master needs to satisfy `100`- and `010`-class replication; leaving them empty is correct for a single rack and fatal for placement that needs them.

### filer — `helm/templates/filer.yaml`

```
weed filer \
  -ip.bind=0.0.0.0 \
  -port=8888 \
  -master=seaweedfs-master:9333 \
  -defaultReplicaPlacement=000 \
  -dirListLimit=100000 \
  -ip=$(POD_IP) \
  -metricsPort=9327
```

- **`-defaultReplicaPlacement` comes from `master.defaultReplication`** — one value, two flags, on two components. Changing the value rolls both.
- **`-dirListLimit=100000` is hardcoded**, not a value; it bounds one directory listing.
- **`-ip=$(POD_IP)`** — the filer advertises its pod IP, not a DNS name, unlike master and volume.
- **The LevelDB store is enabled by environment, not by a flag** (§3). There is no `-defaultStoreDir` on `weed filer`.
- **No gRPC flag exists here** — the process derives its gRPC listener as `port + 10000`, i.e. 18888. That is why `filer-client` must publish both ports, and why the S3 gateway hangs when only 8888 is published.

### s3 — `helm/templates/s3.yaml`

```
weed s3 \
  -port=8333 \
  -filer=seaweedfs-filer-client:8888 \
  -config=/etc/sw/seaweedfs_s3_config
```

**`weed s3` accepts only `-port`, `-filer` and `-config`.** The other three subcommands take a much wider flag set, and carrying any of it over aborts the process during flag parsing (`flag provided but not defined`) before it binds a socket — which is why the gateway once ran, logged nothing and never listened on 8333.

- **`-filer` points at the `-filer-client` Service**, not at the headless filer Service: the gateway needs both 8888 and 18888 reachable there.
- **`-config`** is the mounted Secret file, read when the process starts. Treat a credential change as needing an s3 restart (§6).
- **No `-metricsPort`** — this subcommand does not accept one, so the gateway exposes no metrics through the chart.

---

## 3. Environment variables and mount paths

Three environment variables, all set by the templates, and two mount paths.

| variable | set on | source | why |
|---|---|---|---|
| `POD_NAME` | master, volume | `fieldRef: metadata.name` | feeds `-ip=$(POD_NAME).<service>.<ns>.svc.cluster.local`, so each replica advertises its own DNS name. |
| `POD_IP` | filer | `fieldRef: status.podIP` | feeds `-ip=$(POD_IP)`; the filer advertises the pod IP. |
| `WEED_LEVELDB2_ENABLED` | filer | literal `"true"` | enables the embedded LevelDB metadata store, which then lives on `/data`. |

No other environment variable is set, and there is no `extraEnv` value: a tuning knob that is not a chart value cannot be injected without editing a template.

| path | component | backing | contents |
|---|---|---|---|
| `/data` | master, volume, filer | the `data` PVC claim (`ReadWriteOnce`, one per replica) | master: raft and volume registry (`-mdir`). volume: the needles (`-dir`). filer: the LevelDB namespace. |
| `/etc/sw` (readOnly) | s3 | Secret `<fullname>-s3-config`, key `seaweedfs_s3_config` | the identity JSON, addressed as `/etc/sw/seaweedfs_s3_config` by `-config`. |

The S3 gateway has no PVC: it is stateless, and everything it stores goes through the filer to the volume servers. Confirm on first deploy that the filer's LevelDB directory really landed under `/data` — the check is in [DEPLOYMENT.md](DEPLOYMENT.md) §2.

---

## 4. The S3 identity config

The gateway's only authentication is a JSON identity file. There is no user database, no IAM service, and no per-bucket ACL anywhere in this chart.

**Recommended pattern: you own the Secret, the chart only names it.** Set `s3.existingConfigSecret` and create the object out of band — the credential never appears in a values document (which is what gets pasted into an editor, attached to a ticket, or packaged into a chart), and rotation is `kubectl apply` + `kubectl rollout restart` with no Helm run at all. The chart-generated Secret below is the fallback for throwaway deployments.

### The JSON the chart writes

```json
{
  "identities": [
    {
      "name": "admin",
      "credentials": [
        { "accessKey": "seaweedfs", "secretKey": "<the key>" }
      ],
      "actions": ["Admin", "Read", "Write"]
    }
  ]
}
```

Schema: `identities[]` holds one object per credential set — `name` is a label, `credentials[]` holds `accessKey`/`secretKey` pairs, `actions[]` is what that identity may do. The chart always writes exactly one identity named `admin` with exactly one credential. The access key is `s3.auth.accessKey`; the secret is `s3.auth.secretKey`, or `randAlphaNum 32` when that value is empty (`helm/templates/s3-secret.yaml`).

### Where it lives

| item | value |
|---|---|
| Secret name | `<fullname>-s3-config` — for release `seaweedfs`, `seaweedfs-s3-config` |
| Key | `seaweedfs_s3_config` |
| Type | `Opaque`, written as `stringData` |
| Mount | `/etc/sw/seaweedfs_s3_config`, readOnly, from `/etc/sw` |
| Consumed by | `weed s3 -config=/etc/sw/seaweedfs_s3_config` |

### What the actions mean here

**The chart grants `["Admin", "Read", "Write"]` and nothing else**, on one identity, with no bucket scoping in the file. In this deployment that means:

- **`Read`** — object and bucket reads: `get_object`, `head_object`, `list_objects_v2`. The smoke test's read and list steps run under it.
- **`Write`** — `put_object`, multipart upload, delete. The test's create, put, multipart and cleanup steps run under it.
- **`Admin`** — the administrative surface (bucket-level and gateway-configuration operations) rather than per-object data access.
- **The practical consequence** — these are full-control credentials over the whole store, not a per-bucket key. Every client that holds them can reach every bucket, and the chart has no second, read-only identity. If a workload needs narrower rights, that is a bring-your-own config, and the `actions[]` list is where the restriction goes.

### Bringing your own identity file

Set `s3.existingConfigSecret` to a non-empty value and the chart stops rendering the Secret — `helm/templates/s3-secret.yaml` is gated on `not .Values.s3.existingConfigSecret`. Your Secret must use the key `seaweedfs_s3_config`, because the mount path and the `-config` flag are hardcoded, not values.

The name the pod mounts is resolved by the `seaweedfs.s3SecretName` helper in `helm/templates/_helpers.tpl` from **the same key**, so the Secret can be called whatever you set `s3.existingConfigSecret` to. (`s3.existingSecret` is still honoured as a legacy alias for the same purpose.)

**Pick a name that cannot collide with the chart's own.** The chart-managed Secret is `<fullname>-s3-config`, and for a release named `seaweedfs` that resolves to `seaweedfs-s3-config` — exactly the name people reach for. It works today (with `existingConfigSecret` set the chart renders no Secret at all), but it leaves a trap: if the release ever goes back to rendering its own Secret, Helm **creates or deletes that object by name** and your credential goes with it. Use a distinct name such as `seaweedfs-s3-identity`.

Verify the mount before you rely on it:

```bash
helm template seaweedfs helm -f /tmp/values.rendered.yaml | grep -A2 'secretName'
```

### The rotation consequence of an empty `s3.auth.secretKey`

**An empty `s3.auth.secretKey` is regenerated on every `helm upgrade`.** The template calls `randAlphaNum 32` at render time and writes the result with `stringData`, so each upgrade overwrites the Secret with a new key. Nothing in the pod template carries a checksum of that Secret, so the pods do not roll — they keep serving the identity they loaded at start until something restarts them, and then every client still holding the old key fails with `SignatureDoesNotMatch`. There is no sticky-value behaviour: the chart never reads the existing Secret back.

What to do: set `s3.auth.secretKey` explicitly (CLI: `--set-string`, so a numeric-looking key is not coerced — see [DEPLOYMENT.md](DEPLOYMENT.md)), or own the file through `s3.existingConfigSecret`. With a fixed value, every upgrade rewrites the same bytes, which is harmless.

A deliberate rotation is a cutover, not a values edit: write the new key, upgrade, then `kubectl rollout restart deployment/seaweedfs-s3` so the gateway reloads the file, and move clients before you drop the old key. The file holds one credential, so there is no overlap window. The runbook is [OPERATIONS.md](OPERATIONS.md) §5.

---

## 5. Keys that do not do what they look like

- **`s3.domainName` is inert.** `weed s3` on this image has no `-domainName` flag and `helm/templates/s3.yaml` never passes the value. The consequence is the useful part: the endpoint is path-style only, which is what a single-host `VirtualService` requires anyway. Setting this key changes no argument and no client behaviour — a client that tries virtual-hosted style (`bucket.host`) fails on DNS and TLS, not on this value.
- **The metrics ports are bound but never scraped.** `master.metricsPort`, `volume.metricsPort` and `filer.metricsPort` are all `9327` and each is passed to its process as `-metricsPort`. But no template declares a `metrics` container port or Service port, and the chart ships no `PodMonitor` or `ServiceMonitor`. The listener exists inside the pod and is reachable from nowhere else, so the value only becomes meaningful once a scrape config is added. All three may share 9327 without conflict only because they are in different pods.
- **`s3.replicas` is inert once autoscaling is on, and the HPA needs three things to work.** `s3.resources.requests.cpu` (else the render fails by design), a running **metrics-server** (else `kubectl get hpa` reports `<unknown>` and the HPA parks at `minReplicas`), and a scale target that is actually the bottleneck — it is not: the filer is a single replica and the volume servers are disk-bound, so the HPA buys concurrency, not throughput. Enabling it also removes `spec.replicas` from the Deployment, which the API defaults to 1 for a moment before the HPA scales back up; expect one short dip when you flip it.
- **`master.defaultReplication` is a placement default, not a guarantee.** The digits are `x` = other data centers, `y` = other racks, `z` = other servers in the same rack. With three volume servers in one rack only `001` can be satisfied — one extra copy on another server in the rack, two copies total. `010` needs a second rack and `100` a second data center; neither places with one rack, and writes then fail. The chart default is `000` (one copy); G2 runs `001` and the live master's argv shows `-defaultReplication=001`. Two further consequences: the same value becomes the filer's `-defaultReplicaPlacement`, and existing volumes keep the placement they were created with, so changing the value does not re-replicate anything (the repair procedure is [OPERATIONS.md](OPERATIONS.md) §2).
- **`volume.persistence.size` — and the master and filer equivalents — is immutable on an existing StatefulSet.** The size lives in `volumeClaimTemplates`, which cannot be patched. An upgrade that changes it is rejected and fails the whole release, not just that component (§6).
- **`ezua.s3VirtualService.timeout` must be omitted or a duration greater than 1 ms.** `"0s"` is not a way to say "no timeout": Istio validates the field as a duration greater than 1 ms and rejects the route at admission, which fails the release. Omitted (the empty string) is the correct disabled state, because the template renders the key only when the value is non-empty. A real cap such as `3600s` is fine.
- **`ezua.domainName` is read by no template.** Only `virtualService.endpoint`, `s3VirtualService.*` and `authorizationPolicy.*` are referenced. The key is the anchor for `${DOMAIN_NAME}` substitution; the hosts that actually render are the two endpoints.
- **`s3.existingConfigSecret` is not a values-level override of the credential.** It suppresses the chart-created Secret and points the mount at the name you give; the Secret must already exist in the release namespace with key `seaweedfs_s3_config`, or the pod fails to start on a missing mount (§4). While it is set, `s3.auth.accessKey` and `s3.auth.secretKey` render nothing, so editing them changes no object.
- **`filer.replicas` above 1 splits the metadata store.** Each replica gets its own PVC and its own embedded LevelDB, and nothing replicates between them: two filers would report different namespaces over the same volume servers. Keep it at 1 unless the store moves to a shared backend.
- **`nameOverride` / `fullnameOverride` rename the whole install.** Object names, PVC names (`data-<fullname>-master-0`) and the S3 Secret name all follow. On a live release this is not a rename but a second deployment alongside the old one.

---

## 6. Safe-change matrix

| change | on a live release | what happens |
|---|---|---|
| `master.replicas`, `volume.replicas`, `s3.replicas`, `filer.replicas` | safe | StatefulSet or Deployment scale. New volume replicas get new PVCs; `master.replicas` also re-renders `-peers`, so every master pod rolls. |
| `image.tag`, `image.repository`, `image.registry`, `image.pullPolicy` | rollout | pod template change; components roll one at a time. |
| `*.resources` | rollout | pod template change. |
| `s3.probes.*` | rollout (s3 only) | pod template change. |
| `s3.autoscaling.*` | no rollout, but the replica count moves | enabling removes `spec.replicas` from the Deployment (the API default of 1 applies briefly until the HPA reacts); disabling renders it again from `s3.replicas` in one step. Pods that stay in the replica set are not restarted. |
| `master.defaultReplication` | rollout, data untouched | master and filer argv change, so both roll; existing volumes keep their placement. |
| `master.volumeSizeLimitMB`, `volume.maxVolumes`, `volume.minFreeSpacePercent`, `volume.compactionMBps`, `volume.readMode`, `volume.dataCenter`, `volume.rack` | rollout | argv change only. |
| `master.port`, `master.grpcPort`, `volume.port`, `volume.grpcPort`, `filer.port`, `filer.grpcPort`, `s3.port` | rollout, and every consumer moves at once | Services, `-master=`/`-filer=` addresses and the `VirtualService` destination all follow in the same release. |
| `s3.auth.accessKey`, `s3.auth.secretKey` | no rollout, but clients break | the Secret is rewritten; pods keep the identity they loaded until restarted (§4). |
| `s3.existingConfigSecret` | rollout when the mounted name changes | the chart stops creating its own Secret and the pod mounts the name you set; a different name is a pod-template change, so the Deployment rolls (§4). |
| `ezua.virtualService.*`, `ezua.s3VirtualService.*`, `ezua.authorizationPolicy.*` | safe | `VirtualService` and `AuthorizationPolicy` update in place; no pod restarts. |
| `storageClass` | **rejected** | it is inside `volumeClaimTemplates`; the StatefulSet patch is refused and the release fails. |
| `master.persistence.size`, `volume.persistence.size`, `filer.persistence.size` | **rejected** | same reason: `volumeClaimTemplates` are immutable. |
| `nameOverride`, `fullnameOverride` | **treat as a new install** | every object and PVC name changes; the old release's PVCs are orphaned, not renamed. |

**What "rejected" means in practice.** Helm submits the new StatefulSet, the API server refuses the patch because `volumeClaimTemplates` differ, and the release fails. The pods keep running — it is a failed upgrade, not an outage — but the release is left failed and the next upgrade has to succeed or be rolled back. To change a size, either expand the PVCs directly (if the storage class allows it) or delete the StatefulSet with `--cascade=orphan` and let the next upgrade re-create it over the existing pods and PVCs.

**The paste that fails most often** is `volume.replicas` and `volume.persistence.size` in the same update. The scale is safe and the size is not, and because both arrive in one release the size rejection fails the scale with it. Split them into two upgrades.

**The S3 key is not a row in this matrix.** Rotating it is a coordinated change: there is one credential in the file, no overlap window, and every existing client breaks as soon as it signs with the old key. Plan it as a credential cutover (§4), not as a values edit.

---

## 7. Related documents

- [DEPLOYMENT.md](DEPLOYMENT.md) — deploy, upgrade, register the endpoint as a PCAI data source, and the symptom → cause → fix table for the failures named here.
- [OPERATIONS.md](OPERATIONS.md) — day-2: what to watch, how to scale, how to repair placement, how to rotate.
- [ARCHITECTURE.md](ARCHITECTURE.md) — why the components are shaped this way: request path, durability, and the two deliberately separate `VirtualService`s.
- [../helm/PORTING.md](../helm/PORTING.md) — what was changed for PCAI and why, including the flags that were removed.
- [../helm/local/README.md](../helm/local/README.md) — where real site values live and what must never be committed.
