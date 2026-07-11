---
name: docker
description: Docker and containerization for deployments
---

# Docker Skill

Containerization guide for portfolio applications.

## Projects Using Docker

| Project | Use Case |
|---------|----------|
| example-toolchain | Main runtime |
| sample-service | n8n self-hosted |
| All backends | Production deployment |

## Dockerfile Best Practices

### Node.js/React
```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable pnpm && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

# Production stage
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 appuser

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

USER appuser
EXPOSE 3000
CMD ["node", "dist/server.js"]
```

### Multi-stage for Next.js
```dockerfile
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
ENV PORT 3000
CMD ["node", "server.js"]
```

### Rust (example-cli)
```dockerfile
FROM rust:1.75-alpine AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release
COPY . .
RUN cargo build --release

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=builder /app/target/release/ironclaw .
EXPOSE 3002
CMD ["./ironclaw"]
```

## Docker Compose

### Development
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/app
    depends_on:
      - db
      - redis

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: app
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

volumes:
  postgres_data:
```

### Production
```yaml
version: '3.8'

services:
  app:
    build: .
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      - NODE_ENV=production
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## Common Commands

```bash
# Build
docker build -t app:latest .

# Run
docker run -p 3000:3000 app:latest

# Compose
docker compose up -d
docker compose logs -f
docker compose down

# Debug
docker exec -it container_name sh
docker logs -f container_name

# Clean up
docker system prune -af
```

## Security Hardening

```dockerfile
# Don't run as root
RUN adduser --system --uid 1001 appuser
USER appuser

# Read-only filesystem (where possible)
docker run --read-only

# No secrets in image
# Use runtime environment variables
```

## Best Practices

1. **Multi-stage builds** - Reduce image size
2. **.dockerignore** - Exclude node_modules, git, etc.
3. **Non-root user** - Security first
4. **Health checks** - For orchestration
5. **Layer caching** - Copy package files first
6. **Small base images** - Alpine when possible