# Guia de Deploy

Este documento contém instruções detalhadas para implantar o sistema CRM em diferentes ambientes.

## 🚀 Opções de Deploy

### 1. VPS (Servidor Privado Virtual)

#### Requisitos Mínimos
- **CPU**: 2 vCPUs
- **RAM**: 4GB
- **Storage**: 50GB SSD
- **SO**: Ubuntu 20.04+ / CentOS 8+

#### Passos para Deploy

1. **Preparar Servidor**:
```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Instalar PostgreSQL
sudo apt install postgresql postgresql-contrib

# Instalar Nginx
sudo apt install nginx

# Instalar PM2
sudo npm install -g pm2
```

2. **Configurar Banco de Dados**:
```bash
# Acessar PostgreSQL
sudo -u postgres psql

# Criar banco e usuário
CREATE DATABASE crm_db;
CREATE USER crm_user WITH PASSWORD 'senha_segura';
GRANT ALL PRIVILEGES ON DATABASE crm_db TO crm_user;
\q
```

3. **Clonar Projeto**:
```bash
# Criar diretório
sudo mkdir -p /var/www/crm
sudo chown $USER:$USER /var/www/crm

# Clonar repositório
cd /var/www/crm
git clone https://github.com/PedroPaduelo/crm-teste-n8n.git .
```

4. **Configurar Backend**:
```bash
cd backend
npm install --production

# Configurar variáveis de ambiente
cp .env.example .env
nano .env  # Editar com valores reais

# Build do projeto
npm run build

# Iniciar com PM2
pm2 start dist/index.js --name crm-backend
pm2 save
pm2 startup
```

5. **Configurar Frontend**:
```bash
cd ../frontend
npm install

# Build para produção
npm run build

# Configurar Nginx
sudo nano /etc/nginx/sites-available/crm
```

6. **Configurar Nginx**:
```nginx
server {
    listen 80;
    server_name seu-dominio.com;

    # Frontend
    location / {
        root /var/www/crm/frontend/dist;
        try_files $uri $uri/ /index.html;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:3001/health;
    }
}
```

7. **Ativar Site e HTTPS**:
```bash
# Ativar site
sudo ln -s /etc/nginx/sites-available/crm /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Instalar Certbot para HTTPS
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d seu-dominio.com
```

### 2. Heroku

#### Pré-requisitos
- Conta Heroku
- Heroku CLI instalada

#### Deploy

1. **Preparar Projeto**:
```bash
# Criar app Heroku
heroku create seu-nome-de-app

# Configurar variáveis de ambiente
heroku config:set NODE_ENV=production
heroku config:set DATABASE_URL=postgresql://usuario:senha@host:5432/dbname
heroku config:set JWT_SECRET=seu-segredo-jwt

# Configurar WhatsApp
heroku config:set WHATSAPP_API_TOKEN=seu-token
heroku config:set WHATSAPP_PHONE_NUMBER_ID=seu-id
heroku config:set VERIFY_TOKEN=seu-verify-token
```

2. **Criar arquivos Heroku**:

`Procfile`:
```
web: npm start
```

`heroku-postbuild` (em package.json scripts):
```json
{
  "scripts": {
    "heroku-postbuild": "npm run build"
  }
}
```

3. **Deploy**:
```bash
# Adicionar remote Heroku
heroku git:remote -a seu-nome-de-app

# Push para Heroku
git push heroku main

# Ver logs
heroku logs --tail
```

### 3. Docker

#### Criar Dockerfile para Backend

`backend/Dockerfile`:
```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copiar package files
COPY package*.json ./
RUN npm ci --only=production

# Copiar código fonte
COPY . .

# Build TypeScript
RUN npm run build

# Expor porta
EXPOSE 3001

# Iniciar aplicação
CMD ["npm", "start"]
```

#### Criar Dockerfile para Frontend

`frontend/Dockerfile`:
```dockerfile
FROM node:18-alpine as builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### Docker Compose

`docker-compose.yml`:
```yaml
version: '3.8'

services:
  db:
    image: postgres:13
    environment:
      POSTGRES_DB: crm_db
      POSTGRES_USER: crm_user
      POSTGRES_PASSWORD: senha_segura
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  backend:
    build: ./backend
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://crm_user:senha_segura@db:5432/crm_db
      JWT_SECRET: ${JWT_SECRET}
      WHATSAPP_API_TOKEN: ${WHATSAPP_API_TOKEN}
      WHATSAPP_PHONE_NUMBER_ID: ${WHATSAPP_PHONE_NUMBER_ID}
      VERIFY_TOKEN: ${VERIFY_TOKEN}
    depends_on:
      - db
    ports:
      - "3001:3001"

  frontend:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - backend

volumes:
  postgres_data:
```

#### Deploy com Docker
```bash
# Criar arquivo .env para variáveis
cat > .env << EOF
JWT_SECRET=seu-segredo-jwt
WHATSAPP_API_TOKEN=seu-token-whatsapp
WHATSAPP_PHONE_NUMBER_ID=seu-id-whatsapp
VERIFY_TOKEN=seu-verify-token
EOF

# Build e iniciar containers
docker-compose up -d

# Ver logs
docker-compose logs -f
```

### 4. Render.com

#### Backend Service

1. **Criar Web Service**:
   - Connect GitHub repository
   - Root directory: `backend`
   - Build command: `npm install && npm run build`
   - Start command: `npm start`

2. **Configurar Environment Variables**:
   ```
   NODE_ENV=production
   DATABASE_URL=postgresql://...
   JWT_SECRET=seu-segredo
   WHATSAPP_API_TOKEN=seu-token
   WHATSAPP_PHONE_NUMBER_ID=seu-id
   VERIFY_TOKEN=seu-verify-token
   ```

#### Frontend Service

1. **Criar Static Site**:
   - Connect GitHub repository
   - Root directory: `frontend`
   - Build command: `npm install && npm run build`
   - Publish directory: `dist`

2. **Configurar Redirects**:
   Criar arquivo `frontend/_redirects`:
   ```
   /*    /index.html   200
   /api/* https://seu-backend-url.herokuapp.com/api/:splat 200
   ```

### 5. Railway.app

#### Deploy

1. **Instalar Railway CLI**:
```bash
npm install -g @railway/cli
```

2. **Login e Deploy**:
```bash
railway login
railway init
railway up
```

3. **Configurar Variáveis**:
```bash
railway variables set NODE_ENV=production
railway variables set DATABASE_URL=postgresql://...
railway variables set JWT_SECRET=seu-segredo
# ... outras variáveis
```

## 🔧 Configurações Adicionais

### Backup Automático

#### Script de Backup PostgreSQL
```bash
#!/bin/bash
# backup.sh

DB_NAME="crm_db"
DB_USER="crm_user"
BACKUP_DIR="/var/backups/crm"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

pg_dump -U $DB_USER -h localhost $DB_NAME > $BACKUP_DIR/backup_$DATE.sql

# Manter apenas últimos 7 dias
find $BACKUP_DIR -name "backup_*.sql" -mtime +7 -delete

echo "Backup realizado: backup_$DATE.sql"
```

#### Agendar com Cron
```bash
# Editar crontab
crontab -e

# Adicionar linha para backup diário às 2h
0 2 * * * /var/www/crm/scripts/backup.sh
```

### Monitoramento

#### Instalar Node Exporter (Prometheus)
```bash
# Baixar node exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz

# Extrair e configurar
tar xvfz node_exporter-1.3.1.linux-amd64.tar.gz
sudo mv node_exporter-1.3.1.linux-amd64/node_exporter /usr/local/bin/
sudo useradd node_exporter --no-create-home --shell /bin/false

# Criar serviço systemd
sudo nano /etc/systemd/system/node_exporter.service
```

#### Configurar Serviço
```ini
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
```

#### Ativar e Iniciar
```bash
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
```

### Logs Centralizados

#### Configurar Log Rotation
```bash
sudo nano /etc/logrotate.d/crm
```

```
/var/log/crm/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        pm2 reload crm-backend
    endscript
}
```

## 🚨 Considerações de Segurança

### 1. Firewall
```bash
# Configurar UFW
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

### 2. Variáveis de Ambiente
- Nunca commitar `.env` no Git
- Use secrets manager em produção
- Rotacione chaves regularmente

### 3. SSL/TLS
- Use HTTPS em produção
- Renove certificados automaticamente
- Configure headers de segurança

### 4. Backup
- Backup diário do banco
- Backup de arquivos importantes
- Teste restauração regularmente

## 📊 Escalabilidade

### Horizontal Scaling

#### Load Balancer com Nginx
```nginx
upstream backend {
    server 127.0.0.1:3001;
    server 127.0.0.1:3002;
    server 127.0.0.1:3003;
}

server {
    listen 80;
    server_name seu-dominio.com;
    
    location /api {
        proxy_pass http://backend;
        # ... outras configurações
    }
}
```

#### PM2 Cluster Mode
```bash
# Iniciar em cluster mode
pm2 start dist/index.js -i max --name crm-backend-cluster
```

### Database Scaling

#### Read Replicas
```javascript
// Configurar pool de conexões
const Pool = require('pg').Pool;

const pool = new Pool({
  user: 'crm_user',
  host: 'localhost',
  database: 'crm_db',
  password: 'senha',
  port: 5432,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

## 🔄 CI/CD Pipeline

### GitHub Actions

`.github/workflows/deploy.yml`:
```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Deploy to server
      uses: appleboy/ssh-action@v0.1.4
      with:
        host: ${{ secrets.HOST }}
        username: ${{ secrets.USERNAME }}
        key: ${{ secrets.SSH_KEY }}
        script: |
          cd /var/www/crm
          git pull origin main
          cd backend
          npm install --production
          npm run build
          pm2 reload crm-backend
          cd ../frontend
          npm install
          npm run build
```

Este guia cobre os principais cenários de deploy. Escolha a opção que melhor se adapta às suas necessidades e orçamento.