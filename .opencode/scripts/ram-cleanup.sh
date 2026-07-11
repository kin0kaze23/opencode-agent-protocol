#!/bin/bash
# RAM Cleanup — Interactive cleanup to free memory fast
# Usage: bash .opencode/scripts/ram-cleanup.sh
# Canonical location: .opencode/scripts/ram-cleanup.sh

echo "============================================="
echo "  RAM CLEANUP — $(date '+%H:%M:%S')"
echo "============================================="

FREED=0

# Step 1: Check for standalone opencode sessions (not serve/attach)
echo ""
echo "Step 1: Checking for standalone opencode sessions..."
STANDALONE_PIDS=$(pgrep opencode 2>/dev/null | while read pid; do
    cmd=$(ps -o command= -p $pid 2>/dev/null)
    if [[ "$cmd" != *"serve"* && "$cmd" != *"attach"* ]]; then
        echo $pid
    fi
done)

if [ -n "$STANDALONE_PIDS" ]; then
    STANDALONE_MB=$(echo "$STANDALONE_PIDS" | xargs ps -o rss= -p 2>/dev/null | awk '{sum+=$1} END {printf "%.0f", sum/1024}')
    STANDALONE_COUNT=$(echo "$STANDALONE_PIDS" | wc -l | tr -d ' ')
    echo "  Found ${STANDALONE_COUNT} standalone sessions using ${STANDALONE_MB}MB"
    echo "  PIDs: $(echo $STANDALONE_PIDS | tr '\n' ' ')"
    read -p "  Kill standalone sessions? (y/N): " confirm
    if [[ $confirm == [Yy] ]]; then
        echo "$STANDALONE_PIDS" | xargs kill 2>/dev/null
        FREED=$((FREED + STANDALONE_MB))
        echo "  ✅ Killed standalone sessions (${STANDALONE_MB}MB freed)"
    fi
else
    echo "  ✅ No standalone sessions found"
fi

# Step 2: Clear macOS file cache
echo ""
echo "Step 2: Clearing macOS file cache..."
BEFORE_FREE=$(vm_stat | awk '/Pages free:/ {print $3}')
sudo purge 2>/dev/null
AFTER_FREE=$(vm_stat | awk '/Pages free:/ {print $3}')
CACHE_FREED=$(( (AFTER_FREE - BEFORE_FREE) * $(sysctl -n hw.pagesize) / 1024 / 1024 ))
echo "  ✅ Cache cleared (~${CACHE_FREED}MB freed)"
FREED=$((FREED + CACHE_FREED))

# Step 3: Suggest browser tab cleanup
echo ""
echo "Step 3: Browser tabs..."
BRAVE_TABS=$(pgrep -c -f "Brave Browser Helper (Renderer)" 2>/dev/null || echo 0)
if [ "$BRAVE_TABS" -gt 15 ]; then
    BRAVE_MB=$(ps aux | grep "[B]rave" | awk '{sum+=$6} END {printf "%.0f", sum/1024}')
    echo "  ⚠️  You have ~${BRAVE_TABS} Brave tabs using ${BRAVE_MB}MB"
    echo "  💡 Close unused tabs in Brave to free 500MB-1GB+"
else
    echo "  ✅ Browser tabs reasonable (${BRAVE_TABS} tabs)"
fi

# Step 4: Check for zombie opencode processes
echo ""
echo "Step 4: Checking for zombie opencode processes..."
ZOMBIES=$(pgrep opencode 2>/dev/null | while read pid; do
    state=$(ps -o state= -p $pid 2>/dev/null)
    if [[ "$state" == "Z" ]]; then
        echo $pid
    fi
done)
if [ -n "$ZOMBIES" ]; then
    echo "  Found zombie processes: $ZOMBIES"
    echo "  These should clear on their own, or restart terminal"
else
    echo "  ✅ No zombie processes"
fi

# Summary
echo ""
echo "============================================="
echo "  CLEANUP COMPLETE"
echo "  Total freed: ~${FREED}MB"
echo "============================================="
echo ""

# Show current state
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/ram-check.sh" 2>/dev/null | grep -A3 "Status:"
