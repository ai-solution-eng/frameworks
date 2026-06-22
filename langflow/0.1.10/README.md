# LangFlow IDE chart

Helm chart for LangFlow as IDE with a persistent storage or an external database (for example PostgreSQL).


## Quick start

Install the chart:

```bash
helm repo add langflow https://langflow-ai.github.io/langflow-helm-charts
helm repo update
helm install langflow-ide langflow/langflow-ide -n langflow --create-namespace
```


## Examples
See more examples in the [examples directory](https://github.com/langflow-ai/langflow-helm-charts/tree/main/examples/langflow-ide).


## Increase file upload size

By default, file uploads in the frontend are limited to 1 MB.  

To allow larger uploads, we added the environment variable `LANGFLOW_MAX_FILE_SIZE_UPLOAD` in the frontend deployment.

### What was changed

The following variable was added to the frontend container:

```yaml
env:
  - name: LANGFLOW_MAX_FILE_SIZE_UPLOAD
    value: "500"