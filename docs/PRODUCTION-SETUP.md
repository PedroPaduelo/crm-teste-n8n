# Configuração de Produção - CRM com N8N

## 📋 Visão Geral

Este documento fornece um guia completo para configurar o CRM com N8N em ambiente de produção, incluindo configurações de segurança, desempenho e monitoramento.

## 🏗️ Pré-requisitos

### Infraestrutura Mínima

- **CPU**: 2+ cores
- **RAM**: 4+ GB
- **Armazenamento**: 50+ GB SSD
- **SO**: Ubuntu 20.04+ / CentOS 8+ / Debian 11+
- **Docker**: 20.10+
- **Docker Compose**: 2.0+

### Software Necessário

```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Instalar Node.js (para scripts)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Instalar outras dependências
sudo apt-get update
sudo apt-get install -y git nginx certbot python3-certbot-nginx
```

## 🔧 Configuração do Servidor

### 1. Configurar Firewall

```bash
# Configurar UFW (Ubuntu)
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

# Ou configurar iptables
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

### 2. Configurar Usuário de Deploy

```bash
# Criar usuário para deploy
sudo adduser deploy
sudo usermod -aG docker deploy

# Configurar SSH key
sudo mkdir -p /home/deploy/.ssh
sudo cp ~/.ssh/authorized_keys /home/deploy/.ssh/
sudo chown -R deploy:deploy /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh
sudo chmod 600 /home/deploy/.ssh/authorized_keys
```

### 3. Configurar Nginx

```bash
# Criar arquivo de configuração
sudo nano /etc/nginx/sites-available/crm
```

```nginx
# /etc/nginx/sites-available/crm
server {
    listen 80;
    server_name seu-dominio.com www.seu-dominio.com;
    
    # Redirecionar para HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name seu-dominio.com www.seu-dominio.com;
    
    # Configurações SSL
    ssl_certificate /etc/letsencrypt/live/seu-dominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/seu-dominio.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Proxy para Backend
    location /api/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Rate limiting
        limit_req zone=api burst=20 nodelay;
    }
    
    # Proxy para Frontend
    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        
        # Cache estático
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            add_header X-Content-Type-Options nosniff;
        }
    }
    
    # Webhook do WhatsApp
    location /webhooks/whatsapp {
        proxy_pass http://127.0.0.1:3001/webhooks/whatsapp;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Rate limiting
http {
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
}
```

### 4. Configurar SSL com Let's Encrypt

```bash
# Obter certificado SSL
sudo certbot --nginx -d seu-dominio.com -d www.seu-dominio.com

# Configurar renovação automática
sudo crontab -e
# Adicionar linha:
# 0 12 * * * /usr/bin/certbot renew --quiet
```

## 🗄️ Configuração do Banco de Dados

### PostgreSQL em Produção

```bash
# Instalar PostgreSQL
sudo apt-get install postgresql postgresql-contrib

# Configurar PostgreSQL
sudo nano /etc/postgresql/13/main/postgresql.conf
```

```ini
# /etc/postgresql/13/main/postgresql.conf
# Configurações de performance
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 4MB
min_wal_size = 1GB
max_wal_size = 4GB
max_connections = 200
```

```bash
# Configurar autenticação
sudo nano /etc/postgresql/13/main/pg_hba.conf
```

```ini
# /etc/postgresql/13/main/pg_hba.conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
```

### Criar Banco de Dados e Usuário

```bash
# Acessar PostgreSQL
sudo -u postgres psql

# Criar banco de dados
CREATE DATABASE crm_db;
CREATE USER crm_user WITH PASSWORD 'senha_segura_123';
GRANT ALL PRIVILEGES ON DATABASE crm_db TO crm_user;
ALTER USER crm_user CREATEDB;
\q
```

## 🐳 Configuração Docker Compose Produção

```bash
# Criar docker-compose.prod.yml
nano docker-compose.prod.yml
```

```yaml
version: '3.8'

services:
  db:
    image: postgres:15-alpine
    container_name: crm_db_prod
    restart: always
    environment:
      POSTGRES_DB: crm_db
      POSTGRES_USER: crm_user
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - crm_network
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U crm_user -d crm_db"]
      interval: 30s
      timeout: 10s
      retries: 3

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: crm_backend_prod
    restart: always
    environment:
      NODE_ENV: production
      PORT: 3001
      DATABASE_URL: postgresql://crm_user:${DB_PASSWORD}@db:5432/crm_db
      JWT_SECRET: ${JWT_SECRET}
      WHATSAPP_API_TOKEN: ${WHATSAPP_API_TOKEN}
      WHATSAPP_PHONE_NUMBER_ID: ${WHATSAPP_PHONE_NUMBER_ID}
      VERIFY_TOKEN: ${VERIFY_TOKEN}
      N8N_WEBHOOK_URL: ${N8N_WEBHOOK_URL}
      N8N_API_KEY: ${N8N_API_KEY}
      SMTP_HOST: ${SMTP_HOST}
      SMTP_PORT: ${SMTP_PORT}
      SMTP_USER: ${SMTP_USER}
      SMTP_PASS: ${SMTP_PASS}
      FRONTEND_URL: https://seu-dominio.com
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./backend/uploads:/app/uploads
      - ./logs:/app/logs
    networks:
      - crm_network
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: crm_frontend_prod
    restart: always
    environment:
      VITE_API_URL: https://seu-dominio.com/api
      VITE_N8N_WEBHOOK_URL: https://seu-dominio.com/webhooks/n8n
      VITE_NODE_ENV: production
    depends_on:
      - backend
    networks:
      - crm_network
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.25'

  n8n:
    image: n8nio/n8n:latest
    container_name: crm_n8n_prod
    restart: always
    environment:
      N8N_BASIC_AUTH_ACTIVE: true
      N8N_BASIC_AUTH_USER: ${N8N_USER}
      N8N_BASIC_AUTH_PASSWORD: ${N8N_PASSWORD}
      N8N_HOST: n8n.seu-dominio.com
      N8N_PORT: 5678
      N8N_PROTOCOL: https
      WEBHOOK_URL: https://seu-dominio.com/
      N8N_SECURE_COOKIE: true
      N8N_METRICS: true
      N8N_DIAGNOSTICS_ENABLED: false
    volumes:
      - n8n_data:/home/node/.n8n
      - ./n8n/workflows:/home/node/.n8n/workflows
    networks:
      - crm_network
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'

  redis:
    image: redis:7-alpine
    container_name: crm_redis_prod
    restart: always
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - crm_network
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.25'

volumes:
  postgres_data:
    driver: local
  n8n_data:
    driver: local
  redis_data:
    driver: local

networks:
  crm_network:
    driver: bridge
```

## 🔐 Configuração de Segurança

### 1. Variáveis de Ambiente

```bash
# Criar arquivo de produção
sudo nano /opt/crm-teste-n8n/.env.prod
```

```bash
# Banco de Dados
DB_PASSWORD=senha_super_segura_banco_123!

# JWT
JWT_SECRET=jwt_secret_super_seguro_com_mais_de_32_caracteres_unicos_e_aleatorios

# WhatsApp
WHATSAPP_API_TOKEN=seu_token_api_whatsapp_business
WHATSAPP_PHONE_NUMBER_ID=seu_id_telefone_whatsapp
VERIFY_TOKEN=token_verificacao_webhook_unico_secreto

# N8N
N8N_USER=admin
N8N_PASSWORD=senha_n8n_super_segura_456
N8N_WEBHOOK_URL=https://seu-dominio.com/webhooks/n8n
N8N_API_KEY=api_key_n8n_super_secreta

# Email
SMTP_HOST=smtp.seu-dominio.com
SMTP_PORT=587
SMTP_USER=seu_email@seu-dominio.com
SMTP_PASS=sua_senha_app_segura

# Redis
REDIS_PASSWORD=senha_redis_super_segura_789
```

### 2. Configurar Log Rotation

```bash
# Criar configuração de log rotation
sudo nano /etc/logrotate.d/crm
```

```
/opt/crm-teste-n8n/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 deploy deploy
    postrotate
        docker-compose -f /opt/crm-teste-n8n/docker-compose.prod.yml restart backend
    endscript
}
```

## 📊 Monitoramento e Logs

### 1. Configurar Monitoramento com PM2

```bash
# Instalar PM2
sudo npm install -g pm2

# Criar arquivo de configuração PM2
sudo nano /opt/crm-teste-n8n/ecosystem.config.js
```

```javascript
module.exports = {
  apps: [{
    name: 'crm-backend',
    script: 'dist/index.js',
    cwd: '/opt/crm-teste-n8n/backend',
    instances: 2,
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3001
    },
    error_file: '/opt/crm-teste-n8n/logs/backend-error.log',
    out_file: '/opt/crm-teste-n8n/logs/backend-out.log',
    log_file: '/opt/crm-teste-n8n/logs/backend-combined.log',
    time: true,
    max_memory_restart: '1G',
    node_args: '--max_old_space_size=1024'
  }]
};
```

### 2. Configurar Backup Automático

```bash
# Criar script de backup
sudo nano /opt/scripts/backup-crm.sh
```

```bash
#!/bin/bash

BACKUP_DIR="/opt/backups/crm"
DATE=$(date +%Y%m%d_%H%M%S)
COMPOSE_FILE="/opt/crm-teste-n8n/docker-compose.prod.yml"

# Criar diretório de backup
mkdir -p $BACKUP_DIR

# Backup do banco de dados
docker-compose -f $COMPOSE_FILE exec -T db pg_dump -U crm_user crm_db > $BACKUP_DIR/db_backup_$DATE.sql

# Backup dos volumes
docker run --rm -v crm_postgres_data:/data -v $BACKUP_DIR:/backup ubuntu tar czf /backup/postgres_data_$DATE.tar.gz -C /data .
docker run --rm -v crm_n8n_data:/data -v $BACKUP_DIR:/backup ubuntu tar czf /backup/n8n_data_$DATE.tar.gz -C /data .

# Remover backups antigos (manter 7 dias)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup concluído: $DATE"
```

```bash
# Tornar executável e agendar
sudo chmod +x /opt/scripts/backup-crm.sh
sudo crontab -e
# Adicionar:
# 0 2 * * * /opt/scripts/backup-crm.sh >> /var/log/crm-backup.log 2>&1
```

## 🚀 Deploy Inicial

### 1. Preparar Ambiente

```bash
# Clonar repositório
git clone https://github.com/PedroPaduelo/crm-teste-n8n.git /opt/crm-teste-n8n
cd /opt/crm-teste-n8n

# Configurar permissões
sudo chown -R deploy:deploy /opt/crm-teste-n8n
chmod +x scripts/deploy-production.sh
```

### 2. Executar Deploy

```bash
# Executar script de deploy
./scripts/deploy-production.sh
```

### 3. Verificar Deploy

```bash
# Verificar containers
docker ps

# Verificar logs
docker-compose -f docker-compose.prod.yml logs -f

# Testar API
curl https://seu-dominio.com/api/health

# Testar Frontend
curl -I https://seu-dominio.com
```

## 🔧 Manutenção

### Atualizações

```bash
# Atualizar aplicação
cd /opt/crm-teste-n8n
git pull origin main
./scripts/deploy-production.sh
```

### Diagnóstico

```bash
# Verificar status
docker-compose -f docker-compose.prod.yml ps

# Verificar logs de erros
docker-compose -f docker-compose.prod.yml logs backend | grep ERROR

# Verificar performance
docker stats

# Verificar espaço em disco
df -h
```

### Recuperação de Desastres

```bash
# Restaurar banco de dados
docker-compose -f docker-compose.prod.yml exec -T db psql -U crm_user -d crm_db < /opt/backups/crm/db_backup_YYYYMMDD_HHMMSS.sql

# Reiniciar serviços
docker-compose -f docker-compose.prod.yml restart
```

## 📈 Performance e Otimização

### 1. Configurar CDN

```nginx
# Adicionar ao nginx.conf
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header X-Content-Type-Options nosniff;
    
    # CDN configuration
    proxy_cache_valid 200 1y;
    proxy_cache_valid 404 1m;
}
```

### 2. Configurar Redis para Cache

```javascript
// Adicionar ao backend
const redis = require('redis');
const client = redis.createClient({
  host: 'redis',
  port: 6379,
  password: process.env.REDIS_PASSWORD
});

// Cache de API
app.get('/api/clients', async (req, res) => {
  const cacheKey = 'clients:list';
  const cached = await client.get(cacheKey);
  
  if (cached) {
    return res.json(JSON.parse(cached));
  }
  
  const clients = await getClientsFromDB();
  await client.setex(cacheKey, 300, JSON.stringify(clients)); // 5 minutos
  res.json(clients);
});
```

## 📞 Suporte e Contato

### Emergências

1. **Servidor fora do ar**: Verificar logs e reiniciar serviços
2. **Banco de dados**: Restaurar do backup mais recente
3. **Performance**: Analisar logs e métricas
4. **Segurança**: Verificar tentativas de invasão

### Contatos

- **Suporte Técnico**: support@seu-dominio.com
- **Emergência**: emergency@seu-dominio.com
- **Documentação**: https://docs.seu-dominio.com

---

**Status: Produção** ✅
**Última Atualização: 2024**