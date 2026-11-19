{{/*
HPE EZUA labels
*/}}
{{- define "hpe-ezua.labels" -}}
hpe-ezua/app: {{ .Release.Name }}
hpe-ezua/type: vendor-service
{{- end }}

{{/*
HPE EZUA labels with a component. Call with (dict "ctx" . "component" "server")
*/}}
{{- define "hpe-ezua.componentLabels" -}}
{{ include "hpe-ezua.labels" .ctx }}
hpe-ezua/component: {{ .component }}
{{- end }}
