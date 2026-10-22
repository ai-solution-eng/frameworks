{{/*
HPE EZUA labels - required for Resource Management monitoring and
Pod Health monitoring in the EZUA "Tools & Frameworks" UI.
*/}}
{{- define "hpe-ezua.labels" -}}
hpe-ezua/app: {{ .Release.Name }}
hpe-ezua/type: vendor-service
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "librechat.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "librechat.fullname" -}}
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
Air-gap registry prefix.
Returns "<registry>/" when .Values.global.imageRegistry is set, else "".
Prepend to every image reference so an air-gapped mirror (e.g. Harbor
proxy-cache that preserves the upstream path) can be selected with a single
value. Leave global.imageRegistry empty to pull upstream images directly.
Usage: image: "{{ include "librechat.registry" . }}{{ .Values.x.image }}"
*/}}
{{- define "librechat.registry" -}}
{{- $reg := "" -}}
{{- if .Values.global -}}
{{- $reg = .Values.global.imageRegistry | default "" -}}
{{- end -}}
{{- if $reg -}}
{{- printf "%s/" (trimSuffix "/" $reg) -}}
{{- end -}}
{{- end }}

{{/*
Common labels
*/}}
{{- define "librechat.labels" -}}
helm.sh/chart: {{ include "librechat.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "librechat.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "hpe-ezua.labels" . }}
{{- end }}

{{/*
Selector labels (include hpe-ezua labels so pod templates are matched too)
*/}}
{{- define "librechat.selectorLabels" -}}
app.kubernetes.io/name: {{ include "librechat.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{ include "hpe-ezua.labels" . }}
{{- end }}
