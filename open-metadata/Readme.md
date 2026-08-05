# Open Metadata

**Important: When importing OpenMetadata using openmetadata-1.12.13.tgz chart, use "openmetadata-dependencies" as release name!**

Helm charts for importing Open Metadata to PCAI:
- **openmetadata-1.12.13.tgz** has been packaged using files from the provided **openmetadata-1.12.13-merged** folder. This helm chart has been built from the official Open Metadata 1.12.13 release from the [**Open Metadata Helm Charts repository**](https://github.com/open-metadata/openmetadata-helm-charts), with the following changes:
  - The official repository provides two helm charts: one for Open Metadata's dependencies, and another one for Open Metadata itself. For convenience, we merged both helm charts into one (merging templates, values and subcharts).
  - The official installation requires manually creating secrets before installing the charts. Our chart includes the secrets' creation (change templates/ezua-specific/secrets.yaml if needed), so no manual kubectl is needed for application import.
  - As usual when porting an application to PCAI, a virtual service has been created to expose Open Metadata web UI, which becomes accessible by clicking on the "Open" button in the Tools & Frameworks page. For reference, we also expose the airflow backend service accessible at the URL appending "-airflow" to "open-metadata" from the Web UI URL. 
  - The following additional values have been added to the airflow section of the values.yaml file to overcome some installation issues:
```
  createUserJob:
    useHelmHooks: false
    applyCustomEnv: false
    
  migrateDatabaseJob:
    useHelmHooks: false
    applyCustomEnv: false
```
- **openmetadata-1.2.4.tgz** corresponds to the former Open Metadata helm chart found in this folder (previously labelled as "1.2.702"), before the addition of the newest 1.12.13 version. It has been changed to no longer refer to bitnami, but to use bitnamilegacy images. It is provided for reference only, use the latest version if possible.

# Known issues

* The official Open Metadata helm chart values assume that the dependencies helm chart has been deployed using openmetadata-dependencies as release name. This has not been changed when merging both, so when importing this merged helm chart, **use "openmetadata-dependencies" as release name**. The import will fail without it.
* **Some features of Open Metadata may not work as expected** with this installation. This includes, but may not be limited to executing ingestion pipelines from the UI. Further troubleshooting is required to get a fully working Open Metadata experience on PCAI.