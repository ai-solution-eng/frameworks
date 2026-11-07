# WebOllama Helm Chart

A simple Helm chart to deploy WebOllama.

## Installation

To install the chart with a custom Ollama URL:

```bash
helm install webollama ./chart \
  --namespace webollama \
  --set ollamaUrl=http://your-ollama-service:11434
```

## Configuration

The following table lists the configurable parameters of the chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ollamaUrl` | The endpoint for the Ollama service | `http://ollama.ollama.svc.cluster.local:11434` |
| `image.repository` | Image repository | `ghcr.io/dkruyt/webollama` |
| `image.tag` | Image tag | `latest` |
| `service.port` | Service port | `5000` |
