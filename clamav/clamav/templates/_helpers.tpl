{{/*
HPE EZUA labels
*/}}
{{- define "hpe-ezua.labels" -}}
hpe-ezua/app: {{ .Release.Name }}
hpe-ezua/type: vendor-service
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "clamav.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "clamav.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "clamav.api.fullname" -}}
{{- printf "%s-api" (include "clamav.fullname" .) }}
{{- end }}

{{/*
Create chart label
*/}}
{{- define "clamav.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "clamav.labels" -}}
helm.sh/chart: {{ include "clamav.chart" . }}
{{ include "clamav.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "clamav.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clamav.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ClamAV Server component labels
*/}}
{{- define "clamav.server.labels" -}}
{{ include "clamav.labels" . }}
app.kubernetes.io/component: server
{{- end }}

{{- define "clamav.server.selectorLabels" -}}
{{ include "clamav.selectorLabels" . }}
app.kubernetes.io/component: server
{{- end }}

{{/*
ClamAV API component labels
*/}}
{{- define "clamav.api.labels" -}}
{{ include "clamav.labels" . }}
app.kubernetes.io/component: api
{{- end }}

{{- define "clamav.api.selectorLabels" -}}
{{ include "clamav.selectorLabels" . }}
app.kubernetes.io/component: api
{{- end }}

{{/*
ServiceAccount name
*/}}
{{- define "clamav.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "clamav.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
ClamAV Server service hostname (used by API)
*/}}
{{- define "clamav.server.host" -}}
{{- printf "%s-server" (include "clamav.fullname" .) }}
{{- end }}
