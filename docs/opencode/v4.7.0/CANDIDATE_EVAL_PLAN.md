# OpenCode v4.7.0 Candidate Eval Plan

Status: Phase E live validation pilot plan and historical activation prerequisite. Phase F.1 promotes v4.7.0 to the active production baseline.

## Objective

Validate that the v4.7.0 Senior Specialist Capability Pack improves real task execution without adding process bloat, weakening v4.6.1 gates, changing model routing, or creating new agents.

## Candidate tasks to test

Use small but realistic tasks that exercise different specialist surfaces:

1. **Product + UI planning task**
   - Trigger: net-new or product-facing UI request.
   - Expected artifacts: PRD-lite, Design Brief, QA Plan, compact Proof of Done plan.
   - Evidence focus: user problem, visual hierarchy, state matrix, accessibility, N/A handling.

2. **API contract task**
   - Trigger: API/client/server contract change or review.
   - Expected artifacts: API contract notes, QA Plan, relevant ADR if cross-surface.
   - Evidence focus: request/response/error/auth compatibility, tests, docs, client/server alignment.

3. **Infra/runtime task**
   - Trigger: runtime config, environment, CI, deploy, or rollback readiness review.
   - Expected artifacts: infra validation notes, rollback plan, health/observability checks.
   - Evidence focus: runtime authority, secret safety, deploy/rollback/health proof.

4. **Sensitive-path task**
   - Trigger: auth, payment, crypto, permissions, user data, or other sensitive trust boundary.
   - Expected artifacts: Threat Model, QA Plan, security review summary.
   - Evidence focus: assets, actors, trust boundaries, mitigations, residual owner acceptance.

## Required artifacts

Each pilot task should explicitly state which artifacts are required, compact, or N/A with reason and risk:
- Product Brief / PRD-lite
- UI Design Brief
- QA Plan
- Threat Model
- ADR
- Proof of Done
- Role-profile evidence notes when relevant

## Expected evidence

Every pilot task should include:
- Touch list and out-of-scope boundaries.
- Runtime authority when implementation or runtime review depends on it.
- v4.6.1 gate classifications for every non-pass or skipped gate.
- Dirty workspace inventory.
- Browser route preflight and structured browser evidence for qualifying UI work.
- API contract evidence for API/client/server changes.
- Infra/deploy/rollback/health evidence for runtime/deploy changes.
- Security summary for sensitive paths.

## Validation commands

Run these candidate validation commands during Phase E:

```bash
git diff --check -- .opencode/conformance docs/opencode/v4.7.0
bash .opencode/conformance/tests/protocol-capabilities-v470.sh
bash .opencode/scripts/workspace-protocol-guard.sh
jq -r '.version' .opencode/brain-config.json
git status --short
```

For any pilot touching product code, also run the repo-native gates declared in that repo's `PLAN.md` and `AGENTS.md`.

## Pass criteria

The pilot passes only if:
- v4.7.0 remained candidate/prep until Phase F and is active after Phase F.1 promotion.
- Active version remains v4.6.1 during the pilot.
- Required artifacts are present or N/A with reason and risk.
- The workflow improves clarity without forcing all templates onto DIRECT/FAST tasks.
- v4.6.1 gate classifications are used correctly.
- No new agents or model-routing changes are required.
- Workspace protocol guard passes.
- No secrets or unrelated dirty files are staged.

## Fail criteria

The pilot fails if:
- Any command or doc implies v4.7.0 is active before Phase F.
- Candidate checks require heavy artifacts for tiny DIRECT/FAST tasks without N/A escape.
- Missing artifacts force implementation to invent product, architecture, security, or release strategy.
- Gate classifications are skipped or misused.
- Product-code changes are included without an approved repo-specific plan.
- Sensitive residual risk lacks owner acceptance.

## Rollback criteria

Rollback or revise the candidate if:
- Candidate conformance conflicts with v4.6.1 active guard behavior.
- Role profiles behave like new agents or imply model-routing changes.
- Command wiring causes over-enforcement on small tasks.
- The live pilot shows material confusion, unnecessary bloat, or weaker verification.

## Preconditions before v4.7.0 activation

Before v4.7.0 activation (completed before Phase F.1 promotion):
- Phase E live validation pilot must pass.
- Phase F.0 activation-polish fixes must preserve compact/N/A paths, risk-based visual regression, boundary-only API contract validation, explicit secret-safety language, and advisory-only role profiles.
- Candidate conformance must pass.
- Workspace protocol guard must pass.
- Active promotion touch list must be explicit and approved.
- `brain-config`, `NOW.md`, `.opencode/AGENTS.md`, and any version docs must be updated together in Phase F.
- Rollback plan for activation must be documented.
