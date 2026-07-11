# Pre-Promotion Gate Workflow

> **Purpose:** Executable gate workflow for promoting code to production across workspace repos.
> **Trigger:** Manual promotion, release tag, or PR labelled `release` or `promotion`.
> **Last Updated:** 2026-05-22 (Phase M.7R)

---

## Gate Tiers

| Tier | Trigger | Scripts | Purpose |
|---|---|---|---|
| **FAST** | Every PR | `agent:gate:fast` | Lint + typecheck + unit tests |
| **UI** | PR labelled `ui` or `visual` | `agent:gate:ui` | FAST + a11y + visual snapshots |
| **RELEASE** | Release/promotion workflow | `agent:gate:release` | UI + build + Lighthouse |

---

## Repo-Specific Gate Commands

### protected-repo

```bash
# FAST gate (every PR)
pnpm agent:gate:fast

# UI gate (UI-labelled PRs)
pnpm agent:gate:ui

# RELEASE gate (promotion workflow)
pnpm agent:gate:release
```

### demo-project

```bash
# FAST gate (every PR)
npm run agent:gate:fast

# UI gate (UI-labelled PRs)
npm run agent:gate:ui

# RELEASE gate (promotion workflow)
npm run agent:gate:release
```

---

## GitHub Actions Workflow

Create `.github/workflows/pre-promotion-gate.yml` in each repo:

```yaml
name: Pre-Promotion Gate
on:
  pull_request:
    branches: [main]
    types: [labeled, synchronize, opened]
  push:
    tags: ['v*']

jobs:
  gate-fast:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4  # protected-repo
        with:
          version: 9
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'  # protected-repo: 'pnpm', demo-project: 'npm'
      - run: pnpm install  # protected-repo
      - run: pnpm agent:gate:fast  # protected-repo

  gate-ui:
    needs: gate-fast
    if: contains(github.event.pull_request.labels.*.name, 'ui') || contains(github.event.pull_request.labels.*.name, 'visual')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 9
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'
      - run: pnpm install
      - run: pnpm agent:gate:ui

  gate-release:
    needs: gate-ui
    if: github.event_name == 'push' && startsWith(github.ref, 'refs/tags/v')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 9
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'
      - run: pnpm install
      - run: pnpm agent:gate:release
```

---

## Local Pre-Promotion Checklist

Before promoting any repo to production:

- [ ] `agent:gate:fast` passes (lint 0 errors, typecheck 0, tests 100%)
- [ ] `agent:gate:ui` passes (a11y 0 violations, visual snapshots match)
- [ ] `agent:gate:release` passes (Lighthouse performance >= 90, accessibility >= 90)
- [ ] `/review-ui` completed with score >= 80/100 (for CPO/CMO-grade claims)
- [ ] Dirty workspace inventory clean (no uncommitted protocol files)
- [ ] Rollback note documented in commit/PR

---

## Gate Failure Classification

| Classification | Meaning | Action |
|---|---|---|
| `TARGETED_FAILURE` | Changed area failed | Block commit, fix, re-run |
| `BROAD_BASELINE_FAILURE` | Unrelated pre-existing failure | Document, may proceed with owner approval |
| `FLAKY_OR_INFRA_FAILURE` | Infra/flaky test | Retry once, document both attempts |
| `NOT_RUN` | Gate skipped | Document reason, risk, missing confidence |
| `ACCEPTED_NON_BLOCKING` | Owner-approved exception | Cite approval in summary |
| `BLOCKING_UNKNOWN` | Unclassifiable failure | Block commit, investigate |

---

## Rollback Recipe

| Field | Value |
|---|---|
| Type | revert-commit |
| Scope | Revert the promotion commit |
| Preconditions | Previous production deploy is healthy |
| Action | `git revert <promotion-commit-sha>` then re-deploy |
| Verify | Health check passes, gates pass on reverted state |
