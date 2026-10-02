{{/*
HPE EZUA labels — required for tile health, scheduling, metering, preemption.
*/}}
{{- define "hpe-ezua.labels" -}}
hpe-ezua/app: {{ .Release.Name }}
hpe-ezua/type: vendor-service
{{- end }}
