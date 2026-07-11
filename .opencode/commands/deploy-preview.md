---
description: "Deploy a scoped preview environment with verification and rollback notes"
---

# /deploy-preview

**Mode:** Executor
**Model:** qwen3-coder-plus
**Tool access:** Layer A + Layer B (Vercel CLI, Wrangler CLI, gh CLI, git)
**Success output:** Preview deployment URL + smoke test pass

## Behaviour

When invoked, the Owner agent:

1. Runs preflight - confirms target repo and branch
2. Identifies deployment platform from repo config:
   - If `vercel.json` or `.vercel/` exists: Vercel
   - If `wrangler.toml` exists: Cloudflare Workers
   - If `Dockerfile` or `docker-compose.yml` exists: Docker
   - If none: determine from repo AGENTS.md or ask user
3. **v4.17.0 Parallel Preview Build:** Starts preview deployment in parallel with remaining gates:
   - Start `vercel --yes` (or platform equivalent) in the background
   - Continue running any remaining gates (e2e, visual QA, reviewer)
   - When preview URL is ready, run smoke test against it
4. Captures the deployment URL from output
5. Runs smoke test: `curl -I <preview-url>` - expects HTTP 200
6. **v4.17.0 Enhanced Smoke Test:** If possible, also verify:
   - Page renders (not blank/empty body)
   - CSS files loaded (no 404s)
   - No console errors (if browser route available)
7. Reports: preview URL, status, and any warnings
8. If deploying from a PR branch: comments the preview URL on the PR
9. **v4.17.0 Deployment Readiness Report:** Generate machine-readable report:
   - Run `bash .opencode/scripts/deploy-readiness-report.sh <repo> --preview-url <url>`
   - Include report in output for machine consumption

## Repos that use this command
- All repos with Vercel deployment (ClearPathOS, example-app, StableVault)
- All repos with Cloudflare Workers
- All repos with Docker deployment

## Do not
- Deploy from `main` branch (use `/deploy-vercel` or `/deploy-workers` for production)
- Deploy without confirming the branch is not `main`
- Proceed if smoke test fails
- Deploy if quality gates have not passed
