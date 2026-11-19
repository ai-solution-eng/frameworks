{{- define "argilla.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "argilla.fullname" -}}
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

{{- define "argilla.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels. Call with (dict "ctx" . "component" "server")
*/}}
{{- define "argilla.labels" -}}
helm.sh/chart: {{ include "argilla.chart" .ctx }}
{{ include "argilla.selectorLabels" . }}
app.kubernetes.io/version: {{ .ctx.Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .ctx.Release.Service }}
{{ include "hpe-ezua.componentLabels" . }}
{{- end }}

{{/*
Selector labels (immutable). Call with (dict "ctx" . "component" "server")
*/}}
{{- define "argilla.selectorLabels" -}}
app.kubernetes.io/name: {{ include "argilla.name" .ctx }}
app.kubernetes.io/instance: {{ .ctx.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Pod labels: selector labels + hpe-ezua labels (needed on pods for Kyverno,
GPU metering and EzAppConfig health checks).
*/}}
{{- define "argilla.podLabels" -}}
{{ include "argilla.selectorLabels" . }}
{{ include "hpe-ezua.componentLabels" . }}
{{- end }}

{{- define "argilla.secretName" -}}
{{- if .Values.argilla.auth.existingSecret }}
{{- .Values.argilla.auth.existingSecret }}
{{- else }}
{{- include "argilla.fullname" . }}
{{- end }}
{{- end }}

{{- define "argilla.postgresql.fullname" -}}
{{- printf "%s-postgresql" (include "argilla.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "argilla.elasticsearch.fullname" -}}
{{- printf "%s-elasticsearch" (include "argilla.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "argilla.redis.fullname" -}}
{{- printf "%s-redis" (include "argilla.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "argilla.elasticsearchUrl" -}}
{{- if .Values.elasticsearch.enabled }}
{{- printf "http://%s:9200" (include "argilla.elasticsearch.fullname" .) }}
{{- else }}
{{- .Values.externalElasticsearch.url }}
{{- end }}
{{- end }}

{{- define "argilla.redisUrl" -}}
{{- if .Values.redis.enabled }}
{{- printf "redis://%s:6379/0" (include "argilla.redis.fullname" .) }}
{{- else }}
{{- .Values.externalRedis.url }}
{{- end }}
{{- end }}

{{/*
Return a value from an existing secret (so generated passwords survive upgrades),
otherwise the provided value, otherwise a random string.
Call with (dict "ctx" . "secret" <name> "key" <key> "value" <value> "length" <n>)
*/}}
{{- define "argilla.secretValue" -}}
{{- $existing := lookup "v1" "Secret" .ctx.Release.Namespace .secret }}
{{- if .value }}
{{- .value }}
{{- else if and $existing (index $existing.data .key) }}
{{- index $existing.data .key | b64dec }}
{{- else }}
{{- randAlphaNum (int .length) }}
{{- end }}
{{- end }}

{{/*
Environment shared by the server and the worker.
*/}}
{{- define "argilla.commonEnv" -}}
- name: ARGILLA_HOME_PATH
  value: {{ .Values.argilla.persistence.mountPath | quote }}
- name: ARGILLA_DATABASE_URL
  valueFrom:
    secretKeyRef:
      {{- if .Values.postgresql.enabled }}
      name: {{ include "argilla.fullname" . }}
      key: database-url
      {{- else if .Values.externalDatabase.existingSecret }}
      name: {{ .Values.externalDatabase.existingSecret }}
      key: {{ .Values.externalDatabase.existingSecretKey }}
      {{- else }}
      name: {{ include "argilla.fullname" . }}
      key: database-url
      {{- end }}
- name: ARGILLA_ELASTICSEARCH
  value: {{ include "argilla.elasticsearchUrl" . | quote }}
- name: ARGILLA_ELASTICSEARCH_SSL_VERIFY
  value: {{ ternary "true" (.Values.externalElasticsearch.sslVerify | toString) .Values.elasticsearch.enabled | quote }}
- name: ARGILLA_SEARCH_ENGINE
  value: {{ ternary "elasticsearch" .Values.externalElasticsearch.searchEngine .Values.elasticsearch.enabled | quote }}
- name: ARGILLA_REDIS_URL
  value: {{ include "argilla.redisUrl" . | quote }}
- name: ARGILLA_REDIS_USE_CLUSTER
  value: {{ ternary "false" (.Values.externalRedis.cluster | toString) .Values.redis.enabled | quote }}
- name: ARGILLA_AUTH_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "argilla.secretName" . }}
      key: auth-secret-key
{{- if .Values.argilla.disableTelemetry }}
- name: HF_HUB_DISABLE_TELEMETRY
  value: "1"
{{- end }}
{{- end }}

{{/*
Shell snippet: wait until a TCP host:port answers. Uses python (present in the image),
and runs inside the main container so it works with Istio sidecars.
*/}}
{{- define "argilla.waitFor" -}}
python - <<'PY'
import socket, sys, time, urllib.parse, os
targets = []
for var, default_port in (("ARGILLA_DATABASE_URL", 5432), ("ARGILLA_ELASTICSEARCH", 9200), ("ARGILLA_REDIS_URL", 6379)):
    u = urllib.parse.urlparse(os.environ.get(var, ""))
    if u.hostname and u.scheme not in ("sqlite", "sqlite+aiosqlite"):
        targets.append((u.hostname, u.port or default_port))
for host, port in targets:
    for i in range(120):
        try:
            socket.create_connection((host, port), timeout=3).close()
            print(f"{host}:{port} is reachable", flush=True)
            break
        except OSError:
            print(f"waiting for {host}:{port} ...", flush=True)
            time.sleep(5)
    else:
        sys.exit(f"timed out waiting for {host}:{port}")
PY
{{- end }}

{{/*
Keycloak CA: inline pem, or a read-only lookup of the platform root CA.
Returns the PEM text or "".
*/}}
{{- define "argilla.caPem" -}}
{{- $ca := .Values.ezua.sso.caCert -}}
{{- if $ca.pem -}}
{{- $ca.pem -}}
{{- else if $ca.copyFrom.enabled -}}
{{- $src := lookup "v1" "Secret" $ca.copyFrom.namespace $ca.copyFrom.name -}}
{{- if and $src $src.data (index $src.data $ca.copyFrom.key) -}}
{{- index $src.data $ca.copyFrom.key | b64dec -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Name of the Secret holding the Keycloak CA (key: .Values.ezua.sso.caCert.key, or ca.crt for
the chart-managed one), or "" when no CA is configured.
*/}}
{{- define "argilla.caSecretName" -}}
{{- if .Values.ezua.sso.enabled -}}
{{- if .Values.ezua.sso.caCert.secretName -}}
{{- .Values.ezua.sso.caCert.secretName -}}
{{- else if include "argilla.caPem" . -}}
{{- printf "%s-ca" (include "argilla.fullname" .) -}}
{{- end -}}
{{- end -}}
{{- end }}

{{- define "argilla.caSecretKey" -}}
{{- if .Values.ezua.sso.caCert.secretName -}}
{{- .Values.ezua.sso.caCert.key -}}
{{- else -}}
ca.crt
{{- end -}}
{{- end }}
