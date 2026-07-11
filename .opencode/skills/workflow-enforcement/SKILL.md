---
name: workflow-enforcement
description: Enforces development workflow standards from the dev-playbook — PRD before implementation, staging before production, task briefs, PM handshake, evidence labels, and UI revamp workflow.
---

# Workflow Enforcement Skill

Enforces the development workflow standards defined in `dev-playbook/`. This skill bridges the gap between documented standards and actual agent behavior.

## When to Use

- User mentions "PRD", "product requirements", "task brief", "spec"
- Planning a feature that affects staging or production
- User asks about deployment workflow, release process, or environment promotion
- UI/UX revamp work (distinct from minor polish)
- Any task that involves PM/engineering coordination
- Before any production deployment

## Core Enforcement Rules

### Rule 1: PRD Before Implementation

For new features or significant changes, a PRD (Product Requirements Document) must exist before `/implement` begins.

**PRD must include:**
- User problem being solved
- Target user
- Success metric
- Non-goals
- Acceptance criteria
- Urgency/priority

**If no PRD exists:**
1. Create a minimal PRD stub at `docs/PRD.md` or `<repo>/PRD.md`
2. Fill in the 6 required fields
3. Get user confirmation before proceeding to implementation

**Exception:** Bug fixes, hotfixes, and minor polish do not require a PRD.

### Rule 2: Staging Before Production

For any deployed project, staging (or preview for Vercel) must be verified before production deployment.

**Enforcement:**
- If the repo has a staging environment: verify staging health before `/deploy-vercel` or `/deploy-workers`
- If the repo uses Vercel preview URLs: verify preview URL before production merge
- If the repo has no staging/preview: flag this as a RISK in the completion summary

**Never deploy to production without:**
1. Staging/preview verification evidence
2. Passing quality gates
3. Explicit user approval for production

### Rule 3: Task Brief Before Planning

For non-trivial tasks, produce a task brief before `/plan-feature`:

```
Task Brief:
- Objective: <one sentence>
- Type: Bug Fix / New Feature / Refactor / UI Polish / UI Revamp / Performance / Security / Infra
- Scope in: <what's included>
- Scope out: <what's explicitly excluded>
- Risk level: Low / Medium / High
- Environments affected: local / preview / staging / production
```

### Rule 4: PM + Engineering Handshake

For new features, both sides must define their part:

**PM defines:**
- User problem
- Target user
- Success metric
- Non-goals
- Acceptance criteria
- Priority

**Engineering defines:**
- Technical approach
- Touch points (files/systems)
- Risks
- Constraints
- Test plan
- Rollout plan

**Shared definition of done:**
- Scope implemented
- Tests/checks pass
- UI/UX validated (if applicable)
- Docs/config updated
- Rollback understood
- Deployment path clear

### Rule 5: Evidence Labels

Every verification claim must use evidence labels:

| Label | Meaning | When to Use |
|---|---|---|
| `VERIFIED` | Actually tested and confirmed | Ran the test, saw the result |
| `INFERRED` | Likely true but not directly tested | Reasonable assumption based on evidence |
| `NOT TESTED` | Not verified yet | Explicitly calling out a gap |
| `RISK` | Known uncertainty or danger | Something that could go wrong |

**Examples:**
- `VERIFIED`: local build passes, login form renders in staging
- `INFERRED`: production should behave the same because config is aligned
- `NOT TESTED`: migration rollback not tested yet
- `RISK`: third-party API rate limit may affect this flow

### Rule 6: UI Revamp Workflow

UI revamps (distinct from minor polish) require stricter rules:

**Before starting:**
- Preserve user-critical flows first
- Define interaction states before styling polish
- Keep route behavior stable unless intentionally changed

**During:**
- Do not mix visual revamp with deep logic rewrites
- Verify desktop + tablet + mobile
- Verify loading, empty, error, disabled, success states
- Keep accessibility in scope

**Checklist:**
- [ ] Visual hierarchy improved
- [ ] Spacing and alignment consistent
- [ ] Typography scale consistent
- [ ] Buttons and form controls consistent
- [ ] Dark/light handling considered
- [ ] Keyboard/focus states considered
- [ ] Skeleton/loading states present
- [ ] Error messages clear
- [ ] No layout jumps on async load
- [ ] Major flows tested end to end

## Environment Tier Awareness

Before any deployment-related work, identify the repo's deployment profile:

| Profile | Environments | When |
|---|---|---|
| **A — Vercel/Cloud** | local → preview → production | Web apps deployed to Vercel |
| **B — Self-Hosted** | local → staging → production | Docker services, control planes |
| **C — Local-First** | local only | Internal tools, no deployment |
| **D — Desktop** | local → release channel | Native apps (macOS, etc.) |

**How to determine:** Check `<repo>/AGENTS.md` deploy target, or `dev-playbook/PORTFOLIO_DEPLOYMENT_MATRIX.md`.

## Integration with Protocol Commands

| Command | Workflow Enforcement |
|---|---|
| `/plan-feature` | Check if PRD exists for new features; produce task brief |
| `/implement` | Apply evidence labels to all verification claims |
| `/review` | Check UI revamp checklist if applicable |
| `/ship` | Verify staging/preview before production |
| `/deploy-vercel` | Confirm staging/preview verification evidence |
| `/deploy-workers` | Confirm staging/preview verification evidence |
