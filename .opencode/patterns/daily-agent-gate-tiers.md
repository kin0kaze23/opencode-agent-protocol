# Daily Agent Gate Tiers

> **Pattern:** `.opencode/patterns/daily-agent-gate-tiers.md`
> **Version:** 1.0.0
> **Created:** 2026-05-22
> **Status:** Active

## Purpose

Defines 4 tiers of daily agent gates so that not every session runs the full expensive suite. Agents select the tier based on the change scope and risk level.

## Tier Selection Matrix

| Change type | Tier | Rationale |
|---|---|---|
| Text copy, config, non-UI | Tier 1 | Fast gate sufficient |
| Small component fix, no visual change | Tier 1 | Fast gate sufficient |
| Visual change, new component, layout | Tier 2 | UI/a11y gate required |
| New page, route, or surface | Tier 2 | UI/a11y gate required |
| Production deploy, release candidate | Tier 3 | Full release gate required |
| Protocol change, dependency update | Tier 3 | Full release gate required |

## Tier 0 — Pre-Edit Context Check

**When:** Before any code changes, at session start.

**Commands:**
```bash
# Read repo truth
cat <repo>/AGENTS.md
cat <repo>/NOW.md
cat <repo>/PLAN.md  # if exists

# Inspect route/component ownership
# (Explorer or manual file tree read)
```

**No code changes yet.** This tier is read-only context gathering.

**Output:** Session banner with repo, mode, lane, risk score, and likely files.

## Tier 1 — Fast Daily Gate

**When:** Text changes, config updates, small non-UI fixes, dependency bumps (non-sensitive).

**Commands:**
```bash
pnpm lint
pnpm typecheck
pnpm test                    # or targeted test file
pnpm exec playwright test tests/e2e/loaded-state.spec.ts  # targeted smoke
```

**Pass criteria:**
- Lint: 0 errors, 0 warnings
- Typecheck: 0 errors
- Tests: All pass
- Loaded state: Core routes reach expected content

**Time:** ~30-60 seconds

**Skip if:** Any UI, visual, accessibility, or layout change is in scope.

## Tier 2 — UI/A11y Gate

**When:** Visual changes, new components, layout modifications, accessibility fixes, new pages.

**Commands:**
```bash
# Tier 1 gates first
pnpm lint
pnpm typecheck
pnpm test

# UI/a11y specific
pnpm exec playwright test tests/e2e/a11y-keyboard-smoke.spec.ts
pnpm exec playwright test tests/e2e/a11y-aria-snapshots.spec.ts
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts

# Production axe scan (against running dev server)
pnpm dlx @axe-core/cli http://localhost:3004/onboarding --tags wcag2a,wcag2aa,wcag22aa
pnpm dlx @axe-core/cli http://localhost:3004/today --tags wcag2a,wcag2aa,wcag22aa
```

**Pass criteria:**
- All Tier 1 gates pass
- Keyboard smoke: All pass
- ARIA snapshots: All pass (or skipped with documented reason)
- Visual snapshots: All match or intentional diffs approved
- Axe-core: 0 new violations introduced

**Time:** ~2-4 minutes

**Skip if:** Production deploy or release candidate (use Tier 3 instead).

## Tier 3 — Production Release Gate

**When:** Production deploy, release candidate, major feature merge, protocol change.

**Commands:**
```bash
# Full Tier 1 + Tier 2 gates
pnpm lint
pnpm typecheck
pnpm test
pnpm exec playwright test tests/e2e/  # full E2E suite

# Production build
pnpm build

# Production axe scan (against preview server)
pnpm start --port 3005 &
pnpm dlx @axe-core/cli http://localhost:3005/onboarding --tags wcag2a,wcag2aa,wcag22aa
pnpm dlx @axe-core/cli http://localhost:3005/today --tags wcag2a,wcag2aa,wcag22aa

# Lighthouse performance budget
pnpm dlx lighthouse http://localhost:3005/onboarding --output=json --output-path=/tmp/lighthouse-onboarding.json --only-categories=performance,accessibility,best-practices --chrome-flags="--headless"
node scripts/check-lighthouse-budget.js /tmp/lighthouse-onboarding.json

# Visual snapshots against production build
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts --grep "onboarding|today"

# Screenshot evidence pack
# (See screenshot-evidence-pack.md for structure)

# Executive review rubric
# (See executive-product-review-rubric.md for scoring)
```

**Pass criteria:**
- All Tier 1 + Tier 2 gates pass
- Full E2E suite: All pass
- Production axe: 0 violations
- Lighthouse: Performance >= 85, Accessibility >= 95, Best Practices >= 90
- Visual snapshots: All match or intentional diffs approved
- Executive rubric: Score >= 80/100
- Screenshot evidence pack: Complete

**Time:** ~5-10 minutes

**Never skip for production deploys.**

## Escalation Rules

| Condition | Action |
|---|---|
| Tier 1 fails | Stop, fix, re-run Tier 1 |
| Tier 2 fails | Stop, fix, re-run Tier 2 |
| Tier 3 fails | Stop, fix, re-run Tier 3. Do not deploy. |
| Lighthouse LCP > 2500ms | Document as known gap, do not block unless regression |
| demo-project ARIA skipped | Document as cross-repo infrastructure gap, do not block BabyGate |
| Visual snapshot fails | Review diff. If intentional, update baseline with rationale. If unexpected, fix. |
| Axe violation introduced | Block commit. Fix violation before proceeding. |

## Related Patterns

- `visual-quality-gate.md` — Visual quality gate definition
- `a11y-production-gate.md` — Accessibility gate
- `performance-budget-gate.md` — Performance budget targets
- `executive-product-review-rubric.md` — Executive review scoring
