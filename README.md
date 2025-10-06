# CRM com Integração N8N

Sistema CRM (Customer Relationship Management) desenvolvido com integração com N8N para automação de processos e WhatsApp Business API para comunicação com clientes.

## 🏗️ Arquitetura do Projeto

```
crm-teste-n8n/
├── backend/               # API RESTful com Node.js + Express + TypeScript
├── frontend/              # Aplicação web React + TypeScript
└── README.md              # Este arquivo
```

## 🚀 Quick Start

### Pré-requisitos

- Node.js 18+
- PostgreSQL 13+
- Conta WhatsApp Business (para integração)
- N8N (opcional, para automação)

### 1. Configuração do Backend

```bash
# Navegar para pasta do backend
cd backend

# Instalar dependências
npm install

# Copiar arquivo de ambiente
cp .env.example .env

# Configurar variáveis de ambiente (veja seção Configuração)
```

### 2. Configuração do Frontend

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

Acesse:
- Frontend: http://localhost:5173
- Backend API: http://localhost:3001
- Health Check: http://localhost:3001/health

## ⚙️ Configuração

### Variáveis de Ambiente Obrigatórias

No arquivo `backend/.env`, configure as seguintes variáveis:

```bash
# Database
DATABASE_URL=postgresql://usuario:senha@localhost:5432/crm_db

# JWT
JWT_SECRET=seu-segredo-jwt-muito-seguro

# WhatsApp Business API
WHATSAPP_API_TOKEN=seu-token-api-whatsapp
WHATSAPP_PHONE_NUMBER_ID=seu-id-numero-whatsapp
VERIFY_TOKEN=seu-token-verificacao-webhook
```

### Configuração do WhatsApp Business

1. **Criar conta Meta Developer**: Acesse [developers.facebook.com](https://developers.facebook.com)
2. **Criar aplicação WhatsApp**:
   - Business → WhatsApp
   - Configure webhook e número de telefone
3. **Obter credenciais**:
   - API Token (painel da aplicação)
   - Phone Number ID (painel do WhatsApp)
4. **Configurar webhook**:
   - URL: `https://seu-dominio.com/api/whatsapp/webhook`
   - Verify Token: configure no Meta e no `.env`

### Banco de Dados

```sql
-- Criar banco de dados
CREATE DATABASE crm_db;

-- Criar usuário (opcional)
CREATE USER crm_user WITH PASSWORD 'senha_segura';
GRANT ALL PRIVILEGES ON DATABASE crm_db TO crm_user;
```

## 🛠️ Desenvolvimento

### Scripts Úteis

```bash
# Backend
npm run dev              # Servidor desenvolvimento
npm run build            # Compilar TypeScript
npm start                # Servidor produção

# Frontend
npm run dev              # Servidor desenvolvimento
npm run build            # Build para produção
npm run preview          # Preview do build
```

### ngrok para Webhooks

Para testar webhooks localmente:

```bash
# Expor backend
ngrok http 3001

# Usar URL gerida no Meta Developer Portal
# Ex: https://abc123.ngrok.io/api/whatsapp/webhook
```

## 🚀 Deploy em Produção

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

# Deploy da pasta dist/
# Configure servidor web para servir arquivos estáticos
```

### Opções de Hospedagem

#### Backend
- **VPS**: DigitalOcean, Linode, AWS EC2
- **PaaS**: Heroku, Render, Railway
- **Container**: Docker + Kubernetes

#### Frontend
- **Static Hosting**: Vercel, Netlify, GitHub Pages
- **CDN**: AWS S3 + CloudFront
- **VPS**: Nginx + Apache

## 📱 Integração com N8N

O sistema integra com N8N para automação:

1. **Configurar webhooks** no N8N:
   - URL: `http://localhost:5678/webhook`
2. **Automações disponíveis**:
   - Novos leads
   - Atualizações de clientes
   - Envio de mensagens WhatsApp
   - Disparos de emails

## 🔧 Funcionalidades

### CRM Core
- ✅ Gestão de clientes
- ✅ Controle de leads
- ✅ Histórico de interações
- ✅ Pipeline de vendas

### Comunicação
- ✅ WhatsApp Business API
- ✅ Envio de emails
- ✅ Notificações automáticas

### Automação
- ✅ Integração N8N
- ✅ Webhooks personalizados
- ✅ Fluxos de trabalho

## 📚 Documentação

- [Backend Documentation](./backend/README.md)
- [Frontend Documentation](./frontend/README.md)
- [API Reference](./docs/api.md) *(em construção)*
- [Deploy Guide](./docs/deploy.md) *(em construção)*

## 🤝 Contribuindo

1. Fork o projeto
2. Crie branch para feature (`git checkout -b feature/nova-funcionalidade`)
3. Commit changes (`git commit -am 'Add nova funcionalidade'`)
4. Push para branch (`git push origin feature/nova-funcionalidade`)
5. Abra Pull Request

## 📄 Licença

Este projeto está sob licença MIT. Veja [LICENSE](LICENSE) para mais detalhes.

## 🆘 Suporte

Para suporte:

- Abra uma Issue no GitHub
- Email: support@seu-dominio.com
- Documentação: [Wiki do Projeto](https://github.com/PedroPaduelo/crm-teste-n8n/wiki)

## 🔄 Status do Projeto

- [x] Backend API básica
- [x] Configuração WhatsApp
- [x] Documentação inicial
- [ ] Frontend completo
- [ ] Integração N8N avançada
- [ ] Testes automatizados
- [ ] CI/CD pipeline

---

**Desenvolvido com ❤️ usando Node.js, React e N8N**