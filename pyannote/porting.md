# Pyannote Diarization 

Pyannote Diarization is a standalone microservice that performs **speaker diarization** — identifying "who spoke when" in an audio recording. It wraps the [pyannote.audio](https://github.com/pyannote/pyannote-audio) `speaker-diarization-community-1` pipeline in a FastAPI REST API, allowing other services to call it over HTTP.

**Based on:** [pyannote.audio](https://github.com/pyannote/pyannote-audio)

Given an audio file, the service returns a list of speech segments with speaker labels and timestamps:

```
SPEAKER_00: 0.20s → 4.80s
SPEAKER_01: 5.10s → 12.30s
SPEAKER_00: 12.80s → 18.50s
```

It detects the number of speakers automatically (or accepts `min_speakers` / `max_speakers` hints) and handles overlapping speech.

**This service has no UI.** It is a backend API designed to be called by [WhisperX-FastAPI](https://github.com/pavelzbornik/whisperX-FastAPI), which orchestrates the full transcription + diarization pipeline.

## Architecture: Role Within the Meeting Transcription Stack

```
Open WebUI  ──▶  WhisperX-FastAPI  ──▶  Pyannote Diarization  ← you are here
   (UI)           (orchestrator)         (speaker detection)
                       │
                       ▼
                  MLIS Whisper
                  (ASR on GPU)
```

**Pyannote Diarization is not called directly by users or by Open WebUI.** It is an internal service consumed by WhisperX-FastAPI. When a user uploads an audio file through Open WebUI:

1. WhisperX-FastAPI receives the file and sends it to MLIS Whisper for transcription
2. WhisperX-FastAPI sends the same audio to **this Pyannote Diarization service** for speaker detection
3. WhisperX-FastAPI combines (aligns) the transcript with the speaker segments
4. The diarized transcript is returned to Open WebUI

Deploying this as a **separate service** (rather than built into WhisperX-FastAPI) allows independent scaling, separate API keys, and the flexibility to run diarization on CPU while keeping the GPU for Whisper inference.

## Docker Image

A custom lightweight Docker image was built with FastAPI + pyannote.audio. One critical fix applied: the `use_auth_token` parameter was renamed to `token` to support pyannote.audio v4.0+ (breaking API change in newer versions).

**Published image:** `caovd/pyannote-diarization:0.1.1` (Docker Hub)

## Key Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `pyannote.pipelineName` | HuggingFace pipeline name | `pyannote/speaker-diarization-3.1` |
| `pyannote.device` | Inference device | `cpu` |
| `hfToken` | HuggingFace access token (required) | `""` — must be set at install |
| `resources.limits.nvidia.com/gpu` | GPU allocation (optional — GPU makes diarization ~3x faster) | not set (CPU default) |
| `persistence.size` | PVC size for model cache | `10Gi` |

## Important Notes

- **No UI** — this is a headless API. Access the Swagger docs at `https://<endpoint>/docs`
- **Runs on CPU by default.** Diarization on CPU is slower (~1x real-time, so a 5-min audio takes ~5 min) but functional. Adding a GPU makes it ~3x faster. For a POC, CPU is sufficient.
- **HuggingFace token is required.** 
- **torchcodec warnings are non-fatal.** On startup, you will see warnings about `libtorchcodec` and `libnvrtc.so.13` — these are harmless. The service falls back to standard audio loading. The pod is healthy when you see `Pipeline ready. Application startup complete.`
- **Internal service.** The WhisperX-FastAPI `values.yaml` should point `mlis.diarization.apiUrl` to this service's internal Kubernetes URL, e.g., `http://pyannote-pyannote-diarization.pyannote-diarization.svc.cluster.local:8000`

## Expected Diarization Accuracy

Speaker diarization accuracy is measured by Diarization Error Rate (DER) — lower is better.

| Audio Condition | Expected DER |
|-----------------|-------------|
| Clean audio, headset mic, 2–3 speakers | 11–17% |
| Conference room, distant mic, 2–3 speakers | 17–22% |
| Noisy environment, 4+ speakers, overlapping speech | 25–40% |

For a POC with curated demo audio (clean recording, 2–3 speakers), the accuracy is sufficient. Speaker labels are generic (`SPEAKER_00`, `SPEAKER_01`) — mapping to real names is not supported.

Source: [pyannote.audio benchmarks](https://github.com/pyannote/pyannote-audio#benchmark-last-updated-in-2025-09)

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/diarize` | POST | Perform speaker diarization on uploaded audio |
| `/health` | GET | Basic health check |
| `/health/live` | GET | Liveness probe |
| `/health/ready` | GET | Readiness probe |

## References

- pyannote.audio: [github.com/pyannote/pyannote-audio](https://github.com/pyannote/pyannote-audio)
- pyannote speaker-diarization-community-1: [huggingface.co/pyannote/speaker-diarization-community-1](https://huggingface.co/pyannote/speaker-diarization-community-1) (CC-BY-4.0)
- pyannote benchmarks: [pyannote.ai/benchmark](https://www.pyannote.ai/benchmark)
- WhisperX-FastAPI (the orchestrator that calls this service): [github.com/pavelzbornik/whisperX-FastAPI](https://github.com/pavelzbornik/whisperX-FastAPI)
- PCAI BYOA tutorial: [github.com/HPEEzmeral/byoa-tutorials](https://github.com/HPEEzmeral/byoa-tutorials/tree/main/tutorial)