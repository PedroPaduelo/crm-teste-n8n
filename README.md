# CRM com Integração n8n

Um sistema de CRM (Customer Relationship Management) moderno com integração n8n para automação de workflows.

## 📋 Sobre o Projeto

Este projeto é um sistema CRM desenvolvido com foco em automação e integração com n8n, permitindo criar workflows automatizados para gerenciamento de relacionamento com clientes.

## ✨ Características

- 🚀 API Backend desenvolvida em TypeScript com Express.js
- 🔄 Integração com n8n para automação de workflows
- 💼 Gerenciamento de clientes e contatos
- 📊 Dashboard com métricas e relatórios
- 🔐 Sistema de autenticação seguro
- 📱 API RESTful para integração com outros sistemas

## 🛠️ Tecnologias Utilizadas

### Backend
- **Node.js** - Ambiente de execução JavaScript
- **Express.js** - Framework web minimalista
- **TypeScript** - Superset tipado de JavaScript
- **CORS** - Middleware para Cross-Origin Resource Sharing

### Integrações
- **n8n** - Plataforma de automação de workflows

## 📋 Pré-requisitos

Antes de começar, certifique-se de ter instalado em sua máquina:

- [Node.js](https://nodejs.org/) (versão 14 ou superior)
- [npm](https://www.npmjs.com/) ou [yarn](https://yarnpkg.com/)
- [Git](https://git-scm.com/)

## 🚀 Instalação

1. Clone o repositório:
```bash
git clone https://github.com/PedroPaduelo/crm-teste-n8n.git
cd crm-teste-n8n
```

2. Instale as dependências do backend:
```bash
cd backend
npm install
```

3. Configure as variáveis de ambiente:
```bash
cp .env.example .env
```

Edite o arquivo `.env` com suas configurações.

## 💻 Uso

### Iniciar o Servidor Backend

```bash
cd backend
npm run dev
```

O servidor estará disponível em `http://localhost:3001`

### Endpoints Disponíveis

- `GET /` - Mensagem de boas-vindas da API
- `GET /health` - Verificação de saúde do servidor

### Health Check

Para verificar se o servidor está funcionando:

```bash
curl http://localhost:3001/health
```

Resposta esperada:
```json
{
  "status": "OK",
  "timestamp": "2025-10-06T05:11:00.000Z"
}
```

## 📁 Estrutura do Projeto

```
crm-teste-n8n/
├── backend/              # API Backend
│   ├── src/             # Código fonte
│   │   └── index.ts     # Ponto de entrada da aplicação
│   ├── package.json     # Dependências do backend
│   └── tsconfig.json    # Configuração TypeScript
├── README.md            # Documentação do projeto
└── .gitignore          # Arquivos ignorados pelo Git
```

## 🔧 Configuração

### Variáveis de Ambiente

O projeto utiliza as seguintes variáveis de ambiente:

- `PORT` - Porta do servidor backend (padrão: 3001)

## 🧪 Testes

Para executar os testes:

```bash
cd backend
npm test
```

## 📦 Build

Para gerar a versão de produção:

```bash
cd backend
npm run build
```

## 🔗 Integração com n8n

Este CRM foi projetado para integrar com n8n, permitindo criar automações como:

- Envio automático de emails para novos clientes
- Notificações de follow-up
- Sincronização com outros sistemas
- Geração de relatórios automatizados

### Configurando Webhooks

Configure webhooks no n8n apontando para os endpoints da API do CRM para acionar automações.

## 🤝 Contribuindo

Contribuições são sempre bem-vindas! Para contribuir:

1. Faça um Fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👤 Autor

**Pedro Paduelo**

- GitHub: [@PedroPaduelo](https://github.com/PedroPaduelo)

## 📧 Contato

Para questões e suporte, abra uma [issue](https://github.com/PedroPaduelo/crm-teste-n8n/issues) no GitHub.

---

⭐️ Se este projeto foi útil para você, considere dar uma estrela no repositório!