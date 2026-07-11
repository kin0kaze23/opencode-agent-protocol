# Repo Protocol Baseline — Template for New Repos

> **Purpose:** Starting point for a new repo's `AGENTS.md`. Copy this file, then customize for the specific project.
> **Usage:** `cp .opencode/templates/REPO_PROTOCOL_BASELINE.md <repo>/AGENTS.md`

---

# AGENTS.md — <Repo Name>

> Repo-specific product truth for `<repo>`.
> Workspace protocol authority lives in `.opencode/AGENTS.md` and `.opencode/rules.md`.

## Project Identity

**Name:** <Repo Name>
**Stack:** <e.g., Next.js 14 + TypeScript + Prisma + PostgreSQL>
**Deploy target:** <e.g., Vercel / Self-hosted Docker / Local app / None>
**Local dev port:** <e.g., 3001>
**Canonical path:** `$WORKSPACE_ROOT/<repo>`

## What the Agent Should Read First

1. This file (`<repo>/AGENTS.md`)
2. `<repo>/NOW.md` — current task status
3. `<repo>/PLAN.md` — if it exists, the active plan
4. `.opencode/AGENTS.md` — workspace protocol (lanes, gates, harness patterns)
5. `.opencode/rules.md` — workspace guardrails

## Stack Details

<Describe the tech stack, key dependencies, and architecture.>

## Test Commands

```bash
# Lint
<lint command>

# Typecheck
<typecheck command>

# Unit tests
<test command>

# Build
<build command>

# Dev server
<dev server command>
```

## Deployment

<Describe deployment process, environment variables needed, and rollback procedure.>

## Known Risks

<List any known risks, sensitive paths, or gotchas specific to this repo.>

## Local Overrides

<List any repo-specific overrides that differ from workspace defaults.>
<Do NOT define lanes, gates, token budgets, model routing, or safety rules here.>

## Contract Files

| File | Purpose |
|---|---|
| `NOW.md` | Current task status |
| `PLAN.md` | Active plan (required for STANDARD/HIGH-RISK) |
| `PROJECT_MEMORY.md` | Project memory (optional, created by `/checkpoint`) |
