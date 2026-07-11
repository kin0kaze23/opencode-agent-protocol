# Installation

> **Detailed guide for installing the OpenCode Agent Protocol.**

## Prerequisites

| Requirement | Version | Purpose |
|-------------|---------|---------|
| macOS or Linux | Any recent | Operating system |
| Git | 2.20+ | Version control |
| Python 3 | 3.8+ | Conformance tests |
| OpenCode CLI | Latest | AI agent runtime |
| Node.js | 18+ | OpenCode runtime (if using plugins) |
| jq | 1.6+ | JSON processing in scripts |

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

## Step 1: Clone the Repository

```bash
git clone https://github.com/kin0kaze23/opencode-agent-protocol.git
cd opencode-agent-protocol
```

## Step 2: Initialize Submodules

The vault submodule contains protocol history, lessons, and decisions:

```bash
git submodule update --init --recursive
```

## Step 3: Configure Shell Aliases

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

OpenCode requires API keys for model providers. Set environment variables:

```bash
# Example: Umans provider
export UMANS_API_KEY="your-api-key"

# Example: OpenCode Go provider
export OPENCODE_GO_API_KEY="your-api-key"
```

Or use a secrets manager like [Doppler](https://www.doppler.com/):

```bash
doppler setup
doppler run -- opencode
```

**Never commit API keys to Git.** The `.gitignore` blocks `.env` files and pre-commit hooks scan for secrets.

## Step 5: Verify Installation

```bash
bash scripts/verify-install.sh
```

This runs a 10-suite verification covering:
- Protocol files exist
- Conformance tests pass
- Workspace protocol guard
- Environment verification

## Step 6: Run Validation Suite

```bash
# Protocol Atlas validation
bash .opencode/scripts/validate-protocol-atlas.sh

# Full conformance suite (16 suites, 818+ tests)
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/conformance/tests/reviewer-calibration.sh
bash .opencode/conformance/tests/model-roi.sh
bash .opencode/conformance/tests/loop-controller.sh
bash .opencode/conformance/tests/task-replay.sh
bash .opencode/conformance/tests/evidence-freshness.sh
bash .opencode/conformance/tests/manual-evidence.sh
bash .opencode/conformance/tests/fleet-dashboard.sh
bash .opencode/conformance/tests/fleet-trends.sh
bash .opencode/conformance/tests/pr-comment.sh
bash .opencode/conformance/tests/pr-release-gate.sh
bash .opencode/conformance/tests/branch-protection.sh
bash .opencode/conformance/tests/production-hardening.sh
bash .opencode/conformance/tests/telemetry-hardening.sh
bash .opencode/conformance/tests/evidence-based-routing.sh
```

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

### Vault submodule not initialized

```bash
git submodule update --init --recursive
```

### Permission denied on scripts

```bash
chmod +x .opencode/bin/autopilot
chmod +x .opencode/scripts/opencode-safe-launch.sh
chmod +x scripts/verify-install.sh
chmod +x scripts/bootstrap-opencode.sh
```
