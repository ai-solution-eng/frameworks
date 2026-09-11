# Porting - MediaMTX

Self-contained real-time media server for HPE Private Cloud AI: the **mediamtx**
chart (v0.0.1, appVersion `bluenviron/mediamtx` 1.17.1) deploys MediaMTX —
RTSP/RTMP/SRT/RTP ingest, HLS and WebRTC playback — behind one Istio
`ezaf-gateway` endpoint at `https://mediamtx.${DOMAIN_NAME}`, with native
streaming ports exposed through a MetalLB LoadBalancer, optional S3 (MinIO)
recording via an rclone sidecar, and a recordings web UI. Deployed via the PCAI
**Import Framework** button; `${DOMAIN_NAME}` is substituted by the platform at
import time. The chart is written self-contained rather than ported from an
upstream chart (see HPE notes).

> For usage, deploy and test steps, see **[README.md](README.md)**.

## values.yaml

```yaml
ezua:
  domainName: ${DOMAIN_NAME}
  virtualService:
    endpoint: mediamtx.${DOMAIN_NAME}
    istioGateway: istio-system/ezaf-gateway
  authorizationPolicy:
    namespace: istio-system
    providerName: oauth2-proxy
```

- The VirtualService routes the endpoint to `<release>-svc:8888` (the HLS
  server, which serves the per-stream web player) plus dedicated routes for
  WebRTC and playback (below). The oauth2-proxy AuthorizationPolicy
  (`action: CUSTOM`, provider `oauth2-proxy`, matching the endpoint host) is
  created in `istio-system` — the importing user needs RBAC there.
- `domain: mediamtx.${DOMAIN_NAME}` is the portal "Open" button target.
- Publish credentials live in a k8s Secret (`mediamtx-secret`, keys
  `publishUser`/`publishPassword`, created by `scripts/create-auth-secret.sh`)
  and are injected as `MTX_AUTHINTERNALUSERS_1_*` env — the password never
  appears in a ConfigMap. MinIO credentials come from `mediamtx-s3-creds`
  (`scripts/create-s3-secret.sh`).
- `values-pc.yaml` is the environment-override template (WebRTC hosts,
  LoadBalancer IP, CA injection); `values-deployment.yaml` is a full snapshot
  of the deployed state.

### Chart design

| Decision | Why |
|---|---|
| Self-contained chart, no `st-common` dependency | No second kubeVersion/packaging dependency (see HPE notes) |
| `kubeVersion: ">=1.25.0-0"` | Runs on PCAI's `v1.33.4-hpe1` — pre-release semver only satisfies a constraint that itself carries a pre-release component |
| Probes on `api` port `9997` at `/v3/info` | The API server has no `/` route and the HLS root returns MediaMTX's default 404; `/v3/info` is a guaranteed-200 endpoint |
| `api: true` | Enables the Control API (web dashboard/player + REST) — disabled by default in MediaMTX |
| Publish auth via k8s Secret | Native ports are exposed; the password is injected as env, never stored in a ConfigMap |
| Anonymous `any` = `read` + `api` (+ `playback`) | The HLS web player/dashboard sits behind oauth2-proxy SSO; requiring MediaMTX credentials there would cause double login prompts |
| Corrected port map | SRT is `8890/UDP`, WebRTC ICE `8189/UDP`; RTP/RTCP `8000/8001` UDP added for UDP ingress; the ICE port name is `webrtc-udp` (k8s port names are RFC-1123 lowercase) |
| `streamingService` LoadBalancer | Exposes native publish/read ports externally (RTSP/RTMP/SRT/RTP/WebRTC/HLS) |
| `upstreams` + `metrics` toggles | Native MediaMTX features surfaced as easy chart options |

### PCAI integration

- **Public HTTPS/HLS:** a `VirtualService` (`networking.istio.io/v1`) hosts
  `mediamtx.<DOMAIN>` → `mediamtx-svc:8888` (HLS) via `istio-system/ezaf-gateway`,
  with an oauth2-proxy `AuthorizationPolicy` for SSO. DNS resolves through the
  EZUA VirtualService; cert-helper provisions the per-host certificate.
- **Native ports:** `mediamtx-stream` (MetalLB LoadBalancer). Because the
  cluster's default MetalLB pool can be exhausted, the chart ships
  `manifests/mediamtx-ipaddresspool.yaml` (IPAddressPool + L2Advertisement for a
  dedicated `/32` pool). The dc15 API server **prunes `spec.loadBalancerIPs`**
  (LoadBalancerIPs feature gate off) — the helm value is recorded but the
  Service spec drops it, so IP pinning relies on the dedicated `/32` pool, which
  must exist before the Service is created.
- **Reachability model:** HTTPS = read/HLS (SSO-protected); publishing = native
  ports on the LB IP. The system is publicly exposed, but the LB IP is an
  internal address — external publishers need the **VPN** or a public
  **edge-NAT** to the LB IP.

### Recording to S3

MediaMTX records fMP4 segments to a PVC (`/recordings`); an **rclone sidecar**
(`s3-sync`, `rclone/rclone:1.68`) copies completed segments to an S3-compatible
endpoint (in-cluster MinIO). The sidecar exists because MediaMTX's image is
scratch-based (no shell, no tools) — recording hooks (`runOnRecordSegment*`)
cannot exec anything in-container.

- `recordDeleteAfter` (= `recording.localRetention`) deletes local segments
  older than the retention window regardless of upload success — the volume
  holds at most one retention window, so there is no PVC-full failure mode even
  with S3 down. The sidecar's `--min-age` skips files still being written.
- Default is `rclone copy` (segments stay local for the full retention window,
  so the playback server serves it); `recording.s3.deleteLocal: true` switches
  to `rclone move` (archive-only).
- A **playback server** (VOD with time-range seek, `:9996` → gateway
  `/playback/`) and a **recordings web UI** sidecar (`python:3.12-alpine`,
  list/download/delete archived segments at gateway `/recordings/`, deletes are
  PERMANENT) expose the recorded content behind the same SSO.

### WebRTC real-time playback

- **Two extra VirtualService routes:** MediaMTX v1.x WHEP structure is
  `POST /{path}/whep` (signaling) and `PATCH/DELETE /{path}/whep/{uuid}`
  (session) — matched by a regex for any path. The built-in WebRTC player page
  derives its signaling URL **relatively** (`new URL("whep", location.href)`),
  so the page is exposed under a rewritten prefix `/wrtc/` → `:8889` (rewrite
  `/`), keeping page, `reader.js` and the initial WHEP POST same-origin over
  HTTPS. Session URLs returned in the `Location` header are path-absolute
  (`/{path}/whep/{uuid}`), which the regex route catches without rewrite. The
  catch-all `/` → `:8888` (HLS) stays last, so HLS behavior is unchanged.
- **ICE candidates:** the pod's own IPs are unreachable from outside;
  `webrtcAdditionalHosts` advertises the LoadBalancer IP (in-network viewers)
  and the viewing laptop's LAN IP (the SSH UDP shim).
- **Browser loopback filtering:** remote ICE candidates on `127.0.0.1` are
  discarded by Chrome/Safari/Firefox as an anti-localhost-scanning security
  policy — a shim addressed via loopback silently never connects ("peer
  connection closed"). The shim must be advertised + bound via a real unicast
  IP (laptop LAN IP, relay binds `0.0.0.0:8189`).
- **The UDP-over-SSH shim:** browsers cannot do WebRTC media over TCP, and
  OpenSSH forwards TCP only. `scripts/webrtc-udp-relay.py` frames UDP datagrams
  (2-byte BE length prefix) over one bidirectional TCP stream; the node-side
  relay runs **as the SSH session's remote command** so its lifetime is bound
  to the tunnel (nothing backgrounded survives session close on hardened nodes
  with systemd `KillUserProcesses`). One watching tab per tunnel;
  multi-session server (per-connection UDP socket). The laptop-side relay
  re-learns the browser's address on every packet (self-healing against stray
  probes and reconnects).
- **Publish flapping:** plain ffmpeg has no RTSP reconnect — when the tunnel
  blips, the publisher dies or hangs on a half-open socket and WebRTC fails
  instantly while HLS masks the gap with buffered segments.
  `scripts/stream-laptop-camera.sh publish` wraps ffmpeg in a 2 s retry loop,
  and the tunnel uses `ServerAliveInterval`/`ExitOnForwardFailure` so dead
  sessions fail fast and get rebuilt. Publisher EOFs right after an
  upgrade/reinstall are usually killed connections, not encoder issues — the
  retry loop rides them out.
- **Latency:** HLS delay is dominated by the publisher's default GOP (250
  frames ≈ 8.3 s → segments inflate → player buffers ~3). 1-second GOP
  publishing (`-g 30 …`) brings HLS to ~1–3 s; WebRTC stays at ~200–500 ms.

### Playback server

- Routes are root-level `GET /list` and `GET /get`; the stream path is a
  **query param** (`path=cam`), not a URL segment. Start times are **UTC
  RFC3339** (local-clock values read as future windows → 404). The server
  requires its own `playback` auth permission (granted to the anonymous user
  when recording is enabled).
- **Envoy prefix rewrite + `rewrite: /` can produce a double slash** — a VS
  route matching `prefix: /playback` (no trailing slash) with `rewrite: /`
  turns `/playback/get` into `//get`, which gin answers with a bare
  `404 page not found` (the route never matches). Always match prefixes
  **with a trailing slash** (`prefix: /playback/`) when rewriting onto `/`,
  exactly like the `/wrtc/` route.

## Notes

- **HTTPS is not a publish channel.** The gateway only proxies HTTP → HLS.
  Getting a stream *in* requires a native protocol (RTSP/RTMP/SRT/RTP/WebRTC)
  on a native port.
- **SSO protects the web face.** `curl`/`ffplay` on the public URL are
  redirected to Keycloak; only a logged-in browser (or an app with a token) can
  read HLS publicly. In-cluster consumers use `mediamtx-svc.mediamtx` (no SSO).
- **RTSP-over-TCP through NAT.** ffmpeg publishing via RTSP/UDP dies after
  ~10s behind kube-proxy/NAT ("session timed out" / Broken pipe). Use
  `-rtsp_transport tcp` **in the output section** — placing it as an input
  option gives `Option rtsp_transport not found`.
- **ClusterIPs change on every uninstall/reinstall** — services are recreated
  with new ClusterIPs, and nodes cannot resolve `*.svc.cluster.local` DNS
  (CoreDNS is pod-side only). The tunnel/shim scripts default to the pinned
  LoadBalancer IP (stable via the dedicated `/32` pool; `CLUSTER_IP=<ip>`
  overrides per system) and `stop` kills the tunnel by its LOCAL forward
  (`-L <local-port>:…`) so cleanup never depends on the target IP. Tunnel
  targets must be an IP — a DNS name in `ssh -L` fails on the node. Restart
  the tunnels/shim after any reinstall.
- **MediaMTX has no root page** — `/` returns MediaMTX's default 404;
  players are per-stream at `/<stream>/`.
- **More than a handful of SSH-only real-time viewers** would need coturn
  (TURN over TCP on a reachable port) instead of per-machine shims — currently
  blocked because only ports 443/20022 are reachable on the edge IP, both
  occupied.

## Files

```
Chart.yaml, values.yaml          # chart definition + defaults
values-pc.yaml                   # environment-override template (envsubst ${DOMAIN_NAME})
values-deployment.yaml           # full snapshot of the deployed state (dc15)
templates/                       # deployment, configmap (mediamtx.yml), services,
                                 # VirtualService (HLS + WebRTC + playback routes),
                                 # AuthorizationPolicy, serviceaccount, pvc
manifests/mediamtx-ipaddresspool.yaml   # MetalLB IPAddressPool + L2Advertisement
scripts/create-auth-secret.sh    # create the publish-credentials Secret
scripts/create-s3-secret.sh      # create the MinIO-credentials Secret
scripts/create-ipaddresspool.sh  # discover free IP (two-phase ping) + generate/apply the MetalLB pool
scripts/get-laptop-lan-ip.sh     # detect the viewing laptop's LAN IP + paste-ready snippet
scripts/stream-laptop-camera.sh  # publish laptop camera via SSH tunnel (runbook, self-healing)
scripts/watch-webrtc.sh          # watch in real time via the UDP-over-SSH shim
scripts/webrtc-udp-relay.py      # UDP<->TCP relay used by the shim
ui/app.py                        # recordings web UI (mounted into the recordings-ui sidecar)
README.md                        # usage guide (+ "Porting to another cluster")
```

# HPE notes

- Chart written self-contained rather than porting the upstream
  `startechnica/mediamtx` chart: that chart (and its `st-common` dependency)
  declares `kubeVersion: >=1.25.0`, and PCAI clusters report
  `v1.33.4-hpe1` — the `-hpe1` suffix is a semver **pre-release**, which
  Helm (Masterminds/semver) does not let satisfy a bare `>=` constraint even
  though 1.33 is far above 1.25. The chart therefore declares
  `kubeVersion: ">=1.25.0-0"` so `v1.33.4-hpe1` satisfies it.
- Packaged as `mediamtx-0.0.1.tgz` at the repo root and imported via the PCAI
  **Import Framework** button (namespace = release namespace; values pasted at
  import time). Bump the version in `Chart.yaml` for every re-import — PCAI
  rejects re-uploading the same application name + version.
- A raw `helm install` does **not** resolve `${DOMAIN_NAME}` — run
  `envsubst < values-pc.yaml` first; the Import wizard substitutes it
  automatically.
- Verified with `helm lint` and `helm template` (default + `values-pc.yaml`
  render). Deployed on dc15 (namespace/release `mediamtx`); the full deployed
  state is snapshotted in `values-deployment.yaml` (recording on + recordAll,
  `webrtcAdditionalHosts`, pinned LB IP `10.17.32.22`, CA-bundle injection via
  `certificatesPolicy`, rclone `s3-sync` sidecar).
- Create both Secrets before install: `mediamtx-secret`
  (`scripts/create-auth-secret.sh`) and `mediamtx-s3-creds`
  (`scripts/create-s3-secret.sh`).
- MetalLB: on a fresh system run `scripts/create-ipaddresspool.sh` (two-phase
  ping discovery; skips existing pools/assigned LBs/node IPs; runbook in README
  "Porting to another cluster"). The pool must exist before the streaming
  Service is created, or the Service sits without an external IP.
