---
description: "Deploy to Vercel with scoped checks, evidence, and rollback awareness"
---

# /deploy-vercel

**Mode:** Executor
**Model:** qwen3-coder-plus
**Tool access:** Layer A + Layer B (Vercel CLI, git)
**Success output:** Successful deployment URL + smoke test pass

## Behaviour

When invoked, the Owner agent:

1. Runs preflight - confirms target repo and branch
2. Checks that /ship has already run (PR merged or merge confirmed)
3. Runs `vercel --prod` (or reads repo's AGENTS.md for the exact deploy command)
4. Captures the deployment URL from output
5. Runs a smoke test: `curl -I <deployment-url>` - expects HTTP 200
6. Reports: deployment URL, status, and any warnings from Vercel output

## Repos that use this command
- ClearPathOS (Next.js -> Vercel)
- example-app (React + Vite -> Vercel)
- StableVault (React + Vite -> Vercel)

## Do not
- Deploy without confirming the PR has merged
- Proceed if smoke test fails
- Use this for Cloudflare Workers deployments (use /deploy-workers)
