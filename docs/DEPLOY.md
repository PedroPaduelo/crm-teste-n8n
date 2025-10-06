# Guia de Deploy - CRM com N8N

Guia completo para deploy do sistema CRM com integração N8N em diferentes ambientes.

## 📋 Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Configuração de Ambiente](#configuração-de-ambiente)
3. [Deploy Local com Docker](#deploy-local-com-docker)
4. [Deploy em Produção](#deploy-em-produção)
5. [Configuração de Banco de Dados](#configuração-de-banco-de-dados)
6. [Configuração de Domínio e SSL](#configuração-de-domínio-e-ssl)
7. [Monitoramento e Logs](#monitoramento-e-logs)
8. [Backup e Segurança](#backup-e-segurança)

## 🔧 Pré-requisitos

### Sistema Operacional
- Linux (Ubuntu 20.04+ recomendado)
- macOS 10.15+
- Windows 10+ (com WSL2)

### Software Necessário
- Docker e Docker Compose
- Node.js 18+ (para deploy sem Docker)
- PostgreSQL 13+ (banco de dados)
- Nginx (servidor web)
- Git

### Contas e Serviços
- Meta for Developers (WhatsApp Business API)
- N8N Cloud ou auto-hospedado
- Provedor de hospedagem (VPS, Cloud, etc.)

## 🌍 Configuração de Ambiente

### 1. Clonar o Repositório

```bash
git clone https://github.com/PedroPaduelo/crm-teste-n8n.git
cd crm-teste-n8n
```

### 2. Configurar Variáveis de Ambiente

#### Backend
```bash
cd backend
cp .env.example .env
```

Configure as variáveis essenciais:
```env
# Ambiente
NODE_ENV=production
PORT=3001

# Banco de Dados
DATABASE_URL=postgresql://user:password@localhost:5432/crm_db

# JWT
JWT_SECRET=your-super-secret-jwt-key-min-32-characters

# WhatsApp
WHATSAPP_API_TOKEN=your-whatsapp-api-token
WHATSAPP_PHONE_NUMBER_ID=your-whatsapp-phone-number-id
VERIFY_TOKEN=your-webhook-verify-token

# Frontend URL
FRONTEND_URL=https://seu-dominio.com

# N8N
N8N_WEBHOOK_URL=https://seu-n8n.com/webhook
N8N_API_KEY=your-n8n-api-key

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=seu-email@gmail.com
SMTP_PASS=sua-app-password
```

#### Frontend
```bash
cd frontend
cp .env.example .env
```

Configure as variáveis essenciais:
```env
VITE_API_URL=https://api.seu-dominio.com
VITE_N8N_WEBHOOK_URL=https://seu-n8n.com/webhook
VITE_NODE_ENV=production
```

## 🐳 Deploy Local com Docker

### 1. Criar Docker Compose

Crie o arquivo `docker-compose.yml` na raiz do projeto:

```yaml
version: '3.8'

services:
  # Banco de Dados PostgreSQL
  db:
    image: postgres:15
    container_name: crm_db
    restart: unless-stopped
    environment:
      POSTGRES_DB: crm_db
      POSTGRES_USER: crm_user
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    networks:
      - crm_network

  # Backend API
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: crm_backend
    restart: unless-stopped
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://crm_user:${DB_PASSWORD}@db:5432/crm_db
      JWT_SECRET: ${JWT_SECRET}
      WHATSAPP_API_TOKEN: ${WHATSAPP_API_TOKEN}
      WHATSAPP_PHONE_NUMBER_ID: ${WHATSAPP_PHONE_NUMBER_ID}
      VERIFY_TOKEN: ${VERIFY_TOKEN}
      FRONTEND_URL: ${FRONTEND_URL}
    depends_on:
      - db
    ports:
      - "3001:3001"
    volumes:
      - ./backend/uploads:/app/uploads
    networks:
      - crm_network

  # Frontend
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: crm_frontend
    restart: unless-stopped
    environment:
      VITE_API_URL: ${FRONTEND_API_URL}
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - crm_network

  # N8N (opcional)
  n8n:
    image: n8nio/n8n:latest
    container_name: crm_n8n
    restart: unless-stopped
    environment:
      N8N_BASIC_AUTH_ACTIVE: true
      N8N_BASIC_AUTH_USER: ${N8N_USER}
      N8N_BASIC_AUTH_PASSWORD: ${N8N_PASSWORD}
      WEBHOOK_URL: https://seu-dominio.com/webhook
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - crm_network

volumes:
  postgres_data:
  n8n_data:

networks:
  crm_network:
    driver: bridge
```

### 2. Criar Dockerfiles

#### Backend Dockerfile
Crie `backend/Dockerfile`:

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copiar package files
COPY package*.json ./
RUN npm ci --only=production

# Copiar código fonte
COPY . .

# Compilar TypeScript
RUN npm run build

# Criar diretório de uploads
RUN mkdir -p uploads

# Expor porta
EXPOSE 3001

# Comando de start
CMD ["npm", "start"]
```

#### Frontend Dockerfile
Crie `frontend/Dockerfile`:

```dockerfile
FROM node:18-alpine as builder

WORKDIR /app

# Copiar package files
COPY package*.json ./
RUN npm ci

# Copiar código e build
COPY . .
RUN npm run build

# Servir com Nginx
FROM nginx:alpine

# Copiar build
COPY --from=builder /app/dist /usr/share/nginx/html

# Copiar configuração Nginx
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### 3. Configurar Nginx

Crie `frontend/nginx.conf`:

```nginx
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;

        # Servir arquivos estáticos
        location / {
            try_files $uri $uri/ /index.html;
        }

        # Proxy para API
        location /api {
            proxy_pass http://backend:3001;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Webhook para WhatsApp
        location /webhook {
            proxy_pass http://backend:3001;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

### 4. Deploy com Docker

```bash
# Criar arquivo .env com variáveis
echo "DB_PASSWORD=senha_segura" >> .env
echo "JWT_SECRET=jwt_super_secreto_min_32_chars" >> .env
echo "FRONTEND_URL=https://seu-dominio.com" >> .env
echo "FRONTEND_API_URL=https://api.seu-dominio.com" >> .env

# Iniciar containers
docker-compose up -d

# Verificar logs
docker-compose logs -f
```

## 🚀 Deploy em Produção

### Opção 1: VPS com Docker

1. **Configurar Servidor**
```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

2. **Configurar Firewall**
```bash
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw enable
```

3. **Deploy**
```bash
# Clonar repositório
git clone https://github.com/PedroPaduelo/crm-teste-n8n.git
cd crm-teste-n8n

# Configurar variáveis
cp .env.example .env
# Editar .env com valores de produção

# Iniciar containers
docker-compose up -d
```

### Opção 2: AWS ECS

1. **Criar Cluster ECS**
2. **Configurar Task Definitions**
3. **Criar Service com Load Balancer**
4. **Configurar Auto Scaling**

### Opção 3: Google Cloud Run

#### Backend
```bash
# Build e push da imagem
cd backend
gcloud builds submit --tag gcr.io/PROJECT-ID/crm-backend

# Deploy
gcloud run deploy crm-backend \
  --image gcr.io/PROJECT-ID/crm-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars NODE_ENV=production
```

#### Frontend
```bash
cd frontend
npm run build

# Deploy no Firebase Hosting
firebase deploy

# Ou no Vercel
vercel --prod
```

### Opção 4: Heroku

```bash
# Instalar Heroku CLI
# Login no Heroku
heroku login

# Criar app
heroku create crm-sistema

# Configurar variáveis
heroku config:set NODE_ENV=production
heroku config:set DATABASE_URL=postgresql://...
heroku config:set JWT_SECRET=seu-jwt-secret

# Deploy
git subtree push --prefix backend heroku main
```

## 🗄️ Configuração de Banco de Dados

### PostgreSQL Production

1. **Instalar PostgreSQL**
```bash
sudo apt install postgresql postgresql-contrib
```

2. **Criar Banco e Usuário**
```bash
sudo -u postgres psql
CREATE DATABASE crm_db;
CREATE USER crm_user WITH PASSWORD 'senha_segura';
GRANT ALL PRIVILEGES ON DATABASE crm_db TO crm_user;
\q
```

3. **Configurar Acesso Remoto**
```bash
sudo nano /etc/postgresql/15/main/postgresql.conf
# Descomentar: listen_addresses = 'localhost'

sudo nano /etc/postgresql/15/main/pg_hba.conf
# Adicionar: host crm_db crm_user 0.0.0.0/0 md5

sudo systemctl restart postgresql
```

### Backup Automático

Crie script `backup.sh`:
```bash
#!/bin/bash

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/crm"
DB_NAME="crm_db"
DB_USER="crm_user"

mkdir -p $BACKUP_DIR

pg_dump -U $DB_USER -h localhost $DB_NAME > $BACKUP_DIR/backup_$DATE.sql

# Manter últimos 7 dias
find $BACKUP_DIR -name "backup_*.sql" -mtime +7 -delete

echo "Backup realizado: backup_$DATE.sql"
```

Adicionar ao crontab:
```bash
crontab -e
# Adicionar: 0 2 * * * /path/to/backup.sh
```

## 🌐 Configuração de Domínio e SSL

### 1. Configurar Nginx

Crie `/etc/nginx/sites-available/crm`:
```nginx
server {
    listen 80;
    server_name seu-dominio.com api.seu-dominio.com;

    # Redirecionar para HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name seu-dominio.com;

    # SSL
    ssl_certificate /etc/letsencrypt/live/seu-dominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/seu-dominio.com/privkey.pem;

    # Headers de segurança
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    # Frontend
    root /var/www/crm/frontend/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}

server {
    listen 443 ssl http2;
    server_name api.seu-dominio.com;

    # SSL
    ssl_certificate /etc/letsencrypt/live/seu-dominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/seu-dominio.com/privkey.pem;

    # API
    location / {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 2. Instalar Certificado SSL

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx

# Gerar certificado
sudo certbot --nginx -d seu-dominio.com -d api.seu-dominio.com

# Renovação automática
sudo crontab -e
# Adicionar: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 📊 Monitoramento e Logs

### 1. Configurar PM2 (sem Docker)

```bash
# Instalar PM2 globalmente
npm install -g pm2

# Criar arquivo ecosystem.config.js
module.exports = {
  apps: [{
    name: 'crm-backend',
    script: 'dist/index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3001
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};

# Iniciar aplicação
pm2 start ecosystem.config.js

# Salvar configuração
pm2 save

# Iniciar no boot
pm2 startup
```

### 2. Monitoramento com Docker

```bash
# Ver status dos containers
docker-compose ps

# Ver logs
docker-compose logs -f backend
docker-compose logs -f frontend

# Monitorar recursos
docker stats
```

### 3. Health Checks

Adicionar endpoint health no backend:
```typescript
// src/routes/health.ts
import { Router } from 'express';
import pg from 'pg';

const router = Router();

router.get('/health', async (req, res) => {
  try {
    // Testar conexão com banco
    const client = new pg.Client({
      connectionString: process.env.DATABASE_URL
    });
    await client.connect();
    await client.query('SELECT 1');
    await client.end();

    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: 'connected'
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      error: error.message
    });
  }
});

export default router;
```

## 🔒 Backup e Segurança

### 1. Segurança do Servidor

```bash
# Criar usuário deploy
sudo adduser deploy
sudo usermod -aG sudo deploy

# Configurar SSH com chaves
sudo nano /etc/ssh/sshd_config
# PasswordAuthentication no
# PubkeyAuthentication yes

# Reiniciar SSH
sudo systemctl restart ssh

# Configurar fail2ban
sudo apt install fail2ban
sudo systemctl enable fail2ban
```

### 2. Backup Completo

Script `full-backup.sh`:
```bash
#!/bin/bash

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/crm"

# Backup do banco
docker exec crm_db pg_dump -U crm_user crm_db > $BACKUP_DIR/db_backup_$DATE.sql

# Backup dos arquivos
tar -czf $BACKUP_DIR/files_backup_$DATE.tar.gz \
  /path/to/crm-teste-n8n \
  /etc/nginx/sites-available/crm

# Upload para S3 (opcional)
aws s3 cp $BACKUP_DIR/db_backup_$DATE.sql s3://seu-bucket/backups/
aws s3 cp $BACKUP_DIR/files_backup_$DATE.tar.gz s3://seu-bucket/backups/

# Limpar backups antigos
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Backup completo realizado: $DATE"
```

### 3. Variáveis de Ambiente Seguras

```bash
# Usar Docker secrets ou AWS Secrets Manager
# Nunca commitar .env no versionamento

# Exemplo com AWS Secrets Manager
aws secretsmanager create-secret \
  --name crm/database-url \
  --secret-string "postgresql://user:pass@host:5432/db"

# Na aplicação, usar SDK para buscar o secret
```

## ✅ Checklist de Deploy

- [ ] Configurar variáveis de ambiente
- [ ] Build da aplicação
- [ ] Configurar banco de dados
- [ ] Configurar servidor web (Nginx)
- [ ] Instalar certificado SSL
- [ ] Configurar backups automáticos
- [ ] Configurar monitoramento
- [ ] Testar webhooks
- [ ] Configurar domínios
- [ ] Testar funcionamento completo
- [ ] Documentar processo

## 🚨 Solução de Problemas

### Erros Comuns

1. **CORS Error**
   - Verificar configuração de CORS no backend
   - Configurar FRONTEND_URL corretamente

2. **Database Connection Failed**
   - Verificar string de conexão
   - Testar conectividade com banco

3. **Webhook Not Working**
   - Verificar URL e token do webhook
   - Testar com ngrok em desenvolvimento

4. **Build Failed**
   - Verificar dependências
   - Limpar cache: `npm cache clean --force`

### Logs Úteis

```bash
# Logs do PM2
pm2 logs crm-backend

# Logs do Docker
docker-compose logs -f

# Logs do Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Logs do PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-15-main.log
```

---

## 📞 Suporte

Para dúvidas sobre o deploy:

1. Consulte a documentação específica
2. Verifique os logs de erro
3. Abra uma Issue no GitHub
4. Contate a equipe de suporte

**Deploy concluído com sucesso! 🎉**