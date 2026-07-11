#!/bin/bash
# oc-clean.sh — Clean up orphaned OpenCode processes
# Usage: bash .opencode/scripts/oc-clean.sh [--force]
# Canonical location: .opencode/scripts/oc-clean.sh
#
# Run this when you have multiple 'opencode attach' processes

set -e

FORCE=0
if [ "$1" == "--force" ]; then
    FORCE=1
fi

echo "🧹 OpenCode Process Cleanup"
echo "============================"
echo ""

# Count attach processes
ATTACH_COUNT=$(ps aux | grep "opencode attach" | grep -v grep | wc -l | tr -d ' ')

if [ "$ATTACH_COUNT" -le 1 ]; then
    echo "✅ No cleanup needed ($ATTACH_COUNT attach process)"
    echo ""
    echo "Processes:"
    ps aux | grep "opencode" | grep -v grep | head -5
    exit 0
fi

echo "⚠️  Found $ATTACH_COUNT attach processes (expected: 1)"
echo ""

# Show the processes with timing
echo "Current processes (oldest first):"
ps aux | grep "opencode attach" | grep -v grep | sort -k9 -n | head -10
echo ""

# Kill ALL attach processes and let user restart fresh
echo "🛑 Stopping ALL attach processes..."
ps aux | grep "opencode attach" | grep -v grep | awk '{print $2}' | xargs kill 2>/dev/null || true
sleep 2

# Verify
REMAINING=$(ps aux | grep "opencode attach" | grep -v grep | wc -l | tr -d ' ')
echo "✅ Remaining: $REMAINING attach processes"
echo ""

# Show what's left (should be just server)
echo "Remaining processes:"
ps aux | grep "opencode" | grep -v grep | head -5
echo ""

echo "============================"
echo "✅ Cleanup Complete!"
echo ""
echo "To restart fresh: oc-fresh"
echo "To attach to server: oc"
echo ""
