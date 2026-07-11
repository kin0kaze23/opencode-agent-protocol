# New Repo Bootstrap Guide

> **How to add a new project repo to the workspace.**

## Step 1: Create the Repo

```bash
# Create the repo on GitHub, then clone it
git clone https://github.com/kin0kaze23/<new-repo>.git <new-repo>
cd <new-repo>
```

## Step 2: Create AGENTS.md

Use the template as a starting point:

```bash
cp ../.opencode/templates/REPO_PROTOCOL_BASELINE.md AGENTS.md
```

Customize it with:
- Project name and purpose
- Tech stack
- Test commands
- Deploy target
- Known risks
- What not to touch casually

**Do NOT include:** Lanes, gates, token budgets, model routing, or safety rules. Those are workspace-level.

## Step 3: Create NOW.md

```bash
cat > NOW.md << 'EOF'
---
status: active
task: Initial setup
lane: FAST
objective: Set up project structure and initial code
blockers: []
last_decision: Initial repo creation
next_step: Start first feature
rollback: n/a
updated: <today's date>
---

# Current State — <Repo Name>

**Status:** active
EOF
```

## Step 4: Create PROJECT_MEMORY.md

```bash
cat > PROJECT_MEMORY.md << 'EOF'
# Project Memory — <Repo Name>

> Auto-maintained by /checkpoint. Read this first for project context.
> Last updated: <today's date>

## Purpose
<One sentence describing what this project does>

## Stack
<Tech stack details>

## Architecture Notes
<Key directories and design decisions>

## Key Decisions
- <date>: Initial setup

## Known Risks
<Repo-specific risks>

## Testing Commands
- lint: <command>
- typecheck: <command>
- test: <command>
- build: <command>
- dev: <command>

## What the Agent Should Read First
1. `<repo>/AGENTS.md`
2. `<repo>/NOW.md`
3. This file

## What Not to Touch Casually
<Repo-specific dangerous areas>
EOF
```

## Step 5: Register in Workspace

Add the repo to:
1. `.opencode/registry.yaml` — under `repositories:`
2. `WORKSPACE_MAP.md` — in the repo table

## Step 6: Verify

```bash
bash .opencode/scripts/verify-environment.sh --mode repo <new-repo>
```

Expected: 6 PASS, 0 FAIL, 0-1 WARN.

## Step 7: Commit

```bash
git add AGENTS.md NOW.md PROJECT_MEMORY.md
git commit -m "docs: initial repo setup with AGENTS.md, NOW.md, PROJECT_MEMORY.md"
```

## What NOT to Do

- Do NOT copy workspace `.opencode/` files to the repo
- Do NOT define lanes, gates, or model routing in repo AGENTS.md
- Do NOT override workspace safety rules
- Do NOT create a repo-level `.opencode/` directory unless you have an approved ADR exception
