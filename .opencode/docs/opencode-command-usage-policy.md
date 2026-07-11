# OpenCode Command Usage Policy

> CANONICAL — Defines which OpenCode commands to use for reliable, consistent,
> production-grade daily use after OC-L.1/2A/2B migration.
>
> Last updated: 2026-05-22 (OC-L.2B)
> Associated tag: `oc-l.2b-checkpoint`

## Source-of-Truth Architecture

```
.opencode/agents/*.md                     = human-edited canonical source
.opencode/global-runtime/prompts/*.md     = generated mirror (GENERATED FILE header)
~/.config/opencode/prompts/*.md           = installed runtime (copy of mirror)
.opencode/global-runtime/prompts/orchestrator.md = canonical manual prompt (special case)
```

Do NOT edit generated or installed prompt files. Edit canonical agent specs, then run sync.

## Command Reference

| Command | Path | Purpose | Default? |
|---|---|---|---|
| `oc` | `.opencode/scripts/opencode-safe-launch.sh` | Normal daily OpenCode | **YES** |
| `oc-fresh` | same launcher with `--fresh` | After runtime changes, stale behavior | When needed |
| `oc-safe` | same launcher with `--server-only` | Only for server-flag debugging | No |
| `oc-clean` | `.opencode/scripts/oc-clean.sh` | Kill stuck opencode processes | When needed |
| `oc -v` | passthrough to native | Check version | As needed |
| `oc upgrade` | passthrough to native | Upgrade OpenCode | As needed |
| `oc help` | passthrough to native | Help | As needed |
| `ram-check` | `.opencode/scripts/ram-check.sh` | Check RAM usage | When needed |
| `ram-cleanup` | `.opencode/scripts/ram-cleanup.sh` | Free RAM | When needed |
| `ram-monitor` | `.opencode/scripts/ram-monitor.sh` | Monitor RAM over time | When needed |
| `dban` (db-clean) | `.opencode/scripts/opencode-db-clean.sh` | Clean OpenCode DB caches | When needed |

## 1. Default Daily Driver: `oc`

**Use `oc` for everything.** It is the single, canonical entrypoint.

Why:
- Points to `.opencode/scripts/opencode-safe-launch.sh` (not legacy `.agent/`)
- Runs standalone mode by default (safer — no auto-server restart)
- Detects stale runtime and warns you
- Has fast-path passthroughs for `-v`, `--version`, `version`, `help`, `--help`, `upgrade`

## 2. When to use `oc-fresh` instead of `oc`

Use `oc-fresh` after ANY of these change:
- `.opencode/agents/*.md` — agent prompt canonical specs edited
- `.opencode/brain-config.json` — models, routing, or roster changed
- `.opencode/scripts/*` — sync script or launcher changed
- `~/.config/opencode/*` — global runtime installed
- OpenCode version/runtime changed (`oc upgrade`)
- Agent behaves like it loaded stale instructions (e.g., references obsolete paths)
- You ran `sync-opencode-runtime.sh` manually

`oc-fresh` kills the existing server and starts a new one with the latest prompts.

## 3. When to use `oc-clean`

Use `oc-clean` when:
- Multiple opencode processes are running
- A session appears stuck or unresponsive
- Port 4000 listener won't release
- RAM usage from OpenCode is high
- You see stale-session artifacts (wrong agent, old prompt)

After `oc-clean`, launch with `oc-fresh` to start clean.

## 4. When to run `sync-opencode-runtime.sh` manually

Run `sync-opencode-runtime.sh` manually after editing:
- `.opencode/agents/*.md` (any canonical agent spec)
- `.opencode/brain-config.json` (model routing, roster changes)

The `oc` launcher auto-triggers sync when it detects local canonical files are newer
than the installed runtime, so manual sync is only needed if you want to:
- Verify the generation worked correctly
- Test a specific agent prompt change before launching OpenCode
- Prepare changes before a checkpoint/commit

```bash
bash .opencode/scripts/sync-opencode-runtime.sh
```

## 5. When to run conformance

Run the full conformance suite BEFORE committing any change to:
- Launcher scripts (`.opencode/scripts/opencode-safe-launch.sh`)
- Agent specs (`.opencode/agents/*.md`)
- Brain config (`.opencode/brain-config.json`)
- Sync script (`.opencode/scripts/sync-opencode-runtime.sh`)
- Generated prompts (`.opencode/global-runtime/prompts/*.md`)
- Any `.zshrc` alias change
- Any test file under `.opencode/conformance/`

```bash
bash .opencode/conformance/tests/global-opencode-runtime.sh
```

Expected result: **123 PASS, 0 FAIL** (or more as new tests are added).

## 6. Commands to avoid using directly

| Avoid | Reason | Use instead |
|---|---|---|
| `opencode` (bare) | Skips all preflight, drift detection, and runtime sync | `oc` |
| `~/.config/opencode/prompts/*` (manual edit) | Generated files — changes overwritten by sync | Edit `.opencode/agents/*.md` |
| `.opencode/global-runtime/prompts/explorer.md` etc. (manual edit) | Generated files — changes overwritten by sync | Edit `.opencode/agents/explorer.md` |
| Legacy root agent script shims, if present | Compatibility shims only — canonical implementations live under `.opencode/scripts/` | `.opencode/scripts/*.sh` |
| `npm start` / `pnpm dev` in workspace root | Not applicable — use repo-level project commands | Check `WORKSPACE_MAP.md` first |

## 7. What to do after changing specific files

### After `.opencode/agents/*.md` changes:
```bash
bash .opencode/scripts/sync-opencode-runtime.sh
bash .opencode/conformance/tests/global-opencode-runtime.sh
oc-fresh
```

### After `.opencode/brain-config.json` changes:
```bash
bash .opencode/scripts/sync-opencode-runtime.sh
bash .opencode/conformance/tests/global-opencode-runtime.sh
oc-fresh
```

### After `.opencode/scripts/*` changes:
```bash
bash .opencode/conformance/tests/global-opencode-runtime.sh
oc-fresh   # if launcher changed
```

### After `~/.zshrc` alias changes:
```bash
source ~/.zshrc
bash .opencode/conformance/tests/global-opencode-runtime.sh
```

### After `~/.config/opencode/prompts/*` (accidental edit):
```bash
bash .opencode/scripts/sync-opencode-runtime.sh  # restores from canonical
bash .opencode/conformance/tests/global-opencode-runtime.sh
```

## 8. Decision Tree

### Normal coding session
```
oc
```
That's it. The launcher checks for stale runtime, warns if needed, and launches.

### After protocol/runtime changes
```
1. bash .opencode/scripts/sync-opencode-runtime.sh
2. bash .opencode/conformance/tests/global-opencode-runtime.sh
3. oc-fresh
```

### After agent prompt changes
```
1. bash .opencode/scripts/sync-opencode-runtime.sh
2. bash .opencode/conformance/tests/global-opencode-runtime.sh
3. oc-fresh
```

### After OpenCode upgrade
```
1. oc upgrade
2. oc-fresh
```

### After weird behavior / stale agent behavior
```
1. oc-clean
2. bash .opencode/scripts/sync-opencode-runtime.sh
3. bash .opencode/conformance/tests/global-opencode-runtime.sh
4. oc-fresh
```

### After memory / process issues
```
1. ram-check          # diagnose
2. ram-cleanup        # free memory (optional)
3. oc-clean           # kill stuck processes
4. oc-fresh           # clean restart
```
