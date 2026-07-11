#!/bin/bash
# OpenCode Safe Launch — Pre-flight memory check before starting opencode
# Usage: bash .opencode/scripts/opencode-safe-launch.sh [--fresh] [opencode args...]
#
# Canonical launcher for the Personal Projects workspace.
# This is the single entrypoint for `oc` and `oc-fresh`.
#
# Scope: CLI only. This launcher starts an OpenCode CLI session in the
# current terminal. It does NOT launch or manage OpenCode Desktop — the
# Desktop is a separate Electron client that connects to the shared local
# `opencode serve` (default port 4096). To start the Desktop, use the OS
# launcher (open -a OpenCode, click the app icon, etc.).
#
# Default mode:
#   Runs a standalone opencode session after sync/drift checks.
#   This is the safest mode for multiple concurrent terminals.
#
# --fresh:
#   Kill any existing opencode-serve listener on port 4096 (only if its
#   process command includes "opencode"), then launch a clean standalone
#   OpenCode CLI session. Use this after protocol/runtime config changes.
#
# Fast-path passthroughs (skip all preflight):
#   -v, --version, version, help, --help, upgrade
#   These call native opencode directly.
#
# Checks RAM before launching. Warns or blocks if memory is tight.
# Default mode avoids shared-server session clobbering between terminals.
# Fresh mode clears stale shared-server artifacts first, then starts clean.

# Avoid `set -e`: macOS ships bash 3.2.57, where a failed command substitution
# in a top-level variable assignment (e.g. X=$(false)) silently aborts the
# script with no error message. The user would see the launcher print
# "Loading Doppler secrets..." and then nothing. We rely on `set -u` and
# `set -o pipefail` for fast-fail on unset-variable and pipeline failures,
# and on explicit error handling for everything else.
set -u
set -o pipefail

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_FILE="$HOME/.config/opencode/opencode.json"
PROMPTS_DIR="$HOME/.config/opencode/prompts"
LOCAL_SYNC_SCRIPT="$WORKSPACE_ROOT/.opencode/scripts/sync-opencode-runtime.sh"
LOCAL_CANONICAL_ITEMS=(
    "$WORKSPACE_ROOT/.opencode/brain-config.json"
    "$WORKSPACE_ROOT/.opencode/helper-roster.md"
    "$WORKSPACE_ROOT/.opencode/global-runtime/prompts"
    "$WORKSPACE_ROOT/.opencode/agents"
)
PORT=4096
FORCE_FRESH=0

# ── Fast-path passthroughs ───────────────────────────────────────────────────
# For version/help/upgrade queries, call native opencode directly without
# memory preflight, sync checks, or any other overhead.
for arg in "$@"; do
    case "$arg" in
        -v|--version|version|help|--help|upgrade)
            exec opencode "$@"
            ;;
    esac
done

# Parse --fresh flag
PASSTHROUGH_ARGS=()
for arg in "$@"; do
    if [[ "$arg" == "--fresh" ]]; then
        FORCE_FRESH=1
    else
        PASSTHROUGH_ARGS+=("$arg")
    fi
done

# Thresholds (percentage of RAM used)
WARN_THRESHOLD=75
BLOCK_THRESHOLD=90

echo "🔍 Pre-flight memory check..."

# Get memory usage percentage
FREE_PCT=$(memory_pressure 2>/dev/null | grep "free percentage" | awk '{print $NF}' | tr -d '%')
if [ -z "$FREE_PCT" ]; then
    FREE_MB=$(vm_stat | awk -v ps=$(sysctl -n hw.pagesize) '
        /Pages free:/ {free=$3}
        /Pages speculative:/ {spec=$3}
        END {printf "%.0f", (free+spec)*ps/1024/1024}')
    TOTAL_GB=$(sysctl -n hw.memsize | awk '{printf "%.0f", $1/1024/1024/1024}')
    FREE_PCT=$(echo "$FREE_MB $TOTAL_GB" | awk '{printf "%.0f", ($1/($2*1024))*100}')
fi

USED_PCT=$((100 - ${FREE_PCT:-50}))

# Check existing opencode processes
OC_COUNT=$(pgrep -c opencode 2>/dev/null || echo 0)
LISTEN_PID=$(lsof -tiTCP:$PORT -sTCP:LISTEN 2>/dev/null | head -1 || true)
SERVE_PID=$(pgrep -f "opencode serve" 2>/dev/null | head -1 || true)
if [ -z "$SERVE_PID" ] && [ -n "$LISTEN_PID" ]; then
    SERVE_PID="$LISTEN_PID"
fi

if [ "$USED_PCT" -ge "$BLOCK_THRESHOLD" ]; then
    echo ""
    echo "🚫 BLOCKED: Memory usage at ${USED_PCT}% (threshold: ${BLOCK_THRESHOLD}%)"
    echo ""
    echo "Current opencode processes: ${OC_COUNT}"
    echo ""
    echo "To free memory:"
    echo "  1. Run: ram-cleanup"
    echo "  2. Close browser tabs"
    echo "  3. Kill standalone opencode: pkill -f 'opencode [a-z]'"
    echo ""
    exit 1
fi

if [ "$USED_PCT" -ge "$WARN_THRESHOLD" ]; then
    echo ""
    echo "⚠️  WARNING: Memory usage at ${USED_PCT}%"
    echo "   You have ${OC_COUNT} opencode processes running"
    echo ""
    read -p "   Continue anyway? (y/N): " confirm
    if [[ $confirm != [Yy] ]]; then
        echo "   Cancelled. Run: ram-cleanup"
        exit 1
    fi
fi

echo "✅ Memory OK (${USED_PCT}% used)"

# ── Ensure prompts symlink exists ─────────────────────────────────────────────
# The workspace config references {file:prompts/*.md} but the actual prompts
# live in global-runtime/prompts/. Create a symlink if it doesn't exist.
PROMPTS_LINK="$WORKSPACE_ROOT/.opencode/prompts"
PROMPTS_TARGET="global-runtime/prompts"
if [ ! -e "$PROMPTS_LINK" ]; then
    echo "🔗 Creating prompts symlink..."
    ln -s "$PROMPTS_TARGET" "$PROMPTS_LINK"
    echo "✅ Prompts symlink created"
fi

# ── Provider secrets (intentionally NOT loaded here) ────────────────────────
# The launcher does not own provider secrets. Earlier revisions of this script
# tried to fetch BAILIAN_CODING_PLAN_API_KEY from Doppler, but that secret has
# been removed (Alibaba/Bailian is decommissioned; canonical secret is
# OPENCODE_GO_API_KEY, see .opencode/brain-config.json and
# .opencode/model-registry.yaml). The OpenCode Go provider reads
# OPENCODE_GO_API_KEY from the environment itself, not from this launcher.
#
# If a future migration adds a new provider, configure the provider in
# .opencode/opencode.json — do not add secret loading back to this script.

# ── Runtime staleness / sync check ────────────────────────────────────────────
# The launcher-visible runtime lives in ~/.config/opencode, but the canonical
# helper policy lives in the checked-in workspace protocol. If local canonical
# helper files are newer than the global runtime, sync first. Then, if the
# effective runtime is newer than the running server process, note it.
CONFIG_STALE=0
latest_mtime() {
    local latest=0
    for item in "$@"; do
        if [ -d "$item" ]; then
            while IFS= read -r path; do
                local mtime
                mtime=$(stat -f "%m" "$path" 2>/dev/null || echo "0")
                if [ "$mtime" -gt "$latest" ]; then
                    latest="$mtime"
                fi
            done < <(find "$item" -type f 2>/dev/null)
        elif [ -f "$item" ]; then
            local mtime
            mtime=$(stat -f "%m" "$item" 2>/dev/null || echo "0")
            if [ "$mtime" -gt "$latest" ]; then
                latest="$mtime"
            fi
        fi
    done
    echo "$latest"
}

GLOBAL_RUNTIME_EPOCH=$(latest_mtime "$CONFIG_FILE" "$PROMPTS_DIR")
LOCAL_CANONICAL_EPOCH=$(latest_mtime "${LOCAL_CANONICAL_ITEMS[@]}")

if [ "$LOCAL_CANONICAL_EPOCH" -gt "$GLOBAL_RUNTIME_EPOCH" ] && [ -x "$LOCAL_SYNC_SCRIPT" ]; then
    echo "🔄 Local canonical helper policy is newer than the global OpenCode runtime — syncing..."
    "$LOCAL_SYNC_SCRIPT"
    GLOBAL_RUNTIME_EPOCH=$(latest_mtime "$CONFIG_FILE" "$PROMPTS_DIR")
fi

if [ -n "$SERVE_PID" ] && [ -f "$CONFIG_FILE" ]; then
    SERVER_START=$(ps -o lstart= -p "$SERVE_PID" 2>/dev/null || echo "")
    if [ -n "$SERVER_START" ]; then
        SERVER_START_EPOCH=$(date -j -f "%a %b %d %T %Y" "$SERVER_START" "+%s" 2>/dev/null || echo "0")
        if [ "$GLOBAL_RUNTIME_EPOCH" -gt "$SERVER_START_EPOCH" ]; then
            CONFIG_STALE=1
            echo "⚠️  OpenCode runtime changed since server started."
            echo "   Default oc uses standalone mode, so this session is safe."
            echo "   Run oc-fresh to clear stale shared-server artifacts."
        fi
    fi
fi

# ── Fresh-mode cleanup ────────────────────────────────────────────────────────
# Fresh mode clears any stale shared-server listener/process first.
# Safer: only kill a port-${PORT} listener if its process command includes "opencode".
if [ "$FORCE_FRESH" -eq 1 ]; then
    if [ -n "$SERVE_PID" ]; then
        echo "🛑 Stopping existing server (PID $SERVE_PID)..."
        kill "$SERVE_PID" 2>/dev/null || true
        sleep 1
    fi
    # If the fixed shared port is still occupied, stop only if it's opencode.
    PORT_LISTENER=$(lsof -tiTCP:$PORT -sTCP:LISTEN 2>/dev/null | head -1 || true)
    if [ -n "$PORT_LISTENER" ]; then
        LISTENER_CMD=$(ps -o command= -p "$PORT_LISTENER" 2>/dev/null || echo "")
        if [[ "$LISTENER_CMD" == *"opencode"* ]]; then
            echo "🛑 Clearing existing opencode listener on port ${PORT} (PID $PORT_LISTENER)..."
            kill "$PORT_LISTENER" 2>/dev/null || true
            sleep 1
        else
            echo "⚠️  Port ${PORT} is in use by a non-opencode process (PID $PORT_LISTENER). Skipping."
        fi
    fi
fi

# ── Standalone launch ─────────────────────────────────────────────────────────
if [ "$FORCE_FRESH" -eq 1 ]; then
    echo "🧼 Launching clean standalone opencode session..."
else
    if [ "$CONFIG_STALE" -eq 1 ]; then
        echo "ℹ️  Shared server runtime is stale, but default oc mode uses standalone launch."
        echo "   Run oc-fresh if you want to clear any stale shared-server artifacts first."
    fi
    echo "🧭 Launching standalone opencode session..."
fi
# `set -u` treats a zero-length array as "unset" for [@] expansion. The
# `${arr[@]+"${arr[@]}"}` idiom expands the array when set (even if empty)
# and expands to nothing when unset, so `oc` (no args) does not abort.
exec opencode ${PASSTHROUGH_ARGS[@]+"${PASSTHROUGH_ARGS[@]}"}
