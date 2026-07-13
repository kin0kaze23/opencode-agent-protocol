#!/bin/bash
# setup.sh — First-run setup for OpenCode Agent Protocol
# Usage: bash scripts/setup.sh [--check]
#
# Detects OS, checks prerequisites, generates alias snippets,
# and guides provider configuration.
#
# --check: Only check prerequisites, don't generate aliases

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OS_TYPE="$(uname -s)"
CHECK_ONLY=0

for arg in "$@"; do
    case "$arg" in
        --check) CHECK_ONLY=1 ;;
        --help|-h)
            echo "Usage: bash scripts/setup.sh [--check]"
            echo ""
            echo "  --check    Only check prerequisites, don't generate aliases"
            echo "  --help     Show this help"
            exit 0
            ;;
    esac
done

PASS=0
FAIL=0
WARN=0

pass() { printf '  \033[0;32m✓\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }
warn() { printf '  \033[0;33m⚠\033[0m %s\n' "$1"; WARN=$((WARN + 1)); }

echo "=========================================="
echo "OpenCode Agent Protocol — Setup"
echo "=========================================="
echo "OS: $OS_TYPE"
echo "Root: $ROOT_DIR"
echo ""

# ── Check prerequisites ────────────────────────────────────────────────────────
echo "== Prerequisites =="

for tool in git bash python3 node jq; do
    if command -v "$tool" >/dev/null 2>&1; then
        version=$("$tool" --version 2>&1 | head -1)
        pass "$tool: $version"
    else
        fail "$tool: NOT FOUND"
        case "$tool" in
            jq)
                echo "    Install: brew install jq (macOS) or sudo apt-get install jq (Linux)"
                ;;
            node)
                echo "    Install: brew install node (macOS) or see https://nodejs.org/"
                ;;
            python3)
                echo "    Install: brew install python3 (macOS) or sudo apt-get install python3 (Linux)"
                ;;
        esac
    fi
done

# Check OpenCode CLI
echo ""
echo "== OpenCode CLI =="
if command -v opencode >/dev/null 2>&1; then
    pass "opencode CLI: $(opencode --version 2>&1 | head -1)"
else
    warn "opencode CLI: NOT FOUND"
    echo "    Install: curl -fsSL https://opencode.ai/install | bash"
fi

# Check lsof (needed by launcher)
echo ""
echo "== Launcher Dependencies =="
if command -v lsof >/dev/null 2>&1; then
    pass "lsof: available"
else
    warn "lsof: NOT FOUND"
    echo "    Install: brew install lsof (macOS) or sudo apt-get install lsof (Linux)"
fi

# ── Check workspace structure ────────────────────────────────────────────────
echo ""
echo "== Workspace Structure =="
for f in .opencode/AGENTS.md .opencode/rules.md .opencode/opencode.json .opencode/brain-config.json; do
    if [ -f "$ROOT_DIR/$f" ]; then
        pass "$f exists"
    else
        fail "$f missing"
    fi
done

# ── Check provider configuration ──────────────────────────────────────────────
echo ""
echo "== Provider Configuration =="

# Check if opencode.json still has placeholder models
if [ -f "$ROOT_DIR/.opencode/opencode.json" ]; then
    if grep -q "YOUR_PROVIDER" "$ROOT_DIR/.opencode/opencode.json" 2>/dev/null; then
        warn "opencode.json has placeholder model IDs"
        echo "    You need to configure your own model provider."
        echo "    See: docs/OWN_MODEL_SETUP.md"
    else
        pass "opencode.json has model IDs configured"
    fi
fi

# Check common provider env vars
PROVIDER_VARS="OPENAI_API_KEY ANTHROPIC_API_KEY OPENCODE_GO_API_KEY OPENROUTER_API_KEY"
PROVIDER_FOUND=0
for var in $PROVIDER_VARS; do
    # Use indirect expansion safely
    eval "var_value=\${$var:-}"
    if [ -n "$var_value" ]; then
        pass "$var is set"
        PROVIDER_FOUND=1
        break
    fi
done
if [ "$PROVIDER_FOUND" -eq 0 ]; then
    warn "No provider API key found in environment"
    echo "    Set one of: $PROVIDER_VARS"
    echo "    Or use a secrets manager like Doppler"
fi

# ── Check global config ───────────────────────────────────────────────────────
echo ""
echo "== Global Config =="
GLOBAL_DIR="$HOME/.config/opencode"
if [ -f "$GLOBAL_DIR/opencode.json" ]; then
    pass "Global opencode.json exists"
else
    warn "Global opencode.json not found"
    echo "    Run: bash .opencode/scripts/sync-opencode-runtime.sh"
fi

prompt_count=$(ls "$GLOBAL_DIR/prompts/"*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$prompt_count" -ge 9 ]; then
    pass "Global prompts: $prompt_count files"
else
    warn "Global prompts: $prompt_count files (expected 9+)"
    echo "    Run: bash .opencode/scripts/sync-opencode-runtime.sh"
fi

# ── Generate alias snippets ───────────────────────────────────────────────────
if [ "$CHECK_ONLY" -eq 0 ]; then
    echo ""
    echo "== Shell Aliases =="
    echo ""
    echo "Add these to your ~/.zshrc or ~/.bashrc:"
    echo ""
    echo '```bash'
    echo "WORKSPACE_ROOT=\"$ROOT_DIR\""
    echo ""
    echo "alias oc=\"bash \$WORKSPACE_ROOT/.opencode/bin/autopilot\""
    echo "alias oc-fresh=\"bash \$WORKSPACE_ROOT/.opencode/bin/autopilot --fresh\""
    echo "alias oc-manual=\"bash \$WORKSPACE_ROOT/.opencode/scripts/opencode-safe-launch.sh\""
    echo '```'
    echo ""
    echo "Then run: source ~/.zshrc"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
printf '  PASSED: %d\n' "$PASS"
printf '  FAILED: %d\n' "$FAIL"
printf '  WARNED: %d\n' "$WARN"
echo "=========================================="

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "[FAIL] Setup incomplete. Fix failures above."
    echo ""
    echo "Next steps:"
    echo "  1. Install missing prerequisites"
    echo "  2. Run: bash scripts/setup.sh --check"
    echo "  3. Configure your model provider (see docs/OWN_MODEL_SETUP.md)"
    echo "  4. Run: bash scripts/verify-install.sh"
    exit 1
else
    echo ""
    echo "[PASS] Setup checks passed."
    echo ""
    echo "Next steps:"
    echo "  1. Add shell aliases (see above)"
    echo "  2. Configure your model provider (see docs/OWN_MODEL_SETUP.md)"
    echo "  3. Run: bash .opencode/scripts/sync-opencode-runtime.sh"
    echo "  4. Run: bash scripts/verify-install.sh"
    echo "  5. Start: oc"
    exit 0
fi
