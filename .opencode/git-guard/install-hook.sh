#!/usr/bin/env bash
# GitGuard Hook Installer
# Installs the canonical pre-push hook into a single repo.
# Idempotent: safe to run multiple times on the same repo.
#
# Usage:
#   bash .opencode/git-guard/install-hook.sh <repo-path>
#   bash .opencode/git-guard/install-hook.sh sample-service    (relative to workspace root)
#
# Exit codes:
#   0 — Hook installed or already up to date
#   1 — Error (no .git directory, canonical source missing, etc.)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
CANONICAL_HOOK="$SCRIPT_DIR/pre-push-hook.sh"

# Resolve repo path
if [ $# -lt 1 ]; then
    echo "Usage: $0 <repo-path>"
    echo "  repo-path can be absolute or relative to workspace root"
    exit 1
fi

REPO_INPUT="$1"

# If relative path, resolve from workspace root
if [[ "$REPO_INPUT" != /* ]]; then
    REPO_PATH="$WORKSPACE_ROOT/$REPO_INPUT"
else
    REPO_PATH="$REPO_INPUT"
fi

# Normalize path (remove trailing slash, resolve .)
REPO_PATH="$(cd "$REPO_PATH" 2>/dev/null && pwd)" || {
    echo "ERROR: Directory not found: $REPO_INPUT"
    exit 1
}

REPO_NAME="$(basename "$REPO_PATH")"
GIT_DIR="$REPO_PATH/.git"
HOOK_TARGET="$GIT_DIR/hooks/pre-push"

# Validate canonical source exists
if [ ! -f "$CANONICAL_HOOK" ]; then
    echo "ERROR: Canonical hook not found at $CANONICAL_HOOK"
    echo "Run this script from the workspace root or fix the canonical source path."
    exit 1
fi

# Validate .git directory exists
if [ ! -d "$GIT_DIR" ]; then
    echo "SKIP: $REPO_NAME — no .git directory (not a git repo or uses worktrees)"
    exit 0
fi

# Check if hook is already installed and up to date
if [ -f "$HOOK_TARGET" ]; then
    if diff -q "$CANONICAL_HOOK" "$HOOK_TARGET" >/dev/null 2>&1; then
        echo "OK: $REPO_NAME — hook already installed and up to date"
        exit 0
    else
        echo "UPDATE: $REPO_NAME — hook exists but differs from canonical source"
    fi
else
    echo "INSTALL: $REPO_NAME — no pre-push hook found"
fi

# Install the hook
cp "$CANONICAL_HOOK" "$HOOK_TARGET"
chmod +x "$HOOK_TARGET"

# Verify installation
if diff -q "$CANONICAL_HOOK" "$HOOK_TARGET" >/dev/null 2>&1; then
    echo "DONE: $REPO_NAME — GitGuard pre-push hook installed"
    exit 0
else
    echo "ERROR: $REPO_NAME — hook installation verification failed"
    exit 1
fi
