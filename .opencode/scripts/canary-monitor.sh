#!/usr/bin/env bash
# canary-monitor.sh — v4.19.0 DIRECT Lane Canary Monitoring (v2)
# Purpose: Track canary metrics for DIRECT lane routing to umans-flash
# Usage:
#   bash .opencode/scripts/canary-monitor.sh --report    # Generate weekly report
#   bash .opencode/scripts/canary-monitor.sh --status    # Check current status
#   bash .opencode/scripts/canary-monitor.sh --add <task_id> <duration_ms> <result> [escalated] [retry_count] [tokens] [task_type]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DATA_DIR="$ROOT_DIR/vault/protocols/opencode/evals/canary-data"
REPORT_DIR="$ROOT_DIR/vault/protocols/opencode"

# Create data directory if it doesn't exist
mkdir -p "$DATA_DIR"

# Parse arguments
MODE=""
TASK_ID=""
DURATION_MS=""
RESULT=""
ESCALATED="false"
RETRY_COUNT="0"
TOKENS="0"
TASK_TYPE="unknown"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --report) MODE="report"; shift ;;
    --status) MODE="status"; shift ;;
    --add) MODE="add"; shift ;;
    *)
      if [[ -z "$TASK_ID" ]]; then
        TASK_ID="$1"
      elif [[ -z "$DURATION_MS" ]]; then
        DURATION_MS="$1"
      elif [[ -z "$RESULT" ]]; then
        RESULT="$1"
      elif [[ "$ESCALATED" == "false" && ("$1" == "true" || "$1" == "false") ]]; then
        ESCALATED="$1"
      elif [[ "$RETRY_COUNT" == "0" ]]; then
        RETRY_COUNT="$1"
      elif [[ "$TOKENS" == "0" ]]; then
        TOKENS="$1"
      elif [[ "$TASK_TYPE" == "unknown" ]]; then
        TASK_TYPE="$1"
      fi
      shift
      ;;
  esac
done

# Add new canary record
if [[ "$MODE" == "add" ]]; then
  if [[ -z "$TASK_ID" || -z "$DURATION_MS" || -z "$RESULT" ]]; then
    echo "Usage: canary-monitor.sh --add <task_id> <duration_ms> <result> [escalated] [retry_count] [tokens] [task_type]"
    echo ""
    echo "Task types: docs_only, comments_docs, no_changes, config_readonly, style_trivial"
    exit 1
  fi

  # Use Python to safely add record to JSON
  python3 -c "
import json, os
from datetime import datetime

task_id = '$TASK_ID'
duration_ms = int('$DURATION_MS')
result = '$RESULT'
escalated = '$ESCALATED' == 'true'
retry_count = int('$RETRY_COUNT')
tokens = int('$TOKENS')
task_type = '$TASK_TYPE'

record = {
    'task_id': task_id,
    'timestamp': datetime.now().isoformat(),
    'duration_ms': duration_ms,
    'result': result,
    'escalated': escalated,
    'retry_count': retry_count,
    'tokens': tokens,
    'model': 'umans-flash',
    'lane': 'DIRECT',
    'task_type': task_type
}

# Get current week file
week = datetime.now().strftime('%Y-W%V')
data_dir = '$DATA_DIR'
file_path = os.path.join(data_dir, f'direct-canary-{week}.json')

# Load existing records or create new list
if os.path.exists(file_path):
    with open(file_path, 'r') as f:
        records = json.load(f)
else:
    records = []

# Add new record
records.append(record)

# Save back
with open(file_path, 'w') as f:
    json.dump(records, f, indent=2)

print(f'Record added: {task_id}')
"

  exit 0
fi

# Generate status report
if [[ "$MODE" == "status" ]]; then
  echo "=== v4.19.0 DIRECT Lane Canary Status ==="
  echo ""

  # Find current week's data
  WEEK=$(date +%Y-W%V)
  FILE="$DATA_DIR/direct-canary-$WEEK.json"

  if [[ ! -f "$FILE" ]]; then
    echo "No canary data for week $WEEK"
    echo "Start recording tasks with: canary-monitor.sh --add <task_id> <duration_ms> <result>"
    exit 0
  fi

  # Analyze data
  python3 -c "
import json, sys
import statistics

with open('$FILE') as f:
    records = json.load(f)

total = len(records)
if total == 0:
    print('No records found')
    sys.exit(0)

passes = sum(1 for r in records if r.get('result') == 'pass')
durations = [r.get('duration_ms', 0) for r in records if r.get('duration_ms', 0) > 0]
escalated = sum(1 for r in records if r.get('escalated') == True)
retried = sum(1 for r in records if r.get('retry_count', 0) > 0)
tokens = [r.get('tokens', 0) for r in records if r.get('tokens', 0) > 0]

pass_rate = passes / total * 100 if total else 0
avg_duration = sum(durations) / len(durations) if durations else 0
median_duration = statistics.median(durations) if durations else 0
p95_duration = sorted(durations)[int(len(durations) * 0.95)] if len(durations) >= 20 else max(durations) if durations else 0
escalation_rate = escalated / total * 100 if total else 0
retry_rate = retried / total * 100 if total else 0
total_tokens = sum(tokens)
token_count = len(tokens)

print(f'Total tasks: {total}')
print(f'Pass rate: {pass_rate:.1f}% (target: ≥ 95%)')
print(f'Avg duration: {avg_duration:.0f}ms (target: ≤ 800ms)')
print(f'Median duration: {median_duration:.0f}ms (target: ≤ 800ms)')
print(f'P95 duration: {p95_duration:.0f}ms (target: ≤ 1000ms)')
print(f'Escalation rate: {escalation_rate:.1f}% (target: < 20%)')
print(f'Retry rate: {retry_rate:.1f}% (target: < 5%)')
if token_count > 0:
    print(f'Token usage: {total_tokens} total ({token_count} tasks with data)')
else:
    print(f'Token usage: UNKNOWN (no data collected)')
print()

# Check rollback triggers
issues = []
if pass_rate < 90:
    issues.append(f'CRITICAL: Pass rate {pass_rate:.1f}% < 90%')
if avg_duration > 1000:
    issues.append(f'CRITICAL: Avg duration {avg_duration:.0f}ms > 1000ms')
if median_duration > 800:
    issues.append(f'WARNING: Median duration {median_duration:.0f}ms > 800ms')
if retry_rate > 5:
    issues.append(f'WARNING: Retry rate {retry_rate:.1f}% > 5%')
if escalation_rate > 20:
    issues.append(f'WARNING: Escalation rate {escalation_rate:.1f}% > 20%')

if issues:
    print('ROLLBACK TRIGGERS:')
    for issue in issues:
        print(f'  - {issue}')
else:
    print('Status: NO ROLLBACK TRIGGERS')
"

  exit 0
fi

# Generate weekly report
if [[ "$MODE" == "report" ]]; then
  echo "=== v4.19.0 DIRECT Lane Canary Weekly Report ==="
  echo ""

  # Find current week's data
  WEEK=$(date +%Y-W%V)
  FILE="$DATA_DIR/direct-canary-$WEEK.json"

  if [[ ! -f "$FILE" ]]; then
    echo "No canary data for week $WEEK"
    exit 0
  fi

  # Generate report
  python3 -c "
import json, sys
import statistics
from datetime import datetime

with open('$FILE') as f:
    records = json.load(f)

total = len(records)
if total == 0:
    print('No records found')
    sys.exit(0)

passes = sum(1 for r in records if r.get('result') == 'pass')
fails = total - passes
durations = [r.get('duration_ms', 0) for r in records if r.get('duration_ms', 0) > 0]
escalated = sum(1 for r in records if r.get('escalated') == True)
retried = sum(1 for r in records if r.get('retry_count', 0) > 0)
tokens = [r.get('tokens', 0) for r in records if r.get('tokens', 0) > 0]

pass_rate = passes / total * 100 if total else 0
avg_duration = sum(durations) / len(durations) if durations else 0
median_duration = statistics.median(durations) if durations else 0
p95_duration = sorted(durations)[int(len(durations) * 0.95)] if len(durations) >= 20 else max(durations) if durations else 0
escalation_rate = escalated / total * 100 if total else 0
retry_rate = retried / total * 100 if total else 0
total_tokens = sum(tokens)
token_count = len(tokens)

# Determine status
status = 'PASS'
issues = []
if pass_rate < 95:
    status = 'FAIL'
    issues.append(f'Pass rate {pass_rate:.1f}% < 95%')
if avg_duration > 800:
    status = 'FAIL'
    issues.append(f'Avg duration {avg_duration:.0f}ms > 800ms')
if retry_rate > 5:
    status = 'FAIL'
    issues.append(f'Retry rate {retry_rate:.1f}% > 5%')
if escalation_rate > 20:
    status = 'FAIL'
    issues.append(f'Escalation rate {escalation_rate:.1f}% > 20%')

# Check if token data is complete
token_status = 'COMPLETE' if token_count > 0 else 'UNKNOWN'
if token_count == 0:
    status = 'HOLD'
    issues.append('Token data not collected — cannot verify cost savings')

print(f'# v4.19.0 DIRECT Canary Week {datetime.now().strftime(\"%W\")} Report')
print()
print(f'**Date:** {datetime.now().strftime(\"%Y-%m-%d\")}')
print(f'**Status:** {status}')
print()
print('## Metrics Summary')
print()
print('| Metric | Target | Actual | Status |')
print('|--------|--------|--------|--------|')
print(f'| Pass rate | ≥ 95% | {pass_rate:.1f}% | {\"PASS\" if pass_rate >= 95 else \"FAIL\"} |')
print(f'| Duration (avg) | ≤ 800ms | {avg_duration:.0f}ms | {\"PASS\" if avg_duration <= 800 else \"FAIL\"} |')
print(f'| Duration (median) | ≤ 800ms | {median_duration:.0f}ms | {\"PASS\" if median_duration <= 800 else \"FAIL\"} |')
print(f'| Duration (P95) | ≤ 1000ms | {p95_duration:.0f}ms | {\"PASS\" if p95_duration <= 1000 else \"FAIL\"} |')
print(f'| Retry rate | < 5% | {retry_rate:.1f}% | {\"PASS\" if retry_rate < 5 else \"FAIL\"} |')
print(f'| Escalation rate | < 20% | {escalation_rate:.1f}% | {\"PASS\" if escalation_rate < 20 else \"FAIL\"} |')
print(f'| Token cost | 30-50% reduction | {\"{0} total ({1} tasks)\".format(total_tokens, token_count) if token_count > 0 else \"UNKNOWN\"} | {token_status} |')
print()
print('## Task Summary')
print()
print(f'- Total DIRECT tasks: {total}')
print(f'- Successful: {passes}')
print(f'- Failed: {fails}')
print(f'- Retried: {retried}')
print(f'- Escalated: {escalated}')
print()
print('## Task Type Breakdown')
print()
task_types = {}
for r in records:
    tt = r.get('task_type', 'unknown')
    task_types[tt] = task_types.get(tt, 0) + 1
for tt, count in sorted(task_types.items()):
    print(f'- {tt}: {count}')
print()
print('## Issues/Anomalies')
print()
if issues:
    for issue in issues:
        print(f'- {issue}')
else:
    print('- None')
print()
print('## Decision')
print()
if status == 'PASS':
    print('- [x] PASS → Proceed to FAST lane canary (Week 2)')
    print('- [ ] HOLD → Extend monitoring')
    print('- [ ] FAIL → Rollback to v4.18.3')
elif status == 'HOLD':
    print('- [ ] PASS → Proceed to FAST lane canary (Week 2)')
    print('- [x] HOLD → Extend monitoring (token data incomplete)')
    print('- [ ] FAIL → Rollback to v4.18.3')
else:
    print('- [ ] PASS → Proceed to FAST lane canary (Week 2)')
    print('- [ ] HOLD → Extend monitoring')
    print('- [x] FAIL → Rollback to v4.18.3')
print()
print('---')
print()
print('*Generated by canary-monitor.sh v2*')
"

  exit 0
fi

# Default: show usage
echo "Usage:"
echo "  canary-monitor.sh --add <task_id> <duration_ms> <result> [escalated] [retry_count] [tokens] [task_type]"
echo "  canary-monitor.sh --status"
echo "  canary-monitor.sh --report"
echo ""
echo "Task types:"
echo "  docs_only        - README updates, documentation"
echo "  comments_docs    - Adding documentation comments"
echo "  no_changes       - Read-only verification"
echo "  config_readonly  - Config file inspection"
echo "  style_trivial    - Non-visible CSS/formatting (trivial only)"
echo ""
echo "Examples:"
echo "  canary-monitor.sh --add task-001 650 pass false 0 0 docs_only"
echo "  canary-monitor.sh --add task-002 720 pass false 0 1500 comments_docs"
echo "  canary-monitor.sh --add task-003 580 pass true 0 1200 config_readonly"
echo "  canary-monitor.sh --status"
echo "  canary-monitor.sh --report"
echo ""
echo "Escalation triggers (escalate to umans-coder):"
echo "  - 4+ files changed"
echo "  - Sensitive paths (auth/security/payment/schema)"
echo "  - Logic changes"
echo "  - Type/interface changes"
echo "  - Test failures"
echo "  - Visual/UI changes"
echo "  - Ambiguous diffs"
