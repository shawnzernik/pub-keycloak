#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Keycloak Configuration
KC_SERVER="http://localhost:8080"
KC_REALM="mycompany"
CLIENT_ID="net8saml"
KC_USER="admin"
KC_PASSWORD="admin"

# Output file paths
CERT_FILE="$SCRIPT_DIR/../public-cert.pem"
PRIVATE_KEY_FILE="$SCRIPT_DIR/../private-key.pem"

echo "🔹 Logging into Keycloak..."
TOKEN=$(curl -s -X POST "$KC_SERVER/realms/master/protocol/openid-connect/token" \
    -d "client_id=admin-cli" \
    -d "username=$KC_USER" \
    -d "password=$KC_PASSWORD" \
    -d "grant_type=password" \
    -H "Content-Type: application/x-www-form-urlencoded" | jq -r .access_token)

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "❌ Failed to get access token"
    exit 1
fi

echo "🔹 Fetching client ID..."
CLIENT_UUID=$(curl -s "$KC_SERVER/admin/realms/$KC_REALM/clients" \
    -H "Authorization: Bearer $TOKEN" | jq -r ".[] | select(.clientId==\"$CLIENT_ID\").id")

if [[ -z "$CLIENT_UUID" ]]; then
    echo "❌ Failed to retrieve Client ID"
    exit 1
fi

echo "🔹 Fetching client configuration..."
CLIENT_CONFIG=$(curl -s "$KC_SERVER/admin/realms/$KC_REALM/clients/$CLIENT_UUID" \
    -H "Authorization: Bearer $TOKEN")

# Extract SAML signing certificate and private key
CERT=$(echo "$CLIENT_CONFIG" | jq -r '.attributes."saml.signing.certificate"')
PRIVATE_KEY=$(echo "$CLIENT_CONFIG" | jq -r '.attributes."saml.signing.private.key"')

# Write to files
echo "🔹 Writing SAML signing certificate to $CERT_FILE..."
echo "-----BEGIN CERTIFICATE-----" > "$CERT_FILE"
echo "$CERT" | fold -w 64 >> "$CERT_FILE"
echo "-----END CERTIFICATE-----" >> "$CERT_FILE"

echo "🔹 Writing SAML signing private key to $PRIVATE_KEY_FILE..."
echo "-----BEGIN PRIVATE KEY-----" > "$PRIVATE_KEY_FILE"
echo "$PRIVATE_KEY" | fold -w 64 >> "$PRIVATE_KEY_FILE"
echo "-----END PRIVATE KEY-----" >> "$PRIVATE_KEY_FILE"

echo "✅ Keys extracted and saved!"

CURR_DIR="$(pwd)"
cd "$SCRIPT_DIR/.."
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in private-key.pem -out private-key-pkcs8.pem
cd $CURR_DIR