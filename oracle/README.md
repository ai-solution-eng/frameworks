# Oracle Database
[Oracle](http://www.oracle.com)
Database 26ai is an industry leading relational database server.

## Getting started
The provided **Helm Chart** in this repo is a modified version of the one available in the official [Oracle GitHub repository](https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance/helm-charts/oracle-db)




## Introduction

The Oracle Database Chart contains the Oracle Database 26ai running on Oracle Linux 8. 

For more information on Oracle Database 26ai refer to [Oracle Database Online Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/index.html) or [Oracle Container Registry](https://container-registry.oracle.com/ords/ocr/ba/database/free).

## Prerequisites

- Kubernetes 1.12+
- Helm 2.x or 3.x
- Storage Provisioner
- Using Oracle Database Docker image requires you to accept terms of service
- Create image pull secrets
```bash
kubectl create secret docker-registry regcred --docker-server=container-registry.oracle.com --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>
```

## Configuration

The following tables lists the configurable parameters of the Oracle  Database chart and their default values.

| Parameter                            | Description                                | Default                                                    |
| -------------------------------      | -------------------------------            | ---------------------------------------------------------- |
| oracle_sid                           | Database name (ORACLE_SID)                 | FREE                                                    |
| oracle_pdb                           | PDB name                                   | FREEPDB1                                                   |
| oracle_pwd                           | SYS, SYSTEM and PDBADMIN password          | Prueba123                                             |
| oracle_characterset                  | The character set to use                   | AL32UTF8                                                   |
| oracle_edition                       | The database edition                       | free                                                 |
| persistence.size                     | Size of persistence storage                | 100g                                                       |
| persistence.storageClass             | Storage Class for PVC                      | nfs-csi                                                   |
| loadBalService                       | Create a load balancer service instead of NodePort | false                                              |
| image                                | Image to pull                              | registry.oracle.com/database/free:latest |
| imagePullPolicy                      | Image pull policy                          | Always                                                     |
| imagePullSecrets                     | container registry login/password          |                                                            |
| enable_archivelog                    | Set true to enable archive log mode when creating the database | false                                                      |


> Modify the [values.yaml](values.yaml) file to customize the installation.


## Persistence

The [Oracle Database](https://www.oracle.com) image stores the Oracle Database data files  and configurations at the `/opt/oracle/oradata` path of the container.

Persistent Volume Claims are used to keep the data across deployments.

