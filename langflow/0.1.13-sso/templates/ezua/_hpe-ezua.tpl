{{/*
HPE EZUA labels
Required by HPE AI Essentials (PCAI) so the imported framework is
identified, scheduled, monitored and metered correctly. Without these,
the application tile shows the framework in an "Unknown" state.

Usage in a workload (Deployment/StatefulSet/Pod), in BOTH the
metadata.labels block and the spec.template.metadata.labels block:

    {{- include "hpe-ezua.labels" . | nindent <n> }}

For a per-component label (recommended: at least one component per
framework), add alongside the include, e.g.:

    hpe-ezua/component: backend     # or: frontend
*/}}
{{- define "hpe-ezua.labels" -}}
hpe-ezua/app: {{ .Release.Name }}
hpe-ezua/type: vendor-service
{{- end }}
