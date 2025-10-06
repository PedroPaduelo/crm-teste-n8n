# Backend do CRM com Integração N8N

Este projeto contém o backend para o sistema CRM, desenvolvido com Node.js, Express e TypeScript.

## 🚀 Configuração

### Pré-requisitos
- Node.js (v18+)
- npm ou yarn

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

## 📋 Scripts Disponíveis

```bash
# Iniciar servidor em modo desenvolvimento
npm run dev

# Iniciar servidor usando o arquivo server.ts (para teste)
npm run dev:server

# Compilar projeto TypeScript
npm run build

# Compilar apenas o server.ts para teste
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

## 🔧 Teste de Compilação

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
│   ├── controllers/     # Controladores das rotas
│   ├── middleware/      # Middleware do Express
│   ├── routes/          # Definição das rotas
│   ├── services/        # Lógica de negócio
│   ├── types/           # Definições de tipos TypeScript
│   ├── utils/           # Utilitários
│   ├── index.ts         # Arquivo principal do servidor
│   └── server.ts        # Arquivo para teste de compilação
├── dist/                # Arquivos compilados (gerado automaticamente)
├── package.json
├── tsconfig.json
└── .env.example
```

## 🌐 Endpoints Disponíveis

- `GET /` - Mensagem de boas-vindas
- `GET /health` - Status do servidor
- `GET /api/status` - Status detalhado do sistema
- `GET /api/test-typescript` - Teste de compilação TypeScript

## 🛠️ Tecnologias Utilizadas

- Node.js
- Express.js
- TypeScript
- ESLint
- ts-node