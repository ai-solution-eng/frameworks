{{/*
Global level service name definition.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
This will allow top level overrides of service names when using the platform helm chart
*/}}
{{- define "nemo-common.servicename" -}}
{{- if .Values.serviceName }}
{{- .Values.serviceName | trunc 63 | trimSuffix "-" }}
{{- else }}
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
{{- end }}
