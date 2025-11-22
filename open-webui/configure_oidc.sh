#!/bin/bash
# Run this script from a terminal configured with the KUBECONFIG for the AIE environment
#  to set up OIDC for OpenWebUI programmatically.

# Define the realm, client, and name of the virtual service for the AIE hosted app
REALM="UA"
CLIENT="ua"
VIRTUAL_SERVICE_NAME="open-webui"

# Domain name for the AIE environment
DOMAIN_NAME=$(kubectl get cm ezapp-manager-parameters -n ezapp-system -o jsonpath='{..DOMAIN_NAME}')
KEYCLOAK_URL="https://keycloak.${DOMAIN_NAME}"

# Get the admin password in order to get an OIDC token for the admin-cli keycloak API
KEYCLOAK_ADMIN_PASSWORD=$(kubectl get secrets admin-pass -n keycloak -o template='{{.data.password | base64decode}}')
ADMIN_TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin" \
    -d "password=${KEYCLOAK_ADMIN_PASSWORD}" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" | jq -r '.access_token')

# Get the internal client id for the ua client
CLIENT_ID=$(curl -s -X GET -H "Authorization: Bearer $ADMIN_TOKEN" \
                 "${KEYCLOAK_URL}/admin/realms/${REALM}/clients?clientId=${CLIENT}" | jq -r '.[0].id')

# Get ua client secret for the clientSecret field in values.yaml
CLIENT_SECRET=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${CLIENT_ID}" \
                     -H "Content-Type: application/json" -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.secret')
echo "clientSecret: \"${CLIENT_SECRET}\""

# Get the current list of redirect URIs for the ua client and add a new of for the app
OIDC_CALLBACK_URL="https://${VIRTUAL_SERVICE_NAME}.${DOMAIN_NAME}/oauth/oidc/callback"
REDIRECT_URIS=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${CLIENT_ID}" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq '.redirectUris' | jq ". += [\"${OIDC_CALLBACK_URL}\"]")

# Update the Valid redirect URIs field for the ua client
curl -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${CLIENT_ID}" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -d "{
          \"clientId\": \"${CLIENT}\",
          \"name\": \"${CLIENT}\",
          \"redirectUris\": ${REDIRECT_URIS}
}"