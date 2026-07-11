---
description: "End-to-end deployment automation across Vercel, Cloudflare Workers, GitHub Actions, and Docker"
---

# CI/CD Pipeline Skill

> **Version:** 1.0
> **Scope:** End-to-end deployment automation across Vercel, Cloudflare Workers, GitHub Actions, and Docker
> **Integration:** Works with `/ship`, `/deploy-vercel`, `/deploy-workers`, `/deploy-preview`, `/deploy-rollback`

## When to Activate

Task keywords: `deploy`, `deployment`, `CI/CD`, `pipeline`, `GitHub Actions`, `Vercel`, `Wrangler`, `Docker`, `rollback`, `preview`, `production`, `staging`, `environment`, `smoke test`, `health check`, `deployment gate`, `deployment strategy`, `canary`, `blue-green`, `infrastructure as code`, `terraform`, `Pulumi`

## Deployment Architecture

### Supported Platforms

| Platform | Repos | Deploy Command | Health Check |
|---|---|---|---|
| **Vercel** | ClearPathOS, example-app, StableVault | `vercel --prod` | `curl -I <url>` |
| **Cloudflare Workers** | (workers repos) | `wrangler deploy` | `curl -I <url>` |
| **GitHub Pages** | (docs repos) | `gh-pages -d dist/` | HTTP 200 on pages URL |
| **Docker** | (containerized repos) | `docker compose up -d` | Container health check |

### Deployment Environments

| Environment | Trigger | Approval Required | Rollback Strategy |
|---|---|---|---|
| **Preview** | PR created/updated | No | Delete preview URL |
| **Staging** | PR merged to `staging` | No | Redeploy previous commit |
| **Production** | PR merged to `main` | Yes (`/deploy-vercel --prod`) | `/deploy-rollback` |

## Deployment Workflow

### Phase 1: Pre-Deployment Checks

Before any deployment, verify:

1. **Source control:**
   - Current branch matches target environment
   - Working tree is clean (no uncommitted changes)
   - PR has been merged (for staging/production)

2. **Quality gates:**
   - All quality gates passed (lint, typecheck, test, build)
   - No open security findings from SAST
   - No pending review comments on PR

3. **Environment readiness:**
   - Target platform CLI is available (`vercel`, `wrangler`, `gh`, `docker`)
   - Environment variables are configured
   - Domain/DNS is pointing to the platform

4. **Deployment safety:**
   - Rollback plan is documented
   - Smoke test endpoints are known
   - Monitoring/alerting is active (if applicable)

### Phase 2: Deployment Execution

#### Preview Deployments (PR-based)

```bash
# Vercel preview (automatic on PR)
vercel --yes

# Cloudflare preview
wrangler deploy --env preview

# GitHub Pages preview
gh-pages -d dist/ --message "Preview: $PR_NUMBER"
```

**Success criteria:**
- Deployment URL is accessible (HTTP 200)
- No console errors in deployment logs
- Preview URL matches PR content

#### Production Deployments

```bash
# Vercel production
vercel --prod

# Cloudflare Workers production
wrangler deploy

# Docker production
docker compose up -d --pull always
```

**Success criteria:**
- Deployment completes without errors
- Smoke test passes (HTTP 200 on main endpoint)
- Health check endpoint returns healthy status
- No regression in key metrics (if monitoring active)

### Phase 3: Post-Deployment Verification

1. **Smoke tests:**
   ```bash
   # Basic connectivity
   curl -I <deployment-url>
   
   # Health endpoint (if exists)
   curl -s <deployment-url>/api/health | jq .status
   
   # Key user flow (if test suite exists)
   npm run test:e2e -- --grep "critical-flow"
   ```

2. **Rollback verification (if rollback was executed):**
   ```bash
   # Verify previous version is live
   curl -s <deployment-url>/api/version | jq .commit
   ```

3. **Deployment logging:**
   - Record deployment timestamp, commit hash, environment
   - Record deployment URL and health check result
   - Append to deployment log in repo or vault

## Rollback Strategies

### Strategy Selection

| Situation | Strategy | Command |
|---|---|---|
| **Failed deployment** | Automatic rollback to previous version | `/deploy-rollback --auto` |
| **Performance regression** | Rollback to last known good version | `/deploy-rollback --version <hash>` |
| **Security issue** | Immediate rollback + hotfix branch | `/deploy-rollback --urgent` |
| **Feature flag issue** | Disable feature flag (no rollback needed) | `/deploy-rollback --flag <name>` |

### Rollback Execution

```bash
# Vercel rollback (redeploy previous deployment)
vercel rollback <deployment-url>

# Cloudflare Workers rollback (redeploy previous version)
wrangler deploy --version <previous-version>

# Docker rollback
docker compose up -d --pull always <previous-image-tag>
```

**Rollback success criteria:**
- Previous version is live and accessible
- Health check passes on previous version
- No data loss or corruption during rollback
- Rollback completed within SLA (usually <5 minutes)

## GitHub Actions Integration

### Pipeline Templates

#### Basic CI Pipeline

```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - run: pnpm install
      - run: pnpm lint
      - run: pnpm typecheck
      - run: pnpm test
```

#### Deploy Pipeline (Vercel)

```yaml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
```

#### Deploy Pipeline (Cloudflare Workers)

```yaml
name: Deploy Worker
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CF_API_TOKEN }}
          command: deploy
```

## Deployment Best Practices

### Do
- ✅ Always run pre-deployment checks
- ✅ Always verify deployment with smoke tests
- ✅ Always have a rollback plan before deploying
- ✅ Always deploy from CI/CD pipeline (not local)
- ✅ Use preview deployments for PR review
- ✅ Tag deployments with commit hash and version
- ✅ Monitor deployment health for 15 minutes after

### Don't
- ❌ Deploy without passing quality gates
- ❌ Deploy directly to production without staging
- ❌ Deploy on Fridays or before holidays
- ❌ Skip rollback planning
- ❌ Deploy multiple changes simultaneously
- ❌ Deploy without monitoring/alerting active
- ❌ Deploy when team is unavailable for rollback

## Deployment Metrics to Track

| Metric | Target | How to Measure |
|---|---|---|
| **Deployment frequency** | Multiple per day | Git tags + deployment log |
| **Lead time for changes** | <1 hour | Commit to deploy time |
| **Change failure rate** | <5% | Failed deployments / total |
| **Mean time to recovery** | <15 minutes | Rollback start to complete |
| **Deployment success rate** | >95% | Successful deployments / total |

## Troubleshooting

### Common Issues

| Issue | Cause | Fix |
|---|---|---|
| `vercel: command not found` | CLI not installed | `npm i -g vercel` or use `npx vercel` |
| `wrangler: command not found` | CLI not installed | `npm i -g wrangler` or use `npx wrangler` |
| Deployment fails with 500 | Environment variables missing | Check platform dashboard for env vars |
| Health check fails | Wrong endpoint or service down | Verify health endpoint exists and service is running |
| Rollback fails | Previous deployment deleted | Redeploy from git tag or commit hash |

## Integration with Other Commands

| Command | Integration Point |
|---|---|
| `/ship` | Creates PR → merges → triggers deployment pipeline |
| `/deploy-vercel` | Executes Vercel production deployment |
| `/deploy-workers` | Executes Cloudflare Workers deployment |
| `/deploy-preview` | Creates preview deployment for PR |
| `/deploy-rollback` | Rolls back to previous deployment |
| `/gates` | Pre-deployment quality checks |
| `/checkpoint` | Records deployment in vault progress log |

## Environment-Specific Configuration

### Vercel

```json
{
  "platform": "vercel",
  "environments": {
    "preview": "Automatic on PR",
    "production": "Manual trigger after PR merge"
  },
  "commands": {
    "deploy": "vercel --prod",
    "preview": "vercel",
    "rollback": "vercel rollback <url>"
  }
}
```

### Cloudflare Workers

```json
{
  "platform": "cloudflare",
  "environments": {
    "production": "Manual trigger after PR merge"
  },
  "commands": {
    "deploy": "wrangler deploy",
    "rollback": "wrangler deploy --version <prev>"
  }
}
```

### Docker

```json
{
  "platform": "docker",
  "environments": {
    "production": "Manual trigger with image tag"
  },
  "commands": {
    "deploy": "docker compose up -d --pull always",
    "rollback": "docker compose up -d <prev-image>"
  }
}
```
