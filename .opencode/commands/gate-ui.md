---
description: "Run Tier 2 UI and accessibility gates with browser-route awareness"
---

# /gate-ui

**Mode:** Executor
**Model:** qwen3.7-plus (v1.1-production, Action 4D)
**Tool access:** Layer A + browser
**Success output:** Tier 2 UI/a11y gate results (lint, typecheck, test, axe, keyboard, ARIA, visual snapshots) — browser-dependent gates may be NOT_RUN when agent-browser is the active route

## Browser Route

Run `bash .opencode/scripts/browser-verification-preflight.sh` before UI gates.
- **V1 active route:** agent-browser (basic visual evidence fallback — NOT full Tier 2 gate coverage)
- Playwright MCP is disabled; Python Playwright has no browser binaries installed
- If preflight returns `NOT_RUN`: document exact blocker and skip browser-dependent gates with `NOT_RUN` classification
- **Important distinction:**
  - Playwright browser/runtime enables multi-viewport capture, axe-core scanning, keyboard tests, ARIA snapshots, and visual diff automation
  - Playwright MCP enables OpenCode-integrated browser control (session-level integration, not the test runner itself)
  - agent-browser provides basic desktop screenshot capture only — it cannot run axe, keyboard, ARIA, or visual diff tests

## Behaviour

When invoked, the Owner agent:
1. Reads `<repo>/AGENTS.md` and `<repo>/NOW.md` for context
2. Determines the target repo from user intent or current directory
3. Runs browser verification preflight: `bash .opencode/scripts/browser-verification-preflight.sh`
4. Runs Tier 1 gates first (lint, typecheck, test)
5. If Tier 1 passes, runs Tier 2 UI/a11y gates:

**When Playwright is available:**
```bash
pnpm exec playwright test tests/e2e/a11y-keyboard-smoke.spec.ts
pnpm exec playwright test tests/e2e/a11y-aria-snapshots.spec.ts
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts
pnpm dlx @axe-core/cli http://localhost:<port>/onboarding --tags wcag2a,wcag2aa,wcag22aa
pnpm dlx @axe-core/cli http://localhost:<port>/today --tags wcag2a,wcag2aa,wcag22aa
```

**When agent-browser is the active route (V1):**
```bash
# Visual verification via agent-browser
agent-browser open http://localhost:<port>/<page>
agent-browser snapshot --json --screenshot <page>-verify.png
agent-browser screenshot <page>-verify.png
# Note: axe-core, keyboard smoke, and ARIA snapshots require Playwright
# Classify as NOT_RUN with reason: "agent-browser route does not support automated axe/keyboard/ARIA gates"
```

6. Reports results in structured format
7. If any gate fails: stops and reports failure details with remediation guidance
8. If all gates pass: reports success and suggests `/gate-release` for production deploys

## When to use /gate-ui

- After any UI/visual/layout change
- After adding new components or pages
- After accessibility fixes
- Before merging UI changes to main
- When you need to verify visual regression protection

## When NOT to use /gate-ui

- For non-UI changes → use `/gate-fast`
- Before production deploy → use `/gate-release` (includes Tier 2 + Lighthouse + executive review)

## Output format

```
## UI Gate Results
Repo:     <repo>
Tier:     2 (UI/A11y)
Browser route: <agent-browser / Playwright MCP / Python Playwright / NOT_RUN>

| Gate | Status | Details |
|---|---|---|
| Lint | PASS/FAIL | <errors/warnings> |
| Typecheck | PASS/FAIL | <errors> |
| Unit tests | PASS/FAIL | <X/Y passed> |
| Keyboard smoke | PASS/FAIL/NOT_RUN | <X/Y passed or "NOT_RUN: agent-browser route does not support keyboard tests"> |
| ARIA snapshots | PASS/FAIL/NOT_RUN | <X/Y passed or "NOT_RUN: agent-browser route does not support ARIA snapshots"> |
| Visual snapshots | PASS/FAIL/NOT_RUN | <screenshot ref or "NOT_RUN: agent-browser route does not support automated visual snapshots"> |
| Axe /onboarding | PASS/FAIL/NOT_RUN | <violations or "NOT_RUN: agent-browser route does not support axe-core scanning"> |
| Axe /today | PASS/FAIL/NOT_RUN | <violations or "NOT_RUN: agent-browser route does not support axe-core scanning"> |

Verdict: PASS / FAIL / PARTIAL (browser-dependent gates NOT_RUN)
Next: <suggest /gate-release for production, or "Ready to commit", or "Enable Playwright for full Tier 2 coverage">
```

## Do not
- Skip any gate in the tier
- Update visual/ARIA baselines without explicit rationale
- Claim PASS if any gate fails
- Claim full Tier 2 coverage when browser-dependent gates are NOT_RUN — use PARTIAL verdict instead
- Use for production deploy without also running `/gate-release`
