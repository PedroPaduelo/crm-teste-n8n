#!/bin/bash

# Script de Deploy Automatizado - CRM com N8N
# Uso: ./scripts/deploy.sh [ambiente]
# Exemplo: ./scripts/deploy.sh production

set -e  # Parar script em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
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

# Variáveis
ENVIRONMENT=${1:-development}
PROJECT_NAME="crm-teste-n8n"
BACKUP_DIR="/backups/$PROJECT_NAME"
DATE=$(date +%Y%m%d_%H%M%S)

log_info "Iniciando deploy do projeto $PROJECT_NAME para ambiente $ENVIRONMENT"
log_info "Data/Hora: $(date)"

# Verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker não está instalado"
        exit 1
    fi
    
    # Verificar Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose não está instalado"
        exit 1
    fi
    
    # Verificar arquivo .env
    if [ ! -f .env ]; then
        log_warning "Arquivo .env não encontrado. Copiando de .env.example"
        cp .env.example .env
        log_warning "Por favor, configure as variáveis de ambiente no arquivo .env"
        exit 1
    fi
    
    # Verificar conectividade com repositório
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Diretório não é um repositório Git"
        exit 1
    fi
    
    log_success "Pré-requisitos verificados"
}

# Backup do ambiente atual
backup_current() {
    if [ "$ENVIRONMENT" = "production" ]; then
        log_info "Fazendo backup do ambiente atual..."
        
        mkdir -p $BACKUP_DIR
        
        # Backup do banco de dados
        if docker ps | grep -q crm_db; then
            log_info "Fazendo backup do banco de dados..."
            docker exec crm_db pg_dump -U crm_user crm_db > $BACKUP_DIR/db_backup_$DATE.sql
            log_success "Backup do banco salvo em: $BACKUP_DIR/db_backup_$DATE.sql"
        fi
        
        # Backup dos volumes
        log_info "Fazendo backup dos volumes Docker..."
        docker run --rm -v crm_teste_n8n_postgres_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/postgres_data_$DATE.tar.gz -C /data .
        docker run --rm -v crm_teste_n8n_n8n_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/n8n_data_$DATE.tar.gz -C /data .
        
        log_success "Backup dos volumes concluído"
    fi
}

# Atualizar código fonte
update_code() {
    log_info "Atualizando código fonte..."
    
    # Fazer pull das últimas mudanças
    git fetch origin
    git pull origin main
    
    log_success "Código atualizado"
}

# Build das imagens
build_images() {
    log_info "Construindo imagens Docker..."
    
    # Build do backend
    log_info "Build do backend..."
    docker-compose build --no-cache backend
    
    # Build do frontend
    log_info "Build do frontend..."
    docker-compose build --no-cache frontend
    
    log_success "Imagens construídas com sucesso"
}

# Executar migrações do banco de dados
run_migrations() {
    log_info "Executando migrações do banco de dados..."
    
    # Iniciar apenas o banco de dados
    docker-compose up -d db
    
    # Esperar banco ficar pronto
    log_info "Aguardando banco de dados ficar pronto..."
    sleep 30
    
    # Rodar migrações (se existirem)
    if [ -f "database/migrations/run.sh" ]; then
        docker-compose exec db bash /docker-entrypoint-initdb.d/migrations/run.sh
    fi
    
    log_success "Migrações executadas"
}

# Deploy dos serviços
deploy_services() {
    log_info "Iniciando deploy dos serviços..."
    
    # Parar serviços existentes
    log_info "Parando serviços existentes..."
    docker-compose down
    
    # Iniciar novos serviços
    log_info "Iniciando novos serviços..."
    docker-compose up -d
    
    log_success "Serviços iniciados"
}

# Verificar saúde dos serviços
health_check() {
    log_info "Verificando saúde dos serviços..."
    
    # Esperar serviços iniciarem
    sleep 30
    
    # Verificar backend
    if curl -f http://localhost:3001/health > /dev/null 2>&1; then
        log_success "Backend está saudável"
    else
        log_error "Backend não está respondendo"
        return 1
    fi
    
    # Verificar frontend
    if curl -f http://localhost/health > /dev/null 2>&1; then
        log_success "Frontend está saudável"
    else
        log_error "Frontend não está respondendo"
        return 1
    fi
    
    # Verificar N8N (se configurado)
    if [ -n "$N8N_HOST" ]; then
        if curl -f http://localhost:5678 > /dev/null 2>&1; then
            log_success "N8N está saudável"
        else
            log_warning "N8N não está respondendo (pode ser normal se não configurado)"
        fi
    fi
    
    log_success "Todos os serviços estão saudáveis"
}

# Limpeza
cleanup() {
    log_info "Fazendo limpeza..."
    
    # Remover imagens antigas
    docker image prune -f
    
    # Remover volumes órfãos
    docker volume prune -f
    
    # Manter apenas últimos 7 dias de backups
    if [ "$ENVIRONMENT" = "production" ]; then
        find $BACKUP_DIR -name "*.sql" -mtime +7 -delete 2>/dev/null || true
        find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete 2>/dev/null || true
    fi
    
    log_success "Limpeza concluída"
}

# Rollback (em caso de falha)
rollback() {
    log_error "Ocorreu um erro durante o deploy. Iniciando rollback..."
    
    # Parar serviços atuais
    docker-compose down
    
    # Restaurar backup mais recente
    if [ -f "$BACKUP_DIR/db_backup_latest.sql" ]; then
        docker-compose up -d db
        sleep 30
        docker exec -i crm_db psql -U crm_user crm_db < $BACKUP_DIR/db_backup_latest.sql
        log_info "Banco de dados restaurado"
    fi
    
    # Tentar usar imagem anterior
    docker-compose up -d
    
    log_error "Rollback concluído. Por favor, verifique o status dos serviços."
}

# Monitoramento pós-deploy
post_deploy_monitoring() {
    log_info "Iniciando monitoramento pós-deploy (5 minutos)..."
    
    for i in {1..30}; do
        if curl -f http://localhost:3001/health > /dev/null 2>&1 && \
           curl -f http://localhost/health > /dev/null 2>&1; then
            echo -n "."
        else
            echo -n "!"
        fi
        sleep 10
    done
    
    echo ""
    log_success "Monitoramento pós-deploy concluído"
}

# Função principal
main() {
    # Executar rollback em caso de erro
    trap rollback ERR
    
    check_prerequisites
    backup_current
    update_code
    build_images
    run_migrations
    deploy_services
    health_check
    cleanup
    post_deploy_monitoring
    
    echo ""
    echo "=================================="
    log_success "Deploy concluído com sucesso!"
    echo "=================================="
    echo ""
    echo "Serviços disponíveis:"
    echo "  • Frontend: http://localhost"
    echo "  • Backend API: http://localhost:3001"
    echo "  • Health Check: http://localhost:3001/health"
    echo "  • N8N: http://localhost:5678 (se configurado)"
    echo "  • PgAdmin: http://localhost:5050 (se configurado)"
    echo ""
    echo "Logs dos serviços:"
    echo "  docker-compose logs -f backend"
    echo "  docker-compose logs -f frontend"
    echo "  docker-compose logs -f db"
    echo ""
}

# Executar script
main "$@"