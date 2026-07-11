# Proof of Done

Status: `<draft | complete>`
Mode: `<compact | full>`
Date: `<YYYY-MM-DD>`

## Use

- Purpose: provide final evidence that the work is complete, verified, scoped, and reversible.
- Required when: non-DIRECT completion, review handoff, ship handoff, or any owner approval boundary.
- N/A allowed when: DIRECT summary is sufficient. Reason: `<specific reason>`. Risk if skipped: `<risk or none>`
- Mode guidance: compact mode summarizes commands and dirty inventory; full mode completes every table for STANDARD/HIGH-RISK.
- Required evidence: changed files, planned-vs-actual touch list, gates, v4.6.1 classifications, browser evidence when UI changed, dirty inventory, rollback plan.

## Summary

- What changed: `<user-visible outcome, not just files>`
- Owner approval required: `<yes/no — reason>`
- Owner approval: `<pending | approved | not required>`

## Files changed

- `<path>` — `<reason>`

## Planned vs actual touch list

| Planned path | Actual status | Deviation reason |
|---|---|---|
| `<path>` | `<changed/unchanged/added/removed>` | `<reason or none>` |

## Gates run

| Gate | Command | Result | Classification | Evidence |
|---|---|---|---|---|
| `<gate>` | `<command>` | `<PASS/FAIL/SKIPPED>` | `<TARGETED_FAILURE | BROAD_BASELINE_FAILURE | FLAKY_OR_INFRA_FAILURE | NOT_RUN | ACCEPTED_NON_BLOCKING | BLOCKING_UNKNOWN | N/A>` | `<evidence>` |

## Browser verification preflight

- Playwright MCP: `<enabled/disabled/unavailable>`
- Python Playwright: `<usable/unavailable>`
- Browser binary: `<installed/missing/unknown>`
- agent-browser: `<usable/unavailable/not configured>`
- Selected route: `<route or NOT_RUN with reason>`

## Structured browser evidence

Required for UI work; otherwise `N/A — <reason>`.

- dev_url: `<url>`
- screenshot_path: `<path>`
- viewport: `<size>`
- console_errors: `<none/list>`
- accessibility_result: `<result or N/A>`
- performance_result: `<result or N/A>`
- command_used: `<command>`
- timestamp: `<ISO timestamp>`
- known_visual_risks: `<risks or none>`

## Manual verification

- [ ] `<step and expected result>`
- [ ] `<step and expected result>`

## Dirty workspace inventory

- OpenCode protocol files: `<clean/list>`
- Vault protocol/eval files: `<clean/list>`
- Product-code files: `<clean/list>`
- Unrelated pre-existing changes: `<clean/list>`
- Unknown/risky changes: `<clean/list>`

## Unresolved risks

- `<risk or none>`

## Rollback plan

- Type: `<rollback type>`
- Scope: `<exact scope>`
- Preconditions: `<what must be true>`
- Action: `<exact command/operator action>`
- Verify: `<how rollback success is confirmed>`
