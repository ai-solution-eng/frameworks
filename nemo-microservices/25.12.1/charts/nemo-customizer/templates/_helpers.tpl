{{/*
Create app name and version as used by the chart label.
*/}}
{{- define "ft.appName" -}}
    {{- default .Chart.Name .Values.nameOverride | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ft.fullname" -}}
{{- if .Values.fullnameOverride }}
    {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
    {{- $name := default .Chart.Name .Values.nameOverride | replace "+" "_" }}
    {{- if contains $name .Release.Name }}
        {{- .Release.Name | trunc 63 | trimSuffix "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name $name | replace "+" "_" | trunc 63 | trimSuffix "-" }}
    {{- end }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ft.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ft.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Common labels
*/}}
{{- define "ft.labels" -}}
{{ include "ft.selectorLabels" . }}
{{ include "nemo-common.common-labels" . }}
{{- end }}


{{/*
Create the name of the service account to use
*/}}
{{- define "ft.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
    {{- default (include "ft.fullname" .) .Values.serviceAccount.name }}
{{- else }}
    {{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
PostgreSQL service name
*/}}
{{- define "ft.postgresql.fullname" -}}
{{ template "postgresql.v1.primary.fullname" .Subcharts.postgresql }}
{{- end -}}


{{/*
PostgreSQL Hostname
*/}}
{{- define "ft.database.host" -}}
{{- if .Values.postgresql.enabled -}}
    {{- print (include "ft.postgresql.fullname" .) -}}
{{- else -}}
    {{- print .Values.externalDatabase.host -}}
{{- end -}}
{{- end -}}

{{/*
PostgreSQL Port
*/}}
{{- define "ft.database.port" -}}
{{- if .Values.postgresql.enabled -}}
    {{- printf "%d" (.Values.postgresql.primary.service.ports.postgresql | int) -}}
{{- else -}}
    {{- printf "%d" (.Values.externalDatabase.port | int) -}}
{{- end -}}
{{- end -}}

{{/*
PostgreSQL User
*/}}
{{- define "ft.database.user" -}}
{{- if .Values.postgresql.enabled -}}
    {{- print .Values.postgresql.auth.username -}}
{{- else -}}
    {{- print .Values.externalDatabase.user -}}
{{- end -}}
{{- end -}}

{{/*
PostgreSQL database name
*/}}
{{- define "ft.database.name" -}}
{{- if .Values.postgresql.enabled -}}
    {{- print .Values.postgresql.auth.database -}}
{{- else -}}
    {{- print .Values.externalDatabase.database -}}
{{- end -}}
{{- end -}}

{{/*
PostgreSQL Secret Name
*/}}
{{- define "ft.database.secretName" -}}
{{- if .Values.postgresql.enabled -}}
    {{- if .Values.postgresql.auth.existingSecret -}}
    {{- print .Values.postgresql.auth.existingSecret -}}
    {{- else -}}
    {{- print (include "ft.postgresql.fullname" .) -}}
    {{- end -}}
{{- else if .Values.externalDatabase.existingSecret -}}
    {{- print .Values.externalDatabase.existingSecret -}}
{{- else -}}
    {{- printf "%s-%s" (include "ft.fullname" .) "externaldb" -}}
{{- end -}}
{{- end -}}

{{/*
PostgreSQL Secret Key
*/}}
{{- define "ft.database.passwordKey" -}}
{{- if or .Values.postgresql.enabled (not .Values.externalDatabase.existingSecret) -}}
    {{- print "password" -}}
{{- else -}}
    {{- print .Values.externalDatabase.existingSecretPasswordKey -}}
{{- end -}}
{{- end -}}

{{/*
WandB Secret Name
*/}}
{{- define "ft.wandb.secretName" -}}
    {{- if .Values.wandb.existingSecret -}}
    {{- print .Values.wandb.existingSecret -}}
    {{- else -}}
    {{- print "wandb-secret" -}}
    {{- end -}}
{{- end -}}

{{/*
WandB Secret Key
*/}}
{{- define "ft.wandb.secretKey" -}}
{{- if (not .Values.wandb.existingSecret) -}}
    {{- print "encryption_key" -}}
{{- else -}}
    {{- print .Values.wandb.existingSecretKey -}}
{{- end -}}
{{- end -}}

{{/*
Validate WandB
*/}}
{{- define "validate.wandb" -}}
{{/* validate that wandb secretValue and existingSecret+existingSecretKey are not set simultaneously */}}
{{- $areBothOptionsSet := (and .Values.wandb.secretValue (or .Values.wandb.existingSecret .Values.wandb.existingSecretKey)) -}}
{{- if $areBothOptionsSet -}}
{{- fail "If `.Values.wandb.secretValue` is set, `.Values.wandb.existingSecret` and `.Values.wandb.existingSecretKey` must be unset. See details at https://docs.nvidia.com/nemo/microservices/latest/set-up/deploy-as-microservices/customizer.html#wandb" -}}
{{- end -}}
{{/* validate that wandb secret is cretaed: default one, or custom */}}
{{- if and (not .Values.wandb.secretValue) (or (not .Values.wandb.existingSecret) (not .Values.wandb.existingSecretKey)) -}}
{{- fail "Either set `.Values.wandb.secretValue`, or `.Values.wandb.existingSecret` and `.Values.wandb.existingSecretKey`. See details at https://docs.nvidia.com/nemo/microservices/latest/set-up/deploy-as-microservices/customizer.html#wandb" -}}
{{- end -}}
{{- end -}}

{{/*
Validate OpenTelemetry
*/}}
{{- define "validate.openTelemetry" -}}
{{- $otelCollectorEnabled := (index .Values "opentelemetry-collector" "enabled") | default false -}}
{{- if and $otelCollectorEnabled .Values.customizerConfig.openTelemetry.exporterOtlpEndpoint -}}
{{- fail "Either set .Values.customizerConfig.openTelemetry.exporterOtlpEndpoint to use a custom collector, or use the provided collector by setting .Values.opentelemetry-collector.enabled: true" -}}
{{- end -}}
{{- end -}}

{{/*
Validate Sequence Packing
*/}}
{{- define "validate.sequence_packing" -}}
{{- range $key, $config := .Values.customizerConfig.models -}}
  {{- if and (hasKey $config "max_seq_length") (hasKey $config "sequence_packing") (hasKey $config.sequence_packing "pack_size") -}}
    {{- if gt $config.sequence_packing.pack_size $config.max_seq_length -}}
      {{- fail (printf "Error: In Values.customizerConfig.models.%s, sequence_packing.pack_size: %d cannot be greater than max_seq_length: %d" $key (int $config.sequence_packing.pack_size) (int $config.max_seq_length) ) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the exporterOtlpEndpoint to use for OpenTelemetry
*/}}
{{- define "openTelemetry.exporterOtlpEndpoint" -}}
{{- if index .Values "opentelemetry-collector" "enabled" }}
    {{- printf "http://%s-opentelemetry-collector:4317" .Release.Name | quote }}
{{- else }}
    {{- print .Values.customizerConfig.openTelemetry.exporterOtlpEndpoint | quote }}
{{- end }}
{{- end -}}
