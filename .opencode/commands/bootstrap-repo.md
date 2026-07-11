---
description: "Initialize a new repo with protocol state files and GitGuard hook"
---

# /bootstrap-repo

**Purpose:** Initialize a new or freshly-cloned repo with all workspace protocol artifacts
**Mode:** Executor
**Model:** qwen3.7-plus (v1.1-production, Action 4D)
**Tool access:** Layer A (shell, file ops, git)

## Behaviour

When invoked for a new repo, the Owner agent:

1. **Detects repo type** (v4.17.0):
   - Check for `package.json` with `vite` → `react_vite`
   - Check for `package.json` with `next` → `nextjs`
   - Check for `package.json` with `express`/`hono`/`fastify` → `node_backend`
   - Check for `requirements.txt` or `pyproject.toml` → `python`
   - Check for `Cargo.toml` → `rust`
   - Check for only `.md` files → `docs_only`
   - Otherwise → `unknown`
   - Reads `.opencode/config/repo-profiles.yaml` for the matching profile

2. **Creates protocol state files:**
   - `NOW.md` — initial state (status: paused, no active task)
   - `AGENTS.md` — repo-specific agent instructions (template from `.opencode/templates/`)

3. **Assigns default profile** (v4.17.0):
   - Reads the detected repo type from step 1
   - Assigns default lane, verification profile, and gate commands from `repo-profiles.yaml`
   - Writes detected profile to `NOW.md` under `## Repo Profile`

4. **Installs GitGuard pre-push hook:**
   - Runs `.opencode/git-guard/install-hook.sh <repo-name>`
   - Verifies hook is executable and matches canonical source

5. **Sets up repo structure (if not already present):**
   - `docs/` directory for planning artifacts
   - `vault/projects/<repo>/` directory for memory files

6. **Verifies authority hierarchy** (v4.17.0):
   - Confirms global config is thin (no behavioral keys)
   - Confirms workspace policy is canonical
   - Confirms repo overlay does not duplicate workspace authority
   - Runs `bash .opencode/conformance/tests/config-authority-guard.sh`
   - Runs `bash .opencode/conformance/tests/repo-exception-guard.sh`

7. **Registers repo in workspace registry:**
   - Updates `.opencode/registry.yaml` with repo name, path, type, and profile
   - Updates `WORKSPACE_MAP.md` with repo entry

8. **Commits protocol files:**
   - `git add NOW.md AGENTS.md`
   - `git commit -m "Protocol: bootstrap <repo-name> (<repo-type>)"`

9. **Outputs bootstrap summary:**
   - Repo type detected
   - Profile assigned (lane, verification profile, gate commands)
   - Authority verification results
   - Registry registration confirmed

## GitGuard Hook Installation

The canonical hook source lives at:
- `.opencode/git-guard/pre-push-hook.sh` (workspace root)

Installation is handled by:
- `.opencode/git-guard/install-hook.sh <repo-name>` (idempotent)

The hook blocks:
- Direct push to `main` or `master` branches
- Provides safer alternatives (feature branch + PR)

## When to Run

- After cloning a new repo into the workspace
- After initializing a new repo with `git init`
- When a repo's `.git` directory is recreated

## Do Not

- Skip hook installation — it is mandatory for all repos with `.git` directories
- Modify the canonical hook source directly — edit `.opencode/git-guard/pre-push-hook.sh` and run repair
- Install hooks manually with `cp` — always use the install script for consistency
