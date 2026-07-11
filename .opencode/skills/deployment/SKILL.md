---
name: deployment
description: Deployment workflows for Vercel, Railway, and Docker across all portfolio projects.
---

# Deployment Skill

> Canonical OpenCode runtime deployment guidance for active workspace commands.

## Procedure

Before deploying, read the following:

1. Read the repo's `AGENTS.md` to confirm the deployment platform and commands
2. Read the deployment config (`vercel.json`, `wrangler.toml`, or `Dockerfile`)
3. Read the `.env.example` to confirm all required environment variables
4. Read the recent git log to confirm the branch and commit being deployed

Then execute the deployment:

1. Run repo-native gates in order before deploy: `lint -> typecheck -> test -> build`
2. Confirm the correct branch (never deploy from `main` for preview)
3. Run the platform-specific deploy command
4. Capture the deployment URL from output
5. Run a smoke test: `curl -I <deployment-url>` — expect HTTP 200
6. Report the URL, status, and any warnings

---

## Deployment Matrix

| Project | Platform | Method | Preview |
|---------|----------|--------|---------|
| ClearPathOS | Vercel | Git push | PR previews |
| example-app | Vercel | Git push | PR previews |
| demo-project | Vercel | Git push | PR previews |
| sample-service | Railway / Docker | docker compose | Local |
| example-dashboard | Self-hosted | Manual | N/A |

---

## Pre-Deploy Gate (Mandatory)

Run repo-native gates in order before deploy:
`lint -> typecheck -> test -> build`

Never deploy with failing gates.

---

## Vercel Deployment

```bash
# Preview deploy
vercel --yes

# Production deploy
vercel --prod --yes

# Environment variables
vercel env add KEY_NAME production
```

### Pre-Vercel Checklist
- [ ] `vercel.json` has correct rewrites for SPA
- [ ] All env vars set in Vercel dashboard
- [ ] Build command matches `package.json`
- [ ] Output directory correct (`.next`, `dist`, `build`)

---

## Railway (Full-Stack with DB)

```bash
# Install Railway CLI
npm install -g @railway/cli

railway login
railway up

# Add PostgreSQL service in Railway dashboard
# Connect: railway variables → DATABASE_URL auto-set
```

### Railway Checklist
- [ ] `Dockerfile` exists and builds locally first
- [ ] `DATABASE_URL` env var set
- [ ] Health check endpoint at `/health`
- [ ] `RAILWAY_ENVIRONMENT` variable handled in code

---

## Docker Compose (Local Dev)

```bash
docker compose up -d          # start all services
docker compose logs -f api    # follow logs
docker compose down           # stop all
docker compose down -v        # stop + remove volumes
```

---

## Environment Variables

Never commit `.env` files. Use `.env.example` with all variable names (empty values).

```bash
# Check all required vars are set before deploy
node -e "
const required = ['DATABASE_URL', 'NEXTAUTH_SECRET'];
const missing = required.filter(k => !process.env[k]);
if (missing.length) { console.error('Missing:', missing); process.exit(1); }
"
```

---

## Rollback

```bash
# Vercel: instant rollback to previous deployment
vercel rollback

# Railway: re-deploy previous commit
git revert HEAD --no-edit && git push
```

## Output format

Produce a deployment report in this exact format:

```
## Deployment Report — <project name>

**Platform:** <Vercel / Railway / Docker / Self-hosted>
**Branch:** <branch name>
**Commit:** <commit hash>

### Gate results
- lint: <PASS/FAIL>
- typecheck: <PASS/FAIL>
- test: <PASS/FAIL>
- build: <PASS/FAIL>

### Deployment
- URL: <deployment URL>
- Status: <HTTP status code>
- Timestamp: <ISO timestamp>

### Smoke test
- Health check: <PASS/FAIL>
- Response time: <ms>

### Verdict: DEPLOYED / FAILED
```

## Out of Scope

This skill does NOT:
- Write application code or fix bugs (that is /implement or /debug)
- Run security audits on deployed infrastructure (use security/SKILL.md)
- Replace CI/CD pipeline configuration (that is ci-cd-pipeline/SKILL.md)
- Manage database migrations during deploy (use database/SKILL.md)
- Handle emergency production rollbacks without a rollback plan (that is /deploy-rollback)
- Deploy to platforms not listed in the deployment matrix
