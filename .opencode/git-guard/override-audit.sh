#!/usr/bin/env bash
# GitGuard Override Audit
# Reports on override-log.jsonl usage: count, recent entries, commands affected.
#
# Usage:
#   bash .opencode/git-guard/override-audit.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERRIDE_LOG="$SCRIPT_DIR/override-log.jsonl"

echo "=========================================="
echo "GitGuard Override Audit"
echo "=========================================="
echo "Date: $(date -Iseconds)"
echo "Log file: $OVERRIDE_LOG"
echo ""

if [ ! -f "$OVERRIDE_LOG" ]; then
    echo "Status: No override log found"
    echo "This means no overrides have been used since the log was created."
    echo ""
    echo "Override usage: 0"
    echo "Verdict: CLEAN — No overrides to review."
    exit 0
fi

total=$(wc -l < "$OVERRIDE_LOG")
echo "Total overrides: $total"
echo ""

if [ "$total" -eq 0 ]; then
    echo "Verdict: CLEAN — Log exists but is empty."
    exit 0
fi

# Recent entries (last 10)
echo "── Recent Overrides (last 10) ─────────────"
tail -10 "$OVERRIDE_LOG" | while IFS= read -r line; do
    # Parse JSON-like fields (simple extraction, not full JSON parsing)
    timestamp=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
    command=$(echo "$line" | grep -o '"command":"[^"]*"' | cut -d'"' -f4)
    reason=$(echo "$line" | grep -o '"reason":"[^"]*"' | cut -d'"' -f4)
    echo "  [$timestamp] $command"
    echo "    Reason: $reason"
    echo ""
done

# Commands affected
echo "── Commands Affected ──────────────────────"
grep -o '"command":"[^"]*"' "$OVERRIDE_LOG" | cut -d'"' -f4 | sed 's/ .*//' | sort | uniq -c | sort -rn | while read count cmd; do
    echo "  $count × $cmd"
done

echo ""

# Reasons summary
echo "── Reasons Given ──────────────────────────"
grep -o '"reason":"[^"]*"' "$OVERRIDE_LOG" | cut -d'"' -f4 | sort | uniq -c | sort -rn | while read count reason; do
    echo "  $count × $reason"
done

echo ""

# Verdict
if [ "$total" -le 2 ]; then
    echo "Verdict: LOW — $total override(s). Rare usage, within expected bounds."
elif [ "$total" -le 10 ]; then
    echo "Verdict: MODERATE — $total overrides. Review for patterns."
else
    echo "Verdict: HIGH — $total overrides. Investigate why overrides are frequent."
fi
