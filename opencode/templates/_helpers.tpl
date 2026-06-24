{{- define "opencode-web.escapeDomain" -}}
{{- . | replace "." "\\." -}}
{{- end -}}
