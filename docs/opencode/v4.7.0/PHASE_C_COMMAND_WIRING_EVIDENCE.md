# v4.7.0 Phase C Command Wiring Evidence

## Objective

Wire the v4.7.0 Senior Specialist Capability Pack prep artifacts into the OpenCode command surface while keeping the active workspace protocol at v4.6.1.

## Lane

STANDARD — workspace protocol command-surface change spanning multiple files.

## Current Protocol State

- Active protocol remains: v4.6.1.
- v4.7.0 is not active yet.
- Phase A templates are committed.
- Phase B skills are committed.
- Phase C is limited to command wiring only.

## Runtime Authority

- Target runtime surface: checked-in OpenCode workspace command files under `.opencode/commands/`.
- Product runtime entrypoint: N/A — no product app, server, worker, database, or UI route is being changed.
- Protocol runtime checks must continue to report v4.6.1 until a later explicit promotion phase.

## State Model

- This phase changes command guidance only.
- No product data model, API schema, persistent storage, runtime config, helper roster, model routing, or active protocol version changes are in scope.
- New v4.7.0 templates and skills remain prep assets until later promotion.

## Touch List

- `.opencode/commands/analyze.md` — wire Product Brief / PRD-lite and specialist-analysis references where applicable.
- `.opencode/commands/plan-feature.md` — wire v4.7.0 templates and specialist readiness checks into planning.
- `.opencode/commands/implement.md` — require existing Phase C artifacts to be honored before implementation without inventing decisions.
- `.opencode/commands/review.md` — wire specialist review checks for design system, visual regression, contracts, infra, and threat modeling.
- `.opencode/commands/gates.md` — wire command-surface verification expectations for new specialist gates.
- `.opencode/commands/ship.md` — wire ship-readiness reporting for specialist evidence and unresolved risks.

## Explicitly Out of Scope

- `NOW.md`
- `.opencode/AGENTS.md`
- `.opencode/brain-config.json`
- role profiles
- conformance scripts
- vault docs
- product-code repos
- model routing
- v4.7.0 active promotion
- new specialist agents
- broad dirty workspace cleanup
- `.env.doppler` or any secret-bearing file

## Product Brief / PRD-lite

N/A.

Reason: This is protocol infrastructure work, not a product-facing feature.

Risk: Command guidance can still affect future product work, so Phase C must preserve v4.6.1 safety gates and avoid weakening current lifecycle checks.

## UI Design Brief

N/A.

Reason: No product UI, page, component, copy, or visual surface is being changed.

Risk: UI-related command guidance must still preserve browser evidence, accessibility, visual-regression, and design-system expectations for future qualifying UI changes.

## Success Criteria

- Phase B committed status is verified before command wiring begins.
- Only the six command files in the touch list are modified for Phase C implementation.
- Active protocol remains v4.6.1 after Phase C.
- No v4.7.0 promotion language is added to active runtime files.
- New v4.7.0 templates and skills are referenced as prep/specialist capability surfaces, not active protocol promotion.
- `.env.doppler` and unrelated dirty files remain unstaged.
- Command-surface sanity checks pass.
- Workspace protocol guard passes.

## QA Plan

- Run command-surface sanity checks focused on the six touched command files.
- Run `bash .opencode/scripts/workspace-protocol-guard.sh`.
- Confirm active version remains v4.6.1.
- Confirm no unrelated dirty files are staged.
- Confirm `.env.doppler` is not staged.

## Rollback Plan

- Type: git revert.
- Scope: Phase C command wiring commit only.
- Preconditions: Phase C has been committed and no later dependent promotion commit has been applied.
- Action: revert the Phase C command wiring commit.
- Verify: command files return to pre-Phase-C behavior and workspace protocol guard passes.

## Dirty Workspace Note

- The workspace root has substantial unrelated pre-existing dirty state.
- Phase C must use targeted edits and targeted staging only.
- Unrelated dirty files must remain unstaged.
- `.env.doppler` must not be staged.

## Phase C Implementation Evidence

Status: implemented and locally validated; commit approved after evidence was archived outside root `PLAN.md`.

Actual files changed:
- `.opencode/commands/analyze.md`
- `.opencode/commands/plan-feature.md`
- `.opencode/commands/implement.md`
- `.opencode/commands/review.md`
- `.opencode/commands/gates.md`
- `.opencode/commands/ship.md`
- `docs/opencode/v4.7.0/PHASE_C_COMMAND_WIRING_EVIDENCE.md`

Plan-vs-actual touch list:
- Planned and changed: all approved command files.
- Evidence archived to this docs path instead of committing root `PLAN.md` because the pre-commit hook blocks root markdown outside the allowlist.
- Deviations: root `PLAN.md` was not committed; evidence preserved here per owner approval.

Validation commands:
- `git diff --check -- PLAN.md .opencode/commands` — PASS before archive.
- `bash .opencode/scripts/workspace-protocol-guard.sh` — PASS before commit attempt.
- Command-surface sanity check focused on template/skill references in the six touched command files — PASS before commit attempt.
- `jq -r '.version' .opencode/brain-config.json` — PASS, returned `4.6.1`.
- Reviewer audit — APPROVE.

Rollback plan:
- Revert the Phase C command wiring commit if committed.
- Verify command files return to pre-Phase-C behavior and workspace protocol guard passes.

Known risks:
- Command docs now reference v4.7.0 prep artifacts while the active protocol remains v4.6.1; wording must remain clear that this is not active promotion.
- Existing broad workspace dirtiness can obscure review unless scoped status is used.
- Risk-based gates must remain trigger-based so tiny DIRECT/FAST work is not overburdened.

Active protocol confirmation:
- v4.7.0 is not active yet.
- `.opencode/brain-config.json` must continue to report `4.6.1` until the later promotion phase.
