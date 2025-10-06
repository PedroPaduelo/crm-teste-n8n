# Usar imagem Node.js Alpine para menor tamanho
FROM node:18-alpine AS base

# Instalar dependências do sistema
RUN apk add --no-cache \
    curl \
    dumb-init

# Diretório de trabalho
WORKDIR /app

# Copiar arquivos de package
COPY package*.json ./

# Instalar dependências de produção
RUN npm ci --only=production && npm cache clean --force

# Criar usuário não-root para segurança
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Fase de build
FROM base AS builder

# Instalar todas as dependências incluindo development
RUN npm ci

# Copiar código fonte
COPY . .

# Compilar TypeScript
RUN npm run build

# Fase de produção
FROM base AS production

# Copiar arquivos compilados do builder
COPY --from=builder /app/dist ./dist

# Copiar arquivos de template
COPY --from=builder /app/src/views ./src/views

# Criar diretórios necessários
RUN mkdir -p uploads logs && \
    chown -R nodejs:nodejs /app

# Mudar para usuário não-root
USER nodejs

# Expor porta
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3001/health || exit 1

# Iniciar aplicação com dumb-init
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/index.js"]