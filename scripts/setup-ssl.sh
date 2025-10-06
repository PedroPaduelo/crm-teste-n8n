#!/bin/bash

# Script de Configuração Automática de SSL com Let's Encrypt
# Uso: ./scripts/setup-ssl.sh seu-dominio.com

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar argumentos
if [ $# -eq 0 ]; then
    log_error "Por favor, forneça o domínio como argumento"
    echo "Uso: $0 seu-dominio.com"
    exit 1
fi

DOMAIN=$1
EMAIL=${2:-admin@$DOMAIN}

log_info "Configurando SSL para o domínio: $DOMAIN"
log_info "Email para certificado: $EMAIL"

# Verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    # Verificar se está rodando como root
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script precisa ser executado como root (sudo)"
        exit 1
    fi
    
    # Verificar se o domínio está configurado
    if ! nslookup $DOMAIN > /dev/null 2>&1; then
        log_error "Domínio $DOMAIN não está configurado ou não aponta para este servidor"
        exit 1
    fi
    
    # Verificar porta 80
    if ! nc -z localhost 80 > /dev/null 2>&1; then
        log_error "Porta 80 não está aberta. O servidor web precisa estar rodando."
        exit 1
    fi
    
    log_success "Pré-requisitos verificados"
}

# Instalar Certbot
install_certbot() {
    log_info "Instalando Certbot..."
    
    # Detectar sistema operacional
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        apt update
        apt install -y certbot python3-certbot-nginx
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL
        yum install -y epel-release
        yum install -y certbot python3-certbot-nginx
    else
        log_error "Sistema operacional não suportado"
        exit 1
    fi
    
    log_success "Certbot instalado"
}

# Criar configuração Nginx para SSL
create_nginx_ssl_config() {
    log_info "Criando configuração Nginx para SSL..."
    
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    
    cat > /etc/nginx/sites-available/$DOMAIN << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    # Redirecionar para HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    # Frontend
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # API Backend
    location /api {
        proxy_pass http://localhost:3001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Webhooks
    location /webhook {
        proxy_pass http://localhost:3001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

    # Habilitar site
    ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
    
    # Remover default site se existir
    rm -f /etc/nginx/sites-enabled/default
    
    log_success "Configuração Nginx criada"
}

# Obter certificado SSL
obtain_ssl_certificate() {
    log_info "Obtendo certificado SSL para $DOMAIN..."
    
    # Parar Nginx temporariamente se estiver rodando
    systemctl stop nginx 2>/dev/null || true
    
    # Obter certificado
    certbot certonly --standalone \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        -d $DOMAIN \
        -d www.$DOMAIN
    
    log_success "Certificado SSL obtido"
}

# Configurar renovação automática
setup_auto_renewal() {
    log_info "Configurando renovação automática do certificado..."
    
    # Adicionar cron job para renovação
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet --nginx") | crontab -
    
    # Testar renovação
    certbot renew --dry-run
    
    log_success "Renovação automática configurada"
}

# Atualizar Docker Compose para SSL
update_docker_compose() {
    log_info "Atualizando Docker Compose para SSL..."
    
    # Criar cópia de backup
    cp docker-compose.yml docker-compose.yml.backup
    
    # Atualizar configuração do frontend para expor portas 8080 e 443
    sed -i 's/ports:/# SSL Configuration - ports:/' docker-compose.yml
    sed -i '/frontend:/,/^[[:space:]]*[^[:space:]]/ s/ports:/# Original ports/' docker-compose.yml
    
    log_success "Docker Compose atualizado"
}

# Reiniciar serviços
restart_services() {
    log_info "Reiniciando serviços..."
    
    # Testar configuração Nginx
    nginx -t
    
    # Iniciar Nginx
    systemctl start nginx
    systemctl enable nginx
    
    # Reiniciar containers Docker
    docker-compose down
    docker-compose up -d
    
    log_success "Serviços reiniciados"
}

# Verificar instalação
verify_ssl() {
    log_info "Verificando instalação SSL..."
    
    # Esperar um momento para serviços iniciarem
    sleep 10
    
    # Verificar se o certificado foi instalado
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        log_success "Certificado SSL instalado corretamente"
    else
        log_error "Certificado SSL não encontrado"
        exit 1
   
    
    # Verificar se o site está acessível via HTTPS
    if curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN | grep -q "200"; then
        log_success "Site está acessível via HTTPS"
    else
        log_warning "Site pode não estar acessível via HTTPS. Verifique configuração."
    fi
    
    # Verificar validade do certificado
    if openssl x509 -checkend 86400 -noout -in /etc/letsencrypt/live/$DOMAIN/cert.pem; then
        log_success "Certificado é válido por pelo menos 24 horas"
    else
        log_warning "Certificado expira em menos de 24 horas"
    fi
}

# Função principal
main() {
    log_info "Iniciando configuração SSL para $DOMAIN"
    
    check_prerequisites
    install_certbot
    create_nginx_ssl_config
    obtain_ssl_certificate
    setup_auto_renewal
    update_docker_compose
    restart_services
    verify_ssl
    
    echo ""
    echo "=================================="
    log_success "Configuração SSL concluída!"
    echo "=================================="
    echo ""
    echo "Seu site agora está disponível em:"
    echo "  • https://$DOMAIN"
    echo "  • https://www.$DOMAIN"
    echo ""
    echo "Informações do certificado:"
    echo "  • Local: /etc/letsencrypt/live/$DOMAIN/"
    echo "  • Renovação automática: Configurada (diária)"
    echo "  • Próxima verificação: $(date -d "+1 day" "+%H:%M %d/%m/%Y")"
    echo ""
    echo "Comandos úteis:"
    echo "  • Verificar status: systemctl status nginx"
    echo "  • Verificar logs: tail -f /var/log/nginx/access.log"
    echo "  • Renovar manualmente: certbot renew"
    echo "  • Testar configuração: nginx -t"
    echo ""
}

# Executar script
main "$@"