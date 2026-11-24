# SeaweedFS on HPE Private Cloud AI — S3 Clients

Chart `seaweedfs` v0.1.7 · Image `chrislusf/seaweedfs:4.55` · Site SE G2 · Domain `pcai-se-ai-application.hst.rdlabs.hpecorp.net` · Verified 2026-11-24

How to point a real S3 client at this deployment, which two configuration choices are not optional, and what each failure looks like from the client side. Deployment is [DEPLOYMENT.md](DEPLOYMENT.md); the layer-by-layer proof that the stack works is [VERIFICATION.md](VERIFICATION.md).

**This is an S3-compatible surface, not a certified AWS S3 API conformance statement.** The operations exercised end to end are `create_bucket`, `put_object`, `get_object`, `head_object`, `list_objects_v2`, multipart upload, presigned GET, `delete_object` and `delete_bucket` — the seven steps of [test_s3_boto3.py](../test_s3_boto3.py), which include a `head_object` length check after the multipart upload. ACLs, bucket policies, versioning, tagging, object lock, lifecycle rules and `ListBuckets` are **not** verified here, and the single-identity model in § 7 leaves several of them with no configuration surface at all. Test the exact call you depend on before designing around it.

## 1. Endpoints

Three ways in. The difference is authentication, not storage: all three reach the same filer namespace and the same volume bytes ([DEPLOYMENT.md](DEPLOYMENT.md) § 1).

| Endpoint | URL | Auth | Use it for |
|---|---|---|---|
| Public S3 host | `https://seaweedfs-s3.<domain>` | SigV4 static key only — no SSO | Anything outside the cluster: laptops, CI, customer tooling, presigned links |
| In-cluster S3 Service | `http://seaweedfs-s3.seaweedfs.svc.cluster.local:8333` | SigV4 static key | Pods in this cluster. Plain HTTP, so no CA work and no gateway hop |
| PCAI s3-proxy (optional) | `http://seaweed-fs-service.ezdata-system.svc.cluster.local:30000` | JWT in `AUTH_TOKEN` | Apps that must authenticate as a PCAI user instead of holding the static key |

The public host is one Istio host routed by its own VirtualService to the ClusterIP Service ([virtualservice-s3.yaml](../helm/templates/virtualservice-s3.yaml), [s3.yaml](../helm/templates/s3.yaml)); the in-cluster Service is that same ClusterIP. The proxy is a PCAI data-source endpoint in front of the in-cluster Service — the MinIO tile is the closest fit and the path should be validated on a test install before being relied on ([PORTING.md](../helm/PORTING.md) "Optional: also expose it to in-cluster apps via the PCAI s3-proxy").

**Two S3 endpoints, one identity — pick by network location, not by permission.** The public host is the only one reachable from outside; the ClusterIP skips the gateway and the CA ([§ 4](#4-tls-and-the-ca)) but is not routable from a laptop. The proxy is for a different question — *who* the caller is — and it adds a second control plane: a PCAI IAM grant on the proxy does not grant the public host, and the static key does not carry PCAI identity ([DEPLOYMENT.md](DEPLOYMENT.md) § 4).

**The filer UI host is not an S3 endpoint.** `https://seaweedfs.<domain>` serves the filer web UI behind oauth2-proxy ([authorizationPolicy.yaml](../helm/templates/authorizationPolicy.yaml)); an S3 client pointed at it receives a `302` to keycloak, not an S3 error. The S3 host is deliberately outside that policy because SigV4 clients cannot follow an OIDC redirect ([values.yaml](../helm/values.yaml) `s3VirtualService`).

## 2. Two invariants that every client must satisfy

Every entry in the error decoder (§ 8) traces back to one of these two. Both are properties of the deployment, not client preferences.

### 2.1 Path-style addressing

**Every client must use path-style URLs (`https://host/bucket/key`).** The deployment is a single host with no wildcard DNS record and no wildcard certificate: `s3.domainName` is left empty in [values.yaml](../helm/values.yaml) and the S3 VirtualService matches exactly one host ([virtualservice-s3.yaml](../helm/templates/virtualservice-s3.yaml)). There is nothing for virtual-hosted-style (`https://bucket.host/key`) to resolve to.

**If violated:** the client rewrites the endpoint to `bucket.seaweedfs-s3.<domain>` and fails at DNS, before an S3 error exists — boto3 raises `EndpointConnectionError` and the smoke test exits with `CONNECT FAILED - DNS/route/VirtualService problem` ([test_s3_boto3.py](../test_s3_boto3.py) line 133). If a wildcard record were ever added, the next failure would be the TLS handshake, because the certificate names the single host.

Per client: boto3 `Config(s3={"addressing_style": "path"})`; aws-cli is path-style by default for a custom `--endpoint-url` ([PORTING.md](../helm/PORTING.md) "First-deploy checks"); rclone `force_path_style = true`; s3fs `config_kwargs`; Spark `fs.s3a.path.style.access=true`.

### 2.2 SigV4 with a static key

**The public S3 host authenticates with the static access key from the `s3-config` Secret, and nothing else.** The oauth2-proxy `CUSTOM` AuthorizationPolicy lists the filer UI host only ([authorizationPolicy.yaml](../helm/templates/authorizationPolicy.yaml)), so the S3 host is never redirected to SSO. This is the one deliberate divergence from the usual PCAI posture in which every published endpoint sits behind oauth2-proxy ([PORTING.md](../helm/PORTING.md) § "Security notes for the public S3 route").

**If violated by the client** (unsigned request, or a client configured to fetch an SSO token first): the gateway answers `403` with `<Code>AccessDenied</Code>` and there is no login flow to complete — the signature is the only credential.

**If violated by the deployment** (the SSO policy put in front of the S3 host): every S3 client breaks at once, because the client receives a `302` to keycloak and cannot follow it. That is the failure the two-VirtualService split exists to prevent.

**Static keys only — there is no STS.** Temporary credentials and role assumption fail with `no signing key found for STS service` in the gateway log ([DEPLOYMENT.md](DEPLOYMENT.md) § 7). Handing out scoped, expiring credentials is therefore a deployment-level change, not a client option; see § 7.

## 3. Working recipes

**A ready-made implementation of all of this is in [`../s3_helper.py`](../s3_helper.py)** — bucket create, single-file and whole-folder upload, listing, download, `cat`, presign and delete, as both functions and a CLI. Reach for it instead of retyping the snippets below:

```bash
python3 s3_helper.py buckets                      # list
python3 s3_helper.py mkdir andrew-bucket          # create (idempotent)
python3 s3_helper.py put ./paper.pdf andrew-bucket/LLM_Papers/paper.pdf
python3 s3_helper.py putdir ./LLM_Papers andrew-bucket/LLM_Papers
python3 s3_helper.py ls andrew-bucket --long
python3 s3_helper.py cat andrew-bucket/notes.md
python3 s3_helper.py get andrew-bucket/notes.md ./notes.md
```

All recipes use the same four values: the public host, access key `seaweedfs` ([values.yaml](../helm/values.yaml) `s3.auth.accessKey`), the secret key held in the `s3-config` Secret, and region `us-east-1` ([test_s3_boto3.py](../test_s3_boto3.py) `S3_REGION`). Client option names below are the clients' own; the deployment constrains only endpoint, path style, SigV4 and the CA. The boto3 and rclone forms were checked against the installed clients (1.43.71 and 1.76.0); aws-cli and s3fs follow their documented option names. The only end-to-end run is the boto3 smoke test in [VERIFICATION.md](VERIFICATION.md) § 6.

### 3.1 Pre-flight: an unsigned request must fail

Reachability, TLS and the absence of SSO in two calls. A healthy S3 host answers `403`, not `302`:

```bash
export CA=~/.dsh/certs/pcai-aie-root-ca.crt      # needed for the public host, § 4
export S3=https://seaweedfs-s3.pcai-se-ai-application.hst.rdlabs.hpecorp.net

curl -sS --cacert "$CA" -o /dev/null -w '%{http_code}\n' "$S3/"   # 403
curl -sS --cacert "$CA" "$S3/" | head -c 200                     # ...<Code>AccessDenied</Code>...
```

`302` means SSO is in front of the host you called — you used the UI host, or the S3 route was put behind the policy. `SSL certificate problem` means the CA is missing (§ 4).

### 3.2 boto3 — the client the smoke test uses

```python
import os
import boto3
from botocore.config import Config

s3 = boto3.client(
    "s3",
    endpoint_url=os.environ.get(
        "S3_ENDPOINT", "https://seaweedfs-s3.pcai-se-ai-application.hst.rdlabs.hpecorp.net"
    ),
    aws_access_key_id="seaweedfs",
    aws_secret_access_key=os.environ["S3_SECRET_KEY"],      # never hardcode
    region_name="us-east-1",
    config=Config(
        signature_version="s3v4",
        s3={"addressing_style": "path"},                    # invariant § 2.1
        retries={"max_attempts": 3, "mode": "standard"},
        connect_timeout=10,
        read_timeout=120,
    ),
    verify=os.path.expanduser("~/.dsh/certs/pcai-aie-root-ca.crt"),   # § 4
)

s3.create_bucket(Bucket="uploads")
s3.put_object(Bucket="uploads", Key="hello.txt", Body=b"hello from boto3\n")
print(s3.get_object(Bucket="uploads", Key="hello.txt")["Body"].read())
print([o["Key"] for o in s3.list_objects_v2(Bucket="uploads").get("Contents", [])])
```

This is the client configuration of [test_s3_boto3.py](../test_s3_boto3.py) lines 45-59, minus the multipart and presigned steps. Run the script rather than retyping those: it is the artifact the deployment was verified with.

### 3.3 aws-cli

```bash
export AWS_ACCESS_KEY_ID=seaweedfs
export AWS_SECRET_ACCESS_KEY='<the key in the s3-config Secret>'
export AWS_DEFAULT_REGION=us-east-1
export AWS_CA_BUNDLE=~/.dsh/certs/pcai-aie-root-ca.crt   # § 4; there is no --ca-bundle flag
S3=https://seaweedfs-s3.pcai-se-ai-application.hst.rdlabs.hpecorp.net

aws --endpoint-url "$S3" s3 mb s3://uploads                 # create_bucket
aws --endpoint-url "$S3" s3 cp ./file.bin s3://uploads/     # put_object
aws --endpoint-url "$S3" s3 ls s3://uploads                 # list_objects_v2
aws --endpoint-url "$S3" s3 cp s3://uploads/file.bin .      # get_object
aws --endpoint-url "$S3" s3 sync ./data s3://uploads/data    # list + put per changed object
```

**Keep `--endpoint-url` on every call** — a custom endpoint is also what selects path-style addressing, which is the default for a non-AWS endpoint ([PORTING.md](../helm/PORTING.md)). A bare `aws s3 ls` with no bucket is `ListBuckets`, which is outside the exercised set; `s3 ls s3://uploads` is the check that matches the smoke test.

### 3.4 rclone

```ini
# ~/.config/rclone/rclone.conf
[seaweedfs]
type = s3
provider = Other
access_key_id = seaweedfs
secret_access_key = <the key in the s3-config Secret>
endpoint = https://seaweedfs-s3.pcai-se-ai-application.hst.rdlabs.hpecorp.net
region = us-east-1
force_path_style = true
```

```bash
CA=~/.dsh/certs/pcai-aie-root-ca.crt
rclone --ca-cert "$CA" lsf    seaweedfs:uploads                     # list_objects_v2
rclone --ca-cert "$CA" copyto ./file.bin seaweedfs:uploads/file.bin  # put_object
rclone --ca-cert "$CA" cat    seaweedfs:uploads/hello.txt           # get_object
rclone --ca-cert "$CA" copy   ./data seaweedfs:uploads/data          # list + put per object
```

`--ca-cert` is rclone's own global CA option, so no environment variable and no system trust-store edit is needed (§ 4).

### 3.5 s3fs / fsspec

```python
import os
import s3fs

fs = s3fs.S3FileSystem(
    key="seaweedfs",
    secret=os.environ["S3_SECRET_KEY"],
    endpoint_url="https://seaweedfs-s3.pcai-se-ai-application.hst.rdlabs.hpecorp.net",
    use_ssl=True,
    client_kwargs={
        "region_name": "us-east-1",
        "verify": os.path.expanduser("~/.dsh/certs/pcai-aie-root-ca.crt"),
    },
    config_kwargs={"signature_version": "s3v4", "s3": {"addressing_style": "path"}},
)

print(fs.ls("uploads"))                       # list_objects_v2
with fs.open("uploads/hello.txt", "wb") as f:  # put_object
    f.write(b"hello from s3fs\n")
```

`config_kwargs` is s3fs's pass-through to botocore's `Config`, which is where the two mandatory settings live; `client_kwargs` is where the CA goes.

### 3.6 Spark / Hadoop S3A

```python
import os
from pyspark.sql import SparkSession

spark = (
    SparkSession.builder
    .config("spark.hadoop.fs.s3a.endpoint", "https://seaweedfs-s3.<domain>")
    .config("spark.hadoop.fs.s3a.path.style.access", "true")
    .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "true")
    .config("spark.hadoop.fs.s3a.access.key", "seaweedfs")
    .config("spark.hadoop.fs.s3a.secret.key", os.environ["S3_SECRET_KEY"])
    .config("spark.hadoop.fs.s3a.endpoint.region", "us-east-1")
    .getOrCreate()
)
df.write.parquet("s3a://uploads/out/")
```

**S3A takes its trust from the JVM truststore, not from an S3A option** — import the AIE Root CA with `keytool -importcert` and point driver and executors at that store with `-Djavax.net.ssl.trustStore=...` (§ 4). Without it the job fails at the TLS handshake while every S3A setting above is correct.

### 3.7 One sanity check that outranks all of the above

Whatever client you use, two calls settle it: a list against a bucket you created returns your keys, and the same client with no credentials gets `403 AccessDenied` (§ 3.1). If both hold, the connection and the identity are right and any remaining failure is the specific operation you are calling — which is the point at which the unverified surface in the introduction matters.

## 4. TLS and the CA

**The public host presents a certificate from the cluster-internal AIE Root CA, and that CA is in no system trust store.** Every client fails TLS on its first call until it is told where the CA is; this is not a client misconfiguration and there is nothing to install cluster-wide. The 2026-11-24 run used `/home/andrew/.dsh/certs/pcai-aie-root-ca.crt` (`~/.dsh/certs/pcai-aie-root-ca.crt` in the recipes below); any copy of the AIE Root CA certificate works.

The exact failure, as recorded in [DEPLOYMENT.md](DEPLOYMENT.md) § 6:

```
SSL: CERTIFICATE_VERIFY_FAILED
```

Go-based clients (rclone) phrase the same condition as `x509: certificate signed by unknown authority`.

Three ways to trust it, in order of locality:

| Way | Where it goes | Applies to |
|---|---|---|
| `verify=<path>` | boto3/botocore client argument ([test_s3_boto3.py](../test_s3_boto3.py) line 58) | that one client |
| `AWS_CA_BUNDLE=<path>` | environment | aws-cli and boto3 in that shell |
| `REQUESTS_CA_BUNDLE=<path>` | environment | anything built on `requests` — boto3 does not read it |

```bash
# boto3 - the variable test_s3_boto3.py reads
export S3_CA_BUNDLE=~/.dsh/certs/pcai-aie-root-ca.crt
# aws-cli and boto3
export AWS_CA_BUNDLE=~/.dsh/certs/pcai-aie-root-ca.crt
# requests-based clients
export REQUESTS_CA_BUNDLE=~/.dsh/certs/pcai-aie-root-ca.crt
```

**The in-cluster Service needs none of this** — it is plain HTTP ([DEPLOYMENT.md](DEPLOYMENT.md) § 3), so only the public host requires the CA.

**Do not close this with `--no-verify-ssl` or `verify=False`.** It makes the call succeed and tells you nothing about which host or proxy answered; use it once to confirm the CA is the cause, then set the CA path. A fetcher of presigned URLs needs the CA as well (§ 6).

## 5. Large objects and multipart

**The S3 route has no timeout and no Envoy retries, deliberately.** [virtualservice-s3.yaml](../helm/templates/virtualservice-s3.yaml) renders `retries.attempts: 0` and omits `timeout` entirely; `ezua.s3VirtualService.timeout` is empty in [values.yaml](../helm/values.yaml) because an omitted Istio timeout already means disabled, while `0s` is rejected at admission with *must be a valid duration greater than 1ms* ([PORTING.md](../helm/PORTING.md)).

- **Retries are off because a proxy-level retry can duplicate an upload or corrupt a multipart completion** — the template says so where the value is set. Retry policy therefore belongs to the client, which knows which request it is repeating; the boto3 recipe sets `max_attempts: 3` ([test_s3_boto3.py](../test_s3_boto3.py) line 54).
- **The timeout is off because a multi-megabyte upload over a slow link is not a hung request.** To add a hard ceiling, set a real duration (`ezua.s3VirtualService.timeout: "3600s"`); do not set a small one — a slow upload then ends as a `504` from the gateway.
- **What the chart cannot bound is upstream of the ezua gateway.** A load balancer or proxy in front of it can still impose its own body-size or idle-timeout limit, and no value in this chart changes that ([PORTING.md](../helm/PORTING.md) "Upload size"). An upload that dies at a suspiciously round number of seconds, or exactly at a body-size boundary, is that limit rather than SeaweedFS.
- **What is exercised:** the smoke test writes 12 MiB of random bytes through boto3's transfer manager with a 5 MiB threshold and 5 MiB chunks, then verifies the length with `head_object` ([test_s3_boto3.py](../test_s3_boto3.py) lines 96-108). It passed on 2026-11-24 ([VERIFICATION.md](VERIFICATION.md) § 6).
- **A `500` during a volume-server restart is replication, not signing.** With `defaultReplication: 001` SeaweedFS is W=N, R=1: if any replica write fails the whole write fails ([DEPLOYMENT.md](DEPLOYMENT.md) § 2).

## 6. Presigned URLs

**A presigned URL is a bearer token signed for one host, and this deployment cannot revoke it early.** Generating one is pure client-side work — no request to the gateway — so it succeeds even while the cluster is unreachable:

```python
url = s3.generate_presigned_url(
    "get_object", Params={"Bucket": "uploads", "Key": "hello.txt"}, ExpiresIn=300
)
```

The URL boto3 produces against this configuration is path-style and carries the host inside the signature:

```
https://seaweedfs-s3.<domain>/uploads/hello.txt
  ?X-Amz-Algorithm=AWS4-HMAC-SHA256
  &X-Amz-Credential=seaweedfs%2F20261124%2Fus-east-1%2Fs3%2Faws4_request
  &X-Amz-Date=...&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=...
```

- **Valid only against the host it was signed for** — `X-Amz-SignedHeaders=host` is part of what is signed, so a URL signed for the public host returns `SignatureDoesNotMatch` against the in-cluster Service, and the reverse. Sign against the endpoint the holder will actually call; the smoke test notes the same constraint where it generates one ([test_s3_boto3.py](../test_s3_boto3.py) line 111).
- **Anyone holding it bypasses the gateway's SSO, because the S3 host has none** (§ 2.2). There is no login in front of the route, so the signature is the only check — treat the URL as a credential for its whole lifetime and do not paste it into a ticket.
- **The fetcher needs the CA too:** `curl --cacert ~/.dsh/certs/pcai-aie-root-ca.crt "$URL" -o out.bin`, or a browser that trusts the AIE Root CA. Without it the download fails on TLS, which reads like a broken signature if you only look at the exit code.
- **Revocation is expiry or rotation:** deleting the object kills one URL; everything else waits for `ExpiresIn` or for the key to change (§ 7).

## 7. Identity and permissions model

**One identity, three actions, no per-bucket IAM.** The entire authorization surface is one JSON document in the `s3-config` Secret ([s3-secret.yaml](../helm/templates/s3-secret.yaml)):

```json
{
  "identities": [
    {
      "name": "admin",
      "credentials": [
        { "accessKey": "seaweedfs", "secretKey": "<the key in the s3-config Secret>" }
      ],
      "actions": ["Admin", "Read", "Write"]
    }
  ]
}
```

- **One credential per deployment.** Every client, team and pipeline shares the same key pair. There is no per-bucket policy, no per-user identity, and no way through the chart to give one consumer read-only and another write; `actions` is a global list on the single identity, so narrowing it to `["Read"]` changes every consumer at once.
- **Read the key from the Secret, not from a values file.** If `s3.auth.secretKey` is empty the chart generates a random key at install ([s3-secret.yaml](../helm/templates/s3-secret.yaml)) and **regenerates it on every upgrade**, breaking every client ([values.yaml](../helm/values.yaml)). Set it explicitly in any environment you intend to upgrade; [VERIFICATION.md](VERIFICATION.md) § 5 has the read-back command.
- **Rotate by editing the Secret and restarting the gateway.** The Secret is mounted as a volume, but the s3 Deployment carries no config checksum annotation ([s3.yaml](../helm/templates/s3.yaml)), so a Secret edit alone does not roll the pod. Rotation is a cutover: every client and every outstanding presigned URL breaks at the same moment, so stage the new key with consumers first.
- **STS and temporary credentials are unsupported** — the gateway logs `no signing key found for STS service` ([DEPLOYMENT.md](DEPLOYMENT.md) § 7). No role assumption, no session tokens, no expiry: a leaked key is valid until it is rotated.
- **The PCAI s3-proxy is a second control plane, not a second identity here.** Per-user PCAI IAM grants apply to the proxy path only; they do not grant the public S3 host, and the shared static key does not carry PCAI identity ([DEPLOYMENT.md](DEPLOYMENT.md) § 4).
- **Treat the public key as internet-facing.** The route is reachable from outside the cluster and is not SSO-protected; `ezua.s3VirtualService.allowList.enabled` is the chart's only network-level restriction and it is off by default ([values.yaml](../helm/values.yaml), [authorizationPolicy-s3-allowlist.yaml](../helm/templates/authorizationPolicy-s3-allowlist.yaml)).

## 8. Client error decoder

The smoke test prints a short version of this on failure ([test_s3_boto3.py](../test_s3_boto3.py) lines 137-140). Deployment-side symptoms — a gateway that never binds 8333, unknown flags, PVCs pending — are in [DEPLOYMENT.md](DEPLOYMENT.md) § 6.

| What the client shows | Cause | Fix |
|---|---|---|
| `SignatureDoesNotMatch` | Secret key wrong, or the request was signed for a different host (a presigned URL used against another endpoint), or a proxy rewrote `Host` | Re-read the key from the Secret ([VERIFICATION.md](VERIFICATION.md) § 5); re-sign against the host you will call (§ 6); check for a rewriting proxy |
| `InvalidAccessKeyId` | The access key does not match the identity in the Secret | Use `seaweedfs`, or whatever `s3.auth.accessKey` the release was installed with ([values.yaml](../helm/values.yaml)) |
| `AccessDenied` with an S3 `<Error>` body | The request was unsigned — this is the healthy answer for an anonymous call (§ 3.1) | Send SigV4 credentials; if you believe you did, check the client actually loaded them (`aws configure list`, or `print(s3.meta.config)`) |
| `403` with no S3 XML — typically plain-text `RBAC: access denied` | Not S3: the optional Istio DENY policy dropped the source IP | `ezua.s3VirtualService.allowList.cidrs` ([authorizationPolicy-s3-allowlist.yaml](../helm/templates/authorizationPolicy-s3-allowlist.yaml)) |
| `NoSuchBucket` | The bucket was never created, or the name differs from what the client sends | `create_bucket` first (§ 3.2, § 3.3); the smoke test tolerates `BucketAlreadyOwnedByYou` |
| `RequestTimeTooSkewed` | The client clock is off; SigV4 signs the request timestamp | Sync the clock (NTP) and retry |
| `SSL: CERTIFICATE_VERIFY_FAILED` | The AIE Root CA is not trusted by this client | § 4 — `verify=`, `AWS_CA_BUNDLE`, `REQUESTS_CA_BUNDLE` |
| DNS failure or `EndpointConnectionError` for `bucket.seaweedfs-s3.<domain>` | Virtual-hosted-style addressing against a single-host endpoint | Path style (§ 2.1) |
| `302` to a keycloak URL, or an HTML login page instead of XML | SSO is in front of the host you called | Call the S3 host, not the filer UI host (§ 1) |
