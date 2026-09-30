# Kubernetes Platform Operations Scope

## 1. Kubernetes Platform Operations

Core Kubernetes administration, performance tuning, and lifecycle management.

**Platform Configuration**
- Tuning Pod Density
- Add exemption paths in the authflow of Istio
- Configure the Container Engine to Trust External Image Registries

**Platform Lifecycle**
- Perform PCAI upgrades

**Platform Troubleshooting**
- Perform troubleshoot of Kubernetes HPE-supported components
- Recover logs from any components of the platform for support

---

## 2. GPU & AI Infrastructure Management

Management of AI accelerator resources and GPU optimization.

**GPU Configuration**
- Configure MIG partition according to customer needs

---

## 3. Identity & Access Management (IAM)

Authentication, authorization, and user lifecycle integration.

**Federation & SSO**
- Configure the SSO in GreenLake with the customer IdP and their domain

**User Provisioning**
- Configure SCIM through the `hpe_css_attribute` for customer IdP user provisioning

**Air-Gapped Identity Services**
- Integrate customer AD with Morpheus

---

## 4. Certificate & PKI Management

Certificate lifecycle, trust chains, and secure communications.

**External CA Integration**
- Integrate HPE AI with external CA service (DigiCert ACME, Let's Encrypt)

**TLS Certificate Management**
- Replace self-signed certificates with a customer CA

**Trust Store Management**
- Add cluster-wide custom CA certificate distributed across all pods

---

## 5. Monitoring, Observability & Alerting

Monitoring stack configuration, telemetry integration, and alert management.

**Alerting**
- Configure templates and filtering alerts in Alertmanager

**Telemetry & Observability**
- Configure the OTEL endpoint in AIE

**Notifications**
- Configure SNMP email notifications (Air-Gapped)

---

## 6. Security & Compliance Operations

Security hardening and encryption management.

**Node Security**
- Change the LUKS configuration in the worker nodes

---

## 7. Infrastructure Operations (Compute, Hardware & Power)

Physical infrastructure and hardware lifecycle operations.

**Server Operations**
- Perform graceful reboot, shutdown, or power-on of components

**Hardware Support**
- Perform troubleshoot with iLO
- Perform PDU/FRU replacement procedures

**Support Access**
- Enable DSC VM access for support team if needed from GreenLake

---

## 8. Storage & Data Services

Storage provisioning, backup, and recovery services.

**Storage Provisioning**
- Create a partition on the GL4F Storage with NFS policy

**Backup & Recovery**
- Backup and restore PCAI configurations, including:
  - Netplan creation
  - Storage network enablement for VME Manager
  - Snapshot repository configuration
  - Incremental VM backups
  - Restore datastore creation
  - GLFS backup configuration for supported platform components

---

## 9. Managed Service Enhancements / Future Scope

Activities that should remain covered as the platform evolves.

**Feature Adoption**
- Support newer officially documented features related to internal platform configurations

**Operational Automation**
- Integrate ad-hoc runbooks created by the product team to satisfy customer requirements

---

## Executive-Level Grouping (Simplified)

If this is going into a service proposal or managed services statement of work, simplify it into **8 top-level towers**:

| Service Tower | Included Areas |
|---|---|
| Kubernetes Operations | Platform administration, upgrades, troubleshooting, logging, Istio |
| GPU & AI Infrastructure | MIG partitioning, AI-specific tuning |
| Identity & Access Management | SSO, SCIM, AD integrations |
| Security & Compliance | PKI, certificates, LUKS, trust stores |
| Monitoring & Observability | Alertmanager, OTEL, SNMP notifications |
| Storage & Data Protection | NFS, backups, restores, snapshots |
| Infrastructure Operations | Hardware, iLO, power operations, FRU/PDU |
| Service Customization & Integrations | Customer-specific configurations, runbooks, future features |
