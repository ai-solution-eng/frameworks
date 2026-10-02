{{/*
HPE EZUA labels — required on every workload pod so the tile reports health.
Subcharts receive these through podLabels in values.yaml; this helper is for
resources rendered by the umbrella chart itself.
*/}}
{{- define "hpe-ezua.labels" -}}
hpe-ezua/app: {{ .Release.Name }}
hpe-ezua/type: vendor-service
hpe-ezua/component: logbook
{{- end }}
