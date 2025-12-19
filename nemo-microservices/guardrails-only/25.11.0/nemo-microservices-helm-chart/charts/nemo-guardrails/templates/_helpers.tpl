{{/*
Expand the name of the chart.
*/}}
{{- define "helm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "helm.fullname" -}}
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
{{- define "helm.labels" -}}
{{ include "nemo-common.common-labels" . }}
{{ include "helm.selectorLabels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "helm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "helm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "helm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "helm.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Convert a file path to a unique key for the config map
*/}}
{{- define "helm.filepathToConfigMapKey" -}}
{{- $filePath := . | replace "/" "_" | lower }}
{{- $filePath }}
{{- end }}


{{/*
Validate data and filePath are not set simultaneously
*/}}
{{- define "validate.configStore.files" -}}
    {{/* validate that only one of `data` or filePath is set */}}
    {{- $areBothOptionsSet := (and .dataKey .filePathKey) -}}
    {{- if $areBothOptionsSet -}}
        {{- $dataPath := printf ".Values.configStore.files.%s.data" .mountedFilePath -}}
        {{- $filePathPath := printf ".Values.configStore.files.%s.filePath" .mountedFilePath -}}
        {{- fail (printf "%s and %s cannot be set simultaneously. Set only one of them. Note: `filePath` can be set only with --set-file flag when installing the chart." $dataPath $filePathPath) -}}
    {{- end -}}
    {{- $areNeitherSet := (and (not .dataKey) (not .filePathKey)) -}}
    {{- if $areNeitherSet -}}
        {{- $dataPath := printf ".Values.configStore.files.%s.data" .mountedFilePath -}}
        {{- $filePathPath := printf ".Values.configStore.files.%s.filePath" .mountedFilePath -}}
        {{- fail (printf "One of %s or %s must be set. Set only one of them. Note: `filePath` can be set only with --set-file flag when installing the chart." $dataPath $filePathPath) -}}
    {{- end -}}
{{- end -}}

{{/*
OpenTelemetry environment variables
*/}}
{{- define "helm.otelEnvVars" -}}
- name: NAMESPACE
  value: "{{ .Release.Namespace }}"
{{- range $k, $v := .Values.otelEnvVars }}
- name: "{{ $k }}"
  value: "{{ $v }}"
{{- end }}
{{- if and .Values.otelExporterEnabled ( index .Values "opentelemetry-collector" ).enabled ( not ( index .Values.otelEnvVars "OTEL_EXPORTER_OTLP_ENDPOINT" ) ) }}
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: "http://{{ .Release.Name }}-opentelemetry-collector:4317"
{{- end }}
{{- if .Values.otelExporterEnabled }}
- name: OTEL_SDK_DISABLED
  value: "false"
{{- else }}
- name: OTEL_SDK_DISABLED
  value: "true"
{{- end }}
{{- end -}}