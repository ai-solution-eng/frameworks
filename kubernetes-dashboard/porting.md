# Porting Kubernetes Dashboard to PCAI
Kubernetes Dashboard is a general purpose, web-based UI for Kubernetes clusters. It allows users to manage applications running in the cluster and troubleshoot them, as well as manage the cluster itself. [github](https://github.com/kubernetes/dashboard)

## Prerequisites

- Create namespace (if not already created)
```bash
export NAMESPACE="kube-dash"
kubectl create namespace $NAMESPACE
```
- Create ServiceAccount and Get the token for authentication. [reference](https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md#creating-sample-user)
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-dash
EOF
```
```bash
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-dash
EOF
```
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: admin-user
  namespace: kube-dash
  annotations:
    kubernetes.io/service-account.name: "admin-user"   
type: kubernetes.io/service-account-token  
EOF
```
- Get the Token with following command. 
```bash
kubectl get secret admin-user -n $NAMESPACE -o jsonpath="{.data.token}" | base64 -d
```

### Changes in values.yaml

- Add PCAI's virtual service using Istio gateway.
```yaml
ezua:
  #Use next options in order to configure the application endpoint.
  virtualService:
    endpoint: "kube-dash.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
```
- add HPE EzUA label
```yaml
# General configuration shared across resources
app:
...
  # Common labels & annotations shared across all deployed resources
  labels:
    hpe-ezua/app: kubernetes-dashboard
    hpe-ezua/type: vendor-service
```
- configure Kong Proxy with HTTP
```yaml
kong:
  enabled: true
...
  proxy:
    type: ClusterIP
    http:
      enabled: true
```

- Point Kong Proxy service url to the virtualservice's destination
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
            host: {{ template "kubernetes-dashboard.name" . }}-kong-proxy.{{ .Release.Namespace }}.svc.cluster.local
            port:
              # Insert target service port number here
              number: 80
```