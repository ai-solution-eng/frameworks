{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}

{{- define "dgxcController.name" -}}
{{- default "controller" .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}

{{- define "dgxcController.fullname" -}}
{{- if .Values.dgxcController.deploymentFullNameOverride -}}
{{- .Values.dgxcController.deploymentFullNameOverride | trunc 63 | trimSuffix "-" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "dgxcController.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "dgx-application-deploy" -}}
{{ .Release.Name }}-{{ .Release.Revision }}
{{- end -}}

{{- define "kubernetesAffinityConfig" }}
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: {{ .Values.kubernetesAffinity.antiAffinityKey | default "reason-to-avoid" }}
          operator: DoesNotExist
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
         - key: "nvidia.com/dgx-application-deploy"
           operator: In
           values:
           - {{ include "dgx-application-deploy" . }}
      topologyKey: {{ .Values.kubernetesAffinity.topologyKey | default "kubernetes.io/hostname" }}
{{- if .Values.kubernetesAffinity.runOnMasters }}
tolerations:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
    operator: Exists
{{- end }}
{{- end }}

