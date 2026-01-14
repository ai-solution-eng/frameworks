{{/*
Expand the name of the chart.
*/}}
{{- define "nemo-safe-synthesizer.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nemo-safe-synthesizer.fullname" -}}
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
{{- define "nemo-safe-synthesizer.labels" -}}
{{ include "nemo-safe-synthesizer.selectorLabels" . }}
{{ include "nemo-common.common-labels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nemo-safe-synthesizer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nemo-safe-synthesizer.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nemo-safe-synthesizer.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nemo-safe-synthesizer.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }} 

{{/*
Image used to run jobs for the safe-synthesizer api
*/}}
{{- define "nemo-safe-synthesizer.jobs-image" -}}
{{- if .Values.jobsImage.registry -}}
{{ .Values.jobsImage.registry }}/{{ .Values.jobsImage.repository }}:{{ default .Chart.AppVersion .Values.jobsImage.tag }}
{{- else -}}
{{ .Values.jobsImage.repository }}:{{ default .Chart.AppVersion .Values.jobsImage.tag }}
{{- end }}
{{- end }}


{{- define "nemo-safe-synthesizer.secret-name" -}}
{{- if .Values.classify.existingSecret -}}
{{- print .Values.classify.existingSecret -}}
{{- else -}}
{{- print "safe-synthesizer-classify-secret" -}}
{{- end -}}
{{- end -}}
