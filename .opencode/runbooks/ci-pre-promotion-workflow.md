# CI/Pre-Promotion Workflow

> **Runbook:** `.opencode/runbooks/ci-pre-promotion-workflow.md`
> **Version:** 1.0.0
> **Created:** 2026-05-22
> **Status:** Active

## Purpose

Defines the CI/pre-promotion workflow that splits gates by PR type to avoid slowing daily development while still protecting quality.

## Gate Split by PR Type

### On Every PR (Lightweight)

**Trigger:** Any pull request

**Gates:**
```bash
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

**Pass criteria:** All pass. Block merge if any fail.

**Time:** ~1-2 minutes

### On UI-Labelled PR (Medium)

**Trigger:** PR with `ui` or `visual` or `accessibility` label

**Gates:**
```bash
# All lightweight gates plus:
pnpm exec playwright test tests/e2e/a11y-keyboard-smoke.spec.ts
pnpm exec playwright test tests/e2e/a11y-aria-snapshots.spec.ts
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts
pnpm dlx @axe-core/cli http://localhost:<port>/onboarding --tags wcag2a,wcag2aa,wcag22aa
pnpm dlx @axe-core/cli http://localhost:<port>/today --tags wcag2a,wcag2aa,wcag22aa
```

**Pass criteria:** All pass. Block merge if any fail.

**Time:** ~3-5 minutes

### On Release/Promotion (Heavy)

**Trigger:** PR to `main` for release, or `/gate-release` command

**Gates:**
```bash
# All UI gates plus:
pnpm build
pnpm start --port <preview-port> &
pnpm dlx lighthouse http://localhost:<preview-port>/onboarding --output=json --output-path=/tmp/lighthouse-onboarding.json --only-categories=performance,accessibility,best-practices --chrome-flags="--headless"
node scripts/check-lighthouse-budget.js /tmp/lighthouse-onboarding.json
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts  # against production
/review-ui  # Independent executive review
```

**Pass criteria:** All pass. Block release if any fail. Requires owner approval.

**Time:** ~5-10 minutes

## CI Configuration Example (GitHub Actions)

```yaml
name: UI Quality Gates
on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  lightweight-gates:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - run: pnpm install
      - run: pnpm lint
      - run: pnpm typecheck
      - run: pnpm test
      - run: pnpm build

  ui-gates:
    if: contains(github.event.pull_request.labels.*.name, 'ui') || contains(github.event.pull_request.labels.*.name, 'visual')
    needs: lightweight-gates
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - run: pnpm install
      - run: pnpm exec playwright install --with-deps chromium
      - run: pnpm dev &
      - run: pnpm exec playwright test tests/e2e/a11y-keyboard-smoke.spec.ts
      - run: pnpm exec playwright test tests/e2e/a11y-aria-snapshots.spec.ts
      - run: pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts

  release-gates:
    if: github.base_ref == 'main'
    needs: ui-gates
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - run: pnpm install
      - run: pnpm build
      - run: pnpm start &
      - run: pnpm dlx lighthouse http://localhost:3000 --output=json --output-path=lighthouse.json
      - run: node scripts/check-lighthouse-budget.js lighthouse.json
```

## Local Development Workflow

For local development, use the OpenCode commands:

| Command | When to Use |
|---|---|
| `/gate-fast` | After small non-UI changes |
| `/gate-ui` | After UI/visual/layout changes |
| `/gate-release` | Before production deploy |
| `/review-ui` | For independent executive review |

## Promotion Criteria

A PR is ready for promotion when:

- [ ] Lightweight gates pass (lint, typecheck, test, build)
- [ ] UI gates pass (if UI changes)
- [ ] Release gates pass (if releasing to production)
- [ ] Executive review score >= 80/100 (if claiming premium quality)
- [ ] Owner approval received (for production deploys)
- [ ] No capability drift introduced (check `CAPABILITY_DRIFT_LOG.md`)

## Related Documents

- `daily-agent-gate-tiers.md` — Gate tier definitions
- `gate-fast.md` — Fast gate command
- `gate-ui.md` — UI gate command
- `gate-release.md` — Release gate command
- `review-ui.md` — Independent review command
- `production-release-gate.md` — Production release runbook
