# Harbor on PCAI — active/passive HA with replication

Two independent Harbor releases, each pinned to one node with its own DB, Redis
and storage. Harbor replication copies images from A to B. Clients always use
the shared name `harbor.${DOMAIN_NAME}`, which only the active release serves.

```
clients ──► harbor.${DOMAIN_NAME} ──► ezaf-gateway ──► harbor-a (node-a)  ACTIVE
                                                         │ push replication
            harbor-b.${DOMAIN_NAME} ─────────────────► harbor-b (node-b)  PASSIVE
```

No DNS changes are needed: the PCAI wildcard `*.${DOMAIN_NAME}` and the gateway
cert already cover `harbor-a`, `harbor-b` and `harbor`.

## 0. About this chart

PCAI chart 1.18.0 = upstream harbor-helm **v1.19.4** (Harbor 2.15.4 templates) plus:

- PCAI integration: `templates/ezua/` (Istio VirtualService on `ezaf-gateway`,
  Kyverno label policy), `templates/_hpe_ezua.tpl`, `hpe-ezua` selector labels,
  Istio ingress annotations, TLS terminated at the gateway, `HARBOR_AUTH_MODE=db_auth`,
  resource requests/limits, 200Gi registry volume.
- `ezua.virtualService.extraEndpoints` for the shared client hostname; service
  names derived from the release name.
- `imageTag`: one value for all Harbor images.

Package: `helm package harbor/1.18.0` → `harbor-1.18.0.tgz`.

## Harbor version

All Harbor images use the tag in `imageTag` (default `v2.16.0`). To change the
version, edit that one line in both values files. Keep A and B on the same tag:
replication between different Harbor versions is not guaranteed.
If v2.16.0 misbehaves with this chart, set `imageTag: ""` (or `"v2.15.4"`):
the per-component tags are v2.15.4, the release this chart's templates ship with.

## 1. Check what you have

```bash
kubectl get nodes
kubectl get pods -n <harbor-ns> -o wide       # which node A runs on today
kubectl get pvc,pv -n <harbor-ns> -o wide     # storage class / node affinity
helm list -n <harbor-ns>                      # release name of A
```

Pin A to the node it already runs on. If its PVs are node-local and live on
another node, pinning A elsewhere will leave pods Pending.

## 2. Install or upgrade harbor-a (active)

Import Framework: name `harbor-a`, namespace `harbor-a`, upload `harbor-1.18.0.tgz`, and paste
the full `values-harbor-a.yaml` into the values.yaml box (replace the node names first).
For an existing Harbor: PCAI tile → Configure with the same values.

Result: A answers on `harbor-a.${DOMAIN_NAME}` and `harbor.${DOMAIN_NAME}`; the
token realm (`externalURL`) becomes `harbor-a`. Existing `docker login harbor.${DOMAIN_NAME}`
keeps working.

## 3. Install harbor-b (passive)

Import the chart a second time as a new framework in a **different namespace**
(e.g. `harbor-b`) using the full `values-harbor-b.yaml` as its values. Use the same admin password.

## 4. Recreate identities on B

This chart runs `HARBOR_AUTH_MODE=db_auth`: users, project members, quotas and
robot accounts live in each Harbor's own DB and are **not** replicated. Create
on B the same users/robots that CI and clusters use (or move both to the same
LDAP/OIDC).

## 5. Configure replication (Harbor UI on A)

1. On **B**: Administration → Robot Accounts → New (system level, all projects,
   push + pull on repositories).
2. On **A**: Administration → Registries → New Endpoint
   - Provider `Harbor`, URL `https://harbor-b.${DOMAIN_NAME}`, robot credentials
   - Untick *Verify Remote Cert* if the gateway cert is self-signed → Test → OK
3. On **A**: Administration → Replications → New Rule
   - Mode `Push-based`, source `**` (all), destination = the B endpoint, namespace unchanged
   - Trigger `Event Based`, tick *Delete remote resources when locally deleted*
4. Add a second identical rule with trigger `Scheduled` (e.g. `0 0 * * * *`, hourly) to catch missed events.
5. Run the scheduled rule once manually to copy what already exists.
6. On **B**: create the reverse endpoint (A) and rule B → A, **disabled**. Enable it only after a failover.

Projects are created on B automatically by replication.

## 6. Failover (node-a down)

Move the shared name from A to B (the API server is still up if the control
plane survived):

```bash
helm upgrade <release-a> harbor-1.18.0.tgz -n <ns-a> --reuse-values \
  --set-json 'ezua.virtualService.extraEndpoints=[]'
helm upgrade <release-b> harbor-1.18.0.tgz -n harbor-b --reuse-values \
  --set-json 'ezua.virtualService.extraEndpoints=["harbor.<your-domain>"]'
```

Remove it from A first: two VirtualServices claiming the same host on one
gateway give unpredictable routing. Clients keep using `harbor.${DOMAIN_NAME}`
but must `docker login` again (B has its own sessions/tokens).

When node-a is back: enable the B → A rule, let it catch up, then either swap
the shared name back or make B the new active and reverse the roles.

## Limits

- Replication is asynchronous: an image pushed seconds before the failure may be missing on B.
- Failover is a manual (or scripted) step, not automatic.
- Do not send traffic to both at once; a push split across A and B fails.
- If the Istio ingress gateway or the only control-plane node runs on the failed node, fix that first; Harbor B cannot be reached through a dead gateway.
