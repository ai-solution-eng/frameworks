{{/*
Copyright Broadcom, Inc. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/* vim: set filetype=mustache: */}}

{{/*
Create a global name for the chart to use and parse with other naming functions
Please use instead of "common.names.fullname" to preserve support for .Values.global.postgresql.fullnameOverride
*/}}
{{- define "postgresql.v1.chart.fullname" -}}
{{- default (include "common.names.fullname" .) .Values.global.postgresql.fullnameOverride -}}
{{- end -}}

{{/*
Create a default fully qualified app name for PostgreSQL Primary objects
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgresql.v1.primary.fullname" -}}
{{- $fullname := include "postgresql.v1.chart.fullname" . -}}
{{- ternary (printf "%s-%s" $fullname .Values.primary.name | trunc 63 | trimSuffix "-") $fullname (eq .Values.architecture "replication") -}}
{{- end -}}

{{/*
Create a default fully qualified app name for PostgreSQL read-only replicas objects
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgresql.v1.readReplica.fullname" -}}
{{- printf "%s-%s" (include "postgresql.v1.chart.fullname" .) .Values.readReplicas.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the default FQDN for PostgreSQL primary headless service
We truncate at 63 chars because of the DNS naming spec.
*/}}
{{- define "postgresql.v1.primary.svc.headless" -}}
{{- printf "%s-hl" (include "postgresql.v1.primary.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the default FQDN for PostgreSQL read-only replicas headless service
We truncate at 63 chars because of the DNS naming spec.
*/}}
{{- define "postgresql.v1.readReplica.svc.headless" -}}
{{- printf "%s-hl" (include "postgresql.v1.readReplica.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper PostgreSQL image name
*/}}
{{- define "postgresql.v1.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper PostgreSQL metrics image name
*/}}
{{- define "postgresql.v1.metrics.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.metrics.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper image name (for the init container volume-permissions image)
*/}}
{{- define "postgresql.v1.volumePermissions.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.volumePermissions.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "postgresql.v1.imagePullSecrets" -}}
{{ include "common.images.renderPullSecrets" (dict "images" (list .Values.image .Values.metrics.image .Values.volumePermissions.image) "context" .) }}
{{- end -}}

{{/*
Return the name for a custom user to create
*/}}
{{- define "postgresql.v1.username" -}}
{{- coalesce (((.Values.global).postgresql).auth).username .Values.auth.username | default "" -}}
{{- end -}}

{{/*
Return the name for a custom database to create
*/}}
{{- define "postgresql.v1.database" -}}
{{- tpl (coalesce (((.Values.global).postgresql).auth).database .Values.auth.database | default "") . -}}
{{- end -}}

{{/*
Get the password secret.
*/}}
{{- define "postgresql.v1.secretName" -}}
{{- $existingSecret := coalesce (((.Values.global).postgresql).auth).existingSecret .Values.auth.existingSecret -}}
{{- if $existingSecret -}}
    {{- tpl $existingSecret . -}}
{{- else -}}
    {{- include "postgresql.v1.chart.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Get the replication-password key.
*/}}
{{- define "postgresql.v1.replicationPasswordKey" -}}
{{- if or (((.Values.global).postgresql).auth).existingSecret .Values.auth.existingSecret -}}
    {{- tpl (default "replication-password" (coalesce (((.Values.global).postgresql).auth).secretKeys.replicationPasswordKey .Values.auth.secretKeys.replicationPasswordKey)) . -}}
{{- else -}}
    {{- "replication-password" -}}
{{- end -}}
{{- end -}}

{{/*
Get the admin-password key.
*/}}
{{- define "postgresql.v1.adminPasswordKey" -}}
{{- if or (((.Values.global).postgresql).auth).existingSecret .Values.auth.existingSecret -}}
    {{- tpl (default "postgres-password" (coalesce (((.Values.global).postgresql).auth).secretKeys.adminPasswordKey .Values.auth.secretKeys.adminPasswordKey)) . -}}
{{- else -}}
    {{- "postgres-password" -}}
{{- end -}}
{{- end -}}

{{/*
Get the user-password key.
*/}}
{{- define "postgresql.v1.userPasswordKey" -}}
{{- if or (empty (include "postgresql.v1.username" .)) (eq (include "postgresql.v1.username" .) "postgres") -}}
    {{- include "postgresql.v1.adminPasswordKey" . -}}
{{- else if or (((.Values.global).postgresql).auth).existingSecret .Values.auth.existingSecret -}}
    {{- tpl (default "password" (coalesce (((.Values.global).postgresql).auth).secretKeys.userPasswordKey .Values.auth.secretKeys.userPasswordKey)) . -}}
{{- else -}}
    {{- "password" -}}
{{- end -}}
{{- end -}}

{{/*
Get metrics-password key.
*/}}
{{- define "postgresql.v1.metricsPasswordKey" -}}
{{- if or (((.Values.global).postgresql).auth).existingSecret .Values.auth.existingSecret -}}
    {{- tpl (default "metrics-password" (coalesce (((.Values.global).postgresql).auth).secretKeys.metricsPasswordKey .Values.auth.secretKeys.metricsPasswordKey)) . -}}
{{- else -}}
    {{- "metrics-password" -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a secret object should be created
*/}}
{{- define "postgresql.v1.createSecret" -}}
{{- $customUser := include "postgresql.v1.username" . -}}
{{- $postgresPassword := include "common.secrets.lookup" (dict "secret" (include "postgresql.v1.chart.fullname" .) "key" .Values.auth.secretKeys.adminPasswordKey "defaultValue" (ternary (coalesce .Values.global.postgresql.auth.postgresPassword .Values.auth.postgresPassword .Values.global.postgresql.auth.password .Values.auth.password) (coalesce .Values.global.postgresql.auth.postgresPassword .Values.auth.postgresPassword) (or (empty $customUser) (eq $customUser "postgres"))) "context" $) -}}
{{- if and (not (or .Values.global.postgresql.auth.existingSecret .Values.auth.existingSecret)) (or $postgresPassword .Values.auth.enablePostgresUser (and (not (empty $customUser)) (ne $customUser "postgres")) (eq .Values.architecture "replication") (and .Values.ldap.enabled (or .Values.ldap.bind_password .Values.ldap.bindpw))) -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a secret object should be created for PostgreSQL
*/}}
{{- define "postgresql.v1.createPreviousSecret" -}}
{{- if and .Values.passwordUpdateJob.previousPasswords.postgresPassword (not .Values.passwordUpdateJob.previousPasswords.existingSecret) }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the secret with previous PostgreSQL credentials
*/}}
{{- define "postgresql.v1.update-job.previousSecretName" -}}
{{- if .Values.passwordUpdateJob.previousPasswords.existingSecret -}}
    {{- /* The secret with the previous password is provided externally */ -}}
    {{- tpl .Values.passwordUpdateJob.previousPasswords.existingSecret . -}}
{{- else if .Values.passwordUpdateJob.previousPasswords.postgresPassword -}}
    {{- /* The secret with the previous password is managed by the helm chart */ -}}
    {{- printf "%s-previous-secret" (include "postgresql.v1.chart.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- /* The secret with the new password is managed by the helm chart. We use the current secret name as it has the old password */ -}}
    {{- include "postgresql.v1.chart.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the secret with new PostgreSQL credentials
*/}}
{{- define "postgresql.v1.update-job.newSecretName" -}}
{{- if and (not .Values.passwordUpdateJob.previousPasswords.existingSecret) (not .Values.passwordUpdateJob.previousPasswords.postgresPassword) -}}
    {{- /* The secret with the new password is managed by the helm chart. We create a new secret as the current one has the old password */ -}}
    {{- printf "%s-new-secret" (include "postgresql.v1.chart.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- /* The secret with the new password is managed externally */ -}}
    {{- include "postgresql.v1.secretName" . -}}
{{- end -}}
{{- end -}}

{{/*
Return PostgreSQL service port
*/}}
{{- define "postgresql.v1.service.port" -}}
{{- coalesce ((((.Values.global).postgresql).service).ports).postgresql .Values.primary.service.ports.postgresql -}}
{{- end -}}

{{/*
Return PostgreSQL read replica service port
*/}}
{{- define "postgresql.v1.readReplica.service.port" -}}
{{- coalesce ((((.Values.global).postgresql).service).ports).postgresql .Values.readReplicas.service.ports.postgresql -}}
{{- end -}}

{{/*
Get the PostgreSQL primary configuration ConfigMap name.
*/}}
{{- define "postgresql.v1.primary.configmapName" -}}
{{- if .Values.primary.existingConfigmap -}}
    {{- tpl .Values.primary.existingConfigmap . -}}
{{- else -}}
    {{- printf "%s-configuration" (include "postgresql.v1.primary.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a ConfigMap object should be created for PostgreSQL primary with the configuration
*/}}
{{- define "postgresql.v1.primary.createConfigmap" -}}
{{- if and (or .Values.primary.configuration .Values.primary.pgHbaConfiguration) (not .Values.primary.existingConfigmap) -}}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Get the PostgreSQL primary extended configuration ConfigMap name.
*/}}
{{- define "postgresql.v1.primary.extendedConfigmapName" -}}
{{- if .Values.primary.existingExtendedConfigmap -}}
    {{- tpl .Values.primary.existingExtendedConfigmap . -}}
{{- else -}}
    {{- printf "%s-extended-configuration" (include "postgresql.v1.primary.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Get the PostgreSQL read replica extended configuration ConfigMap name.
*/}}
{{- define "postgresql.v1.readReplicas.extendedConfigmapName" -}}
{{- printf "%s-extended-configuration" (include "postgresql.v1.readReplica.fullname" .) -}}
{{- end -}}

{{/*
Return true if a ConfigMap object should be created for PostgreSQL primary with the extended configuration
*/}}
{{- define "postgresql.v1.primary.createExtendedConfigmap" -}}
{{- if and .Values.primary.extendedConfiguration (not .Values.primary.existingExtendedConfigmap) -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a ConfigMap object should be created for PostgreSQL read replica with the extended configuration
*/}}
{{- define "postgresql.v1.readReplicas.createExtendedConfigmap" -}}
{{- if .Values.readReplicas.extendedConfiguration -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "postgresql.v1.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "postgresql.v1.chart.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return true if a ConfigMap should be mounted with PostgreSQL configuration
*/}}
{{- define "postgresql.v1.mountConfigurationCM" -}}
{{- if or .Values.primary.configuration .Values.primary.pgHbaConfiguration .Values.primary.existingConfigmap -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Get the pre-initialization scripts ConfigMap name.
*/}}
{{- define "postgresql.v1.preInitDb.scriptsCM" -}}
{{- if .Values.primary.preInitDb.scriptsConfigMap -}}
    {{- tpl .Values.primary.preInitDb.scriptsConfigMap . -}}
{{- else -}}
    {{- printf "%s-preinit-scripts" (include "postgresql.v1.primary.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Get the initialization scripts ConfigMap name.
*/}}
{{- define "postgresql.v1.initdb.scriptsCM" -}}
{{- if .Values.primary.initdb.scriptsConfigMap -}}
    {{- tpl .Values.primary.initdb.scriptsConfigMap . -}}
{{- else -}}
    {{- printf "%s-init-scripts" (include "postgresql.v1.primary.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if TLS is enabled for LDAP connection
*/}}
{{- define "postgresql.v1.ldap.tls.enabled" -}}
{{- if or (and (kindIs "string" .Values.ldap.tls) (not (empty .Values.ldap.tls))) (and (kindIs "map" .Values.ldap.tls) .Values.ldap.tls.enabled) -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Get the pg_isready command to use on probes
*/}}
{{- define "postgresql.v1.pgIsreadyCommand" -}}
{{- $user := default "postgres" (include "postgresql.v1.username" .) -}}
{{- $dbFlags := "" -}}
{{- if (include "postgresql.v1.database" .) }}
    {{- $dbFlags = printf "dbname=%s" (include "postgresql.v1.database" .) -}}
{{- end -}}
{{- if and .Values.tls.enabled (or .Values.tls.certCAFilename .Values.tls.autoGenerated) -}}
    {{- $dbFlags = cat $dbFlags "sslcert=/opt/bitnami/postgresql/certs/tls.crt sslkey=/opt/bitnami/postgresql/certs/tls.key" -}}
    {{/* We need to use "postgres" given the CN of the certificate is "postgres" and it will not work with other users */}}
    {{- $user = "postgres" -}}
{{- end -}}
exec pg_isready -U {{ $user | quote }} {{- if not (empty $dbFlags) }} -d "{{ $dbFlags }}" {{- end }} -h 127.0.0.1 -p {{ .Values.containerPorts.postgresql }}
{{- end -}}

{{/*
Return the name of the TLS credentials secret.
*/}}
{{- define "postgresql.v1.tlsSecretName" -}}
{{- if .Values.tls.autoGenerated -}}
    {{- printf "%s-crt" (include "postgresql.v1.chart.fullname" .) -}}
{{- else -}}
    {{ tpl (required "A secret containing TLS certificates is required when TLS is enabled" .Values.tls.certificatesSecret) . }}
{{- end -}}
{{- end -}}

{{/*
Check if there are rolling tags in the images
*/}}
{{- define "postgresql.v1.checkRollingTags" -}}
{{- range (list .Values.image .Values.metrics.image .Values.volumePermissions.image) -}}
{{- include "common.warnings.rollingTag" . -}}
{{- end -}}
{{- end -}}

{{/*
Compile all warnings into a single message, and call fail.
*/}}
{{- define "postgresql.v1.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "postgresql.v1.validateValues.ldapConfigurationMethod" .) -}}
{{- $messages := append $messages (include "postgresql.v1.validateValues.psp" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{- printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/*
Validate values of Postgresql - If ldap.url is used then you don't need the other settings for ldap
*/}}
{{- define "postgresql.v1.validateValues.ldapConfigurationMethod" -}}
{{- if and .Values.ldap.enabled (and (not (empty .Values.ldap.url)) (not (empty .Values.ldap.server))) -}}
postgresql: ldap.url, ldap.server
    You cannot set both `ldap.url` and `ldap.server` at the same time.
    Please provide a unique way to configure LDAP.
    More info at https://www.postgresql.org/docs/current/auth-ldap.html
{{- end -}}
{{- end -}}

{{/*
Validate values of Postgresql - If PSP is enabled RBAC should be enabled too
*/}}
{{- define "postgresql.v1.validateValues.psp" -}}
{{- if and .Values.psp.create (not .Values.rbac.create) -}}
postgresql: psp.create, rbac.create
    RBAC should be enabled if PSP is enabled in order for PSP to work.
    More info at https://kubernetes.io/docs/concepts/policy/pod-security-policy/#authorizing-policies
{{- end -}}
{{- end -}}
