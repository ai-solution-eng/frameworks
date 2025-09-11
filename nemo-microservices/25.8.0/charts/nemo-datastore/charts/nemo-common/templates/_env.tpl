{{/*
nemo-common.env generates an env var array out of a dict or array of supported values
*/}}
{{- define "nemo-common.env" -}}
{{- if and .Values.env (kindIs "slice" .Values.env) -}}
{{- toYaml .Values.env -}}
{{- else if and .Values.env (kindIs "map" .Values.env) -}}
{{- range $k, $v := .Values.env }}
- name: {{ $k }}
  {{- if kindIs "map" $v }}
  valueFrom:
    {{ toYaml $v.valueFrom | nindent 4 | trim }}
  {{- else }}
  value: {{ $v | quote }}
  {{- end }}
{{- end }}
{{- else if .Values.envVars }}
{{- range $k, $v := .Values.envVars }}
- name: {{ $k }}
  value: {{ $v | quote }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
nemo-common.postgresql.uri provides a template for constructing a postgresql database
connection string as an environment variable value
*/}}
{{- define "nemo-common.postgresql.uri" -}}
{{- if and .Values.externalDatabase.uriSecret .Values.externalDatabase.uriSecret.name .Values.externalDatabase.uriSecret.key }}
valueFrom:
  secretKeyRef:
    name: {{ .Values.externalDatabase.uriSecret.name }}
    key: {{ .Values.externalDatabase.uriSecret.key }}
{{- else }}
value: {{ printf "postgresql://%s:$(POSTGRES_DB_PASSWORD)@%s:%s/%s" (include "nemo-common.postgresql.user" .) (include "nemo-common.postgresql.host" .) (include "nemo-common.postgresql.port" .) (include "nemo-common.postgresql.name" .) | quote }}
{{- end }}
{{- end -}}

{{/*
PostgreSQL Hostname
*/}}
{{- define "nemo-common.postgresql.host" -}}
{{- if .Values.postgresql.enabled -}}
{{ template "postgresql.v1.primary.fullname" .Subcharts.postgresql }}
{{- else -}}
{{ .Values.externalDatabase.host }}
{{- end -}}
{{- end -}}

{{/*
nemo-common.database.port chooses between externalDatabase and the bitnami postgresql port values
*/}}
{{- define "nemo-common.postgresql.port" -}}
{{- if .Values.postgresql.enabled -}}
{{- printf "%d" (.Values.postgresql.primary.service.ports.postgresql | int) -}}
{{- else -}}
{{- printf "%d" (.Values.externalDatabase.port | int) -}}
{{- end -}}
{{- end -}}

{{/*
nemo-common.database.user chooses between externalDatabase and the bitnami postgresql user values
*/}}
{{- define "nemo-common.postgresql.user" -}}
{{- if .Values.postgresql.enabled -}}
{{- print .Values.postgresql.auth.username -}}
{{- else -}}
{{- print .Values.externalDatabase.user -}}
{{- end -}}
{{- end -}}

{{/*
nemo-common.database.name chooses between externalDatabase and the bitnami postgresql db name values
*/}}
{{- define "nemo-common.postgresql.name" -}}
{{- if .Values.postgresql.enabled -}}
{{- print .Values.postgresql.auth.database -}}
{{- else -}}
{{- print .Values.externalDatabase.database -}}
{{- end -}}
{{- end -}}

{{/*
nemo-common.database.secret-name chooses between externalDatabase and the bitnami postgresql existing secret values
*/}}
{{- define "nemo-common.postgresql.secret-name" -}}
{{- if .Values.postgresql.enabled -}}
{{- if .Values.postgresql.auth.existingSecret -}}
{{- print .Values.postgresql.auth.existingSecret -}}
{{- else -}}
{{- template "postgresql.v1.primary.fullname" .Subcharts.postgresql -}}
{{- end -}}
{{- else if .Values.externalDatabase.existingSecret -}}
{{- print .Values.externalDatabase.existingSecret -}}
{{- end -}}
{{- end -}}

{{/*
nemo-common.database.password-key chooses between externalDatabase and the bitnami postgresql existing secret key values
*/}}
{{- define "nemo-common.postgresql.password-key" -}}
{{- if or .Values.postgresql.enabled (not .Values.externalDatabase.existingSecret) -}}
{{- print "password" -}}
{{- else -}}
{{- print .Values.externalDatabase.existingSecretPasswordKey -}}
{{- end -}}
{{- end -}}

{{/*
nemo-common.database.password generates a POSTGRES_DB_PASSWORD environment value if a full URI isn't used
*/}}
{{- define "nemo-common.postgresql.password" -}}
{{- if not (and .Values.externalDatabase.uriSecret .Values.externalDatabase.uriSecret.name .Values.externalDatabase.uriSecret.key) }}
- name: POSTGRES_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "nemo-common.postgresql.secret-name" .}}
      key: {{ include "nemo-common.postgresql.password-key" .}}
{{- end }}
{{- end -}}
