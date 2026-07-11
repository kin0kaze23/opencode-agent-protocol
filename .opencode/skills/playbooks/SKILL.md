---
description: "Pre-built workflows for recurring tasks including deploys, hotfixes, features, and refactors"
---

# Session Templates / Playbooks

> **Version:** 1.0
> **Scope:** Pre-built workflows for recurring tasks to reduce cognitive load and speed up common patterns
> **Location:** `.opencode/playbooks/`

## Procedure

Before running a playbook, read the following:

1. Read the target repo's `AGENTS.md` to confirm stack, ports, and deployment target
2. Read `WORKSPACE_MAP.md` to confirm the repo exists on disk and its dev port
3. Read the repo's `package.json` or equivalent to confirm available scripts
4. Read any existing playbook history in `vault/projects/<repo>/progress.md`

Then select the appropriate playbook below and execute its steps in order.

## When to Activate

Task matches a playbook name or user invokes `/playbook <name>`.

## Available Playbooks

### 1. `deploy` — End-to-End Deployment

**Trigger:** "deploy", "ship to production", "go live"

**Steps:**
1. Run preflight (confirm repo, branch, environment)
2. Run `/gates` (lint → typecheck → test → build)
3. If gates fail: stop and report
4. If gates pass: run `/ship` (create PR or merge)
5. After merge: run `/deploy-vercel --prod` or `/deploy-workers`
6. Run smoke test on deployment URL
7. If smoke test fails: run `/deploy-rollback --auto`
8. Report deployment URL, status, health check result

**Success criteria:** Deployment live, smoke test passes, rollback plan documented.

---

### 2. `hotfix` — Emergency Fix

**Trigger:** "hotfix", "emergency fix", "production bug", "critical bug"

**Steps:**
1. Create hotfix branch: `hotfix/<repo>/<task-slug>`
2. Reproduce the issue (read error, locate failing test or log)
3. Apply minimal fix
4. Run `/gates` with `hotfix` verification profile
5. Run `/ship` with hotfix branch (direct merge allowed)
6. Deploy to production
7. Verify fix in production
8. Document root cause and fix

**Success criteria:** Issue resolved, fix deployed, root cause documented.

---

### 3. `feature` — New Feature Development

**Trigger:** "add feature", "new feature", "implement"

**Steps:**
1. Run `/plan-feature` with scope clarification
2. Wait for user approval
3. Run `/implement` with approved plan
4. Run `/gates` per verification profile
5. Run `/review` if required (risk 4+, 4+ files, sensitive paths)
6. Run `/ship` (create PR)
7. Wait for merge
8. Run `/deploy-preview` or `/deploy-vercel --prod`
9. Run smoke tests
10. Run `/checkpoint` to update NOW.md

**Success criteria:** Feature implemented, tested, reviewed, deployed, checkpointed.

---

### 4. `refactor` — Code Refactoring

**Trigger:** "refactor", "clean up", "technical debt", "simplify"

**Steps:**
1. Identify refactoring scope (read relevant files)
2. Run `/plan-feature` with refactoring plan
3. Activate `technical-debt-prevention/SKILL.md`
4. Run `/implement` with behavior-preserving changes
5. Run `/gates` (must pass — refactoring should not break anything)
6. Run `/review` to verify no behavior changes
7. Run `/ship` and deploy
8. Verify no regressions

**Success criteria:** Code improved, no behavior changes, all gates pass.

---

### 5. `bugfix` — Bug Investigation and Fix

**Trigger:** "bug", "broken", "failing", "crash", "error"

**Steps:**
1. Run `/debug` to identify root cause
2. Reproduce the failure
3. Form hypotheses and test them
4. Apply minimal fix
5. Run `/gates` to verify fix and check for regressions
6. Run `/ship` and deploy
7. Verify fix in production

**Success criteria:** Bug fixed, root cause identified, no regressions.

---

### 6. `migrate` — Database Migration

**Trigger:** "migration", "schema change", "prisma migrate", "drizzle migrate"

**Steps:**
1. Activate `database/SKILL.md`
2. Read current schema and migration history
3. Create migration files
4. Run migration in development: `prisma migrate dev` or `drizzle-kit generate`
5. Test migration (up and down)
6. Run `/gates` (typecheck is critical here)
7. Run `/ship` with migration notes
8. Deploy to staging first
9. Verify staging migration
10. Deploy to production
11. Verify production migration
12. Document migration in changelog

**Success criteria:** Migration applied, no data loss, rollback tested.

---

## Playbook Invocation

### Explicit Invocation
```
/playbook deploy
/playbook hotfix
/playbook feature
/playbook refactor
/playbook bugfix
/playbook migrate
```

### Automatic Invocation
Agent detects task matches playbook pattern and suggests:
```
This matches the 'deploy' playbook. Proceed with automated deployment flow?
Reply 'yes' to proceed, 'no' to customize, or edit the steps.
```

## Customization

Users can customize playbooks by:
1. Creating `.opencode/playbooks/custom-<name>.md`
2. Overriding specific steps
3. Adding repo-specific steps

## Do Not

- Skip required steps in a playbook without user approval
- Run playbooks that require deployment without confirming environment
- Run `migrate` playbook without testing rollback first
- Run `hotfix` playbook without documenting root cause
- Run `feature` playbook without user approval on the plan

## Output format

Produce a playbook execution report in this exact format:

```
## Playbook Execution — <playbook name>

**Repo:** <repo name>
**Risk:** <Low / Medium / High>

### Steps completed
1. ✅ <step 1>
2. ✅ <step 2>
3. <step 3 status>

### Gate results
- lint: <PASS/FAIL>
- typecheck: <PASS/FAIL>
- test: <PASS/FAIL>
- build: <PASS/FAIL>

### Deployment
- URL: <URL or "N/A">
- Status: <HTTP status or "N/A">

### Verdict: COMPLETE / PARTIAL / FAILED
```

## Out of Scope

This skill does NOT:
- Replace `/plan-feature` for complex or ambiguous work (playbooks assume clear scope)
- Fix bugs that require architectural changes (that is /plan-feature)
- Deploy without passing quality gates (always run gates first)
- Replace emergency rollback procedures (that is /deploy-rollback)
- Execute playbooks on repos not listed in `WORKSPACE_MAP.md`
- Skip user approval gates defined in the protocol
- Create custom playbooks without user approval (use customization section above)
