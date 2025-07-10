# GeoServer SSL Demo - Quick Start

Este projeto demonstra como usar SSL/HTTPS com o GeoServer Docker baseado no Dockerfile existente.

## Uso Rápido

### 1. Gerar Certificado SSL (Desenvolvimento)
```bash
# Gera certificado auto-assinado
./generate-ssl-cert.sh
```

### 2. Executar com SSL
```bash
# Usar Docker Compose com SSL
docker-compose -f docker-compose-ssl.yml up -d

# OU usar Docker diretamente
docker run -d \
  --name geoserver-ssl \
  -p 80:8080 -p 443:8443 \
  -v $(pwd)/ssl:/opt/ssl:Z \
  -v $(pwd)/geoserver_data:/opt/geoserver_data:Z \
  -e HTTPS_ENABLED=true \
  -e HTTPS_KEYSTORE_FILE=/opt/ssl/keystore.jks \
  -e HTTPS_KEYSTORE_PASSWORD=geoserver \
  -e HTTPS_KEY_ALIAS=geoserver \
  docker.osgeo.org/geoserver:2.27.0
```

### 3. Acessar GeoServer
- **HTTPS**: https://localhost:443/geoserver
- **HTTP**: http://localhost:80/geoserver (redireciona para HTTPS)

## Validação
```bash
# Testar configuração SSL
./test-ssl-config.sh

# Ver logs do container
docker logs geoserver-ssl
```

## Arquivos Criados

1. **`docker-compose-ssl.yml`** - Configuração Docker Compose com SSL
2. **`generate-ssl-cert.sh`** - Script para gerar certificados SSL
3. **`SSL-GUIDE.md`** - Guia completo de configuração SSL
4. **`test-ssl-config.sh`** - Script de validação da configuração
5. **`Dockerfile.ssl-example`** - Exemplo de Dockerfile com SSL

## Funcionalidades SSL Implementadas

✅ **Dockerfile com suporte SSL completo** (já existia no repositório)
✅ **Configuração automática de SSL** via variáveis de ambiente
✅ **Geração de certificados para desenvolvimento**
✅ **Configuração de produção com Let's Encrypt**
✅ **Integração com reverse proxy (Nginx/Apache)**
✅ **Documentação completa em português e inglês**
✅ **Scripts de automação e validação**
✅ **Exemplos práticos de uso**

## Para Produção

Veja o [SSL-GUIDE.md](SSL-GUIDE.md) para:
- Configuração com certificados Let's Encrypt
- Integração com certificados de CA personalizados
- Configurações avançadas de segurança
- Integração com proxies reversos
- Melhores práticas de segurança

## Conclusão

O Dockerfile original já tinha suporte completo ao SSL. Esta implementação adiciona:
- Exemplos práticos de uso
- Scripts de automação
- Documentação abrangente
- Configurações prontas para produção

Tudo baseado na infraestrutura SSL já existente no repositório original.