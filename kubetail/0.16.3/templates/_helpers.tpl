{{/*
Expand the name of the chart.
*/}}
{{- define "kubetail.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kubetail.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "kubetail.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Print the namespace
*/}}
{{- define "kubetail.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride }}
{{- end }}

{{/**************** Shared helpers ****************/}}

{{/*
Print key/value quoted pairs
*/}}
{{- define "kubetail.printDict" -}}
{{- if . -}}
{{- range $key, $value := . }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Add global labels to input dict
*/}}
{{- define "kubetail.addGlobalLabels" -}}
{{- $ctx := index . 0 -}}
{{- $inputDict := index . 1 -}}
{{- $_ := set $inputDict "helm.sh/chart" (include "kubetail.chart" $ctx) -}}
{{- $_ := set $inputDict "app.kubernetes.io/name" (include "kubetail.name" $ctx) -}}
{{- $_ := set $inputDict "app.kubernetes.io/version" $ctx.Chart.AppVersion -}}
{{- $_ := set $inputDict "app.kubernetes.io/instance" $ctx.Release.Name -}}
{{- $_ := set $inputDict "app.kubernetes.io/managed-by" $ctx.Release.Service -}}
{{- range $k, $v := $ctx.Values.kubetail.global.labels -}}
{{-   $_ := set $inputDict $k $v -}}
{{- end -}}
{{- end -}}

{{/*
Print annotations
*/}}
{{- define "kubetail.annotations" -}}
{{- $ctx := index . 0 -}}
{{- $annotationSet := index . 1 -}}
{{- $annotations := (merge $annotationSet $ctx.Values.kubetail.global.annotations) -}}
{{- include "kubetail.printDict" $annotations -}}
{{- end -}}

{{/*
Convert YAML keys to kebab-case
*/}}
{{- define "kubetail.toKebabYaml" -}}
{{- $result := dict -}}
{{- range $key, $value := . -}}
  {{- $newKey := $key | kebabcase -}}
  {{- if kindIs "map" $value -}}
    {{- $newValue := include "kubetail.toKebabYaml" $value | fromYaml -}}
    {{- $_ := set $result $newKey $newValue -}}
  {{- else if kindIs "slice" $value -}}
    {{- $newValue := list -}}
    {{- range $item := $value -}}
      {{- if kindIs "map" $item -}}
        {{- $convertedItem := include "kubetail.toKebabYaml" $item | fromYaml -}}
        {{- $newValue = append $newValue $convertedItem -}}
      {{- else -}}
        {{- $newValue = append $newValue $item -}}
      {{- end -}}
    {{- end -}}
    {{- $_ := set $result $newKey $newValue -}}
  {{- else -}}
    {{- $_ := set $result $newKey $value -}}
  {{- end -}}
{{- end -}}
{{- $result | toYaml -}}
{{- end -}}

{{/**************** Dashboard helpers ****************/}}

{{/*
Dashboard labels (including shared app labels)
*/}}
{{- define "kubetail.dashboard.labels" -}}
{{- $ctx := index . 0 -}}
{{- $labelSets := slice . 1 -}}
{{- $outputDict := dict -}}
{{- include "kubetail.addGlobalLabels" (list $ctx $outputDict) -}}
{{- $_ := set $outputDict "app.kubernetes.io/component" "dashboard" -}}
{{- range $labelSet := $labelSets -}}
{{- $outputDict = merge $labelSet $outputDict -}}
{{- end -}}
{{- include "kubetail.printDict" $outputDict -}}
{{- end -}}

{{/*
Dashboard selector labels
*/}}
{{- define "kubetail.dashboard.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubetail.name" $ | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/component: "dashboard"
{{- end }}

{{/*
Dashboard config
*/}}
{{- define "kubetail.dashboard.config" -}}
{{- with .Values.kubetail.allowedNamespaces }}
allowed-namespaces: 
{{- toYaml . | nindent 0 }}
{{- end }}
dashboard:
  addr: :{{ .Values.kubetail.dashboard.runtimeConfig.ports.http }}
  auth-mode: {{ .Values.kubetail.dashboard.authMode }}
  {{- if .Values.kubetail.clusterAPI.enabled }}
  cluster-api-endpoint: "{{ if .Values.kubetail.clusterAPI.runtimeConfig.tls.enabled }}https{{ else }}http{{ end }}://{{ include "kubetail.clusterAPI.serviceName" $ }}:{{ .Values.kubetail.clusterAPI.runtimeConfig.ports.http }}"
  {{- end }}
  environment: cluster
  ui:
    cluster-api-enabled: {{ .Values.kubetail.clusterAPI.enabled }}
  {{- $cfg := omit .Values.kubetail.dashboard.runtimeConfig "ports" "http" }}
  {{- $_ := set $cfg.session "secret" "${KUBETAIL_DASHBOARD_SESSION_SECRET}" }}
  {{- include "kubetail.toKebabYaml" $cfg | nindent 2 }}
{{- end }}

{{/*
Dashboard image
*/}}
{{- define "kubetail.dashboard.image" -}}
{{- $img := .Values.kubetail.dashboard.image -}}
{{- $registry := $img.registry | default "" -}}
{{- $repository := $img.repository | default "" -}}
{{- $ref := ternary (printf ":%s" ($img.tag | default .Chart.AppVersion | toString)) (printf "@%s" $img.digest) (empty $img.digest) -}}
{{- if and $registry $repository -}}
  {{- printf "%s/%s%s" $registry $repository $ref -}}
{{- else -}}
  {{- printf "%s%s%s" $registry $repository $ref -}}
{{- end -}}
{{- end }}

{{/*
Dashboard ClusterRole name
*/}}
{{- define "kubetail.dashboard.clusterRoleName" -}}
{{ if .Values.kubetail.dashboard.rbac.name }}{{ .Values.kubetail.dashboard.rbac.name }}{{ else }}{{ include "kubetail.fullname" $ }}-dashboard{{ end }}
{{- end }}

{{/*
Dashboard ClusterRoleBinding name
*/}}
{{- define "kubetail.dashboard.clusterRoleBindingName" -}}
{{ if .Values.kubetail.dashboard.rbac.name }}{{ .Values.kubetail.dashboard.rbac.name }}{{ else }}{{ include "kubetail.fullname" $ }}-dashboard{{ end }}
{{- end }}

{{/*
Dashboard ConfigMap name
*/}}
{{- define "kubetail.dashboard.configMapName" -}}
{{ default (include "kubetail.fullname" $) .Values.kubetail.dashboard.configMap.name }}-dashboard
{{- end }}

{{/*
Dashboard Deployment name
*/}}
{{- define "kubetail.dashboard.deploymentName" -}}
{{ if .Values.kubetail.dashboard.deployment.name }}{{ .Values.kubetail.dashboard.deployment.name }}{{ else }}{{ include "kubetail.fullname" $ }}-dashboard{{ end }}
{{- end }}

{{/*
Dashboard ingress name
*/}}
{{- define "kubetail.dashboard.ingressName" -}}
{{ default (include "kubetail.fullname" $) .Values.kubetail.dashboard.ingress.name }}-dashboard
{{- end }}

{{/*
Dashboard Role name
*/}}
{{- define "kubetail.dashboard.roleName" -}}
{{ if .Values.kubetail.dashboard.rbac.name }}{{ .Values.kubetail.dashboard.rbac.name }}{{ else }}{{ include "kubetail.fullname" $ }}-dashboard{{ end }}
{{- end }}

{{/*
Dashboard RoleBinding name
*/}}
{{- define "kubetail.dashboard.roleBindingName" -}}
{{ if .Values.kubetail.dashboard.rbac.name }}{{ .Values.kubetail.dashboard.rbac.name }}{{ else }}{{ include "kubetail.fullname" $ }}-dashboard{{ end }}
{{- end }}

{{/*
Dashboard Secret name
*/}}
{{- define "kubetail.dashboard.secretName" -}}
{{ if .Values.kubetail.dashboard.secret.name }}{{ .Values.kubetail.dashboard.secret.name }}{{ else }}{{ include "kubetail.fullname" $ }}-dashboard{{ end }}
{{- end }}

{{/*
Dashboard Secret data
*/}}
{{- define "kubetail.dashboard.secretData" -}}
{{- $currentValsRef := dict "data" dict -}}
{{- $currentResource := (lookup "v1" "Secret" (include "kubetail.namespace" $) (include "kubetail.dashboard.secretName" $)) -}}
{{- if $currentResource -}}
{{- $_ := set $currentValsRef "data" (index $currentResource "data") -}}
{{- end -}}
KUBETAIL_DASHBOARD_SESSION_SECRET: {{ .Values.kubetail.secrets.KUBETAIL_DASHBOARD_SESSION_SECRET | default $currentValsRef.data.KUBETAIL_DASHBOARD_SESSION_SECRET | default ((randAlphaNum 32) | b64enc | quote) }}
{{- end }}

{{/*
Dashboard Service name
*/}}
{{- define "kubetail.dashboard.serviceName" -}}
{{ if .Values.kubetail.dashboard.service.name }}{{ .Values.kubetail.dashboard.service.name }}{{ else }}{{ include "kubetail.fullname" $ }}-dashboard{{ end }}
{{- end }}

{{/*
Dashboard ServiceAccount name
*/}}
{{- define "kubetail.dashboard.serviceAccountName" -}}
{{ if .Values.kubetail.dashboard.serviceAccount.name }}{{ .Values.kubetail.dashboard.serviceAccount.name }}{{ else }}{{ include "kubetail.fullname" $ }}-dashboard{{ end }}
{{- end }}

{{/**************** Cluster API helpers ****************/}}

{{/*
Cluster API labels (including shared app labels)
*/}}
{{- define "kubetail.clusterAPI.labels" -}}
{{- $ctx := index . 0 -}}
{{- $labelSets := slice . 1 -}}
{{- $outputDict := dict -}}
{{- include "kubetail.addGlobalLabels" (list $ctx $outputDict) -}}
{{- $_ := set $outputDict "app.kubernetes.io/component" "cluster-api" -}}
{{- range $labelSet := $labelSets -}}
{{- $outputDict = merge $labelSet $outputDict -}}
{{- end -}}
{{- include "kubetail.printDict" $outputDict -}}
{{- end -}}

{{/*
Cluster API selector labels
*/}}
{{- define "kubetail.clusterAPI.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubetail.name" $ | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/component: "cluster-api"
{{- end }}

{{/*
Cluster API config
*/}}
{{- define "kubetail.clusterAPI.config" -}}
{{- $dispatchUrlPort := int .Values.kubetail.clusterAgent.runtimeConfig.ports.grpc }}
{{- $dispatchUrl := printf "kubernetes://%s:%d" (include "kubetail.clusterAgent.serviceName" $) $dispatchUrlPort }}
{{- with .Values.kubetail.allowedNamespaces }}
allowed-namespaces: 
{{- toYaml . | nindent 0 }}
{{- end }}
cluster-api:
  addr: :{{ .Values.kubetail.clusterAPI.runtimeConfig.ports.http }}
  {{- $cfg := omit .Values.kubetail.clusterAPI.runtimeConfig "ports" "http"}}
  {{- $_ := set $cfg "clusterAgent" ( dict "dispatchUrl" $dispatchUrl )}}
  {{- include "kubetail.toKebabYaml" $cfg | nindent 2 }}
{{- end }}

{{/*
Cluster API image
*/}}
{{- define "kubetail.clusterAPI.image" -}}
{{- $img := .Values.kubetail.clusterAPI.image -}}
{{- $registry := $img.registry | default "" -}}
{{- $repository := $img.repository | default "" -}}
{{- $ref := ternary (printf ":%s" ($img.tag | default .Chart.AppVersion | toString)) (printf "@%s" $img.digest) (empty $img.digest) -}}
{{- if and $registry $repository -}}
  {{- printf "%s/%s%s" $registry $repository $ref -}}
{{- else -}}
  {{- printf "%s%s%s" $registry $repository $ref -}}
{{- end -}}
{{- end }}

{{/*
Cluster API ConfigMap name
*/}}
{{- define "kubetail.clusterAPI.configMapName" -}}
{{ default (include "kubetail.fullname" $) .Values.kubetail.clusterAPI.configMap.name }}-cluster-api
{{- end }}

{{/*
Cluster API Deployment name
*/}}
{{- define "kubetail.clusterAPI.deploymentName" -}}
{{ if .Values.kubetail.clusterAPI.deployment.name }}{{ .Values.kubetail.clusterAPI.deployment.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cluster-api{{ end }}
{{- end }}

{{/*
Cluster API ClusterRole name
*/}}
{{- define "kubetail.clusterAPI.clusterRoleName" -}}
{{ if .Values.kubetail.clusterAPI.rbac.name }}{{ .Values.kubetail.clusterAPI.rbac.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cluster-api{{ end }}
{{- end }}

{{/*
Cluster API ClusterRoleBinding name
*/}}
{{- define "kubetail.clusterAPI.clusterRoleBindingName" -}}
{{ if .Values.kubetail.clusterAPI.rbac.name }}{{ .Values.kubetail.clusterAPI.rbac.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cluster-api{{ end }}
{{- end }}

{{/*
Cluster API Role name
*/}}
{{- define "kubetail.clusterAPI.roleName" -}}
{{ if .Values.kubetail.clusterAPI.rbac.name }}{{ .Values.kubetail.clusterAPI.rbac.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cluster-api{{ end }}
{{- end }}

{{/*
Cluster API RoleBinding name
*/}}
{{- define "kubetail.clusterAPI.roleBindingName" -}}
{{ if .Values.kubetail.clusterAPI.rbac.name }}{{ .Values.kubetail.clusterAPI.rbac.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cluster-api{{ end }}
{{- end }}

{{/*
Cluster API Secret name
*/}}
{{- define "kubetail.clusterAPI.secretName" -}}
{{ if .Values.kubetail.clusterAPI.secret.name }}{{ .Values.kubetail.clusterAPI.secret.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cluster-api{{ end }}
{{- end }}

{{/*
Cluster API Secret data
*/}}
{{- define "kubetail.clusterAPI.secretData" -}}
{{- $currentValsRef := dict "data" dict -}}
{{- $currentResource := (lookup "v1" "Secret" (include "kubetail.namespace" $) (include "kubetail.clusterAPI.secretName" $)) -}}
{{- if $currentResource -}}
{{- $_ := set $currentValsRef "data" (index $currentResource "data") -}}
{{- end -}}
{{- end }}

{{/*
Cluster API Service name
*/}}
{{- define "kubetail.clusterAPI.serviceName" -}}
{{ if .Values.kubetail.clusterAPI.service.name }}{{ .Values.kubetail.clusterAPI.service.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cluster-api{{ end }}
{{- end }}

{{/*
Cluster API ServiceAccount name
*/}}
{{- define "kubetail.clusterAPI.serviceAccountName" -}}
{{ if .Values.kubetail.clusterAPI.serviceAccount.name }}{{ .Values.kubetail.clusterAPI.serviceAccount.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cluster-api{{ end }}
{{- end }}

{{/**************** Cluster Agent helpers ****************/}}

{{/*
Cluster Agent labels (including shared app labels)
*/}}
{{- define "kubetail.clusterAgent.labels" -}}
{{- $ctx := index . 0 -}}
{{- $labelSets := slice . 1 -}}
{{- $outputDict := dict -}}
{{- include "kubetail.addGlobalLabels" (list $ctx $outputDict) -}}
{{- $_ := set $outputDict "app.kubernetes.io/component" "cluster-agent" -}}
{{- range $labelSet := $labelSets -}}
{{- $outputDict = merge $labelSet $outputDict -}}
{{- end -}}
{{- include "kubetail.printDict" $outputDict -}}
{{- end -}}

{{/*
Cluster Agent selector labels
*/}}
{{- define "kubetail.clusterAgent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubetail.name" $ | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/component: "cluster-agent"
{{- end }}

{{/*
Cluster Agent config
*/}}
{{- define "kubetail.clusterAgent.config" -}}
{{- with .Values.kubetail.allowedNamespaces }}
allowed-namespaces: 
{{- toYaml . | nindent 0 }}
{{- end }}
cluster-agent:
  addr: 0.0.0.0:{{ .Values.kubetail.clusterAgent.runtimeConfig.ports.grpc }}
  {{- $cfg := omit .Values.kubetail.clusterAgent.runtimeConfig "ports" "grpc" }}
  {{- include "kubetail.toKebabYaml" $cfg | nindent 2 }}
{{- end }}

{{/*
Cluster Agent image
*/}}
{{- define "kubetail.clusterAgent.image" -}}
{{- $img := .Values.kubetail.clusterAgent.image -}}
{{- $registry := $img.registry | default "" -}}
{{- $repository := $img.repository | default "" -}}
{{- $ref := ternary (printf ":%s" ($img.tag | default .Chart.AppVersion | toString)) (printf "@%s" $img.digest) (empty $img.digest) -}}
{{- if and $registry $repository -}}
  {{- printf "%s/%s%s" $registry $repository $ref -}}
{{- else -}}
  {{- printf "%s%s%s" $registry $repository $ref -}}
{{- end -}}
{{- end }}

{{/*
Cluster Agent ClusterRole name
*/}}
{{- define "kubetail.clusterAgent.clusterRoleName" -}}
{{ if .Values.kubetail.clusterAgent.rbac.name }}{{ .Values.kubetail.clusterAgent.rbac.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cluster-agent{{ end }}
{{- end }}

{{/*
Cluster Agent ClusterRoleBinding name
*/}}
{{- define "kubetail.clusterAgent.clusterRoleBindingName" -}}
{{ if .Values.kubetail.clusterAgent.rbac.name }}{{ .Values.kubetail.clusterAgent.rbac.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cluster-agent{{ end }}
{{- end }}

{{/*
Cluster Agent ConfigMap name
*/}}
{{- define "kubetail.clusterAgent.configMapName" -}}
{{ default (include "kubetail.fullname" $) .Values.kubetail.clusterAgent.configMap.name }}-cluster-agent
{{- end }}

{{/*
Cluster Agent DaemonSet name
*/}}
{{- define "kubetail.clusterAgent.daemonSetName" -}}
{{ if .Values.kubetail.clusterAgent.daemonSet.name }}{{ .Values.kubetail.clusterAgent.daemonSet.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cluster-agent{{ end }}
{{- end }}

{{/*
Cluster Agent NetworkPolicy name
*/}}
{{- define "kubetail.clusterAgent.networkPolicyName" -}}
{{ if .Values.kubetail.clusterAgent.networkPolicy.name }}{{ .Values.kubetail.clusterAgent.networkPolicy.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cluster-agent{{ end }}
{{- end }}

{{/*
Cluster Agent Role name
*/}}
{{- define "kubetail.clusterAgent.roleName" -}}
{{ if .Values.kubetail.clusterAgent.rbac.name }}{{ .Values.kubetail.clusterAgent.rbac.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cluster-agent{{ end }}
{{- end }}

{{/*
Cluster Agent RoleBinding name
*/}}
{{- define "kubetail.clusterAgent.roleBindingName" -}}
{{ if .Values.kubetail.clusterAgent.rbac.name }}{{ .Values.kubetail.clusterAgent.rbac.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cluster-agent{{ end }}
{{- end }}

{{/*
Cluster Agent Service name
*/}}
{{- define "kubetail.clusterAgent.serviceName" -}}
{{ if .Values.kubetail.clusterAgent.service.name }}{{ .Values.kubetail.clusterAgent.service.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cluster-agent{{ end }}
{{- end }}

{{/*
Cluster Agent ServiceAccount name
*/}}
{{- define "kubetail.clusterAgent.serviceAccountName" -}}
{{ if .Values.kubetail.clusterAgent.serviceAccount.name }}{{ .Values.kubetail.clusterAgent.serviceAccount.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cluster-agent{{ end }}
{{- end }}

{{/**************** CLI helpers ****************/}}

{{/*
CLI labels (including shared app labels)
*/}}
{{- define "kubetail.cli.labels" -}}
{{- $ctx := index . 0 -}}
{{- $labelSets := slice . 1 -}}
{{- $outputDict := dict -}}
{{- include "kubetail.addGlobalLabels" (list $ctx $outputDict) -}}
{{- $_ := set $outputDict "app.kubernetes.io/component" "cli" -}}
{{- range $labelSet := $labelSets -}}
{{- $outputDict = merge $labelSet $outputDict -}}
{{- end -}}
{{- include "kubetail.printDict" $outputDict -}}
{{- end -}}

{{/*
CLI Role name
*/}}
{{- define "kubetail.cli.roleName" -}}
{{ if .Values.kubetail.cli.rbac.name }}{{ .Values.kubetail.cli.rbac.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cli{{ end }}
{{- end }}

{{/*
CLI RoleBinding name
*/}}
{{- define "kubetail.cli.roleBindingName" -}}
{{ if .Values.kubetail.cli.rbac.name }}{{ .Values.kubetail.cli.rbac.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cli{{ end }}
{{- end }}


{{/*
CLI ServiceAccount name
*/}}
{{- define "kubetail.cli.serviceAccountName" -}}
{{ if .Values.kubetail.cli.serviceAccount.name }}{{ .Values.kubetail.cli.serviceAccount.name }}{{ else }}{{ include "kubetail.fullname" $ }}-cli{{ end }}
{{- end }}
