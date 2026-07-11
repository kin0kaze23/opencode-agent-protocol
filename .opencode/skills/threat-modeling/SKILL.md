---
name: threat-modeling
description: Lightweight practical threat modeling for sensitive changes — assets, actors, trust boundaries, data flows, STRIDE risks, mitigations, residual risk, and owner acceptance. Active v4.7.0 specialist skill with trigger-based command wiring.
---

# Threat Modeling

Security reasoning before scanning. This skill complements `security/SKILL.md`; it does not replace code review, SAST, or secret scanning.

## Purpose

Help agents reason like security reviewers by identifying assets, actors, trust boundaries, data flows, mitigations, residual risk, and owner acceptance before relying on scanners.

## Read First

1. `<repo>/AGENTS.md`, `<repo>/NOW.md`, and active `<repo>/PLAN.md` if present
2. `.opencode/templates/THREAT_MODEL.md` and `.opencode/templates/PROOF_OF_DONE.md`
3. Relevant auth, permission, data-flow, API, payment, crypto, secret, webhook, or callback code/docs
4. Existing security notes, incident notes, or threat models if present

## When to Use

- Touch list includes auth, payments, crypto, secrets, permissions, user data, external callbacks/webhooks, multi-tenant/company boundaries, or trust-boundary crossings.
- HIGH-RISK lane has security, privacy, integrity, or abuse potential.
- Owner asks for threat model, abuse cases, trust boundaries, or security design review.

## When N/A Is Allowed

Use `N/A — <reason>; risk: <risk or none>` only when work does not touch sensitive data, trust boundaries, permissions, external callbacks, or security controls.

## When Not to Use

- Pure docs/UI copy with no data exposure or action semantics.
- As a replacement for `security/SKILL.md`, CodeQL, gitleaks, dependency checks, or runtime tests.
- Enterprise-heavy analysis where a lightweight model is enough; keep it practical.

## Secret Safety Rule

When the threat model touches credentials, env vars, tokens, or secret-bearing config, report variable names only. Never print, log, paste, store, or commit secret values. Do not stage `.env`, `.env.*`, `.env.doppler`, credentials, token-bearing files, or resolved secret output without explicit owner approval; stop on any secret-handling ambiguity.

## Procedure

1. Define scope: changed system, flows in scope, and explicit non-goals.
2. Identify assets: user data, credentials, permissions, funds, private content, availability, audit logs.
3. Identify actors: normal user, admin, service account, third-party service, anonymous attacker, malicious tenant.
4. Map trust boundaries: browser/server, server/database, service/service, tenant/company, webhook/external provider, local/cloud.
5. Map data flows across those boundaries; note sensitive data and write actions.
6. Apply STRIDE lightly: spoofing, tampering, repudiation, information disclosure, denial of service, elevation of privilege.
7. Define mitigations already present and mitigations required before ship.
8. List residual risks and whether owner acceptance is required.
9. Classify unresolved or skipped security gates using v4.6.1 labels: `TARGETED_FAILURE`, `BROAD_BASELINE_FAILURE`, `FLAKY_OR_INFRA_FAILURE`, `NOT_RUN`, `ACCEPTED_NON_BLOCKING`, or `BLOCKING_UNKNOWN`.

## Evidence Requirements

- Scope and non-goals
- Assets and actors list
- Trust boundary and data-flow table
- STRIDE risk table with mitigations
- Residual risks and owner approval status
- Links/paths to code or docs inspected

## Output Format

```markdown
## Threat Model Report

Scope: <system/change>
N/A status: <not N/A or reason+risk>

Assets: <list>
Actors: <list>
Trust boundaries: <list>

| Flow | Boundary | STRIDE risk | Mitigation | Residual risk |
|---|---|---|---|---|
| <flow> | <boundary> | <risk> | <mitigation> | <risk/none> |

Owner acceptance required: <yes/no — reason>
Owner approval: <pending/approved/not required>
Gate classification if non-pass/skipped: <v4.6.1 label>
Verdict: <PASS / NEEDS_FIX / ACCEPTED_RISK / NOT_RUN>
```

## Failure Conditions

- Trust boundary is touched but not identified.
- Sensitive asset or actor is omitted from a relevant flow.
- High or critical residual risk lacks mitigation or explicit owner acceptance.
- Permission/auth semantics are unclear; classify as `BLOCKING_UNKNOWN`.
- Security review is skipped without reason and risk.

## Related Templates

- Fill the working model in `.opencode/templates/THREAT_MODEL.md`.
- Record residual risks and owner approval in `.opencode/templates/PROOF_OF_DONE.md`.
