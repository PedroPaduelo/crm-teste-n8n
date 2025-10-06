#!/bin/bash

# Script de Backup Completo - CRM com N8N
# Uso: ./scripts/backup.sh [tipo]
# Tipos: full, db, files, all (default)

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

# Variáveis
BACKUP_TYPE=${1:-all}
PROJECT_NAME="crm-teste-n8n"
BACKUP_DIR="/backups/$PROJECT_NAME"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Criar diretório de backup
mkdir -p $BACKUP_DIR

log_info "Iniciando backup do projeto $PROJECT_NAME"
log_info "Tipo: $BACKUP_TYPE"
log_info "Data/Hora: $(date)"

# Backup do banco de dados
backup_database() {
    log_info "Fazendo backup do banco de dados..."
    
    if docker ps | grep -q crm_db; then
        # Backup completo
        docker exec crm_db pg_dump -U crm_user -h localhost crm_db > $BACKUP_DIR/db_backup_$DATE.sql
        
        # Backup comprimido
        gzip $BACKUP_DIR/db_backup_$DATE.sql
        
        log_success "Backup do banco salvo: $BACKUP_DIR/db_backup_$DATE.sql.gz"
        
        # Criar symlink para "latest"
        ln -sf db_backup_$DATE.sql.gz $BACKUP_DIR/db_backup_latest.sql.gz
    else
        log_warning "Container do banco não está rodando"
    fi
}

# Backup dos arquivos de upload
backup_files() {
    log_info "Fazendo backup dos arquivos..."
    
    # Backup dos uploads
    if [ -d "backend/uploads" ]; then
        tar -czf $BACKUP_DIR/uploads_backup_$DATE.tar.gz -C backend uploads
        log_success "Backup dos uploads salvo: $BACKUP_DIR/uploads_backup_$DATE.tar.gz"
        
        # Criar symlink para "latest"
        ln -sf uploads_backup_$DATE.tar.gz $BACKUP_DIR/uploads_backup_latest.tar.gz
    fi
    
    # Backup dos volumes Docker
    if docker volume ls | grep -q crm_teste_n8n_postgres_data; then
        docker run --rm -v crm_teste_n8n_postgres_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/postgres_volume_$DATE.tar.gz -C /data .
        log_success "Backup do volume PostgreSQL salvo: $BACKUP_DIR/postgres_volume_$DATE.tar.gz"
    fi
    
    if docker volume ls | grep -q crm_teste_n8n_n8n_data; then
        docker run --rm -v crm_teste_n8n_n8n_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/n8n_volume_$DATE.tar.gz -C /data .
        log_success "Backup do volume N8N salvo: $BACKUP_DIR/n8n_volume_$DATE.tar.gz"
    fi
    
    if docker volume ls | grep -q crm_teste_n8n_redis_data; then
        docker run --rm -v crm_teste_n8n_redis_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/redis_volume_$DATE.tar.gz -C /data .
        log_success "Backup do volume Redis salvo: $BACKUP_DIR/redis_volume_$DATE.tar.gz"
    fi
}

# Backup das configurações
backup_config() {
    log_info "Fazendo backup das configurações..."
    
    # Criar diretório temporário
    TEMP_DIR=$(mktemp -d)
    
    # Copiar arquivos de configuração
    cp docker-compose.yml $TEMP_DIR/
    cp .env $TEMP_DIR/ 2>/dev/null || log_warning ".env não encontrado"
    cp -r nginx/ $TEMP_DIR/ 2>/dev/null || true
    cp -r scripts/ $TEMP_DIR/ 2>/dev/null || true
    
    # Copiar Dockerfiles
    find . -name "Dockerfile" -exec cp {} $TEMP_DIR/ \;
    
    # Criar arquivo de metadados
    cat > $TEMP_DIR/backup_info.txt << EOF
Backup Information
==================
Project: $PROJECT_NAME
Date: $(date)
Type: $BACKUP_TYPE
Git Commit: $(git rev-parse HEAD 2>/dev/null || echo "N/A")
Git Branch: $(git branch --show-current 2>/dev/null || echo "N/A")
Docker Version: $(docker --version)
Docker Compose Version: $(docker-compose --version)
System: $(uname -a)
EOF
    
    # Compactar configurações
    tar -czf $BACKUP_DIR/config_backup_$DATE.tar.gz -C $TEMP_DIR .
    
    # Limpar diretório temporário
    rm -rf $TEMP_DIR
    
    log_success "Backup das configurações salvo: $BACKUP_DIR/config_backup_$DATE.tar.gz"
    
    # Criar symlink para "latest"
    ln -sf config_backup_$DATE.tar.gz $BACKUP_DIR/config_backup_latest.tar.gz
}

# Backup do código fonte
backup_source() {
    log_info "Fazendo backup do código fonte..."
    
    # Criar arquivo com informações do Git
    git log --oneline -10 > $BACKUP_DIR/git_log_$DATE.txt 2>/dev/null || log_warning "Git não disponível"
    
    # Criar diff das últimas mudanças
    git diff HEAD~5..HEAD > $BACKUP_DIR/git_diff_$DATE.txt 2>/dev/null || log_warning "Não foi possível criar diff"
    
    log_success "Informações do Git salvas"
}

# Backup para nuvem (AWS S3)
backup_to_cloud() {
    log_info "Enviando backup para nuvem..."
    
    if command -v aws &> /dev/null && [ -n "$AWS_S3_BUCKET" ]; then
        # Enviar backups para S3
        aws s3 sync $BACKUP_DIR/ s3://$AWS_S3_BUCKET/backups/$PROJECT_NAME/$DATE/ --delete
        
        # Manter apenas últimos backups no S3
        aws s3 ls s3://$AWS_S3_BUCKET/backups/$PROJECT_NAME/ | while read -r line; do
            createDate=$(echo $line | awk '{print $1" "$2}')
            createDate=$(date -d "$createDate" +%s)
            olderThan=$(date -d "$RETENTION_DAYS days ago" +%s)
            
            if [[ $createDate -lt $olderThan ]]; then
                fileName=$(echo $line | awk '{print $4}')
                if [[ $fileName != "" ]]; then
                    aws s3 rm s3://$AWS_S3_BUCKET/backups/$PROJECT_NAME/$fileName
                fi
            fi
        done
        
        log_success "Backup enviado para S3: s3://$AWS_S3_BUCKET/backups/$PROJECT_NAME/$DATE/"
    else
        log_warning "AWS CLI não configurado ou AWS_S3_BUCKET não definido"
    fi
}

# Limpar backups antigos
cleanup_old_backups() {
    log_info "Limpando backups antigos (mais de $RETENTION_DAYS dias)..."
    
    # Remover arquivos antigos
    find $BACKUP_DIR -name "*.gz" -mtime +$RETENTION_DAYS -delete
    find $BACKUP_DIR -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
    find $BACKUP_DIR -name "*.txt" -mtime +$RETENTION_DAYS -delete
    
    # Manter apenas os 10 backups mais recentes de cada tipo
    ls -t $BACKUP_DIR/db_backup_*.sql.gz 2>/dev/null | tail -n +11 | xargs rm -f
    ls -t $BACKUP_DIR/uploads_backup_*.tar.gz 2>/dev/null | tail -n +11 | xargs rm -f
    ls -t $BACKUP_DIR/config_backup_*.tar.gz 2>/dev/null | tail -n +11 | xargs rm -f
    
    log_success "Limpeza concluída"
}

# Verificar integridade dos backups
verify_backups() {
    log_info "Verificando integridade dos backups..."
    
    # Verificar se os arquivos de backup existem e não estão vazios
    if [ -f "$BACKUP_DIR/db_backup_$DATE.sql.gz" ]; then
        if [ -s "$BACKUP_DIR/db_backup_$DATE.sql.gz" ]; then
            log_success "Backup do banco verificado"
        else
            log_error "Backup do banco está vazio"
            return 1
        fi
    fi
    
    if [ -f "$BACKUP_DIR/config_backup_$DATE.tar.gz" ]; then
        if [ -s "$BACKUP_DIR/config_backup_$DATE.tar.gz" ]; then
            log_success "Backup das configurações verificado"
        else
            log_error "Backup das configurações está vazio"
            return 1
        fi
    fi
    
    log_success "Todos os backups verificados com sucesso"
}

# Gerar relatório do backup
generate_report() {
    log_info "Gerando relatório do backup..."
    
    REPORT_FILE="$BACKUP_DIR/backup_report_$DATE.txt"
    
    cat > $REPORT_FILE << EOF
========================================
Backup Report - $PROJECT_NAME
========================================
Date: $(date)
Type: $BACKUP_TYPE
Server: $(hostname)
System: $(uname -a)

Backup Files Created:
--------------------
EOF
    
    # Listar arquivos de backup criados
    find $BACKUP_DIR -name "*_$DATE.*" -exec ls -lh {} \; >> $REPORT_FILE
    
    cat >> $REPORT_FILE << EOF

Docker Status:
--------------
$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")

Disk Usage:
-----------
$(df -h | grep -E "(Filesystem|/dev/)")

Backup Directory Size:
---------------------
$(du -sh $BACKUP_DIR)

========================================
EOF
    
    log_success "Relatório gerado: $REPORT_FILE"
}

# Restaurar backup (função para uso futuro)
restore_backup() {
    local backup_date=$1
    log_info "Restaurando backup de $backup_date..."
    
    if [ -z "$backup_date" ]; then
        log_error "Por favor, forneça a data do backup (formato: YYYYMMDD_HHMMSS)"
        return 1
    fi
    
    # Restaurar banco de dados
    if [ -f "$BACKUP_DIR/db_backup_$backup_date.sql.gz" ]; then
        log_info "Restaurando banco de dados..."
        gunzip -c $BACKUP_DIR/db_backup_$backup_date.sql.gz | docker exec -i crm_db psql -U crm_user crm_db
        log_success "Banco de dados restaurado"
    fi
    
    # Restaurar arquivos
    if [ -f "$BACKUP_DIR/uploads_backup_$backup_date.tar.gz" ]; then
        log_info "Restaurando arquivos de upload..."
        tar -xzf $BACKUP_DIR/uploads_backup_$backup_date.tar.gz -C backend/
        log_success "Arquivos restaurados"
    fi
    
    log_success "Backup restaurado com sucesso"
}

# Função principal
main() {
    case $BACKUP_TYPE in
        "db")
            backup_database
            ;;
        "files")
            backup_files
            ;;
        "config")
            backup_config
            backup_source
            ;;
        "full")
            backup_database
            backup_files
            backup_config
            backup_source
            ;;
        "all"|"*)
            backup_database
            backup_files
            backup_config
            backup_source
            backup_to_cloud
            cleanup_old_backups
            ;;
    esac
    
    verify_backups
    generate_report
    
    echo ""
    echo "=================================="
    log_success "Backup concluído com sucesso!"
    echo "=================================="
    echo ""
    echo "Backup Summary:"
    echo "  • Type: $BACKUP_TYPE"
    echo "  • Date: $(date)"
    echo "  • Location: $BACKUP_DIR"
    echo "  • Size: $(du -sh $BACKUP_DIR | cut -f1)"
    echo ""
    echo "Latest Backups:"
    if [ -L "$BACKUP_DIR/db_backup_latest.sql.gz" ]; then
        echo "  • Database: $(readlink $BACKUP_DIR/db_backup_latest.sql.gz)"
    fi
    if [ -L "$BACKUP_DIR/config_backup_latest.tar.gz" ]; then
        echo "  • Config: $(readlink $BACKUP_DIR/config_backup_latest.tar.gz)"
    fi
    echo ""
    echo "To restore: $0 restore YYYYMMDD_HHMMSS"
    echo ""
}

# Executar script
if [ "$1" = "restore" ]; then
    restore_backup "$2"
else
    main "$@"
fi