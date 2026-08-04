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

It provides a full UI for navigating, uploading, downloading, and editing files across the **Personal** and **Shared** PVCs:

- **Browse** — Folder tree with breadcrumb navigation across Personal and Shared workspaces.
- **Upload** — Drag-and-drop or click-to-select file upload into any folder.
- **Download** — Single files download directly (with optional rename); multiple files or folders are archived as ZIP or TAR.GZ with a custom filename.
- **Edit** — Double-click any text file to open it in the Monaco editor (VS Code's editor engine) with syntax highlighting and save support. Binary or large files show metadata with a download option.
- **CRUD** — Create folders, create files, rename/move, and delete (recursive for directories).
- **Storage Status** — A collapsible panel shows real-time PVC usage (bytes + inodes) for Personal, Shared, and State volumes, with color-coded usage bars.

The data manager runs as a zero-dependency Node.js process (`data_manager.mjs`) inside the user pod on port 7682, alongside ttyd and the opencode supervisor. All file operations are path-traversal-protected (clamped to `/workspace/personal` and `/workspace/shared`).

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
