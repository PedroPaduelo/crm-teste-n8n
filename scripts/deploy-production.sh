#!/bin/bash

# Script de Deploy para Produção - CRM com N8N
# Autor: Equipe de Desenvolvimento
# Descrição: Script automatizado para deploy em produção

set -e  # Exit on any error

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Configurações
PROJECT_NAME="crm-teste-n8n"
BACKUP_DIR="/opt/backups/$PROJECT_NAME"
DEPLOY_DIR="/opt/$PROJECT_NAME"
LOG_FILE="/var/log/$PROJECT_NAME/deploy.log"

# Verificar se está rodando como root
if [[ $EUID -eq 0 ]]; then
   error "Este script não deve ser executado como root"
fi

# Verificar dependências
check_dependencies() {
    log "Verificando dependências..."
    
    command -v docker >/dev/null 2>&1 || error "Docker não está instalado"
    command -v docker-compose >/dev/null 2>&1 || error "Docker Compose não está instalado"
    command -v git >/dev/null 2>&1 || error "Git não está instalado"
    command -v npm >/dev/null 2>&1 || error "NPM não está instalado"
    
    success "Dependências verificadas com sucesso"
}

# Backup dos dados existentes
backup_data() {
    log "Realizando backup dos dados existentes..."
    
    # Criar diretório de backup se não existir
    sudo mkdir -p $BACKUP_DIR
    
    # Backup do banco de dados
    if docker ps | grep -q crm_db; then
        log "Fazendo backup do banco de dados..."
        docker exec crm_db pg_dump -U crm_user crm_db > $BACKUP_DIR/db_backup_$(date +%Y%m%d_%H%M%S).sql
        success "Backup do banco de dados concluído"
    fi
    
    # Backup dos arquivos de upload
    if [ -d "$DEPLOY_DIR/backend/uploads" ]; then
        log "Fazendo backup dos arquivos de upload..."
        sudo tar -czf $BACKUP_DIR/uploads_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C $DEPLOY_DIR backend/uploads
        success "Backup dos uploads concluído"
    fi
    
    # Backup do N8N (se existir)
    if [ -d "$DEPLOY_DIR/n8n_data" ]; then
        log "Fazendo backup dos dados do N8N..."
        sudo tar -czf $BACKUP_DIR/n8n_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C $DEPLOY_DIR n8n_data
        success "Backup do N8N concluído"
    fi
    
    success "Backup concluído com sucesso"
}

# Atualizar código fonte
update_code() {
    log "Atualizando código fonte..."
    
    # Criar diretório de deploy se não existir
    sudo mkdir -p $DEPLOY_DIR
    
    # Fazer pull das últimas alterações
    if [ -d "$DEPLOY_DIR/.git" ]; then
        log "Repositório já existe, fazendo pull..."
        cd $DEPLOY_DIR
        git fetch origin
        git reset --hard origin/main
    else
        log "Clonando repositório..."
        sudo rm -rf $DEPLOY_DIR
        git clone https://github.com/PedroPaduelo/crm-teste-n8n.git $DEPLOY_DIR
        cd $DEPLOY_DIR
    fi
    
    success "Código fonte atualizado com sucesso"
}

# Verificar variáveis de ambiente
check_env_files() {
    log "Verificando arquivos de ambiente..."
    
    # Backend
    if [ ! -f "$DEPLOY_DIR/backend/.env" ]; then
        if [ -f "$DEPLOY_DIR/backend/.env.production.example" ]; then
            warning "Arquivo .env não encontrado no backend. Copiando .env.production.example"
            cp $DEPLOY_DIR/backend/.env.production.example $DEPLOY_DIR/backend/.env
            error "POR FAVOR, EDITE O ARQUIVO $DEPLOY_DIR/backend/.env COM SUAS CONFIGURAÇÕES DE PRODUÇÃO ANTES DE CONTINUAR"
        else
            error "Arquivo .env.example não encontrado no backend"
        fi
    fi
    
    # Frontend
    if [ ! -f "$DEPLOY_DIR/frontend/.env" ]; then
        if [ -f "$DEPLOY_DIR/frontend/.env.production.example" ]; then
            warning "Arquivo .env não encontrado no frontend. Copiando .env.production.example"
            cp $DEPLOY_DIR/frontend/.env.production.example $DEPLOY_DIR/frontend/.env
            warning "POR FAVOR, VERIFIQUE O ARQUIVO $DEPLOY_DIR/frontend/.env COM SUAS CONFIGURAÇÕES"
        fi
    fi
    
    success "Arquivos de ambiente verificados"
}

# Construir imagens Docker
build_images() {
    log "Construindo imagens Docker..."
    
    cd $DEPLOY_DIR
    
    # Build do backend
    log "Build do backend..."
    docker-compose build backend --no-cache
    
    # Build do frontend
    log "Build do frontend..."
    docker-compose build frontend --no-cache
    
    success "Imagens Docker construídas com sucesso"
}

# Deploy da aplicação
deploy_app() {
    log "Realizando deploy da aplicação..."
    
    cd $DEPLOY_DIR
    
    # Parar serviços existentes
    log "Parando serviços existentes..."
    docker-compose down
    
    # Iniciar novos serviços
    log "Iniciando novos serviços..."
    docker-compose up -d
    
    # Aguardar serviços iniciarem
    log "Aguardando serviços iniciarem..."
    sleep 30
    
    success "Aplicação deployada com sucesso"
}

# Verificar saúde dos serviços
health_check() {
    log "Verificando saúde dos serviços..."
    
    # Verificar se containers estão rodando
    if ! docker ps | grep -q crm_backend; then
        error "Container do backend não está rodando"
    fi
    
    if ! docker ps | grep -q crm_frontend; then
        error "Container do frontend não está rodando"
    fi
    
    if ! docker ps | grep -q crm_db; then
        error "Container do banco de dados não está rodando"
    fi
    
    # Verificar health check
    sleep 10
    
    if curl -f http://localhost:3001/health >/dev/null 2>&1; then
        success "Backend está saudável"
    else
        error "Backend não está respondendo ao health check"
    fi
    
    if curl -f http://localhost >/dev/null 2>&1; then
        success "Frontend está acessível"
    else
        error "Frontend não está acessível"
    fi
    
    success "Verificação de saúde concluída com sucesso"
}

# Limpar recursos antigos
cleanup() {
    log "Limpando recursos antigos..."
    
    # Remover imagens antigas
    docker image prune -f
    
    # Remover volumes não utilizados
    docker volume prune -f
    
    # Manter apenas os últimos 7 backups
    find $BACKUP_DIR -name "*.sql" -type f -mtime +7 -delete 2>/dev/null || true
    find $BACKUP_DIR -name "*.tar.gz" -type f -mtime +7 -delete 2>/dev/null || true
    
    success "Limpeza concluída"
}

# Enviar notificação (opcional)
send_notification() {
    log "Enviando notificação de deploy..."
    
    # Implementar notificação por Slack, Email, etc.
    # Exemplo:
    # curl -X POST -H 'Content-type: application/json' \
    #     --data '{"text":"✅ Deploy do CRM realizado com sucesso!"}' \
    #     $SLACK_WEBHOOK_URL
    
    success "Notificação enviada"
}

# Função principal
main() {
    log "Iniciando deploy do CRM com N8N para produção..."
    
    # Criar diretório de log
    sudo mkdir -p $(dirname $LOG_FILE)
    
    # Executar steps
    check_dependencies
    backup_data
    update_code
    check_env_files
    build_images
    deploy_app
    health_check
    cleanup
    send_notification
    
    success "Deploy concluído com sucesso! 🚀"
    
    echo ""
    echo "=============================================="
    echo "🎉 DEPLOY CONCLUÍDO COM SUCESSO!"
    echo "=============================================="
    echo "Frontend: http://$(curl -s ifconfig.me)"
    echo "Backend API: http://$(curl -s ifconfig.me)/api"
    echo "Health Check: http://$(curl -s ifconfig.me)/health"
    echo "Logs: docker-compose logs -f"
    echo "=============================================="
}

# Executar função principal
main 2>&1 | tee -a $LOG_FILE