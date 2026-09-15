# Single Sign-On (SSO) with OIDC

Penpot can be configured to use OAuth and SSO with OpenID Connect (OIDC) that is used for identity and access management in AIE. There is an included script that automates the addition of a valid redirect URI for the keycloak OIDC endpoint as well as the client secret required with PenPot [values.yaml](1.9.0/values.yaml#L257).

You can run the provided bash script ([configure_oidc.sh](configure_oidc.sh)) within a terminal that is configured with the `KUBECONFIG` admin access through `kubectl` to the AIE environment:

```bash
chmod +x configure_oidc.sh
./configure_oidc.sh
```

It will print out the `clientSecret` that you can copy into the Open WebUI [values.yaml](1.9.0/values.yaml#L278).

