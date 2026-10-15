# OpenShell for AI Essentials

This chart packages OpenShell for deployment through HPE AIE, on top of the upstream
[OpenShell Helm chart](https://github.com/NVIDIA/openshell). See
[porting.md](porting.md) for the full list of differences from upstream.

## Prerequisites

Before installing this chart, make sure the target cluster satisfies the
following:

- **Agent Sandbox CRDs and controller.** OpenShell requires the Kubernetes
  Agent Sandbox API (`agents.x-k8s.io/v1beta1` or `agents.x-k8s.io/v1alpha1`)
  to be served by the cluster. Agent Sandbox is available as a bundled
  subchart dependency of this chart (`charts/agent-sandbox`), based on
  [kubernetes-sigs/agent-sandbox](https://github.com/kubernetes-sigs/agent-sandbox).
  Either:
  - install it yourself beforehand (for example, via the standalone
    manifest), and leave `agent-sandbox.enabled=false` (the default) so
    this chart does not deploy a second, conflicting copy of the CRDs and
    controller, or
  - set `agent-sandbox.enabled=true` in `values.yaml` (or pass
    `--set agent-sandbox.enabled=true` to `helm install`/`helm upgrade`) to
    have this chart also deploy the Agent Sandbox CRDs and controller
    alongside OpenShell:

    ```yaml
    agent-sandbox:
      enabled: true
    ```

- A preflight check (`agentSandbox.preflight.enabled=true`, the default)
  fails the install early if neither API is served. Disable it only for
  offline `helm template` rendering, where Helm cannot discover cluster
  APIs.
