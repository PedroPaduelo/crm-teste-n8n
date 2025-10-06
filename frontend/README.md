# Frontend do CRM

Aplicação frontend desenvolvida com React, TypeScript e Vite para o sistema CRM com integração N8N.

## 🚀 Quick Start

### Pré-requisitos

- Node.js 18+
- npm ou yarn

### Instalação

1. Clone o repositório:
```bash
git clone https://github.com/PedroPaduelo/crm-teste-n8n.git
```

2. Navegue até a pasta frontend:
```bash
cd frontend
```

3. Instale as dependências:
```bash
npm install
```

4. Configure as variáveis de ambiente:
```bash
cp .env.example .env
```

5. Configure as variáveis no arquivo `.env`:
```env
VITE_API_URL=http://localhost:3001
VITE_N8N_WEBHOOK_URL=http://localhost:5678/webhook
```

### Scripts Disponíveis

```bash
# Desenvolvimento
npm run dev

# Build para produção
npm run build

# Preview do build
npm run preview

# Linting
npm run lint
```

### 🌐 Acesso

- Frontend: http://localhost:5173 (modo desenvolvimento)
- Preview: http://localhost:4173 (após build)

## 🔧 Configuração

### Variáveis de Ambiente

Configure as seguintes variáveis no arquivo `.env`:

```env
# URL da API do Backend
VITE_API_URL=http://localhost:3001

# URL do N8N (se necessário)
VITE_N8N_WEBHOOK_URL=http://localhost:5678/webhook

# Configurações do WhatsApp (se necessário)
VITE_WHATSAPP_PHONE_NUMBER_ID=your-whatsapp-phone-number-id

# Configurações de Ambiente
VITE_NODE_ENV=development

# Configurações de Analytics (opcional)
VITE_GA_TRACKING_ID=your-google-analytics-tracking-id

# Configurações de Mapas (opcional)
VITE_MAPBOX_API_KEY=your-mapbox-api-key

# Configurações de Pagamento (opcional)
VITE_STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
```

## 🏗️ Estrutura do Projeto

```
frontend/
├── src/
│   ├── components/          # Componentes React
│   ├── pages/              # Páginas da aplicação
│   ├── hooks/              # Hooks personalizados
│   ├── services/           # Serviços de API
│   ├── types/              # Definições TypeScript
│   ├── utils/              # Utilitários
│   ├── assets/             # Assets estáticos
│   ├── App.tsx             # Componente principal
│   ├── main.tsx            # Ponto de entrada
│   └── index.css           # Estilos globais
├── public/                 # Arquivos públicos
├── dist/                   # Build de produção (gerado)
├── package.json            # Dependências e scripts
├── vite.config.ts          # Configuração do Vite
├── tsconfig.json           # Configuração TypeScript
└── .env.example            # Variáveis de ambiente exemplo
```

## 🎨 Tecnologias Utilizadas

- **React 18** - Biblioteca UI
- **TypeScript** - Tipagem estática
- **Vite** - Build tool e dev server
- **React Router DOM** - Roteamento
- **Axios** - Client HTTP
- **Lucide React** - Ícones
- **Tailwind CSS** - Framework CSS

## 🚀 Deploy em Produção

### 1. Build da Aplicação

```bash
npm run build
```

### 2. Deploy da Pasta `dist`

A pasta `dist` contém os arquivos estáticos prontos para deploy.

### 3. Opções de Hospedagem

#### Vercel
```bash
# Instalar Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

#### Netlify
```bash
# Instalar Netlify CLI
npm i -g netlify-cli

# Deploy
netlify deploy --prod --dir=dist
```

#### Nginx (VPS)
```nginx
server {
    listen 80;
    server_name seu-dominio.com;
    root /path/to/frontend/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Configurar proxy para API
    location /api {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 4. Configuração de CORS

Certifique-se de que o backend está configurado para aceitar requisições do domínio do frontend em produção.

## 🔧 Desenvolvimento

### Adicionando Novas Páginas

1. Crie o componente em `src/pages/`
2. Configure a rota em `src/App.tsx` ou no arquivo de rotas
3. Exporte o componente

### Consumindo a API

Use o serviço de API configurado em `src/services/`:

```typescript
import { apiService } from '@/services/api';

// Exemplo de uso
const response = await apiService.get('/customers');
```

### Estilização

- Use Tailwind CSS para estilização
- Componentes seguem o padrão do design system
- Estilos responsivos por padrão

## 🚨 Boas Práticas

- Use TypeScript para todas as novas funcionalidades
- Mantenha componentes pequenos e focados (< 250 linhas)
- Use hooks personalizados para lógica compartilhada
- Implemente tratamento de erros com Toast
- Mantenha o código limpo e documentado

## 🐛 Troubleshooting

### Problemas Comuns

1. **Erro de CORS**: Verifique a configuração do backend
2. **Variáveis de ambiente não encontradas**: Verifique o arquivo `.env`
3. **Build falha**: Verifique imports e tipos TypeScript
4. **Roteamento não funciona**: Verifique configuração do servidor em produção

### Logs de Depuração

```bash
# Ver logs de build
npm run build -- --verbose

# Ver análise de bundle
npm run build -- --analyze
```

## 📝 Documentação

- [Backend Documentation](../backend/README.md)
- [API Reference](../docs/api.md)
- [Deploy Guide](../docs/deploy.md)

## 🤝 Contribuindo

1. Fork o projeto
2. Crie branch para feature (`git checkout -b feature/nova-funcionalidade`)
3. Commit mudanças (`git commit -am 'Add nova funcionalidade'`)
4. Push para branch (`git push origin feature/nova-funcionalidade`)
5. Abra Pull Request

## 📄 Licença

Este projeto está sob licença MIT.

## 🆘 Suporte

Para suporte:

- Abra uma Issue no GitHub
- Email: support@seu-dominio.com
- Documentação: [Wiki do Projeto](https://github.com/PedroPaduelo/crm-teste-n8n/wiki)

---

**Desenvolvido com ❤️ usando React, TypeScript e Vite**