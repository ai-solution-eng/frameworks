{{/*
Image Definition Parsing
Favor not using a separate registry because it is confusing, but support it.
*/}}
{{- define "nemo-common.mainimage" -}}
{{- if .Values.image.registry -}}
{{ .Values.image.registry }}/{{ .Values.image.repository }}:{{ default .Chart.AppVersion .Values.image.tag }}
{{- else -}}
{{ .Values.image.repository }}:{{ default .Chart.AppVersion .Values.image.tag }}
{{- end }}
{{- end }}

{{/*
Image Pull Secrets
Use globals if they are there, but define sensibly.
*/}}
{{- define "nemo-common.imagepullsecrets" -}}
{{- if and .Values.global .Values.global.imagePullSecrets }}
{{- range .Values.global.imagePullSecrets }}
- {{ . | toYaml }}
{{- end }}
{{- else }}
{{- range .Values.imagePullSecrets }}
- {{ . | toYaml }}
{{- end }}
{{- end }}
{{- end }}
