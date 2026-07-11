# OpenCode Templates

Reusable artifact templates for the active v4.7.0 senior-specialist workflow. These templates are trigger-based and proportional to risk; they do not make every small task bureaucratic.

## Lifecycle map

| Stage | Template | Required when | N/A allowed when |
|---|---|---|---|
| Product / PM | `PRD.md` | Net-new, product-facing, or ambiguous work | DIRECT tiny bug fix; include reason + risk |
| UI / UX | `DESIGN_BRIEF.md` | UI, component, page, copy, or visual-system work | No user-facing UI; include reason + risk |
| QA | `QA_PLAN.md` | STANDARD/HIGH-RISK, stateful, release, or broad regression risk | DIRECT/FAST with narrow verification; include reason + risk |
| Security | `THREAT_MODEL.md` | Auth, payments, crypto, secrets, permissions, user data, callbacks | Non-sensitive work; include reason + risk |
| Architecture | `ADR.md` | High-risk, cross-surface, schema/state/model/runtime decisions | Local reversible detail; include reason + risk |
| Completion | `PROOF_OF_DONE.md` | Non-DIRECT completion, ship, or review handoff | DIRECT summary is enough; include reason + risk |

## Mode guidance

- **Compact mode:** DIRECT/FAST tasks may keep each applicable section to the smallest useful evidence, typically 1-3 bullets, when risk is low and scope is narrow.
- **Full mode:** STANDARD/HIGH-RISK should fill all required fields or mark `N/A — <reason>; risk: <risk or none>`.
- **N/A rule:** `N/A` is acceptable only with a specific reason and risk statement. Skipped/N/A verification items must include reason, risk, and missing confidence when relevant. Unknown fields that affect scope, risk, or acceptance criteria should block planning.
- **Anti-bureaucracy rule:** Do not force every template onto every small task; select artifacts by trigger and risk, and prefer compact/N/A paths for narrow DIRECT/FAST work.
- **v4.6.1 classifications:** Gate results in QA and Proof of Done must use: `TARGETED_FAILURE`, `BROAD_BASELINE_FAILURE`, `FLAKY_OR_INFRA_FAILURE`, `NOT_RUN`, `ACCEPTED_NON_BLOCKING`, or `BLOCKING_UNKNOWN`.

## Wiring note

These templates are part of the v4.7.0 active production baseline. Command wiring is trigger-based: compact/N/A paths remain allowed for DIRECT/FAST work with reason + risk, while STANDARD/HIGH-RISK work should provide fuller artifacts where the trigger applies.
