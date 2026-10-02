# Kafka - HPE Private Cloud AI / AI Essentials (BYOA)

Apache Kafka in **KRaft mode** (no ZooKeeper) packaged the EZUA **BYOA** way: the chart
deploys the **Strimzi custom resources** (`Kafka`, `KafkaNodePool`, `KafkaTopic`, optional
`KafkaUser`) plus an optional **kafka-ui** visibility tile. The **Strimzi Cluster
Operator is a one-time per-namespace prerequisite** - it is intentionally *not* bundled
(operators are cluster infrastructure; keeping it out keeps the BYOA package small and
idempotent). See [porting.md](porting.md) for the full porting story, known issues, and
troubleshooting.

```
0.3.0/  -> kafka-0.3.0.tar.gz   (BYOA guidance compliance: AuthorizationPolicy,
                                 hpe-ezua labels via _hpe-ezua.tpl + Kyverno policy,
                                 EzAppConfig template, SCRAM listener fix)
```

## Contents

| File | Purpose |
|---|---|
| `0.3.0/` | Helm chart source |
| `kafka-0.3.0.tar.gz` | Packaged chart for the EZUA import process |
| `kafka_logo.png` | Logo for the Tools & Frameworks tile |
| `porting.md` | PCAI porting notes, verify-list, troubleshooting |

## Prerequisites

1. **Strimzi Cluster Operator 1.x** running in the target namespace, serving CRDs at
   `kafka.strimzi.io/v1`:
   ```bash
   kubectl api-resources | grep -i strimzi   # must show kafka.strimzi.io/v1
   ```
   Install steps: see [porting.md](porting.md) ("Setting up the Strimzi Cluster
   Operator"). Install into the **same namespace** the chart is deployed to.
2. A **default StorageClass** on the cluster (leave `cluster.storage.class` blank — see
   porting.md Troubleshooting #5).
3. If `kafkaUi.enabled: true`: the `istio-system/ezaf-gateway` must exist (standard on
   EZUA) and the `oauth2-proxy` extension provider configured for SSO

## Client access

| Listener | Port | Auth | Use |
|---|---|---|---|
| `plain` | 9092 | none (PLAINTEXT) | in-cluster sandbox clients |
| `tls` | 9093 | mTLS (ezaf CA) | optional, `listeners.tlsInternal: true` |
| `scram` | 9094 | SCRAM-SHA-512 | optional, `listeners.scramInternal: true` — **required when `user.enabled: true`** |

In-cluster bootstrap: `<cluster.name>-kafka-bootstrap.<ns>.svc.cluster.local:9092`.
Kafka traffic does **not** go through Istio — the VirtualService is only for the
human-facing kafka-ui tile.

## Production gaps (intentional for trial scale — see porting.md)

- `replicas: 1`, all replication factors `1`, `min.insync.replicas: 1` → no HA, no
  durability. For production: 3+ brokers, RF 3, `min.insync.replicas: 2`.
- `plain` PLAINTEXT listener enabled by default; enable `scram`/`tls` listeners and the
  `KafkaUser` for authenticated access.
- kafka-ui is single-replica, no native auth (SSO is enforced at the gateway via the
  AuthorizationPolicy), `dynamicConfig` off by default.
- Brokers get no explicit `topologySpreadConstraints`/anti-affinity (single-node trial).
- No Prometheus/JMX metrics export (Strimzi `Kafka` `metricsConfig` not wired).
- The Strimzi operator is deployed per-namespace by hand — not lifecycle-managed by this
  chart.
