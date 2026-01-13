# Porting NVIDIA NeMo Guardrails Microservice to PCAI

This Helm chart install NeMo Guardrails only with [Tag-Based Installation](https://docs.nvidia.com/nemo/microservices/latest/set-up/deploy-as-microservices/deployment-options.html). 


## Prerequisites
- Create namespace (if not already created)
```bash
kubectl create namespace $NAMESPACE
```
- Create secrets in the namespace
``` bash
export NGC_API_KEY="<your-ngc-api-key>"

kubectl create secret docker-registry nvcrimagepullsecret --docker-server=nvcr.io --docker-username='$oauthtoken' --docker-password=$NGC_API_KEY -n $NAMESPACE
```


## Modifications to the original chart.

How to download the orginal chart via a Helm CLI command. 

```bash
helm fetch https://helm.ngc.nvidia.com/nvidia/nemo-microservices/charts/nemo-microservices-helm-chart-25.8.0.tgz --username='$oauthtoken' --password=$NGC_API_KEY
```

### Changes in values.yaml

Add PCAI's virtual service using Istio gateway.

```yaml
ezua:
  virtualService:
    endpoint: "nemo-guardrails.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
```

Disable Platform installation and Enable Guardrails Tag only. 

```yaml
tags:
  platform: false
  guardrails: true
  auditor: false
  studio: false
  safe-synthesizer: false
```

Disable virtualService and ingress to use PCAI istio, Disable Nim to use MLIS for model deployment
```yaml
virtualService:
  enabled: false

ingress:
  enabled: false

nim:
  enabled: false
```