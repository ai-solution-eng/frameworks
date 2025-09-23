# n8n

Helm chart for n8n version 1.0.4.

Changes have been made to be able to import this application to PCAI, using the **Import Framework** button.

The following has been edited:

* Following instructions from the documentation page, we made these edits:
   * Adding **virtualservice.yaml** under the **templates** folder, configured for n8n service routing with proper TLS and HTTP configurations
   * Adding this section to **values.yaml**:

```yaml
ezua:
  virtualService:
    endpoint: "n8n.${DOMAIN_NAME}" # change this part based on your instance - in doubt, look at the other frameworks' endpoints
    istioGateway: "istio-system/ezaf-gateway"
```

* Adding **kyvernoclusterpolicy.yaml** under the **templates** folder, without any change
* In **values.yaml**, SQLite database has been configured as default to simplify deployment, though PostgreSQL can be enabled if needed
* To avoid EzLicense capacity issues that prevent pods to be scheduled, each pod deployed by the application must specify *resources.limits.cpu*. Hence, these additional changes:
* In **deployment.yaml** under the **templates** folder, resources have been properly defined and referenced from values:

```yaml
resources:
  {{- toYaml .Values.resources | nindent 10 }}
```

* In **values.yaml**, cpu and memory limits have been defined:

```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

* Added **_hpe-ezua.tpl** template file for HPE EZUA specific labels:

```yaml
{{- define "hpe-ezua.labels" -}}
hpe-ezua/app: {{ .Release.Name }}
hpe-ezua/type: vendor-service
{{- end }}
```

* Security contexts have been properly configured to run as non-root user (UID/GID 1000) for security compliance
* Health checks have been implemented using n8n's `/healthz` endpoint for both liveness and readiness probes
* Persistent storage configuration added with **pvc.yaml** for workflow data persistence

## Notes

* Original n8n Docker image `n8nio/n8n:latest` is used as the base
* Basic authentication is enabled by default with username `admin` and password `changeme` - **these must be changed for production use**
* Encryption key is set to a demo value `demo-encryption-key-12345` - **this must be changed for production use**
* Database is configured to use SQLite by default for simplicity. For production environments, consider switching to PostgreSQL
* The CPU limit value of 1000m (1 CPU core) is based on n8n's typical resource requirements. Feel free to adjust based on your workflow complexity
* Version number in **Chart.yaml** has been changed to 0.1.4-pcai to indicate customisation. As PCAI does not allow for reuploading helm charts for the same application name and version (in case the few first uploads led to import failures), you need to change the version in **Chart.yaml**
* Timezone is set to "Europe/Berlin" (CET) by default - adjust as needed for your deployment region
* The chart includes proper Istio VirtualService configuration for both TLS and HTTP traffic routing