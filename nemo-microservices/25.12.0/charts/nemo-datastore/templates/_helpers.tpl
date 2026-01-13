{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}


{{- /* multiple replicas assertions */ -}}
{{- if gt .Values.replicaCount 1.0 -}}
  {{- fail "When using multiple replicas, a RWX file system is required" -}}
  {{- if eq (get (.Values.persistence.accessModes 0) "ReadWriteOnce") -}}
    {{- fail "When using multiple replicas, a RWX file system is required" -}}
  {{- end }}

  {{- if eq (get .Values.config.indexer "ISSUE_INDEXER_TYPE") "bleve" -}}
    {{- fail "When using multiple replicas, the repo indexer must be set to 'meilisearch' or 'elasticsearch'" -}}
  {{- end }}

  {{- if and (eq .Values.config.indexer.REPO_INDEXER_TYPE "bleve") (eq .Values.config.indexer.REPO_INDEXER_ENABLED "true") -}}
    {{- fail "When using multiple replicas, the repo indexer must be set to 'meilisearch' or 'elasticsearch'" -}}
  {{- end }}

  {{- if eq .Values.config.indexer.ISSUE_INDEXER_TYPE "bleve" -}}
    {{- (printf "DEBUG: When using multiple replicas, the repo indexer must be set to 'meilisearch' or 'elasticsearch'") | fail -}}
  {{- end }}
{{- end }}

{{- define "gitea.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "gitea.fullname" -}}
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

{{/*
Storage Class
*/}}
{{- define "gitea.persistence.storageClass" -}}
{{- $storageClass := .Values.persistence.storageClass | default .Values.global.storageClass }}
{{- if $storageClass }}
storageClassName: {{ $storageClass | quote }}
{{- end }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "gitea.labels" -}}
{{ include "gitea.selectorLabels" . }}
{{ include "nemo-common.common-labels" . }}
app: {{ include "gitea.name" . }}
version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "gitea.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gitea.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "postgresql-ha.dns" -}}
{{- if (index .Values "postgresql-ha").enabled -}}
{{- printf "%s-postgresql-ha-pgpool.%s.svc.%s:%d" .Release.Name .Release.Namespace .Values.clusterDomain (int (index .Values "postgresql-ha" "service" "ports" "postgresql")) -}}
{{- end -}}
{{- end -}}

{{- define "postgresql.dns" -}}
{{- if (index .Values "postgresql").enabled -}}
{{- printf "%s-postgresql.%s.svc.%s:%d" .Release.Name .Release.Namespace .Values.clusterDomain (int .Values.postgresql.global.postgresql.service.ports.postgresql) -}}
{{- end -}}
{{- end -}}

{{- define "redis.dns" -}}
{{- if (index .Values "redis-cluster").enabled -}}
{{- printf "redis+cluster://:%s@%s-redis-cluster-headless.%s.svc.%s:%d/0?pool_size=100&idle_timeout=180s&" (index .Values "redis-cluster").global.redis.password .Release.Name .Release.Namespace .Values.clusterDomain (int (index .Values "redis-cluster").service.ports.redis) -}}
{{- end -}}
{{- end -}}

{{- define "redis.port" -}}
{{- if (index .Values "redis-cluster").enabled -}}
{{ (index .Values "redis-cluster").service.ports.redis | int }}
{{- end -}}
{{- end -}}

{{- define "redis.servicename" -}}
{{- if (index .Values "redis-cluster").enabled -}}
{{- printf "%s-redis-cluster-headless.%s.svc.%s" .Release.Name .Release.Namespace .Values.clusterDomain -}}
{{- end -}}
{{- end -}}

{{- define "gitea.default_domain" -}}
{{- printf "%s.%s.svc.%s" (include "gitea.fullname" .) .Release.Namespace .Values.clusterDomain -}}
{{- end -}}

{{- define "gitea.ldap_settings" -}}
{{- $idx := index . 0 }}
{{- $values := index . 1 }}

{{- if not (hasKey $values "bindDn") -}}
{{- $_ := set $values "bindDn" "" -}}
{{- end -}}

{{- if not (hasKey $values "bindPassword") -}}
{{- $_ := set $values "bindPassword" "" -}}
{{- end -}}

{{- $flags := list "notActive" "skipTlsVerify" "allowDeactivateAll" "synchronizeUsers" "attributesInBind" -}}
{{- range $key, $val := $values -}}
{{- if and (ne $key "enabled") (ne $key "existingSecret") -}}
{{- if eq $key "bindDn" -}}
{{- printf "--%s \"${GITEA_LDAP_BIND_DN_%d}\" " ($key | kebabcase) ($idx) -}}
{{- else if eq $key "bindPassword" -}}
{{- printf "--%s \"${GITEA_LDAP_PASSWORD_%d}\" " ($key | kebabcase) ($idx) -}}
{{- else if eq $key "port" -}}
{{- printf "--%s %d " $key ($val | int) -}}
{{- else if has $key $flags -}}
{{- printf "--%s " ($key | kebabcase) -}}
{{- else -}}
{{- printf "--%s %s " ($key | kebabcase) ($val | squote) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "gitea.oauth_settings" -}}
{{- $idx := index . 0 }}
{{- $values := index . 1 }}

{{- if not (hasKey $values "key") -}}
{{- $_ := set $values "key" (printf "${GITEA_OAUTH_KEY_%d}" $idx) -}}
{{- end -}}

{{- if not (hasKey $values "secret") -}}
{{- $_ := set $values "secret" (printf "${GITEA_OAUTH_SECRET_%d}" $idx) -}}
{{- end -}}

{{- range $key, $val := $values -}}
{{- if ne $key "existingSecret" -}}
{{- printf "--%s %s " ($key | kebabcase) ($val | quote) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "gitea.inline_configuration" -}}
  {{- include "gitea.inline_configuration.init" . -}}
  {{- include "gitea.inline_configuration.defaults" . -}}

  {{- $generals := list -}}
  {{- $inlines := dict -}}

  {{- range $key, $value := .Values.config  }}
    {{- if kindIs "map" $value }}
      {{- if gt (len $value) 0 }}
        {{- $section := default list (get $inlines $key) -}}
        {{- range $n_key, $n_value := $value }}
          {{- $section = append $section (printf "%s=%v" $n_key $n_value) -}}
        {{- end }}
        {{- $_ := set $inlines $key (join "\n" $section) -}}
      {{- end -}}
    {{- else }}
      {{- if or (eq $key "APP_NAME") (eq $key "RUN_USER") (eq $key "RUN_MODE") -}}
        {{- $generals = append $generals (printf "%s=%s" $key $value) -}}
      {{- else -}}
        {{- (printf "Key %s cannot be on top level of configuration" $key) | fail -}}
      {{- end -}}

    {{- end }}
  {{- end }}

  {{- $_ := set $inlines "_generals_" (join "\n" $generals) -}}
  {{- toYaml $inlines -}}
{{- end -}}

{{- define "gitea.inline_configuration.init" -}}
  {{- if not (hasKey .Values.config "cache") -}}
    {{- $_ := set .Values.config "cache" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.config "server") -}}
    {{- $_ := set .Values.config "server" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.config "metrics") -}}
    {{- $_ := set .Values.config "metrics" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.config "database") -}}
    {{- $_ := set .Values.config "database" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.config "security") -}}
    {{- $_ := set .Values.config "security" dict -}}
  {{- end -}}
  {{- if not .Values.config.repository -}}
    {{- $_ := set .Values.config "repository" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.config "oauth2") -}}
    {{- $_ := set .Values.config "oauth2" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.config "session") -}}
    {{- $_ := set .Values.config "session" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.config "queue") -}}
    {{- $_ := set .Values.config "queue" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.config "queue.issue_indexer") -}}
    {{- $_ := set .Values.config "queue.issue_indexer" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.config "indexer") -}}
    {{- $_ := set .Values.config "indexer" dict -}}
  {{- end -}}
{{- end -}}

{{- define "gitea.inline_configuration.defaults" -}}
  {{- include "gitea.inline_configuration.defaults.server" . -}}
  {{- include "gitea.inline_configuration.defaults.database" . -}}

  {{- if not .Values.config.repository.ROOT -}}
    {{- $_ := set .Values.config.repository "ROOT" "/data/git/gitea-repositories" -}}
  {{- end -}}
  {{- if not .Values.config.security.INSTALL_LOCK -}}
    {{- $_ := set .Values.config.security "INSTALL_LOCK" "true" -}}
  {{- end -}}
  {{- if not (hasKey .Values.config.metrics "ENABLED") -}}
    {{- $_ := set .Values.config.metrics "ENABLED" .Values.metrics.enabled -}}
  {{- end -}}
  {{- /* redis queue */ -}}
  {{- if (index .Values "redis-cluster").enabled -}}
    {{- $_ := set .Values.config.queue "TYPE" "redis" -}}
    {{- $_ := set .Values.config.queue "CONN_STR" (include "redis.dns" .) -}}
    {{- $_ := set .Values.config.session "PROVIDER" "redis" -}}
    {{- $_ := set .Values.config.session "PROVIDER_CONFIG" (include "redis.dns" .) -}}
    {{- $_ := set .Values.config.cache "ADAPTER" "redis" -}}
    {{- $_ := set .Values.config.cache "HOST" (include "redis.dns" .) -}}
  {{- else -}}
    {{- if not (get .Values.config.session "PROVIDER") -}}
      {{- $_ := set .Values.config.session "PROVIDER" "memory" -}}
    {{- end -}}
    {{- if not (get .Values.config.session "PROVIDER_CONFIG") -}}
      {{- $_ := set .Values.config.session "PROVIDER_CONFIG" "" -}}
    {{- end -}}
    {{- if not (get .Values.config.queue "TYPE") -}}
      {{- $_ := set .Values.config.queue "TYPE" "level" -}}
    {{- end -}}
    {{- if not (get .Values.config.queue "CONN_STR") -}}
      {{- $_ := set .Values.config.queue "CONN_STR" "" -}}
    {{- end -}}
    {{- if not (get .Values.config.cache "ADAPTER") -}}
      {{- $_ := set .Values.config.cache "ADAPTER" "memory" -}}
    {{- end -}}
    {{- if not (get .Values.config.cache "HOST") -}}
      {{- $_ := set .Values.config.cache "HOST" "" -}}
    {{- end -}}
  {{- end -}}
  {{- if not .Values.config.indexer.ISSUE_INDEXER_TYPE -}}
     {{- $_ := set .Values.config.indexer "ISSUE_INDEXER_TYPE" "db" -}}
  {{- end -}}
{{- end -}}

{{- define "gitea.inline_configuration.defaults.server" -}}
  {{- $rootless := true -}}
  {{- if not (hasKey .Values.config.server "HTTP_PORT") -}}
    {{- $_ := set .Values.config.server "HTTP_PORT" .Values.service.http.port -}}
  {{- end -}}
  {{- if not .Values.config.server.PROTOCOL -}}
    {{- $_ := set .Values.config.server "PROTOCOL" "http" -}}
  {{- end -}}
  {{- if not ( .Values.config.server.DOMAIN) -}}
    {{- $_ := set .Values.config.server "DOMAIN" (include "gitea.default_domain" .) -}}
  {{- end -}}
  {{- if not .Values.config.server.ROOT_URL -}}
    {{- $_ := set .Values.config.server "ROOT_URL" (printf "%s://%s" .Values.config.server.PROTOCOL .Values.config.server.DOMAIN) -}}
  {{- end -}}
  {{- if not .Values.config.server.SSH_DOMAIN -}}
    {{- $_ := set .Values.config.server "SSH_DOMAIN" .Values.config.server.DOMAIN -}}
  {{- end -}}
  {{- if not .Values.config.server.SSH_PORT -}}
    {{- $_ := set .Values.config.server "SSH_PORT" .Values.service.ssh.port -}}
  {{- end -}}
  {{- if not (hasKey .Values.config.server "SSH_LISTEN_PORT") -}}
    {{- if not $rootless -}}
      {{- $_ := set .Values.config.server "SSH_LISTEN_PORT" .Values.config.server.SSH_PORT -}}
    {{- else -}}
      {{- $_ := set .Values.config.server "SSH_LISTEN_PORT" "2222" -}}
    {{- end -}}
  {{- end -}}
  {{- if not (hasKey .Values.config.server "START_SSH_SERVER") -}}
    {{- if $rootless -}}
      {{- $_ := set .Values.config.server "START_SSH_SERVER" "true" -}}
    {{- end -}}
  {{- end -}}
  {{- if not (hasKey .Values.config.server "APP_DATA_PATH") -}}
    {{- $_ := set .Values.config.server "APP_DATA_PATH" "/data" -}}
  {{- end -}}
  {{- if not (hasKey .Values.config.server "ENABLE_PPROF") -}}
    {{- $_ := set .Values.config.server "ENABLE_PPROF" false -}}
  {{- end -}}
{{- end -}}

{{- define "gitea.inline_configuration.defaults.database" -}}
  {{- if (index .Values "postgresql-ha" "enabled") -}}
    {{- $_ := set .Values.config.database "DB_TYPE"   "postgres" -}}
    {{- if not ( .Values.config.database.HOST) -}}
      {{- $_ := set .Values.config.database "HOST"      (include "postgresql-ha.dns" .) -}}
    {{- end -}}
    {{- $_ := set .Values.config.database "NAME"      (index .Values "postgresql-ha" "global" "postgresql" "database") -}}
    {{- $_ := set .Values.config.database "USER"      (index .Values "postgresql-ha" "global" "postgresql" "username") -}}
    {{- $_ := set .Values.config.database "PASSWD"    (index .Values "postgresql-ha" "global" "postgresql" "password") -}}
  {{- end -}}
  {{- if (index .Values "postgresql" "enabled") -}}
    {{- $_ := set .Values.config.database "DB_TYPE"   "postgres" -}}
    {{- if not ( .Values.config.database.HOST) -}}
      {{- $_ := set .Values.config.database "HOST"      (include "postgresql.dns" .) -}}
    {{- end -}}
    {{- $_ := set .Values.config.database "NAME"      .Values.postgresql.global.postgresql.auth.database -}}
    {{- $_ := set .Values.config.database "USER"      .Values.postgresql.global.postgresql.auth.username -}}
    {{- $_ := set .Values.config.database "PASSWD"    .Values.postgresql.global.postgresql.auth.password -}}
  {{- end -}}
{{- end -}}

{{- define "gitea.init-additional-mounts" -}}
  {{- /* Honor the deprecated extraVolumeMounts variable when defined */ -}}
  {{- if gt (len .Values.extraInitVolumeMounts) 0 -}}
    {{- toYaml .Values.extraInitVolumeMounts -}}
  {{- else if gt (len .Values.extraVolumeMounts) 0 -}}
    {{- toYaml .Values.extraVolumeMounts -}}
  {{- end -}}
{{- end -}}

{{- define "gitea.container-additional-mounts" -}}
  {{- /* Honor the deprecated extraVolumeMounts variable when defined */ -}}
  {{- if gt (len .Values.extraContainerVolumeMounts) 0 -}}
    {{- toYaml .Values.extraContainerVolumeMounts -}}
  {{- else if gt (len .Values.extraVolumeMounts) 0 -}}
    {{- toYaml .Values.extraVolumeMounts -}}
  {{- end -}}
{{- end -}}

{{- define "gitea.gpg-key-secret-name" -}}
{{ default (printf "%s-gpg-key" (include "gitea.fullname" .)) .Values.signing.existingSecret }}
{{- end -}}

{{- define "gitea.serviceAccountName" -}}
{{ .Values.serviceAccount.name | default (include "gitea.fullname" .) }}
{{- end -}}

{{/*
     Data store specific helper functions
*/}}

{{/*
Gitea service name
*/}}
{{- define "datastore.gitea.fullname" -}}
{{- printf "%s" (include "gitea.fullname" .)  }}
{{- end -}}


{{/*
Gitea's root URL config
Note: we are using default gitea port: 3000
*/}}
{{- define "datastore.gitea.root-url" -}}
{{- if (.Values.external.rootUrl) -}}
{{- print .Values.external.rootUrl -}}
{{- else -}}
{{- printf "http://%s:%v" (include "datastore.gitea.domain" .) .Values.service.http.port }}
{{- end -}}
{{- end }}

{{/*
Gitea's root domain config
*/}}
{{- define "datastore.gitea.domain" -}}
{{- if (.Values.external.domain) -}}
{{- print .Values.external.domain  -}}
{{- else -}}
{{- printf "%s.%s.svc.cluster.local" (include "datastore.gitea.fullname" .) .Release.Namespace }}
{{- end -}}
{{- end }}


{{/*
PostgreSQL Secret Key
*/}}
{{- define "datastore.database.passwordKey" -}}
{{- if or .Values.postgresql.enabled (not .Values.externalDatabase.existingSecret) -}}
    {{- print "password" -}}
{{- else -}}
    {{- print .Values.externalDatabase.existingSecretPasswordKey -}}
{{- end -}}
{{- end -}}


{{/*
PostgreSQL Secret Name
*/}}
{{- define "datastore.database.secretName" -}}
{{- if .Values.postgresql.enabled -}}
    {{- if .Values.postgresql.auth.existingSecret -}}
    {{- print .Values.postgresql.auth.existingSecret -}}
    {{- else -}}
    {{- print (include "datastore.postgresql.fullname" .) -}}
    {{- end -}}
{{- else if .Values.externalDatabase.existingSecret -}}
    {{- print .Values.externalDatabase.existingSecret -}}
{{- end -}}
{{- end -}}


{{/*
ObjectStore Secret Name
*/}}
{{- define "datastore.objectStore.secretName" -}}
{{- if .Values.objectStore.existingSecret -}}
    {{- print .Values.objectStore.existingSecret -}}
{{- else -}}
    {{- printf "%s-%s" (include "gitea.fullname" .) "external-objstore" -}}
{{- end -}}
{{- end -}}


{{/*
ObjectStore Access Key
*/}}
{{- define "datastore.objectStore.accessKey" -}}
{{- if  .Values.objectStore.existingSecret -}}
    {{- print .Values.objectStore.existingSecretAccessKey -}}
{{- else -}}
    {{- print "accessKey" -}}
{{- end -}}
{{- end -}}


{{/*
ObjectStore Access Secret
*/}}
{{- define "datastore.objectStore.accessSecret" -}}
{{- if .Values.objectStore.existingSecret -}}
    {{- print .Values.objectStore.existingSecretAccessSecret -}}
{{- else -}}
    {{- print "accessSecret" -}}
{{- end -}}
{{- end -}}


{{/*
Lfs Jwt Secret Secret Name
*/}}
{{- define "datastore.lfsJwtSecret.secretName" -}}
{{- if .Values.jwtSecret.existingSecret -}}
    {{- print .Values.jwtSecret.existingSecret -}}
{{- else -}}
    {{- printf "%s-%s" (include "gitea.fullname" .) "-lfs-jwt" -}}
{{- end -}}
{{- end -}}


{{/*
Lfs Jwt Secret Secret Key
*/}}
{{- define "datastore.lfsJwtSecret.secretKey" -}}
{{- if  .Values.jwtSecret.existingSecret -}}
    {{- print .Values.jwtSecret.existingSecretKey -}}
{{- else -}}
    {{- print "jwtSecret" -}}
{{- end -}}
{{- end -}}


{{/*
Generates a random LFS_JWT_SECRET for gitea server
reference: https://github.com/go-gitea/gitea/issues/22727
*/}}
{{- define "datastore.lfsJwtSecret.random" -}}
{{- randAlphaNum 32 | b64enc | replace "=" "" | replace "/" "+" | replace "=" "" | replace "_" "-" -}}
{{- end }}



{{/*
PostgreSQL service name
*/}}
{{- define "datastore.postgresql.fullname" -}}
{{ template "postgresql.v1.primary.fullname" .Subcharts.postgresql }}
{{- end -}}


{{/*
PostgreSQL Hostname
*/}}
{{- define "datastore.database.host" -}}
{{- if .Values.postgresql.enabled -}}
    {{- print (include "datastore.postgresql.fullname" .) -}}
{{- else -}}
    {{- print .Values.externalDatabase.host -}}
{{- end -}}
{{- end -}}

{{/*
PostgreSQL Port
*/}}
{{- define "datastore.database.port" -}}
{{- if .Values.postgresql.enabled -}}
    {{- printf "%d" (.Values.postgresql.primary.service.ports.postgresql | int) -}}
{{- else -}}
    {{- printf "%d" (.Values.externalDatabase.port | int) -}}
{{- end -}}
{{- end -}}

{{/*
PostgreSQL User
*/}}
{{- define "datastore.database.user" -}}
{{- if .Values.postgresql.enabled -}}
    {{- print .Values.postgresql.auth.username -}}
{{- else -}}
    {{- print .Values.externalDatabase.user -}}
{{- end -}}
{{- end -}}

{{/*
PostgreSQL database name
*/}}
{{- define "datastore.database.name" -}}
{{- if .Values.postgresql.enabled -}}
    {{- print .Values.postgresql.auth.database -}}
{{- else -}}
    {{- print .Values.externalDatabase.database -}}
{{- end -}}
{{- end -}}


{{/*
Image pull secret data for NGC
*/}}
{{- define "datastore.nvcr.imagepull.secret.data" -}}
{{- $username := "$oauthtoken" -}}
{{- $password := .Values.demo.ngcApiKey -}}
{{- $registry := "nvcr.io" -}}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"auth\":\"%s\"}}}" $registry $username $password (printf "%s:%s" $username $password | b64enc) | b64enc }}
{{- end }}
