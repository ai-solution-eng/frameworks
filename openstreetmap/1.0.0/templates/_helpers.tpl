{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "osm-seed.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "osm-seed.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
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
{{- define "osm-seed.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
S3 endpoint: the bundled MinIO service when provider=minio (computed in-chart,
lifecycle-safe), nothing for aws (upstream AWS env behavior).
*/}}
{{- define "osm-seed.s3Endpoint" -}}
{{- if eq .Values.s3.provider "minio" -}}
http://{{ .Release.Name }}-minio.{{ .Release.Namespace }}.svc.cluster.local:9000
{{- end -}}
{{- end -}}

{{/*
S3 creds + endpoint env entries (no bucket vars). Rendered only when s3.provider == "minio";
with "aws" this renders nothing so upstream AWS behavior is untouched.
Use inside a container's env: block after the generic env entries.
*/}}
{{- define "osm-seed.s3Creds" -}}
{{- if eq .Values.s3.provider "minio" }}
- name: AWS_ACCESS_KEY_ID
  value: {{ .Values.s3.minio.accessKey | quote }}
- name: AWS_SECRET_ACCESS_KEY
  value: {{ .Values.s3.minio.secretKey | quote }}
- name: AWS_ENDPOINT_URL
  value: {{ include "osm-seed.s3Endpoint" . | quote }}
- name: AWS_ENDPOINT
  value: {{ include "osm-seed.s3Endpoint" . | quote }}
{{- end -}}
{{- end -}}

{{/*
Full S3 env set: bucket (s3:// URI style, as most osm-seed scripts expect),
plain bucket name (AWS_S3_BUCKET_NAME, for scripts that build s3:// URIs themselves)
plus creds/endpoint. Rendered only when s3.provider == "minio".
*/}}
{{- define "osm-seed.s3Env" -}}
{{- if eq .Values.s3.provider "minio" }}
- name: AWS_S3_BUCKET
  value: {{ printf "s3://%s" .Values.s3.minio.bucket | quote }}
- name: AWS_S3_BUCKET_NAME
  value: {{ .Values.s3.minio.bucket | quote }}
{{- include "osm-seed.s3Creds" . }}
{{- end -}}
{{- end -}}

{{/*
Corporate-wall support: proxy + CA env entries (gated independently).
Use inside a container's env: block; renders nothing when all blocks are disabled.
*/}}
{{- define "osm-seed.proxyCertsEnv" -}}
{{- $out := list -}}
{{- if .Values.certificatesPolicy.enabled -}}{{- $out = concat $out .Values.certificatesPolicy.env -}}{{- end -}}
{{- if .Values.proxy.enabled -}}{{- $out = concat $out .Values.proxy.env -}}{{- end -}}
{{- if .Values.no_proxy.enabled -}}{{- $out = concat $out .Values.no_proxy.env -}}{{- end -}}
{{- with $out -}}
{{- toYaml $out -}}
{{- end -}}
{{- end -}}

{{/*
Corporate CA init container — entry form (for pods that already have initContainers).
*/}}
{{- define "osm-seed.certsInitEntry" -}}
{{- if and .Values.certificatesPolicy.enabled .Values.certificatesPolicy.initContainer.image }}
- name: copy-ca-certificates
  image: {{ .Values.certificatesPolicy.initContainer.image }}
  command:
{{ toYaml .Values.certificatesPolicy.initContainer.command | nindent 4 }}
  env:
{{ include "osm-seed.proxyCertsEnv" . | nindent 4 }}
  volumeMounts:
{{ toYaml .Values.certificatesPolicy.initVolumeMounts | nindent 4 }}
{{- end -}}
{{- end -}}

{{/*
Corporate CA init container — full block (for pods without initContainers).
*/}}
{{- define "osm-seed.certsInitBlock" -}}
{{- if .Values.certificatesPolicy.enabled }}
initContainers:
{{ include "osm-seed.certsInitEntry" . | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Corporate CA volume mounts — entry form (for containers that already have volumeMounts).
*/}}
{{- define "osm-seed.certsVolumeMountsEntry" -}}
{{- if and .Values.certificatesPolicy.enabled .Values.certificatesPolicy.volumeMounts -}}
{{- toYaml .Values.certificatesPolicy.volumeMounts -}}
{{- end -}}
{{- end -}}

{{/*
Corporate CA volume mounts — full block (for containers without volumeMounts).
*/}}
{{- define "osm-seed.certsVolumeMountsBlock" -}}
{{- if and .Values.certificatesPolicy.enabled .Values.certificatesPolicy.volumeMounts }}
volumeMounts:
{{ toYaml .Values.certificatesPolicy.volumeMounts | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Corporate CA volume — entry form (for pods that already have volumes).
*/}}
{{- define "osm-seed.certsVolumesEntry" -}}
{{- if and .Values.certificatesPolicy.enabled .Values.certificatesPolicy.volumes -}}
{{- toYaml .Values.certificatesPolicy.volumes -}}
{{- end -}}
{{- end -}}

{{/*
Corporate CA volume — full block (for pods without volumes).
*/}}
{{- define "osm-seed.certsVolumesBlock" -}}
{{- if and .Values.certificatesPolicy.enabled .Values.certificatesPolicy.volumes }}
volumes:
{{ toYaml .Values.certificatesPolicy.volumes | nindent 2 }}
{{- end -}}
{{- end -}}
