#!/usr/bin/env bash
# benchmark-telemetry.sh — v4.18.2
# Purpose: Capture gate execution telemetry (timing, cache behavior, diff classification)
# Usage:
#   bash .opencode/scripts/benchmark-telemetry.sh <repo> [--parallel] [--report] [--integrity-report]
#
# Modes:
#   Default: Run gates with telemetry capture
#   --parallel: Run lint+typecheck+test in parallel
#   --report: Generate aggregated evidence report from captured data
#   --integrity-report: Generate telemetry integrity report (usable/excluded records, repo health matrix)
#
# v4.18.1: Added failure_classification (pass, fail_new, fail_pre_existing, not_run, cached)
# v4.18.2: Added skip_reason, usable_for_routing, gate-health baseline lookup, integrity report, 10 statuses

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

REPO=""
MODE="run"
PARALLEL=false
OVERRIDE_LANE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --parallel) PARALLEL=true; shift ;;
    --report) MODE="report"; shift ;;
    --integrity-report) MODE="integrity"; shift ;;
    --lane) OVERRIDE_LANE="$2"; shift 2 ;;
    *) REPO="$1"; shift ;;
  esac
done

if [[ "$MODE" == "report" ]]; then
  # Generate evidence report from captured data
  DATA_DIR="$ROOT_DIR/vault/protocols/opencode/evals/benchmark-data"
  REPORT_DIR="$ROOT_DIR/vault/protocols/opencode/evals/benchmark-reports"
  mkdir -p "$REPORT_DIR"
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  REPORT_FILE="$REPORT_DIR/benchmark-report-${TIMESTAMP}.md"

  echo "# Benchmark Telemetry Report" > "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Generated:** $(date -Iseconds)" >> "$REPORT_FILE"
  echo "**Data source:** \`vault/protocols/opencode/evals/benchmark-data/\`" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"

  if [[ ! -d "$DATA_DIR" ]] || [[ -z "$(ls "$DATA_DIR"/*.json 2>/dev/null)" ]]; then
    echo "## No Data" >> "$REPORT_FILE"
    echo "No benchmark data found. Run \`benchmark-telemetry.sh <repo>\` first." >> "$REPORT_FILE"
    cat "$REPORT_FILE"
    exit 0
  fi

  # Aggregate data using python3
  python3 -c "
import json, glob, os
from collections import defaultdict

data_dir = '$DATA_DIR'
records = []
for f in sorted(glob.glob(os.path.join(data_dir, '*.json'))):
    try:
        with open(f) as fh:
            records.extend(json.load(fh))
    except:
        pass

if not records:
    print('## No Data')
    print('No valid records found.')
    exit(0)

print('## Summary')
print(f'- Total gate executions: {len(records)}')
print(f'- Repos benchmarked: {len(set(r.get(\"repo\",\"?\") for r in records))}')
print(f'- Unique gates: {len(set(r.get(\"gate\",\"?\") for r in records))}')
print()

# By repo
print('## By Repo')
by_repo = defaultdict(list)
for r in records:
    by_repo[r.get('repo','?')].append(r)
for repo, recs in sorted(by_repo.items()):
    durations = [r.get('duration_ms',0) for r in recs]
    passes = sum(1 for r in recs if r.get('result') == 'pass')
    cached = sum(1 for r in recs if r.get('cache_hit') == True)
    avg_dur = sum(durations) / len(durations) if durations else 0
    print(f'| {repo} | executions: {len(recs)} | pass: {passes} | cached: {cached} | avg_ms: {avg_dur:.0f} |')
print()

# By gate
print('## By Gate')
by_gate = defaultdict(list)
for r in records:
    by_gate[r.get('gate','?')].append(r)
for gate, recs in sorted(by_gate.items()):
    durations = [r.get('duration_ms',0) for r in recs]
    passes = sum(1 for r in recs if r.get('result') == 'pass')
    cached = sum(1 for r in recs if r.get('cache_hit') == True)
    avg_dur = sum(durations) / len(durations) if durations else 0
    cache_rate = (cached / len(recs) * 100) if recs else 0
    print(f'| {gate} | executions: {len(recs)} | pass: {passes} | cache_hit: {cache_rate:.0f}% | avg_ms: {avg_dur:.0f} |')
print()

# Cache effectiveness
print('## Cache Effectiveness')
total = len(records)
cached_count = sum(1 for r in records if r.get('cache_hit') == True)
executed_count = total - cached_count
cached_time_saved = sum(r.get('duration_ms',0) for r in records if r.get('cache_hit') == True)
print(f'- Total gate calls: {total}')
print(f'- Cache hits: {cached_count} ({cached_count/total*100:.0f}%)' if total else '- Cache hits: 0')
print(f'- Actually executed: {executed_count}')
print(f'- Estimated time saved by cache: {cached_time_saved}ms')
print()

# Diff classification
print('## Diff Classification')
by_diff = defaultdict(list)
for r in records:
    by_diff[r.get('diff_classification','?')].append(r)
for diff, recs in sorted(by_diff.items()):
    skipped = sum(1 for r in recs if r.get('result') in ('skip','not_run'))
    print(f'| {diff} | gates: {len(recs)} | skipped: {skipped} |')
print()

# Parallel benefit
parallel_records = [r for r in records if r.get('parallel') == True]
serial_records = [r for r in records if r.get('parallel') == False and r.get('cache_hit') == False]
if parallel_records and serial_records:
    p_avg = sum(r.get('duration_ms',0) for r in parallel_records) / len(parallel_records)
    s_avg = sum(r.get('duration_ms',0) for r in serial_records) / len(serial_records)
    print('## Parallel Gate Benefit')
    print(f'- Parallel avg: {p_avg:.0f}ms')
    print(f'- Serial avg: {s_avg:.0f}ms')
    if s_avg > 0:
        print(f'- Speedup: {s_avg/p_avg:.2f}x')
    print()

print('## Recommendations')
print('- Review slowest gates for optimization opportunities')
print('- Consider model routing changes only if pass rate is acceptable and duration difference is significant')
print('- Cache hit rate > 50% indicates session cache is effective')
print('- False skip rate should be 0% (any false skip is a bug)')
" >> "$REPORT_FILE"

  cat "$REPORT_FILE"
  echo ""
  echo "Report written to: $REPORT_FILE"
  exit 0
fi

# --- Integrity report mode ---
if [[ "$MODE" == "integrity" ]]; then
  DATA_DIR="$ROOT_DIR/vault/protocols/opencode/evals/benchmark-data"
  BASELINE_FILE="$ROOT_DIR/.opencode/config/gate-health-baseline.yaml"

  echo "=== TELEMETRY INTEGRITY REPORT ==="
  echo "Generated: $(date -Iseconds)"
  echo ""

  python3 -c "
import json, glob, os, sys

data_dir = '$DATA_DIR'
baseline_file = '$BASELINE_FILE'

# Load all records
all_records = []
files = sorted(glob.glob(os.path.join(data_dir, '*.json')))
for f in files:
    with open(f) as fh:
        records = json.load(fh)
    for r in records:
        r['_source_file'] = os.path.basename(f)
        all_records.append(r)

print(f'Total records: {len(all_records)}')
print(f'Source files: {len(files)}')
print()

# Classify records
usable = []
excluded = []
exclusion_reasons = {}

for r in all_records:
    sv = r.get('schema_version', '')
    fc = r.get('failure_classification', '')
    has_sv = bool(sv)
    has_fc = bool(fc)

    if not has_sv:
        reason = 'missing_schema_version (pre-v4.18.1)'
        r['_exclusion_reason'] = reason
        excluded.append(r)
        exclusion_reasons[reason] = exclusion_reasons.get(reason, 0) + 1
    elif not has_fc:
        reason = 'missing_failure_classification (pre-v4.18.1)'
        r['_exclusion_reason'] = reason
        excluded.append(r)
        exclusion_reasons[reason] = exclusion_reasons.get(reason, 0) + 1
    elif fc in ('pass', 'fail_new', 'cached_pass'):
        r['_exclusion_reason'] = None
        usable.append(r)
    else:
        reason = f'{fc}'
        r['_exclusion_reason'] = reason
        excluded.append(r)
        exclusion_reasons[reason] = exclusion_reasons.get(reason, 0) + 1

print('--- Usable Records ---')
print(f'Usable for routing: {len(usable)}')
print(f'Excluded from routing: {len(excluded)}')
print()

print('--- Exclusion Reasons ---')
for reason, count in sorted(exclusion_reasons.items(), key=lambda x: -x[1]):
    print(f'  {reason}: {count}')
print()

# Repo health matrix
print('--- Repo Health Matrix ---')
repos = sorted(set(r.get('repo', 'unknown') for r in all_records))
for repo in repos:
    repo_records = [r for r in all_records if r.get('repo') == repo]
    gates = sorted(set(r.get('gate', '') for r in repo_records))
    print(f'  {repo}:')
    for gate in gates:
        gate_records = [r for r in repo_records if r.get('gate') == gate]
        latest = gate_records[-1] if gate_records else {}
        fc = latest.get('failure_classification', 'MISSING')
        result = latest.get('result', 'MISSING')
        usable_count = sum(1 for r in gate_records if r.get('failure_classification') in ('pass', 'fail_new', 'cached_pass'))
        total = len(gate_records)
        print(f'    {gate:12s}: result={result:5s} classification={fc:20s} usable={usable_count}/{total}')
print()

# Lane coverage matrix
print('--- Lane Coverage Matrix ---')
lanes = sorted(set(r.get('lane', 'unknown') for r in all_records))
for lane in lanes:
    lane_records = [r for r in all_records if r.get('lane') == lane]
    usable_count = sum(1 for r in lane_records if r.get('failure_classification') in ('pass', 'fail_new', 'cached_pass'))
    print(f'  {lane}: total={len(lane_records)} usable={usable_count}')
print()

# Task type coverage matrix
print('--- Task Type Coverage Matrix ---')
task_types = sorted(set(r.get('task_type', 'unknown') for r in all_records))
for tt in task_types:
    tt_records = [r for r in all_records if r.get('task_type') == tt]
    usable_count = sum(1 for r in tt_records if r.get('failure_classification') in ('pass', 'fail_new', 'cached_pass'))
    print(f'  {tt}: total={len(tt_records)} usable={usable_count}')
print()

# Schema version distribution
print('--- Schema Version Distribution ---')
sv_counts = {}
for r in all_records:
    sv = r.get('schema_version', 'MISSING')
    sv_counts[sv] = sv_counts.get(sv, 0) + 1
for sv, count in sorted(sv_counts.items()):
    print(f'  {sv}: {count}')
print()

# Decision readiness
print('--- Decision Readiness ---')
min_samples = 100
min_per_repo_lane = 20
print(f'  Minimum samples for routing: {min_samples}')
print(f'  Current usable samples: {len(usable)}')
print(f'  Status: {\"SUFFICIENT\" if len(usable) >= min_samples else \"INSUFFICIENT (need \" + str(min_samples - len(usable)) + \" more)\"}')
" 2>&1

  exit 0
fi

# --- Run mode: execute gates with telemetry ---
if [[ -z "$REPO" ]]; then
  echo "Usage: benchmark-telemetry.sh <repo> [--parallel] [--report] [--integrity-report]" >&2
  exit 1
fi

REPO_PATH="$ROOT_DIR/$REPO"
if [[ ! -d "$REPO_PATH" ]]; then
  echo "ERROR: repo not found: $REPO_PATH" >&2
  exit 1
fi

# Get repo profile
PROFILE_OUTPUT=$(bash "$SCRIPT_DIR/bootstrap-repo-profile.sh" "$REPO_PATH" 2>/dev/null)
REPO_TYPE=$(echo "$PROFILE_OUTPUT" | grep '^REPO_TYPE:' | cut -d' ' -f2)
GATE_LINT=$(echo "$PROFILE_OUTPUT" | grep '^GATE_LINT:' | cut -d' ' -f2-)
GATE_TC=$(echo "$PROFILE_OUTPUT" | grep '^GATE_TYPECHECK:' | cut -d' ' -f2-)
GATE_TEST=$(echo "$PROFILE_OUTPUT" | grep '^GATE_TEST:' | cut -d' ' -f2-)
GATE_BUILD=$(echo "$PROFILE_OUTPUT" | grep '^GATE_BUILD:' | cut -d' ' -f2-)
DEFAULT_LANE=$(echo "$PROFILE_OUTPUT" | grep '^DEFAULT_LANE:' | cut -d' ' -f2)
VERIFICATION_PROFILE=$(echo "$PROFILE_OUTPUT" | grep '^VERIFICATION_PROFILE:' | cut -d' ' -f2)

# Override lane if specified (for telemetry collection coverage)
if [[ -n "$OVERRIDE_LANE" ]]; then
  DEFAULT_LANE="$OVERRIDE_LANE"
fi

# Get diff classification
DIFF_OUTPUT=$(bash "$SCRIPT_DIR/diff-analyze.sh" "$REPO_PATH" 2>/dev/null)
DIFF_CLASSIFICATION=$(echo "$DIFF_OUTPUT" | grep '^DIFF_CLASSIFICATION:' | cut -d' ' -f2)

# Determine if working tree is clean (for failure classification)
# If clean, any gate failure is pre-existing or environmental (benchmark didn't cause it)
# If dirty, any gate failure could be new (caused by uncommitted changes)
WORKING_TREE_CLEAN=false
if [[ -z "$(git -C "$REPO_PATH" status --porcelain 2>/dev/null)" ]]; then
  WORKING_TREE_CLEAN=true
fi

# Load gate-health baseline for this repo
BASELINE_FILE="$ROOT_DIR/.opencode/config/gate-health-baseline.yaml"
is_known_failing() {
  local gate="$1"
  if [[ ! -f "$BASELINE_FILE" ]]; then
    return 1
  fi
  # Check if gate is listed under this repo's known_failing_gates
  python3 -c "
import yaml, sys
with open('$BASELINE_FILE') as f:
    data = yaml.safe_load(f)
repos = data.get('repos', {})
repo_data = repos.get('$REPO', {})
known = repo_data.get('known_failing_gates', [])
for entry in known:
    if entry.get('gate') == '$gate':
        print('true')
        sys.exit(0)
print('false')
" 2>/dev/null
}

# Classify failure using gate-health baseline
# Returns one of: pass, fail_new, fail_pre_existing, fail_environment, not_run, cached_pass, cached_stale, skipped_unsupported
classify_failure() {
  local result="$1"
  local gate_name="$2"
  local cache_status="${3:-}"

  if [[ "$result" == "pass" ]]; then
    echo "pass"
  elif [[ "$result" == "not_run" ]]; then
    echo "not_run"
  elif [[ "$result" == "cached" ]]; then
    echo "cached_pass"
  elif [[ "$WORKING_TREE_CLEAN" == "true" ]]; then
    # Clean tree failure — check if it's a known failing gate
    local known
    known=$(is_known_failing "$gate_name")
    if [[ "$known" == "true" ]]; then
      echo "fail_pre_existing"
    else
      echo "fail_environment"
    fi
  else
    # Dirty tree failure — could be caused by current change
    echo "fail_new"
  fi
}

# Determine if a record is usable for routing decisions
is_usable_for_routing() {
  local failure_class="$1"
  case "$failure_class" in
    pass|fail_new|cached_pass) echo "true" ;;
    *) echo "false" ;;
  esac
}

# Determine skip reason
get_skip_reason() {
  local result="$1"
  local command="$2"
  local cache_status="$3"

  if [[ "$cache_status" == "cached" ]]; then
    echo "cache_hit"
  elif [[ -z "$command" ]] || echo "$command" | grep -q "^echo "; then
    echo "unsupported"
  else
    echo ""
  fi
}

# Check session cache for each gate
check_cache() {
  local gate="$1"
  local result
  result=$(bash "$SCRIPT_DIR/session-cache.sh" gate-skip "$gate" "benchmark" 2>/dev/null || echo "NOT_CACHED")
  if echo "$result" | grep -q "^CACHED"; then
    echo "cached"
  else
    echo "not_cached"
  fi
}

# Time a gate execution
time_gate() {
  local gate_name="$1"
  local command="$2"
  local cache_status="$3"

  if [[ "$cache_status" == "cached" ]]; then
    # Gate is cached — record as cached_pass with 0ms
    local skip_reason="cache_hit"
    local failure_class="cached_pass"
    local usable="true"
    echo "{\"schema_version\":\"4.18.2\",\"repo\":\"$REPO\",\"lane\":\"$DEFAULT_LANE\",\"task_type\":\"$DIFF_CLASSIFICATION\",\"model_used\":\"runtime\",\"gate\":\"$gate_name\",\"duration_ms\":0,\"result\":\"cached\",\"failure_classification\":\"$failure_class\",\"skip_reason\":\"$skip_reason\",\"usable_for_routing\":$usable,\"cache_hit\":true,\"diff_classification\":\"$DIFF_CLASSIFICATION\",\"selected_gate_profile\":\"$VERIFICATION_PROFILE\",\"parallel\":false,\"timestamp\":\"$(date -Iseconds)\"}"
    return
  fi

  if [[ -z "$command" ]] || echo "$command" | grep -q "^echo "; then
    # Gate command is a placeholder — repo doesn't support this gate
    local skip_reason="unsupported"
    local failure_class="not_run"
    local usable="false"
    echo "{\"schema_version\":\"4.18.2\",\"repo\":\"$REPO\",\"lane\":\"$DEFAULT_LANE\",\"task_type\":\"$DIFF_CLASSIFICATION\",\"model_used\":\"runtime\",\"gate\":\"$gate_name\",\"duration_ms\":0,\"result\":\"not_run\",\"failure_classification\":\"$failure_class\",\"skip_reason\":\"$skip_reason\",\"usable_for_routing\":$usable,\"cache_hit\":false,\"diff_classification\":\"$DIFF_CLASSIFICATION\",\"selected_gate_profile\":\"$VERIFICATION_PROFILE\",\"parallel\":false,\"timestamp\":\"$(date -Iseconds)\"}"
    return
  fi

  # Execute gate and time it
  local start_ms end_ms duration exit_code result
  start_ms=$(python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || echo "0")
  set +e
  (cd "$REPO_PATH" && eval "$command" > /tmp/v4180-${gate_name}.log 2>&1)
  exit_code=$?
  set -e
  end_ms=$(python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || echo "0")
  duration=$((end_ms - start_ms))

  if [[ $exit_code -eq 0 ]]; then
    result="pass"
  else
    result="fail"
  fi

  # Classify failure type using gate-health baseline
  local failure_class
  failure_class=$(classify_failure "$result" "$gate_name" "$cache_status")

  # Determine if usable for routing
  local usable
  usable=$(is_usable_for_routing "$failure_class")

  # Determine skip reason
  local skip_reason=""
  skip_reason=$(get_skip_reason "$result" "$command" "$cache_status")

  # Record gate result in session cache
  bash "$SCRIPT_DIR/session-cache.sh" gate-set "$gate_name" "$result" "$exit_code" > /dev/null 2>&1 || true

  echo "{\"schema_version\":\"4.18.2\",\"repo\":\"$REPO\",\"lane\":\"$DEFAULT_LANE\",\"task_type\":\"$DIFF_CLASSIFICATION\",\"model_used\":\"runtime\",\"gate\":\"$gate_name\",\"duration_ms\":$duration,\"result\":\"$result\",\"failure_classification\":\"$failure_class\",\"skip_reason\":\"$skip_reason\",\"usable_for_routing\":$usable,\"cache_hit\":false,\"diff_classification\":\"$DIFF_CLASSIFICATION\",\"selected_gate_profile\":\"$VERIFICATION_PROFILE\",\"parallel\":false,\"timestamp\":\"$(date -Iseconds)\"}"
}

# Run gates
DATA_DIR="$ROOT_DIR/vault/protocols/opencode/evals/benchmark-data"
mkdir -p "$DATA_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DATA_FILE="$DATA_DIR/${REPO}-${TIMESTAMP}.json"

echo "=== BENCHMARK TELEMETRY: $REPO ==="
echo "Profile: $REPO_TYPE | Lane: $DEFAULT_LANE | Verification: $VERIFICATION_PROFILE"
echo "Diff classification: $DIFF_CLASSIFICATION"
echo "Parallel: $PARALLEL"
echo ""

# Initialize session cache
bash "$SCRIPT_DIR/session-cache.sh" init "$REPO" > /dev/null 2>&1 || true

RECORDS="["

if [[ "$PARALLEL" == "true" ]]; then
  # Parallel execution: lint + typecheck + test in parallel
  echo "--- Phase 1: Parallel lint + typecheck + test ---"

  LINT_CACHE=$(check_cache "lint")
  TC_CACHE=$(check_cache "typecheck")
  TEST_CACHE=$(check_cache "test")

  # Run in parallel (only non-cached gates)
  set +e
  if [[ "$LINT_CACHE" != "cached" && -n "$GATE_LINT" && ! "$GATE_LINT" =~ ^echo ]]; then
    (cd "$REPO_PATH" && eval "$GATE_LINT" > /tmp/v4180-lint.log 2>&1) &
    LINT_PID=$!
  fi
  if [[ "$TC_CACHE" != "cached" && -n "$GATE_TC" && ! "$GATE_TC" =~ ^echo ]]; then
    (cd "$REPO_PATH" && eval "$GATE_TC" > /tmp/v4180-typecheck.log 2>&1) &
    TC_PID=$!
  fi
  if [[ "$TEST_CACHE" != "cached" && -n "$GATE_TEST" && ! "$GATE_TEST" =~ ^echo ]]; then
    (cd "$REPO_PATH" && eval "$GATE_TEST" > /tmp/v4180-test.log 2>&1) &
    TEST_PID=$!
  fi

  # Wait and collect
  start_ms=$(python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || echo "0")

  [[ -n "${LINT_PID:-}" ]] && wait $LINT_PID; LINT_EXIT=$?
  [[ -n "${TC_PID:-}" ]] && wait $TC_PID; TC_EXIT=$?
  [[ -n "${TEST_PID:-}" ]] && wait $TEST_PID; TEST_EXIT=$?

  end_ms=$(python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || echo "0")
  phase1_duration=$((end_ms - start_ms))

  set -e

  # Record parallel results
  for gate_name in lint typecheck test; do
    cache=$(check_cache "$gate_name")
    if [[ "$cache" == "cached" ]]; then
      p_skip_reason="cache_hit"
      p_failure_class="cached_pass"
      p_usable="true"
      RECORDS="${RECORDS}{\"schema_version\":\"4.18.2\",\"repo\":\"$REPO\",\"lane\":\"$DEFAULT_LANE\",\"task_type\":\"$DIFF_CLASSIFICATION\",\"model_used\":\"runtime\",\"gate\":\"$gate_name\",\"duration_ms\":0,\"result\":\"cached\",\"failure_classification\":\"$p_failure_class\",\"skip_reason\":\"$p_skip_reason\",\"usable_for_routing\":$p_usable,\"cache_hit\":true,\"diff_classification\":\"$DIFF_CLASSIFICATION\",\"selected_gate_profile\":\"$VERIFICATION_PROFILE\",\"parallel\":true,\"timestamp\":\"$(date -Iseconds)\"},"
    else
      case $gate_name in
        lint) exit_code=${LINT_EXIT:-0} ;;
        typecheck) exit_code=${TC_EXIT:-0} ;;
        test) exit_code=${TEST_EXIT:-0} ;;
      esac
      result=$([[ $exit_code -eq 0 ]] && echo "pass" || echo "fail")
      failure_class=$(classify_failure "$result" "$gate_name" "$cache")
      usable=$(is_usable_for_routing "$failure_class")
      # Gates ran in parallel — skip_reason is empty (not skipped)
      skip_reason=""
      bash "$SCRIPT_DIR/session-cache.sh" gate-set "$gate_name" "$result" "$exit_code" > /dev/null 2>&1 || true
      RECORDS="${RECORDS}{\"schema_version\":\"4.18.2\",\"repo\":\"$REPO\",\"lane\":\"$DEFAULT_LANE\",\"task_type\":\"$DIFF_CLASSIFICATION\",\"model_used\":\"runtime\",\"gate\":\"$gate_name\",\"duration_ms\":${phase1_duration},\"result\":\"$result\",\"failure_classification\":\"$failure_class\",\"skip_reason\":\"$skip_reason\",\"usable_for_routing\":$usable,\"cache_hit\":false,\"diff_classification\":\"$DIFF_CLASSIFICATION\",\"selected_gate_profile\":\"$VERIFICATION_PROFILE\",\"parallel\":true,\"timestamp\":\"$(date -Iseconds)\"},"
    fi
  done

  echo "  Phase 1 duration: ${phase1_duration}ms (parallel)"

  # Phase 2: build (sequential)
  echo "--- Phase 2: Sequential build ---"
  BUILD_RECORD=$(time_gate "build" "$GATE_BUILD" "$(check_cache 'build')")
  echo "  build: $(echo "$BUILD_RECORD" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d[\"result\"]} ({d[\"duration_ms\"]}ms)')" 2>/dev/null || echo "done")"
  RECORDS="${RECORDS}${BUILD_RECORD},"
else
  # Serial execution
  echo "--- Serial gate execution ---"
  for gate_name in lint typecheck test build; do
    case $gate_name in
      lint) cmd="$GATE_LINT" ;;
      typecheck) cmd="$GATE_TC" ;;
      test) cmd="$GATE_TEST" ;;
      build) cmd="$GATE_BUILD" ;;
    esac
    cache=$(check_cache "$gate_name")
    record=$(time_gate "$gate_name" "$cmd" "$cache")
    dur=$(echo "$record" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['duration_ms'])" 2>/dev/null || echo "?")
    res=$(echo "$record" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['result'])" 2>/dev/null || echo "?")
    echo "  $gate_name: $res (${dur}ms)"
    RECORDS="${RECORDS}${record},"
  done
fi

# Remove trailing comma and close array
RECORDS="${RECORDS%,}]"

# Save data
echo "$RECORDS" | python3 -c "import json,sys; data=json.load(sys.stdin); print(json.dumps(data, indent=2))" > "$DATA_FILE" 2>/dev/null || echo "$RECORDS" > "$DATA_FILE"

echo ""
echo "=== TELEMETRY CAPTURED ==="
echo "Data: $DATA_FILE"
echo "Records: $(python3 -c "import json; print(len(json.load(open('$DATA_FILE'))))" 2>/dev/null || echo "?")"
echo ""
echo "To generate report: bash $0 --report"
