---
name: design-system-governance
description: Design-system governance for UI work — token/component reuse, visual consistency, responsive states, accessibility fit, and drift prevention. Active v4.7.0 specialist skill with trigger-based command wiring.
---

# Design-System Governance

Senior UI/UX + frontend review for preventing design drift. Use this skill when UI/design-system triggers apply; compact/N/A paths remain valid for low-risk work with reason and risk.

## Purpose

Help agents behave like senior UI/UX designers and frontend engineers by reusing the existing design system, preventing visual drift, and documenting intentional exceptions.

## Read First

Before judging design-system fit, read:

1. `<repo>/AGENTS.md` and `<repo>/NOW.md`
2. `.opencode/templates/DESIGN_BRIEF.md` and `.opencode/templates/PROOF_OF_DONE.md`
3. The active `<repo>/PLAN.md` if one exists
4. Existing design-system sources: tokens, theme config, Tailwind config, CSS variables, component library, Storybook, design docs, or established UI components
5. The touched UI/component/style files and adjacent examples

## When to Use

- Touch list includes UI components, pages, layouts, CSS, theme, tokens, typography, spacing, icons, or product copy.
- A new component, variant, state, token, or visual pattern is proposed.
- Review mentions design drift, generic UI, inconsistent spacing, brand mismatch, or dark/light mode issues.

## When Not to Use

- No user-facing UI, copy, layout, state, or visual behavior changes.
- Pure backend/API/config work with no visual output.
- DIRECT lane typo fixes that do not change UI structure or meaning.
- Use `N/A — <reason>; risk: <risk or none>` when skipped.

## Required Inputs

- UI Design Brief or `N/A` reason
- Touch list with UI/style paths
- Existing design-system source or explicit statement that none exists
- Target states and responsive targets

## Procedure

1. Identify the design-system source of truth: tokens, components, theme files, style guide, or existing dominant patterns.
2. Check token usage: color, typography, spacing, radius, shadow, border, z-index, motion, and focus styles.
3. Check component reuse: prefer existing components/variants before new primitives; flag duplicate patterns.
4. Check typography and spacing hierarchy against adjacent screens and the UI Design Brief.
5. Check state coverage: loading, empty, error, disabled, success, hover, focus, active, selected.
6. Check responsive behavior for mobile, tablet, desktop, and wide layouts where relevant.
7. Check dark/light mode when the repo supports both; otherwise mark `N/A — no mode support found`.
8. Check accessibility fit at a design level: visible labels, focus affordance, contrast intent, reduced-motion alternatives.
9. Classify gaps with v4.6.1 labels when they affect gates: `TARGETED_FAILURE`, `BROAD_BASELINE_FAILURE`, `FLAKY_OR_INFRA_FAILURE`, `NOT_RUN`, `ACCEPTED_NON_BLOCKING`, or `BLOCKING_UNKNOWN`.

## Evidence Requirements

- Design-system source path(s) inspected
- Tokens/components reused or intentionally added
- State/responsive coverage summary
- Screenshot or browser evidence when UI is implemented
- Explicit exceptions with owner approval if design drift is accepted

## Output Format

```markdown
## Design-System Governance Report

Design-system source: <paths or none found>
Scope: <UI paths/components reviewed>

### Checks
- Token reuse: <PASS/FAIL/N/A> — <evidence>
- Component reuse: <PASS/FAIL/N/A> — <evidence>
- Typography/spacing: <PASS/FAIL/N/A> — <evidence>
- State coverage: <PASS/FAIL/N/A> — <evidence>
- Responsive coverage: <PASS/FAIL/N/A> — <evidence>
- Dark/light mode: <PASS/FAIL/N/A> — <evidence>
- Accessibility design fit: <PASS/FAIL/N/A> — <evidence>

Verdict: <PASS / NEEDS_FIX / ACCEPTED_EXCEPTION>
Gate classification if non-pass: <v4.6.1 label>
Required follow-up: <none or actions>
```

## Failure Conditions

- New visual language or tokens are introduced without rationale or owner approval.
- Existing components are bypassed without reason.
- Required UI states or responsive targets are missing.
- Dark/light mode support regresses in a repo that supports both.
- Missing evidence makes the result `BLOCKING_UNKNOWN`.

## Related Templates

- Fill design intent in `.opencode/templates/DESIGN_BRIEF.md`.
- Record final evidence and exceptions in `.opencode/templates/PROOF_OF_DONE.md`.
