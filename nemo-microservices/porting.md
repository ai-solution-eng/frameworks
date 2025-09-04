# Porting NVIDIA NeMo Microservices to PCAI

## Todo

Replace <YOUR-NGC-API-KEY> with your actual NGC API key.

```yaml
# -- Your NVIDIA GPU Cloud (NGC) API key authenticates and enables pulling images from the NGC container registry. The existing secret overrides this key if you provide one to the `existingSecret` key.
ngcAPIKey: <YOUR-NGC-API-KEY>

# -- List of image pull secrets. Existing secrets override these values if you specify them. Use this only for experimentation when you want to hardcode a secret in your values file.
# @default -- `[{"name":"nvcrimagepullsecret","password":"YOUR-NGC-API-KEY","registry":"nvcr.io","username":"$$oauthtoken"}]`
imagePullSecrets:
  - name: nvcrimagepullsecret
    registry: nvcr.io
    username: $oauthtoken
    password: <YOUR-NGC-API-KEY>
```

## What was changed? 
Highlights the modifications made to the original helm chart.
Coming soon...