# Porting notes: differences from the upstream OpenShell Helm chart

This repository vendors the upstream NVIDIA OpenShell Helm chart
(published as `oci://ghcr.io/nvidia/openshell/helm-chart`) with a small set
of HPE-specific additions layered on top. This document tracks what was
added or changed relative to upstream so future rebases are easier.

## 1. EZUA (HPE Ezmeral Unified Analytics) integration

A new `ezua` section was added to `values.yaml` to support importing this
chart as an application in HPE Ezmeral Unified Analytics:

```yaml
ezua:
  domainName: "${DOMAIN_NAME}"
  virtualService:
    endpoint: "openshell.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
  authorizationPolicy:
    namespace: "istio-system"
    providerName: "oauth2-proxy"
    matchLabels:
      app: "openshell"
    include: false
  selfSignedCert: true
```

These values are not present upstream and are only consumed by the
EZUA-specific resources described below.

In addition, the standard `hpe-ezua/app` and `hpe-ezua/type` labels were
added to pod templates so EZUA can discover and manage the workload:

- [templates/_gateway-workload.tpl](0.0.116/templates/_gateway-workload.tpl)
- [templates/deployment.yaml](0.0.116/templates/deployment.yaml)
- [templates/service.yaml](0.0.116/templates/service.yaml)
- [templates/statefulset.yaml](0.0.116/templates/statefulset.yaml)

## 2. VirtualService template

[templates/virtualservice.yaml](0.0.116/templates/virtualservice.yaml) is a
new template, not present upstream. It renders an Istio `VirtualService`
that routes traffic from the EZUA Istio gateway
(`.Values.ezua.virtualService.istioGateway`) to the OpenShell gateway
Service, using `.Values.ezua.virtualService.endpoint` as the host. This is
how OpenShell is exposed through the EZUA ingress/gateway rather than
relying solely on the upstream `Gateway`/`GRPCRoute`/`Route` resources.

## 3. Pinned versions

Upstream leaves several image tags and the `agent-sandbox` dependency
version open-ended (empty tag defaults, or a version range) so consumers
can override them per-release. In this fork, those have been pinned to
known-good values for the HPE package build:

- `image.tag` and `supervisor.image.tag` in
  [values.yaml](0.0.116/values.yaml) are pinned to the chart version
  (`"0.0.116"`) instead of being left empty.
- `server.sandboxImage` in [values.yaml](0.0.116/values.yaml) is pinned to
  a specific build (`ghcr.io/nvidia/openshell-community/sandboxes/base:fffb6b2`)
  instead of a floating tag.
- The bundled `agent-sandbox` subchart dependency in
  [Chart.yaml](0.0.116/Chart.yaml) is pinned to an exact version
  (`version: "0.1.0"`) rather than a version range, and its own
  `image.tag` in
  [charts/agent-sandbox/values.yaml](0.0.116/charts/agent-sandbox/values.yaml)
  is pinned to `v1.0.3`.

When rebasing onto a newer upstream release, re-check these pinned values
against the new upstream defaults and bump them deliberately rather than
inheriting upstream's floating/empty defaults.

## 4. Bundled Agent Sandbox subchart

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
