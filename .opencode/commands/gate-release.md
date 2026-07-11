---
description: "Run Tier 3 release gates with full validation and evidence"
---

# /gate-release

**Mode:** Executor
**Model:** qwen3.5-plus
**Tool access:** Layer A + browser + Lighthouse
**Success output:** Tier 3 release gate results (all Tier 2 + Lighthouse + screenshot evidence + executive review)

## Behaviour

When invoked, the Owner agent:
1. Reads `<repo>/AGENTS.md`, `<repo>/NOW.md`, and `<repo>/PLAN.md` for context
2. Determines the target repo from user intent or current directory
3. Runs Tier 1 + Tier 2 gates first
4. If all pass, builds production and runs Tier 3 gates:
   ```bash
   pnpm build
   pnpm start --port <preview-port> &
   pnpm dlx lighthouse http://localhost:<preview-port>/onboarding --output=json --output-path=/tmp/lighthouse-onboarding.json --only-categories=performance,accessibility,best-practices --chrome-flags="--headless"
   node scripts/check-lighthouse-budget.js /tmp/lighthouse-onboarding.json
   pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts  # against production
   ```
5. Produces screenshot evidence pack (before/after/diff)
6. **Mandatory:** Runs `/review-ui` for independent executive review (required for CPO/CMO-grade claims)
7. Reports results in structured format
8. If any gate fails: stops and reports failure details
9. If all gates pass: produces release summary and requests owner approval for deploy

**Executive Review Enforcement:**
- `/gate-release` MUST call `/review-ui` before completing.
- If executive review is skipped or fails: gate fails with "executive review missing."
- CPO/CMO-grade claims are invalid without independent reviewer score >= 80/100.
- For non-release UI work, manual review can remain optional.

## When to use /gate-release

- Before production deploy
- Before merging to main for release
- Before shipping a major feature
- When you need full production confidence

## When NOT to use /gate-release

- For routine non-UI changes → use `/gate-fast`
- For UI changes without deploy intent → use `/gate-ui`
- When you need quick feedback → use `/gate-fast`

## Output format

```
## Release Gate Results
Repo:     <repo>
Tier:     3 (Release)

| Gate | Status | Details |
|---|---|---|
| Lint | PASS/FAIL | <errors/warnings> |
| Typecheck | PASS/FAIL | <errors> |
| Unit tests | PASS/FAIL | <X/Y passed> |
| E2E tests | PASS/FAIL | <X/Y passed> |
| Keyboard smoke | PASS/FAIL | <X/Y passed> |
| ARIA snapshots | PASS/FAIL/SKIP | <X/Y passed> |
| Visual snapshots | PASS/FAIL | <X/Y passed> |
| Axe /onboarding | PASS/FAIL | <violations> |
| Axe /today | PASS/FAIL | <violations> |
| Lighthouse perf | PASS/FAIL | <score>/100 |
| Lighthouse a11y | PASS/FAIL | <score>/100 |
| Lighthouse bp | PASS/FAIL | <score>/100 |
| Executive rubric | PASS/FAIL | <score>/100 |

Verdict: PASS / FAIL
Evidence: artifacts/visual-review-v<N>/
Release summary: <summary>
Owner approval: REQUIRED before deploy
```

## Do not
- Skip any gate in the tier
- Skip executive review (`/review-ui`) for release gates
- Deploy without explicit owner approval
- Update baselines without explicit rationale
- Claim PASS if any gate fails
- Claim CPO/CMO-grade quality without independent reviewer score >= 80/100
- Use for routine changes (use `/gate-fast` or `/gate-ui` instead)
