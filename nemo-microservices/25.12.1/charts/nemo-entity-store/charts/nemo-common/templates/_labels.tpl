
{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nemo-common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
nemo-common.common-labels implements a standardized template for common labels
throughout helm objects
*/}}
{{- define "nemo-common.common-labels" -}}
helm.sh/chart: {{ include "nemo-common.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
