# HashiCorp Vault Standalone Deployment on HPE PCAI

[![Vault](https://img.shields.io/badge/HashiCorp-Vault-000000?logo=vault&logoColor=white)](https://developer.hashicorp.com/vault)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Deployment-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-Chart-0F1689?logo=helm&logoColor=white)](https://helm.sh/)

This guide explains how to deploy, initialise, unseal, verify, and access a **standalone HashiCorp Vault** instance on **HPE PCAI** using the Vault Helm chart.

> [!IMPORTANT]
> This deployment uses standalone file storage and has High Availability disabled. It is suitable for development, demonstration, or lab environments. Review the architecture and storage design before using it for production workloads.

## Table of Contents

- [Architecture](#architecture)
- [Deployment](#deployment)
- [Initialize Vault](#initialize-vault)
- [Unseal Vault](#unseal-vault)
- [Verify Vault](#verify-vault)
- [Log In to Vault](#log-in-to-vault)

## Architecture

```text
HPE PCAI Kubernetes Cluster
└── Namespace: vault
    ├── StatefulSet: vault
    │   └── Pod: vault-0
    │       ├── Vault server
    │       ├── File storage
    │       └── PersistentVolumeClaim: data-vault-0
    └── Deployment: vault-agent-injector
        └── Vault Agent Injector pod
```

| Component | Configuration |
|---|---|
| Deployment mode | Standalone |
| Storage backend | File |
| Seal type | Shamir |
| Key shares | 5 |
| Unseal threshold | 3 |
| High Availability | Disabled |
| Vault API port | `8200` |

## Deployment

### Deploy the Helm Chart

Use the **Import Framework** option in HPE PCAI to deploy the standalone Vault Helm chart.

After deployment, monitor the resources in the `vault` namespace:

```bash
kubectl get pods -n vault -w
```

Expected initial state:

```text
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 0/1     Running   0          8s
vault-agent-injector-7b8988697f-mz8c9   1/1     Running   0          10s
```

> [!NOTE]
> `vault-0` showing `0/1 Running` is expected before Vault has been initialised and unsealed.

## Initialize Vault

> [!WARNING]
> Run `vault operator init` only once for a new Vault storage backend. Do not initialise Vault again after it has already been initialised.

Generate five unseal key shares with a threshold of three:

```bash
kubectl exec -n vault vault-0 -- \
  vault operator init \
  -key-shares=5 \
  -key-threshold=3
```

Example output:

```text
Unseal Key 1: <UNSEAL_KEY_1>
Unseal Key 2: <UNSEAL_KEY_2>
Unseal Key 3: <UNSEAL_KEY_3>
Unseal Key 4: <UNSEAL_KEY_4>
Unseal Key 5: <UNSEAL_KEY_5>

Initial Root Token: <INITIAL_ROOT_TOKEN>

Vault initialized with 5 key shares and a key threshold of 3.
```

> [!CAUTION]
> Never add real unseal keys or root tokens to this README, source control, shell scripts, tickets, email, or chat. Store them using your organisation's approved secure process and distribute the key shares to authorised custodians.

## Unseal Vault

Run the following command three times. Enter a **different unseal key** each time when prompted:

```bash
kubectl exec -it -n vault vault-0 -- vault operator unseal
```

### First key

Expected status:

```text
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    1/3
Version            2.0.3
Storage Type       file
HA Enabled         false
```

### Second key

Run the same command again using a different key:

```bash
kubectl exec -it -n vault vault-0 -- vault operator unseal
```

Expected progress:

```text
Sealed             true
Unseal Progress    2/3
```

### Third key

Run the command a third time using another different key:

```bash
kubectl exec -it -n vault vault-0 -- vault operator unseal
```

Expected final state:

```text
Initialized        true
Sealed             false
Total Shares       5
Threshold          3
Storage Type       file
HA Enabled         false
```

> [!TIP]
> When the third valid key is accepted, `Sealed` changes to `false`. The final output may no longer display `Unseal Progress` because the unseal operation is complete.

## Verify Vault

### Check Vault status

```bash
kubectl exec -n vault vault-0 -- vault status
```

Expected output:

```text
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    5
Threshold       3
Storage Type    file
HA Enabled      false
```

### Check pod readiness

```bash
kubectl get pods -n vault
```

Expected state:

```text
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 1/1     Running   0          50s
vault-agent-injector-7b8988697f-mz8c9   1/1     Running   0          50s
```

## Log In to Vault

Use the initial root token generated during initialisation:

```bash
kubectl exec -it -n vault vault-0 -- vault login
```

Enter the token when prompted:

```text
Token (will be hidden):
```

Verify the authenticated token:

```bash
kubectl exec -n vault vault-0 -- vault token lookup
```

> [!IMPORTANT]
> Use the initial root token only for bootstrap administration. Configure an appropriate administrative authentication method and policies, validate access, and then revoke the initial root token according to your organisation's security process.
