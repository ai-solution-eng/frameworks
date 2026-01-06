# Arize Phoenix

## Introduction

Arize Phoenix is an LLM tracing and evaluation platform. It uses OpenTelemetry to instrument applications with minimal code changes, allowing developers to see end-to-end LLM spans: model calls, tool calls, retrieval steps, etc.

The helm charts in this directory adapt the upstream Arize Phoenix chart for use with HPE Private Cloud for AI.

## Configuration
### Access

After installation, the web UI can be accessed at the URL provided in the values file. By default, it's `phoenix.DOMAIN`. The default username is `admin@localhost` and the password is set in the values file. Note that the password will need to be changed on first login.

### API Key Generation
After logging in to Phoenix:
Settings -> General -> System Keys -> Create new System Key
Note the key for later use

### Configure Custom Model
Out of the box, Phoenix is configured with support for many hosted model providers. If you're using a self-hosted model, you can add it explicitly to Phoenix. Note that this step is not strictly required but recommended for better visibility of model calls.

Settings -> Models -> Add Model -> Add model name (Llama-3.1-8B-Instruct for example)

## App Instrumentation 
### Crew
#### Env additions
Add below env vars to `.env`
```
PHOENIX_COLLECTOR_ENDPOINT=http://phoenix-svc.phoenix.svc.cluster.local:4317
PHOENIX_API_KEY=api_key_from_above
```
#### Package additions
Add below packages to crew virtual environment
```shell
uv add openinference-instrumentation-crewai crewai-tools arize-phoenix-otel openinference-instrumentation-litellm
```
> [!NOTE]
> When using different Agentic framework, you may need to find `openinference` packages for the framework if applicable. Generally, it will run without specific framework packages but the traces won't be as detailed.

#### Code additions
Add below to main.py of crew code, changing `name` to whatever you want your project name to be
```python
from phoenix.otel import register
tracer_provider = register(project_name="name", auto_instrument=True)
```

### Langflow
Add below to Langflow values.yaml
```yaml
langflow:
  backend:
    env:
      - name: PHOENIX_API_KEY
        value: "api_key_from_above"
      - name: PHOENIX_COLLECTOR_ENDPOINT
        value: "http://phoenix-svc.phoenix.svc.cluster.local:6006"
```
> [!NOTE]
> It looks like only HTTP collection (port 6006) is supported in Langflow, not GRPC collection (port 4317). Although this integration does currently work, note that it may not be officially supported as a relevant recent [Github issue](https://github.com/langflow-ai/langflow/issues/8367) was closed as not planned.

## View Traces
Navigate to Phoenix URL and view trace data. Click trace to see detailed agent usage and tool calls.