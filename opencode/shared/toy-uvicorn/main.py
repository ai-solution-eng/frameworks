from fastapi import FastAPI
from fastapi.responses import HTMLResponse

app = FastAPI(title="Toy Uvicorn App")

@app.get("/", response_class=HTMLResponse)
async def home():
    return """<!doctype html><html><head><meta charset=\"utf-8\" /><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" /><title>Toy Uvicorn App</title><style>body{font-family:ui-monospace,monospace;background:#0f172a;color:#e2e8f0;display:grid;place-items:center;min-height:100vh;margin:0}main{max-width:720px;padding:32px;border:1px solid rgba(148,163,184,.25);border-radius:20px;background:rgba(15,23,42,.9)}code{color:#67e8f9}</style></head><body><main><h1>Toy Uvicorn App</h1><p>This FastAPI/Uvicorn preview is running inside the <code>opencode-web</code> pod.</p><p>Try <code>/status</code> for JSON.</p></main></body></html>"""

@app.get("/status")
async def status():
    return {"ok": True, "app": "uvicorn", "preview": True}