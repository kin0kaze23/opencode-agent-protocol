---
name: slim
description: Local HTTPS tunneling and reverse proxy for development
---

# Slim.sh Skill

Local development tunneling tool that provides HTTPS `.test` domains and public URL sharing.

## What is Slim.sh?

- Maps `localhost:3000` → `https://myapp.test`
- Supports path routing (one domain for frontend + backend)
- Public URL sharing (like ngrok)
- Automatic HTTPS with trusted certificates

## Installation

```bash
curl -sL https://slim.sh/install.sh | sh
```

Or build from source:
```bash
git clone https://github.com/kamranahmedse/slim.git
cd slim
make build
make install
```

## Use Cases

| Use Case | When to Use |
|----------|-------------|
| **HTTPS for webhooks** | Stripe, payment, OAuth callbacks need HTTPS |
| **Third-party OAuth** | Google, GitHub login callbacks |
| **Demo to others** | Share local app without deploying |
| **Clean local URLs** | Prefer `app.test` over `localhost:3000` |
| **Multi-app on one domain** | Frontend + API on same domain |

## Quick Commands

### Local HTTPS

```bash
# Start proxying to a .test domain
slim start myapp --port 3000
# Opens https://myapp.test → localhost:3000

# With path routing (frontend + API)
slim start myapp --port 3000 --route /api=8080
# https://myapp.test → localhost:3000
# https://myapp.test/api → localhost:8080
```

### Public URL Sharing

```bash
# Authenticate first
slim login

# Share with custom subdomain
slim share --port 3000 --subdomain myapp
# → https://myapp.slim.show

# Share with password protection
slim share --port 3000 --password --ttl 30m
# → https://abc123.slim.show (expires in 30 min)
```

### Project Config (.slim.yaml)

```yaml
# .slim.yaml - place at project root
services:
  - domain: myapp
    port: 3000
    routes:
      - path: /api
        port: 8080
  - domain: dashboard
    port: 5173
log_mode: minimal
```

```bash
slim up          # Start all services
slim down        # Stop all services
slim list        # Show running domains
slim logs        # View access logs
slim doctor      # Diagnose issues
```

## Project-Specific Setup

### StableVault (React + Express)

```yaml
# StableVault/.slim.yaml
services:
  - domain: stablevault
    port: 5173
    routes:
      - path: /api
        port: 3000
log_mode: minimal
```

### ClearPathOS (Next.js)

```yaml
# ClearPathOS/.slim.yaml
services:
  - domain: clearpath
    port: 3004
log_mode: minimal
```

### sample-service (React + Hono + n8n)

```yaml
# sample-service/.slim.yaml
services:
  - domain: automation
    port: 3003
    routes:
      - path: /api
        port: 4000
  - domain: n8n
    port: 5678
log_mode: minimal
```

### example-analyzer

```yaml
# example-analyzer/.slim.yaml
services:
  - domain: portfolio
    port: 3005
log_mode: minimal
```

### example-dashboard

```yaml
# example-dashboard/.slim.yaml
services:
  - domain: eliza
    port: 5000
log_mode: minimal
```

## Security Considerations

| Aspect | Notes |
|--------|-------|
| **Root CA** | Generated on first run, trusted in system keychain |
| **Local only** | `.test` domains only resolve locally |
| **Public sharing** | Use `--password` for sensitive demos |
| **Auto-expiry** | Use `--ttl` for time-limited public URLs |
| **Uninstall** | Run `slim uninstall` to remove CA and all config |

## Troubleshooting

```bash
# Check setup status
slim doctor

# View logs
slim logs -f myapp

# Stop specific domain
slim stop myapp

# Stop all and shutdown daemon
slim stop
```

## Comparison with Alternatives

| Tool | Local .test | Public Sharing | Path Routing | Auth |
|------|-------------|----------------|--------------|------|
| **Slim.sh** | ✅ | ✅ | ✅ | ✅ Password |
| **ngrok** | ❌ | ✅ | ✅ | ✅ Basic auth |
| **Cloudflare Tunnel** | ❌ | ✅ | ✅ | ✅ Zero-trust |
| **localtunnel** | ❌ | ✅ | ❌ | ❌ |

## Best Practices

1. **Use .slim.yaml** — Commit to repo so team can run `slim up`
2. **Password protect** — Always use `--password` for public demos
3. **Short TTL** — Use `--ttl` for time-limited sharing
4. **Run doctor** — If something breaks, `slim doctor` first
5. **Clean up** — Run `slim stop` when done, not just Ctrl+C

## Output format

Produce a Slim tunnel report in this exact format:

```
## Slim Tunnel — <domain name>

**Domain:** <local .test domain>
**Port:** <local port>
**Target:** <target URL or "N/A">

### Tunnel status
- HTTPS: <enabled / disabled>
- Public URL: <URL or "local only">
- Auth: <password / none>
- TTL: <duration or "none">

### Verification
- [ ] `slim doctor` passes
- [ ] HTTPS certificate valid
- [ ] Target responds on local port
- [ ] Public URL accessible (if configured)
```

## Out of Scope

This skill does NOT:
- Replace production deployment (that is deployment/SKILL.md)
- Fix target application bugs (that is /debug)
- Replace ngrok or Cloudflare Tunnel for enterprise use cases
- Manage DNS or domain registration
- Replace the slim CLI for advanced configuration (use slim CLI docs directly)
- Set up permanent public hosting (this is for local development tunneling only)