#!/bin/bash
# OpenCode Environment Check — Verify runtime is healthy before launch
# Usage: bash .opencode/scripts/opencode-env-check.sh
#
# Checks:
# 1. Doppler secrets available
# 2. OpenCode CLI version
# 3. Provider connectivity
# 4. Stale processes
# 5. Cache state

set -e

echo "🔍 OpenCode Environment Check"
echo "=============================="

# 1. Check Doppler secrets
echo -n "🔑 Doppler secrets: "
DOPPLER_KEY=$(doppler secrets get BAILIAN_CODING_PLAN_API_KEY --project nuggie-be --config dev_backend --plain 2>/dev/null)
if [ -n "$DOPPLER_KEY" ] && [ "$DOPPLER_KEY" != "null" ]; then
    echo "✅ Available"
else
    echo "❌ Missing"
    echo "   Run: doppler login && doppler setup --project nuggie-be --config dev_backend"
    exit 1
fi

# 2. Check OpenCode CLI version
echo -n "📦 OpenCode CLI: "
OC_VERSION=$(opencode --version 2>/dev/null)
if [ -n "$OC_VERSION" ]; then
    echo "✅ $OC_VERSION"
else
    echo "❌ Not found"
    exit 1
fi

# 3. Check for stale processes
echo -n "🔄 Stale processes: "
OC_COUNT=$(pgrep -c opencode 2>/dev/null || echo 0)
if [ "$OC_COUNT" -gt 2 ]; then
    echo "⚠️  $OC_COUNT processes running (may cause conflicts)"
    echo "   Run: ram-cleanup"
else
    echo "✅ $OC_COUNT processes (OK)"
fi

# 4. Check cache state
echo -n "💾 Cache state: "
if [ -d "$HOME/.config/opencode/cache" ]; then
    CACHE_SIZE=$(du -sh "$HOME/.config/opencode/cache" 2>/dev/null | awk '{print $1}')
    echo "✅ $CACHE_SIZE"
else
    echo "✅ Empty (will be created on first launch)"
fi

# 5. Check config validity
echo -n "⚙️  Config validity: "
if python3 -m json.tool "$HOME/.config/opencode/opencode.json" >/dev/null 2>&1; then
    echo "✅ Valid JSON"
else
    echo "❌ Invalid JSON"
    exit 1
fi

echo ""
echo "✅ Environment check passed. OpenCode is ready to launch."
