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
kubectl exec -it <headlamp-pod> -n <headlamp-namespace> -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

To create a token scoped to the privs of a specific account (where sa is the name of the k8s sa and ns is the namespace):
```shell
kubectl create token sa -n ns
```


### Permanent login token

For a token that stays the same, create a secret of type `kubernetes.io/service-account-token` bound to the Headlamp service account. Kubernetes fills it with a token that has no expiry; it stays valid until the secret is deleted.

1. Find the namespace and service account:
   ```shell
   kubectl get pods -A | grep headlamp     # first column = namespace
   NS=<headlamp-namespace>
   kubectl get sa -n $NS                    # usually "headlamp"
   ```

2. Save the following as `headlamp-token.yaml`, replacing the placeholders:
   ```yaml
   apiVersion: v1
   kind: Secret
   type: kubernetes.io/service-account-token
   metadata:
     name: headlamp-login-token
     namespace: <headlamp-namespace>
     annotations:
       kubernetes.io/service-account.name: <headlamp-sa-name>
   ```

3. Apply it and read the token (if it prints nothing, wait a second and retry):
   ```shell
   kubectl apply -f headlamp-token.yaml
   kubectl get secret headlamp-login-token -n $NS -o jsonpath='{.data.token}' | base64 -d; echo
   ```

4. Verify it (should print `yes`), then paste it into the Headlamp login page:
   ```shell
   kubectl --token="<token>" auth can-i list pods -A
   ```

### Regenerating the token

Re-running `kubectl apply` on an existing secret does **not** change the token. To get a new one, the secret must be deleted.

**Replace in place** (old token stops working immediately):
```shell
kubectl delete secret headlamp-login-token -n $NS
kubectl apply -f headlamp-token.yaml
kubectl get secret headlamp-login-token -n $NS -o jsonpath='{.data.token}' | base64 -d; echo
```

**Rotate with no gap** (when teammates or scripts share the token):
1. Copy the file with a dated name (e.g. `headlamp-token-2026-11.yaml`) and set `metadata.name: headlamp-login-token-2026-11`.
2. Apply it and read the new token. Both old and new tokens now work.
3. Share the new token and update scripts/CI.
4. List the token secrets and delete the old one:
   ```shell
   kubectl get secret -n $NS --field-selector type=kubernetes.io/service-account-token
   kubectl delete secret <old-secret-name> -n $NS
   ```
5. Confirm the old token is rejected (`kubectl --token="<old-token>" auth can-i list pods -A` returns `Unauthorized`).

Deleting a secret revokes only that token; deleting the service account revokes all of its tokens.
