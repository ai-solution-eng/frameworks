{{/*
Expand the name of the chart.
*/}}
{{- define "entity-store.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "entity-store.fullname" -}}
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
PostgreSQL service name
*/}}
{{- define "entity-store.postgresql.fullname" -}}
{{ template "postgresql.v1.primary.fullname" .Subcharts.postgresql }}
{{- end -}}

##
{{/*
PostgreSQL Hostname
*/}}
{{- define "entity-store.database.host" -}}
{{- if .Values.postgresql.enabled -}}
    {{- print (include "entity-store.postgresql.fullname" .) -}}
{{- else -}}
    {{- print .Values.externalDatabase.host -}}
{{- end -}}
{{- end -}}

{{/*
PostgreSQL Port
*/}}
{{- define "entity-store.database.port" -}}
{{- if .Values.postgresql.enabled -}}
    {{- printf "%d" (.Values.postgresql.primary.service.ports.postgresql | int) -}}
{{- else -}}
    {{- printf "%d" (.Values.externalDatabase.port | int) -}}
{{- end -}}
{{- end -}}

{{/*
PostgreSQL User
*/}}
{{- define "entity-store.database.user" -}}
{{- if .Values.postgresql.enabled -}}
    {{- print .Values.postgresql.auth.username -}}
{{- else -}}
    {{- print .Values.externalDatabase.user -}}
{{- end -}}
{{- end -}}

{{/*
PostgreSQL database name
*/}}
{{- define "entity-store.database.name" -}}
{{- if .Values.postgresql.enabled -}}
    {{- print .Values.postgresql.auth.database -}}
{{- else -}}
    {{- print .Values.externalDatabase.database -}}
{{- end -}}
{{- end -}}

{{/*
PostgreSQL Secret Name
*/}}
{{- define "entity-store.database.secretName" -}}
{{- if .Values.postgresql.enabled -}}
    {{- if .Values.postgresql.auth.existingSecret -}}
    {{- print .Values.postgresql.auth.existingSecret -}}
    {{- else -}}
    {{- print (include "entity-store.postgresql.fullname" .) -}}
    {{- end -}}
{{- else if .Values.externalDatabase.existingSecret -}}
    {{- print .Values.externalDatabase.existingSecret -}}
{{- else -}}
    {{- printf "%s-%s" (include "entity-store.fullname" .) "externaldb" -}}
{{- end -}}
{{- end -}}

{{/*
PostgreSQL Secret Key
*/}}
{{- define "entity-store.database.passwordKey" -}}
{{- if or .Values.postgresql.enabled (not .Values.externalDatabase.existingSecret) -}}
    {{- print "password" -}}
{{- else -}}
    {{- print .Values.externalDatabase.existingSecretPasswordKey -}}
{{- end -}}
{{- end -}}


{{/*
Common labels
*/}}
{{- define "entity-store.labels" -}}
{{ include "entity-store.selectorLabels" . }}
{{ include "nemo-common.common-labels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "entity-store.selectorLabels" -}}
app.kubernetes.io/name: {{ include "entity-store.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Create the name of the service account to use
*/}}
{{- define "entity-store.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "entity-store.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Image pull secret data for NGC
*/}}
{{- define "entity-store.nvcr.imagepull.secret.data" -}}
{{- $username := "$oauthtoken" -}}
{{- $password := .Values.demo.ngcApiKey -}}
{{- $registry := "nvcr.io" -}}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"auth\":\"%s\"}}}" $registry $username $password (printf "%s:%s" $username $password | b64enc) | b64enc }}
{{- end }}

