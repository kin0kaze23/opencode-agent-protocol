---
name: infra-validation
description: DevOps/infra validation for Docker, deploy config, CI, env/secrets, runtime configuration, healthchecks, and rollback readiness. Active v4.7.0 specialist skill with trigger-based command wiring.
---

# Infra Validation

Validate deployment and runtime risk without installing expensive tools or printing secrets.

## Purpose

Help agents behave like senior DevOps/infra engineers by checking deployment, runtime, env/secrets, health, and rollback risk before ship.

## Read First

1. `<repo>/AGENTS.md`, `<repo>/NOW.md`, and active `<repo>/PLAN.md` if present
2. `.opencode/templates/QA_PLAN.md` and `.opencode/templates/PROOF_OF_DONE.md`
3. `WORKSPACE_MAP.md` deploy target and port information
4. Repo deploy/runtime files: Dockerfile, compose files, Vercel/Railway/Cloudflare config, CI workflows, env examples, healthcheck routes
5. Existing deployment/rollback docs when present

## When to Use

- Touch list includes Docker, compose, CI/CD, deploy config, env examples, secrets references, worker/runtime config, healthcheck, ports, process manager, or infrastructure docs.
- Shipping or reviewing deployment-sensitive changes.
- A runtime or environment variable assumption changes.

## When Not to Use

- Pure UI/backend logic with no deployment/runtime/env impact.
- Local-only docs changes unrelated to runtime.
- Expensive scanners or installs are required; report advisory `NOT_RUN` unless owner approves. Do not install or run heavy tools by default.
- Use `N/A — <reason>; risk: <risk or none>` when no Docker, deploy, CI, env/secrets, runtime config, healthcheck, or rollback surface is affected.

## Secret Safety Rule

Report variable **names only**. Never print, log, paste, copy into chat/docs, store, or commit secret values. Redact any encountered value as `<redacted>` without preserving the value. Do not stage `.env`, `.env.*`, `.env.doppler`, credentials, token-bearing config, or resolved secret output unless the owner explicitly reviews and approves that exact file. If secret-handling scope is ambiguous, stop for owner approval before continuing.

## Procedure

1. Identify infra files and runtime surfaces touched.
2. Confirm deploy target from repo truth and `WORKSPACE_MAP.md`.
3. Check Docker/container config when present: base image, build command, exposed ports, non-root user, healthcheck, volumes, secrets handling.
4. Check deploy config: project name, build/output commands, rewrites/routes, worker bindings, runtime compatibility.
5. Check CI/CD: required gates, branch protections, deploy workflow triggers, cache assumptions.
6. Check env/secrets: required variable names, `.env.example` coverage, no secret values printed/logged/pasted/committed, and no `.env`, `.env.doppler`, credentials, or token-bearing files staged.
7. Check health and rollback: health endpoint/smoke test, rollback command/operator action, verification step.
8. Mark expensive or unavailable checks as advisory or `NOT_RUN` with reason and risk; do not install tools by default.
9. Classify non-pass outcomes with v4.6.1 labels: `TARGETED_FAILURE`, `BROAD_BASELINE_FAILURE`, `FLAKY_OR_INFRA_FAILURE`, `NOT_RUN`, `ACCEPTED_NON_BLOCKING`, or `BLOCKING_UNKNOWN`.

## Required vs Advisory Checks

- **Required:** touched deploy/runtime/env config, rollback note, secret-name safety, health/smoke plan.
- **Advisory:** Docker hardening beyond touched files, external platform inspection, heavy SAST/container scanners.

## Evidence Requirements

- Infra files inspected
- Deploy target and runtime command summary
- Env variable names checked, values never printed, and secret-bearing files confirmed unstaged or explicitly owner-approved
- CI/gate coverage summary
- Healthcheck and rollback evidence or `N/A` reason

## Output Format

```markdown
## Infra Validation Report

Deploy target: <target or N/A>
Runtime surfaces: <files/configs>

| Check | Result | Evidence | Classification if non-pass |
|---|---|---|---|
| Docker/container | <PASS/FAIL/N/A> | <paths/notes> | <v4.6.1 label or N/A> |
| Deploy config | <PASS/FAIL/N/A> | <paths/notes> | <label or N/A> |
| CI/CD gates | <PASS/FAIL/N/A> | <paths/notes> | <label or N/A> |
| Env/secrets | <PASS/FAIL/N/A> | <names only> | <label or N/A> |
| Healthcheck | <PASS/FAIL/N/A> | <command/route> | <label or N/A> |
| Rollback | <PASS/FAIL/N/A> | <plan> | <label or N/A> |

Verdict: <PASS / NEEDS_FIX / NOT_RUN / ACCEPTED_EXCEPTION>
```

## Failure Conditions

- Secret value is exposed, staged, or printed.
- Deploy/runtime config is changed without rollback or health verification plan.
- Required env variable names are undocumented or inconsistent.
- CI/deploy gates are bypassed for product-code shipping.
- Required infra evidence is missing; classify as `BLOCKING_UNKNOWN`.

## Related Templates

- Verification plan belongs in `.opencode/templates/QA_PLAN.md`.
- Final evidence, dirty inventory, and rollback belong in `.opencode/templates/PROOF_OF_DONE.md`.
