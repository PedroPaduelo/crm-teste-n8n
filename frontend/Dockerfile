# Fase de build
FROM node:18-alpine AS builder

# Instalar dependências do sistema
RUN apk add --no-cache libc6-compat

WORKDIR /app

# Copiar arquivos de package
COPY package*.json ./

# Instalar dependências
RUN npm ci

# Copiar código fonte
COPY . .

# Build da aplicação
RUN npm run build

# Fase de produção
FROM nginx:alpine AS production

# Instalar curl para health check
RUN apk add --no-cache curl

# Copiar build do frontend
COPY --from=builder /app/dist /usr/share/nginx/html

# Copiar configuração customizada do Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Criar diretório para logs
RUN mkdir -p /var/log/nginx

# Mudar permissões
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/log/nginx && \
    chmod -R 755 /usr/share/nginx/html

# Mudar para usuário não-root
USER nginx

# Expor portas HTTP e HTTPS
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Iniciar Nginx
CMD ["nginx", "-g", "daemon off;"]