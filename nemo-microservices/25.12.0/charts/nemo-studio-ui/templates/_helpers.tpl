{{/*
Expand the name of the chart.
*/}}
{{- define "nemo-studio-ui.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nemo-studio-ui.fullname" -}}
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

{{/*
Common labels
*/}}
{{- define "nemo-studio-ui.labels" -}}
{{ include "nemo-studio-ui.selectorLabels" . }}
{{ include "nemo-common.common-labels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nemo-studio-ui.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nemo-studio-ui.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nemo-studio-ui.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nemo-studio-ui.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
