{{/*
Chart name.
*/}}
{{- define "pgvector.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Full resource name.
*/}}
{{- define "pgvector.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := include "pgvector.name" . }}
{{- if ne .Release.Name $name }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Namespace helper.
*/}}
{{- define "pgvector.namespace" -}}
{{- if .Values.namespaceOverride }}
{{- .Values.namespaceOverride }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "pgvector.labels" -}}
app.kubernetes.io/name: {{ include "pgvector.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "pgvector.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pgvector.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}