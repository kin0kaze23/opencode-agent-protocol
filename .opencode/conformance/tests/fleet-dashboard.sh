#!/usr/bin/env bash
# fleet-dashboard.sh — v4.40 Fleet Dashboard Conformance Tests
#
# Tests for generate-fleet-dashboard.sh, record-fleet-snapshot.sh,
# and fleet-repos.yaml manifest.
#
# Usage: bash .opencode/conformance/tests/fleet-dashboard.sh

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

reset_counters

echo "=== v4.40 Fleet Dashboard Conformance Tests ==="
echo ""

# ─── FD-001: fleet-repos.yaml exists ────────────────────────────────────
test_start "FD-001" "fleet-repos.yaml exists"
assert_file_exists "$ROOT_DIR/.opencode/config/fleet-repos.yaml" "Fleet manifest exists"

# ─── FD-002: manifest includes sample-service ────────────────────────────
test_start "FD-002" "manifest includes sample-service"
assert_file_contains "$ROOT_DIR/.opencode/config/fleet-repos.yaml" "sample-service" "Manifest includes sample-service"

# ─── FD-003: manifest includes demo-project ────────────────────────────────
test_start "FD-003" "manifest includes demo-project"
assert_file_contains "$ROOT_DIR/.opencode/config/fleet-repos.yaml" "demo-project" "Manifest includes demo-project"

# ─── FD-004: manifest includes protected-repo as excluded ────────────────────
test_start "FD-004" "protected-repo is excluded"
assert_file_contains "$ROOT_DIR/.opencode/config/fleet-repos.yaml" "protected-repo" "Manifest includes protected-repo"
assert_file_contains "$ROOT_DIR/.opencode/config/fleet-repos.yaml" "excluded" "protected-repo is marked excluded"
assert_file_contains "$ROOT_DIR/.opencode/config/fleet-repos.yaml" "do_not_touch" "protected-repo has do_not_touch marker"

# ─── FD-005: generate-fleet-dashboard.sh exists ─────────────────────────
test_start "FD-005" "dashboard generator exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "Dashboard generator exists"

# ─── FD-006: record-fleet-snapshot.sh exists ───────────────────────────
test_start "FD-006" "snapshot recorder exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/record-fleet-snapshot.sh" "Snapshot recorder exists"

# ─── FD-007: dashboard generator has markdown output ───────────────────
test_start "FD-007" "generator produces markdown"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "fleet-dashboard.md" "Generator outputs markdown"

# ─── FD-008: dashboard generator has JSON output ────────────────────────
test_start "FD-008" "generator produces JSON"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "fleet-dashboard.json" "Generator outputs JSON"

# ─── FD-009: dashboard has executive summary ────────────────────────────
test_start "FD-009" "dashboard has executive summary"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "Executive Summary" "Generator has executive summary section"

# ─── FD-010: dashboard has repo status table ───────────────────────────
test_start "FD-010" "dashboard has repo status table"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "Release Gate" "Dashboard includes release gate status"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "CODEOWNERS" "Dashboard includes CODEOWNERS status"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "Branch Protection" "Dashboard includes branch protection status"

# ─── FD-011: dashboard has owner next actions ──────────────────────────
test_start "FD-011" "dashboard has owner next actions"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "Owner Next Actions" "Dashboard includes owner next actions"

# ─── FD-012: dashboard has known baseline failures ──────────────────────
test_start "FD-012" "dashboard has known baseline failures"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "Baseline Failures" "Dashboard includes baseline failures section"

# ─── FD-013: dashboard has classification ───────────────────────────────
test_start "FD-013" "dashboard has classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "protected" "Dashboard has protected classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "protection_ready" "Dashboard has protection_ready classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "not_protected" "Dashboard has not_protected classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "unknown_permission_limited" "Dashboard has unknown_permission_limited classification"

# ─── FD-014: unknown_permission_limited is not called protected ────────
test_start "FD-014" "unknown is not protected"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "protection_ready" "Unknown permission is classified as protection_ready, not protected"

# ─── FD-015: protected-repo is excluded from dashboard ─────────────────────
test_start "FD-015" "protected-repo excluded from dashboard"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "Excluded" "Dashboard has excluded section"
assert_file_contains "$ROOT_DIR/.opencode/config/fleet-repos.yaml" "do_not_touch" "protected-repo marked do_not_touch"

# ─── FD-016: snapshot recorder creates timestamped files ──────────────
test_start "FD-016" "snapshot recorder creates timestamped files"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-fleet-snapshot.sh" "fleet-snapshots" "Recorder uses fleet-snapshots directory"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-fleet-snapshot.sh" "timestamp" "Recorder includes timestamp"

# ─── FD-017: snapshot tracks key metrics ───────────────────────────────
test_start "FD-017" "snapshot tracks key metrics"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-fleet-snapshot.sh" "total_repos" "Snapshot tracks total repos"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-fleet-snapshot.sh" "release_gate_installed" "Snapshot tracks gate installed count"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-fleet-snapshot.sh" "codeowners_verified" "Snapshot tracks CODEOWNERS verified count"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-fleet-snapshot.sh" "branch_protection_verified" "Snapshot tracks branch protection verified count"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-fleet-snapshot.sh" "unknown_permission_limited" "Snapshot tracks unknown permission count"

# ─── FD-018: manifest has known baseline failures for demo-project ────────
test_start "FD-018" "manifest has demo-project baseline failures"
assert_file_contains "$ROOT_DIR/.opencode/config/fleet-repos.yaml" "deploy-preview" "Manifest includes deploy-preview baseline failure"
assert_file_contains "$ROOT_DIR/.opencode/config/fleet-repos.yaml" "VERCEL_TOKEN" "Manifest references VERCEL_TOKEN"

# ─── FD-019: manifest has owner next actions ───────────────────────────
test_start "FD-019" "manifest has owner next actions"
assert_file_contains "$ROOT_DIR/.opencode/config/fleet-repos.yaml" "owner_next_action" "Manifest has owner_next_action section"
assert_file_contains "$ROOT_DIR/.opencode/config/fleet-repos.yaml" "Configure branch protection" "Manifest has branch protection action"
assert_file_contains "$ROOT_DIR/.opencode/config/fleet-repos.yaml" "Require Release Gate" "Manifest has require release gate action"

# ─── FD-020: dashboard generator reads manifest ────────────────────────
test_start "FD-020" "generator reads fleet manifest"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "fleet-repos.yaml" "Generator reads fleet manifest"

# ─── FD-021: dashboard has fleet-dashboard marker ──────────────────────
test_start "FD-021" "dashboard has marker"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "fleet-dashboard" "Generator has fleet-dashboard marker"

# ─── FD-022: JSON output has summary ───────────────────────────────────
test_start "FD-022" "JSON has summary"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "summary" "JSON output has summary section"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "gate_installed" "JSON summary has gate_installed"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "codeowners_verified" "JSON summary has codeowners_verified"

# ─── FD-023: demo-project deploy-preview recommendation ────────────────────
test_start "FD-023" "demo-project deploy-preview recommendation"
assert_file_contains "$ROOT_DIR/.opencode/config/fleet-repos.yaml" "Do NOT require deploy-preview" "Manifest has do-not-require recommendation for deploy-preview"

# ─── FD-024: dashboard has trend snapshot section ──────────────────────
test_start "FD-024" "dashboard has trend snapshot"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-fleet-snapshot.sh" "metrics" "Snapshot recorder tracks metrics"

# ─── FD-025: manifest has protection notes ─────────────────────────────
test_start "FD-025" "manifest has protection notes"
assert_file_contains "$ROOT_DIR/.opencode/config/fleet-repos.yaml" "protection_notes" "Manifest has protection_notes field"
assert_file_contains "$ROOT_DIR/.opencode/config/fleet-repos.yaml" "403" "Manifest references 403 permission issue"

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
