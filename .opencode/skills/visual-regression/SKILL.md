---
name: visual-regression
description: Risk-based visual regression and UI polish verification using browser preflight, viewport screenshots, baseline/reference comparison, and intentional-change classification. Active v4.7.0 specialist skill with trigger-based command wiring.
---

# Visual Regression

Catch visual regressions and polish drift without making every tiny UI change bureaucratic. This skill is risk-based: required for material visual changes or available baselines/references, advisory or `NOT_RUN` with reason/risk for tiny or baseline-free changes.

## Purpose

Help agents verify visual quality with browser evidence, viewport coverage, and intentional-vs-regression classification before UI changes are accepted.

## Read First

1. `<repo>/AGENTS.md`, `<repo>/NOW.md`, and active `<repo>/PLAN.md` if present
2. `.opencode/templates/DESIGN_BRIEF.md` and `.opencode/templates/PROOF_OF_DONE.md`
3. Browser verification preflight result when available
4. Existing screenshots, Storybook stories, design references, or previous Proof of Done evidence
5. Changed UI files and routes/components they affect

## When to Use

- UI-surface work materially changes layout, visual hierarchy, tokens, responsive behavior, component states, or product copy.
- A baseline/reference screenshot exists, a Design Brief defines visual expectations, or the changed surface is material enough that visual drift would affect user trust.
- Reviewing a user-facing UI change before ship.

## Required vs Advisory

- **Required:** a baseline/reference exists for the changed route, a material visual surface changed, public/customer-facing layout changed, design-system tokens/components changed, high-risk visual flows changed, or stateful screens changed.
- **Advisory:** no baseline exists, small copy changes, internal-only UI, local style tweaks, or low-risk DIRECT/FAST changes with no layout/state/hierarchy impact.
- **N/A:** non-visual work; include reason and risk.

## When Not to Use

- Backend-only, docs-only, API-only, or config-only work.
- DIRECT lane UI typo where no layout/state/hierarchy changes.
- When no browser route is usable; report `NOT_RUN` with reason and risk instead of installing dependencies without approval.

## Procedure

1. Run or read browser verification preflight: Playwright MCP state, Python Playwright state, browser binary state, agent-browser state, selected route.
2. Identify affected routes/components and expected viewports from the Design Brief.
3. Locate baseline/reference screenshots or approved visual descriptions.
4. Capture current screenshots only through an approved usable browser route.
5. Compare baseline/reference vs current for layout, hierarchy, spacing, typography, color, state, and responsive behavior.
6. Classify each difference as `INTENTIONAL`, `REGRESSION`, `BASELINE_MISSING`, or `UNCLEAR`.
7. Use v4.6.1 labels for non-pass outcomes: `TARGETED_FAILURE`, `BROAD_BASELINE_FAILURE`, `FLAKY_OR_INFRA_FAILURE`, `NOT_RUN`, `ACCEPTED_NON_BLOCKING`, or `BLOCKING_UNKNOWN`.
8. Record structured browser evidence in Proof of Done when UI work was implemented.

## Viewport Matrix Guidance

Use the repo's Design Brief. Default when unspecified:

| Target | Viewport |
|---|---|
| Mobile | 390x844 |
| Tablet | 768x1024 |
| Desktop | 1440x900 |
| Wide | 1920x1080 when wide layout matters |

## Evidence Requirements

- Browser preflight summary
- Baseline/reference source or reason none exists
- Screenshot paths and viewports
- Console error status
- Intentional vs unintentional difference classification
- Known visual risks

## Output Format

```markdown
## Visual Regression Report

Routes/components: <list>
Browser route: <selected route>
Baseline/reference: <paths or N/A reason>

| Target | Screenshot | Classification | Notes |
|---|---|---|---|
| <viewport> | <path> | <INTENTIONAL/REGRESSION/BASELINE_MISSING/UNCLEAR> | <notes> |

Console errors: <none/list>
Verdict: <PASS / NEEDS_FIX / NOT_RUN / ACCEPTED_EXCEPTION>
Gate classification if non-pass: <v4.6.1 label>
```

## Failure Conditions

- Required browser route is unavailable and no owner-approved exception exists.
- Visual differences are unintentional on changed routes.
- Baseline is missing for required visual-regression coverage and no reason/risk is documented; for low-risk or baseline-free work, record `BASELINE_MISSING` or `NOT_RUN` with reason, risk, and missing confidence instead of treating it as automatically blocking.
- Screenshot evidence is missing for UI work that required it.
- Result is unclear and must be `BLOCKING_UNKNOWN`.

## Related Templates

- Plan routes, states, and visual evidence in `.opencode/templates/DESIGN_BRIEF.md`.
- Record browser preflight and structured evidence in `.opencode/templates/PROOF_OF_DONE.md`.
