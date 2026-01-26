# Langfuse Framework

Langfuse is an open-source LLM engineering platform designed to provide observability, tracing, and evaluation for Generative AI applications. It helps teams collaboratively debug, analyze, and iterate on their LLM applications by providing a visual interface for complex traces, prompt management, and performance metrics. In the context of HPE Private Cloud AI (PCAI), Langfuse serves as the critical "command center" for understanding how models are performing and how they are being utilized by end-users.

# Why do we need it

While LiteLLM acts as the gateway for your models, Langfuse provides the deep visibility required to move from prototype to production. Within the HPE AI Essentials stack, Langfuse enables:

*   **Deep Traceability:** Log every step of a multi-turn conversation or an agentic workflow, including retrieval steps, tool calls, and model responses.
*   **Prompt Management:** Decouple prompts from your application code, allowing your team to version, test, and deploy prompt updates directly from the Langfuse UI.
*   **Evaluation & Quality Control:** Implement human-in-the-loop annotations or "LLM-as-a-judge" to score outputs, ensuring your PCAI-hosted models maintain high quality over time.

### The "Tokenomics" of Langfuse
Langfuse takes the raw usage data from your applications and transforms it into actionable financial and operational intelligence:

*   **Cost & Usage Tracking:** Automatically calculates the cost of every generation based on model-specific pricing tiers (input/output/cached tokens).
*   **User & Team Analytics:** Track token consumption and costs per individual user or project team, providing the transparency needed for internal chargeback models.
*   **Latency vs. Cost Analysis:** Use built-in dashboards to identify which models or prompts are the most expensive or slowest, enabling data-driven optimization of your PCAI resources.
*   **Session Management:** Group traces into user sessions to understand the total cost and token "burn" of a complete user interaction, rather than just isolated API calls.

# Pre-requisites to use this

To successfully deploy Langfuse in your PCAI/AIE environment, ensure you have:

1.  **Postgres Database:** Langfuse requires a dedicated PostgreSQL instance (12+) to store traces, prompts, and analytics data. You can either have the Helm Chart deploy an instance or refer to an already existing instance.
2.  **Authentication Provider:** For production use, you should configure an SSO provider (like Okta, GitHub, or GitLab) or use the default credentials for initial setup.
3.  **App Integration:** You will need to integrate the Langfuse SDK (Python or JS) into your application or point your LiteLLM proxy to Langfuse to begin capturing data.

Settings such as `DATABASE_URL`, `NEXTAUTH_SECRET`, and initial `SALT` values are defined in the `values.yaml` file. 
For official Kubernetes deployment patterns and advanced configuration, refer to the [langfuse-k8s repository](https://github.com/langfuse/langfuse-k8s)

# Changes with respect to the official Langfuse Helm Chart

**NOTE:** We bumped the Helm chart version to `v1.5.18`. The official Langfuse Helm Chart version is still `v1.5.17` as of the time this commit was made.

We modified the `templates/_helpers.tpl` to ensure that when we define the `langfuse.postgres.hostname`, `langfuse.redis.hostname`, `langfuse.clickhous.hostname` and `langfuse.s3.endpoint` they get dynamically generated to include the full internal kubernetes service name including the `.svc.cluster.local`.
This is in order to avoid the Kubernetes known `ndots:5` issue. ([1](https://pracucci.com/kubernetes-dns-resolution-ndots-options-and-why-it-may-affect-application-performances.html#:~:text=When%20an%20application%20connects%20to,absolute%20name%20only%20at%20last.)) ([2](https://dev.to/imjoseangel/tune-up-your-kubernetes-application-performance-with-a-small-dns-configuration-1o46#:~:text=ndots:5%20can%20negatively%20affect,in%20case%20of%20heavy%20traffic.))
