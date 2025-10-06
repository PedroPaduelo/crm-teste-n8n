# Backend do CRM com Integração N8N

Este projeto contém o backend para o sistema CRM, desenvolvido com Node.js, Express e TypeScript.

## 🚀 Configuração

### Pré-requisitos
- Node.js (v18+)
- npm ou yarn
- PostgreSQL (banco de dados)
- Conta WhatsApp Business com API (opcional)

### Instalação

1. Clone o repositório
2. Navegue até a pasta backend
3. Instale as dependências:

```bash
cd backend
npm install
```

4. Crie um arquivo `.env` baseado no `.env.example`:

```bash
cp .env.example .env
```

5. Configure as variáveis de ambiente no arquivo `.env`:

### Variáveis de Ambiente

O sistema requer as seguintes variáveis de ambiente para funcionar corretamente:

```bash
# Configurações do Servidor
PORT=3001
NODE_ENV=development

# Configurações de Banco de Dados
DATABASE_URL=postgresql://usuario:senha@localhost:5432/crm_db

# JWT Secret
JWT_SECRET=seu-segredo-jwt-super-secreto-mude-em-producao

# Configurações do WhatsApp (obrigatório)
WHATSAPP_API_TOKEN=seu-token-api-whatsapp
WHATSAPP_PHONE_NUMBER_ID=seu-id-numero-whatsapp
VERIFY_TOKEN=seu-token-verificacao-webhook

# Configurações do N8N (opcional)
N8N_WEBHOOK_URL=http://localhost:5678/webhook
N8N_API_KEY=sua-chave-api-n8n

# Configurações de Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=seu-email@gmail.com
SMTP_PASS=sua-senha-app
```

### Configuração do WhatsApp Business API

Para configurar a integração com WhatsApp:

1. **Criar Meta Developer Account**: Acesse [developers.facebook.com](https://developers.facebook.com)
2. **Criar Aplicação Meta**: 
   - Vá para "Meus Apps" → "Criar App"
   - Selecione "Business" → "WhatsApp"
3. **Configurar WhatsApp**:
   - Adicione seu número de telefone
   - Configure o webhook (use ngrok para desenvolvimento)
   - Obtenha o `WHATSAPP_API_TOKEN` e `WHATSAPP_PHONE_NUMBER_ID`
4. **Webhook Setup**:
   - URL do webhook: `https://seu-dominio.com/api/whatsapp/webhook`
   - Verify Token: use o valor configurado em `VERIFY_TOKEN`

### Scripts Disponíveis

```bash
# Iniciar servidor em modo desenvolvimento
npm run dev

# Iniciar servidor usando o server.ts (para teste)
npm run dev:server

# Compilar projeto TypeScript
npm run build

# Compilar e executar o server.ts para teste
npm run build:server

# Iniciar servidor em produção
npm start

# Iniciar servidor usando o server.ts em produção
npm run start:server

# Executar linting
npm run lint

# Executar testes
npm test
```

## 🛠️ Teste de Compilação

Para testar se a configuração TypeScript está funcionando corretamente:

1. **Teste de compilação do server.ts**:
```bash
npm run dev:server
```
Este comando irá compilar e executar o arquivo `src/server.ts`, mostrando se a configuração TypeScript está correta.

2. **Compilação para produção**:
```bash
npm run build:server
```
Este comando irá gerar o arquivo compilado `dist/server.js`.

## 📁 Estrutura do Projeto

```
backend/
├── src/
│   ├── controllers/       # Controllers das rotas
│   ├── middleware/        # Middleware do Express
│   ├── routes/            # Definição das rotas
│   ├── services/          # Lógica de negócio
│   ├── types/             # Definições de tipos TypeScript
│   ├── utils/             # Utilitários
│   ├── index.ts           # Arquivo principal do servidor
│   └── server.ts          # Arquivo para teste de compilação
├── dist/                  # Arquivos compilados (gerado automaticamente)
├── package.json
├── tsconfig.json
├── .env.example
└── .env                   # Não commitar - contém segredos
```

## 🔗 Endpoints Disponíveis

- `GET /` - Mensagem de boas-vindas
- `GET /health` - Status do servidor
- `GET /api/status` - Status detalhado do sistema
- `GET /api/test-typescript` - Teste de compilação TypeScript
- `POST /api/whatsapp/webhook` - Webhook do WhatsApp (quando configurado)

## 🌍 Desenvolvimento com ngrok

Para desenvolvimento local com webhook do WhatsApp:

1. **Instalar ngrok**:
```bash
# Windows
choco install ngrok

# macOS
brew install ngrok

# Linux
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && sudo apt update && sudo apt install ngrok
```

2. **Expor porta local**:
```bash
ngrok http 3001
```

3. **Configurar webhook**:
   - Use a URL gerada pelo ngrok no Meta Developer Portal
   - Exemplo: `https://abc123.ngrok.io/api/whatsapp/webhook`

## 🚀 Deploy em Produção

### Opções de Hospedagem

1. **VPS/Dedicado**:
   - Ubuntu 20.04+ / CentOS 8+
   - Docker recomendado
   - Nginx como reverse proxy

2. **Cloud Platforms**:
   - AWS EC2 + RDS
   - Google Cloud Platform
   - Azure App Service
   - DigitalOcean Droplet + Managed Database

3. **PaaS**:
   - Heroku (com add-ons)
   - Render.com
   - Railway.app

### Passos para Deploy

1. **Preparar ambiente de produção**:
```bash
# Configurar NODE_ENV=production
NODE_ENV=production

# Instalar dependências de produção
npm ci --only=production

# Compilar projeto
npm run build

# Iniciar servidor
npm start
```

2. **Configurar processo com PM2**:
```bash
# Instalar PM2 globalmente
npm install -g pm2

# Iniciar aplicação
pm2 start dist/index.js --name crm-backend

# Salvar configuração
pm2 save

# Configurar startup automático
pm2 startup
```

3. **Configurar reverse proxy (Nginx)**:
```nginx
server {
    listen 80;
    server_name seu-dominio.com;

    location / {
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
}
```

### Variáveis de Ambiente em Produção

⚠️ **IMPORTANTE**: Nunca faza commit do arquivo `.env` no controle de versão!

- Use serviços de gerenciamento de segredos (AWS Secrets Manager, HashiCorp Vault)
- Ou configure como variáveis de ambiente no servidor
- Ou use arquivos de configuração específicos do ambiente

### Backup e Monitoramento

1. **Backup do banco de dados**:
```bash
# Backup diário automatizado
pg_dump crm_db > backup_$(date +%Y%m%d).sql
```

2. **Monitoramento**:
   - Configure logs para monitoramento
   - Use ferramentas como New Relic, DataDog ou Grafana
   - Configure alertas para erros e downtime

## 🛡️ Segurança

- Configure CORS para domains específicos
- Use HTTPS em produção
- Valide tokens JWT
- Implemente rate limiting
- Sanitize inputs de usuários
- Configure headers de segurança

## 📝 Logs e Debug

Em desenvolvimento, logs são exibidos no console. Em produção:

```bash
# Ver logs PM2
pm2 logs crm-backend

# Ver logs específicos
tail -f /var/log/crm/app.log
```

## 📚 Tecnologias Utilizadas

- Node.js
- Express.js
- TypeScript
- ESLint
- PostgreSQL
- JWT (jsonwebtoken)
- Nodemailer
- WhatsApp Business API