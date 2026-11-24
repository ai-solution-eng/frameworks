{{/*
Common name helpers. Kept deliberately Helm-3 compatible: PCAI ships an older
Helm than this workspace, so avoid Helm-4-only template functions.
*/}}
{{- define "seaweedfs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "seaweedfs.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* image ref, honouring an optional mirror registry for air-gapped PCAI */}}
{{- define "seaweedfs.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- if .Values.image.registry -}}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository $tag -}}
{{- else -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end -}}
{{- end -}}

{{- define "seaweedfs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "seaweedfs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Labels applied to every resource AND to pod templates. The hpe-ezua/* labels are
required by PCAI to recognise the chart as a vendor service. Applied natively here
(preferred) rather than via a Kyverno ClusterPolicy, because this chart is
scaffolded and its templates are fully under our control.
*/}}
{{- define "seaweedfs.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "seaweedfs.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: seaweedfs
hpe-ezua/app: {{ .Chart.Name }}
hpe-ezua/type: vendor-service
{{- end -}}

{{/* name of the Secret holding the S3 identity config.
     s3.existingConfigSecret is the documented key; s3.existingSecret is kept as a
     legacy alias because earlier revisions of the helper read it. */}}
{{- define "seaweedfs.s3SecretName" -}}
{{- if .Values.s3.existingConfigSecret -}}
{{- .Values.s3.existingConfigSecret -}}
{{- else if .Values.s3.existingSecret -}}
{{- .Values.s3.existingSecret -}}
{{- else -}}
{{- printf "%s-s3-config" (include "seaweedfs.fullname" .) -}}
{{- end -}}
{{- end -}}
