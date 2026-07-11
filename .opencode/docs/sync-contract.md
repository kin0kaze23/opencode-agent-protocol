# Sync Contract — How Protocol Layers Stay Aligned

> **Version:** v4.27.2
> **Status:** Active
> **Purpose:** Define how each environment layer is updated and how to prevent drift.

## Update Procedures

### Global Protocol Updates

**When:** Global provider config, auth, or machine-local plugins change.

**Procedure:**
1. Edit `~/.config/opencode/opencode.json` (provider/auth only).
2. Do NOT add behavioral policy (lanes, gates, model routing) to global config.
3. If runtime prompts need updating, run `bash .opencode/scripts/sync-opencode-runtime.sh` from the workspace root to regenerate `~/.config/opencode/prompts/*.md` from `.opencode/agents/*.md`.
4. Restart OpenCode after config changes.

**What NOT to do:**
- Do NOT copy workspace config to global.
- Do NOT define model routing in global config.
- Do NOT add commands or skills to global config.

### Workspace Protocol Updates

**When:** Protocol version changes, new commands/scripts/tests added, model routing updated.

**Procedure:**
1. Make changes in `.opencode/` directory.
2. Update `brain-config.json` version field (single source of truth).
3. If commands added/removed: update `brain-config.json` `command_surface.commands` array.
4. If model routing changed: update `model-registry.yaml` and `helper-roster.md`.
5. Run `bash .opencode/scripts/sync-opencode-runtime.sh` to regenerate global runtime mirrors.
6. Run `bash .opencode/scripts/workspace-protocol-guard.sh` to verify coherence.
7. Run conformance tests.
8. Commit with conventional message.
9. Restart OpenCode.

**Version sync rule:** The version in `brain-config.json` is the single source of truth. All other files (AGENTS.md, rules.md, NOW.md, vault NOW.md) must reference this version. Conformance tests read the version dynamically from brain-config.json.

### Repo-Specific Updates

**When:** Repo stack changes, deploy target changes, new risks identified.

**Procedure:**
1. Edit `<repo>/AGENTS.md` (repo-local facts only).
2. Edit `<repo>/NOW.md` if task status changed.
3. Do NOT add workspace-level concerns (lanes, gates, model routing) to repo config.
4. If repo needs a local `.opencode/` directory, document the exception in an ADR.

**What NOT to do:**
- Do NOT copy workspace `.opencode/` files to repo-level `.opencode/`.
- Do NOT define model routing, lanes, or gates in repo config.
- Do NOT override workspace safety rules in repo config.

### PROJECT_MEMORY.md Updates

**When:** After `/checkpoint` for STANDARD/HIGH-RISK tasks.

**Procedure:**
1. `/checkpoint` creates or updates `<repo>/PROJECT_MEMORY.md`.
2. Memory is repo-specific and does NOT propagate to other repos.
3. Cross-project patterns are retrieved via `search-patterns.sh --cross-project`.
4. PROJECT_MEMORY.md is committed to the repo, not to the workspace.

## Drift Prevention Rules

### What Should Never Be Copied Blindly

| Source | Target | Rule |
|---|---|---|
| Workspace `.opencode/AGENTS.md` | Repo `AGENTS.md` | NEVER copy. Repo AGENTS.md is repo-specific. |
| Workspace `.opencode/opencode.json` | Global `opencode.json` | NEVER copy. Global is provider/auth only. |
| Repo `AGENTS.md` | Another repo's `AGENTS.md` | NEVER copy. Each repo has its own truth. |
| Global `prompts/*.md` | Workspace `.opencode/agents/*.md` | NEVER copy. Prompts are generated from agents, not vice versa. |

### How to Bootstrap a New Repo

1. Create `<repo>/AGENTS.md` using `.opencode/templates/REPO_PROTOCOL_BASELINE.md` as a starting point.
2. Create `<repo>/NOW.md` with initial status.
3. Add the repo to `.opencode/registry.yaml` and `WORKSPACE_MAP.md`.
4. Run `bash .opencode/scripts/verify-environment.sh --mode repo <repo-path>` to verify.
5. Run `bash .opencode/scripts/bootstrap-repo-profile.sh` to generate a repo profile.
6. Commit the repo's `AGENTS.md` and `NOW.md`.

### How to Detect Drift

```bash
# Full environment verification
bash .opencode/scripts/verify-environment.sh --mode workspace

# Repo-specific verification
bash .opencode/scripts/verify-environment.sh --mode repo <repo-path>

# Workspace protocol guard (includes brain-config coherence)
bash .opencode/scripts/workspace-protocol-guard.sh

# Brain-config coherence check
bash .opencode/scripts/brain-config-coherence.sh
```

### Sync Frequency

| Layer | Sync Trigger |
|---|---|
| Global prompts | After workspace agent prompt changes (`sync-opencode-runtime.sh`) |
| Workspace version | After any protocol version change |
| Command surface | After adding/removing commands |
| Model routing | After model registry changes |
| Repo AGENTS.md | After repo stack/deploy changes |
| PROJECT_MEMORY.md | After `/checkpoint` for STANDARD/HIGH-RISK |
