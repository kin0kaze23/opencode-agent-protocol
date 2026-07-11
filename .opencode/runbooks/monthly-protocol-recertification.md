# Monthly Protocol Recertification

> **Runbook:** `.opencode/runbooks/monthly-protocol-recertification.md`
> **Version:** 1.0.0
> **Created:** 2026-05-22
> **Status:** Active

## Purpose

Defines the monthly recertification workflow to prevent protocol drift. Protocols degrade over time as agents add exceptions, skip gates, or normalize regressions. This runbook ensures the protocol stays healthy.

## When to Run

- **Monthly:** On the first Monday of each month
- **After major protocol changes:** Within 1 week of change
- **After 3+ drift entries in a month:** Immediately
- **Before major release:** As part of release preparation

## Recertification Checklist

### Phase 1: Gate Command Verification

```bash
# Verify all gate commands still work
/gate-fast    # Tier 1 fast gate
/gate-ui      # Tier 2 UI/a11y gate
/gate-release # Tier 3 release gate
/review-ui    # Independent executive review
```

**Pass criteria:** All commands execute without errors and produce expected output format.

### Phase 2: Golden Scenario Re-Run

Run at least 2 golden scenarios from `golden-ui-scenarios.md`:

1. **Scenario 1:** Add a settings page using existing design tokens
2. **Scenario 4:** Improve a core card while preserving all gates

**Pass criteria:** Both scenarios complete with all gates passing.

### Phase 3: Capability Matrix Verification

Re-run the full capability certification matrix from `CAPABILITY_CERTIFICATION.md`:

| Capability | Test Command | Expected |
|---|---|---|
| Lint hygiene | `pnpm lint` | 0 errors, 0 warnings |
| Type safety | `pnpm typecheck` | 0 errors |
| Unit test coverage | `pnpm test` | All pass |
| Accessibility audit | `pnpm dlx @axe-core/cli` | 0 violations |
| Keyboard verification | `pnpm exec playwright test .../a11y-keyboard-smoke.spec.ts` | All pass |
| ARIA snapshot regression | `pnpm exec playwright test .../a11y-aria-snapshots.spec.ts` | All pass |
| Visual snapshot regression | `pnpm exec playwright test .../visual-snapshots.spec.ts` | All pass |
| Performance budget | `node scripts/check-lighthouse-budget.js` | All pass |
| Build integrity | `pnpm build` | 0 errors |

**Pass criteria:** All capabilities still PASS. Update matrix if any changed.

### Phase 4: Dependency Drift Check

```bash
# Check for dependency updates
pnpm outdated

# Check for duplicate Playwright versions across repos
find . -name "package.json" -exec grep -l "@playwright/test" {} \;

# Verify lockfiles are up to date
pnpm install --frozen-lockfile  # Should pass without changes
```

**Pass criteria:** No unexpected dependency changes. Lockfiles are consistent.

### Phase 5: Visual Baseline Stability

```bash
# Run visual snapshots without updating baselines
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts
```

**Pass criteria:** All snapshots pass without baseline updates. If any fail:
- Review diff to determine if intentional or regression
- If regression: fix the code
- If intentional: update baseline with rationale per `baseline-update-policy.md`

### Phase 6: Executive Rubric Consistency

Run `/review-ui` on a recent UI change and verify:
- Reviewer scores independently
- Evidence is cited for each category
- Discrepancy analysis is provided if scores differ

**Pass criteria:** Review produces structured output with evidence citations.

### Phase 7: Drift Log Update

Review `CAPABILITY_DRIFT_LOG.md` and:
- Add any new drift entries discovered during recertification
- Mark resolved entries as resolved
- Escalate any REGRESSION or high-severity drift

## Output Format

```markdown
# Monthly Recertification — <Month Year>

## Date: <date>
## Agent: <agent name>

## Results
| Phase | Status | Notes |
|---|---|---|
| Gate commands | PASS/FAIL | <details> |
| Golden scenarios | PASS/FAIL | <details> |
| Capability matrix | PASS/FAIL | <X/Y capabilities PASS> |
| Dependency drift | PASS/FAIL | <details> |
| Visual baseline stability | PASS/FAIL | <details> |
| Executive rubric consistency | PASS/FAIL | <details> |
| Drift log update | PASS/FAIL | <X new entries> |

## Verdict: PASS / FAIL
## New drift entries: <list or "None">
## Resolved drift entries: <list or "None">
## Next recertification: <date>
```

## Escalation Rules

| Condition | Action |
|---|---|
| Any phase FAIL | Investigate root cause. Fix before marking recertification complete. |
| Capability REGRESSION | Block release. Fix capability before proceeding. |
| 3+ new drift entries | Review agent behavior. Reinforce protocol rules. |
| Gate commands broken | Fix commands immediately. Protocol is unusable without them. |

## Related Documents

- `CAPABILITY_CERTIFICATION.md` — Capability certification matrix
- `CAPABILITY_DRIFT_LOG.md` — Capability drift log
- `golden-ui-scenarios.md` — Golden scenario tests
- `baseline-update-policy.md` — Baseline update approval policy
- `daily-agent-gate-tiers.md` — Gate tier definitions
