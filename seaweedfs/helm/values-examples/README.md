# values-examples — paste-ready values documents (secret-free)

Complete, sanitized values documents for this chart: full copies of `helm/values.yaml`
with the site decisions filled in — **not** overlay snippets, because on PCAI the values
pasted into the *Helm Values* editor **replace** the chart's `values.yaml` entirely.

Nothing here is a credential. The only secret is the `<S3_SECRET_KEY>` filler; real
per-site values live in [`helm/local/`](../local/README.md) (gitignored, excluded from
packaged charts).

## Files

| File | Target |
|---|---|
| `values.hosted-trial-ingest.yaml` | Hosted trial, **ingest window**: public S3 host open, gateway HPA armed, 3 × 250Gi with `001` replication (750Gi raw, ~375Gi usable). |
| `values.hosted-trial-locked.yaml` | The same deployment after ingest: identical except `ezua.s3VirtualService.enabled: false`. |

**The two files are byte-identical except one line.** That is a rule, not a coincidence:
the flip must be a single values edit so it cannot carry an accidental revert of
`s3.auth.secretKey` or `volume.persistence.size` with it. Verify before applying:

```bash
diff helm/values-examples/values.hosted-trial-ingest.yaml \
     helm/values-examples/values.hosted-trial-locked.yaml   # one changed line, no more
```

## Before you install (a new cluster)

Five checks, ordered so the cheapest failure surfaces first. Every one of them has
bitten a deployment of this chart at least once.

```bash
# 1. Will the pods be able to write their claims as uid 1000? (securityContext is on)
kubectl get csidriver -o custom-columns=NAME:.metadata.name,FSGROUP:.spec.fsGroupPolicy
#    File / ReadWriteOnceWithFSType -> works for these RWO filesystem claims.
#    None -> set securityContext.enabled=false in the values, or the pods will never be Ready.

# 2. Does the storage class in the values exist here?
kubectl get storageclass | grep -i vast
#    No gl4f-filesystem? Change storageClass: to a class that exists.

# 3. Is there room for the claims? (3 x 250Gi = 750Gi raw, ~375Gi usable with 001)
kubectl get resourcequota -A | grep -i -e storage -e requests.storage

# 4. Does the HPA have metrics to read? (autoscaling is on, 2 -> 4)
kubectl top pods -A | head -1     # empty or error = no metrics-server; the HPA parks at 2

# 5. Does the identity Secret exist? The profiles point at it, they do not create it.
kubectl get secret seaweedfs-s3-identity -n <ns>
```

Two DNS names are needed as well: `seaweedfs.<domain>` (filer UI, behind SSO) and
`seaweedfs-s3.<domain>` (S3 API, not behind SSO). If only one can exist, set
`ezua.s3VirtualService.enabled: false` and use the in-cluster endpoint instead.

## Using them on PCAI

1. Import the packaged chart once.
2. Open the release's **Helm Values** editor and paste the whole file.
3. Replace the `# SITE:` lines — at minimum `storageClass` and `s3.auth.secretKey`.
4. Apply. PCAI substitutes `${DOMAIN_NAME}` before rendering.

Render-check without installing:

```bash
helm template seaweedfs helm -f helm/values-examples/values.hosted-trial-ingest.yaml
helm template seaweedfs helm -f helm/values-examples/values.hosted-trial-locked.yaml
```

## Placeholder convention

Everything you must replace is in angle brackets and named for its role —
`<S3_SECRET_KEY>`. The one exception is `${DOMAIN_NAME}`, which PCAI substitutes; leave
it verbatim.

## What these are not

`helm/local/values.g2.yaml` is the SE G2 **lab** deployment (3 × 100Gi, `001`, one S3
replica). It is gitignored and never packaged, and it is not a profile to copy.
