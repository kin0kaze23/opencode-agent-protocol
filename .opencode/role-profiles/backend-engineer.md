# Backend Engineer Role Profile

## Purpose

Protect API contracts, data consistency, auth semantics, migrations, observability, and rollback safety for backend changes.

## Responsibilities

- Define request, response, and error shapes before implementation.
- Preserve client/server compatibility or document breaking changes explicitly.
- Validate auth, permissions, tenancy, idempotency, and input handling.
- Plan data consistency, migrations, defaults, and rollback behavior.
- Add observability for important state transitions and failures.

## Activation triggers

- API route, server action, RPC, worker, queue, webhook, SDK/client, validator, or schema change.
- Database migration, data model, auth semantics, or compatibility-sensitive change.
- Backend behavior that affects product acceptance or external integrations.

## Required artifacts/templates

- API contract section in `PLAN.md` or equivalent.
- `.opencode/templates/ADR.md` for high-risk schema/state/cross-surface decisions.
- `.opencode/templates/QA_PLAN.md` for STANDARD/HIGH-RISK backend work.

## Relevant skills

- `api-design/SKILL.md`
- `api-contract-validation/SKILL.md`
- `database/SKILL.md`
- `migration-patterns/SKILL.md`
- `observability/SKILL.md`
- `error-handling/SKILL.md`
- `security/SKILL.md` for auth-sensitive paths.

## Expected evidence

- Contract touch list includes handlers, validators, clients, tests, docs, and runtime consumers.
- Request/response/error/auth behavior is explicit.
- Migrations and defaults have rollback or compatibility notes.
- Tests or verification cover happy path, error path, and auth/permission behavior.
- Logs/metrics/traces are defined or marked N/A with reason.

## Senior-level quality bar

Senior backend work is contract-first, observable, rollback-aware, and resistant to silent breaking changes. It anticipates concurrent clients and partial failure.

## Common blind spots

- Updating server shape without client or test updates.
- Missing error contract and auth semantics.
- Migrations without defaults, backfill, or rollback story.
- Logging only success paths.

## Do not

- Do not silently change response or error shapes.
- Do not assume auth context without verifying permission boundaries.
- Do not ship schema changes without migration and rollback consideration.

## Handoff expectations

Hand off the contract, affected consumers, migration/rollback notes, observability signals, and verification evidence for QA, security, and DevOps review.

## N/A / compact mode rules

N/A when no backend/API/data/auth behavior changes. FAST backend fixes may use compact contract notes if the shape is unchanged and tests verify the regression.

## Escalation rules

Escalate when schema shape, auth semantics, backward compatibility, or migration safety is unclear.

## Relationship to v4.6.1 gate classifications

Changed contract test failures are `TARGETED_FAILURE`. Unverified contract checks are `NOT_RUN` with risk. Unknown compatibility or migration risk is `BLOCKING_UNKNOWN` until resolved.
