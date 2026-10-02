# HPE notes — porting Kafka to PCAI (AIE 1.12.x)

Kafka packaged the BYOA way for HPE Private Cloud AI, using the **Strimzi** operator in
**KRaft** mode (no ZooKeeper). This file records how the chart was adapted to PCAI and
the things to verify on the target cluster. 

> **Strimzi 1.x / CRD API `kafka.strimzi.io/v1` (chart 0.2.0).** This chart targets
> Strimzi **1.x**, which serves the CRDs **only at `v1`** (`v1beta2` was removed at the
> 1.0 release). It will NOT install against a 0.x operator that serves `v1beta2`. Confirm
> with `kubectl api-resources | grep -i strimzi` before installing. `spec.kafka.version`
> is left blank by default so the operator picks a version it supports — pin it only to a
> version the installed operator lists.

> **AIE import OOM (seen on this engagement).** The AIE framework-import runs a Helm
> install Job in `ezapp-system` capped at `memory: 128Mi`, which is too little for Helm —
> the Job is `OOMKilled` and the log shows only "Installing it now." before dying. Fixes:
> raise the ezapp install-Job memory limit (platform-side; no LimitRange to edit, it is
> the ezapp controller default — may need cluster-admin / HPE support).

## How it was ported

- Hand-crafted Helm chart (like several charts in the `frameworks` repo) that deploys
  the Kafka **custom resources** — `Kafka`, `KafkaNodePool` (dual-role controller+broker,
  KRaft), `KafkaTopic`, optional `KafkaUser` — plus an optional **kafka-ui** tile.- The **Strimzi Cluster Operator is a prerequisite** installed once per namespace
  (see README). Operators install CRDs and are cluster infra, so they are kept out of
  the app chart rather than bundled — this keeps the BYOA package small and idempotent.
- KRaft is enabled via the two annotations on the `Kafka` CR
  (`strimzi.io/kraft: enabled`, `strimzi.io/node-pools: enabled`); storage and replica
  count live on the `KafkaNodePool`, per the current Strimzi schema.

## Setting up the Strimzi Cluster Operator (kubectl)

The operator is a one-time prerequisite that reconciles the Kafka CRs this chart
deploys. This is the kubectl route (no Helm needed). It installs the operator into the
`kafka` namespace and, by default, has it watch **only that namespace** — which is what
this bundle assumes, so deploy the chart into the same namespace.

1. **Create the namespace** (operator + Kafka cluster live here):
   ```bash
   kubectl create namespace kafka
   ```

2. **Install the operator.** The `?namespace=` query parameter rewrites the default
   `myproject` namespace in the downloaded `ClusterRole`/`ClusterRoleBinding` manifests
   to `kafka`:
   ```bash
   kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka
   ```
   For a repeatable trial, pin a release instead of `latest` (pick a version from the
   Strimzi releases page):
   ```bash
   kubectl create -f 'https://strimzi.io/install/<version>?namespace=kafka' -n kafka
   ```

3. **Wait for it to be ready:**
   ```bash
   kubectl -n kafka wait deployment/strimzi-cluster-operator \
     --for=condition=Available --timeout=300s
   kubectl -n kafka get pods
   ```

4. **Confirm the CRDs registered** (Kafka, KafkaNodePool, KafkaTopic, KafkaUser):
   ```bash
   kubectl get crd | grep strimzi
   ```

**Watching another namespace.** To keep the operator in `kafka` but have it also manage
Kafka CRs in, say, `plant-apps`, set `STRIMZI_NAMESPACE` on the operator Deployment
(comma-separated, or `*` for all) and add matching RoleBindings in that namespace:
```bash
kubectl -n kafka set env deployment/strimzi-cluster-operator \
  STRIMZI_NAMESPACE=kafka,plant-apps
```

**Restricted egress / air-gapped PCAI.** If the cluster cannot reach `strimzi.io`,
download the release install bundle on a jump host
(`github.com/strimzi/strimzi-kafka-operator/releases`), rewrite the namespace across the
YAMLs, mirror the operator images to the internal registry (Harbor/Nexus), then apply:
```bash
sed -i 's/namespace: myproject/namespace: kafka/' install/cluster-operator/*.yaml
kubectl create -f install/cluster-operator/ -n kafka
```

Once the operator is `Available`, deploy this chart's Kafka CRs into the **same
namespace** (see README → Install).

## PCAI adaptations

- **EzUA VirtualService** for the kafka-ui tile
  (`templates/ezua/virtualservice.yaml`) — routes the `${RELEASE_NAME}-${NAMESPACE}.${DOMAIN_NAME}`
  host through `istio-system/ezaf-gateway` to the in-cluster Service, matching the pattern used by
  other PCAI framework charts. The release/namespace-prefixed host (BYOA tutorial placeholder
  convention, chart 0.3.0+) avoids gateway-host collisions when more than one Kafka release
  exists on the cluster.
- **EzUA AuthorizationPolicy** (`templates/ezua/authorizationpolicy.yaml`, chart 0.3.0+) —
  CUSTOM action via the `oauth2-proxy` provider on the gateway, giving the kafka-ui tile the
  same EZUA SSO as other frameworks. Without it the tile was reachable by anyone who could
  resolve the URL. If your app supports the OAuth2 flow, also add the
  `https://<endpoint>/oauth2/callback` redirect URI to the `ua` client in Keycloak (optional,
  see the BYOA tutorial).
- **hpe-ezua labels** — chart 0.3.0+ ships the tutorial's `_hpe-ezua.tpl`
  (`hpe-ezua.labels`: `hpe-ezua/app: <release>`, `hpe-ezua/type: vendor-service`) applied to the
  kafka-ui Deployment and pod template, plus a Kyverno ClusterPolicy
  (`templates/ezua/kyverno.yaml`, pre-install hook) that mutates Pods/Deployments/Services in the
  release namespace — this also covers the Strimzi operator-created broker and entity-operator
  pods, which Helm does not template directly. Both are required for Resource Management and
  Pod Health monitoring.
- **EzAppConfig CR template** (`ezappconfig-kafka-template.yaml`, chart 0.3.0+) — the import
  manifest for the BYOA process; the `${RELEASE_NAME}`/`${NAMESPACE}`/`${DOMAIN_NAME}`
  placeholders must appear in `spec.values` or the EzApp controller will not substitute them.
- **SCRAM listener** (chart 0.3.0+) — `listeners.scramInternal: true` adds a SCRAM-SHA-512
  listener on :9094. Required whenever `user.enabled: true`: a SCRAM KafkaUser cannot
  authenticate against the PLAINTEXT listener (0.2.0 shipped this mismatch).
- **kafka-ui hardening** (chart 0.3.0+) — `DYNAMIC_CONFIG_ENABLED` now defaults to `false`
  (runtime config mutation from an unauthenticated UI was a takeover risk) and the Deployment
  gained a livenessProbe.
- **In-cluster access bypasses Istio:** the replay producer and scoring consumer use the
  Strimzi **bootstrap Service DNS** (`<cluster>-kafka-bootstrap.<ns>.svc.cluster.local:9092`),
  not the ingress — the VirtualService is only for the human-facing UI.
- **No GPU:** Kafka is CPU/memory/storage only; pods request no GPU, so the AIE
  `scheduler-plugins-scheduler` places them without accelerator constraints.

## Verify on the target cluster (highest-risk first)

0. **CRD API version.** `kubectl api-resources | grep -i strimzi` must show
   `kafka.strimzi.io/v1`. If it shows only `v1beta2`, the operator is 0.x — either
   upgrade to 1.x or change this chart's CR `apiVersion` back to `v1beta2`.
1. **AIE install-Job memory.** If importing via the AIE UI, confirm the `ezapp-system`
   install Job has enough memory (the default 128Mi OOMs Helm — see note above), or apply
   the CRs directly.
2. **Storage class — LEAVE IT BLANK on 1.x operators.** `cluster.storage.class` defaults
   to `""` and should stay that way when a **default StorageClass** exists (verify with
   `kubectl get sc` — the default is marked `(default)`). Setting an explicit class trips a
   1.x operator bug (see "Storage class reconcile loop" in Troubleshooting) that makes the
   operator try to null the PVC's immutable class and hang forever. With the class blank,
   the PVC is provisioned by the default SC and the operator never manages the field.
   Only set an explicit class if the cluster has **no** default SC. VAST/NFS
   (`csi.vastdata.com`) is functionally fine for a bounded trial replay (its
   segment/partition paths use no colons, so the VAST colon `EINVAL` gotcha doesn't bite);
   it is not a production Kafka storage pattern.
2. **TLS/CA (only if `listeners.tlsInternal: true`).** Inject the `ezaf-root-ca` via the
   namespaced **Kyverno Policy** pattern rather than mounting certs by hand. The sandbox
   default is PLAINTEXT in-cluster, which needs none of this.
3. **Operator scope.** Install the operator with `watchNamespaces` limited to the trial
   namespace on a shared cluster.
4. **Image pull.** Confirm the registry for `kafkaUi.image` is reachable, or mirror it
   to the internal registry (Harbor/Nexus) and update the value.

## Troubleshooting — issues hit on a real 1.x deployment (in order)

All six of these were hit bringing this up on an AIE Gen-2 cluster with Strimzi `1.2.0`
(serving Kafka 4.3.1) and a default `gl4f-filesystem` (VAST) StorageClass. **Direct
`kubectl apply` of the CRs worked cleanly once these were understood; the AIE Helm import
tripped over several of them.**

1. **AIE import Job OOMKilled.** The `ezapp-system` install Job is capped at
   `memory: 128Mi`; Helm needs more, so the pod is `OOMKilled` and the log shows only
   "Release … does not exist. Installing it now." before dying. Fix: raise the ezapp
   install-Job memory (platform-side; no LimitRange to edit — it is the ezapp controller
   default, likely needs cluster-admin / HPE support), **or** bypass the import and
   `kubectl apply` the CRs (`examples/rendered-default.yaml`).
2. **`no matches for kind "Kafka" in version kafka.strimzi.io/v1beta2`.** Strimzi 1.x
   serves the CRDs only at `v1`. This chart is already `v1`; confirm with
   `kubectl api-resources | grep strimzi`.
3. **`invalid ownership metadata … missing key app.kubernetes.io/managed-by: Helm`.** A
   re-import can't adopt CRs that were first created by `kubectl apply`. Either delete them
   and let Helm create them, or stamp all of them (Helm fails on the first one it hits, so
   do all at once):
   ```bash
   for r in kafka/plant-kafka kafkanodepool/dual-role kafkatopic/plant-telemetry; do
     kubectl -n kafka annotate $r meta.helm.sh/release-name=kafka meta.helm.sh/release-namespace=kafka --overwrite
     kubectl -n kafka label   $r app.kubernetes.io/managed-by=Helm --overwrite
   done
   ```
4. **`--wait --atomic` rollback wipes the cluster.** If the import runs atomic and any
   resource never goes Ready (classically the `kafka-ui` image can't be pulled through the
   egress allowlist), the rollback deletes the whole release — including CRs it adopted.
   Keep `kafkaUi.enabled: false` until the UI image is mirrored to Harbor/Nexus.
5. **Storage-class reconcile loop (the big one).** With an explicit `storage.class`, the
   1.x operator drops it during v1 conversion, then tries to PATCH the bound PVC's
   `StorageClassName` to `null` — forbidden (PVC spec is immutable) — so reconcile fails
   forever and no broker pod appears. The `Kafka` status shows the `422 … spec is
   immutable` error. Fix: leave `storage.class` blank and rely on the default SC.
6. **Stale PVC survives "recreation."** A Strimzi PVC carries a finalizer; if the broker
   was ever created, `kubectl delete pvc` hangs in `Terminating` and every re-apply
   silently **reuses the old, mismatched PVC** — so the loop in (5) persists even after you
   "recreated" everything. Fix: delete the CRs, then force the PVC delete and confirm it is
   actually gone before re-applying:
   ```bash
   kubectl -n kafka delete kafka/plant-kafka kafkanodepool/dual-role
   kubectl -n kafka patch pvc data-0-plant-kafka-dual-role-0 -p '{"metadata":{"finalizers":null}}' --type=merge
   kubectl -n kafka delete pvc data-0-plant-kafka-dual-role-0
   kubectl -n kafka get pvc          # MUST be empty before the next apply
   kubectl apply -f examples/rendered-default.yaml -n kafka   # class blank -> fresh PVC on default SC
   ```
   A genuinely fresh PVC created by the operator under the blank-class spec reconciles
   immediately (broker + entity-operator Running, `Kafka` READY=True).

**Net for the next engagement:** install a pinned operator (not `latest`), import with
`kafkaUi.enabled=false` and `storage.class` blank, and prefer direct `kubectl apply` over
the AIE import for the CRs.

## References

- https://strimzi.io/ · https://strimzi.io/docs/operators/latest/deploying (KRaft, node pools)
- https://kafka.apache.org/documentation/
- BYOA / import-application: https://github.com/HPEEzmeral/byoa-tutorials/tree/main/tutorial
- PCAI frameworks (convention + Pulsar): https://github.com/ai-solution-eng/frameworks
