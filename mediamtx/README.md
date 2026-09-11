# MediaMTX on HPE Private Cloud AI (dc15-0103)

[MediaMTX](https://mediamtx.org) (`bluenviron/mediamtx:1.17.1`) is a ready-to-use, zero-dependency **live media router / media proxy**. It publishes, reads, proxies, records and plays back real-time video/audio across RTSP, RTMP, HLS, WebRTC, SRT and RTP. This chart deploys it on HPE Private Cloud AI and exposes it through the platform's EZUA ingress (with SSO) plus a native MetalLB endpoint.

> This is the **usage guide** ("everything we know, how to use it"). For the engineering/porting story, see **[porting.md](porting.md)**.

## Mental model (important)

There are **two separate planes**, and this is the source of most confusion:

| Plane | Protocol | Entry point | Auth |
|---|---|---|---|
| **Read / Playback (browser)** | HLS over HTTPS | `https://mediamtx.<DOMAIN>/<stream>/` | platform **SSO** (oauth2-proxy/Keycloak) |
| **Write / Publish (ingest)** | RTSP / RTMP / SRT / WebRTC / RTP | native ports on the LB IP `10.17.32.22` | MediaMTX publish credentials (from the `mediamtx-secret`) |
| **Read (in-cluster app/analytics)** | HLS / RTSP | `mediamtx-svc.mediamtx` | MediaMTX credentials (no SSO) |

- **HTTPS is read-only (HLS).** You cannot push a camera over `https://` — that endpoint only serves HLS playback.
- **Publishing uses native ports** (RTSP 8554, RTMP 1935, SRT 8890, RTP 8000/8001, WebRTC 8889/8189).

## Architecture

```
                              ┌──────────────────────────────────────────────┐
 Publishers (any)             │                 PCAI / dc15-0103              │
 ┌──────────────┐  RTSP/RTMP  │  ┌─────────────────┐   HLS  ┌──────────────┐  │  Browser
 │ Camera/ffmpeg│────────────▶│  │   MediaMTX      │◀──────▶│ ezaf-gateway │──┼──▶ https://mediamtx.<DOMAIN>/<stream>/
 │ upstream pull│ (source)     │  │  (pod)          │        │ (ISTIO, SSO) │  │  (public, logged-in)
 │ UDP RTP push │──8000/8001───│  │  :8554/:8888/...│        └──────────────┘  │
 └──────────────┘              │  └───────▲────────┘                           │
                                │          │  in-cluster HLS/RTSP               │
                                │   ┌──────┴──────────┐                          │
                                │   │ mediamtx-svc     │── analytics apps ───────┘
                                │   │ mediamtx-stream  │  (LB 10.17.32.22)
                                │   └─────────────────┘
```

## Deploy (or upgrade)

```bash
cd frameworks/mediamtx

# 1. Create the publish-credentials Secret (prompts for a password; defaults user=admin)
scripts/create-auth-secret.sh
#   or non-interactive: MTX_PUBLISH_PASSWORD=password scripts/create-auth-secret.sh

# 2. Install / upgrade
helm upgrade mediamtx ./mediamtx -n mediamtx -f values-pc.yaml \
  --set streamingService.loadBalancerIPs[0]=10.17.32.22

# 3. Confirm
kubectl rollout status deployment/mediamtx -n mediamtx --timeout=120s
kubectl get svc mediamtx-stream -n mediamtx   # EXTERNAL-IP should be 10.17.32.22
```

## Porting to another cluster

Everything is chart-driven **except two platform resources** that must be recreated per system: the auth Secret and the MetalLB pool. Full order of operations:

```bash
# 0) Cluster access ready (kubeconfig / node admin.conf).

# 1) Publish-credentials Secret (must exist BEFORE install, or the pod
#    lands in CreateContainerConfigError):
scripts/create-auth-secret.sh mediamtx mediamtx-secret

# 2) MetalLB pool — on the TARGET system (SSH in, run there; the ping probe
#    then uses the correct L2 vantage point). Runs with `sh` or `bash` and
#    needs only kubectl + awk + ping (no python3/jq):
scripts/create-ipaddresspool.sh --apply
#    Discovers a free IP (skips existing pools, assigned LB IPs, node IPs),
#    probe-verified with a TWO-PHASE ping (ARP warm-up + decisive probe — a
#    cold-ARP first ping can make a live gateway look "free", so the script
#    pings twice and never recommends an address that answered), prints the
#    manifest, applies it with --apply, and PRINTS the values-pc.yaml snippet.
#    On a system that ALREADY has mediamtx-pool / mediamtx-stream, the script
#    skips discovery and re-prints the EXISTING configuration (plus deletion
#    instructions) — keep those values; --ip/--cidr override explicitly.
#    Manual variant: edit the <IP> in manifests/mediamtx-ipaddresspool.yaml
#    and kubectl apply it. Prerequisite: MetalLB must exist (the script
#    verifies; if the cluster has no MetalLB, no pool can help).

# 3) Edit values-pc.yaml with the snippet the script printed:
#      streamingService.loadBalancerIPs: ["<new-ip>"]      # pin the IP
#      mediamtxConfig.webrtcAdditionalHosts:
#        - "<new-ip>"              # LB IP (in-network viewers)
#        - "<viewing-laptop-LAN-ip>"  # only when using the SSH shim
#                                   # (browsers discard 127.0.0.1 candidates!)
#    Don't know the laptop's LAN IP? On the laptop:
#      scripts/get-laptop-lan-ip.sh --lb <new-ip>    # prints the paste-ready block

# 4) RENDER values-pc.yaml — it contains literal ${DOMAIN_NAME} placeholders;
#    installing it raw registers the host as "mediamtx.${DOMAIN_NAME}":
DOMAIN_NAME=<new-system-domain> envsubst < values-pc.yaml > /tmp/values-pc.yaml

# 5) Install:
helm install mediamtx . -n mediamtx --create-namespace -f /tmp/values-pc.yaml

# 6) Verify:
kubectl -n mediamtx rollout status deploy/mediamtx
kubectl -n mediamtx get svc mediamtx-stream   # EXTERNAL-IP = <new-ip>, not <pending>
```

Uninstall cleanly (never bare-`kubectl delete ns`): `helm uninstall mediamtx -n mediamtx` — the chart also owns the oauth2-proxy `AuthorizationPolicy` in `istio-system`, which only helm removes. Two post-uninstall notes:
- **ClusterIPs change on every reinstall** — the tunnel/shim scripts therefore target the system's **pinned LoadBalancer IP** by default (stable via the /32 pool; override with `CLUSTER_IP=<ip>`). After a reinstall, restart them (`stop` + `start`) — the connections themselves die with the node session.

**Amendment rules for `manifests/mediamtx-ipaddresspool.yaml`** (manual path): the IP is the only mandatory edit — it must be free on the target LAN, same L2 segment as the nodes, and not overlap existing pools. Verify `metallb-system` exists (pre-installed on PCAI; you never create it by hand).

> If the LB shows no external IP, ensure a MetalLB `IPAddressPool` exists for it — see `manifests/mediamtx-ipaddresspool.yaml`.

## Publish a stream into MediaMTX

### Synthetic test stream (no camera) — recommended for a first check
```bash
kubectl -n mediamtx run ffmpeg-pub --image=linuxserver/ffmpeg --restart=Always -- \
  -re -f lavfi -i "testsrc=size=1280x720:rate=30" \
  -c:v libx264 -preset veryfast \
  -g 30 -keyint_min 30 -sc_threshold 0 \
  -tune zerolatency -fflags nobuffer -flags low_delay \
  -rtsp_transport tcp -f rtsp \
  "rtsp://admin:<password-from-secret>@mediamtx-svc.mediamtx:8554/test"
```
This runs a pod that generates a **test-pattern video (with a timer)**, encodes it to H.264, and publishes it via RTSP (TCP) to MediaMTX at path `test`.

- `-rtsp_transport tcp` **must be in the output section** (right before `-f rtsp`) — RTSP-over-TCP is required for stability through cluster NAT. Placing it as an input option breaks ffmpeg.
- `-g 30 -keyint_min 30 -sc_threshold 0` forces a 1-second GOP. ffmpeg's default GOP (250 frames ≈ 8.3s) forces HLS segments to inflate to ~8s, which is the main cause of the 8–25s delay on the HLS page. With a 1s GOP, HLS drops to ~1–3s.
- `-tune zerolatency -fflags nobuffer -flags low_delay` minimizes encoder-side buffering and speeds up WebRTC first frame.
- Uses the in-cluster service `mediamtx-svc.mediamtx:8554`, so no external IP needed.

Stop it: `kubectl -n mediamtx delete pod ffmpeg-pub --ignore-not-found` (or `kubectl -n mediamtx delete deployment ffmpeg-pub`).

### Real camera from a Mac

**From the laptop (via the SSH tunnel — recommended, self-healing):**
```bash
export JUMP_PASS=...
scripts/stream-laptop-camera.sh start     # tunnel (keepalive-enabled)
scripts/stream-laptop-camera.sh publish   # camera, auto-republish on drops
```
The `publish` mode retries every 2 s when the connection blips (plain ffmpeg has no RTSP reconnect — without the loop, the stream silently disappears and WebRTC fails while HLS shows stale frames). Stop with Ctrl-C + `stream-laptop-camera.sh stop`.

The tunnel targets the **pinned LoadBalancer IP** by default (`CLUSTER_IP=10.17.32.22` on dc15 — stable across reinstalls via the /32 pool; override with `CLUSTER_IP=<ip>` if your system differs). After any `helm uninstall`/reinstall, restart the tunnels/shim (`stop` + `start`) — the SSH connections die with the session.

**Direct publish (needs the Mac to reach `10.17.32.22`, e.g. VPN):**
```bash
ffmpeg -f avfoundation -framerate 30 -video_size 1280x720 -i "0" \
  -c:v libx264 -preset veryfast -pix_fmt yuv420p \
  -g 30 -keyint_min 30 -sc_threshold 0 \
  -tune zerolatency -fflags nobuffer -flags low_delay \
  -rtsp_transport tcp \
  -f rtsp "rtsp://admin:<password-from-secret>@10.17.32.22:8554/cam"
```

### Pull from an upstream MediaMTX (the metadata-driven use case)
Set in `values.yaml`:
```yaml
upstreams:
  enabled: true
  baseUrl: "rtsp://<upstream-ip>:8554"
```
Then any requested path relays from the upstream (MediaMTX's regex proxy). Explicit per-path sources go under `paths:` (e.g. `source: rtsp://<camera-ip>/...`).

### Listen for incoming UDP (RTP/SRT)
RTP is received on `10.17.32.22:8000` (RTP) / `:8001` (RTCP), SRT on `:8890` (UDP). These are exposed on the `mediamtx-stream` LB. (Validating this is an open item — see porting.md.)

## Consume / watch a stream

### Latency cheat-sheet

| How you watch | Latency | Works from |
|---|---|---|
| WebRTC player page `/wrtc/<path>/` — in-network machine | **~200–500 ms** | any machine that reaches `10.17.32.22:8189/UDP` |
| WebRTC player page + `scripts/watch-webrtc.sh` (UDP-over-SSH shim) | **~200–500 ms** | any machine with SSH access (e.g. the laptop) |
| HLS player page `/<path>/` | ~1–3 s (with a tuned publisher; see "Latency tuning") | everywhere (HTTPS only) |

### URLs (stream `test` shown; substitute your path)

| Consumer | URL | Auth |
|---|---|---|
| **Real-time (WebRTC)**, in-network | `https://mediamtx.<DOMAIN>/wrtc/test/` | SSO (browser login) |
| **Real-time (WebRTC)**, over SSH shim | `https://mediamtx.<DOMAIN>/wrtc/<path>/` + `scripts/watch-webrtc.sh start <path>` | SSO |
| Browser player (HLS) | `https://mediamtx.<DOMAIN>/test/` | SSO (browser login) |
| HLS manifest (app/ffplay/OpenCV) | `https://mediamtx.<DOMAIN>/test/index.m3u8` | SSO (needs session/token) |
| HLS, in-cluster (no SSO) | `http://mediamtx-svc.mediamtx:8888/test/index.m3u8` | none |
| RTSP, in-cluster (low latency) | `rtsp://admin:<password-from-secret>@mediamtx-svc.mediamtx:8554/test` | MediaMTX creds |
| RTSP, external | `rtsp://admin:<password-from-secret>@10.17.32.22:8554/test` | MediaMTX creds |

Where `<DOMAIN>` = `dc15-0103-ai-application.pcai0103.dc15.hpecolo.net`.

> **Trailing slash required** on `/wrtc/<path>/` — MediaMTX 302-redirects slash-less URLs to an absolute path that would drop the `/wrtc` prefix.

### End-to-end: stream your camera, watch it in real time

The canonical order (one command per terminal; keep 1–3 running while you watch):

```bash
export JUMP_PASS=...        # jump host (steps 1 & 3)
export RTSP_PASS=...        # publish password from mediamtx-secret (step 2)

1) scripts/stream-laptop-camera.sh start     # SSH tunnel → MediaMTX
2) scripts/stream-laptop-camera.sh publish   # camera → live on path 'cam' (self-healing)
3) scripts/watch-webrtc.sh start             # real-time shim → open /wrtc/cam/
4) scripts/watch-webrtc.sh stop              # when done WATCHING
5) scripts/stream-laptop-camera.sh stop      # when done STREAMING
```

- Steps 1–3 can run in any relative order — the player page retries every 2 s and self-resolves.
- Steps 4 and 5 are independent of each other; stop in whichever order you finish.
- Others on the network can watch the same stream at ~1–3 s latency on `/cam/` without running anything.
- Watch at `https://mediamtx.<DOMAIN>/wrtc/cam/` (trailing slash!).

### Real-time watching from an SSH-only machine (the shim)

WebRTC media is UDP; SSH-only machines have no UDP route into the cluster. `scripts/watch-webrtc.sh` bridges this with two tiny relays that frame the UDP packets over the existing SSH tunnel. The shim itself is path-agnostic — it carries whatever stream you open.

```bash
export JUMP_PASS=...
scripts/watch-webrtc.sh start cam    # or: start <any-path>
# open https://mediamtx.<DOMAIN>/wrtc/cam/  (trailing slash!)
scripts/watch-webrtc.sh stop        # when done
```

- The node-side relay runs **as the SSH session's remote command**, so killing the tunnel always cleans it up.
- One watching tab per watch instance (per machine); multiple machines each run their own instance — the node relay is multi-session.
- If the SSH session blips, the player page auto-reconnects within ~2 s.
- **Why the laptop's LAN IP matters:** MediaMTX advertises it as an ICE candidate (set in `values-pc.yaml` → `webrtcAdditionalHosts`). Browsers discard remote `127.0.0.1` candidates (anti-localhost-scanning security policy in Chrome/Safari/Firefox), so the shim must be addressed via a normal unicast IP — the relay therefore binds `0.0.0.0:8189` on the viewing machine. If the laptop's DHCP IP changes, update the value + `helm upgrade`.

### Player page vs. HLS manifest
- **`/test/`** = the HTML player page (open in a browser to *see* the video).
- **`/test/index.m3u8`** = the HLS **playlist** that a player/app fetches to download the video segments. Opening it raw shows text, not video. `index.m3u8` is just the conventional HLS filename MediaMTX serves for each path.

### Recording to S3 (MinIO)

MediaMTX records fMP4 segments to a shared volume; an **rclone sidecar** moves completed segments to an S3-compatible endpoint (MinIO). Disk usage stays bounded **by design**: MediaMTX's native `recordDeleteAfter` deletes local segments older than `recording.localRetention` — even when MinIO is unreachable, the volume can only ever hold the retention window (no PVC-full failure mode).

```
MediaMTX (record) → /recordings (shared volume) → rclone sidecar → MinIO S3
                                       └─ recordDeleteAfter deletes aged segments
Playback (the recording — past, within the local window; SSO):
  List segments:  https://mediamtx.<DOMAIN>/playback/list?path=<path>
  Play a window:  https://mediamtx.<DOMAIN>/playback/get?path=<path>&start=<RFC3339-UTC>&duration=<e.g. 1m>
  (the stream path is a QUERY PARAM — there is no /playback/<path> route)
Archive:  older segments live only in MinIO (console / boto3 / mc)
```

**Prerequisites**
1. MinIO installed (in-cluster S3 API, e.g. `http://minio.minio.svc.cluster.local:9000`) — `frameworks/minio/` chart; create the target bucket via the console.
2. Credentials Secret (keys `accessKey`, `secretKey`) — **you run this yourself**:
   ```bash
   scripts/create-s3-secret.sh mediamtx mediamtx-s3-creds
   # prompts for the MinIO access/secret key (or env: MINIO_ACCESS_KEY / MINIO_SECRET_KEY)
   ```

**Enable** in `values-pc.yaml`:
```yaml
recording:
  enabled: true
  recordAll: true                  # or: paths: ["cam", "test"]
  localRetention: 2h               # local window = what the playback server can serve
  volume: {type: pvc, size: 10Gi}
  s3:
    endpoint: "http://minio.minio.svc.cluster.local:9000"
    bucket: "mediamtx-recordings"
    existingSecret: "mediamtx-s3-creds"
```
Then `envsubst` + `helm upgrade` as usual.

**On-the-fly toggle** (ephemeral — resets on pod restart, same as dynamic sources):
`PATCH /v3/config/paths/modify/<name> {"record": true}` on the Control API (9997).

**Key values**: `recording.segmentDuration` (1m → S3-friendly chunks), `recording.s3.minAge` (skip files still being written), `recording.s3.deleteLocal` (move vs copy), `recording.localRetention` (the disk guard — must exceed the upload interval).

**Verify**: publish a stream → objects appear in MinIO within ~1–2 min (`s3.list_objects_v2(Bucket=…)` or the console) → local directory never exceeds the retention window → playback server serves the local window.

### Latency tuning (why your HLS was slow)
The dominant cause of multi-second HLS delay is the **publisher's GOP**: ffmpeg's default GOP is 250 frames (≈8.3 s at 30 fps), and since MediaMTX must start each HLS segment on an IDR frame, segments inflate to ~8 s and the player buffers ~3 of them → 8–25 s. Publishing with a 1-second GOP (`-g 30 -keyint_min 30 -sc_threshold 0 -tune zerolatency -fflags nobuffer -flags low_delay`) brings HLS to ~1–3 s for every viewer, and speeds up WebRTC first-frame. MediaMTX already runs the lowLatency HLS variant by default (`hlsVariant: lowLatency`, 200 ms parts).

### From video-analytics code (in-cluster, recommended)
```python
import cv2
cap = cv2.VideoCapture("rtsp://admin:<password-from-secret>@mediamtx-svc.mediamtx:8554/test")
while True:
    ret, frame = cap.read()
    # run analytics on `frame`
```
or
```python
cap = cv2.VideoCapture("http://mediamtx-svc.mediamtx:8888/test/index.m3u8")
```

## Verify it works (smoke test)

1. Publish the test stream (command above).
2. Watch in a browser (login via SSO): `https://mediamtx.<DOMAIN>/test/` → you should see the test pattern with a **timer**.
3. Confirm MediaMTX sees the stream:
   ```bash
   kubectl -n mediamtx logs deploy/mediamtx --tail=20 | grep -E "RTSP|path test|HLS"
   # e.g. "[path test] stream is available and online, 1 track (H264)"
   ```
4. List paths via the Control API (in-cluster):
   ```bash
   kubectl -n mediamtx run api --rm -it --restart=Never --image=curlimages/curl -- \
     http://mediamtx-svc.mediamtx:9997/v3/paths/list
   ```
   (You should see `test` with a `publisher`.)

## Configuration reference (key `values.yaml` knobs)

| Key | Default | Meaning |
|---|---|---|
| `ezua.virtualService.endpoint` | `mediamtx.<DOMAIN>` | Public HTTPS host (HLS player) |
| `ports` | rtsp 8554, rtp 8000, rtcp 8001, rtmp 1935, hls 8888, webrtc 8889, webrtcUdp 8189, srt 8890, api 9997, metrics 9098 | MediaMTX listeners |
| `streamingService` | LoadBalancer, IP `10.17.32.22` | Exposes native publish/read ports externally |
| `auth` | existingSecret `mediamtx-secret`, user `admin` | publish/read credentials (injected as env, never in a ConfigMap) |
| `upstreams.enabled/baseUrl` | false / `<upstream-ip>` | Relay/pull from an upstream MediaMTX |
| `paths` | `all_others: { source: publisher }` | Per-path sources (publisher push or URL pull) |
| `metrics.enabled` | false | MediaMTX `/metrics` on `:9098` |
| `probePort` / probe `path` | `api` / `/v3/info` | Health probes (API is the stable 200 endpoint) |

Full details: `values.yaml` (heavily commented).

## Troubleshooting

- **`curl`/`ffplay` on the public URL → login redirect / "Input/output error"** — the public HTTPS path is SSO-protected. Use a logged-in browser, pass a token, or use the in-cluster URLs.
- **Publish works ~10s then dies ("session timed out" / Broken pipe)** — ffmpeg was using RTSP/UDP; add `-rtsp_transport tcp` in the **output** section.
- **`Option rtsp_transport not found`** — you put `-rtsp_transport tcp` in the **input** section; move it before `-f rtsp`.
- **Root `https://mediamtx.<DOMAIN>/` shows "404 page not found"** — MediaMTX serves no root page; per-stream pages are at `/<stream>/`. A landing page is a planned improvement (porting.md).
- **`spec.ports[..].name: Invalid value: "webrtcUdp"`** — Kubernetes port names must be lowercase; the chart uses `webrtc-udp`.

## Expand / next steps
Real camera exposure (VPN vs edge-NAT), upstream relay setup, UDP ingress validation, a root landing page, and metrics enablement — see **[porting.md](porting.md) → Notes**.

## Files
```
Chart.yaml, values.yaml
templates/  (deployment, configmap, service, streaming-service, metrics-service, virtualservice, authorizationpolicy, secret, serviceaccount)
manifests/mediamtx-ipaddresspool.yaml   # MetalLB pool for the external LB IP
scripts/create-auth-secret.sh            # create publish credentials Secret
```