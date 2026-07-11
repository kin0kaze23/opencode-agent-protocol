# MCP Runtime Verification Runbook

> **Version:** 1.0.0 — 2026-07-01
> **Purpose:** Document how to correctly verify MCP server availability at runtime, including the OpenCode server caching behavior that makes `opencode mcp list` misleading when run from different directories.

## The Problem

`opencode mcp list` and `opencode debug config` connect to the **running OpenCode server**, which caches MCP configuration at startup from the directory it was launched from. They do **NOT** reflect per-directory config resolution.

This means:
- If you start OpenCode from the workspace root, `opencode mcp list` shows the workspace root's MCP config (playwright disabled, no pencil) — even if you `cd` into protected-repo-prod and run the command from there.
- If you start OpenCode from protected-repo-prod, `opencode mcp list` shows protected-repo-prod's resolved MCP config (playwright enabled, pencil enabled) — even if you `cd` to the workspace root.

## Correct Runtime Verification

To verify MCP availability for a specific repo at runtime:

```bash
# 1. Stop any running OpenCode server
#    (If you're in an OpenCode session, exit it first)
#    On macOS, you can also kill the server process:
#    pkill -f "opencode" 

# 2. Start OpenCode from the target repo directory
cd /path/to/target-repo
opencode

# 3. In the OpenCode session, run:
opencode mcp list

# 4. Verify the expected MCPs are connected:
#    - context7: connected
#    - exa: connected
#    - sequential-thinking: connected
#    - github: connected
#    - playwright: connected (for ui_ux repos)
#    - pencil: connected (for ui_ux repos)
#    - web-tools: deprecated (removed 2026-07-01)
#    - firecrawl: disabled
```

## Config File Verification (Authoritative)

Config file verification is the authoritative check for per-directory config resolution. It does not require restarting OpenCode:

```bash
# Check workspace root config
python3 -c "
import json
with open('.opencode/opencode.json') as f:
    mcp = json.load(f).get('mcp', {})
    for name, cfg in sorted(mcp.items()):
        print(f'  {name:20s} enabled={cfg.get(\"enabled\", \"N/A\")}')
"

# Check repo-level overlay
python3 -c "
import json
with open('protected-repo-prod/.opencode/opencode.json') as f:
    mcp = json.load(f).get('mcp', {})
    for name, cfg in sorted(mcp.items()):
        print(f'  {name:20s} enabled={cfg.get(\"enabled\", \"N/A\")}')
"

# Check global config
python3 -c "
import json
with open('$HOME/.config/opencode/opencode.json') as f:
    mcp = json.load(f).get('mcp', {})
    for name, cfg in sorted(mcp.items()):
        print(f'  {name:20s} enabled={cfg.get(\"enabled\", \"N/A\")}')
"
```

## Global Config Drift

The OpenCode server can write merged config (including repo-level MCPs) back to the global config file (`~/.config/opencode/opencode.json`) when `opencode mcp list` is run from a repo directory. This causes `repo_only` MCPs like pencil to leak into the global config.

**Symptom:** `pencil` appears in the global config with `enabled: true`.

**Repair:**
```bash
bash .opencode/scripts/sync-opencode-runtime.sh
```

**Prevention:** The MCP Global Config Drift Guard (`.opencode/conformance/tests/mcp-global-drift-guard.sh`) detects this drift. Run it after any `opencode mcp list` invocation from a repo directory.

## Expected MCP State by Repo Type

### Baseline repos (non-UI)
- context7: enabled
- exa: enabled
- sequential-thinking: enabled
- github: enabled
- playwright: disabled
- pencil: absent
- firecrawl: disabled
- web-tools: deprecated (removed 2026-07-01 — no service code, no unique capability)

### ui_ux repos (protected-repo-prod, example-app, paperclip-PROD, demo-project, example-dashboard)
- context7: enabled (inherited from global)
- exa: enabled (inherited from global)
- sequential-thinking: enabled (inherited from global)
- github: enabled (inherited from global)
- playwright: enabled (repo overlay)
- pencil: enabled (repo overlay)
- firecrawl: disabled (inherited from global)
- web-tools: deprecated (removed 2026-07-01)

### Archived repos (protected-repo)
- All MCPs: disabled or absent
