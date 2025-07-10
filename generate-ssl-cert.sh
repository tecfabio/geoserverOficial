#!/bin/bash

# Script to generate SSL certificates for GeoServer Docker container
# This creates a self-signed certificate suitable for development/testing

set -e

# Configuration
SSL_DIR="./ssl"
KEYSTORE_FILE="$SSL_DIR/keystore.jks"
KEYSTORE_PASSWORD="geoserver"
KEY_ALIAS="geoserver"
VALIDITY_DAYS=365

# Certificate details
CERT_CN="${CERT_CN:-localhost}"
CERT_OU="${CERT_OU:-GeoServer}"
CERT_O="${CERT_O:-OSGeo}"
CERT_L="${CERT_L:-City}"
CERT_ST="${CERT_ST:-State}"
CERT_C="${CERT_C:-US}"

echo "=== GeoServer SSL Certificate Generator ==="
echo "This script will generate a self-signed SSL certificate for development/testing purposes."
echo ""
echo "Configuration:"
echo "  SSL Directory: $SSL_DIR"
echo "  Keystore File: $KEYSTORE_FILE"
echo "  Keystore Password: $KEYSTORE_PASSWORD"
echo "  Key Alias: $KEY_ALIAS"
echo "  Validity: $VALIDITY_DAYS days"
echo "  Common Name (CN): $CERT_CN"
echo ""

# Create SSL directory if it doesn't exist
if [ ! -d "$SSL_DIR" ]; then
    echo "Creating SSL directory: $SSL_DIR"
    mkdir -p "$SSL_DIR"
fi

# Remove existing keystore if it exists
if [ -f "$KEYSTORE_FILE" ]; then
    echo "Removing existing keystore: $KEYSTORE_FILE"
    rm "$KEYSTORE_FILE"
fi

# Generate the keystore with self-signed certificate
echo "Generating self-signed SSL certificate..."
keytool -genkeypair \
    -alias "$KEY_ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity "$VALIDITY_DAYS" \
    -keystore "$KEYSTORE_FILE" \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEYSTORE_PASSWORD" \
    -dname "CN=$CERT_CN, OU=$CERT_OU, O=$CERT_O, L=$CERT_L, ST=$CERT_ST, C=$CERT_C" \
    -ext SAN=dns:localhost,dns:geoserver,ip:127.0.0.1

echo ""
echo "✅ SSL certificate generated successfully!"
echo ""
echo "Keystore details:"
keytool -list -v -keystore "$KEYSTORE_FILE" -storepass "$KEYSTORE_PASSWORD" | head -20

echo ""
echo "📋 To use this certificate with GeoServer:"
echo "1. Make sure the ssl directory is mounted to /opt/ssl in your container"
echo "2. Set the following environment variables:"
echo "   - HTTPS_ENABLED=true"
echo "   - HTTPS_KEYSTORE_FILE=/opt/ssl/keystore.jks"
echo "   - HTTPS_KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD"
echo "   - HTTPS_KEY_ALIAS=$KEY_ALIAS"
echo ""
echo "3. Access GeoServer at: https://localhost:443/geoserver"
echo ""
echo "⚠️  Note: This is a self-signed certificate for development only."
echo "   Your browser will show a security warning that you'll need to accept."
echo "   For production, use a certificate from a trusted Certificate Authority."
echo ""
echo "🚀 Ready to run docker-compose -f docker-compose-ssl.yml up"