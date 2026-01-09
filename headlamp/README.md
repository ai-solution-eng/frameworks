# Headlamp

## Introduction

Headlamp is an easy-to-use and extensible Kubernetes web UI.

The helm charts in this directory adapt the upstream Headlamp chart for use with HPE Private Cloud for AI.

## Configuration
### Access

After installation, the web UI can be accessed at the URL provided in the values file. By default, it's `headlamp.DOMAIN`. The user will need to provide an access token when the UI is first deployed.

> [!WARNING]
> The token accessed via the method below is scoped to `cluster-admin` and will provide access to the entire cluster


To use the cluster-admin token:
```shell
k exec -it headlamp-8466698f5b-zht5j -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

To create a token scoped to the privs of a specific account (where sa is the name of the k8s sa and ns is the namespace):
```shell
kubectl create token sa -n ns
```