---
description: "Deploy to Cloudflare Workers with scoped checks and rollback awareness"
---

# /deploy-workers

**Mode:** Executor
**Model:** qwen3-coder-plus
**Tool access:** Layer A + Layer B (Wrangler CLI, git)
**Success output:** Worker live + health check pass

## Behaviour

When invoked, the Owner agent:

1. Runs preflight - confirms target repo and worker name
2. Checks that /ship has already run
3. Reads the repo's `wrangler.toml` to confirm worker name and environment
4. Runs `wrangler deploy` (or reads repo's AGENTS.md for the exact command)
5. Captures the worker URL from output
6. Runs health check: `curl -I <worker-url>` - expects HTTP 200
7. Reports: worker URL, deployment timestamp, and any warnings

## Do not
- Deploy without confirming the PR has merged
- Proceed if health check fails
- Use this for Vercel deployments (use /deploy-vercel)
- Modify `wrangler.toml` - that requires /plan-feature first
