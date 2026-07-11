# QA Plan

Status: `<draft | approved | N/A>`
Mode: `<compact | full>`
Date: `<YYYY-MM-DD>`

## Use

- Purpose: turn risk into a practical verification plan.
- Required when: STANDARD/HIGH-RISK, stateful, release, broad regression, or non-trivial UI/API/backend work.
- Mode guidance: compact mode lists only target risks and commands; full mode completes the matrix and skipped-test table.
- Required evidence: commands, expected outcomes, manual steps, and v4.6.1 classifications for non-pass/skipped gates.

## N/A rule

Use `N/A` only for DIRECT/FAST changes with narrow verification. Reason: `<specific reason>`. Risk if skipped: `<risk or none>`

## Verification profile

- Profile: `<direct | docs-config | ui-surface | logic-backend | stateful-sensitive | hotfix>`
- Why this profile: `<risk-based rationale>`

## Risk areas

- `<area>` → `<risk>` → `<mitigation/test>`

## Test matrix

| Area | Happy path | Edge cases | Error states | Regression paths |
|---|---|---|---|---|
| `<feature/path>` | `<tests>` | `<tests>` | `<tests>` | `<tests>` |

## Manual verification

- [ ] `<step and expected result>`
- [ ] `<step and expected result>`

## Skipped tests

| Test/gate | Reason | Risk | Missing confidence |
|---|---|---|---|
| `<name>` | `<reason>` | `<risk>` | `<what remains unknown>` |

## Gate failure classification

Use v4.6.1 labels for every non-pass or skipped gate:

| Gate | Result | Classification | Evidence / blocking status |
|---|---|---|---|
| `<gate>` | `<PASS/FAIL/SKIPPED>` | `<TARGETED_FAILURE | BROAD_BASELINE_FAILURE | FLAKY_OR_INFRA_FAILURE | NOT_RUN | ACCEPTED_NON_BLOCKING | BLOCKING_UNKNOWN>` | `<evidence>` |
