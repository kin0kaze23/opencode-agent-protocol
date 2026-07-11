---
description: "Rollback a deployment safely with verification and incident notes"
---

# /deploy-rollback

**Mode:** Executor
**Model:** qwen3-coder-plus
**Tool access:** Layer A + Layer B (Vercel CLI, Wrangler CLI, Docker CLI, git)
**Success output:** Rollback successful + smoke test pass on previous version

## Behaviour

When invoked, the Owner agent:

1. Runs preflight - confirms target repo and rollback reason
2. Identifies deployment platform from repo config:
   - If `vercel.json` or `.vercel/` exists: Vercel
   - If `wrangler.toml` exists: Cloudflare Workers
   - If `Dockerfile` or `docker-compose.yml` exists: Docker
3. Determines rollback target:
   - If `--version <hash>` provided: rollback to specific version
   - If `--auto`: rollback to last known good deployment
   - If `--urgent`: rollback immediately to previous version
   - Otherwise: ask user for rollback target
4. Runs platform-specific rollback:
   - Vercel: `vercel rollback <deployment-url>`
   - Cloudflare: `wrangler deploy --version <previous-version>`
   - Docker: `docker compose up -d <previous-image-tag>`
5. Captures the rollback deployment URL
6. Runs smoke test: `curl -I <rollback-url>` - expects HTTP 200
7. Verifies rollback:
   - Confirms previous version is live
   - Health check passes
   - No data loss or corruption
8. Reports: rollback URL, status, previous version hash, and any warnings
9. If rollback fails: reports failure and suggests manual intervention

## Rollback Strategies

| Strategy | When to Use | Command |
|---|---|---|
| `--auto` | Standard rollback to last known good | `/deploy-rollback --auto` |
| `--version <hash>` | Rollback to specific commit | `/deploy-rollback --version abc123` |
| `--urgent` | Immediate rollback (skip checks) | `/deploy-rollback --urgent` |
| `--flag <name>` | Disable feature flag instead | `/deploy-rollback --flag my-feature` |

## Do not
- Rollback without confirming the rollback target
- Proceed if smoke test fails on previous version
- Rollback if data migration has already run (requires manual intervention)
- Rollback production deployments without user approval (unless `--urgent`)
