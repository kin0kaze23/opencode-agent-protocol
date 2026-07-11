# OpenCode Desktop + CLI Sync — Runbook

**Status:** Stable — CLI server + Desktop client architecture  
**Versions:** CLI 1.15.13, Desktop 1.15.13

---

## Observed Failure Mode / Likely Contributors

OpenCode Desktop's local sidecar server failed to bootstrap with:
```
Failed to finish bootstrap instance
Failed to load sessions
```

This prevented the Desktop UI from loading any providers or models, showing "No results" in the model picker.

### Confirmed

- **Desktop sidecar/provider bootstrap failed** to load provider/model data
- **CLI server provider endpoints were healthy** (139 providers, 7 connected, 14 opencode-go models)
- **Desktop works when connected to the CLI server** at `http://127.0.0.1:4096`

### Suspected (Not Proven)

- **Plugin/module loading may have contributed** — plugin warnings appeared in server logs (`stuck-retry.js`, `brain-hooks.js`, `opencode-gemini-auth@latest`), and the Desktop's Electron environment may have stricter module resolution than the CLI's Node environment
- **Plugins were not proven as the sole root cause** — Desktop still failed after plugin/cache clean-room isolation and Desktop state reset

### Working Hypothesis

The CLI runs in a standard Node environment with full module resolution. Desktop runs in an Electron sandbox that may handle module loading differently. Plugin initialization warnings were observed, but the confirmed stable solution is to use the CLI server as the source of truth and connect Desktop to it, rather than relying on Desktop's local sidecar bootstrap.

---

## Working Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenCode CLI Server                       │
│  opencode serve --hostname 127.0.0.1 --port 4096            │
│  - Reads auth from ~/.local/share/opencode/auth.json        │
│  - Reads config from ~/.config/opencode/opencode.json       │
│  - Exposes: /global/health, /provider, /config/providers    │
│  - Models: 14 opencode-go models visible                    │
└──────────────────────┬──────────────────────────────────────┘
                       │ HTTP
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                   OpenCode Desktop                           │
│  Connects to: http://127.0.0.1:4096                         │
│  - UI client only (no local sidecar)                        │
│  - Gets providers/models from CLI server                    │
│  - Sessions run through CLI server backend                  │
└─────────────────────────────────────────────────────────────┘
```

**Key principle:** CLI server is the source of truth. Desktop is a client UI.

---

## Startup Command

```bash
# Quick start (recommended)
~/.local/bin/opencode-server-personal

# Or manually
cd ~/Developer/PersonalProjects
NO_PROXY=localhost,127.0.0.1 opencode serve --hostname 127.0.0.1 --port 4096 --log-level INFO
```

**Desktop connection:** `http://127.0.0.1:4096`

**Stop server:** `pkill -f "opencode serve.*4096"`

**View logs:** `tail -f /tmp/opencode-server-4096.log`

---

## Configuration State

### Global Config (`~/.config/opencode/opencode.json`)
```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "opencode-go/qwen3.6-plus",
  "small_model": "opencode-go/minimax-m2.5",
  "plugin": []
}
```

### Auth Store (`~/.local/share/opencode/auth.json`)
- OpenCode Go (api) ← **Primary provider**
- Other providers (OpenAI, Google, Alibaba) available but not primary

### Plugin State

- **Global config:** `plugin: []` (no plugins declared in config)
- **`.opencode/plugins/` directory:** Restored to working tree to avoid git noise; contains `brain-hooks.js`
- **Auto-loading behavior:** OpenCode may auto-load plugins from `.opencode/plugins/` and `~/.config/opencode/plugins/` directories even when not declared in config; this was not fully verified
- **Global plugins directory:** `~/.config/opencode/plugins/` backed up locally and disabled
- **Future plugin testing:** Should be done one-by-one with Desktop restart after each change

---

## Rollback Notes

### If Desktop breaks again:
1. **Restart CLI server:** `pkill -f "opencode serve.*4096" && ~/.local/bin/opencode-server-personal`
2. **Reconnect Desktop:** Server indicator → `http://127.0.0.1:4096`
3. **Clear Desktop cache:** `rm -rf ~/.cache/opencode`
4. **Reset Desktop state:** Restore `.dat` files from local backup if needed

### If CLI server fails:
1. Check auth: `opencode auth ls`
2. Re-authenticate if needed: `opencode auth login -p opencode-go`
3. Verify models: `opencode models opencode-go`
4. Restart server

### Full rollback to pre-fix state:
```bash
# Restore original config from local backup
cp ~/.config/opencode/desktop-fix-backup-*/opencode.json.backup ~/.config/opencode/opencode.json

# Restore plugins from local backups
mv ~/.config/opencode/plugins.disabled-* ~/.config/opencode/plugins
mv ~/Developer/PersonalProjects/.opencode/plugins.disabled-* ~/Developer/PersonalProjects/.opencode/plugins

# Restore Desktop state from local backup
cp ~/.config/opencode/desktop-state-reset-backup-*/*.dat ~/Library/Application\ Support/ai.opencode.desktop/
```

---

## What NOT to Restore Yet

Do **not** re-enable these until baseline is stable:

1. **`opencode-gemini-auth@latest`** — npm plugin, may conflict with Desktop
2. **`stuck-retry.js`** — global plugin, showed module resolution warnings
3. **`brain-hooks.js`** — workspace plugin, showed module resolution warnings
4. **Full behavioral config** — keep minimal until Desktop stability confirmed

### Plugin Directory Note

- `.opencode/plugins/` was restored to the working tree to avoid git deletion noise
- The directory contains `brain-hooks.js` but is not actively loaded due to `plugin: []` in global config
- OpenCode's auto-loading behavior from plugin directories was not fully verified
- Future plugin testing should re-enable one-by-one with Desktop restart after each change

### Safe Re-enable Order (Future)
1. Restore minimal config + `opencode-gemini-auth@latest` only
2. Test Desktop → if works, proceed
3. Restore global plugins dir (`stuck-retry.js`)
4. Test Desktop → if works, proceed
5. Restore workspace plugins dir (`brain-hooks.js`)
6. Test Desktop → if works, proceed
7. Restore full behavioral config (agents, MCP, permissions)

**Restart Desktop after each step.** The step that breaks Desktop identifies the culprit.

---

## Known Issues & Risks

| Risk | Severity | Mitigation |
|---|---|---|
| CLI server must be running before Desktop | Medium | Use launcher script; consider launchd service |
| Server port 4096 conflict | Low | Script checks for existing server |
| Plugin re-enable may break Desktop | Medium | Re-enable one by one with testing |
| Desktop auto-update may change behavior | Low | Monitor after updates |
| Auth token expiration | Low | Re-run `opencode auth login -p opencode-go` |

---

## Verification Checklist

Run this to confirm everything is working:

```bash
# CLI health
opencode --version
opencode auth ls
opencode models opencode-go

# Server health
curl -fsS http://127.0.0.1:4096/global/health
curl -fsS http://127.0.0.1:4096/provider | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'Connected: {data.get(\"connected\", [])}')
print(f'opencode-go models: {len([p for p in data.get(\"all\", []) if p.get(\"id\") == \"opencode-go\"][0].get(\"models\", {}))}')
"

# Desktop: manually verify
# 1. Server indicator shows http://127.0.0.1:4096
# 2. Model picker shows opencode-go with 14 models
# 3. Can start new session
```

---

## Future Improvements

1. **Launchd service:** Create `~/Library/LaunchAgents/ai.opencode.server.plist` for auto-start
2. **Plugin debugging:** Fix module resolution for `stuck-retry.js` and `brain-hooks.js`
3. **Desktop bug report:** Report bootstrap failure to OpenCode team
4. **Config sync:** Consider syncing workspace `.opencode/opencode.json` with global config
