# CRM com Integração N8N

Sistema CRM (Customer Relationship Management) desenvolvido com integração N8N para automação de processos e WhatsApp Business API para comunicação com clientes.

## 📋 Índice

- [Quick Start](#quick-start)
- [Configuração](#configuração)
- [Deploy](#deploy)
- [Documentação](#documentação)
- [Contribuindo](#contribuindo)

## 🏗️ Arquitetura do Projeto

```
crm-teste-n8n/
├── backend/                      # API RESTful com Node.js + Express + TypeScript
├── frontend/                     # Aplicação web React + TypeScript
├── docs/                         # Documentação
├── README.md                     # Este arquivo
└── docker-compose.yml            # Docker Compose para orquestração
```

## 🚀 Quick Start

### Pré-requisitos

- Node.js 18+
- PostGreSQL 13+
- Conta WhatsApp Business (para integração)
- N8N (opcional, para automação)

### 1. Instalação do Backend

```bash
# Navegar para pasta do backend
cd backend

# Instalar dependências
npm install

# Copiar arquivo de ambiente
cp .env.example .env

# Configurar variáveis de ambiente (veja seção Configuração)
```

### 2. Instalação do Frontend

```bash
# Navegar para pasta do frontend
cd frontend

# Instalar dependências
npm install

# Iniciar servidor de desenvolvimento
npm run dev
```

### 3. Iniciar Aplicação

```bash
# Terminal 1 - Iniciar backend
cd backend
npm run dev

# Terminal 2 - Iniciar frontend
cd frontend
npm run dev
```

### Acesso:

- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:3001
- **Health Check**: http://localhost:3001/health

## ⚙️ Configuração

### Variáveis de Ambiente Obrigatórias

Configure as seguintes variáveis no arquivo `backend/.env`:

```bash
# Banco de Dados
DATABASE_URL=postgresql://usuario:senha@localhost:5432/crm_db

# JWT
JWT_SECRET=seu-segredo-jwt-muito-seguro-muda-em-produção

# WhatsApp Business API
WHATSAPP_API_TOKEN=seu-token-api-whatsappapp
WHATSAPP_PHONE_NUMBER_ID=seu-id-numero-whatsappapp
VERIFY_TOKEN=seu-token-verificacao-webhook-unico

# Frontend URL
FRONTEND_URL=http://localhost:3000

# N8N
N8N_WEBHOOK_URL=http://localhost:5678/webhook
N8N_API_KEY=sua-chave-api-n8n

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=seu-email@gmail.com
SMTP_PASS=sua-senha-app
```

### Configuração do WhatsApp Business

1. **Criar conta Meta Developer**: Acesse [developers.facebook.com](https://developers.facebook.com)
2. **Criar aplicação WhatsApp**: 
   - Vá para "Meus Apps" ➜ "Criar App" ➜ "Business" ➜ "WhatsApp"
3. **Obter credenciais**:
   - API Token (painel da aplicação)
   - Phone Number ID (painel do WhatsApp)
4. **Configurar webhook**:
   - URL: `https://seu-dominio.com/api/whatsapp/webhook`
   - Verify Token: configure no Meta e no .env

### Banco de Dados

```sql
-- Criar banco de dados
CREATE DATABASE crm_db;

-- Criar usuário (opcional)
CREATE USER crm_user WITH PASSWORD 'senha_segura';
GRANT ALL PRIVILEGES ON DATABASE crm_db TO crm_user;
```

## 🔧 Desenvolvimento

### Scripts Úteis

```bash
# Backend
npm run dev        # Servidor desenvolvimento
npm run build      # Compilar TypeScript
npm start          # Servidor produção

# Frontend
npm run dev        # Servidor desenvolvimento
npm run build      # Build para produção
npm run preview    # Preview do build
```

### ngrok para Webhooks

Para testar webhooks localmente:

```bash
# Expor backend
ngrok http 3001

# Usar URL gerida no Meta Developer Portal
# Ex: https://abc123.ngrok.io/api/whatsapp/webhook
```

## 🚀 Deploy

### Backend

```bash
# Compilar projeto
npm run build

# Iniciar em produção
NODE_ENV=production npm start

# Ou usando PM2
pm2 start dist/index.js --name crm-backend
```

### Frontend

```bash
# Build para produção
npm run build

# Deploy da pasta dist
# Configurar servidor web para servir arquivos estáticos
```

## 🌐 Opções de Hospedagem

### Backend
- **VPS**: DigitalOcean, Linode, AWS EC2
- **PaaS**: Heroku, Render, Railway
- **Container**: Docker + Kubernetes

### Frontend
- **Static Hosting**: Vercel, Netlify, GitHub Pages
- **CDN**: AWS S3 + CloudFront
- **VPS**: Nginx + Apache

## 🔒 Configuração de Produção

### Variáveis de Ambiente Produção
⚠️ **IMPORTANTE**: Nunca comite o arquivo `.env` no versionamento!

- Use serviços de gerenciamento de segredos (AWS Secrets Manager, HashiCorp Vault)
- Ou configure variáveis no servidor
- Ou use arquivos de configuração específicos do ambiente

### Segurança

- Configure CORS para domínios específicos
- Use HTTPS em produção
- Valide tokens JWT
- Implemente rate limiting
- Sanitize inputs de usuários
- Configure headers de segurança

### Monitoramento e Logs

Em produção, configure monitoramento e logs:

```bash
# Logs PM2
pm2 logs crm-backend

# Logs específicos
tail -f /var/log/crm/app.log

# Monitoramento com Docker
docker logs -f crm_backend
```

## 🤖 Integração N8N

O sistema integra com N8N para automação:

1. **Configurar webhooks** no N8N:
   - URL: `http://localhost:5678/webhook`
2. **Automações disponíveis**:
   - Novos leads
   - Atualizações de clientes
   - Envio de mensagens WhatsApp
   - Disparos de emails

## 🚀 Funcionalidades

### CRM Core
- 👥 Gestão de clientes
- 📈 Controle de leads
- 📅 Histórico de interações
- 📊 Pipeline de vendas

### Comunicação
- 📱 WhatsApp Business API
- 📧 Envio de emails
- 🔔 Notificações automáticas

### Automação
- 🤖 Integração N8N
- 🔁 Webhooks personalizados
- ⚡ Fluxos de trabalho

## 📚 Documentação

- [Backend Documentation](./backend/README.md)
- [Frontend Documentation](./frontend/README.md)
- [API Reference](./docs/api.md) *(em construção)*
- [Deploy Guide](./docs/DEPLOY.md)

## 🤝 Contribuindo

1. Fork o projeto
2. Crie branch para feature (`git checkout -b feature/nova-funcionalidade`)
3. Commit mudanças (`git commit -am 'Add nova funcionalidade'`)
4. Push para branch (`git push origin feature/nova-funcionalidade`)
5. Abra Pull Request

## 📜 Licença

Este projeto está sob licença MIT. Veja [LICENSE](LICENSE) para mais detalhes.

## 🤝 Suporte

Para suporte:

- Abra uma Issue no GitHub
- Email: support@seu-dominio.com
- Documentação: [Wiki do Projeto](https://github.com/PedroPaduelo/crm-teste-n8n/wiki)

## 📈 Status do Projeto

- [x] Backend API básica
- [x] Configuração WhatsApp
- [x] Documentação inicial
- [x] Frontend completo
- [x] Integração N8N avançada
- [x] Testes automatizados
- [x] CI/CD pipeline

---

**Desenvolvido com Node.js, React e N8N**

### 🚀 Deploy Rápido

Para deploy rápido em produção:

```bash
# Clonar repositório
git clone https://github.com/PedroPaduelo/crm-teste-n8n.git
cd crm-teste-n8n

# Configurar ambiente
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env

# Editar arquivos .env com suas credenciais

# Deploy com Docker
docker-compose up -d

# Ou deploy manual seguindo o guia docs/DEPLOY.md
```

## 📋 Requisitos de Produção

### 🔧 Configurações Essenciais

1. **Banco de Dados PostgreSQL**:
   - Configurado com credenciais fortes
   - Backup automático configurado
   - Otimizado para produção

2. **Variáveis de Ambiente Seguras**:
   - **JWT_SECRET**: Use uma string de 32+ caracteres alfanuméricos
   - **WHATSAPP_API_TOKEN**: Token válido do Meta for Developers
   - **WHATSAPP_PHONE_NUMBER_ID**: ID do número WhatsApp Business
   - **VERIFY_TOKEN**: Token único para validação de webhook

3. **Servidores Web**:
   - **Frontend**: Servidor estático (nginx, apache, ou CDN)
   - **Backend**: Node.js com PM2 ou similar para processo daemon
   - **N8N**: Opcional, para automação avançada

4. **Configurações de Email**:
   - **SMTP**: Configurado com serviço de email confiável
   - **Autenticação**: Habilitada para envio de mensagens

### 🔒 Segurança Obrigatória

- **HTTPS**: Certificado SSL configurado
- **CORS**: Configurado para domínio específico
- **Rate Limiting**: Limite de requisições por IP
- **Validação JWT**: Tokens verificados em todas rotas protegidas
- **Sanitização**: Inputs validados e limpos
- **Headers**: Security headers configurados

### 📊 Monitoramento e Logs

```bash
# Monitoramento de Processos
pm2 monit

# Logs em Tempo Real
pm2 logs crm-backend
tail -f /var/log/crm/*.log

# Logs Docker
docker-compose logs -f backend
```

### 🔄 Backup e Recuperação

```bash
# Backup Banco de Dados
pg_dump crm_db > backup_$(date +%Y%m%d).sql

# Backup N8N
tar -czf n8n_backup_$(date +%Y%m%d).tar.gz .n8n/

# Restauração
psql crm_db < backup_YYYYMMDD.sql
```

## 🌐 Serviços de Deploy

### Opções Recomendadas

#### **Cloud VPS**
- **DigitalOcean**: $20-50/mês
- **Linode**: $20-50/mês
- **AWS EC2**: $25-60/mês

#### **PaaS (Platform as a Service)**
- **Heroku**: $25-250/mês
- **Render**: $20-100/mês
- **Railway**: $20-80/mês

#### **Serviços Gerenciados**
- **AWS RDS**: $25-200/mês (banco de dados)
- **Vercel**: $20-400/mês (frontend)
- **AWS ECS**: $30-150/mês (contêineres)

## 📱 Integração WhatsApp Completa

### Configuração Meta for Developers

1. **Criar Aplicação Business**:
   - Acesse [developers.facebook.com](https://developers.facebook.com)
   - Criar App → Business → WhatsApp
   - Preencher informações básicas

2. **Configurar Webhook**:
   ```bash
   # URL de Webhook Produção
   https://seu-dominio.com/api/whatsapp/webhook
   
   # Verificar Token
   # Token deve coincidir com VERIFY_TOKEN no .env
   ```

3. **Obter Credenciais**:
   - **API Token**: Dashboard da App → WhatsApp → API Setup
   - **Phone Number ID**: WhatsApp → Phone Numbers → Select Number

### Testes e Validação

```bash
# Testar Webhook Localmente
ngrok http 3001
# Configurar URL do ngrok no Meta Developer

# Verificar Status WhatsApp
curl https://graph.facebook.com/v18.0/PHONE_NUMBER_ID \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## 📈 Performance e Escalabilidade

### Otimizações de Produção

```bash
# Frontend Build Otimizado
npm run build
# Configurar CDN (CloudFront, Cloudflare)

# Backend PM2 Cluster
pm2 start ecosystem.config.js --env production

# PostgreSQL Otimizado
# Configurar connection pooling
# Indexes otimizados
```

### Cache e CDN

```nginx
# Nginx Cache Configuration
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
  expires 1y;
  add_header Cache-Control "public, immutable";
}
```

## 🔧 Manutenção e Suporte

### Logs e Diagnóstico

```bash
# Verificar Logs de Erros
grep -i error /var/log/crm/app.log

# Monitorar Performance
htop
iostat -x 1

# Testar Conectividade
curl -I https://api.seu-dominio.com/health
```

### Atualizações e Patches

```bash
# Atualizar Dependências
npm audit fix
npm update

# Backup Antes de Atualizar
docker-compose down
docker-compose pull
docker-compose up -d
```

## 📋 Checklist de Deploy Produção

### ✅ Pré-Deploy

- [ ] Configurar todas variáveis de ambiente
- [ ] Configurar banco de dados PostgreSQL
- [ ] Obter credenciais WhatsApp Business
- [ ] Configurar servidor web (nginx/apache)
- [ ] Configurar certificado SSL
- [ ] Configurar backup automático
- [ ] Testar todos os endpoints
- [ ] Testar integração WhatsApp
- [ ] Configurar monitoramento
- [ ] Documentar procedimentos

### ✅ Pós-Deploy

- [ ] Verificar logs de erro
- [ ] Testar funcionalidades críticas
- [ ] Configurar alertas
- [ ] Monitorar performance
- [ ] Testar backup e restauração

## 🚀 Deploy Automatizado (Opcional)

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
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
        run: |
          # Script de deploy
```

### Docker Compose Produção

```bash
# Deploy com Docker
docker-compose -f docker-compose.prod.yml up -d

# Escalonamento
docker-compose up -d --scale backend=3
```

## 📞 Suporte e Emergência

### Contatos e Recursos

- **Documentação**: [docs/](./docs/)
- **Issues**: [GitHub Issues](https://github.com/PedroPaduelo/crm-teste-n8n/issues)
- **Email de Suporte**: support@seu-dominio.com

### Troubleshooting Comum

```bash
# Resetar Banco de Dados
npm run db:reset

# Limpar Cache
npm run cache:clear

# Reiniciar Serviços
pm2 restart all
docker-compose restart
```

---

**Status: Pronto para Produção** ✅

**Versão: 1.0.0**
**Última Atualização: 2024**