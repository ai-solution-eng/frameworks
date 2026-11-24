# Changelog

Chart versions of the `seaweedfs` package for HPE Private Cloud AI. Versions are chart versions; the SeaweedFS image tag is recorded separately because the two have moved independently.

---

## [0.1.7] — 2026-11-24

Packaged as `seaweedfs-0.1.7.tar.gz` from this tree. **It supersedes 0.1.6**, which pins image 4.23 and predates every entry below — including the PodDisruptionBudgets, HPA, securityContext, metrics ports, network policy and backup, none of which exist in that artifact's templates. Importing 0.1.6 with these values would silently ignore the new keys.


### Changed

- **Image tag 4.23 → 4.55** (`values.yaml`, `helm/local/values.g2.yaml`). The argv was re-verified unchanged on 4.55: the S3 gateway still accepts only `-port`, `-filer`, `-config`. `Chart.yaml` `appVersion` now reads `4.55` too (chart 0.1.7): it feeds the `app.kubernetes.io/version` label and is the fallback for an empty `image.tag`, so leaving it at 4.23 was a way to get 4.23 back by accident.
- **Pod security is now the chart default.** A deployment whose storage driver ignores `fsGroup` must set `securityContext.enabled=false`; PVCs written by an earlier root-owned deployment should be regenerated rather than reused.
- **The default render is now 15 objects, not 13**: the two PodDisruptionBudgets are on by default. Every count in [VERIFICATION.md](VERIFICATION.md) § 1 is updated with the per-toggle arithmetic.
- **`helm/templates/s3.yaml`** omits `spec.replicas` when `s3.autoscaling.enabled` is true, so a `helm upgrade` cannot reset the replica count the HPA owns. The default render is unchanged.
- **Replication guidance corrected.** `001` is documented as the strongest placement a single-rack cluster can satisfy (one extra copy on a different volume server in the same rack), replacing the earlier `010` recommendation. `010` needs a second rack and `100` a second data center; neither places on a one-rack PCAI cluster, and an unplaceable placement makes writes fail. Comments in `values.yaml` and `helm/local/values.g2.yaml` updated to match.
- **G2 site values moved to the replicated topology**: `volume.replicas: 3`, `master.defaultReplication: 001`.

### Added

- `README.md` — the package front door: what it is, the problem it solves, the two endpoints and their two auth models, the verified state, and the documentation map.
- `documentation/ARCHITECTURE.md` — components, request paths, replication arithmetic, failure matrix, why each Kubernetes object looks the way it does.
- `documentation/OPERATIONS.md` — health baseline, replication repair, capacity, upgrades, key rotation, backup, node drains, uninstall.
- `documentation/CLIENTS.md` — boto3, aws-cli, rclone and Spark recipes, the CA bundle, multipart, presigned URLs, and a client error decoder.
- `documentation/VERIFICATION.md` — the ordered verification ladder with expected outputs.
- `documentation/CONFIGURATION.md` — every values key, the exact argv per component, and the keys that do not do what they look like.
- `documentation/ROADMAP.md`, `documentation/CHANGELOG.md`, `helm/local/README.md`, `.gitignore`, `helm/.helmignore`.
- **`s3.autoscaling`** — opt-in `autoscaling/v2` HorizontalPodAutoscaler for the stateless S3 gateway (`minReplicas: 2`, `maxReplicas: 8`, CPU target 70%, immediate scale-up, 300 s scale-down window). The Deployment omits `spec.replicas` while the HPA owns it, and the render **fails** if a CPU target is set without a CPU request — an HPA measuring utilisation of nothing reports `<unknown>` forever. Volume servers, filer and master stay non-autoscalable by design: PVCs and an embedded metadata store.
- **`helm/values-examples/`** — `values.hosted-trial-ingest.yaml` and `values.hosted-trial-locked.yaml` (3 × 250Gi volume servers, `001`, 1 GB volumes, gateway HPA armed, `~375Gi` usable), byte-identical except `ezua.s3VirtualService.enabled`, plus the folder README.
- **`securityContext`, ON by default** — every pod runs as uid/gid 1000 with `fsGroup`, RuntimeDefault seccomp, no privilege escalation and all capabilities dropped. Nothing in the chart needs root (all ports are unprivileged); the one dependency is the storage driver applying `fsGroup`, and the failure is visible in the first minute with a one-flag rollback. The render fails if `runAsNonRoot` is set without `runAsUser`.
- **`metrics`** — publishes the already-bound `-metricsPort` (9327) on the master, volume and filer Services, plus an opt-in ServiceMonitor for clusters with the Prometheus Operator CRDs.
- **`podDisruptionBudget`** — `maxUnavailable: 1` budgets for the volume servers and the S3 gateway, on by default. Master and filer are excluded: a PDB on a single replica blocks every drain.
- **`networkPolicy`** — opt-in default-deny plus explicit allows (intra-release, DNS, ezua gateway, configured namespaces/CIDRs, a narrower metrics-only door). Off by default; `nodeCIDRs` exists because Calico applies policy to kubelet probes.
- **`backup`** — opt-in CronJob that `rclone sync`s every bucket to a remote you own, with `_versions/<timestamp>` retention so a bad sync is recoverable. Logical backup; restore is a sync back.
- **The S3 credential moved out of the values documents.** `helm/local/values.g2.yaml` and both trial profiles now ship `s3.auth.secretKey: ""` with `s3.existingConfigSecret` naming a Secret you own (`seaweedfs-s3-identity` — deliberately not `seaweedfs-s3-config`, which is the chart's own default name for a release called `seaweedfs` and therefore an object Helm owns). A values document no longer carries a credential, and rotation is `kubectl apply` + rollout restart with no Helm run.
- **`s3_helper.py`** — a bucket/upload/download/`cat` helper with a CLI, path-style and CA handling built in, for moving data in and out without writing boto3 boilerplate.
- `documentation/OPERATIONS.md` § 11 — the ingest-window runbook: open → ingest → close out → lock → rotate, including the abandoned-multipart cleanup that a bucket listing cannot see.

### Fixed

- **Site values no longer enter a packaged chart.** `helm/.helmignore` now excludes `local/` and `PORTING.md`; before this, every tarball built from this tree contained `local/values.g2.yaml` **including the S3 secret key**. Any tarball built before this change and shared outside the machine must be treated as having disclosed that key — rotate it ([OPERATIONS.md § 5](OPERATIONS.md#5-key-rotation)).
- **`s3.existingConfigSecret` now actually names the mounted Secret.** The `seaweedfs.s3SecretName` helper read `s3.existingSecret` — a key `values.yaml` does not define — so a bring-your-own identity Secret was never mounted under the name the operator set. It now resolves from `s3.existingConfigSecret` first (the legacy `existingSecret` key is still honoured). Rendered with `--set s3.existingConfigSecret=my-s3-identity`, the Deployment mounts `my-s3-identity` and the chart renders 12 objects instead of 13.
- **Stale template comments corrected.** `s3.yaml`, `virtualservice.yaml` and `authorizationPolicy.yaml` still claimed the S3 API was "not exposed through the gateway at all" — true before `virtualservice-s3.yaml` was added, false since. Comments now describe the two-host split.
- Stale comments in `helm/local/values.g2.yaml` (a "must stay 000 while volume.replicas is 1" note that contradicted the `001` two lines below it, a "1 volume server" note on a 3-replica block, and a chart version three releases behind).

---

## [0.1.6] — 2026-11-24

### Fixed

- **The S3 gateway no longer hangs silently on startup.** `filer-client` now publishes the filer's gRPC port **18888** alongside 8888. `weed s3` runs with `-iam=true` by default and reaches the filer over gRPC at `<filer port>+10000`; with only 8888 published it dialled `:18888`, got connection refused, and blocked in IAM/bucket initialisation **before binding 8333**. The symptom was a `Running` pod that logged nothing, never listened, and exited 0 on SIGTERM — the most expensive bug in the port.

This is the only difference between the 0.1.5 and 0.1.6 artifacts.

## [0.1.5] — 2026-11-24

Packaged artifact present in this workspace; it still contained the silent-hang bug fixed in 0.1.6. The diff against 0.1.6 is the filer `grpc` Service port and the version string, so 0.1.5's own changes relative to 0.1.4 are not recoverable from this workspace.

## [0.1.0] — 2026-11-24

### Added

- Initial scaffold: `master`, `volume`, `filer` StatefulSets with `volumeClaimTemplates`, `s3` Deployment, five Services (three headless, `-filer-client`, `-s3`), an S3 identity Secret in the upstream schema, two VirtualServices (filer UI, S3 API), a `CUSTOM` AuthorizationPolicy for the UI host, an optional `DENY` source-IP allowlist for the S3 host, and `hpe-ezua` vendor labels applied natively from the label helper.
- `helm/PORTING.md` — why the chart was scaffolded rather than ported, and how each flag was verified.

### Decisions recorded

| Id | Decision | Reason |
|---|---|---|
| D1 | Scaffold the chart rather than port upstream | no egress, no vendored chart; scaffolding kept full control of labels, Services and probes |
| D2 | Two VirtualServices, two auth models | SigV4 clients cannot follow an OIDC redirect; one SSO host would be unusable by every real client |
| D3 | Source-IP allowlist as `DENY`, not `ALLOW` | a host-scoped `DENY` cannot change authorisation for other hosts on the shared gateway |
| D4 | Omit the S3 route timeout rather than set `0s` | `0s` is rejected by Istio admission and fails the whole release; an omitted timeout is already "disabled" |
| D5 | `retries.attempts: 0` on the S3 route | a retried write can duplicate an upload or corrupt a multipart completion |
| D6 | Pass only `-port`, `-filer`, `-config` to `weed s3` | that is the documented flag set; carrying over `-ip.bind`/`-metricsPort` CrashLoops on flag parsing |
| D7 | No `command:` override, no glog flags | the image ENTRYPOINT is already `weed`; `-logtostderr` does not exist in this build |
| D8 | Forgiving S3 probes (120s / 6 failures) | a probe-kill loop destroyed the evidence of the 18888 bug; a stuck gateway must stay inspectable |
| D9 | Embedded LevelDB for the filer, one replica | simplest correct store; an external backend is the HA path, tracked in the roadmap |
| D10 | `001` replication on 3 volume servers | the strongest placement a single-rack cluster can satisfy; `010`/`100` cannot place and fail writes |

---

## Version gaps

Artifacts for `0.1.1`–`0.1.4` are not present in this workspace, so their contents are not recorded here. Only `seaweedfs-0.1.5.tar.gz` and `seaweedfs-0.1.6.tar.gz` were available to diff against the working tree.
