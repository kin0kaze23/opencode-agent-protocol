#!/usr/bin/env bash
# session-cache.sh — v4.17.0 Session Cache
# Purpose: Track gate results, file hashes, and browser preflight results within a session
#          to avoid redundant re-reads and re-runs.
#
# Usage:
#   bash .opencode/scripts/session-cache.sh init <repo>
#   bash .opencode/scripts/session-cache.sh gate-get <gate_name>
#   bash .opencode/scripts/session-cache.sh gate-set <gate_name> <pass|fail> <exit_code>
#   bash .opencode/scripts/session-cache.sh gate-skip <gate_name> <reason>
#   bash .opencode/scripts/session-cache.sh file-hash <file_path>
#   bash .opencode/scripts/session-cache.sh file-changed <file_path>
#   bash .opencode/scripts/session-cache.sh preflight-get
#   bash .opencode/scripts/session-cache.sh preflight-set <route>
#   bash .opencode/scripts/session-cache.sh invalidate <reason>
#   bash .opencode/scripts/session-cache.sh summary

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CACHE_DIR="$ROOT_DIR/.opencode/.session-cache"
CACHE_FILE="$CACHE_DIR/cache.json"

# Ensure cache directory exists
init_cache() {
  mkdir -p "$CACHE_DIR"
  if [[ ! -f "$CACHE_FILE" ]]; then
    cat > "$CACHE_FILE" << 'EOF'
{
  "session_id": "",
  "repo": "",
  "created_at": "",
  "gates": {},
  "files": {},
  "preflight": null,
  "invalidations": []
}
EOF
  fi
}

# Get current source hash for a repo (hash of all non-.md tracked files)
get_source_hash() {
  local repo_path="${1:-.}"
  local hash
  hash=$(cd "$repo_path" && git ls-files -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.css' '*.scss' '*.py' '*.rs' '*.json' 2>/dev/null | head -100 | xargs shasum 2>/dev/null | shasum | cut -d' ' -f1)
  echo "${hash:-empty}"
}

# Initialize session cache for a repo
cmd_init() {
  local repo="${1:-}"
  if [[ -z "$repo" ]]; then
    echo "Usage: session-cache.sh init <repo>" >&2
    exit 1
  fi
  init_cache
  local source_hash
  source_hash=$(get_source_hash "$ROOT_DIR/$repo" 2>/dev/null || echo "empty")
  local timestamp
  timestamp=$(date -Iseconds 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
  # Use python3 for portable JSON manipulation
  python3 -c "
import json, sys
with open('$CACHE_FILE') as f:
    data = json.load(f)
data['session_id'] = '$timestamp'
data['repo'] = '$repo'
data['created_at'] = '$timestamp'
data['source_hash'] = '$source_hash'
data['gates'] = {}
data['files'] = {}
data['preflight'] = None
data['invalidations'] = []
with open('$CACHE_FILE', 'w') as f:
    json.dump(data, f, indent=2)
repo_name = '$repo'
src_hash = '$source_hash'
print(f'Session cache initialized for {repo_name} (source_hash: {src_hash[:8]})')
"
}

# Get gate result
cmd_gate_get() {
  local gate_name="${1:-}"
  if [[ -z "$gate_name" ]]; then
    echo "Usage: session-cache.sh gate-get <gate_name>" >&2
    exit 1
  fi
  init_cache
  python3 -c "
import json
with open('$CACHE_FILE') as f:
    data = json.load(f)
gate = data.get('gates', {}).get('$gate_name')
if gate:
    print(f\"{gate['status']}|{gate.get('exit_code', 'N/A')}|{gate.get('timestamp', 'N/A')}|{gate.get('source_hash', 'N/A')[:8]}\")
else:
    print('NOT_CACHED')
"
}

# Set gate result
cmd_gate_set() {
  local gate_name="${1:-}"
  local status="${2:-}"
  local exit_code="${3:-0}"
  if [[ -z "$gate_name" || -z "$status" ]]; then
    echo "Usage: session-cache.sh gate-set <gate_name> <pass|fail> <exit_code>" >&2
    exit 1
  fi
  init_cache
  local repo
  repo=$(python3 -c "import json; print(json.load(open('$CACHE_FILE')).get('repo', ''))" 2>/dev/null || echo "")
  local source_hash
  source_hash=$(get_source_hash "$ROOT_DIR/$repo" 2>/dev/null || echo "empty")
  local timestamp
  timestamp=$(date -Iseconds 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
  python3 -c "
import json
with open('$CACHE_FILE') as f:
    data = json.load(f)
data.setdefault('gates', {})['$gate_name'] = {
    'status': '$status',
    'exit_code': $exit_code,
    'timestamp': '$timestamp',
    'source_hash': '$source_hash'
}
with open('$CACHE_FILE', 'w') as f:
    json.dump(data, f, indent=2)
print(f'Gate $gate_name: $status (exit $exit_code)')
"
}

# Check if gate can be skipped (source unchanged since last pass)
cmd_gate_skip() {
  local gate_name="${1:-}"
  local reason="${2:-no reason provided}"
  if [[ -z "$gate_name" ]]; then
    echo "Usage: session-cache.sh gate-skip <gate_name> <reason>" >&2
    exit 1
  fi
  init_cache
  local repo
  repo=$(python3 -c "import json; print(json.load(open('$CACHE_FILE')).get('repo', ''))" 2>/dev/null || echo "")
  local current_hash
  current_hash=$(get_source_hash "$ROOT_DIR/$repo" 2>/dev/null || echo "empty")
  python3 -c "
import json, sys
with open('$CACHE_FILE') as f:
    data = json.load(f)
gate = data.get('gates', {}).get('$gate_name')
if not gate:
    print('NOT_CACHED')
    sys.exit(0)
if gate['status'] == 'pass' and gate.get('source_hash', '') == '$current_hash':
    print(f'CACHED|{gate.get(\"timestamp\", \"\")}|$reason')
else:
    print('STALE')
"
}

# Get file hash
cmd_file_hash() {
  local file_path="${1:-}"
  if [[ -z "$file_path" ]]; then
    echo "Usage: session-cache.sh file-hash <file_path>" >&2
    exit 1
  fi
  init_cache
  if [[ ! -f "$file_path" ]]; then
    echo "FILE_NOT_FOUND"
    exit 0
  fi
  local hash
  hash=$(shasum "$file_path" 2>/dev/null | cut -d' ' -f1 || echo "error")
  echo "$hash"
}

# Check if file changed since last read
cmd_file_changed() {
  local file_path="${1:-}"
  if [[ -z "$file_path" ]]; then
    echo "Usage: session-cache.sh file-changed <file_path>" >&2
    exit 1
  fi
  init_cache
  if [[ ! -f "$file_path" ]]; then
    echo "FILE_NOT_FOUND"
    exit 0
  fi
  local current_hash
  current_hash=$(shasum "$file_path" 2>/dev/null | cut -d' ' -f1 || echo "error")
  python3 -c "
import json
with open('$CACHE_FILE') as f:
    data = json.load(f)
files = data.get('files', {})
key = '$file_path'
if key not in files:
    print(f'NEW_FILE|{current_hash}')
else:
    cached_hash = files[key].get('hash', '')
    if cached_hash == '$current_hash':
        print(f'UNCHANGED|{cached_hash}')
    else:
        print(f'CHANGED|{cached_hash}|{current_hash}')
"
}

# Record file read (update hash)
cmd_file_record() {
  local file_path="${1:-}"
  if [[ -z "$file_path" ]]; then
    echo "Usage: session-cache.sh file-record <file_path>" >&2
    exit 1
  fi
  init_cache
  if [[ ! -f "$file_path" ]]; then
    exit 0
  fi
  local hash
  hash=$(shasum "$file_path" 2>/dev/null | cut -d' ' -f1 || echo "error")
  local timestamp
  timestamp=$(date -Iseconds 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
  python3 -c "
import json
with open('$CACHE_FILE') as f:
    data = json.load(f)
data.setdefault('files', {})['$file_path'] = {
    'hash': '$hash',
    'read_at': '$timestamp'
}
with open('$CACHE_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
}

# Get browser preflight result
cmd_preflight_get() {
  init_cache
  python3 -c "
import json
with open('$CACHE_FILE') as f:
    data = json.load(f)
pf = data.get('preflight')
if pf:
    print(f'{pf.get(\"route\", \"NOT_RUN\")}|{pf.get(\"timestamp\", \"\")}')
else:
    print('NOT_CACHED')
"
}

# Set browser preflight result
cmd_preflight_set() {
  local route="${1:-}"
  if [[ -z "$route" ]]; then
    echo "Usage: session-cache.sh preflight-set <route>" >&2
    exit 1
  fi
  init_cache
  local timestamp
  timestamp=$(date -Iseconds 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
  python3 -c "
import json
with open('$CACHE_FILE') as f:
    data = json.load(f)
data['preflight'] = {
    'route': '$route',
    'timestamp': '$timestamp'
}
with open('$CACHE_FILE', 'w') as f:
    json.dump(data, f, indent=2)
print(f'Preflight cached: $route')
"
}

# Invalidate cache
cmd_invalidate() {
  local reason="${1:-manual}"
  init_cache
  local timestamp
  timestamp=$(date -Iseconds 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
  python3 -c "
import json
with open('$CACHE_FILE') as f:
    data = json.load(f)
data['gates'] = {}
data['invalidations'].append({'reason': '$reason', 'timestamp': '$timestamp'})
with open('$CACHE_FILE', 'w') as f:
    json.dump(data, f, indent=2)
print(f'Cache invalidated: $reason')
"
}

# Print summary
cmd_summary() {
  init_cache
  python3 -c "
import json
with open('$CACHE_FILE') as f:
    data = json.load(f)
print('=== Session Cache Summary ===')
print(f'Repo: {data.get(\"repo\", \"N/A\")}')
print(f'Session: {data.get(\"session_id\", \"N/A\")}')
gates = data.get('gates', {})
print(f'Gates cached: {len(gates)}')
for name, info in gates.items():
    print(f'  {name}: {info[\"status\"]} (exit {info.get(\"exit_code\", \"N/A\")}) at {info.get(\"timestamp\", \"\")[:19]}')
files = data.get('files', {})
print(f'Files tracked: {len(files)}')
pf = data.get('preflight')
if pf:
    print(f'Preflight: {pf.get(\"route\", \"N/A\")} at {pf.get(\"timestamp\", \"\")[:19]}')
else:
    print('Preflight: NOT_CACHED')
invals = data.get('invalidations', [])
if invals:
    print(f'Invalidations: {len(invals)}')
    for inv in invals[-3:]:
        print(f'  {inv.get(\"reason\", \"\")} at {inv.get(\"timestamp\", \"\")[:19]}')
"
}

# Main command dispatch
case "${1:-help}" in
  init) shift; cmd_init "$@" ;;
  gate-get) shift; cmd_gate_get "$@" ;;
  gate-set) shift; cmd_gate_set "$@" ;;
  gate-skip) shift; cmd_gate_skip "$@" ;;
  file-hash) shift; cmd_file_hash "$@" ;;
  file-changed) shift; cmd_file_changed "$@" ;;
  file-record) shift; cmd_file_record "$@" ;;
  preflight-get) shift; cmd_preflight_get "$@" ;;
  preflight-set) shift; cmd_preflight_set "$@" ;;
  invalidate) shift; cmd_invalidate "$@" ;;
  summary) cmd_summary ;;
  help|*)
    cat << 'USAGE'
session-cache.sh — v4.17.0 Session Cache

Commands:
  init <repo>                    Initialize session cache for a repo
  gate-get <name>                Get cached gate result
  gate-set <name> <pass|fail> <exit>  Record gate result
  gate-skip <name> <reason>      Check if gate can be skipped (source unchanged)
  file-hash <path>               Get file hash
  file-changed <path>            Check if file changed since last read
  file-record <path>             Record file read (update hash)
  preflight-get                   Get cached browser preflight result
  preflight-set <route>          Cache browser preflight result
  invalidate <reason>            Invalidate all gate caches
  summary                        Print cache summary
USAGE
    ;;
esac
