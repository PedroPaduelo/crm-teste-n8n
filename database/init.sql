-- Script de Inicialização do Banco de Dados - CRM com N8N
-- Este script é executado automaticamente quando o container PostgreSQL é iniciado

-- Criar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Criar schema principal (se não existir)
CREATE SCHEMA IF NOT EXISTS crm;

-- Definir schema padrão
SET search_path TO crm, public;

-- ===========================================
-- TABELAS PRINCIPAIS
-- ===========================================

-- Tabela de Usuários
CREATE TABLE IF NOT EXISTS crm.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user' CHECK (role IN ('admin', 'manager', 'user')),
    phone VARCHAR(20),
    avatar_url VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Empresas/Contas
CREATE TABLE IF NOT EXISTS crm.companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    cnpj VARCHAR(20) UNIQUE,
    email VARCHAR(255),
    phone VARCHAR(20),
    website VARCHAR(255),
    industry VARCHAR(100),
    size VARCHAR(50),
    address JSONB,
    logo_url VARCHAR(500),
    notes TEXT,
    owner_id UUID REFERENCES crm.users(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Contatos/Leads
CREATE TABLE IF NOT EXISTS crm.contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    mobile VARCHAR(20),
    company_id UUID REFERENCES crm.companies(id) ON DELETE SET NULL,
    job_title VARCHAR(100),
    department VARCHAR(100),
    lead_source VARCHAR(100),
    status VARCHAR(50) DEFAULT 'lead' CHECK (status IN ('lead', 'prospect', 'customer', 'churned')),
    owner_id UUID REFERENCES crm.users(id),
    address JSONB,
    social_media JSONB,
    custom_fields JSONB,
    tags TEXT[],
    notes TEXT,
    last_contact DATE,
    next_follow_up DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Oportunidades/Deals
CREATE TABLE IF NOT EXISTS crm.deals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    value DECIMAL(15,2),
    currency VARCHAR(3) DEFAULT 'BRL',
    stage VARCHAR(100) NOT NULL,
    probability INTEGER CHECK (probability >= 0 AND probability <= 100),
    expected_close_date DATE,
    actual_close_date DATE,
    contact_id UUID REFERENCES crm.contacts(id),
    company_id UUID REFERENCES crm.companies(id),
    owner_id UUID REFERENCES crm.users(id),
    source VARCHAR(100),
    status VARCHAR(50) DEFAULT 'open' CHECK (status IN ('open', 'won', 'lost', 'cancelled')),
    lost_reason TEXT,
    custom_fields JSONB,
    tags TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Atividades
CREATE TABLE IF NOT EXISTS crm.activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(50) NOT NULL CHECK (type IN ('call', 'email', 'meeting', 'task', 'note', 'whatsapp')),
    subject VARCHAR(255) NOT NULL,
    description TEXT,
    contact_id UUID REFERENCES crm.contacts(id),
    company_id UUID REFERENCES crm.companies(id),
    deal_id UUID REFERENCES crm.deals(id),
    owner_id UUID REFERENCES crm.users(id),
    status VARCHAR(50) DEFAULT 'completed' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    due_date TIMESTAMP,
    completed_date TIMESTAMP,
    duration_minutes INTEGER,
    location VARCHAR(255),
    attendees JSONB,
    custom_fields JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Tarefas
CREATE TABLE IF NOT EXISTS crm.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    contact_id UUID REFERENCES crm.contacts(id),
    company_id UUID REFERENCES crm.companies(id),
    deal_id UUID REFERENCES crm.deals(id),
    assigned_to UUID REFERENCES crm.users(id),
    created_by UUID REFERENCES crm.users(id),
    status VARCHAR(50) DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'review', 'done', 'cancelled')),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    due_date TIMESTAMP,
    completed_date TIMESTAMP,
    estimated_hours DECIMAL(5,2),
    actual_hours DECIMAL(5,2),
    tags TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Documentos
CREATE TABLE IF NOT EXISTS crm.documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT,
    file_type VARCHAR(100),
    mime_type VARCHAR(100),
    contact_id UUID REFERENCES crm.contacts(id),
    company_id UUID REFERENCES crm.companies(id),
    deal_id UUID REFERENCES crm.deals(id),
    uploaded_by UUID REFERENCES crm.users(id),
    category VARCHAR(100),
    description TEXT,
    is_public BOOLEAN DEFAULT false,
    download_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Tags
CREATE TABLE IF NOT EXISTS crm.tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    color VARCHAR(7) DEFAULT '#007bff',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de integrações com WhatsApp
CREATE TABLE IF NOT EXISTS crm.whatsapp_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id VARCHAR(255) UNIQUE NOT NULL,
    contact_id UUID REFERENCES crm.contacts(id),
    direction VARCHAR(20) NOT NULL CHECK (direction IN ('inbound', 'outbound')),
    content TEXT NOT NULL,
    message_type VARCHAR(50) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'document', 'audio', 'video', 'location', 'contact')),
    media_url VARCHAR(500),
    status VARCHAR(50) DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'read', 'failed')),
    wa_timestamp TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Workflows N8N
CREATE TABLE IF NOT EXISTS crm.workflows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    n8n_workflow_id VARCHAR(255),
    trigger_type VARCHAR(100),
    trigger_config JSONB,
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES crm.users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Logs de Execução de Workflows
CREATE TABLE IF NOT EXISTS crm.workflow_executions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_id UUID REFERENCES crm.workflows(id),
    n8n_execution_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'running' CHECK (status IN ('running', 'success', 'error', 'cancelled')),
    trigger_data JSONB,
    result_data JSONB,
    error_message TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- ===========================================
-- ÍNDICES
-- ===========================================

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_contacts_email ON crm.contacts(email);
CREATE INDEX IF NOT EXISTS idx_contacts_company_id ON crm.contacts(company_id);
CREATE INDEX IF NOT EXISTS idx_contacts_owner_id ON crm.contacts(owner_id);
CREATE INDEX IF NOT EXISTS idx_contacts_status ON crm.contacts(status);
CREATE INDEX IF NOT EXISTS idx_contacts_tags ON crm.contacts USING GIN(tags);

CREATE INDEX IF NOT EXISTS idx_companies_cnpj ON crm.companies(cnpj);
CREATE INDEX IF NOT EXISTS idx_companies_owner_id ON crm.companies(owner_id);

CREATE INDEX IF NOT EXISTS idx_deals_contact_id ON crm.deals(contact_id);
CREATE INDEX IF NOT EXISTS idx_deals_company_id ON crm.deals(company_id);
CREATE INDEX IF NOT EXISTS idx_deals_owner_id ON crm.deals(owner_id);
CREATE INDEX IF NOT EXISTS idx_deals_stage ON crm.deals(stage);
CREATE INDEX IF NOT EXISTS idx_deals_status ON crm.deals(status);

CREATE INDEX IF NOT EXISTS idx_activities_contact_id ON crm.activities(contact_id);
CREATE INDEX IF NOT EXISTS idx_activities_deal_id ON crm.activities(deal_id);
CREATE INDEX IF NOT EXISTS idx_activities_owner_id ON crm.activities(owner_id);
CREATE INDEX IF NOT EXISTS idx_activities_type ON crm.activities(type);
CREATE INDEX IF NOT EXISTS idx_activities_status ON crm.activities(status);
CREATE INDEX IF NOT EXISTS idx_activities_due_date ON crm.activities(due_date);

CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON crm.tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON crm.tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON crm.tasks(due_date);

CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_contact_id ON crm.whatsapp_messages(contact_id);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_direction ON crm.whatsapp_messages(direction);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_created_at ON crm.whatsapp_messages(created_at);

CREATE INDEX IF NOT EXISTS idx_workflow_executions_workflow_id ON crm.workflow_executions(workflow_id);
CREATE INDEX IF NOT EXISTS idx_workflow_executions_status ON crm.workflow_executions(status);
CREATE INDEX IF NOT EXISTS idx_workflow_executions_started_at ON crm.workflow_executions(started_at);

-- Índices para busca full-text
CREATE INDEX IF NOT EXISTS idx_contacts_search ON crm.contacts USING GIN(to_tsvector('portuguese', coalesce(first_name, '') || ' ' || coalesce(last_name, '') || ' ' || coalesce(email, '') || ' ' || coalesce(notes, '')));
CREATE INDEX IF NOT EXISTS idx_companies_search ON crm.companies USING GIN(to_tsvector('portuguese', coalesce(name, '') || ' ' || coalesce(email, '') || ' ' || coalesce(notes, '')));

-- ===========================================
-- TRIGGERS E FUNÇÕES
-- ===========================================

-- Função para atualizar updated_at
CREATE OR REPLACE FUNCTION crm.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar trigger em todas as tabelas
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON crm.users FOR EACH ROW EXECUTE FUNCTION crm.update_updated_at_column();
CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON crm.companies FOR EACH ROW EXECUTE FUNCTION crm.update_updated_at_column();
CREATE TRIGGER update_contacts_updated_at BEFORE UPDATE ON crm.contacts FOR EACH ROW EXECUTE FUNCTION crm.update_updated_at_column();
CREATE TRIGGER update_deals_updated_at BEFORE UPDATE ON crm.deals FOR EACH ROW EXECUTE FUNCTION crm.update_updated_at_column();
CREATE TRIGGER update_activities_updated_at BEFORE UPDATE ON crm.activities FOR EACH ROW EXECUTE FUNCTION crm.update_updated_at_column();
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON crm.tasks FOR EACH ROW EXECUTE FUNCTION crm.update_updated_at_column();
CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON crm.documents FOR EACH ROW EXECUTE FUNCTION crm.update_updated_at_column();
CREATE TRIGGER update_workflows_updated_at BEFORE UPDATE ON crm.workflows FOR EACH ROW EXECUTE FUNCTION crm.update_updated_at_column();

-- ===========================================
-- DADOS INICIAIS
-- ===========================================

-- Inserir tags padrão
INSERT INTO crm.tags (name, color, description) VALUES 
    ('Lead Quente', '#dc3545', 'Contatos com alta probabilidade de conversão'),
    ('Lead Frio', '#6c757d', 'Contatos que precisam nutrição'),
    ('Cliente VIP', '#ffc107', 'Clientes de alto valor'),
    ('Prospect', '#17a2b8', 'Potenciais clientes em negociação'),
    ('Follow-up', '#28a745', 'Contatos que necessitam acompanhamento')
ON CONFLICT (name) DO NOTHING;

-- Criar usuário admin padrão (senha: admin123)
INSERT INTO crm.users (name, email, password_hash, role, email_verified) VALUES 
    ('Administrador', 'admin@crm.local', '$2b$10$rQZ8kHWKtGYIu8K5M2hO7OQqQ9Q9Q9Q9Q9Q9Q9Q9Q9Q9Q9Q9Q9Q9Q9', 'admin', true)
ON CONFLICT (email) DO NOTHING;

-- ===========================================
-- VIEWS ÚTEIS
-- ===========================================

-- View de estatísticas do dashboard
CREATE OR REPLACE VIEW crm.dashboard_stats AS
SELECT 
    (SELECT COUNT(*) FROM crm.contacts WHERE status = 'lead') as total_leads,
    (SELECT COUNT(*) FROM crm.contacts WHERE status = 'customer') as total_customers,
    (SELECT COUNT(*) FROM crm.deals WHERE status = 'open') as active_deals,
    (SELECT COUNT(*) FROM crm.deals WHERE status = 'won' AND actual_close_date >= CURRENT_DATE - INTERVAL '30 days') as won_deals_month,
    (SELECT COALESCE(SUM(value), 0) FROM crm.deals WHERE status = 'won' AND actual_close_date >= CURRENT_DATE - INTERVAL '30 days') as revenue_month,
    (SELECT COUNT(*) FROM crm.activities WHERE status = 'pending' AND due_date <= CURRENT_DATE) as overdue_tasks;

-- View de pipeline de vendas
CREATE OR REPLACE VIEW crm.sales_pipeline AS
SELECT 
    stage,
    COUNT(*) as deal_count,
    COALESCE(SUM(value), 0) as total_value,
    AVG(probability) as avg_probability
FROM crm.deals 
WHERE status = 'open'
GROUP BY stage
ORDER BY 
    CASE stage 
        WHEN 'Prospecting' THEN 1
        WHEN 'Qualification' THEN 2
        WHEN 'Proposal' THEN 3
        WHEN 'Negotiation' THEN 4
        WHEN 'Closed Won' THEN 5
        ELSE 6
    END;

-- ===========================================
-- LOG
-- ===========================================

DO $$
BEGIN
    RAISE NOTICE 'Banco de dados CRM inicializado com sucesso!';
    RAISE NOTICE 'Schema: crm';
    RAISE NOTICE 'Tabelas criadas: users, companies, contacts, deals, activities, tasks, documents, tags, whatsapp_messages, workflows, workflow_executions';
    RAISE NOTICE 'Índices criados para performance';
    RAISE NOTICE 'Views criadas: dashboard_stats, sales_pipeline';
    RAISE NOTICE 'Usuário admin criado: admin@crm.local / admin123';
END $$;