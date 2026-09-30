# Porting to the bundled Agent Sandbox subchart

Agent Sandbox is now available as a bundled subchart dependency of this
chart (`charts/agent-sandbox`), based on
[kubernetes-sigs/agent-sandbox](https://github.com/kubernetes-sigs/agent-sandbox).

Set `agent-sandbox.enabled=true` in `values.yaml` (or pass
`--set agent-sandbox.enabled=true` to `helm install`/`helm upgrade`) to have
this chart also deploy the Agent Sandbox CRDs and controller alongside
OpenShell:

```yaml
agent-sandbox:
  enabled: true
```

If Agent Sandbox is already installed elsewhere on the cluster (for example,
via the standalone manifest), leave `agent-sandbox.enabled=false` (the
default) so this chart does not deploy a second, conflicting copy of the CRDs
and controller.
