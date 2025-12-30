# Porting Milvus to PCAI
Milvus is a high-performance vector database built for scale. It powers AI applications by efficiently organizing and searching vast amounts of unstructured data, such as text, images, and multi-modal information. [github](https://github.com/milvus-io/milvus)


### Changes in values.yaml

- Add PCAI's virtual service configuration using Istio gateway.
```yaml
ezua:
  #Use next options in order to configure the application endpoint.
  virtualService:
    endpoint: "milvus.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
```
- Add HPE EzUA label into the values.yaml for simplicity. if you change release name, then please match hpe-ezua/app label to release name.
```yaml
# Global labels and annotations
# If set, this will apply to all milvus components
labels: 
  # PCAI related labels
  hpe-ezua/app: milvus # must align with release name
  hpe-ezua/type: vendor-service
```
- Configure Resource Limits for enabled Milvus Components. ( Proxy,queryNode,dataNode,mixCoordinator,streamingNode )
```yaml
proxy:
  enabled: true
  # You can set the number of replicas to -1 to remove the replicas field in case you want to use HPA
  replicas: 1
  resources:
    limits:
      cpu: "4"
      memory: "8Gi"
```

- Point Milvus' WebUI port to the virtualservice's destination and redirect to /webui
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: {{ include "milvus.fullname" . }}
spec:
  gateways:
    - {{ .Values.ezua.virtualService.istioGateway | required ".Values.ezua.virtualService.istioGateway is required !\n" }}
  hosts:
    - {{ .Values.ezua.virtualService.endpoint | required ".Values.ezua.virtualService.endpoint is required !\n" }}
  http:
    - match:
      - uri:
          exact: /
      redirect:
        uri: /webui/
    - match:
      - uri:
          prefix: /webui
      route:
        - destination:
            # Insert target service name here
            host: {{ include "milvus.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
            port:
              # Insert target service port number here
              number: 9091
```

### NOTEs
- If Pulsar's PVC provisioninig is failed, Set the release name shorter than "milvus". ( e.g. mil )
- Once you update the release name, please update hpe-ezua/app label aligh with release name