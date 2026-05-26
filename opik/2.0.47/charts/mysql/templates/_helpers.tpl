{{/*
Expand the name of the chart.
*/}}
{{- define "mysql.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "mysql.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "mysql.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mysql.labels" -}}
helm.sh/chart: {{ include "mysql.chart" . }}
{{ include "mysql.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.global.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mysql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mysql.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mysql.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mysql.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper MySQL image name
*/}}
{{- define "mysql.image" -}}
{{- $registryName := .Values.image.registry -}}
{{- $repositoryName := .Values.image.repository -}}
{{- $tag := .Values.image.tag | toString -}}
{{- if .Values.global }}
    {{- if .Values.global.imageRegistry }}
     {{- $registryName = .Values.global.imageRegistry -}}
    {{- end -}}
{{- end -}}
{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else }}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end }}
{{- end }}

{{/*
Return the proper Storage Class
*/}}
{{- define "mysql.storageClass" -}}
{{- $storageClass := .Values.primary.persistence.storageClass -}}
{{- if .Values.global -}}
    {{- if .Values.global.storageClass -}}
        {{- $storageClass = .Values.global.storageClass -}}
    {{- end -}}
{{- end -}}
{{- if $storageClass -}}
  {{- if (eq "-" $storageClass) -}}
      {{- printf "storageClassName: \"\"" -}}
  {{- else }}
      {{- printf "storageClassName: %s" $storageClass -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the secret name for MySQL passwords
*/}}
{{- define "mysql.secretName" -}}
{{- if .Values.auth.existingSecret }}
{{- .Values.auth.existingSecret }}
{{- else }}
{{- include "mysql.fullname" . }}
{{- end }}
{{- end }}

{{/*
Return the configmap name for MySQL configuration
*/}}
{{- define "mysql.configmapName" -}}
{{- if .Values.primary.existingConfigmap }}
{{- .Values.primary.existingConfigmap }}
{{- else }}
{{- printf "%s-config" (include "mysql.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Convert extraFlags string to my.cnf format
Input: "--max-connections=500 --log-bin-trust-function-creators=1"
Output: "max-connections=500\nlog-bin-trust-function-creators=1"
*/}}
{{- define "mysql.extraFlagsToConfig" -}}
{{- if .Values.primary.extraFlags }}
{{- $flags := trim .Values.primary.extraFlags }}
{{- $flags = regexReplaceAll " +--" $flags "\n" }}
{{- $flags = regexReplaceAll "^--" $flags "" }}
{{- $flags }}
{{- end }}
{{- end }}

{{/*
Return the proper MySQL metrics exporter image name
*/}}
{{- define "mysql.metrics.image" -}}
{{- $registryName := .Values.metrics.image.registry -}}
{{- $repositoryName := .Values.metrics.image.repository -}}
{{- $tag := .Values.metrics.image.tag | toString -}}
{{- if .Values.global }}
    {{- if .Values.global.imageRegistry }}
     {{- $registryName = .Values.global.imageRegistry -}}
    {{- end -}}
{{- end -}}
{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else }}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end }}
{{- end }}

