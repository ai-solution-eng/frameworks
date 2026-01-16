# LiteLLM Framework

LiteLLM is a high-performance, lightweight gateway that serves as a universal interface for 100+ LLM APIs. By acting as a standardized proxy, it allows developers to interact with diverse models (from OpenAI, Anthropic, and Google to locally hosted models via vLLM or NVIDIA NIM) using a single, unified OpenAI-compatible format. LiteLLM simplifies the complexity of multi-model environments, making it an essential bridge for GenAI applications within HPE Private Cloud AI (PCAI).

# Why do we need it

HPE AI Essentials and PCAI provide robust infrastructure for running local models, but managing application access across different departments and monitoring resource consumption can be challenging. LiteLLM addresses these operational hurdles by providing:

*   **Unified API Interface:** Switch between local models hosted in PCAI and external cloud providers by changing a single line of code.
*   **Load Balancing & High Availability:** Distribute requests across multiple model endpoints to ensure high uptime and optimize throughput.
*   **Observability & Logging:** Built-in support for logging to platforms like Langfuse, Helicone, or Prometheus for deep insights into model performance.

### The "Tokenomics" of LiteLLM
The core value of LiteLLM in a private cloud environment is its sophisticated management of model "tokenomics," allowing administrators to treat LLM access as a finite, billable resource:

*   **Virtual Keys:** Create specific API keys for different teams or applications instead of sharing master model credentials.
*   **Budgets & Quotas:** Set granular spending limits (in USD or token counts) at the user, team, or key level to prevent accidental resource exhaustion.
*   **Token Rate Limiting:** Implement TPM (Tokens Per Minute) and RPM (Requests Per Minute) limits to ensure fair usage of the high-value GPU resources within PCAI.
*   **Usage Tracking:** Automatically track token consumption by "Team ID" or "User ID," enabling internal chargeback models for GPU and API usage.

# Pre-requisites to use this

Before deploying this framework, ensure you have the following ready:

1.  **A Model Provider:** You should have a model endpoint available. This can be an internal service (like a vLLM or NVIDIA NIM deployment in MLIS within AI Essentials) or an external API key (OpenAI, Anthropic, etc.).
1.1. ** API Key:** An example MLIS model has been added to the `values.yaml`. Search for `proxy_config` section and replace with proper information from your system.
2.  **Database for State:** LiteLLM requires a Postgres database to store its configuration, virtual keys, and usage tracking data. You can either have the Helm Chart deploy an instance or refer to an already existing instance.
3.  **HPE PCAI Access:** Ensure you have the `kubectl` and `helm` CLI tools configured to point to your AI Essentials environment.

Configuration is handled primarily through the `values.yaml` file. You can define your model list, database connection strings, and initial admin settings there.
For official Kubernetes deployment patterns and advanced configuration, refer to the [litellm-helm repository](https://github.com/BerriAI/litellm/tree/main/deploy/charts/litellm-helm)

# How to access

Once the framework is installed, when you click the "Open" button from AI Essentials it will take you to the Swagger documentation.
You have to navigate to the `/ui` endpoint to access the WebUI. There's also a link to this `/ui` endpoint from the Swagger documentation itself.

When no default account is created via `values.yaml`, a new one is automatically created.
* Username: `admin`
* Password: Its password is encrypted and stored into a secret within the namespace where the framework was installed. To get the password you need to run the following `kubectl` command:
```
kubectl get secret litellm-helm-masterkey -n litellm-helm -o json | jq -r '.data.masterkey' | base64 -d
