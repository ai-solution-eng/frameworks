# OpenCode Web — Multi-User version on HPE Private Cloud AI

Deploy and manage multiple isolated [opencode](https://opencode.ai) coding-agent environments on **HPE Private Cloud AI**. Each user gets their own PVC-backed workspace, and a shared workspace enables team collaboration.

---

## Configuration

### opencode.json, Agents & Skills

All configuration lives in `values.yaml`:

| Field | What it defines |
|---|---|
| `opencodeConfig` | The `opencode.json` config (models, providers, MCP servers, permissions) |
| `opencodeSkills` | Skill markdown files seeded into `~/.config/opencode/skills/` |
| `opencodeAgents` | Agent markdown files seeded into `~/.config/opencode/agents/` |
| `opencode.version` | The opencode npm version to install (e.g. `1.18.11`) |
| `openchamber.version` | The OpenChamber npm version to install (used when `ui.mode: openchamber`) |
| `ui.mode` | `opencode` (default, built-in web UI) or `openchamber` (OpenChamber frontend) |

To switch the version of either opencode or OpenChamber, change the number in `values.yaml` and repackage. The chart `version` (in `Chart.yaml`) is bumped manually per release; `appVersion` tracks the opencode major.minor family.

### UI modes

- **`ui.mode: opencode`** (default) — the built-in `opencode web` UI is served on the app port, exactly as before.
- **`ui.mode: openchamber`** — a headless `opencode serve` runs on `ui.serverPort` (loopback, `127.0.0.1`) and [OpenChamber](https://openchamber.dev) is served on `ui.chamberPort` (default `3000`), connecting to it via `OPENCODE_HOST` / `OPENCODE_SKIP_START`. OpenChamber is npm-installed into the user state volume (no separate runtime needed; it runs on the same Node 22 image). The existing terminal / data-manager / preview portals are unchanged. Because the opencode server is loopback-only in this mode, its HTTP basic auth is disabled and access is gated by the inbound `oauth2-proxy` and OpenChamber's `--ui-password` (driven from `auth.password`).

These are bundled into a ConfigMap and copied into each user's `~/.config/opencode/` on first start. Users can **edit any of these files directly** inside their environment — a watcher (`opencode_supervisor.mjs`) monitors `opencode.json`, `config.json`, `opencode.jsonc` and the `skills/` / `agents/` directories for changes and automatically restarts the opencode process. Just **refresh the browser** to see changes take effect.

---

## Warm Pool (instant first launch)

By default, a brand-new user's first launch waits while the router provisions a
per-user Deployment + PVCs and runs a heavy init (`npm install` of opencode,
uv, ttyd, apt packages) — this can take 3–5 minutes.

The router can instead keep a small pool of **already-provisioned, always-ready
user units** so a first-time user's environment is usable in roughly seconds.

```yaml
warmPool:
  enabled: false   # set to true to opt in
  size: 2          # number of always-ready idle user units to maintain
  refreshIntervalSeconds: 15
```

### How it works

- A "warm unit" is the full per-user set — its own Deployment, Service, workspace
  PVC, and **state PVC**. The toolchain (opencode/uv/ttyd/openchamber) is installed
  into the state PVC, so it is built **once** when the unit enters the pool.
- The router runs a background reconcile loop that keeps `size` warm, un-owned,
  and Ready units at all times (it builds a new one whenever one is claimed).
- On a first launch, the router claims the lowest-free warm unit: it patches the
  pod template to set the user's slug (for preview/ttyd URLs) and records the
  user as the unit's owner. The rolling restart is fast because the toolchain is
  already present — no reinstall.
- `size: 0` or `enabled: false` behaves **exactly like before** (on-demand cold
  spin-up; zero idle pods).
- Versions are **not** baked into an image. opencode/OpenChamber remain runtime-
  parameterized, so bumping `opencode.version` / `openchamber.version` in
  `values.yaml` and repackaging still works. Warm units adopt a new version the
  next time they are claimed/re-initialized via the existing template-version
  logic — no image rebuild.

### Tradeoff

Each warm unit is an idle user pod consuming up to `user.resources.limits`
(by default 2 cores / 2 Gi). `warmPool.size` therefore adds a permanent overhead
of `size × those limits`. This is the explicit cost of instant first launch; keep
it `enabled: false` if idle capacity is a concern.

### Uninstall / `helm uninstall`

A `pre-delete` hook deletes the dynamically-created per-user/warm resources
(which Helm does not own) so the namespace and shared PVC do not hang in
`Terminating`. The hook:

1. **Stops the router first** (deletes the router `Deployment`) so it can no
   longer reconcile/re-create warm units while teardown is running.
2. Deletes the per-user **Deployments, Services, and Leases in parallel**.
3. Waits for their **pods to terminate**, then deletes the per-user **PVCs**
   (PVC deletion must wait for the pods that mount them to unmount first, so
   that step is ordered after the pods).
4. Leaves the Helm-owned shared PVC intact (it carries only `hpe-ezua/*`
   labels, not `opencode-user-managed`).

---

## Provisioning Loading Screen

While a user's pod is being assigned/provisioned (a cold first launch can take
3–5 minutes for the per-user `npm install`, uv, ttyd, etc.), the router no
longer leaves the browser hanging on a blank page. It returns a **loading
screen** immediately:

- A spinner plus an elapsed timer and the text "Setting up your
  environment…".
- The page polls the router's `/__oc_setup_status` endpoint every 2 seconds.
- When the pod becomes ready, the page **auto-reloads** and proxies you into
  your environment automatically.
- If provisioning fails or times out, the page swaps to an error state with a
  **Retry** button (the retry clears the failed provisioning attempt and
  starts over).

With a [warm pool](#warm-pool-instant-first-launch) enabled the loading
screen appears only briefly during the fast rolling restart of a claimed
warm unit (no reinstall), so it is near-instant.

### Configuration

```yaml
provisioning:
  loadingUI:
    enabled: true                      # set false to restore the original blocking behavior
    heading: "Setting up your environment…"
    subtext: "This usually takes a few minutes on first launch. Please wait."
```

- `enabled: false` reverts the router to its previous behavior (the request
  blocks until the pod is ready and no loading page is shown).
- The heading and subtext are the messages shown on the loading screen.
- The status/reset endpoint is the reserved router path `/__oc_setup_status`;
  it is handled by the router itself (never proxied to the user pod) and
  requires no ready pod.

---

## Workspaces

HPE Private Cloud AI provides PVC-backed persistent storage:

| Mount point | Type | Purpose |
|---|---|---|
| `/workspace/personal` | `ReadWriteOnce` PVC | **Personal workspace** — private to each user |
| `/workspace/shared` | `ReadWriteMany` PVC | **Team collaboration** — all users share this space |

Every user gets their own personal PVC (sized via `storage.workspaceSize`) and state PVC (`storage.stateSize`). The shared PVC (`storage.sharedSize`) is populated with initial content from the `shared/` directory at deploy time.

---

## Demo Content

Pre-seeded demos help you get started immediately.

### Personal workspace (`/workspace/personal/`)

| File | Description |
|---|---|
| `README.html` | Interactive landing page with copy-paste tutorials for three use cases: Basic Web App (confetti button), Intermediate Web App (coin flip), and Advanced Agentic Workflow (financial advisor with stock research, email draft, feedback). Also lists available MCP tools and provides quick-start instructions. |
| `README.md` | Markdown version of the same demo guide and use-case walkthroughs. Alternative to the html file.|

Each tutorial ends with a `create-server.sh` command to launch a preview server and get a shareable URL.

### Shared workspace (`/workspace/shared/`)

| Directory | Tech | Description |
|---|---|---|
| `toy-web/` | Static HTML/CSS | Simple web page — no dependencies, run with `python3 -m http.server` |
| `toy-gradio/` | Gradio | Interactive ML/demo UI — run with the shared venv |
| `toy-streamlit/` | Streamlit | Data app dashboard — run with the shared venv |
| `toy-uvicorn/` | FastAPI + Uvicorn | REST API backend — run with the shared venv |

A shared Python virtual environment (`/workspace/shared/.venv-preview/`) and `requirements.txt` are provided so you can install dependencies once and run any of the Python-based demos.

---

## Terminal

The built-in opencode web terminal can be unreliable in this environment, with text leaking across terminals. To address this, a dedicated **tabbed, multi-terminal UI** (built on ttyd + tmux) is served at:

```
https://opencode-web-k8s.{DOMAIN_NAME}/terminal
```

It is always available and gives you **multiple independent terminal tabs**, each with the same environment as the opencode agent. Run `opencode` in one tab, `python` in another, and `vim` in a third — they are fully isolated subprocesses.

### Tab model

- **`+`** opens a new terminal tab (a fresh, independent subprocess).
- **Closing the browser tab / reloading the page** only *detaches* — each terminal keeps running in an independent tmux session.
- Reopening `/terminal` lists your still-running terminals and re-attaches them, so you pick up where you left off from your last session.
- **`✕`** on a tab *destroys* it: the subprocess is terminated and the terminal is freed (it will not reappear on reload).
- Terminals persist for the lifetime of your running pod (they are not restored across a pod restart).

---

## Data Manager

A web-based file manager is served at:

```
https://opencode-web-k8s.{DOMAIN_NAME}/data_manager
```

It provides a full UI for navigating, uploading, downloading, and editing files across the **Personal**, **Shared**, and **Config** (`~/.config`) roots:

- **Browse** — Folder tree with breadcrumb navigation across Personal, Shared, and Config. The Config root also shows hidden dotfiles.
- **Upload** — Drag-and-drop or click-to-select file upload into any folder.
- **Download** — Single files download directly (with optional rename); multiple files or folders are archived as ZIP or TAR.GZ with a custom filename.
- **Edit** — Double-click any text file to open it in the Monaco editor (VS Code's editor engine) with syntax highlighting and save support. Binary or large files show metadata with a download option.
- **CRUD** — Create folders, create files, rename/move, and delete (recursive for directories).
- **Storage Status** — A collapsible panel shows real-time PVC usage (bytes + inodes) for Personal, Shared, and State volumes, with color-coded usage bars.

The data manager runs as a zero-dependency Node.js process (`data_manager.mjs`) inside the user pod on port 7682, alongside ttyd and the opencode supervisor. All file operations are path-traversal-protected (clamped to `/workspace/personal`, `/workspace/shared`, and `/var/opencode/home/.config`).

---

## Preview URLs & Port Watcher

A background watcher (`port_watcher.mjs`) polls `/proc/net/tcp` every 3 seconds. When any process listens on a port in the 3000–9999 range (excluding reserved ports), the watcher:

1. Generates a public preview URL: `https://u-{slug}-p-{port}.{DOMAIN_NAME}`
2. Prints the URL directly to the terminal (and all PTY sessions)
3. Writes it to a state file for querying via the `preview-url` helper

The platform's routing layer (Istio VirtualService + nginx sidecar) forwards traffic from `*.{DOMAIN_NAME}` to the correct local port.

### Quick start a preview server

```bash
/workspace/create-server.sh /workspace/personal/my-file.html 8000
# → [preview] Preview available for port 8000: https://u-abc123def456-p-8000.{DOMAIN_NAME}
```

---

## Quick Reference

```bash
# List active preview ports
preview-url

# Get URL for a specific port
preview-url 8000

# Launch a static file server
/workspace/create-server.sh <file-or-dir> <port>
```

### Key files inside the user environment

| Path | Purpose |
|---|---|
| `~/.config/opencode/opencode.json` | Agent config (editable, hot-reloaded) |
| `~/.config/opencode/agents/` | Custom agent definitions |
| `~/.config/opencode/skills/` | Custom skill definitions |
| `/workspace/personal/` | Your private workspace |
| `/workspace/shared/` | Team shared workspace |
| `/workspace/create-server.sh` | Preview server launcher |
