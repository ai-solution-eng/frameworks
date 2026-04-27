{{/*
Expand the name of the chart.
*/}}
{{- define "nemo-kubernetes-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nemo-kubernetes-operator.fullname" -}}
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
{{- define "nemo-kubernetes-operator.labels" -}}
{{ include "nemo-common.common-labels" . }}
{{ include "nemo-kubernetes-operator.selectorLabels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nemo-kubernetes-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nemo-kubernetes-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nemo-kubernetes-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nemo-kubernetes-operator.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
