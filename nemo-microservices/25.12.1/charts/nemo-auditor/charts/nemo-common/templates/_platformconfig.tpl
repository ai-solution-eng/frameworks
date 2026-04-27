{{/*
Platform ConfigMap name.
Use globals if they are there, but define sensibly.
*/}}
{{- define "nemo-common.platform-configmap-name" -}}
{{- if and .Values.global .Values.global.platformConfigmapName -}}
{{ .Values.global.platformConfigmapName }}
{{- else -}}
{{ .Values.platformConfigmapName }}
{{- end -}}
{{- end -}}
