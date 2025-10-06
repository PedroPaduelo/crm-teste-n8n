# CRM Backend

Backend do sistema CRM com integração n8n, construído com Node.js e TypeScript.

## Tecnologias

- Node.js
- TypeScript
- Express
- PostgreSQL (planejado)
- JWT (planejado)
- Integração com N8N (planejado)

## Estrutura do Projeto

```
backend/
├── src/
│   ├── controllers/     # Controladores das rotas
│   ├── middleware/      # Middlewares (autenticação, validação)
│   ├── routes/          # Definição das rotas
│   ├── services/        # Lógica de negócio
│   ├── types/           # Tipos TypeScript
│   ├── utils/           # Utilitários
│   └── index.ts         # Ponto de entrada
├── dist/                # Arquivos compilados
├── package.json
├── tsconfig.json
└── README.md
```

## Instalação

1. Clone o repositório
2. Navegue até a pasta backend:
   ```bash
   cd backend
   ```
3. Instale as dependências:
   ```bash
   npm install
   ```

## Configuração

1. Copie o arquivo de variáveis de ambiente:
   ```bash
   cp .env.example .env
   ```

2. Configure as variáveis de ambiente no arquivo `.env`:
   - `PORT`: Porta do servidor (padrão: 3001)
   - `DATABASE_URL`: URL de conexão com o banco PostgreSQL
   - `JWT_SECRET`: Chave secreta para JWT
   - `N8N_WEBHOOK_URL`: URL do webhook do N8N

## Scripts Disponíveis

- `npm run dev`: Inicia o servidor em modo desenvolvimento
- `npm run build`: Compila o código TypeScript
- `npm run start`: Inicia o servidor em modo produção
- `npm run lint`: Executa o ESLint
- `npm run test`: Executa os testes

## Desenvolvimento

Para iniciar o servidor em modo desenvolvimento:

```bash
npm run dev
```

O servidor estará disponível em `http://localhost:3001`

## Endpoints

### Health Check
- `GET /` - Verifica se o servidor está online
- `GET /health` - Health check detalhado

### API (planejado)
- `POST /api/auth/login` - Login de usuário
- `GET /api/customers` - Lista clientes
- `POST /api/customers` - Cria cliente
- `PUT /api/customers/:id` - Atualiza cliente
- `DELETE /api/customers/:id` - Remove cliente

## Integração com N8N

O backend será configurado para se integrar com workflows do N8N através de webhooks, permitindo automação de processos de negócio.