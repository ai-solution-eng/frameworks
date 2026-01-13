{{/*
Expand the name of the chart.
*/}}
{{- define "nemo-core.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nemo-core.fullname" -}}
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
Create a named core-api service name which can be included from parent chart
*/}}
{{- define "nemo-core.api-servicename" }}
{{- printf "%s-api" ( include "nemo-common.servicename" . | trunc 59 ) }}
{{- end }}

{{/*
Create a named core controller service name which can be included from parent chart
*/}}
{{- define "nemo-core.controller-servicename" }}
{{- printf "%s-controller" ( include "nemo-common.servicename" . | trunc 52 ) }}
{{- end }}

{{/*
Create a named core controller service name which can be included from parent chart
*/}}
{{- define "nemo-core.database-migrations-servicename" }}
{{- printf "%s-migrations" ( include "nemo-core.fullname" .) }}
{{- end }}

{{/*
Create a named logcollector-configmap name which can be included from parent chart
*/}}
{{- define "nemo-core.logcollector-servicename" }}
{{- printf "%s-jobs-logcollector" ( include "nemo-common.servicename" . | trunc 45 ) }}
{{- end }}

{{/*
Create a named logsidecar-configmap name which can be included from parent chart
*/}}
{{- define "nemo-core.logsidecar-configmap" }}
{{- printf "%s-jobs-logsidecar" ( include "nemo-core.fullname" .) }}
{{- end }}


{{/*
Common labels
*/}}
{{- define "nemo-core.labels" -}}
{{ include "nemo-core.selectorLabels" . }}
{{ include "nemo-common.common-labels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nemo-core.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nemo-core.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the API service account to use
*/}}
{{- define "nemo-core.apiServiceAccountName" -}}
{{- if .Values.api.serviceAccount.create }}
{{- default (printf "%s-api" (include "nemo-core.fullname" .)) .Values.api.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.api.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the Controller service account to use
*/}}
{{- define "nemo-core.controllerServiceAccountName" -}}
{{- if .Values.controller.serviceAccount.create }}
{{- default (printf "%s-controller" (include "nemo-core.fullname" .)) .Values.controller.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.controller.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the Log Collector service account to use
*/}}
{{- define "nemo-core.logcollectorServiceAccountName" -}}
{{- if .Values.logcollector.serviceAccount.create }}
{{- default (printf "%s-logcollector" (include "nemo-core.fullname" .)) .Values.logcollector.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.logcollector.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the PVC name
*/}}
{{- define "nemo-core.persistentVolumeClaim" -}}
{{- printf "%s-job-storage" (include "nemo-core.fullname" .) }}
{{- end }}

{{/*
Models Database Name - use override if set, otherwise fall back to standard postgresql/externalDatabase
*/}}
{{- define "nemo-core.models.database.name" -}}
{{- if .Values.config.models.database.name -}}
{{- .Values.config.models.database.name -}}
{{- else -}}
{{- include "nemo-common.postgresql.name" . -}}
{{- end -}}
{{- end -}}

{{/*
Models Database Host - use override if set, otherwise fall back to standard postgresql/externalDatabase
*/}}
{{- define "nemo-core.models.database.host" -}}
{{- if .Values.config.models.database.host -}}
{{- .Values.config.models.database.host -}}
{{- else -}}
{{- include "nemo-common.postgresql.host" . -}}
{{- end -}}
{{- end -}}

{{/*
Models Database Port - use override if set, otherwise fall back to standard postgresql/externalDatabase
*/}}
{{- define "nemo-core.models.database.port" -}}
{{- if .Values.config.models.database.port -}}
{{- printf "%v" .Values.config.models.database.port -}}
{{- else -}}
{{- include "nemo-common.postgresql.port" . -}}
{{- end -}}
{{- end -}}

{{/*
Models Database User - use override if set, otherwise fall back to standard postgresql/externalDatabase
*/}}
{{- define "nemo-core.models.database.user" -}}
{{- if .Values.config.models.database.user -}}
{{- .Values.config.models.database.user -}}
{{- else -}}
{{- include "nemo-common.postgresql.user" . -}}
{{- end -}}
{{- end -}}

{{/*
Models Database Password Secret Name - returns the name of the secret containing the password
*/}}
{{- define "nemo-core.models.database.password-secret-name" -}}
{{- if .Values.config.models.database.passwordExistingSecret.name -}}
{{- .Values.config.models.database.passwordExistingSecret.name -}}
{{- else if .Values.config.models.database.password -}}
{{- printf "%s-models-db-secret" (include "nemo-core.fullname" .) -}}
{{- else -}}
{{- include "nemo-common.postgresql.secret-name" . -}}
{{- end -}}
{{- end -}}

{{/*
Models Database Password Key - returns the key in the secret that contains the password
*/}}
{{- define "nemo-core.models.database.password-key" -}}
{{- if .Values.config.models.database.passwordExistingSecret.name -}}
{{- .Values.config.models.database.passwordExistingSecret.key -}}
{{- else if .Values.config.models.database.password -}}
{{- print "password" -}}
{{- else -}}
{{- include "nemo-common.postgresql.password-key" . -}}
{{- end -}}
{{- end -}}

{{/*
Check if k8s-nim-operator backend is enabled in the models controller backends
*/}}
{{- define "nemo-core.models.nimOperatorEnabled" -}}
{{- $enabled := false -}}
{{- range $backendName, $backendSpec := .Values.config.models.controller.backends -}}
{{- if and (eq $backendName "k8s-nim-operator") $backendSpec.enabled -}}
{{- $enabled = true -}}
{{- end -}}
{{- end -}}
{{- $enabled -}}
{{- end -}}
