#!/usr/bin/env python3
"""Recordings UI + API for MediaMTX on PCAI.

Serves:
  GET  /                     the single-page UI (vanilla JS, no external assets)
  GET  /api/list?path=cam    JSON: {archive:[S3 objects], local:[segment files]}
  GET  /api/download?path=&key=    streams a MinIO object as an attachment
  GET  /api/download_local?path=&file=   streams a LOCAL segment as an attachment
  POST /api/delete           body {"path","key"}     -> S3 DELETE (MinIO archive)
  POST /api/delete_local     body {"path","file"}    -> removes a LOCAL segment

Security model:
  - the gateway (oauth2-proxy SSO) is the authentication gate
  - MinIO: only objects inside BUCKET/<path>/ are touched; keys containing
    ".." or not starting with "<path>/" are rejected
  - local: only files matching the MediaMTX segment filename pattern inside
    RECORD_LOCAL_DIR/<path>/ are touched (no traversal)
S3 access is implemented with stdlib only (SigV4, path-style) — no boto3,
no pip, works air-gapped.
"""

import hashlib
import hmac
import json
import os
import re
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ENDPOINT = os.environ.get("MINIO_ENDPOINT", "http://minio.minio.svc.cluster.local:9000").rstrip("/")
BUCKET = os.environ.get("MINIO_BUCKET", "mediamtx-recordings")
ACCESS = os.environ.get("MINIO_ACCESS_KEY", "")
SECRET = os.environ.get("MINIO_SECRET_KEY", "")
PLAYBACK_API = "http://127.0.0.1:9996"
RECORD_LOCAL_DIR = os.environ.get("RECORD_LOCAL_DIR", "/recordings")
PORT = int(os.environ.get("UI_PORT", "8080"))
REGION = "us-east-1"

_ALLOWED_PATH_RE = re.compile(r"^[A-Za-z0-9._~-]{1,100}$")
_SEG_FILE_RE = re.compile(r"^(\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2})-\d{6}\.mp4$")


def sanitize_path(p):
    p = (p or "").strip()
    if not _ALLOWED_PATH_RE.match(p) or ".." in p:
        return None
    return p


def safe_key(path, key):
    """Key must live strictly inside BUCKET/<path>/ and contain no traversal."""
    if not path or not key:
        return None
    if key.startswith("/") or "\\" in key or ".." in key:
        return None
    prefix = path + "/"
    if not key.startswith(prefix):
        return None
    rest = key[len(prefix):]
    if not rest or ".." in rest:
        return None
    return key


def safe_segment(path, fname):
    """Local segment filename must match MediaMTX's naming pattern and live in
    RECORD_LOCAL_DIR/<path>/."""
    if not path or not fname:
        return None
    if "/" in fname or "\\" in fname or ".." in fname:
        return None
    if not _SEG_FILE_RE.match(fname):
        return None
    return os.path.join(RECORD_LOCAL_DIR, path, fname)


def _enc(s, slash_safe=False):
    safe = "/-._~" if slash_safe else "-._~"
    return urllib.parse.quote(s, safe=safe)


def s3_request(method, key="", query="", payload=b"", extra_headers=None):
    """Signed S3 request (SigV4, path-style). Returns the response object.
    extra_headers: dict of additional headers to SIGN (e.g. {"range": ...})."""
    url = urllib.parse.urlsplit(ENDPOINT)
    host = url.netloc
    object_path = "/" + BUCKET
    if key:
        object_path += "/" + _enc(key, slash_safe=True)
    now = datetime.now(timezone.utc)
    amzdate = now.strftime("%Y%m%dT%H%M%SZ")
    datestamp = now.strftime("%Y%m%d")
    payload_hash = hashlib.sha256(payload).hexdigest()

    hdrs = {
        "x-amz-date": amzdate,
        "x-amz-content-sha256": payload_hash,
    }
    for k, v in (extra_headers or {}).items():
        hdrs[k.lower()] = v

    qitems = sorted(urllib.parse.parse_qsl(query, keep_blank_values=True)) if query else []
    canonical_query = "&".join(f"{_enc(k)}={_enc(v)}" for k, v in qitems)
    canonical_uri = _enc(object_path, slash_safe=True)

    all_headers = {"host": host, **hdrs}
    signed_names = sorted(all_headers.keys())
    canonical_headers = "".join(f"{k}:{all_headers[k]}\n" for k in signed_names)
    signed_headers = ";".join(signed_names)
    canonical_request = "\n".join(
        [method, canonical_uri, canonical_query, canonical_headers, signed_headers, payload_hash]
    )
    scope = f"{datestamp}/{REGION}/s3/aws4_request"
    string_to_sign = "\n".join(
        ["AWS4-HMAC-SHA256", amzdate, scope, hashlib.sha256(canonical_request.encode()).hexdigest()]
    )

    k_date = hmac.new(f"AWS4{SECRET}".encode(), datestamp.encode(), hashlib.sha256).digest()
    k_region = hmac.new(k_date, REGION.encode(), hashlib.sha256).digest()
    k_service = hmac.new(k_region, b"s3", hashlib.sha256).digest()
    k_signing = hmac.new(k_service, b"aws4_request", hashlib.sha256).digest()
    signature = hmac.new(k_signing, string_to_sign.encode(), hashlib.sha256).hexdigest()

    headers = dict(all_headers)
    headers["Authorization"] = (
        f"AWS4-HMAC-SHA256 Credential={ACCESS}/{scope}, "
        f"SignedHeaders={signed_headers}, Signature={signature}"
    )
    target = f"{ENDPOINT}{canonical_uri}"
    if canonical_query:
        target += "?" + canonical_query
    req = urllib.request.Request(target, data=payload if method in ("PUT", "POST") else None, method=method)
    for h, v in headers.items():
        req.add_header(h, v)
    return urllib.request.urlopen(req, timeout=60)


def s3_list(prefix):
    resp = s3_request("GET", query=f"list-type=2&prefix={_enc(prefix)}")
    root = ET.fromstring(resp.read())
    ns = {"s3": "http://s3.amazonaws.com/doc/2006-03-01/"}
    out = []
    for c in root.findall("s3:Contents", ns):
        out.append(
            {
                "key": c.findtext("s3:Key", "", ns),
                "size": int(c.findtext("s3:Size", "0", ns)),
                "modified": c.findtext("s3:LastModified", "", ns),
            }
        )
    out.sort(key=lambda x: x["key"])
    return out


def playback_list(path):
    """Proxy the local playback window (2h) from the MediaMTX playback server."""
    try:
        with urllib.request.urlopen(f"{PLAYBACK_API}/list?path={urllib.parse.quote(path)}", timeout=10) as r:
            data = json.loads(r.read())
            return data if isinstance(data, list) else []
    except Exception:
        return []


def local_list(path):
    """List local segment files with play windows derived from the filenames."""
    d = os.path.join(RECORD_LOCAL_DIR, path)
    if not os.path.isdir(d):
        return []
    files = sorted(f for f in os.listdir(d) if _SEG_FILE_RE.match(f))
    out = []
    for i, fname in enumerate(files):
        start = datetime.strptime(_SEG_FILE_RE.match(fname).group(1), "%Y-%m-%d_%H-%M-%S").replace(
            tzinfo=timezone.utc
        )
        duration = 60.0
        if i + 1 < len(files):
            nxt = _SEG_FILE_RE.match(files[i + 1]).group(1)
            nxt_dt = datetime.strptime(nxt, "%Y-%m-%d_%H-%M-%S").replace(tzinfo=timezone.utc)
            duration = max(1.0, (nxt_dt - start).total_seconds())
        st = os.stat(os.path.join(d, fname))
        out.append(
            {
                "file": fname,
                "size": st.st_size,
                "modified": datetime.fromtimestamp(st.st_mtime, tz=timezone.utc).strftime(
                    "%Y-%m-%d %H:%M:%S"
                ),
                "start": start.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "duration": duration,
            }
        )
    return out


HTML = """<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>MediaMTX recordings</title>
<style>
 body { font-family: system-ui, sans-serif; margin: 24px; background: #111; color: #eee; }
 h1 { font-size: 20px; } h2 { font-size: 15px; margin-top: 28px; color: #9cf; }
 input, button { font-size: 14px; padding: 6px 10px; border-radius: 6px; border: 1px solid #555;
                 background: #222; color: #eee; }
 button { cursor: pointer; } button:hover { background: #333; }
 button:disabled { opacity: 0.4; cursor: default; }
 table { border-collapse: collapse; width: 100%; max-width: 980px; }
 td, th { padding: 6px 10px; border-bottom: 1px solid #333; text-align: left; font-size: 13px; }
 a { color: #7cf; } .size { color: #999; white-space: nowrap; }
 #msg { color: #f96; min-height: 18px; font-size: 13px; }
 #watch { margin-left: 12px; }
</style>
</head>
<body>
<h1>MediaMTX recordings</h1>
<div>
 <label>Stream path: <input id="path" value="cam" size="12"></label>
 <button onclick="refresh()">Refresh</button>
 <button onclick="watchLive()">Watch live</button>
 <button id="openselected" disabled onclick="openSelected()">Open selected (select files first)</button>
 <span id="msg"></span>
</div>
<h2>Local segments (files on disk — playable while they exist)</h2>
<table id="locfiles">
 <thead><tr><th><input type="checkbox" id="selall-local"></th><th>File</th><th>Size</th><th>Modified</th><th></th></tr></thead>
 <tbody></tbody>
</table>
<h2>Archive (MinIO — permanent until deleted)</h2>
<table id="files">
 <thead><tr><th><input type="checkbox" id="selall-archive"></th><th>Object</th><th>Size</th><th>Modified (UTC)</th><th></th></tr></thead>
 <tbody></tbody>
</table>
<script>
function humanSize(n) {
  if (n > 1048576) return (n / 1048576).toFixed(1) + " MB";
  if (n > 1024) return (n / 1024).toFixed(1) + " KB";
  return n + " B";
}
function watchLive() {
  const p = document.getElementById("path").value.trim();
  window.open("/wrtc/" + encodeURIComponent(p) + "/", "_blank");
}
function openSelected() {
  const p = document.getElementById("path").value.trim();
  // Local selections -> live watch tab. Archive selections -> the archived video.
  const localChecked = document.querySelectorAll('#locfiles tbody input.selcheck:checked').length;
  if (localChecked) window.open("/wrtc/" + encodeURIComponent(p) + "/", "_blank");
  document.querySelectorAll('#files tbody input.selcheck:checked').forEach(function (cb) {
    const key = cb.getAttribute("data-key");
    if (key) window.open("api/play?path=" + encodeURIComponent(p) + "&key=" + encodeURIComponent(key), "_blank");
  });
}
function updateSelected() {
  const btn = document.getElementById("openselected");
  const n = document.querySelectorAll('input.selcheck:checked').length;
  btn.disabled = n === 0;
  btn.textContent = n ? ("Open selected (" + n + ")") : "Open selected (select files first)";
}
function updateSelAll(tableId, selAllId) {
  const rows = document.querySelectorAll("#" + tableId + " tbody input.selcheck");
  const total = rows.length;
  const checked = Array.prototype.filter.call(rows, function (cb) { return cb.checked; }).length;
  const sa = document.getElementById(selAllId);
  sa.checked = total > 0 && checked === total;
  sa.indeterminate = checked > 0 && checked < total;
}
function wireTable(tableId, selAllId) {
  document.querySelectorAll("#" + tableId + " tbody input.selcheck").forEach(function (cb) {
    cb.onchange = function () { updateSelected(); updateSelAll(tableId, selAllId); };
  });
  const sa = document.getElementById(selAllId);
  sa.onchange = function () {
    document.querySelectorAll("#" + tableId + " tbody input.selcheck").forEach(function (cb) {
      cb.checked = sa.checked;
    });
    updateSelected();
  };
  updateSelAll(tableId, selAllId);
}
function wireCheckboxes() {
  wireTable("locfiles", "selall-local");
  wireTable("files", "selall-archive");
}
async function refresh() {
  const p = document.getElementById("path").value.trim();
  const msg = document.getElementById("msg");
  msg.textContent = "loading...";
  // RELATIVE URLs: the UI is served under /recordings/ (rewritten route) —
  // absolute /api/... paths would bypass its VS route and hit the HLS server.
  let d = {};
  try {
    const r = await fetch("api/list?path=" + encodeURIComponent(p));
    d = await r.json();
    msg.textContent = d.error ? ("error: " + d.error) : "";
  } catch (e) { msg.textContent = "error: " + e; }

  const lt = document.querySelector("#locfiles tbody");
  lt.innerHTML = "";
  (d.local || []).forEach(function (f) {
    const tr = document.createElement("tr");
    const c0 = document.createElement("td");
    const cb = document.createElement("input");
    cb.type = "checkbox"; cb.className = "selcheck";
    c0.appendChild(cb);
    const td1 = document.createElement("td"); td1.textContent = f.file;
    const td2 = document.createElement("td"); td2.className = "size"; td2.textContent = humanSize(f.size);
    const td3 = document.createElement("td"); td3.className = "size"; td3.textContent = f.modified;
    const td4 = document.createElement("td");
    const play = document.createElement("a");
    play.href = "/playback/get?path=" + encodeURIComponent(p) +
                "&start=" + encodeURIComponent(f.start) +
                "&duration=" + Math.ceil(f.duration) + "s";
    play.textContent = "play";
    const dl = document.createElement("a");
    dl.href = "api/download_local?path=" + encodeURIComponent(p) + "&file=" + encodeURIComponent(f.file);
    dl.textContent = "download"; dl.style.marginLeft = "10px";
    const del = document.createElement("button");
    del.textContent = "delete"; del.style.marginLeft = "10px";
    del.onclick = async function () {
      if (!confirm("Delete LOCAL segment " + f.file + "?\\n(The MinIO archive copy is NOT affected.)")) return;
      const r2 = await fetch("api/delete_local", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ path: p, file: f.file })
      });
      if (!r2.ok) msg.textContent = "local delete failed (" + r2.status + ")";
      refresh();
    };
    td4.appendChild(play); td4.appendChild(dl); td4.appendChild(del);
    tr.append(c0, td1, td2, td3, td4);
    lt.appendChild(tr);
  });
  if (!(d.local || []).length) {
    const tr = document.createElement("tr");
    tr.innerHTML = '<td colspan="5" style="color:#777">(no local segments — check that the stream is publishing)</td>';
    lt.appendChild(tr);
  }

  const tb = document.querySelector("#files tbody");
  tb.innerHTML = "";
  (d.archive || []).forEach(function (f) {
    const tr = document.createElement("tr");
    const c0 = document.createElement("td");
    const cb = document.createElement("input");
    cb.type = "checkbox"; cb.className = "selcheck";
    cb.setAttribute("data-key", f.key);
    c0.appendChild(cb);
    const td1 = document.createElement("td"); td1.textContent = f.key;
    const td2 = document.createElement("td"); td2.className = "size"; td2.textContent = humanSize(f.size);
    const td3 = document.createElement("td"); td3.className = "size"; td3.textContent = f.modified.replace("T", " ").slice(0, 19);
    const td4 = document.createElement("td");
    const play = document.createElement("a");
    play.href = "api/play?path=" + encodeURIComponent(p) + "&key=" + encodeURIComponent(f.key);
    play.target = "_blank";
    play.textContent = "play";
    const dl = document.createElement("a");
    dl.href = "api/download?path=" + encodeURIComponent(p) + "&key=" + encodeURIComponent(f.key);
    dl.textContent = "download"; dl.style.marginLeft = "10px";
    const del = document.createElement("button");
    del.textContent = "delete"; del.style.marginLeft = "10px";
    del.onclick = async function () {
      if (!confirm("Permanently delete " + f.key + " from MinIO?")) return;
      const r2 = await fetch("api/delete", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ path: p, key: f.key })
      });
      if (!r2.ok) msg.textContent = "delete failed (" + r2.status + ")";
      refresh();
    };
    td4.appendChild(dl);
    td4.appendChild(del);
    tr.append(c0, td1, td2, td3, td4);
    tb.appendChild(tr);
  });
  if (!(d.archive || []).length) {
    const tr = document.createElement("tr");
    tr.innerHTML = '<td colspan="5" style="color:#777">(archive empty)</td>';
    tb.appendChild(tr);
  }
  wireCheckboxes();
}
refresh();
</script>
</body>
</html>
"""


def send_html(handler, status, body, ctype="application/json"):
    data = body.encode() if isinstance(body, str) else body
    handler.send_response(status)
    handler.send_header("Content-Type", ctype)
    handler.send_header("Content-Length", str(len(data)))
    handler.send_header("Cache-Control", "no-store")   # UI/API must never be stale
    handler.end_headers()
    handler.wfile.write(data)


class Handler(BaseHTTPRequestHandler):
    server_version = "recordings-ui/1.1"

    def log_message(self, fmt, *args):
        pass

    def _json(self, status, obj):
        send_html(self, status, json.dumps(obj))

    def do_GET(self):
        parsed = urllib.parse.urlsplit(self.path)
        qs = dict(urllib.parse.parse_qsl(parsed.query, keep_blank_values=True))
        route = parsed.path

        if route == "/":
            send_html(self, 200, HTML, ctype="text/html; charset=utf-8")
            return

        if route == "/api/list":
            path = sanitize_path(qs.get("path", ""))
            if not path:
                self._json(400, {"error": "invalid stream path"})
                return
            try:
                archive = s3_list(path + "/")
            except Exception as exc:
                self._json(502, {"error": f"MinIO: {exc}", "archive": [], "local": []})
                return
            self._json(200, {"archive": archive, "local": local_list(path)})
            return

        if route == "/api/play":
            path = sanitize_path(qs.get("path", ""))
            key = safe_key(path, qs.get("key", ""))
            if not key:
                self._json(400, {"error": "invalid key"})
                return
            rng = self.headers.get("Range")
            try:
                resp = s3_request(
                    "GET", key,
                    extra_headers={"range": rng} if rng else None,
                )
            except urllib.error.HTTPError as exc:
                self._json(exc.code, {"error": f"MinIO: {exc.reason}"})
                return
            except Exception as exc:
                self._json(502, {"error": f"MinIO: {exc}"})
                return
            self.send_response(resp.status)   # 200 (full) or 206 (range)
            self.send_header("Content-Type", "video/mp4")
            self.send_header("Accept-Ranges", "bytes")
            if resp.headers.get("Content-Range"):
                self.send_header("Content-Range", resp.headers.get("Content-Range"))
            cl = resp.headers.get("Content-Length")
            if cl:
                self.send_header("Content-Length", cl)
            self.end_headers()
            while True:
                chunk = resp.read(65536)
                if not chunk:
                    break
                self.wfile.write(chunk)
            return

        if route == "/api/download":
            path = sanitize_path(qs.get("path", ""))
            key = safe_key(path, qs.get("key", ""))
            if not key:
                self._json(400, {"error": "invalid key"})
                return
            try:
                resp = s3_request("GET", key)
            except urllib.error.HTTPError as exc:
                self._json(exc.code, {"error": f"MinIO: {exc.reason}"})
                return
            except Exception as exc:
                self._json(502, {"error": f"MinIO: {exc}"})
                return
            filename = key.rsplit("/", 1)[-1]
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header(
                "Content-Disposition", f'attachment; filename="{filename}"'
            )
            self.send_header("Content-Length", str(resp.headers.get("Content-Length", "")))
            self.end_headers()
            while True:
                chunk = resp.read(65536)
                if not chunk:
                    break
                self.wfile.write(chunk)
            return

        if route == "/api/download_local":
            path = sanitize_path(qs.get("path", ""))
            fpath = safe_segment(path, qs.get("file", ""))
            if not fpath or not os.path.isfile(fpath):
                self._json(404, {"error": "local segment not found"})
                return
            filename = os.path.basename(fpath)
            size = os.path.getsize(fpath)
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Disposition", f'attachment; filename="{filename}"')
            self.send_header("Content-Length", str(size))
            self.end_headers()
            with open(fpath, "rb") as f:
                while True:
                    chunk = f.read(65536)
                    if not chunk:
                        break
                    self.wfile.write(chunk)
            return

        self._json(404, {"error": "not found"})

    def do_POST(self):
        if self.path not in ("/api/delete", "/api/delete_local"):
            self._json(404, {"error": "not found"})
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            body = json.loads(self.rfile.read(length) or "{}")
        except Exception:
            self._json(400, {"error": "invalid body"})
            return

        if self.path == "/api/delete":
            path = sanitize_path(body.get("path", ""))
            key = safe_key(path, body.get("key", ""))
            if not key:
                self._json(400, {"error": "invalid key"})
                return
            try:
                resp = s3_request("DELETE", key)
                self._json(resp.status, {"status": "deleted", "key": key})
            except urllib.error.HTTPError as exc:
                self._json(exc.code, {"error": f"MinIO: {exc.reason}"})
            except Exception as exc:
                self._json(502, {"error": f"MinIO: {exc}"})
            return

        # /api/delete_local
        path = sanitize_path(body.get("path", ""))
        fpath = safe_segment(path, body.get("file", ""))
        if not fpath or not os.path.isfile(fpath):
            self._json(404, {"error": "local segment not found"})
            return
        try:
            os.remove(fpath)
            self._json(200, {"status": "deleted", "file": os.path.basename(fpath)})
        except OSError as exc:
            self._json(500, {"error": f"local delete: {exc}"})


if __name__ == "__main__":
    if not ACCESS or not SECRET:
        sys.exit("MINIO_ACCESS_KEY / MINIO_SECRET_KEY not set")
    print(f"recordings-ui listening on :{PORT} (bucket: {BUCKET}, endpoint: {ENDPOINT}, local: {RECORD_LOCAL_DIR})")
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
