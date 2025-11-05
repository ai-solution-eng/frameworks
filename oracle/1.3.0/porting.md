# Oracle

Helm chart for Oracle version 7.6.0. 

Changes have been made to be able to import this application to PCAI, using the **Import Framework** button.

The following has been edited:
  * Adding this section to **values.yaml**.
  * Substitute **deployment.yaml** and **pvc.yaml** for a **StatefulSet.yaml** with a **VolumeClaimTemplate** to generate the automatically persistent storage.
  * Added a **headless service** in the **service.yaml** for the statefulset in case this needs to be scaled out minimally.
  * Added the following definitions to the **_helpers.tpl** file:
    ```smarty
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
        {{ include "hpe-ezua.labels" . }}
        app: {{ include "fullname" . }}
        app.kubernetes.io/name: {{ include "name" . }}
        app.kubernetes.io/instance: {{ .Release.Name }}
        {{- end }}
    ```
    * Added **_hpe_ezua.tpl** file to **templates** folder
    * Added **ingress.yaml** file to **templates** folder
    * Following [Virtual Service Instructions](https://support.hpe.com/hpesc/public/docDisplay?docId=a00aie16hen_us&page=ManageClusters/importing-applications.html) and [SSO Instructions](https://support.hpe.com/hpesc/public/docDisplay?docId=a00aie19hen_us&page=ManageClusters/sso-support-for-imported-apps.html), the following changes were also added:
        * Added **ezua** folder to **templates** folder with **cert-copy.yaml** and **virtualService.yaml** files
        * Added **authpolicy.yaml** file to **templates** folder and the corresponding values to **values.yaml**.
