#!/bin/bash

# Keycloak Configuration
KC_SERVER="http://localhost:8080"
KC_REALM="master"
NEW_REALM="mycompany"
KC_USER="admin"
KC_PASSWORD="admin"
CLIENT_ID="net8saml"
CLIENT_NAME="NET8 SAML"
ROOT_URL="http://localhost:5000"
HOME_URL="http://localhost:5000"
PUBLIC_CERT_PATH="./public-cert.pem"

# User & Group Configuration
USER_NAME="shawnz"
USER_PASSWORD="Shawn123"
GROUP_NAME="net8saml_admins"

echo "🔹 Logging into Keycloak..."
TOKEN=$(curl -s -X POST "$KC_SERVER/realms/$KC_REALM/protocol/openid-connect/token" \
    -d "client_id=admin-cli" \
    -d "username=$KC_USER" \
    -d "password=$KC_PASSWORD" \
    -d "grant_type=password" \
    -H "Content-Type: application/x-www-form-urlencoded" | jq -r .access_token)

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "❌ Failed to get access token"
    exit 1
fi

echo "🔹 Creating realm: $NEW_REALM..."
curl -s -X POST "$KC_SERVER/admin/realms" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"realm\": \"$NEW_REALM\",
        \"enabled\": true
    }"

echo "🔹 Creating client: $CLIENT_ID..."
CLIENT_RESPONSE=$(curl -s -X POST "$KC_SERVER/admin/realms/$NEW_REALM/clients" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"clientId\": \"$CLIENT_ID\",
        \"name\": \"$CLIENT_NAME\",
        \"description\": \"$CLIENT_NAME Client\",
        \"enabled\": true,
        \"protocol\": \"saml\",
        \"publicClient\": true,
        \"rootUrl\": \"$ROOT_URL\",
        \"baseUrl\": \"$HOME_URL\",
        \"redirectUris\": [\"$ROOT_URL/*\"],
        \"webOrigins\": [\"$ROOT_URL\"],
        \"attributes\": {
            \"saml.authnstatement\": \"true\",
            \"saml.server.signature\": \"true\",
            \"saml.client.signature\": \"true\",
            \"saml.assertion.signature\": \"true\",
            \"saml.signature.algorithm\": \"RSA_SHA256\",
            \"saml.force.post.binding\": \"true\",
            \"saml_name_id_format\": \"urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress\"
        }
    }")

CLIENT_UUID=$(curl -s "$KC_SERVER/admin/realms/$NEW_REALM/clients" \
    -H "Authorization: Bearer $TOKEN" | jq -r ".[] | select(.clientId==\"$CLIENT_ID\").id")

if [[ -z "$CLIENT_UUID" ]]; then
    echo "❌ Failed to retrieve Client ID"
    exit 1
fi

echo "🔹 Setting Assertion Consumer Service URL..."
curl -s -X PUT "$KC_SERVER/admin/realms/$NEW_REALM/clients/$CLIENT_UUID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"attributes\": {
            \"saml.assertion_consumer_service_url\": \"$ROOT_URL/api/auth/callback\"
        }
    }"

if [[ -f "$PUBLIC_CERT_PATH" ]]; then
    echo "🔹 Uploading Public Key for SAML Signing..."
    CERT_CONTENT=$(cat "$PUBLIC_CERT_PATH" | tr -d '\n')
    curl -s -X PUT "$KC_SERVER/admin/realms/$NEW_REALM/clients/$CLIENT_UUID" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"attributes\": {
                \"saml.signing.certificate\": \"$CERT_CONTENT\"
            }
        }"
fi

echo "🔹 Creating user: $USER_NAME..."
USER_RESPONSE=$(curl -s -X POST "$KC_SERVER/admin/realms/$NEW_REALM/users" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"username\": \"$USER_NAME\",
        \"enabled\": true,
        \"credentials\": [{ \"type\": \"password\", \"value\": \"$USER_PASSWORD\", \"temporary\": false }]
    }")

USER_UUID=$(curl -s "$KC_SERVER/admin/realms/$NEW_REALM/users" \
    -H "Authorization: Bearer $TOKEN" | jq -r ".[] | select(.username==\"$USER_NAME\").id")

if [[ -z "$USER_UUID" ]]; then
    echo "❌ Failed to retrieve User ID"
    exit 1
fi

echo "🔹 Creating group: $GROUP_NAME..."
GROUP_RESPONSE=$(curl -s -X POST "$KC_SERVER/admin/realms/$NEW_REALM/groups" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"$GROUP_NAME\"
    }")

GROUP_UUID=$(curl -s "$KC_SERVER/admin/realms/$NEW_REALM/groups" \
    -H "Authorization: Bearer $TOKEN" | jq -r ".[] | select(.name==\"$GROUP_NAME\").id")

if [[ -z "$GROUP_UUID" ]]; then
    echo "❌ Failed to retrieve Group ID"
    exit 1
fi

echo "🔹 Adding user '$USER_NAME' to group '$GROUP_NAME'..."
curl -s -X PUT "$KC_SERVER/admin/realms/$NEW_REALM/users/$USER_UUID/groups/$GROUP_UUID" \
    -H "Authorization: Bearer $TOKEN"

echo "🔹 Verifying client configuration..."
curl -s "$KC_SERVER/admin/realms/$NEW_REALM/clients/$CLIENT_UUID" \
    -H "Authorization: Bearer $TOKEN" | jq .

echo "✅ Keycloak client, user, and group setup complete!"