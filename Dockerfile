# ─────────────────────────────────────────────
# Stage 1: Builder — instala dependencias y construye el sitio estático
# ─────────────────────────────────────────────
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

WORKDIR /app

# Copiar solo los archivos de dependencias primero (mejor cache de capas)
COPY pyproject.toml uv.lock ./

# Instalar dependencias sin instalar el propio proyecto
RUN uv sync --frozen --no-install-project --no-dev

# Copiar el resto del proyecto y construir
COPY mkdocs.yml ./
COPY docs/ ./docs/

RUN uv run mkdocs build --strict --clean

# ─────────────────────────────────────────────
# Stage 2: Serve — nginx:alpine sirve el HTML estático (~25 MB final)
# ─────────────────────────────────────────────
FROM nginx:1.27-alpine AS serve

LABEL org.opencontainers.image.title="Angular: La Guía en Español"
LABEL org.opencontainers.image.description="Sitio de documentación de la guía de Angular en español"
LABEL org.opencontainers.image.source="https://github.com/jhonsferg/spanish-angular-guide"

# Eliminar contenido por defecto de nginx
RUN rm -rf /usr/share/nginx/html/*

# Copiar el sitio generado desde el builder
COPY --from=builder /app/site /usr/share/nginx/html

# Configuración de nginx optimizada para sitio estático
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
