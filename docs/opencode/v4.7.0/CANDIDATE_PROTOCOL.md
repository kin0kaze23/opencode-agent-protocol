# OpenCode v4.7.0 Candidate Protocol

Status: historical candidate record. Promoted to active production baseline in Phase F.1 after Phase E validation and Phase F.0 polish fixes.

This document summarizes the v4.7.0 candidate after Phase A templates, Phase B skills, Phase C command wiring, and Phase D1 role profiles. Phase F.1 promotes these capabilities to the active workspace protocol while preserving trigger-based scope.

## Candidate scope

v4.7.0 is the active Senior Specialist Capability Pack baseline after Phase F.1. It adds reusable artifacts and standards for higher-quality planning, implementation, review, gates, and ship decisions while preserving the v4 Owner/helper architecture and v4.6.1 stabilization safeguards.

## Phase A — Templates

Committed in `acfe315 protocol: add v4.7.0 senior specialist templates`.

Candidate templates:
- `.opencode/templates/README.md`
- `.opencode/templates/PRD.md`
- `.opencode/templates/DESIGN_BRIEF.md`
- `.opencode/templates/QA_PLAN.md`
- `.opencode/templates/THREAT_MODEL.md`
- `.opencode/templates/ADR.md`
- `.opencode/templates/PROOF_OF_DONE.md`

Purpose: provide standard artifact shapes for product, UI, QA, security, architecture, and completion evidence.

## Phase B — Skills

Committed in `0026684 protocol: add v4.7.0 senior specialist skills`.

Candidate skills:
- `design-system-governance`
- `visual-regression`
- `api-contract-validation`
- `infra-validation`
- `threat-modeling`

Purpose: add available-on-demand specialist guidance without creating new agents or changing routing.

## Phase C — Command wiring

Committed in `1aa0912 protocol: wire v4.7.0 specialist capabilities into commands`.

Command wiring added references to:
- Product and design templates in `/analyze` and `/plan-feature`.
- QA, threat model, ADR, and Proof of Done artifacts in planning and implementation flows.
- Risk-based visual, API, infra, threat, accessibility, and performance gates.
- Specialist artifact review in `/review`.
- Proof of Done, rollback, deploy, health, and owner-approval requirements in `/ship`.

Purpose: make the candidate capabilities discoverable in command docs while keeping enforcement trigger-based.

## Phase D1 — Role profiles

Committed in `386743a protocol: add v4.7.0 senior role profiles`.

Candidate role profiles:
- Product Manager
- UI/UX Designer
- Frontend Engineer
- Backend Engineer
- QA Engineer
- Security Reviewer
- Technical Architect
- DevOps Engineer

Purpose: define advisory senior-level quality bars. These profiles are not new agents, do not change model routing, and do not activate v4.7.0.

## Current active protocol

- Active production baseline: v4.6.1.
- `.opencode/brain-config.json` must remain `4.6.1` until Phase F.
- `NOW.md` must not describe v4.7.0 as active until Phase F.
- `.opencode/AGENTS.md` must not be promoted to v4.7.0 until Phase F.

## Activation blockers

v4.7.0 activation is pending:
1. Phase D2 audit and commit.
2. Phase E live validation pilot.
3. Phase F explicit promotion if the pilot passes.

## Explicitly deferred

- New specialist agents.
- Model routing changes.
- v5 architecture or owner/helper redesign.
- Product-code changes.
- Mandatory guard wiring for v4.7.0 candidate checks before activation.
- Vault version docs, snapshots, NOW, VERSIONS, and CHANGELOG promotion until activation is approved.

## Safety posture

The v4.7.0 candidate should improve discipline without overburdening small tasks. DIRECT/FAST tasks may use compact mode or N/A with reason and risk. STANDARD/HIGH-RISK work should provide artifacts and evidence proportional to risk.

## Phase F.0 activation-polish requirements

Before Phase F activation, candidate wording must preserve these Phase E findings:

- Compact/N/A paths stay available for DIRECT/FAST work; N/A always includes reason and risk.
- Visual regression stays risk-based: required for material visual changes or available baselines/references, advisory or `NOT_RUN` with reason/risk for tiny or baseline-free changes.
- API contract validation is boundary-triggered only: API routes, client fetchers, request/response/error shapes, auth/permission semantics, generated types, API docs, or API tests.
- Secret safety requires variable names only; never print, log, paste, or commit secret values, and do not stage `.env`, `.env.doppler`, credentials, or token-bearing files without explicit owner approval.
- Role profiles remain advisory standards for review quality and expected evidence; they are not agents, model-routing rules, or automatic delegation changes.
