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
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nemo-platform.fullname" -}}
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
Selector labels
*/}}
{{- define "nemo-platform.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nemo-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
hpe-ezua/type: "vendor-service"
hpe-ezua/app: {{ .Release.Name }}
{{- end }}

{{/*
Image Pull Secrets as comma-separated string (for config values)
Returns: "secret1,secret2,secret3"
*/}}
{{- define "nemo-platform.imagepullsecrets.csv" -}}
{{- $secretNames := list }}
{{- if and .Values.global .Values.global.imagePullSecrets }}
{{- range .Values.global.imagePullSecrets }}
{{- $secretNames = append $secretNames .name }}
{{- end }}
{{- else if .Values.imagePullSecrets }}
{{- range .Values.imagePullSecrets }}
{{- $secretNames = append $secretNames .name }}
{{- end }}
{{- end }}
{{- join "," $secretNames }}
{{- end }}
