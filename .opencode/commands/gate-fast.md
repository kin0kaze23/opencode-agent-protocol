---
description: "Run Tier 1 fast gates for lint, typecheck, tests, and smoke checks"
---

# /gate-fast

**Mode:** Executor
**Model:** qwen3.5-plus
**Tool access:** Layer A
**Success output:** Tier 1 gate results (lint, typecheck, test, loaded-state smoke)

## Behaviour

When invoked, the Owner agent:
1. Reads `<repo>/AGENTS.md` and `<repo>/NOW.md` for context
2. Determines the target repo from user intent or current directory
3. Runs Tier 1 fast gate:
   ```bash
   pnpm lint
   pnpm typecheck
   pnpm test
   pnpm exec playwright test tests/e2e/loaded-state.spec.ts  # if exists
   ```
4. Reports results in structured format
5. If any gate fails: stops and reports failure details
6. If all gates pass: reports success and suggests next tier if UI changes are in scope

## When to use /gate-fast

- After small non-UI changes (text, config, logic)
- Before committing routine changes
- As a quick health check before starting work
- When you need fast feedback without running full UI/a11y gates

## When NOT to use /gate-fast

- After UI/visual/layout changes → use `/gate-ui`
- Before production deploy → use `/gate-release`
- When you need accessibility verification → use `/gate-ui`

## Output format

```
## Fast Gate Results
Repo:     <repo>
Tier:     1 (Fast)

| Gate | Status | Details |
|---|---|---|
| Lint | PASS/FAIL | <errors/warnings> |
| Typecheck | PASS/FAIL | <errors> |
| Unit tests | PASS/FAIL | <X/Y passed> |
| Loaded state | PASS/FAIL/SKIP | <details> |

Verdict: PASS / FAIL
Next: <suggest /gate-ui if UI changes, or "Ready to commit">
```

## Do not
- Skip any gate in the tier
- Claim PASS if any gate fails
- Use for UI changes without also running `/gate-ui`
