# WhisperX-FastAPI 

WhisperX-FastAPI is a REST API service built on top of [WhisperX](https://github.com/m-bain/whisperX), providing speech-to-text transcription with word-level timestamps, forced alignment, and speaker diarization. It wraps WhisperX in a [FastAPI](https://fastapi.tiangolo.com/) application with async task management, health endpoints, and support for multiple audio/video formats.

**Source repository:** [github.com/pavelzbornik/whisperX-FastAPI](https://github.com/pavelzbornik/whisperX-FastAPI)
**Upstream version ported:** v0.5.1

WhisperX-FastAPI accepts audio file uploads via REST API and returns transcripts with:

- Accurate word-level timestamps (via wav2vec2 forced alignment)
- Speaker labels — e.g., `SPEAKER_00`, `SPEAKER_01` (via pyannote.audio diarization)
- Confidence scores per word
- Support for 99+ languages (via OpenAI Whisper models)

**This service has no UI.** It is a backend API designed to be called by a frontend application such as [Open WebUI](https://github.com/open-webui/open-webui) via the community [WhisperX Pipe](https://openwebui.com/f/podden/whisper_x_transciption).

## Architecture: How the Components Work Together

```
┌──────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│  Open WebUI   │────▶│ WhisperX-FastAPI  │────▶│ Pyannote Diarization│
│  (UI + LLM)  │     │ (transcription +  │     │ (separate service,  │
│              │     │  alignment +      │     │  speaker detection) │
│  User uploads │     │  orchestration)   │     │                    │
│  audio file   │     │                  │     │                    │
└──────────────┘     └────────┬─────────┘     └─────────────────────┘
                              │
                              ▼
                     ┌──────────────────┐
                     │  MLIS Whisper    │
                     │  (ASR model      │
                     │   on GPU)        │
                     └──────────────────┘
```

1. **User uploads** an audio file in Open WebUI chat
2. The **WhisperX Pipe** (Open WebUI plugin) sends the file to WhisperX-FastAPI
3. **WhisperX-FastAPI** orchestrates: transcription (via MLIS Whisper endpoint), alignment (local wav2vec2), and diarization (via the separate Pyannote Diarization service)
4. The diarized transcript is returned to **Open WebUI** and displayed in the chat
5. The user prompts the **LLM** (connected to Open WebUI) to summarize the transcript into meeting minutes

## Docker Image

The image is built from the upstream [Dockerfile](https://github.com/pavelzbornik/whisperX-FastAPI/blob/main/dockerfile). One fix was applied: replacing the deprecated `use_auth_token=` parameter with `token=` in `app/main.py` to support newer pyannote.audio versions.

**Published image:** `caovd/whisperx-fastapi:0.5.2-mlis` (Docker Hub)

## Key Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `whisperx.model` | Whisper model size | `large-v3-turbo` |
| `whisperx.device` | Inference device | `cuda` |
| `hfToken` | HuggingFace access token (required for pyannote models) | `""` — must be set at install |
| `mlis.enabled` | Use external MLIS endpoints for inference | `true` |
| `mlis.whisper.apiUrl` | MLIS Whisper endpoint URL | — |
| `mlis.diarization.apiUrl` | Pyannote Diarization service URL | — |
| `resources.limits.nvidia.com/gpu` | GPU allocation (0 when using MLIS mode) | `0` |
| `persistence.size` | PVC size for model cache | `20Gi` |

## Important Notes

- **No UI** — this is a headless API.
- **First startup is slow** (~3–5 min) as alignment models are downloaded to the PVC cache. Subsequent restarts use the cached models.
- **HuggingFace token is required** 
- **MLIS mode** (`mlis.enabled=true`): transcription and diarization are offloaded to external GPU-backed services. WhisperX-FastAPI itself runs on CPU and only performs local alignment. Set `nvidia.com/gpu: 0` in this mode.
- **Local mode** (`mlis.enabled=false`): all models run inside the pod. Requires 1x GPU with ≥8GB VRAM.

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/speech-to-text` | POST | Full pipeline: transcribe + align + diarize |
| `/service/transcribe` | POST | Transcription only |
| `/service/align` | POST | Forced alignment only |
| `/service/diarize` | POST | Speaker diarization only |
| `/service/combine` | POST | Merge transcript with diarization |
| `/task/{id}` | GET | Check async task status and retrieve results |
| `/task/all` | GET | List all tasks |
| `/health/ready` | GET | Readiness probe |

## References

- WhisperX: [github.com/m-bain/whisperX](https://github.com/m-bain/whisperX)
- WhisperX-FastAPI: [github.com/pavelzbornik/whisperX-FastAPI](https://github.com/pavelzbornik/whisperX-FastAPI)
- Whisper large-v3-turbo model card: [huggingface.co/openai/whisper-large-v3-turbo](https://huggingface.co/openai/whisper-large-v3-turbo)
- pyannote speaker-diarization-community-1: [huggingface.co/pyannote/speaker-diarization-community-1](https://huggingface.co/pyannote/speaker-diarization-community-1)
- PCAI BYOA tutorial: [github.com/HPEEzmeral/byoa-tutorials](https://github.com/HPEEzmeral/byoa-tutorials/tree/main/tutorial)
- Open WebUI WhisperX Pipe: [openwebui.com/f/podden/whisper_x_transciption](https://openwebui.com/f/podden/whisper_x_transciption)