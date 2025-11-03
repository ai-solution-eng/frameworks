#
# Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
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

{{- define "oracle.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/* Expand Variables using a template */}}
{{- define "oracle-db-env" }}
env:
  - name: SVC_HOST
    value: "{{ template "fullname" . }}"
  - name: SVC_PORT
    value: "1521"
  - name: ORACLE_SID
    value: {{ default "ORCLCDB" .Values.oracle_sid | quote }}
  - name: ORACLE_PDB
    value: {{ default "ORCLPDB1" .Values.oracle_pdb | quote }}
  - name: ORACLE_PWD
    valueFrom:
      secretKeyRef:
        name: {{ template "fullname" . }}
        key: oracle_pwd
  - name: ORACLE_CHARACTERSET
    value: {{ default "ORCLPDB1" .Values.oracle_characterset | quote }}
  - name: ORACLE_EDITION
    value: {{ default "enterprise" .Values.oracle_edition | quote }}
  - name: ENABLE_ARCHIVELOG
    value: {{ default false .Values.enable_archivelog | quote}}
{{- end }}
{{/* oracle db labels */}}
{{- define "oracle-db-labels" }}
labels:
  app: {{ template "fullname" . }}
  chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
  release: {{ .Release.Name }}
  heritage: {{ .Release.Service }}
  helm.sh/chart: {{ include "oracle.chart" . }}
  {{- include "oracle-db.selectorLabels" . | nindent 2 }}
  {{- if .Chart.AppVersion }}
  app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
  {{- end }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "non-oracle-db-labels" }}
{{ include "hpe-ezua.labels" . }}
labels:
  helm.sh/chart: {{ include "oracle.chart" . }}
  {{- include "oracle-db.selectorLabels" . | nindent 2 }}
  {{- if .Chart.AppVersion }}
  app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
  {{- end }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "oracle-db.selectorLabels" -}}

{{ include "hpe-ezua.labels" . }}
app.kubernetes.io/name: {{ include "name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "oracle-db-fullname.selectorLabels" -}}
app: {{ include "fullname" . }}
app.kubernetes.io/name: {{ include "name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create the name of the service account to use
*/}}
{{- define "oracle-db.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "fullname" .) .Values.serviceAccount.name -}}
{{- else }}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}