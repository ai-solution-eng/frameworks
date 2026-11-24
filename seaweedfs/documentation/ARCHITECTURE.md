# Architecture

How the four SeaweedFS processes cooperate on PCAI, where the bytes actually live, and what each failure costs. Everything here is derived from the chart in `helm/` and the observed state of the SE G2 deployment (2026-11-24); the operational procedures are in [OPERATIONS.md](OPERATIONS.md).

---

## 1. The four processes

| Process | Subcommand | Kubernetes object | Owns | Loses everything if its PVC dies? |
|---|---|---|---|---|
| Master | `weed master` | `seaweedfs-master` StatefulSet, headless Service | The volume registry: which volume ids exist, which volume server holds each, and each volume's replication placement. Raft metadata in `-mdir=/data` | No — volume servers re-register |
| Volume server | `weed volume` | `seaweedfs-volume` StatefulSet ×3, headless Service | The bytes. Append-only volume files plus an index under `/data` | **Yes** — for the volumes it holds |
| Filer | `weed filer` | `seaweedfs-filer` StatefulSet, headless Service + `filer-client` ClusterIP | The hierarchical namespace: `path → fileId`. Metadata store is embedded LevelDB on `/data` | **Yes** — the needles survive but become unaddressable |
| S3 gateway | `weed s3` | `seaweedfs-s3` Deployment, ClusterIP Service | Nothing. A stateless translator between the S3 API and the filer | No — any replica can serve any request |

The important asymmetry: **the filer is stateful and the S3 gateway is not.** That is why the gateway is a Deployment that can be scaled or restarted freely, and why the filer is a one-replica StatefulSet whose PVC is the most dangerous object in the release.

## 2. Request paths

### Write (`PUT /bucket/key`)

```
client
  │ SigV4-signed request
  ▼
VirtualService seaweedfs-s3 ──► Service seaweedfs-s3:8333 ──► s3 pod
                                                                 │
  1. filer gRPC :18888  ◄─────────────────────────────────────────┤  create/lookup the path,
     (via filer-client)                                          │  get or mint a fileId
  2. master :9333      ◄─────────────────────────────────────────┤  assign a volume for the fileId
  3. volume :8080      ◄─────────────────────────────────────────┘  append the needle to /data
```

Step 1 is why **port 18888 must be published on the `filer-client` Service**. `weed s3` runs with `-iam=true` by default and reaches the filer over gRPC, deriving that port as `<filer port> + 10000`. With only 8888 published the gateway dials `:18888`, gets connection refused, and blocks in IAM/bucket initialisation **before it binds 8333** — a pod that is Running, logs nothing useful, and never listens. This was the single most expensive bug in the port.

### Read (`GET /bucket/key`)

```
client ──► VirtualService ──► s3 pod ──► filer (path → fileId)
                                    └──► master (which volume server?)
                                    └──► volume server (stream the needle)
```

The volume server's `-readMode=proxy` means a read that lands on a server which does not hold the volume is proxied to the one that does, rather than redirected to the client. The cost is one extra hop; the benefit is that clients never need to resolve volume servers themselves.

### Delete

A delete removes the namespace entry in the filer and marks the needle as deleted in the volume. **Space is reclaimed later, by volume compaction** (`-compactionMBps=50` caps how fast that rewrite happens). Deleting a large tree therefore does not immediately free PVC space — plan capacity for the peak, not the live set.

## 3. Where the bytes live

**Two words that are easy to swap: `volume.replicas` counts servers, `master.defaultReplication` counts copies.** They are independent knobs and neither implies the other.

| Knob | Counts | What it buys | What it costs |
|---|---|---|---|
| `volume.replicas` | **volume servers** (pods, one PVC each) | capacity and parallel write/read paths — volumes are **sharded** across the servers, each volume living on one of them | one PVC and one pod per server |
| `master.defaultReplication` | **copies of each volume**, on different servers | durability: any one volume server can be lost without losing data | doubles the bytes written for the affected volumes, so halves usable capacity at `001` |
| `s3.replicas` / `s3.autoscaling` | **gateway pods** | request concurrency only — the gateway stores nothing | CPU and memory |

Concretely, for three volume servers with 250Gi claims each:

| Configuration | Raw | Usable | Lose one volume server |
|---|---|---|---|
| 3 servers, `000` | 750Gi | 750Gi | **~⅓ of the data is gone** |
| 3 servers, `001` | 750Gi | ~375Gi | data intact; reads continue, writes to volumes that expected the missing copy fail until `volume.fix.replication` |
| 1 server, `000` | 250Gi | 250Gi | everything is gone |

So `volume.replicas: 3` is **not** "three copies of my data" — it is three storage servers that together hold it once, plus whatever `defaultReplication` adds. It is also not a dial you turn down: removing a volume replica removes that server's shard of the data (the PVC stays behind, orphaned, and its volumes become unavailable), which is why autoscaling is confined to the stateless gateway.

- A file becomes one or more **needles** appended to a **volume**. A volume is a large append-only file under `/data` on a volume server's PVC.
- When a volume reaches `master.volumeSizeLimitMB` (1000 MB), the master allocates the **next** volume id for new writes. Old volumes stay readable; they are never rewritten except by compaction.
- `volume.maxVolumes: 0` means no cap on volumes per server; `volume.minFreeSpacePercent: 1` makes the server refuse new volumes before the PVC is actually full, which is the difference between a clean `no space` error and a corrupted write.
- **Capacity arithmetic** (planning, not measured): three 100Gi claims are 300Gi of raw space. With `001` every byte is stored twice, so the usable payload is roughly **half** the raw space — about 150Gi — before counting the 1% free-space reserve and compaction headroom. Size the claims against that number, not against 300Gi.
- The filer's LevelDB store is small (path → fileId entries) but it is on its own 10Gi claim and is the object whose loss is unrecoverable. The master's 5Gi claim holds only the volume index.

## 4. Replication arithmetic

`master.defaultReplication` is a three-digit string `xyz`, where each digit is the number of **additional** copies required in that failure domain:

| Digit | Domain | Meaning |
|---|---|---|
| `x` | other data centers | a copy in a different `dataCenter` |
| `y` | other racks | a copy in a different `rack` |
| `z` | other servers, same rack | a copy on a different volume server in this rack |

With `volume.dataCenter` and `volume.rack` unset, every volume server sits in the default domain — so **only `z` can be satisfied on a single-rack PCAI cluster**. That is why the deployed value is `001` (one extra copy, two copies total, on two different volume servers) and why `010` or `100` are not "more durable": they cannot be placed at all, and an unplaceable placement makes **writes fail**.

Two consequences that are easy to get wrong:

1. **`001` is a write-availability trade.** SeaweedFS writes with `W = N` (write quorum equals the replica count) and reads with `R = 1`. Both copies must be written for the write to succeed, so losing one volume server does not lose data, but writes to volumes that expected the missing copy fail until the topology is repaired. Reads continue from the surviving copy.
2. **The default only applies to new volumes.** Volumes created before the change keep their placement until you run `volume.configure.replication` followed by `volume.fix.replication` — see [OPERATIONS.md § 2](OPERATIONS.md#2-replication).

## 5. Failure matrix

| Failure | Data | Service | Recovery |
|---|---|---|---|
| One volume server down | Survives — the second copy is on another server | Reads continue; writes to affected volumes fail | Bring the server back, or `volume.fix.replication -apply` to re-place the copies |
| One volume PVC lost | Only that server's share; replicated volumes survive on their other copy | Partial | `volume.fix.replication -apply` after the volume server is healthy again |
| All volume PVCs lost | **Total data loss** | Gateway answers, reads fail | Restore from backup (none built in — [ROADMAP.md](ROADMAP.md)) |
| Filer PVC lost | Needles still on disk, namespace gone — **effectively total loss** | All S3 operations fail | Restore the filer PVC; nothing in the chart rebuilds the namespace |
| Master PVC lost | No data loss | Brief write pause | Volume servers re-register; the volume index is rebuilt from their heartbeats |
| S3 pod lost | No impact | None — other replicas serve | Deployment reschedules it |
| Node lost | Depends on which pods it hosted | Volume pods: survives if the copy is elsewhere | RWO PVCs must detach before the pod reschedules — expect a multi-minute wait, not an instant move |
| `helm uninstall` | Survives | Gone | PVCs created by StatefulSets are **not** deleted by Helm; reinstall against the same claims |

## 6. Why the Kubernetes objects look like this

| Choice | Reason |
|---|---|
| StatefulSets for master/volume/filer, Deployment for s3 | The first three own a PVC and need stable identity; the gateway owns nothing |
| Headless Services (`clusterIP: None`) for the three StatefulSets | Stable per-pod DNS for `-ip=<pod>.<svc>.<ns>.svc.cluster.local`, which is how volume servers register a reachable address with the master |
| A separate `-filer-client` ClusterIP Service | The headless Service is for pod identity; clients (the S3 gateway, the VirtualService) need a normal load-balanced name. The name mirrors the upstream chart so future maintainers recognise it |
| **Both** 8888 and 18888 on `filer-client` | 18888 is the gRPC port the S3 gateway's IAM path dials. See § 2 |
| One PVC per replica via `volumeClaimTemplates` | The platform storage class is RWO, so a claim cannot be shared across pods. The consequence — immutable claim templates — is the reason `persistence.size` cannot be changed in place |
| `tcpSocket` probes everywhere | SeaweedFS health endpoints vary by component and version; a wrong HTTP path would restart-loop a healthy pod. The S3 gateway's liveness probe is deliberately lenient (120s, 6 failures) so a stuck gateway can be inspected before it is killed |
| No `command:` override | The image `ENTRYPOINT` is `weed` and appends the chart's `args`, so `args: [s3, ...]` is already `weed s3 ...`. Overriding `command` with a path produced `weed: unknown subcommand "/usr/bin/weed"` |
| No glog flags | `-logtostderr` / `-v` are glog flags; this build rejects them and exits 2. SeaweedFS logs to stdout by default |

## 7. PCAI integration

### Two VirtualServices, one AuthorizationPolicy

```
gateway istio-system/ezaf-gateway
  ├── host seaweedfs.<domain>      ──► VS -filer ──► filer-client:8888
  │      └── AuthorizationPolicy CUSTOM oauth2-proxy   (host-scoped)
  └── host seaweedfs-s3.<domain>   ──► VS -s3    ──► s3:8333
         └── optional AuthorizationPolicy DENY notRemoteIpBlocks  (host-scoped)
```

The split exists because the two consumer classes authenticate differently: browsers can complete an OIDC redirect, SigV4 clients cannot. A single SSO-protected host would satisfy the UI and break every S3 client; a single open host would expose the UI. Host-scoping both policies keeps the blast radius of each at exactly one host — which is also why the allowlist is a `DENY` rather than an `ALLOW` policy (an `ALLOW` on the shared ingressgateway workload would change authorisation for every other host on the gateway).

### Vendor labels

`hpe-ezua/type: vendor-service` and `hpe-ezua/app: seaweedfs` are applied by the `seaweedfs.labels` helper to every resource **and** every pod template. They are deliberately kept out of `selectorLabels`: selectors are immutable on StatefulSets, so keeping them minimal means a future naming change cannot wedge an upgrade.

### Why the chart is scaffolded

The upstream SeaweedFS chart could not be fetched when this port was written (no outbound egress, no vendored chart), so the templates were written from scratch using flags and conventions verified against the upstream templates. The benefit: full control over labels, Services and probes, and no subchart restructuring. The cost: it is not the upstream chart, so an upgrade path to upstream means a values migration — see [../helm/PORTING.md](../helm/PORTING.md).

## 8. Limits and timeouts

| Limit | Value | Where |
|---|---|---|
| S3 route timeout | **disabled** (omitted) | `helm/templates/virtualservice-s3.yaml` — `0s` is rejected by Istio admission |
| S3 route retries | **0 attempts** | same file — a retried write can duplicate an upload or corrupt a multipart completion |
| Filer UI route timeout | Istio default (15s) | `helm/templates/virtualservice.yaml` |
| Filer directory listing | 100 000 entries | `-dirListLimit=100000` |
| Volume size | 1000 MB | `master.volumeSizeLimitMB` |
| Compaction throughput | 50 MB/s | `volume.compactionMBps` |
| Request body size | not set by this chart | anything in front of the gateway (load balancer, proxy) may still cap it |

## 9. Version and image

The running image is `chrislusf/seaweedfs:4.55` (chart `values.yaml` `image.tag`), and since chart 0.1.7 `Chart.yaml` `appVersion` is `4.55` as well — it feeds the `app.kubernetes.io/version` label and is the fallback when `image.tag` is empty, but it never overrides an explicit tag. The chart was originally written against 4.23, and every flag documented in [../helm/PORTING.md](../helm/PORTING.md) was verified against that build; 4.55 accepted the same argv unchanged on this deployment. Treat a future tag bump as "re-verify the argv", not "change the number": the `weed s3` flag set is the part that has historically moved.
