{{/*
Reuseable init container for running Alembic DB migrations for Evaluator.
*/}}
{{- define "nemo-evaluator.dbMigration" }}
- name: evaluator-db-migration
  {{- if and (.Values.dbMigration.image) (.Values.dbMigration.image.repository) (.Values.dbMigration.image.tag) }}
  image:  "{{ .Values.dbMigration.image.repository }}:{{ .Values.dbMigration.image.tag | default .Chart.AppVersion }}"
  {{ else }}
  image:  {{ include "nemo-common.mainimage" . | quote }}
  {{- end }}
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  env:
    - name: MODE
      value: standalone
    {{ include "nemo-common.postgresql.password" . | nindent 4 | trim }}
    - name: POSTGRES_URI
      {{ include "nemo-common.postgresql.uri" . | nindent 6 | trim }}
    {{- if .Values.dbMigration.extraEnvVars }}
    {{- range $k, $v := .Values.dbMigration.extraEnvVars }}
    - name: "{{ $k }}"
      value: "{{ $v }}"
    {{- end }}
    {{- end }}
    {{ include "nemo-common.env" . | nindent 4 | trim }}
  {{- if or (.Values.dbMigration.extraEnvVarsCM) (.Values.dbMigration.extraEnvVarsSecret) }}
    {{- if .Values.dbMigration.extraEnvVarsCM }}
    - configMapRef:
        name: {{ include "common.tplvalues.render" (dict "value" .Values.dbMigration.extraEnvVarsCM "context" $) }}
    {{- end }}
    {{- if .Values.dbMigration.extraEnvVarsSecret }}
    - secretRef:
        name: {{ include "common.tplvalues.render" (dict "value" .Values.dbMigration.extraEnvVarsSecret "context" $) }}
    {{- end }}
  {{- end }}
  command:
    - "/bin/sh"
    - "-c"
    - "/app/scripts/run-db-migration.sh"
  securityContext:
    runAsUser: 0
  resources:
    {{- toYaml .Values.dbMigration.resources | nindent 4 }}
{{- end }}
