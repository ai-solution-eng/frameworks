# LibreChat

[LibreChat](https://www.librechat.ai/) — open-source, multi-provider AI chat
UI — ported for [HPE Private Cloud AI](https://www.hpe.com/us/en/compute/ai/private-cloud-ai.html)
via the BYOA (Bring-Your-Own-Application) feature.

## Folder contents

| Item | Purpose |
|---|---|
| `librechat-logo.png` | Logo used for the application tile during import |
| `1.0.7/` | Helm chart source for chart version 1.0.7 (appVersion v0.8.7) |
| `librechat-1.0.7.tar.gz` | Packaged tarball of the `1.0.7/` folder |
| `porting.md` | How the framework was ported to PCAI + troubleshooting notes |
| `test-rag.sh` | RAG pipeline smoke test (health, document ingest, query) |
| `test-nim-embed.sh` | NIM embeddings endpoint probe (input_type diagnosis) |

## Quick start

1. Read `porting.md` — it documents every integration step and the pitfalls
   hit on a live cluster (SSO, LiteLLM endpoint, RAG embeddings, SearXNG web
   search).
2. Fill the `REPLACE-ME`/`CHANGEME` values in `1.0.7/values.yaml`
   (LiteLLM URL + virtual key + model id, optional Keycloak OIDC).
3. Package and import via EzAppConfig (`ezappconfig-librechat-template.yaml`
   is included in the chart folder) or the byoa `api/tooling/bootstrap.sh`
   flow.
