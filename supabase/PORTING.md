# Porting guide

All services, except minio for S3 backend, are deployed.

Added virtual service for supabase

```yaml
ezua:
  virtualService:
    endpoint: "supabase.${DOMAIN_NAME}"
```

Added auth policy and virtual service for supabase.

Updated values.yaml with the following:
```yaml
environment:
  studio:
    SUPABASE_PUBLIC_URL: https://supabase.${DOMAIN_NAME}
```

Update auth section in values.yaml to use Keycloak for authentication.

> Please note, internal services still use JWT for authentication provided in the `values.yaml` file. 
> Change these secrets/JWT tokens for your environment.

```yaml
environment:
  auth:
    API_EXTERNAL_URL: https://supabase.${DOMAIN_NAME}/auth
    GOTRUE_SITE_URL: https://supabase.${DOMAIN_NAME}
    GOTRUE_EXTERNAL_KEYCLOAK_ENABLED: "true"
    GOTRUE_EXTERNAL_KEYCLOAK_CLIENT_ID: "${OIDC_CLIENT_ID}"
    GOTRUE_EXTERNAL_KEYCLOAK_SECRET: "${OIDC_CLIENT_SECRET}"
    GOTRUE_EXTERNAL_KEYCLOAK_URL: "https://keycloak.${DOMAIN_NAME}/realms/UA"
    GOTRUE_EXTERNAL_KEYCLOAK_REDIRECT_URI: "https://supabase.${DOMAIN_NAME}/auth/v1/callback"
```  

Added hpe-ezua.labels to the template and updated selectorLabels with it.
[_helpers.tpl](./templates/_helpers.tpl) Line 51: `{{ include "hpe-ezua.labels" . }}`

If enabled, Keycloak needs callback URL configured. Run `./configure_oidc.sh` to configure it.

Update values.yaml secrets section as you see fit. Default values are provided.
- 5-year JWT keys
- DB and Dashboard password

Enabled services:
- analytics
- db
- vector
- studio
- logflare
- edgeFunctions
- postgrest
- postgresMeta

## NOTE

- Make sure CA Root certificate is trusted by the cluster (if using self-signed or custom certs).

- Framework import is possible with `kubectl apply -f supabase-ezapp.yaml`
