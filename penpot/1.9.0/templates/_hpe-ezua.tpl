{{/*
HPE EZUA labels required by the PCAI Import Framework.
Applied to every Pod, Deployment, Service and PVC rendered by this chart.
*/}}
{{- define "penpot.hpeEzuaLabels" -}}
hpe-ezua/app: {{ .Chart.Name }}
hpe-ezua/type: vendor-service
{{- end -}}
