# Installation

> **Detailed guide for installing the OpenCode Agent Protocol.**

## Prerequisites

| Requirement | Version | Purpose |
|-------------|---------|---------|
| macOS or Linux | Any recent | Operating system |
| Git | 2.20+ | Version control |
| Python 3 | 3.8+ | Conformance tests |
| OpenCode CLI | Latest | AI agent runtime |
| Node.js | 18+ | MCP servers, sync scripts |
| jq | 1.6+ | JSON processing in scripts |
| pnpm (optional) | Latest | Plugin dependency installation |

### Install OpenCode

```bash
# Install OpenCode CLI
curl -fsSL https://opencode.ai/install | bash
```

### Install jq (if not present)

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

### Install Node.js (if not present)

```bash
# macOS
brew install node

# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

## Step 1: Clone the Repository

```bash
git clone https://github.com/kin0kaze23/opencode-agent-protocol.git
cd opencode-agent-protocol
```

## Step 2: Run Setup Script (Recommended)

```bash
bash scripts/setup.sh
```

This script:
- Detects your OS (macOS/Linux)
- Checks all prerequisites
- Generates shell alias snippets with correct paths
- Checks for provider environment variables
- Prints next steps

Alternatively, follow the manual steps below.

## Step 3: Configure Shell Aliases (Manual)

Add the following to your `~/.zshrc` or `~/.bashrc`:

```bash
# OpenCode Agent Protocol aliases
# Replace /path/to with your actual clone location
WORKSPACE_ROOT="/path/to/opencode-agent-protocol"

alias oc="bash $WORKSPACE_ROOT/.opencode/bin/autopilot"
alias oc-fresh="bash $WORKSPACE_ROOT/.opencode/bin/autopilot --fresh"
alias oc-manual="bash $WORKSPACE_ROOT/.opencode/scripts/opencode-safe-launch.sh"
```

Apply changes:

```bash
source ~/.zshrc  # or ~/.bashrc
```

## Step 4: Configure Provider/Auth

OpenCode requires API keys for model providers. The protocol ships with placeholder model IDs — you must replace them with your own.

### Option A: Use the setup guide

Read [docs/OWN_MODEL_SETUP.md](OWN_MODEL_SETUP.md) for step-by-step provider configuration.

### Option B: Set environment variables directly

```bash
# Example: OpenAI
export OPENAI_API_KEY="your-api-key"

# Example: Anthropic
export ANTHROPIC_API_KEY="your-api-key"
```

### Option C: Use a secrets manager

```bash
# Doppler
doppler setup
doppler run -- opencode
```

**Never commit API keys to Git.** The `.gitignore` blocks `.env` files and pre-commit hooks scan for secrets.

## Step 5: Install Plugin Dependencies (Optional)

If you want to use the protocol's plugins (brain-hooks.js, permission-guard.js):

```bash
cd .opencode
npm install
cd ..
```

## Step 6: Sync Runtime

```bash
bash .opencode/scripts/sync-opencode-runtime.sh
```

This copies prompts to `~/.config/opencode/prompts/` and updates agent definitions.

## Step 7: Verify Installation

```bash
bash scripts/verify-install.sh
```

This runs a 10-suite verification covering:
- Protocol files exist
- Conformance tests pass
- Workspace protocol guard
- Environment verification

## Step 8: Run Validation Suite

```bash
# Protocol Atlas validation
bash .opencode/scripts/validate-protocol-atlas.sh

# Full conformance suite
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/conformance/tests/production-hardening.sh
bash .opencode/conformance/tests/loop-controller.sh
bash .opencode/conformance/tests/model-roi.sh
```

## MCP Server First Run

The protocol configures several MCP servers (context7, exa, sequential-thinking, github). On first run, `npx` will download these packages automatically. This may take 30-60 seconds. Network access is required.

To disable MCP servers you don't need, edit `.opencode/opencode.json` and set `"enabled": false` for any MCP entry.

## Troubleshooting

### Plugin paths not resolving

The `opencode.json` uses relative plugin paths (`.opencode/plugins/brain-hooks.js`). If OpenCode requires absolute paths, run:

```bash
# Get your workspace root
WORKSPACE_ROOT=$(pwd)
# Update opencode.json plugin paths to absolute
sed -i.bak "s|.opencode/plugins/brain-hooks.js|file://$WORKSPACE_ROOT/.opencode/plugins/brain-hooks.js|g" .opencode/opencode.json
sed -i.bak "s|.opencode/plugins/permission-guard.js|file://$WORKSPACE_ROOT/.opencode/plugins/permission-guard.js|g" .opencode/opencode.json
```

### Conformance results directory missing

The `conformance/results/` directory is `.gitignored` (generated). The `assert.sh` script creates it automatically with `mkdir -p`. If you see errors, run:

```bash
mkdir -p .opencode/conformance/results
```

### Loop lessons file missing

The `loop-lessons.jsonl` file is `.gitignored` (generated). The `run-loop-controller.sh` script creates it automatically. If you see errors, run:

```bash
mkdir -p .opencode/evals/lessons
echo '{"task_id":"init","failure_pattern":"none","fix_pattern":"initialization","evidence":[],"recommended_future_action":"Loop lessons file initialized","applicable_task_types":[],"extracted_at":"2026-07-09T00:00:00Z"}' > .opencode/evals/lessons/loop-lessons.jsonl
```

### Permission denied on scripts

```bash
chmod +x .opencode/bin/autopilot
chmod +x .opencode/scripts/opencode-safe-launch.sh
chmod +x scripts/verify-install.sh
chmod +x scripts/bootstrap-opencode.sh
chmod +x scripts/setup.sh
```

### Launcher fails on Linux

The launcher script (`opencode-safe-launch.sh`) supports both macOS and Linux. If you encounter issues:

1. Verify `uname -s` returns `Linux`
2. Ensure `/proc/meminfo` is accessible
3. Check that `lsof` is installed (`sudo apt-get install lsof`)
4. Report the issue with your OS and error message
