#!/usr/bin/env bash
# deploy-readiness-report.sh — v4.17.0 Deployment Readiness Report
# Purpose: Generate a machine-readable JSON report of all gate evidence,
#          preview deployment status, reviewer verdict, and rollback metadata.
#
# Usage:
#   bash .opencode/scripts/deploy-readiness-report.sh <repo> [--preview-url <url>] [--reviewer-verdict <verdict>]
#
# Output: JSON report to stdout

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

REPO=""
PREVIEW_URL=""
REVIEWER_VERDICT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --preview-url) shift; PREVIEW_URL="$1" ;;
    --reviewer-verdict) shift; REVIEWER_VERDICT="$1" ;;
    *) REPO="$1" ;;
  esac
  shift
done

if [[ -z "$REPO" ]]; then
  echo "Usage: deploy-readiness-report.sh <repo> [--preview-url <url>] [--reviewer-verdict <verdict>]" >&2
  exit 1
fi

REPO_PATH="$ROOT_DIR/$REPO"
CACHE_FILE="$ROOT_DIR/.opencode/.session-cache/cache.json"
TIMESTAMP=$(date -Iseconds 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

# Get commit info
COMMIT_SHA=$(cd "$REPO_PATH" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BRANCH=$(cd "$REPO_PATH" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
PREVIOUS_SHA=$(cd "$REPO_PATH" && git rev-parse --short HEAD~1 2>/dev/null || echo "unknown")

# Collect gate results from session cache
GATES_JSON="{}"
if [[ -f "$CACHE_FILE" ]]; then
  GATES_JSON=$(python3 -c "
import json
with open('$CACHE_FILE') as f:
    data = json.load(f)
gates = data.get('gates', {})
result = {}
for name, info in gates.items():
    result[name] = {
        'status': info.get('status', 'unknown'),
        'exit_code': info.get('exit_code', -1),
        'cached': True
    }
print(json.dumps(result))
" 2>/dev/null || echo '{}')
fi

# Check if all required gates passed
ALL_READY=$(python3 -c "
import json
gates = json.loads('$GATES_JSON')
if not gates:
    print('false')
    exit()
required = ['lint', 'typecheck', 'test', 'build']
all_pass = all(gates.get(g, {}).get('status') == 'pass' for g in required)
print('true' if all_pass else 'false')
" 2>/dev/null || echo "false")

# Generate report
python3 -c "
import json, sys

report = {
    'repo': '$REPO',
    'branch': '$BRANCH',
    'commit': '$COMMIT_SHA',
    'previous_commit': '$PREVIOUS_SHA',
    'timestamp': '$TIMESTAMP',
    'ready': $( [[ "$ALL_READY" == "true" ]] && echo "True" || echo "False" ),
    'gates': json.loads('$GATES_JSON'),
    'preview': {
        'url': '$PREVIEW_URL' if '$PREVIEW_URL' else None,
        'smoke': None
    },
    'reviewer': {
        'verdict': '$REVIEWER_VERDICT' if '$REVIEWER_VERDICT' else None
    },
    'rollback': {
        'type': 'revert-commit',
        'previous_sha': '$PREVIOUS_SHA',
        'command': f'git revert $COMMIT_SHA',
        'verify': f'curl -I https://$REPO.vercel.app' if '$REPO' else 'N/A'
    }
}
print(json.dumps(report, indent=2))
"
