{{/*
HPE EZUA labels (PCAI / HPE AI Essentials).
hpe-ezua/app       : Helm release name, used by EzAppConfig for health discovery.
hpe-ezua/type      : must be "vendor-service" for imported frameworks.
hpe-ezua/component : at least one component is required for each framework.
No hpe-ezua/resource-type label: pgvector is not a GPU workload.
*/}}
{{- define "hpe-ezua.labels" -}}
hpe-ezua/app: {{ .Release.Name | quote }}
hpe-ezua/type: "vendor-service"
hpe-ezua/component: "pgvector"
{{- end }}
