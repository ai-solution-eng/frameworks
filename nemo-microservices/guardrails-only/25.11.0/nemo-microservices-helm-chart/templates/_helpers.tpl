{{/*
Expand the name of the chart.
*/}}
{{- define "nemo-platform.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nemo-platform.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nemo-platform.labels" -}}
helm.sh/chart: {{ include "nemo-platform.chart" . }}
{{ include "nemo-platform.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nemo-platform.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nemo-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
