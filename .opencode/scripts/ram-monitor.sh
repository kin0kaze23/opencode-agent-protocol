#!/bin/bash
# RAM Monitor — Background watcher that alerts on high memory
# Usage: bash .opencode/scripts/ram-monitor.sh
# Canonical location: .opencode/scripts/ram-monitor.sh
# Runs in foreground. Use Ctrl+C to stop.
# Or run in background: bash .opencode/scripts/ram-monitor.sh &

WARN_PCT=80
CRIT_PCT=90
CHECK_INTERVAL=30  # seconds
LOG_FILE="$HOME/.opencode/ram-monitor.log"

mkdir -p "$(dirname "$LOG_FILE")"

echo "============================================="
echo "  RAM MONITOR — watching every ${CHECK_INTERVAL}s"
echo "  Warn at ${WARN_PCT}% | Critical at ${CRIT_PCT}%"
echo "  Log: ${LOG_FILE}"
echo "  Ctrl+C to stop"
echo "============================================="

last_alert=0

while true; do
    # Get memory usage
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
    NOW=$(date +%s)
    TIMESTAMP=$(date '+%H:%M:%S')

    # Log entry
    OC_COUNT=$(pgrep -c opencode 2>/dev/null || echo 0)
    echo "${TIMESTAMP} | ${USED_PCT}% used | ${OC_COUNT} opencode procs" >> "$LOG_FILE"

    # Alert logic (don't spam — max once per 5 minutes)
    if [ "$USED_PCT" -ge "$CRIT_PCT" ] && [ $((NOW - last_alert)) -gt 300 ]; then
        echo ""
        echo "🔴 CRITICAL: ${USED_PCT}% memory used at ${TIMESTAMP}"
        echo "   OpenCode processes: ${OC_COUNT}"
        echo "   Run: ram-cleanup"

        # macOS notification
        osascript -e "display notification \"Memory at ${USED_PCT}% — run ram-cleanup\" with title \"RAM Alert\" subtitle \"Critical pressure\" sound name \"Basso\"" 2>/dev/null

        last_alert=$NOW

    elif [ "$USED_PCT" -ge "$WARN_PCT" ] && [ $((NOW - last_alert)) -gt 300 ]; then
        echo ""
        echo "🟡 WARNING: ${USED_PCT}% memory used at ${TIMESTAMP}"
        echo "   OpenCode processes: ${OC_COUNT}"

        # macOS notification
        osascript -e "display notification \"Memory at ${USED_PCT}% — consider cleanup\" with title \"RAM Warning\"" 2>/dev/null

        last_alert=$NOW
    fi

    sleep $CHECK_INTERVAL
done
