# Baseline Update Approval Policy

> **Pattern:** `.opencode/patterns/baseline-update-policy.md`
> **Version:** 1.0.0
> **Created:** 2026-05-22
> **Status:** Active

## Purpose

Defines strict rules for updating visual and ARIA snapshot baselines. This prevents agents from accidentally normalizing bad UI by updating baselines too easily.

## Policy Statement

**Visual or ARIA snapshot baselines may only be updated when ALL of the following conditions are met:**

1. The visual/semantic change is intentional and approved.
2. Before/after diff is captured and reviewed.
3. Accessibility gates still pass (axe 0 violations, keyboard PASS).
4. Executive/product reviewer approves if visual hierarchy changes significantly.
5. The commit message references the baseline update rationale.

## Forbidden Actions

- **Never** update baselines to make failing tests pass without reviewing the diff.
- **Never** update baselines after introducing accessibility regressions.
- **Never** update baselines without documenting the rationale.
- **Never** update baselines for dynamic content that should be masked or seeded instead.
- **Never** update baselines as a shortcut to fix flaky tests.

## Visual Snapshot Baseline Update Process

### Step 1: Identify the Change

```bash
# Run visual snapshots to see failures
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts
```

### Step 2: Review the Diff

Playwright generates diff images in `test-results/`. Review each diff:
- Expected: `tests/e2e/visual-snapshots.spec.ts-snapshots/<name>.png`
- Received: `test-results/<test-name>/<name>-actual.png`
- Diff: `test-results/<test-name>/<name>-diff.png`

**Decision:**
- If diff shows intentional change → proceed to Step 3
- If diff shows unintentional regression → fix the code, do NOT update baseline

### Step 3: Verify Accessibility Gates

```bash
pnpm exec playwright test tests/e2e/a11y-keyboard-smoke.spec.ts
pnpm dlx @axe-core/cli http://localhost:3004/affected-page
```

**If any gate fails:** Stop. Fix accessibility issue before updating baseline.

### Step 4: Update Baseline with Rationale

```bash
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts --update-snapshots --grep "changed-page"
```

### Step 5: Commit with Rationale

```bash
git add tests/e2e/visual-snapshots.spec.ts-snapshots/
git commit -m "chore: update visual snapshot baseline for <page>

Rationale: <describe intentional visual change>
Before: <describe previous state>
After: <describe new state>
Accessibility: axe 0 violations, keyboard PASS
Reviewer: <agent name or 'self-reviewed'>"
```

## ARIA Snapshot Baseline Update Process

### Step 1: Identify the Change

```bash
pnpm exec playwright test tests/e2e/a11y-aria-snapshots.spec.ts
```

### Step 2: Review the Semantic Diff

ARIA snapshots capture the accessibility tree. Review the diff:
- If diff shows intentional semantic change (e.g., added landmark, improved label) → proceed
- If diff shows regression (e.g., removed landmark, broken label) → fix the code

### Step 3: Verify Accessibility Gates

Same as visual snapshots — axe and keyboard must pass.

### Step 4: Update Baseline with Rationale

```bash
pnpm exec playwright test tests/e2e/a11y-aria-snapshots.spec.ts --update-snapshots
```

### Step 5: Commit with Rationale

```bash
git commit -m "chore: update ARIA snapshot baseline for <page>

Rationale: <describe intentional semantic change>
Accessibility impact: <improved/neutral/regressed>
Accessibility: axe 0 violations, keyboard PASS"
```

## Dynamic Content Handling

If baseline failures are caused by dynamic content (dates, user-specific data, time):

1. **Do NOT update baseline** — this will cause recurring flakiness.
2. **Use stabilization utilities** from `test-utils/snapshot-stability.ts`:
   - `freezeDate(page, '2026-05-22T00:00:00Z')` — freeze system time
   - `maskDynamicElements(page, selectors)` — mask dynamic elements
   - `waitForStability(page)` — wait for animations/fonts
3. **Or seed data** using `scripts/seed-profile-fixture.js` for consistent state.
4. **Re-run snapshots** after stabilization.

## Escalation Rules

| Condition | Action |
|---|---|
| Baseline update would normalize accessibility regression | **Block.** Fix accessibility issue first. |
| Baseline update would normalize visual regression | **Block.** Fix visual issue first. |
| Baseline update for dynamic content | **Block.** Use stabilization utilities instead. |
| Baseline update without rationale | **Block.** Document rationale before updating. |
| Baseline update for significant visual hierarchy change | **Require reviewer approval.** Run `/review-ui` first. |

## Related Documents

- `visual-regression-maintenance.md` — Visual regression maintenance runbook
- `visual-quality-gate.md` — Visual quality gate definition
- `snapshot-stability.ts` — Dynamic content stabilization utilities
- `golden-ui-scenarios.md` — Golden scenario tests (Scenario 5: Add visual snapshots)
