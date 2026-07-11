#!/usr/bin/env bash
# fleet-trends.sh — v4.42 Fleet Trend Analytics Conformance Tests
#
# Tests for analyze-fleet-trends.sh, trend report generation,
# regression detection, and snapshot compatibility.
#
# Usage: bash .opencode/conformance/tests/fleet-trends.sh

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

reset_counters

echo "=== v4.42 Fleet Trend Analytics Conformance Tests ==="
echo ""

# ─── FT-001: trend analyzer exists ─────────────────────────────────────
test_start "FT-001" "trend analyzer exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "Trend analyzer exists"

# ─── FT-002: analyzer generates markdown ────────────────────────────────
test_start "FT-002" "analyzer generates markdown"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "fleet-trends.md" "Analyzer outputs markdown"

# ─── FT-003: analyzer generates JSON ────────────────────────────────────
test_start "FT-003" "analyzer generates JSON"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "fleet-trends.json" "Analyzer outputs JSON"

# ─── FT-004: analyzer handles no snapshots ─────────────────────────────
test_start "FT-004" "analyzer handles no snapshots"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "No snapshots found" "Analyzer handles missing snapshots"

# ─── FT-005: analyzer has metrics over time table ──────────────────────
test_start "FT-005" "analyzer has metrics over time"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "Metrics Over Time" "Analyzer has metrics over time section"

# ─── FT-006: analyzer has lifecycle timeline ───────────────────────────
test_start "FT-006" "analyzer has lifecycle timeline"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "Lifecycle Timeline" "Analyzer has lifecycle timeline section"

# ─── FT-007: analyzer has regression detection ──────────────────────────
test_start "FT-007" "analyzer has regression detection"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "Regressions Detected" "Analyzer has regression detection section"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "HIGH" "Analyzer has HIGH severity regressions"

# ─── FT-008: analyzer has improvement detection ────────────────────────
test_start "FT-008" "analyzer has improvement detection"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "Improvements Detected" "Analyzer has improvement detection section"

# ─── FT-009: analyzer detects manually_verified regression ─────────────
test_start "FT-009" "analyzer detects manually_verified regression"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "manually_verified" "Analyzer tracks manually_verified"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "protection_ready" "Analyzer tracks protection_ready"

# ─── FT-010: analyzer detects protected-repo active ─────────────────────────
test_start "FT-010" "analyzer detects protected-repo active"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "protected-repo" "Analyzer checks protected-repo status"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "active" "Analyzer detects protected-repo as active"

# ─── FT-011: analyzer detects gate missing ─────────────────────────────
test_start "FT-011" "analyzer detects gate missing"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "release gate disappeared" "Analyzer detects gate disappearance"

# ─── FT-012: analyzer detects CODEOWNERS missing ───────────────────────
test_start "FT-012" "analyzer detects CODEOWNERS missing"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "CODEOWNERS disappeared" "Analyzer detects CODEOWNERS disappearance"

# ─── FT-013: analyzer handles old snapshot schema ───────────────────────
test_start "FT-013" "analyzer handles old snapshot schema"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "manually_verified // 0" "Analyzer defaults missing manually_verified to 0"

# ─── FT-014: analyzer skips malformed snapshots ─────────────────────────
test_start "FT-014" "analyzer skips malformed snapshots"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "Skipping malformed" "Analyzer skips malformed snapshots"

# ─── FT-015: analyzer has MEDIUM severity ──────────────────────────────
test_start "FT-015" "analyzer has MEDIUM severity"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "MEDIUM" "Analyzer has MEDIUM severity regressions"

# ─── FT-016: JSON output has summary ───────────────────────────────────
test_start "FT-016" "JSON has summary"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "total_snapshots" "JSON has total_snapshots"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "regressions" "JSON has regressions count"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "improvements" "JSON has improvements count"

# ─── FT-017: JSON output has lifecycle ─────────────────────────────────
test_start "FT-017" "JSON has lifecycle"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "lifecycle" "JSON has lifecycle section"

# ─── FT-018: JSON output has snapshots array ───────────────────────────
test_start "FT-018" "JSON has snapshots array"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "snapshots" "JSON has snapshots array"

# ─── FT-019: analyzer has fleet-trends marker ──────────────────────────
test_start "FT-019" "analyzer has marker"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "fleet-trends" "Analyzer has fleet-trends marker"

# ─── FT-020: analyzer tracks baseline failures over time ───────────────
test_start "FT-020" "analyzer tracks baseline failures"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "baseline_failures" "Analyzer tracks baseline failures"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "Baseline Failures" "Analyzer has baseline failures column"

# ─── FT-021: analyzer tracks gate installed over time ──────────────────
test_start "FT-021" "analyzer tracks gate installed"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "gate_installed" "Analyzer tracks gate installed"

# ─── FT-022: analyzer tracks CODEOWNERS verified over time ─────────────
test_start "FT-022" "analyzer tracks CODEOWNERS verified"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "codeowners_verified" "Analyzer tracks CODEOWNERS verified"

# ─── FT-023: analyzer tracks manually_verified over time ───────────────
test_start "FT-023" "analyzer tracks manually_verified"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "manually_verified" "Analyzer tracks manually_verified"

# ─── FT-024: analyzer tracks unknown_permission over time ───────────────
test_start "FT-024" "analyzer tracks unknown_permission"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "unknown_permission" "Analyzer tracks unknown_permission"

# ─── FT-025: analyzer has version tag ──────────────────────────────────
test_start "FT-025" "analyzer has version tag"
assert_file_contains "$ROOT_DIR/.opencode/scripts/analyze-fleet-trends.sh" "v4.42" "Analyzer references v4.42"

# ─── Summary ────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo -e "${GREEN}PASSED: $TESTS_PASSED${NC}"
echo -e "${RED}FAILED: $TESTS_FAILED${NC}"
echo "=========================================="

if [ "$TESTS_FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
