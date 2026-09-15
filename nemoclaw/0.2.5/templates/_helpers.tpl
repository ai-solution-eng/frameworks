{{- define "nemoclaw.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- /*
  nemoclaw.fullname: the base name for all chart resources.
  Resolution order:
    1. .Values.fullnameOverride (if set)
    2. .Release.Name (fallback — makes side-by-side openclaw/hermes
       imports of the SAME chart non-colliding: each release gets its
       own <release>-gateway-token secret, <release>-openclaw-config,
       <release>-agent-state PVC, <release> deployment/service/VS)
  Using the release name (not the chart name) as the default avoids the
  Helm ownership-metadata conflict when two releases share a namespace.
*/ -}}
{{- define "nemoclaw.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "nemoclaw.serviceName" -}}
{{- include "nemoclaw.fullname" . }}
{{- end }}

{{- define "nemoclaw.releaseName" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "nemoclaw.labels" -}}
app.kubernetes.io/name: {{ include "nemoclaw.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: nemoclaw
hpe-ezua/created-by: ezua
{{- end }}

{{- define "nemoclaw.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nemoclaw.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "nemoclaw.image" -}}
{{- if .Values.image.digest -}}
{{ .Values.image.repository }}@{{ .Values.image.digest }}
{{- else -}}
{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- end -}}
{{- end }}

{{- /*
  isPlaceholder: true when a value is empty or still a "<...>" placeholder
  (i.e. not filled in by the deployer). Used to trigger cluster auto-detect.
*/ -}}
{{- define "nemoclaw.isPlaceholder" -}}
{{- $v := trim . -}}
{{- if or (not $v) (hasPrefix "<" $v) (hasSuffix ">" $v) -}}true{{- else -}}false{{- end -}}
{{- end }}

{{- /*
  litellmNamespace: namespace where the LiteLLM proxy runs (used to build the
  baseUrl). The user supplies the API key directly (litellm.apiKey) — the chart
  does NOT read it from a secret, so no keyRef is needed.
  Resolution order:
    1. explicit .Values.litellm.namespace (if not empty/placeholder)
    2. best-effort cluster auto-detect: the namespace that owns a
       "litellm-helm" Service / "litellm-helm-masterkey" Secret (lookup —
       populated only during a real install/upgrade)
    3. fallback: the release namespace
  Returns "" if nothing resolves.
*/ -}}
{{- define "nemoclaw.litellmNamespace" -}}
{{- $explicit := .Values.litellm.namespace -}}
{{- if and $explicit (eq (trim (include "nemoclaw.isPlaceholder" (printf "%s" $explicit))) "false") }}
{{- $explicit -}}
{{- else -}}
{{- $detected := "" -}}
{{- $svcs := lookup "v1" "Service" "" "litellm-helm" -}}
{{- if $svcs }}
{{- range $svc := $svcs.items }}
{{- if and (not $detected) $svc.metadata.namespace }}
{{- $detected = $svc.metadata.namespace }}
{{- end }}
{{- end }}
{{- end }}
{{- if not $detected }}
{{- $secrets := lookup "v1" "Secret" "" "litellm-helm-masterkey" -}}
{{- if $secrets }}
{{- range $sec := $secrets.items }}
{{- if and (not $detected) $sec.metadata.namespace }}
{{- $detected = $sec.metadata.namespace }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- if $detected }}
{{- $detected -}}
{{- else }}
{{- .Release.Namespace -}}
{{- end -}}
{{- end -}}
{{- end }}

{{- /*
  litellmBaseUrl: the user-specified LLM endpoint.
  Simple passthrough — no auto-detection, no fallback.
*/ -}}
{{- define "nemoclaw.litellmBaseUrl" -}}
{{- .Values.litellm.baseUrl }}
{{- end }}

{{- /*
  baseDomain: the PCAI base domain (e.g. <your-pcai-domain>).
  Resolution order:
    1. Extracted from .Values.ezua.virtualService.endpoint if it's a literal host
       (not a ${...} placeholder) — strip the first label to get the suffix
    2. cluster auto-detect: the most common host suffix across the Istio
       VirtualServices (each host is "<app>.<base>"); strip the first label and
       take the majority. Only populated during a real install/upgrade.
  Returns "" if nothing resolves.
*/ -}}
{{- define "nemoclaw.baseDomain" -}}
{{- $ep := include "nemoclaw.endpointHost" . }}
{{- if and $ep (not (contains "${" $ep)) }}
{{- /* literal host: derive baseDomain by stripping the first label */ -}}
{{- $labels := splitList "." $ep }}
{{- if gt (len $labels) 1 }}
{{- join "." (slice $labels 1 (len $labels)) }}
{{- end }}
{{- else }}
{{- $suffixCount := dict }}
{{- $vss := lookup "networking.istio.io/v1beta1" "VirtualService" "" "" -}}
{{- if $vss }}
{{- range $vs := $vss.items }}
{{- range $h := $vs.spec.hosts }}
{{- if and (contains "." $h) (not (hasSuffix "svc.cluster.local" $h)) }}
{{- $labels := splitList "." $h }}
{{- if gt (len $labels) 1 }}
{{- $suffix := join "." (slice $labels 1 (len $labels)) }}
{{- $cur := get $suffixCount $suffix | default 0 }}
{{- $suffixCount = set $suffixCount $suffix (add $cur 1) }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- $best := "" }}
{{- $bestCount := 0 }}
{{- range $suffix, $count := $suffixCount }}
{{- if gt $count $bestCount }}
{{- $best = $suffix }}
{{- $bestCount = $count }}
{{- end }}
{{- end }}
{{- if $best }}
{{- $best -}}
{{- end -}}
{{- end -}}
{{- end }}

{{- /*
  storageClass: the PVC storage class.
  Resolution order:
    1. explicit .Values.persistence.storageClassName (if not a placeholder)
    2. cluster auto-detect: the StorageClass flagged
       "storageclass.kubernetes.io/is-default-class=true"
    3. fallback "" (use the cluster default — safe when the class is the
       platform default)
*/ -}}
{{- define "nemoclaw.storageClass" -}}
{{- $explicit := .Values.persistence.storageClassName -}}
{{- if and $explicit (eq (trim (include "nemoclaw.isPlaceholder" (printf "%s" $explicit))) "false") }}
{{- $explicit -}}
{{- else -}}
{{- $detected := "" -}}
{{- $scs := lookup "storage.k8s.io/v1" "StorageClass" "" "" -}}
{{- if $scs }}
{{- range $sc := $scs.items }}
{{- if and (not $detected) (eq (get $sc.metadata.annotations "storageclass.kubernetes.io/is-default-class") "true") }}
{{- $detected = $sc.metadata.name }}
{{- end }}
{{- end }}
{{- end }}
{{- if $detected }}
{{- $detected -}}
{{- end -}}
{{- end -}}
{{- end }}

{{- define "nemoclaw.endpointHost" -}}
{{- $h := .Values.ezua.virtualService.endpoint | default "" | trim -}}
{{- if hasPrefix "https://" $h -}}
{{- $h = trimPrefix "https://" $h -}}
{{- else if hasPrefix "http://" $h -}}
{{- $h = trimPrefix "http://" $h -}}
{{- end -}}
{{- $h | trim -}}
{{- end }}

{{- define "nemoclaw.domain" -}}
{{- $h := include "nemoclaw.endpointHost" . }}
{{- if $h -}}
{{- if contains "${" $h -}}
{{- /*
   Platform placeholder (e.g. ${RELEASE_NAME}.${DOMAIN_NAME}).
   Pass through verbatim — the PCAI portal substitutes both the endpoint
   (for the Open button) and the VS host at import time.
*/ -}}
{{ $h }}
{{- else -}}
{{- /* literal host: use as-is (scheme already stripped) */ -}}
{{ $h }}
{{- end -}}
{{- else -}}
{{- /* no endpoint set: fall back to release name + base domain */ -}}
{{- printf "%s.%s" .Release.Name (include "nemoclaw.baseDomain" .) }}
{{- end -}}
{{- end }}

{{- define "nemoclaw.dashboardUrl" -}}
https://{{ include "nemoclaw.domain" . }}
{{- end }}

{{- define "hermes.image" -}}
{{- if .Values.hermes.image.digest -}}
{{ .Values.hermes.image.repository }}@{{ .Values.hermes.image.digest }}
{{- else -}}
{{ .Values.hermes.image.repository }}:{{ .Values.hermes.image.tag }}
{{- end -}}
{{- end }}
