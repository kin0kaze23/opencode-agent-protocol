# Environment Contract — OpenCode Protocol

> **Version:** v4.27.2
> **Status:** Active
> **Purpose:** Define the four-layer environment precedence model and prevent config drift across global, workspace, repo, and session scopes.

## Four-Layer Environment Model

```
Global (machine-local)
  └── Workspace (multi-repo control plane)
        └── Repo (project-specific)
              └── Session/Task (current objective)
```

### Layer 1: Global

**Scope:** Machine-local runtime plumbing.
**Path:** `~/.config/opencode/`
**Purpose:** Provider auth, machine-local plugins, global model defaults.

| File | Purpose | Authority |
|---|---|---|
| `~/.config/opencode/opencode.json` | Provider config, auth references, plugin config | Machine-local only |
| `~/.config/opencode/prompts/*.md` | Installed runtime prompt mirrors | Generated from workspace |

**Rules:**
- Contains ONLY provider/auth/machine-local plumbing.
- Does NOT define: lanes, gates, token budgets, model routing, safety rules, commands, or skills.
- Global config may NOT override workspace behavioral policy.
- If global and workspace config disagree, workspace wins for behavioral policy.

### Layer 2: Workspace

**Scope:** Multi-repo control plane.
**Path:** `.opencode/` at workspace root.
**Purpose:** Protocol kernel, model routing, commands, scripts, conformance tests, skills, templates.

| File | Purpose | Authority |
|---|---|---|
| `.opencode/AGENTS.md` | Protocol kernel, lane selection, harness patterns | CANONICAL |
| `.opencode/rules.md` | OpenCode guardrails, token efficiency, provider fallback | CANONICAL |
| `.opencode/opencode.json` | Runtime config: agents, model routing, MCP policy, permissions | CANONICAL |
| `.opencode/brain-config.json` | Orchestration policy: routing, budgets, eval policy | CANONICAL |
| `.opencode/helper-roster.md` | Helper agent routing (reference-only, not startup-loaded) | REFERENCE |
| `.opencode/model-registry.yaml` | Model definitions and routing chains | REFERENCE |
| `.opencode/config/token-budget.yaml` | Lane-level token/reviewer/premium-model budgets | CANONICAL |
| `.opencode/commands/*.md` | Slash command definitions | CANONICAL |
| `.opencode/scripts/*.sh` | Protocol scripts | CANONICAL |
| `.opencode/conformance/tests/*.sh` | Conformance test suite | CANONICAL |
| `.opencode/skills/*/SKILL.md` | Skill library | REFERENCE |
| `.opencode/templates/*.md` | Document templates | REFERENCE |

**Rules:**
- Workspace defines behavioral policy for ALL repos in the workspace.
- Repo-level config may NOT override workspace lanes, gates, token budgets, model routing, or safety rules.
- Workspace is the self-contained behavioral runtime authority.

### Layer 3: Repo-Specific

**Scope:** Single project repo.
**Path:** `<repo>/` at repo root.
**Purpose:** Project stack, local commands, risks, deployment, tests.

| File | Purpose | Authority |
|---|---|---|
| `<repo>/AGENTS.md` | Repo-specific product truth, stack, deploy target | REPO-CANONICAL |
| `<repo>/NOW.md` | Current task status for this repo | REPO-CANONICAL |
| `<repo>/PLAN.md` | Active plan for current task | REPO-CANONICAL |
| `<repo>/CLAUDE.md` | Claude-specific repo overlay (optional) | REPO-CANONICAL |
| `<repo>/.opencode/` | Repo-local hooks, tools, approved MCP overlays (exception-only) | EXCEPTION |

**Rules:**
- Repo-specific overrides workspace ONLY for repo-local facts (stack, deploy target, test commands, known risks).
- Repo-specific may NOT define: lanes, gates, token budgets, model routing, or safety rules.
- Repo-level `.opencode/` is exception-only with documented ADR exceptions.
- If repo and workspace conflict on behavioral policy, workspace wins.

### Layer 4: Session/Task

**Scope:** Current agent session.
**Path:** In-memory only.
**Purpose:** Current objective, lane, touch list, changed files, verification state.

**Rules:**
- Session state NEVER mutates global, workspace, or repo config files.
- Session state is ephemeral and lost on session restart.
- Session state should be preserved via `/checkpoint` to NOW.md and vault before compaction.

## Precedence Rules

```
1. Current user instructions (highest)
2. Repo AGENTS.md / NOW.md / PLAN.md (repo-local facts only)
3. Workspace .opencode/AGENTS.md / rules.md (behavioral policy)
4. Global ~/.config/opencode/ (machine-local plumbing)
5. Session state (ephemeral, lowest)
```

**Key principle:**
- Global defines defaults.
- Workspace coordinates projects.
- Repo defines local truth.
- Session defines current task.

## What Each Layer May NOT Do

| Layer | May NOT |
|---|---|
| Global | Define lanes, gates, model routing, safety rules, commands, skills |
| Workspace | Override repo-specific stack/deploy/test facts |
| Repo | Define lanes, gates, token budgets, model routing, safety rules |
| Session | Mutate any config file (global, workspace, or repo) |

## Conflict Resolution

When two layers conflict:

1. **Behavioral policy conflict:** Workspace wins. Repo must conform.
2. **Repo-local fact conflict:** Repo wins. Workspace must respect.
3. **Runtime vs written policy:** Fail safe. Stop and surface the mismatch.
4. **Ambiguous authority:** Prefer the stricter live safety rule.

## Enforcement

- `config-authority-guard.sh` — enforces that repo-level config does not define workspace-level concerns.
- `repo-exception-guard.sh` — enforces that repo-level `.opencode/` is exception-only.
- `brain-config-coherence.sh` — enforces version and command surface coherence.
- `verify-environment.sh` — verifies environment consistency per layer.
