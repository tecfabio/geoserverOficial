#!/bin/bash

# Test script to validate SSL configuration
set -e

echo "=== GeoServer SSL Configuration Test ==="
echo ""

# Check if SSL certificate exists
if [ ! -f "./ssl/keystore.jks" ]; then
    echo "❌ SSL keystore not found. Run ./generate-ssl-cert.sh first"
    exit 1
fi

echo "✅ SSL keystore found: ./ssl/keystore.jks"

# Validate keystore
echo "🔍 Validating keystore contents..."
keytool -list -keystore ./ssl/keystore.jks -storepass geoserver -alias geoserver > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Keystore validation successful"
else
    echo "❌ Keystore validation failed"
    exit 1
fi

# Check docker-compose file syntax
echo "🔍 Validating docker-compose-ssl.yml..."
if command -v docker-compose >/dev/null 2>&1; then
    docker-compose -f docker-compose-ssl.yml config > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ docker-compose-ssl.yml syntax is valid"
    else
        echo "❌ docker-compose-ssl.yml syntax validation failed"
        exit 1
    fi
else
    echo "⚠️  docker-compose not available, skipping syntax validation"
fi

# Check if Dockerfile exists
if [ ! -f "./Dockerfile" ]; then
    echo "❌ Dockerfile not found"
    exit 1
fi

echo "✅ Dockerfile found"

# Validate environment variables in SSL guide
echo "🔍 Checking SSL configuration completeness..."

required_vars=("HTTPS_ENABLED" "HTTPS_KEYSTORE_FILE" "HTTPS_KEYSTORE_PASSWORD" "HTTPS_KEY_ALIAS")
for var in "${required_vars[@]}"; do
    if grep -q "$var" docker-compose-ssl.yml; then
        echo "✅ $var configured in docker-compose-ssl.yml"
    else
        echo "❌ $var missing in docker-compose-ssl.yml"
    fi
done

echo ""
echo "🎉 SSL configuration test completed successfully!"
echo ""
echo "Next steps:"
echo "1. Build and run: docker-compose -f docker-compose-ssl.yml up -d"
echo "2. Access: https://localhost:443/geoserver"
echo "3. Accept the self-signed certificate warning in your browser"
echo ""
echo "For production deployment, see SSL-GUIDE.md for complete instructions."