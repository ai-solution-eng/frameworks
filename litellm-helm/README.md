# LiteLLM Framework

LiteLLM is a high-performance, lightweight gateway that serves as a universal interface for 100+ LLM APIs. By acting as a standardized proxy, it allows developers to interact with diverse models (from OpenAI, Anthropic, and Google to locally hosted models via vLLM or NVIDIA NIM) using a single, unified OpenAI-compatible format. LiteLLM simplifies the complexity of multi-model environments, making it an essential bridge for GenAI applications within HPE Private Cloud AI (PCAI).

# Why do we need it

HPE Private Cloud AI and AI Essentials provide robust infrastructure for running local models, but managing application access across different departments and monitoring resource consumption can be challenging. LiteLLM addresses these operational hurdles by providing:

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
- **A Model Provider:** You should have a model endpoint available. This can be an internal service (like a vLLM or NVIDIA NIM deployment in MLIS within AI Essentials) or an external API key (OpenAI, Anthropic, etc.).
  - You can add models as part of installtion in the `values.yaml` itself, but you will not be able to modify them later.
    - An example MLIS model has been added to "Important additional configuration options" section below and the `values.yaml` . Search for `proxy_config.model_list` section and replace with proper information from your system.
  - Only models added from the application side into the DB at a later state can be modified any time (as long as you are an admin or you created that model connection).
- **Database for State:** LiteLLM requires a Postgres database to store its configuration, virtual keys, and usage tracking data. Additionally it's also possible to store models, MCP servers and other artefacts into the DB when `STORE_MODEL_IN_DB=True`. You can either have the Helm Chart deploy an instance or refer to an already existing instance.
- **[Optional] HPE PCAI Kubectl Access:** You will need `kubectl` access to the system when you don't manually specify a LiteLLM UI default user (see "How to access" section below)

Configuration is handled primarily through the `values.yaml` file. You can define your model list, database connection strings, and initial admin settings there.
For official Kubernetes deployment patterns and advanced configuration, refer to:
- [litellm-helm repository](https://github.com/BerriAI/litellm/tree/main/deploy/charts/litellm-helm)
- [LiteLLM configuration settings](https://docs.litellm.ai/docs/proxy/config_settings)

# Important additional configuration options

```
proxy_config:
  # At least one model must exist for the proxy to start when `STORE_MODEL_IN_DB` is not set to `True`. Models defined here are not editable later from the application (only models stored in DB are editable)
  # model_list:
  #  # Sample configuration for local model deployed on MLIS
  #  - model_name: PCAI-Llama-3.2-1B-Instruct
  #    litellm_params:
  #      model: hosted_vllm/meta/llama-3.2-1b-instruct
  #      api_key: "<MLIS_endpoint_token>"
  #      api_base: https://llama-32-1b-instruct.project-user-jose-claudio-calderon.serving.aie01.pcai.tryezmeral.com/
  general_settings:
    master_key: os.environ/PROXY_MASTER_KEY
  litellm_settings:
    # Logging/Callback settings
    success_callback: ["langfuse"]  # list of success callbacks
    failure_callback: ["langfuse"]  # list of failure callbacks
    turn_off_message_logging: boolean  # prevent the messages and responses from being logged to on your callbacks, but request metadata will still be logged. Useful for privacy/compliance when handling sensitive data.
    langfuse_default_tags: ["cache_hit", "cache_key", "proxy_base_url", "user_api_key_alias", "user_api_key_user_id", "user_api_key_user_email", "user_api_key_team_alias", "semantic-similarity", "proxy_base_url"] # default tags for Langfuse Logging
  environment_variables:
    UI_USERNAME: "admin"
    UI_PASSWORD: "password"
    LANGFUSE_HOST: "http://langfuse-web.langfuse.svc.cluster.local:3000"
    LANGFUSE_PUBLIC_KEY: "lf_pk_1234567890"
    LANGFUSE_SECRET_KEY: "lf_sk_1234567890"
    STORE_MODEL_IN_DB: "True" # Allow adding more models live in the application that will be stored in the DB. When set to false, you must define all your models in `proxy_config.model_list`.
```

# How to access

Once the framework is installed, when you click the "Open" button from AI Essentials it will take you to the Swagger documentation.
You have to navigate to the `/ui` endpoint to access the WebUI. There's also a link to this `/ui` endpoint from the Swagger documentation itself.

Login into the UI using the credentials you configured in `proxy_config.environment_variables` in the `values.yaml`

When no default account is created via `values.yaml`, a new one is automatically created.
* Username: `admin`
* Password: Its password is encrypted and stored into a secret within the namespace where the framework was installed. To get the password you need to run the following `kubectl` command:
```
kubectl get secret litellm-helm-masterkey -n litellm-helm -o json | jq -r '.data.masterkey' | base64 -d
```
