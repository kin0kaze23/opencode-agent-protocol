#!/bin/bash
# RAM Check — Quick overview of what's eating memory
# Usage: bash .opencode/scripts/ram-check.sh
# Canonical location: .opencode/scripts/ram-check.sh

echo "============================================="
echo "  MEMORY STATUS — $(date '+%H:%M:%S')"
echo "============================================="

# System overview
TOTAL_GB=$(sysctl -n hw.memsize | awk '{printf "%.0f", $1/1024/1024/1024}')
FREE_PCT=$(memory_pressure 2>/dev/null | grep "free percentage" | awk '{print $NF}' | tr -d '%')

if [ -z "$FREE_PCT" ]; then
    # Fallback calculation
    FREE_MB=$(vm_stat | awk -v ps=$(sysctl -n hw.pagesize) '
        /Pages free:/ {free=$3}
        /Pages speculative:/ {spec=$3}
        END {printf "%.0f", (free+spec)*ps/1024/1024}')
    FREE_PCT=$(echo "$FREE_MB $TOTAL_GB" | awk '{printf "%.0f", ($1/($2*1024))*100}')
fi

USED_PCT=$((100 - ${FREE_PCT:-0}))
echo ""
echo "  Total: ${TOTAL_GB}GB | Used: ~${USED_PCT}% | Free: ~${FREE_PCT:-?}%"

# Memory pressure indicator
if [ "${USED_PCT}" -gt 85 ]; then
    echo "  Status: 🔴 HIGH PRESSURE — cleanup recommended"
elif [ "${USED_PCT}" -gt 70 ]; then
    echo "  Status: 🟡 MODERATE — monitor closely"
else
    echo "  Status: 🟢 HEALTHY"
fi

echo ""
echo "  TOP MEMORY CONSUMERS:"
echo "  ─────────────────────────────────────────────"
printf "  %-25s %8s %6s\n" "APP" "MEMORY" "COUNT"
echo "  ─────────────────────────────────────────────"

# OpenCode
OC_COUNT=$(ps aux | grep "[o]pencode" | wc -l | tr -d ' ')
OC_MB=$(ps aux | grep "[o]pencode" | awk '{sum+=$6} END {printf "%.0f", sum/1024}')
if [ "$OC_COUNT" -gt 0 ]; then
    printf "  %-25s %6sMB %6s\n" "opencode" "${OC_MB}" "(${OC_COUNT} proc)"
fi

# Serve mode check
SERVE_PID=$(ps aux | grep "[o]pencode serve" | awk '{print $2}' | head -1)
if [ -n "$SERVE_PID" ]; then
    SERVE_MB=$(ps -o rss= -p $SERVE_PID 2>/dev/null | awk '{printf "%.0f", $1/1024}')
    ATTACH_COUNT=$(ps aux | grep "[o]pencode attach" | wc -l | tr -d ' ')
    printf "  %-25s %6sMB %6s\n" "  └─ serve" "${SERVE_MB}" ""
    printf "  %-25s %6sMB %6s\n" "  └─ attach clients" "" "(${ATTACH_COUNT})"
fi

# Standalone sessions (NOT serve/attach)
STANDALONE_PIDS=$(ps aux | grep "[o]pencode" | grep -v "serve\|attach" | awk '{print $2}')
if [ -n "$STANDALONE_PIDS" ]; then
    STANDALONE_COUNT=$(echo "$STANDALONE_PIDS" | wc -l | tr -d ' ')
    STANDALONE_MB=$(echo "$STANDALONE_PIDS" | xargs ps -o rss= -p 2>/dev/null | awk '{sum+=$1} END {printf "%.0f", sum/1024}')
    printf "  %-25s %6sMB %6s\n" "  ⚠️  standalone sessions" "${STANDALONE_MB}" "(${STANDALONE_COUNT})"
fi

# Brave
BRAVE_COUNT=$(ps aux | grep "[B]rave" | wc -l | tr -d ' ')
BRAVE_MB=$(ps aux | grep "[B]rave" | awk '{sum+=$6} END {printf "%.0f", sum/1024}')
if [ "$BRAVE_COUNT" -gt 0 ]; then
    printf "  %-25s %6sMB %6s\n" "Brave Browser" "${BRAVE_MB}" "(${BRAVE_COUNT} proc)"
fi

# Cursor
CURSOR_COUNT=$(ps aux | grep -i "[c]ursor" | wc -l | tr -d ' ')
CURSOR_MB=$(ps aux | grep -i "[c]ursor" | awk '{sum+=$6} END {printf "%.0f", sum/1024}')
if [ "$CURSOR_COUNT" -gt 0 ]; then
    printf "  %-25s %6sMB %6s\n" "Cursor" "${CURSOR_MB}" "(${CURSOR_COUNT} proc)"
fi

# Chrome/Chromium if present
CHROME_MB=$(ps aux | grep -i "[c]hrome" | grep -iv "cursor\|brave" | awk '{sum+=$6} END {if(sum>0) printf "%.0f", sum/1024; else print "0"}')
if [ "$CHROME_MB" -gt 0 ]; then
    CHROME_COUNT=$(ps aux | grep -i "[c]hrome" | grep -iv "cursor\|brave" | wc -l | tr -d ' ')
    printf "  %-25s %6sMB %6s\n" "Chrome" "${CHROME_MB}" "(${CHROME_COUNT} proc)"
fi

echo "  ─────────────────────────────────────────────"

# Recommendations
echo ""
if [ "${USED_PCT}" -gt 85 ]; then
    echo "  ⚠️  RECOMMENDATIONS:"
    echo "  • Close unused Brave tabs (biggest consumer after opencode)"
    if [ -n "$STANDALONE_PIDS" ]; then
        echo "  • Kill standalone opencode sessions — use serve+attach instead"
    fi
    echo "  • Run: ram-cleanup"
elif [ "${USED_PCT}" -gt 70 ]; then
    echo "  💡 TIP: Close a few browser tabs before launching new sessions"
else
    echo "  ✅ Safe to launch new opencode sessions"
fi

# OpenCode database size check
OC_DB="$HOME/.local/share/opencode/opencode.db"
if [ -f "$OC_DB" ]; then
    OC_DB_MB=$(du -m "$OC_DB" 2>/dev/null | cut -f1)
    if [ "${OC_DB_MB:-0}" -gt 500 ]; then
        echo ""
        echo "  ⚠️  OpenCode DB is ${OC_DB_MB}MB — run db-clean"
    elif [ "${OC_DB_MB:-0}" -gt 100 ]; then
        echo ""
        echo "  💡 OpenCode DB is ${OC_DB_MB}MB — consider running db-clean soon"
    fi
fi

echo ""
echo "  Quick commands:"
echo "    ram-check      — this overview"
echo "    ram-cleanup    — interactive cleanup"
echo "    ram-monitor    — background watcher"
echo "    db-clean       — opencode DB cleanup"
echo ""
