# OpenCode Role Profiles

Advisory senior-specialist standards for the v4.7.0 active baseline.

These profiles define what senior-level work means across the development lifecycle. They are advisory standards, not new agents, do not change model routing, and do not imply automatic delegation. v4.7.0 is active, but these profiles remain quality bars and evidence standards only.

Commands may reference these standards in v4.7.0 for review, planning, and training consistency without delegating work automatically.

## Profiles

| Role | Profile | Primary focus |
|---|---|---|
| Product Manager | `product-manager.md` | Product clarity, success criteria, non-goals, kill criteria |
| UI/UX Designer | `ui-ux-designer.md` | Visual hierarchy, interaction quality, accessibility, design-system fit |
| Frontend Engineer | `frontend-engineer.md` | Maintainable UI implementation, state coverage, browser evidence |
| Backend Engineer | `backend-engineer.md` | API contracts, consistency, auth semantics, migrations, observability |
| QA Engineer | `qa-engineer.md` | Risk-based verification, edge/error paths, regression confidence |
| Security Reviewer | `security-reviewer.md` | Threat modeling, trust boundaries, secrets, permissions, residual risk |
| Technical Architect | `technical-architect.md` | ADRs, tradeoffs, reversibility, system boundaries, cross-surface impact |
| DevOps Engineer | `devops-engineer.md` | Runtime validation, CI/CD, deploy/rollback/health, blast radius |

## Usage rules

- Treat profiles as quality bars, not autonomous roles.
- Do not add specialist agents or change helper routing because a profile exists.
- Do not treat a profile as an automatic delegation rule; profiles improve review quality and expected evidence only.
- Use the smallest applicable set of profiles based on task risk and trigger.
- Small DIRECT/FAST tasks may use compact mode or mark a profile `N/A with reason and risk`.
- STANDARD/HIGH-RISK work should cite the relevant profile evidence in the plan, review, gates, or Proof of Done when applicable.
- v4.6.1 gate classifications remain the active result language: `TARGETED_FAILURE`, `BROAD_BASELINE_FAILURE`, `FLAKY_OR_INFRA_FAILURE`, `NOT_RUN`, `ACCEPTED_NON_BLOCKING`, and `BLOCKING_UNKNOWN`.

## Handoff expectation

Each profile should leave enough evidence for the next lifecycle stage to continue without inventing missing decisions. If a required artifact is missing, the correct action is to mark the task blocked, ask a focused question, or return to the appropriate planning stage.
