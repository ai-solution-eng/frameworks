{{/*
HPE EZUA labels — required for the platform's "Resource Management monitoring"
and "Pod health monitoring" features (see byoa-tutorials tutorial/README.md).
Apply to Workload resources (Deployment, StatefulSet, Pods) via:
  {{- include "hpe-ezua.labels" . | nindent 4 }}
*/}}
{{- define "hpe-ezua.labels" -}}
hpe-ezua/app: {{ .Release.Name }}
hpe-ezua/type: vendor-service
{{- end }}
