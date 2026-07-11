# Protocol Runbook — OpenCode Agent Protocol

> **Version:** v4.15.0 (Capacity-First Provider Routing Production Core)
> **Last updated:** 2026-06-28
> **Authority:** This runbook is operational guidance for the sealed v4.15.0 production core.

---

## 1. Verify Config Health

Run these commands to verify the OpenCode protocol is healthy:

```bash
# Run all 4 key conformance guards
bash .opencode/conformance/tests/agent-roster-guard.sh
bash .opencode/conformance/tests/mcp-policy-guard.sh
bash .opencode/conformance/tests/effective-runtime-diff.sh
bash .opencode/conformance/tests/config-authority-guard.sh

# Expected: 0 FAIL, 0 WARN across all guards
# If any FAIL or WARN appears, see Section 4 (Recover from Config Drift)
```

Quick check (one-liner):
```bash
for g in agent-roster-guard mcp-policy-guard effective-runtime-diff config-authority-guard; do
  echo "--- $g ---"
  bash .opencode/conformance/tests/$g.sh 2>&1 | grep -E "PASS:|WARN:|FAIL:|SKIP:"
done
```

Verify config sync:
```bash
# Both configs should have 11 agents
node -e "const w=JSON.parse(require('fs').readFileSync('.opencode/opencode.json','utf8')); const g=JSON.parse(require('fs').readFileSync(require('os').homedir()+'/.config/opencode/opencode.json','utf8')); console.log('Workspace:', Object.keys(w.agent).length, 'agents'); console.log('Global:', Object.keys(g.agent).length, 'agents'); console.log('Sync:', Object.keys(w.agent).length === Object.keys(g.agent).length ? 'OK' : 'DRIFT')"
```

---

## 2. Sync Global/Workspace Runtime

The sync script generates agent definitions from the canonical protocol source (brain-config.json + agents/*.md) and writes to BOTH configs:

```bash
# Run the sync script
bash .opencode/scripts/sync-opencode-runtime.sh

# What it does:
# 1. Generates prompt mirrors from .opencode/agents/*.md
# 2. Updates workspace .opencode/opencode.json with agent definitions
# 3. Updates global ~/.config/opencode/opencode.json with same agent definitions
# 4. Copies prompts to ~/.config/opencode/prompts/

# After sync, restart OpenCode for changes to take effect
```

When to sync:
- After adding or removing an agent
- After changing model routing in brain-config.json
- After adding or removing MCP servers
- After updating agent prompts

---

## 3. Onboard a New Repo

New repos under `PersonalProjects/` inherit the workspace config automatically — no setup needed.

For repos outside `PersonalProjects/` (e.g., antigravity repos):

1. **Option A: Rely on global config (default)**
   - No action needed — the global config provides the full behavioral baseline
   - All 11 agents, MCP config, and permissions are available

2. **Option B: Create repo-local overrides (for MCP customization)**
   ```bash
   mkdir -p <repo>/.opencode
   cat > <repo>/.opencode/opencode.json << 'EOF'
   {
     "$schema": "https://opencode.ai/config.json",
     "mcp": {
       "playwright": {
         "command": ["npx", "-y", "@playwright/mcp@0.0.76", "--isolated", "--output-dir", ".claude/visual-qa-output"],
         "enabled": true,
         "type": "local",
         "timeout": 60000,
         "env": {}
       }
     }
   }
   EOF
   ```

3. **Verify the repo has access to all agents:**
   ```bash
   # Open the repo in OpenCode and check available agents
   # The orchestrator should be available as the default agent
   ```

---

## 4. Recover from Config Drift

If conformance guards show FAIL or WARN:

### Step 1: Identify the drift
```bash
# Run the failing guard with verbose output
bash .opencode/conformance/tests/<guard-name>.sh 2>&1 | grep "FAIL\|WARN"
```

### Step 2: Check for common causes
- **Agent count mismatch**: New agent added to one config but not the other → run sync script
- **Model mismatch**: Model changed in brain-config but not synced → run sync script
- **MCP drift**: MCP enabled/disabled in one config but not the other → check mcp-profiles.json
- **Prompt drift**: Prompt mirror doesn't match canonical source → run sync script

### Step 3: Fix by syncing
```bash
bash .opencode/scripts/sync-opencode-runtime.sh
```

### Step 4: Re-run guards
```bash
for g in agent-roster-guard mcp-policy-guard effective-runtime-diff config-authority-guard; do
  bash .opencode/conformance/tests/$g.sh 2>&1 | grep -E "PASS:|WARN:|FAIL:"
done
```

### Step 5: Restart OpenCode
Config changes require an OpenCode restart to take effect.

---

## 5. Run Visual QA Canaries

### Prerequisites
- Dev server running on a known port
- Playwright MCP enabled with `--isolated`

### Standard Visual QA Flow
```
1. Orchestrator navigates to the page via playwright_browser_navigate
2. Take desktop screenshot (1440x900)
3. Resize to mobile (390x844) and take mobile screenshot
4. Delegate screenshot analysis to visual-reviewer agent
5. Run axe-core accessibility check via playwright_browser_evaluate
6. Check console errors via playwright_browser_console_messages
7. Check network errors via playwright_browser_network_requests
8. Compile Visual QA Report
9. If issues found: delegate fix to implementer, then re-verify
10. Delegate final risk review to reviewer agent
```

### Quick axe-core check (one command)
```bash
node ~/.claude/skills/visual-qa/scripts/axe-audit.mjs http://localhost:3000
```

---

## 6. Troubleshoot Playwright Browser Locking

**Symptom:** "Browser is already in use for /Users/.../mcp-chrome-xxx"

**Root cause:** Multiple Playwright MCP sessions trying to use the same browser profile.

**Fix:** The `--isolated` flag prevents this by using in-memory browser profiles. Verify it's enabled:

```bash
# Check workspace config
node -e "const c=JSON.parse(require('fs').readFileSync('.opencode/opencode.json','utf8')); console.log('isolated:', c.mcp.playwright.command.includes('--isolated'))"

# Check global config
node -e "const c=JSON.parse(require('fs').readFileSync(require('os').homedir()+'/.config/opencode/opencode.json','utf8')); console.log('isolated:', c.mcp.playwright.command.includes('--isolated'))"
```

If `--isolated` is missing, add it to the playwright MCP command and restart OpenCode.

**Emergency fix (kill stale processes):**
```bash
pkill -f "playwright-mcp"
pkill -f "ms-playwright-mcp/mcp-chrome"
```

---

## 7. Handle Failed Sub-Agent Delegation

### Symptom: Implementer reports success but edit not applied

**Root cause:** The implementer's `edit: "ask"` permission doesn't work in sub-agent context — the sub-agent cannot get user approval for edits.

**Fix (implemented Phase 2):** The implementer now has `edit: "allow"`. The orchestrator's touch list approval serves as the gate.

**If delegation still fails:**
1. Check the implementer's permission in the active config:
   ```bash
   node -e "const c=JSON.parse(require('fs').readFileSync('.opencode/opencode.json','utf8')); console.log(c.agent.implementer.permission)"
   ```
2. If `edit` is not `"allow"`, run the sync script:
   ```bash
   bash .opencode/scripts/sync-opencode-runtime.sh
   ```
3. Restart OpenCode
4. Retry the delegation

### Symptom: Visual-reviewer returns empty or error

**Possible causes:**
- OpenCode Go quota exhausted → fall back to `visual-reviewer-fallback` (umans-kimi-k2.7)
- Model unavailable → check `opencode models` output
- Screenshot file not found → verify the path exists before delegating

---

## 8. Architecture Reference

```
Canonical Protocol Source
  ├── .opencode/brain-config.json (routing, budgets, roster)
  ├── .opencode/agents/*.md (agent prompt sources)
  ├── .opencode/rules.md (guardrails)
  └── .opencode/policies/*.json (conformance policies)
        ↓ sync-opencode-runtime.sh writes to BOTH
  ├── Workspace Config (.opencode/opencode.json) — 11 agents + compaction/default_agent/watcher/lsp
  └── Global Config (~/.config/opencode/opencode.json) — 11 agents + MCP + model
        ↓ inherits
  ├── PersonalProjects repos → use workspace config (authority)
  ├── antigravity repos → use global config (baseline)
  └── Repo-level overrides (demo-project, example-dashboard) → MCP exceptions only
```

### Agent Roster

| Agent | Model | Delegatable | Purpose |
|---|---|---|---|
| orchestrator | umans-glm-5.2 | — | Primary agent |
| explorer | umans-flash | ✅ | Read-only discovery |
| planner | umans-coder | ✅ | Planning |
| implementer | umans-coder | ✅ | Bounded code changes (edit: allow) |
| reviewer | umans-glm-5.1 | ✅ | Risk review |
| architect | qwen3.7-plus | ✅ | Architecture decisions |
| budget | umans-flash | ✅ | Cheap read-only |
| visual-reviewer | minimax-m3 | ✅ | Screenshot analysis |
| visual-reviewer-fallback | umans-kimi-k2.7 | ✅ | Fallback screenshot analysis |
| summary | umans-kimi-k2.7 | ❌ internal | Session summarization |
| compaction | umans-kimi-k2.7 | ❌ internal | Context compaction |
