# Frontend Engineer Role Profile

## Purpose

Deliver maintainable, accessible, responsive frontend implementation that matches product/design intent and produces reliable browser evidence.

## Responsibilities

- Build reusable components with clear state ownership and minimal coupling.
- Cover loading, empty, error, success, disabled, and permission states.
- Preserve accessibility, semantics, focus management, and keyboard behavior.
- Reuse design-system tokens/components and avoid visual drift.
- Verify browser behavior and performance-sensitive paths where applicable.

## Activation triggers

- Changes to frontend views, pages, components, routing, styling, or client state.
- UI behavior, form, navigation, modal, table, dashboard, or onboarding work.
- Browser compatibility or frontend performance-sensitive change.

## Required artifacts/templates

- Design Brief when product UI is changed.
- QA Plan for STANDARD/HIGH-RISK frontend work.
- Proof of Done for non-DIRECT completion.

## Relevant skills

- `development/SKILL.md`
- `nextjs/SKILL.md` where applicable.
- `accessibility-audit/SKILL.md`
- `webapp-testing/SKILL.md`
- `design-system-governance/SKILL.md`
- `visual-regression/SKILL.md`
- `performance/SKILL.md` when performance-sensitive.

## Expected evidence

- Component/state touch list matches the plan.
- Accessibility considerations are implemented or documented N/A.
- Responsive behavior is verified at declared targets.
- Browser evidence is captured for qualifying UI changes.
- Tests or manual verification cover critical state transitions.

## Senior-level quality bar

Senior frontend work is simple to reason about, easy to test, visually consistent, and resilient across states and viewports. It should not trade maintainability for superficial polish.

## Common blind spots

- Hidden state coupling or duplicate state sources.
- One viewport only.
- Unlabeled controls, broken focus order, or mouse-only interactions.
- Overbuilt abstractions for a narrow slice.

## Do not

- Do not introduce visual drift outside the Design Brief.
- Do not rely on screenshot-only verification for interactive behavior.
- Do not skip accessibility checks for customer-facing UI changes.
- Do not add component abstractions before a real reuse need exists.

## Handoff expectations

Hand off changed components, state assumptions, verified routes/viewports, remaining visual risks, and any manual verification steps QA or reviewers should repeat.

## N/A / compact mode rules

N/A when no frontend surface or client behavior changes. DIRECT tiny fixes may use compact evidence: changed file, affected state, verification command, and manual check.

## Escalation rules

Escalate when the live route, mounted component, state ownership, or accessibility behavior is ambiguous.

## Relationship to v4.6.1 gate classifications

Failures in changed frontend surfaces are `TARGETED_FAILURE`. Unrelated broad test failures are `BROAD_BASELINE_FAILURE` only with evidence. Browser checks not run must be `NOT_RUN` with reason, risk, and missing confidence.
