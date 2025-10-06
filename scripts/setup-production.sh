#!/bin/bash

# Script de Configuração Inicial de Produção - CRM com N8N
# Autor: Equipe de Desenvolvimento
# Descrição: Script para configurar ambiente de produção do zero

set -e  # Exit on any error

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
PROJECT_NAME="crm-teste-n8n"
DEPLOY_DIR="/opt/$PROJECT_NAME"
DOMAIN="${1:-seu-dominio.com}"
EMAIL="${2:-admin@seu-dominio.com}"

# Função de log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Banner
banner() {
    echo -e "${BLUE}"
    echo "=============================================="
    echo "🚀 CRM com N8N - Configuração de Produção"
    echo "=============================================="
    echo "Domínio: $DOMAIN"
    echo "Email: $EMAIL"
    echo "Diretório: $DEPLOY_DIR"
    echo "=============================================="
    echo -e "${NC}"
}

# Verificar se está rodando como root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Este script deve ser executado como usuário com permissões sudo, não como root"
    fi
    
    # Verificar se tem sudo
    if ! sudo -n true 2>/dev/null; then
        log "Solicitando permissões sudo..."
        sudo true
    fi
}

# Atualizar sistema
update_system() {
    log "Atualizando sistema..."
    sudo apt-get update
    sudo apt-get upgrade -y
    success "Sistema atualizado"
}

# Instalar dependências
install_dependencies() {
    log "Instalando dependências..."
    
    # Adicionar repositórios
    sudo apt-get install -y curl wget git software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    
    # Instalar Docker
    if ! command -v docker &> /dev/null; then
        log "Instalando Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        success "Docker instalado"
    else
        log "Docker já está instalado"
    fi
    
    # Instalar Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log "Instalando Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        success "Docker Compose instalado"
    else
        log "Docker Compose já está instalado"
    fi
    
    # Instalar Node.js
    if ! command -v node &> /dev/null; then
        log "Instalando Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
        success "Node.js instalado"
    else
        log "Node.js já está instalado"
    fi
    
    # Instalar Nginx e Certbot
    sudo apt-get install -y nginx certbot python3-certbot-nginx htop ufail2ban
    
    # Instalar ferramentas úteis
    sudo apt-get install -y zip unzip tree jq
    
    success "Dependências instaladas"
}

# Configurar firewall
configure_firewall() {
    log "Configurando firewall..."
    
    # Configurar UFW
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw --force enable
    
    success "Firewall configurado"
}

# Criar estrutura de diretórios
create_directories() {
    log "Criando estrutura de diretórios..."
    
    # Diretórios principais
    sudo mkdir -p $DEPLOY_DIR
    sudo mkdir -p $DEPLOY_DIR/data/{postgres,n8n,redis,pgadmin}
    sudo mkdir -p $DEPLOY_DIR/logs/{nginx,app}
    sudo mkdir -p $DEPLOY_DIR/ssl
    sudo mkdir -p $DEPLOY_DIR/nginx/conf.d
    sudo mkdir -p $DEPLOY_DIR/backups
    sudo mkdir -p $DEPLOY_DIR/scripts
    
    # Diretórios de logs
    sudo mkdir -p /var/log/$PROJECT_NAME
    
    # Configurar permissões
    sudo chown -R $USER:$USER $DEPLOY_DIR
    sudo chown -R $USER:$USER /var/log/$PROJECT_NAME
    
    success "Estrutura de diretórios criada"
}

# Configurar Nginx
configure_nginx() {
    log "Configurando Nginx..."
    
    # Backup da configuração original
    sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
    
    # Criar configuração principal
    sudo tee /etc/nginx/nginx.conf > /dev/null <<EOF
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone \$binary_remote_addr zone=login:10m rate=1r/s;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    # Include configurations
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

    # Criar configuração do site
    sudo tee $DEPLOY_DIR/nginx/conf.d/crm.conf > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}
EOF

    # Criar link simbólico
    sudo ln -sf $DEPLOY_DIR/nginx/conf.d/crm.conf /etc/nginx/sites-enabled/crm.conf
    
    # Remover configuração default
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Testar configuração
    sudo nginx -t
    
    success "Nginx configurado"
}

# Obter certificado SSL
obtain_ssl() {
    log "Obtendo certificado SSL..."
    
    # Criar diretório para certbot
    sudo mkdir -p /var/www/certbot
    
    # Obter certificado
    sudo certbot certonly --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --no-eff-email --non-interactive
    
    # Configurar renovação automática
    sudo crontab -l | grep -q "certbot renew" || (sudo crontab -l; echo "0 12 * * * /usr/bin/certbot renew --quiet --post-hook 'systemctl reload nginx'") | sudo crontab -
    
    # Atualizar configuração Nginx com SSL
    sudo tee $DEPLOY_DIR/nginx/conf.d/crm.conf > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    
    # Rate limiting
    limit_req zone=api burst=20 nodelay;
    
    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    
    # Frontend
    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        
        # Static assets cache
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            add_header X-Content-Type-Options nosniff;
        }
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

    # Recarregar Nginx
    sudo systemctl reload nginx
    
    success "Certificado SSL obtido e configurado"
}

# Clonar repositório
clone_repository() {
    log "Clonando repositório..."
    
    cd $DEPLOY_DIR
    
    if [ -d ".git" ]; then
        log "Repositório já existe, atualizando..."
        git fetch origin
        git reset --hard origin/main
    else
        log "Clonando repositório..."
        git clone https://github.com/PedroPaduelo/crm-teste-n8n.git .
    fi
    
    success "Repositório clonado/atualizado"
}

# Configurar variáveis de ambiente
configure_environment() {
    log "Configurando variáveis de ambiente..."
    
    # Criar arquivo .env.production
    if [ ! -f "$DEPLOY_DIR/.env.production" ]; then
        cat > $DEPLOY_DIR/.env.production <<EOF
# Configurações de Produção - CRM com N8N
# Gerado automaticamente em $(date)

# Domínio
DOMAIN=$DOMAIN

# Banco de Dados
DB_PASSWORD=$(openssl rand -base64 32)
POSTGRES_DB=crm_db
POSTGRES_USER=crm_user

# JWT
JWT_SECRET=$(openssl rand -base64 64)

# WhatsApp (configure com suas credenciais)
WHATSAPP_API_TOKEN=seu-token-api-whatsapp
WHATSAPP_PHONE_NUMBER_ID=seu-id-telefone-whatsapp
VERIFY_TOKEN=$(openssl rand -base64 32)

# N8N
N8N_USER=admin
N8N_PASSWORD=$(openssl rand -base64 16)
N8N_WEBHOOK_URL=https://$DOMAIN/webhooks/n8n
N8N_API_KEY=$(openssl rand -base64 32)

# Email (configure com suas credenciais)
SMTP_HOST=smtp.$(echo $DOMAIN | cut -d'.' -f2-)
SMTP_PORT=587
SMTP_USER=noreply@$DOMAIN
SMTP_PASS=sua-senha-email

# Frontend
VITE_API_URL=https://$DOMAIN/api
VITE_N8N_WEBHOOK_URL=https://$DOMAIN/webhooks/n8n
FRONTEND_URL=https://$DOMAIN

# Redis
REDIS_PASSWORD=$(openssl rand -base64 32)

# PgAdmin
PGADMIN_EMAIL=$EMAIL
PGADMIN_PASSWORD=$(openssl rand -base64 16)

# Upload
UPLOAD_MAX_SIZE=10485760
UPLOAD_ALLOWED_TYPES=image/jpeg,image/png,image/gif,application/pdf

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Logs
LOG_LEVEL=info
EOF
        
        warning "Arquivo .env.production criado. Por favor, edite as configurações do WhatsApp e Email:"
        warning "nano $DEPLOY_DIR/.env.production"
    fi
    
    # Carregar variáveis de ambiente
    set -a
    source $DEPLOY_DIR/.env.production
    set +a
    
    success "Variáveis de ambiente configuradas"
}

# Configurar serviços do sistema
configure_services() {
    log "Configurando serviços do sistema..."
    
    # Habilitar serviços
    sudo systemctl enable docker
    sudo systemctl enable nginx
    sudo systemctl enable certbot.timer
    
    # Configurar logrotate para o projeto
    sudo tee /etc/logrotate.d/$PROJECT_NAME > /dev/null <<EOF
$DEPLOY_DIR/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 $USER $USER
    postrotate
        docker-compose -f $DEPLOY_DIR/docker-compose.prod.yml restart backend
    endscript
}

/var/log/$PROJECT_NAME/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 $USER $USER
}
EOF

    # Configurar fail2ban
    sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 3
EOF

    sudo systemctl restart fail2ban
    
    success "Serviços configurados"
}

# Criar scripts de manutenção
create_maintenance_scripts() {
    log "Criando scripts de manutenção..."
    
    # Script de backup
    cat > $DEPLOY_DIR/scripts/backup.sh <<'EOF'
#!/bin/bash
set -e

BACKUP_DIR="/opt/crm-teste-n8n/backups"
DATE=$(date +%Y%m%d_%H%M%S)
COMPOSE_FILE="/opt/crm-teste-n8n/docker-compose.prod.yml"

mkdir -p $BACKUP_DIR

# Backup do banco de dados
docker-compose -f $COMPOSE_FILE exec -T db pg_dump -U crm_user crm_db > $BACKUP_DIR/db_backup_$DATE.sql

# Backup dos volumes
docker run --rm -v crm_postgres_data:/data -v $BACKUP_DIR:/backup ubuntu tar czf /backup/postgres_data_$DATE.tar.gz -C /data .
docker run --rm -v crm_n8n_data:/data -v $BACKUP_DIR:/backup ubuntu tar czf /backup/n8n_data_$DATE.tar.gz -C /data .

# Remover backups antigos
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup concluído: $DATE"
EOF

    # Script de monitoramento
    cat > $DEPLOY_DIR/scripts/monitor.sh <<'EOF'
#!/bin/bash

COMPOSE_FILE="/opt/crm-teste-n8n/docker-compose.prod.yml"
LOG_FILE="/var/log/crm-teste-n8n/monitor.log"

# Verificar containers
if ! docker-compose -f $COMPOSE_FILE ps | grep -q "Up"; then
    echo "$(date): ALguns containers estão down" >> $LOG_FILE
    docker-compose -f $COMPOSE_FILE restart
fi

# Verificar health check
if ! curl -f http://localhost/api/health >/dev/null 2>&1; then
    echo "$(date): Health check falhou" >> $LOG_FILE
    docker-compose -f $COMPOSE_FILE restart backend
fi

# Verificar espaço em disco
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "$(date): Uso de disco alto: $DISK_USAGE%" >> $LOG_FILE
fi

echo "$(date): Monitoramento concluído" >> $LOG_FILE
EOF

    # Tornar scripts executáveis
    chmod +x $DEPLOY_DIR/scripts/*.sh
    
    # Agendar scripts
    (crontab -l 2>/dev/null; echo "0 2 * * * $DEPLOY_DIR/scripts/backup.sh >> /var/log/crm-teste-n8n/backup.log 2>&1") | crontab -
    (crontab -l 2>/dev/null; echo "*/5 * * * * $DEPLOY_DIR/scripts/monitor.sh") | crontab -
    
    success "Scripts de manutenção criados"
}

# Executar deploy inicial
deploy_initial() {
    log "Executando deploy inicial..."
    
    cd $DEPLOY_DIR
    
    # Copiar arquivos de ambiente
    cp backend/.env.production.example backend/.env 2>/dev/null || true
    cp frontend/.env.production.example frontend/.env 2>/dev/null || true
    
    # Iniciar serviços
    docker-compose -f docker-compose.prod.yml up -d
    
    # Aguardar serviços iniciarem
    log "Aguardando serviços iniciarem..."
    sleep 60
    
    # Verificar se tudo está funcionando
    if curl -f http://localhost/api/health >/dev/null 2>&1; then
        success "Backend está funcionando"
    else
        error "Backend não está funcionando"
    fi
    
    if curl -f https://$DOMAIN/api/health >/dev/null 2>&1; then
        success "Aplicação está acessível via HTTPS"
    else
        warning "Aplicação pode não estar acessível externamente ainda"
    fi
    
    success "Deploy inicial concluído"
}

# Resumo final
summary() {
    log "Criando resumo da instalação..."
    
    cat > $DEPLOY_DIR/INSTALLATION_SUMMARY.md <<EOF
# Resumo da Instalação - CRM com N8N

## 📅 Data da Instalação
$(date)

## 🌐 Domínio
- **Frontend**: https://$DOMAIN
- **Backend API**: https://$DOMAIN/api
- **Health Check**: https://$DOMAIN/api/health
- **N8N**: https://n8n.$DOMAIN (usuário: admin)

## 📁 Diretórios Importantes
- **Projeto**: $DEPLOY_DIR
- **Logs**: $DEPLOY_DIR/logs
- **Backups**: $DEPLOY_DIR/backups
- **SSL**: /etc/letsencrypt/live/$DOMAIN
- **Nginx**: $DEPLOY_DIR/nginx/conf.d

## 🔧 Comandos Úteis

### Verificar status
\`\`\`bash
cd $DEPLOY_DIR
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs -f
\`\`\`

### Reiniciar serviços
\`\`\`bash
cd $DEPLOY_DIR
docker-compose -f docker-compose.prod.yml restart
\`\`\`

### Backup manual
\`\`\`bash
$DEPLOY_DIR/scripts/backup.sh
\`\`\`

### Atualizar aplicação
\`\`\`bash
cd $DEPLOY_DIR
git pull origin main
docker-compose -f docker-compose.prod.yml up -d --build
\`\`\`

## 🔐 Acessos

### N8N
- **URL**: https://n8n.$DOMAIN
- **Usuário**: admin
- **Senha**: Verifique em .env.production

### PgAdmin
- **Container**: crm_pgadmin_prod
- **Email**: $EMAIL
- **Senha**: Verifique em .env.production

## 📊 Monitoramento

### Logs
- **Aplicação**: $DEPLOY_DIR/logs/app/
- **Nginx**: $DEPLOY_DIR/logs/nginx/
- **Sistema**: /var/log/crm-teste-n8n/

### Scripts automáticos
- **Backup**: Diário às 02:00
- **Monitoramento**: A cada 5 minutos

## 🚨 Ações Pós-Instalação

1. **Configurar WhatsApp Business**:
   - Edite \`backend/.env\` com suas credenciais
   - Configure webhook no Meta for Developers
   - URL: https://$DOMAIN/api/whatsapp/webhook

2. **Configurar Email**:
   - Edite \`backend/.env\` com suas credenciais SMTP
   - Teste envio de emails

3. **Configurar N8N**:
   - Acesse https://n8n.$DOMAIN
   - Crie seus workflows de automação
   - Configure webhooks na aplicação

4. **Configurar Backup Externo**:
   - Configure backup para nuvem (AWS S3, Google Drive, etc.)
   - Teste restauração

5. **Configurar Monitoramento**:
   - Configure alertas por email
   - Monitore métricas de performance

## 📞 Suporte

- **Documentação**: $DEPLOY_DIR/docs/
- **Logs de erro**: $DEPLOY_DIR/logs/app/error.log
- **System logs**: /var/log/crm-teste-n8n/

---

**Instalação concluída com sucesso! 🎉**
EOF

    success "Resumo criado em $DEPLOY_DIR/INSTALLATION_SUMMARY.md"
}

# Função principal
main() {
    banner
    check_root
    update_system
    install_dependencies
    configure_firewall
    create_directories
    configure_nginx
    obtain_ssl
    clone_repository
    configure_environment
    configure_services
    create_maintenance_scripts
    deploy_initial
    summary
    
    success "Configuração de produção concluída com sucesso! 🚀"
    
    echo ""
    echo "=============================================="
    echo "🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
    echo "=============================================="
    echo "🌐 Frontend: https://$DOMAIN"
    echo "🔧 Backend API: https://$DOMAIN/api"
    echo "💚 Health Check: https://$DOMAIN/api/health"
    echo "⚙️  N8N: https://n8n.$DOMAIN"
    echo "📋 Resumo completo: $DEPLOY_DIR/INSTALLATION_SUMMARY.md"
    echo "=============================================="
    echo ""
    warning "⚠️  AÇÕES NECESSÁRIAS:"
    echo "1. Configure suas credenciais WhatsApp em $DEPLOY_DIR/backend/.env"
    echo "2. Configure suas credenciais Email em $DEPLOY_DIR/backend/.env"
    echo "3. Verifique o resumo completo em $DEPLOY_DIR/INSTALLATION_SUMMARY.md"
    echo "4. Configure backup externo e monitoramento"
    echo ""
}

# Executar função principal
main "$@"