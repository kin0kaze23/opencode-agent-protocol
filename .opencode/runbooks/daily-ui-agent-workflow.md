# Daily UI Agent Workflow

> **Runbook:** `.opencode/runbooks/daily-ui-agent-workflow.md`
> **Version:** 2.0.0
> **Created:** 2026-05-22
> **Updated:** 2026-05-22 (M.8 — Protocol Seal & Handoff)
> **Status:** Active

---

## Daily Use Quickstart

> **For future agents:** Read this section first. It tells you exactly what to do in the first 60 seconds of a UI task.

### 1. Determine the task type

| Task | Gate tier | Command |
|---|---|---|
| Text, config, non-UI | Tier 1 | `/gate-fast` |
| Visual, component, layout, a11y | Tier 2 | `/gate-ui` |
| Production deploy, release, protocol | Tier 3 | `/gate-release` |

### 2. Read repo truth (mandatory)

```bash
cat <repo>/AGENTS.md
cat <repo>/NOW.md
cat <repo>/PLAN.md  # if exists
```

**Stop if:** `NOW.md` is `blocked` — resolve blocker before proceeding.

### 3. Run the appropriate gate command

```bash
# protected-repo
pnpm agent:gate:fast    # Tier 1
pnpm agent:gate:ui      # Tier 2
pnpm agent:gate:release # Tier 3

# demo-project
npm run agent:gate:fast    # Tier 1
npm run agent:gate:ui      # Tier 2
npm run agent:gate:release # Tier 3
```

### 4. Handle gate results

- **All PASS:** Proceed to commit with evidence in commit message.
- **Any FAIL:** Fix the failure, re-run the gate. Do not skip.
- **Targeted failure:** Blocks commit until fixed.
- **Broad baseline failure:** May validate protocol-only work, but blocks product-code commits unless owner accepts risk.
- **Flaky failure:** Retry once. If still failing, classify as FLAKY_OR_INFRA_FAILURE.

### 5. Produce evidence

Include gate results in commit message:

```
feat: <description>

- Gate results: lint PASS, typecheck PASS, test PASS
- A11y: axe 0 violations, keyboard PASS, ARIA PASS
- Visual: snapshots PASS
- Performance: Lighthouse perf XX, a11y XX, bp XX
```

### 6. Know the boundaries

- **Do NOT** introduce new UI dependencies without approval.
- **Do NOT** change brand colors without approval.
- **Do NOT** skip executive review for release gates.
- **Do NOT** update baselines without rationale.
- **Do NOT** commit without all gates passing.

---

## Before Starting Any UI Work

### 1. Read Repo Truth (Mandatory)

```bash
cat <repo>/AGENTS.md
cat <repo>/NOW.md
cat <repo>/PLAN.md  # if exists
```

**Stop if:** `NOW.md` is `blocked` — resolve blocker before proceeding.

### 2. Determine Gate Tier

Use `daily-agent-gate-tiers.md` to select the appropriate tier:

| Change | Tier |
|---|---|
| Text, config, non-UI | Tier 1 |
| Visual, component, layout, a11y | Tier 2 |
| Production deploy, release, protocol | Tier 3 |

### 3. Read Design System

```bash
# protected-repo
cat src/styles/globals.css          # Design tokens
cat docs/design-system/COMPONENT_REGISTRY.md  # Available components

# demo-project
cat src/styles/design-system.css
cat docs/design-system/COMPONENT_REGISTRY.md
```

**Rule:** Never introduce new colors, spacing, or typography without checking existing tokens first.

## During Implementation

### 4. Produce Touch List (Before Any Code Changes)

```
TOUCH LIST:
- path/to/file1.tsx (reason)
- path/to/file2.tsx (reason)
```

**Rule:** Never add files mid-task without re-approving the touch list.

### 5. Follow Component Decision Rule

Read `.opencode/patterns/component-decision-rule.md` before adding any new component.

**Decision flow:**
1. Existing repo component → use it
2. Standard primitive needed → shadcn/ui (with approval)
3. Custom compose → build from tokens
4. Never hand-roll accessible primitives

### 6. Run Tier 1 Gates (Fast Check)

```bash
pnpm lint
pnpm typecheck
pnpm test
```

**Stop if:** Any gate fails. Fix before proceeding.

## After Implementation

### 7. Run Tier-Specific Gates

**Tier 1:** Already done in step 6.

**Tier 2:**
```bash
pnpm exec playwright test tests/e2e/a11y-keyboard-smoke.spec.ts
pnpm exec playwright test tests/e2e/a11y-aria-snapshots.spec.ts
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts
pnpm dlx @axe-core/cli http://localhost:3004/affected-page
```

**Tier 3:**
```bash
# All Tier 2 gates plus:
pnpm build
pnpm start --port 3005 &
pnpm dlx lighthouse http://localhost:3005/affected-page --output=json --output-path=/tmp/lighthouse.json --only-categories=performance,accessibility,best-practices --chrome-flags="--headless"
node scripts/check-lighthouse-budget.js /tmp/lighthouse.json
```

### 8. Handle Failed Gates

| Failure | Action |
|---|---|
| Lint error | Fix the error, re-run lint |
| Typecheck error | Fix the type error, re-run typecheck |
| Test failure | Fix the test or code, re-run tests |
| Axe violation | **Block commit.** Fix violation before proceeding |
| Keyboard test failure | Fix keyboard accessibility, re-run |
| ARIA snapshot failure | Review if intentional. If yes, update baseline with rationale. If no, fix. |
| Visual snapshot failure | Review diff. If intentional, update baseline with rationale. If no, fix. |
| Lighthouse failure | Document as known gap. Do not block unless regression from baseline. |

### 9. Produce Evidence

**Tier 2 evidence:**
- Gate results (lint, typecheck, test, keyboard, ARIA, visual, axe)
- Visual snapshot diff (if applicable)

**Tier 3 evidence:**
- All Tier 2 evidence plus:
- Lighthouse report
- Screenshot evidence pack (before/after/diff)
- Executive review rubric score

### 10. Commit

```bash
cd <repo>
git add <changed files>
git commit -m "feat: <description>

- Gate results: lint PASS, typecheck PASS, test PASS
- A11y: axe 0 violations, keyboard PASS, ARIA PASS
- Visual: snapshots PASS
- Performance: Lighthouse perf XX, a11y XX, bp XX"
```

**Rule:** Never commit without all gates passing.

## When to Ask for Approval

| Situation | Action |
|---|---|
| Adding new dependency | Ask before installing |
| Adopting shadcn/ui | Ask before adding |
| Adding Motion library | Ask before adding |
| Changing brand colors | Ask before changing |
| Score below 80 on executive review | Ask before shipping |
| Lighthouse regression > 10 points | Ask before shipping |
| New accessibility violation introduced | **Never ship.** Fix first. |

## How to Update Screenshots

```bash
# Update baselines for intentional changes
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts --update-snapshots --grep "changed-page"

# Verify updated baselines pass
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts --grep "changed-page"
```

**Rule:** Never update baselines without explicit rationale in the commit message.

## How to Avoid Dependency Bloat

1. **Check existing tokens first** — `globals.css` has colors, spacing, typography, shadows
2. **Check component registry** — `docs/design-system/COMPONENT_REGISTRY.md` lists available components
3. **Use CSS for simple motion** — `transition`, `transform`, `opacity` are sufficient for most cases
4. **Reject shadcn/ui unless** — a complex accessible primitive is needed (dialog, combobox, select)
5. **Reject Motion unless** — complex animation orchestration is needed (stagger, spring physics)

## Related Documents

- `daily-agent-gate-tiers.md` — Gate tier definitions
- `component-decision-rule.md` — Component selection decision flow
- `visual-quality-gate.md` — Visual quality gate
- `production-release-gate.md` — Production release workflow
- `visual-regression-maintenance.md` — Visual regression maintenance
