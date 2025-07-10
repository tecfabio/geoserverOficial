# GeoServer SSL/HTTPS Configuration Guide

This guide provides detailed instructions for enabling SSL/HTTPS in the GeoServer Docker container.

## Overview

The GeoServer Docker image includes built-in SSL/HTTPS support with configurable options for:
- Self-signed certificates (development/testing)
- Custom SSL certificates (production)
- Automatic HTTP to HTTPS redirection
- Configurable SSL parameters

## Quick Start with SSL

### 1. Generate SSL Certificate (Development)

For development and testing, use the provided script to generate a self-signed certificate:

```bash
# Generate self-signed certificate
./generate-ssl-cert.sh

# The script creates:
# - ./ssl/keystore.jks (Java KeyStore with SSL certificate)
# - Configures the certificate for localhost access
```

### 2. Run with SSL using Docker Compose

Use the provided SSL-enabled Docker Compose configuration:

```bash
# Start GeoServer with SSL
docker-compose -f docker-compose-ssl.yml up -d

# Access GeoServer securely:
# - HTTPS: https://localhost:443/geoserver
# - HTTP: http://localhost:80/geoserver (redirects to HTTPS)
```

### 3. Docker Run with SSL

For direct Docker usage:

```bash
# Generate certificate first
./generate-ssl-cert.sh

# Run container with SSL
docker run -d \
  --name geoserver-ssl \
  -p 80:8080 \
  -p 443:8443 \
  -v $(pwd)/ssl:/opt/ssl:Z \
  -v $(pwd)/geoserver_data:/opt/geoserver_data:Z \
  -e HTTPS_ENABLED=true \
  -e HTTPS_KEYSTORE_FILE=/opt/ssl/keystore.jks \
  -e HTTPS_KEYSTORE_PASSWORD=geoserver \
  -e HTTPS_KEY_ALIAS=geoserver \
  docker.osgeo.org/geoserver:2.27.0
```

## SSL Environment Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `HTTPS_ENABLED` | Enable/disable HTTPS | `false` |
| `HTTPS_KEYSTORE_FILE` | Path to Java KeyStore file | `/opt/keystore.jks` |
| `HTTPS_KEYSTORE_PASSWORD` | KeyStore password | `changeit` |
| `HTTPS_KEY_ALIAS` | Certificate alias in KeyStore | `server` |

## Production SSL Setup

### Using Let's Encrypt Certificate

1. **Obtain Let's Encrypt Certificate:**
```bash
# Use certbot to get certificate
certbot certonly --standalone -d your-domain.com

# Convert to Java KeyStore format
openssl pkcs12 -export \
  -in /etc/letsencrypt/live/your-domain.com/fullchain.pem \
  -inkey /etc/letsencrypt/live/your-domain.com/privkey.pem \
  -out ssl/certificate.p12 \
  -name geoserver \
  -passout pass:your-secure-password

keytool -importkeystore \
  -deststorepass your-secure-password \
  -destkeypass your-secure-password \
  -destkeystore ssl/keystore.jks \
  -srckeystore ssl/certificate.p12 \
  -srcstoretype PKCS12 \
  -srcstorepass your-secure-password \
  -alias geoserver
```

2. **Configure Environment:**
```bash
# Set secure environment variables
export HTTPS_ENABLED=true
export HTTPS_KEYSTORE_FILE=/opt/ssl/keystore.jks
export HTTPS_KEYSTORE_PASSWORD=your-secure-password
export HTTPS_KEY_ALIAS=geoserver
```

### Using Custom CA Certificate

1. **Create KeyStore from existing certificate:**
```bash
# If you have .crt and .key files
openssl pkcs12 -export \
  -in your-certificate.crt \
  -inkey your-private-key.key \
  -out ssl/certificate.p12 \
  -name geoserver \
  -passout pass:your-password

keytool -importkeystore \
  -deststorepass your-password \
  -destkeypass your-password \
  -destkeystore ssl/keystore.jks \
  -srckeystore ssl/certificate.p12 \
  -srcstoretype PKCS12 \
  -srcstorepass your-password \
  -alias geoserver
```

## Advanced SSL Configuration

### Custom Tomcat SSL Configuration

To use advanced SSL settings, create a custom `server.xml`:

1. **Create custom server configuration:**
```bash
mkdir -p config_overrides
cp config/server-https.xml config_overrides/server.xml
```

2. **Modify SSL connector settings in `config_overrides/server.xml`:**
```xml
<Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"
           maxThreads="150" SSLEnabled="true"
           maxParameterCount="1000"
           scheme="https" secure="true"
           clientAuth="false" sslProtocol="TLS"
           ciphers="TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
           protocols="TLSv1.2,TLSv1.3"
           >
    <SSLHostConfig>
        <Certificate certificateKeystoreFile="${HTTPS_KEYSTORE_FILE}"
                     certificateKeystorePassword="${HTTPS_KEYSTORE_PASSWORD}"
                     certificateKeyAlias="${HTTPS_KEY_ALIAS}"
                     type="RSA" />
    </SSLHostConfig>
</Connector>
```

3. **Mount custom configuration:**
```bash
docker run -d \
  -v $(pwd)/config_overrides:/opt/config_overrides:Z \
  -e HTTPS_ENABLED=true \
  # ... other options
```

## SSL Certificate Management

### Certificate Renewal

For automated certificate renewal with Let's Encrypt:

```bash
#!/bin/bash
# renewal-script.sh
certbot renew --quiet
# Convert and update keystore
# Restart container
docker-compose -f docker-compose-ssl.yml restart geoserver-ssl
```

### Certificate Validation

Validate your SSL setup:

```bash
# Check certificate expiration
openssl s_client -connect localhost:443 -servername localhost 2>/dev/null | \
  openssl x509 -noout -dates

# Test SSL connection
curl -k -I https://localhost:443/geoserver

# Check certificate details
keytool -list -v -keystore ssl/keystore.jks -storepass geoserver
```

## Troubleshooting SSL

### Common Issues

1. **Certificate not trusted:**
   - Use a certificate from a trusted CA for production
   - For development, accept the browser security warning

2. **Port conflicts:**
   - Ensure ports 443 and 80 are not used by other services
   - Use different ports if needed: `-p 8443:8443`

3. **KeyStore errors:**
   - Verify keystore password and file path
   - Check file permissions and ownership

### Debug SSL Issues

Enable SSL debug logging:

```bash
# Add to EXTRA_JAVA_OPTS
-Djavax.net.debug=ssl:handshake:verbose
```

View container logs:
```bash
docker logs geoserver-ssl
```

## Security Best Practices

1. **Use strong passwords** for keystores
2. **Keep certificates updated** and monitor expiration
3. **Use TLS 1.2 or higher** only
4. **Implement proper firewall rules**
5. **Regular security updates** of the container
6. **Monitor SSL/TLS configuration** with tools like SSL Labs

## Integration Examples

### With Nginx Reverse Proxy

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    
    location /geoserver/ {
        proxy_pass https://geoserver-ssl:8443/geoserver/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

### With Apache HTTP Server

```apache
<VirtualHost *:443>
    ServerName your-domain.com
    
    SSLEngine on
    SSLCertificateFile /path/to/certificate.crt
    SSLCertificateKeyFile /path/to/private.key
    
    ProxyPreserveHost On
    ProxyPass /geoserver/ https://geoserver-ssl:8443/geoserver/
    ProxyPassReverse /geoserver/ https://geoserver-ssl:8443/geoserver/
</VirtualHost>
```

For more information, see the [GeoServer Production Documentation](https://docs.geoserver.org/latest/en/user/production/).