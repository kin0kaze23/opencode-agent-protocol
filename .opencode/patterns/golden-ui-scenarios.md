# Golden UI Scenarios

> **Pattern:** `.opencode/patterns/golden-ui-scenarios.md`
> **Version:** 1.0.0
> **Created:** 2026-05-22
> **Status:** Active

## Purpose

Defines 7 golden scenario tests that prove future agents follow the protocol correctly. Each scenario has expected behavior and forbidden behavior. These scenarios bridge the gap from "docs exist" to "agents actually obey."

## Scenario 1: Add a Settings Page Using Existing Design Tokens

**Task:** Add a new `/settings/notifications` page to protected-repo using only existing design tokens and components.

**Expected behavior:**
- Reads `globals.css` for available tokens before writing any styles
- Uses existing `AppShell` component for layout
- Uses existing spacing scale (`--space-*`), colors (`--text-*`, `--bg-*`), and typography (`--text-xs`, etc.)
- Passes Tier 2 gates (lint, typecheck, axe, keyboard, ARIA, visual)
- Touch list includes only the new page file and any necessary route registration
- No new CSS variables introduced

**Forbidden behavior:**
- Adding shadcn/ui or any new UI library
- Hardcoding hex colors instead of using CSS variables
- Creating new spacing values (e.g., `p-5` instead of `p-[var(--space-5)]`)
- Skipping accessibility gates
- Adding new dependencies without explicit approval

**Verification:**
```bash
pnpm lint && pnpm typecheck && pnpm test
pnpm exec playwright test tests/e2e/a11y-keyboard-smoke.spec.ts
pnpm dlx @axe-core/cli http://localhost:3004/settings/notifications
```

## Scenario 2: Fix a Contrast Issue Without Changing Product Identity

**Task:** Fix a color contrast violation on an existing component without changing the visual identity.

**Expected behavior:**
- Identifies the specific contrast violation from axe report
- Fixes by adjusting the text color token or background token, not by changing the component structure
- Preserves the existing visual hierarchy and brand colors
- Re-runs axe to confirm 0 violations
- Visual snapshot shows only the contrast fix, no other visual changes
- Documents the change in the commit message

**Forbidden behavior:**
- Redesigning the component while fixing contrast
- Changing brand colors to fix contrast
- Skipping visual snapshot verification
- Introducing new accessibility violations while fixing the original one

**Verification:**
```bash
pnpm dlx @axe-core/cli http://localhost:3004/affected-page
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts --grep "affected-page"
```

## Scenario 3: Add Form Validation Using ErrorMessage

**Task:** Add form validation to an existing form using the existing `ErrorMessage.tsx` component.

**Expected behavior:**
- Imports and uses existing `ErrorMessage` component
- Adds `role="alert"` and `aria-live="assertive"` to error messages
- Associates error messages with inputs via `aria-describedby`
- Passes keyboard navigation tests (Tab through form, errors announced)
- Passes axe-core with 0 violations
- Visual snapshot shows error state correctly

**Forbidden behavior:**
- Creating a new error message component instead of using existing one
- Using `alert()` or console.log for errors
- Skipping keyboard verification
- Hardcoding error styles instead of using design tokens

**Verification:**
```bash
pnpm exec playwright test tests/e2e/a11y-keyboard-smoke.spec.ts
pnpm dlx @axe-core/cli http://localhost:3004/form-page
```

## Scenario 4: Improve a Core Card While Preserving All Gates

**Task:** Improve the visual hierarchy of a core card component (e.g., care dock, count card) while preserving all accessibility, keyboard, ARIA, and visual gates.

**Expected behavior:**
- Reads existing card component and design tokens before changes
- Makes targeted improvements (spacing, typography, icon size) without redesign
- All Tier 2 gates pass after changes
- Visual snapshot shows intentional improvements only
- Executive rubric score does not decrease
- Touch list is complete before implementation

**Forbidden behavior:**
- Redesigning the card from scratch
- Adding new dependencies or animation libraries
- Skipping any gate
- Claiming improvement without visual evidence
- Breaking existing accessibility features

**Verification:**
```bash
pnpm lint && pnpm typecheck && pnpm test
pnpm exec playwright test tests/e2e/a11y-keyboard-smoke.spec.ts
pnpm exec playwright test tests/e2e/a11y-aria-snapshots.spec.ts
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts
pnpm dlx @axe-core/cli http://localhost:3004/affected-page
```

## Scenario 5: Add Visual Snapshots for a New Route

**Task:** Add visual snapshot coverage for a newly created route.

**Expected behavior:**
- Adds snapshot tests for mobile, tablet, and desktop viewports
- Uses existing snapshot test patterns from `visual-snapshots.spec.ts`
- Captures baseline screenshots with `--update-snapshots`
- Documents the new route in the snapshot test file
- Re-runs snapshot tests to prove they pass against baselines
- Handles dynamic content (dates, user-specific data) by seeding or mocking

**Forbidden behavior:**
- Capturing snapshots with dynamic content that will change between runs
- Skipping viewport coverage (must have at least mobile)
- Not documenting the new route in the test file
- Updating baselines without explicit rationale

**Verification:**
```bash
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts --grep "new-route"
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts --grep "new-route"  # Second run must pass
```

## Scenario 6: Run Executive Review and Produce Evidence-Backed Scoring

**Task:** Complete an executive product review for a UI change with evidence, not vague praise.

**Expected behavior:**
- Scores all 10 rubric categories with specific rationale per score
- Produces before/after screenshots for each changed surface
- Links to axe report, keyboard test results, and visual snapshot results
- Identifies top 3 fixes if score is below 90
- Verdict matches the score threshold (Excellent/Good/Acceptable/Needs Work/Not Ready)
- Evidence pack is complete and committed to `artifacts/visual-review-v<N>/`

**Forbidden behavior:**
- Giving scores without rationale
- Claiming "Excellent" without before/after evidence
- Skipping accessibility or performance gates
- Self-assessing without evidence pack
- Vague praise like "looks great" without specific criteria

**Verification:**
- Review document exists with all 10 categories scored
- Evidence pack directory exists with before/after/diff screenshots
- All gate results are linked or embedded

## Scenario 7: Reject Unnecessary shadcn/ui or Motion Adoption

**Task:** An agent is asked to add a dropdown menu. It should evaluate whether to use shadcn/ui, Motion, or existing components.

**Expected behavior:**
- Checks existing component registry first
- Determines if existing components can compose the dropdown
- If no existing primitive exists, evaluates shadcn/ui against the component decision rule
- Rejects shadcn/ui if the dropdown can be built with existing tokens and a simple `<select>` or `<details>` element
- Rejects Motion if CSS transitions are sufficient
- Documents the decision with rationale
- Passes all Tier 2 gates

**Forbidden behavior:**
- Adding shadcn/ui without checking existing components first
- Adding Motion for simple hover/fade transitions
- Hand-rolling accessible primitives (dropdowns, modals, dialogs)
- Skipping the component decision rule
- Adding dependencies without explicit approval

**Verification:**
```bash
git diff package.json  # Should show no new UI dependencies
cat .opencode/patterns/component-decision-rule.md  # Decision rule was followed
```

## Scenario Execution Protocol

1. **Select scenario** from the 7 above
2. **Read repo truth** (`AGENTS.md`, `NOW.md`, `PLAN.md`)
3. **Execute scenario** following expected behavior
4. **Run verification commands** listed for the scenario
5. **Produce evidence** (screenshots, test results, axe reports)
6. **Document outcome** (PASS/FAIL with rationale)
7. **Update capability certification matrix** if scenario introduces new capability

## Related Documents

- `component-decision-rule.md` — Component selection decision flow
- `executive-product-review-rubric.md` — Executive review scoring
- `daily-agent-gate-tiers.md` — Gate tier definitions
- `CAPABILITY_CERTIFICATION.md` — Capability certification matrix
