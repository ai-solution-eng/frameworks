# Porting

https://github.com/HPEEzmeral/byoa-tutorials/tree/main/tutorial#configure-application-endpointvirtualservice

### Notes
HPE Lable for Pod resource monitoring and SSO is not applied for now. 

## VirtualService.yaml

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: {{ printf "%s-%s-virtual-service" .Release.Name .Chart.Name }}
spec:
  gateways:
    - {{ .Values.ezua.virtualService.istioGateway | required ".Values.ezua.virtualService.istioGateway is required !\n" }}
  hosts:
    - {{ .Values.ezua.virtualService.endpoint | required ".Values.ezua.virtualService.endpoint is required !\n" }}
  http:
    - match:
        - uri:
            prefix: /
      rewrite:
        uri: /
      route:
        - destination:
            # Insert target service name here
            host: {{ template "argo-cd.server.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
            port:
              # Insert target service port number here
              number: {{ .Values.service.port }}

```

## values.yaml

Uncommented podLabels and set to:
```yaml
podLabels:
  hpe-ezua/app: grafana-aie
  hpe-ezua/type: vendor-service

```

Also uncommented resource requests and limits, and kept the proposed values.

```yaml
ezua:
  #Use next options in order to configure the application endpoint.
  virtualService:
    endpoint: "argo-cd.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"

### Added for virtualService
service:
  port: 80

configs:
...
  params:
  ...
    # Set insecure as True to enable Istio Ingress sending traffic with HTTP ref: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#istio
    server.insecure: true
```

```sh
[root@ez-master01 ~]# k describe virtualservice -n argo-cd
Name:         argo-cd-argo-cd-virtual-service
Namespace:    argo-cd
Labels:       app.kubernetes.io/managed-by=Helm
Annotations:  meta.helm.sh/release-name: argo-cd
              meta.helm.sh/release-namespace: argo-cd
API Version:  networking.istio.io/v1beta1
Kind:         VirtualService
Metadata:
  Creation Timestamp:  2025-04-08T12:34:02Z
  Generation:          1
  Resource Version:    89167467
  UID:                 0e92ba57-fd68-4107-b139-4425df7d616e
Spec:
  Gateways:
    istio-system/ezaf-gateway
  Hosts:
    argo-cd.ingress.pcai0103.sy6.hpecolo.net
  Http:
    Match:
      Uri:
        Prefix:  /
    Rewrite:
      Uri:  /
    Route:
      Destination:
        Host:  argo-cd-argocd-server.argo-cd.svc.cluster.local
        Port:
          Number:  80
Events:            <none>
```

## Getting the default password

The generated password can be obtained running the following command:

```sh
kubectl -n NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

where NAMESPACE is the namespace specified during the import process.
