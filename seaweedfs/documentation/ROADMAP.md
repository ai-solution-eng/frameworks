# Roadmap — candidate work, in the order it would pay off

What this package deliberately does not do yet, why it matters, and what each item would take. Nothing here is committed work; it is the queue, ranked by risk removed per unit of effort.

---

## 1. Backup and restore

**The gap:** nothing snapshots the volume or filer PVCs, and the filer claim is a single point of total loss — losing it makes every needle unaddressable even though the bytes are intact. [OPERATIONS.md § 6](OPERATIONS.md#6-backup-and-restore) documents what to snapshot today and admits it is manual.

**What it takes:** a CronJob that either (a) drives `VolumeSnapshot` objects against the filer and volume claims from the same instant, or (b) runs an S3-to-S3 sync to a second target. Option (a) is the only one that is consistent by construction; option (b) is the only one that works without CSI snapshot support. Either way the restore runbook is the deliverable that matters, and it needs to be rehearsed once against a scratch namespace before anyone believes it.

**Why first:** every other item on this list is a feature. This one is the difference between an incident and a loss.

## 2. A filer that can survive its own PVC

**The gap:** the filer runs with embedded LevelDB at one replica. The metadata store is the namespace; there is no second copy and no way to run two filers against it.

**What it takes:** point the filer at an external store (`WEED_*_ENABLED` / `filer.toml` for Postgres, Redis, etcd or TiKV — upstream supports all of them), add the connection values and a Secret, then raise `filer.replicas` above 1. The chart currently hardcodes the LevelDB path via `WEED_LEVELDB2_ENABLED=true` and has no values surface for a store backend.

**Why second:** it removes the largest single-object risk in the release and is the prerequisite for any HA story.

## 3. Master quorum

**The gap:** one master. It holds no irreplaceable data (volume servers re-register), so its loss is a write pause rather than data loss — but a pause is still an outage.

**What it takes:** `master.replicas: 3` already renders a correct `-peers` list automatically, so the chart side is done. What is missing is the operational proof: raft election on a real 3-master set, a documented quorum-loss behaviour, and a PDB so a drain cannot take two masters at once (see § 6).

## 4. Metrics that are actually scrapeable — **shipped**, gateway still uncovered

**Shipped:** `metrics.enabled` now publishes the `-metricsPort` (9327) on the master, volume and filer Services, and `metrics.serviceMonitor.enabled` renders a ServiceMonitor (gated, because it needs the Prometheus Operator CRDs).

**Still missing:** the S3 gateway has no metrics listener at all — `weed s3` in this build accepts only `-port`, `-filer`, `-config`. Re-verify the flag set on a newer image before promising gateway metrics; a tag bump is the one place that could change. A dashboard (volume fill, write errors, filer latency) is also still to write.

## 5. Real identity: STS, multiple identities, per-bucket access

**The gap:** one static identity (`admin`, actions `Admin`/`Read`/`Write`) for the whole deployment. STS temporary credentials are unsupported — the gateway logs `no signing key found for STS service`. There is no per-bucket grant and no way to give a team access to one bucket only.

**What it takes:** a `security.toml` with `jwt.filer_signing.key` for STS, plus a values surface for multiple `identities[]` entries (the Secret already carries an array; only the template is single-identity). Per-bucket authorisation is a larger design question and would need a decision on whether it belongs in the chart or in a fronting proxy.

**Why it is not higher:** the deployment is single-tenant by intent today, and the workaround — one deployment per tenant — is honest and works.

## 6. Disruption and placement controls — **PDBs shipped**, spread still missing

**Shipped:** `podDisruptionBudget.volume` and `.s3` are on by default with `maxUnavailable: 1`, so a node drain takes one volume server at a time and cannot make `001` placement unsatisfiable. Master and filer are deliberately excluded — a PDB on a single replica blocks every drain.

**Still missing:** `topologySpreadConstraints` across nodes, and values for `volume.dataCenter` / `volume.rack` so `010` becomes meaningful on a multi-rack cluster.

## 7. Supply-chain and packaging hygiene

**The gap:** `image.tag` floats on a mutable tag; `Chart.yaml` `appVersion` is stale relative to it; packaging is three hand-typed commands; and there is no automated check that a rendered chart is still the expected 15 objects with the right names.

**What it takes:** `image.digest` support (pin the manifest, keep the tag for readability), a version-bump script that updates `Chart.yaml` + `appVersion` + any packaged artifact together, and `helm unittest` (or a `helm template | grep` smoke test) in CI. The `.helmignore` added with this documentation round is the first piece: site values can no longer enter a packaged chart.

## 8. Values schema and defaults

**The gap:** `resources: {}` for every component means a deployment with no requests or limits unless the site sets them; there is no `values.schema.json`, so a typo in a key is silently ignored by Helm.

**What it takes:** a JSON schema with `additionalProperties: false` for the four component blocks, and defensible default requests/limits derived from the G2 site file (master 100m/256Mi, volume 200m/512Mi, filer 200m/512Mi, s3 100m/256Mi).

## 9. Erasure coding

**The gap:** replication `001` doubles the bytes. SeaweedFS also supports erasure-coded volumes, which trade CPU for capacity and survive more failures per byte stored.

**What it takes:** EC volume creation (`ec.encode` in `weed shell`), a documented capacity model, and an honest statement about the read-path cost. Worth a decision document before any code — EC is not a values toggle.

## 10. An upgrade path to the upstream chart

**The gap:** this chart is scaffolded, not ported ([../helm/PORTING.md](../helm/PORTING.md) explains why). Anyone who later wants upstream's feature set faces a values migration with no map.

**What it takes:** a mapping table from this chart's values to upstream's, plus a note on what upstream provides that this one does not (EC, cloud tiers, filer sync, `weed mount`).

## Deliberately not planned

- **`weed mount` (POSIX filesystem in a pod).** It needs FUSE and privileged access; the platform answer is a CSI driver, not a sidecar in this chart.
- **A bucket browser in the filer UI.** The UI assets are `go:embed`ed — customising means forking SeaweedFS. A custom uploader should use the filer HTTP contract instead (`POST /dir/` multipart with field `file`, `PUT /dir/name`, and `POST /dir/newdir/` with an empty body and no `Content-Type` to mkdir — there is no `?op=mkdir`).
- **Kafka/Hadoop/Cassandra integrations.** Upstream supports them; they are separate products, not this chart's scope.
- **Terminating TLS inside the gateway.** TLS ends at the Istio gateway; the backend is plain HTTP by design and stays that way.

## Suggested order

1. Backup + restore runbook (§ 1) — the only item that prevents a loss.
2. PDBs and topology spread (§ 6) — cheap, and it stops a drain from becoming an outage.
3. Metrics (§ 4) — you cannot tune what you cannot see.
4. External filer store + master quorum (§ 2, § 3) — the HA story, in that order.
5. Everything else as demand appears.
