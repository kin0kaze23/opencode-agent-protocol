# Production Release Gate

> **Runbook:** `.opencode/runbooks/production-release-gate.md`
> **Version:** 1.0.0
> **Created:** 2026-05-22
> **Status:** Active

## Purpose

Defines the production release gate workflow for shipping UI changes to production. This is the highest-confidence gate tier and must not be skipped for production deploys.

## When to Apply

- Production deploy of any user-facing surface
- Release candidate merge to main
- Major feature launch
- Protocol or dependency change affecting UI

## Pre-Release Checklist

### 1. Verify Branch State

```bash
cd <repo>
git status --short
git log --oneline -5
```

**Stop if:** Working tree is dirty with unrelated changes. Clean up before proceeding.

### 2. Read Repo Truth

```bash
cat <repo>/AGENTS.md
cat <repo>/NOW.md
cat <repo>/PLAN.md
```

**Stop if:** `NOW.md` is `blocked` — resolve blocker before proceeding.

### 3. Run Full Gate Suite (Tier 3)

```bash
# Fast gates
pnpm lint
pnpm typecheck
pnpm test

# Full E2E suite
pnpm exec playwright test tests/e2e/

# Production build
pnpm build

# Start production preview
pnpm start --port 3005 &
sleep 3

# Production axe scans
pnpm dlx @axe-core/cli http://localhost:3005/onboarding --tags wcag2a,wcag2aa,wcag22aa --save /tmp/axe-onboarding.json
pnpm dlx @axe-core/cli http://localhost:3005/today --tags wcag2a,wcag2aa,wcag22aa --save /tmp/axe-today.json

# Lighthouse performance budget
pnpm dlx lighthouse http://localhost:3005/onboarding --output=json --output-path=/tmp/lighthouse-onboarding.json --only-categories=performance,accessibility,best-practices --chrome-flags="--headless"
pnpm dlx lighthouse http://localhost:3005/today --output=json --output-path=/tmp/lighthouse-today.json --only-categories=performance,accessibility,best-practices --chrome-flags="--headless"

# Budget check
node scripts/check-lighthouse-budget.js /tmp/lighthouse-onboarding.json
node scripts/check-lighthouse-budget.js /tmp/lighthouse-today.json

# Visual snapshots against production build
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts
```

### 4. Produce Screenshot Evidence Pack

```
artifacts/visual-review-v<N>/
├── README.md
├── before/
│   ├── onboarding-mobile.png
│   ├── today-mobile.png
│   └── ...
├── after/
│   ├── onboarding-mobile.png
│   ├── today-mobile.png
│   └── ...
├── diff/
│   └── ...
└── axe-reports/
    ├── onboarding-axe.json
    └── today-axe.json
```

### 5. Run Executive Review Rubric

Score the release against the 10-category rubric (`executive-product-review-rubric.md`):

| Category | Score | Notes |
|---|---|---|
| First Impression | /10 | |
| Visual Hierarchy | /10 | |
| Emotional Tone | /10 | |
| Brand Consistency | /10 | |
| Whitespace and Rhythm | /10 | |
| Typography Quality | /10 | |
| Color Discipline | /10 | |
| Motion Restraint | /10 | |
| Mobile Polish | /10 | |
| CTA Clarity | /10 | |
| **Total** | **/100** | |

**Pass threshold:** >= 80/100

### 6. Verify Gate Results

| Gate | Pass Criteria | Status |
|---|---|---|
| Lint | 0 errors, 0 warnings | [ ] |
| Typecheck | 0 errors | [ ] |
| Unit tests | All pass | [ ] |
| E2E tests | All pass | [ ] |
| Axe-core | 0 violations | [ ] |
| Keyboard smoke | All pass | [ ] |
| ARIA snapshots | All pass | [ ] |
| Visual snapshots | All match or approved | [ ] |
| Lighthouse perf | >= 85 | [ ] |
| Lighthouse a11y | >= 95 | [ ] |
| Lighthouse bp | >= 90 | [ ] |
| Executive rubric | >= 80/100 | [ ] |

**Stop if:** Any gate fails. Fix before proceeding.

### 7. Produce Release Summary

```markdown
# Production Release — <repo> — <date>

## What Changed
- <one paragraph summary>

## Gate Results
| Gate | Status | Details |
|---|---|---|
| Lint | PASS/FAIL | |
| Typecheck | PASS/FAIL | |
| Unit tests | PASS/FAIL | X/Y |
| E2E tests | PASS/FAIL | X/Y |
| Axe-core | PASS/FAIL | 0 violations |
| Keyboard | PASS/FAIL | X/Y |
| ARIA snapshots | PASS/FAIL | X/Y |
| Visual snapshots | PASS/FAIL | X/Y |
| Lighthouse perf | PASS/FAIL | XX/100 |
| Lighthouse a11y | PASS/FAIL | XX/100 |
| Lighthouse bp | PASS/FAIL | XX/100 |
| Executive rubric | PASS/FAIL | XX/100 |

## Evidence
- Screenshot evidence pack: `artifacts/visual-review-v<N>/`
- Lighthouse reports: `/tmp/lighthouse-*.json`
- Axe reports: `/tmp/axe-*.json`

## Rollback Recipe
- Type: <revert-commit / discard-working-tree / drop-branch>
- Scope: <what is being reversed>
- Preconditions: <what must be true>
- Action: <exact command>
- Verify: <how to confirm rollback succeeded>

## Verdict
GO / NO-GO
```

### 8. Get Owner Approval

**Never deploy to production without explicit owner approval.**

Present the release summary and evidence pack to the owner. Wait for explicit "GO" before deploying.

### 9. Deploy

```bash
# Deploy to production (example: Vercel)
vercel --prod

# Or deploy via CI/CD pipeline
git push origin main
```

### 10. Post-Deploy Verification

```bash
# Verify production URL
curl -s -o /dev/null -w "%{http_code}" https://<production-url>/onboarding
curl -s -o /dev/null -w "%{http_code}" https://<production-url>/today

# Run axe against production
pnpm dlx @axe-core/cli https://<production-url>/onboarding --tags wcag2a,wcag2aa,wcag22aa

# Run Lighthouse against production
pnpm dlx lighthouse https://<production-url>/onboarding --output=json --output-path=/tmp/lighthouse-prod.json --only-categories=performance,accessibility,best-practices
```

## Escalation Rules

| Condition | Action |
|---|---|
| Any gate fails | Stop. Fix. Re-run full suite. |
| Lighthouse perf < 85 | Document as known gap. Do not deploy unless owner approves. |
| Axe violation introduced | **Never deploy.** Fix violation first. |
| Executive rubric < 80 | Do not deploy. Fix visual quality first. |
| Owner says NO | Stop. Address concerns. Re-run gates. |
| Post-deploy axe failure | Rollback immediately. Fix. Re-deploy. |

## Related Documents

- `daily-agent-gate-tiers.md` — Gate tier definitions
- `visual-quality-gate.md` — Visual quality gate
- `performance-budget-gate.md` — Performance budget targets
- `executive-product-review-rubric.md` — Executive review scoring
- `screenshot-evidence-pack.md` — Evidence pack structure
