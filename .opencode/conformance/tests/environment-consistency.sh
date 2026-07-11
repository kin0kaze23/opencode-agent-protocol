#!/bin/bash
# environment-consistency.sh — Conformance test for v4.27.2 environment contract
# Verifies that environment contract docs, runtime contract docs, sync contract docs,
# verify-environment.sh script, and repo baseline template all exist and are coherent.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
mkdir -p "$RESULTS_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/environment-consistency-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Environment Consistency Test (v4.27.2)"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo "Root: $ROOT_DIR"
echo ""

reset_counters

# ============================================================
# EC-001: environment-contract.md exists
# ============================================================
test_start "EC-001" "environment-contract.md exists"
assert_file_exists "$ROOT_DIR/.opencode/docs/environment-contract.md" "Environment contract doc"

# ============================================================
# EC-002: runtime-contract.md exists
# ============================================================
test_start "EC-002" "runtime-contract.md exists"
assert_file_exists "$ROOT_DIR/.opencode/docs/runtime-contract.md" "Runtime contract doc"

# ============================================================
# EC-003: sync-contract.md exists
# ============================================================
test_start "EC-003" "sync-contract.md exists"
assert_file_exists "$ROOT_DIR/.opencode/docs/sync-contract.md" "Sync contract doc"

# ============================================================
# EC-004: verify-environment.sh exists and is executable
# ============================================================
test_start "EC-004" "verify-environment.sh exists and is executable"
assert_file_exists "$ROOT_DIR/.opencode/scripts/verify-environment.sh" "Verify environment script"
if [ -x "$ROOT_DIR/.opencode/scripts/verify-environment.sh" ]; then
    echo -e "  ${GREEN}✓${NC} Script is executable"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  ${RED}✗${NC} Script is NOT executable"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# EC-005: verify-environment.sh supports --mode global
# ============================================================
test_start "EC-005" "verify-environment.sh supports --mode global"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-environment.sh" "MODE" "Script accepts --mode flag"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-environment.sh" "global" "Script supports global mode"

# ============================================================
# EC-006: verify-environment.sh supports --mode workspace
# ============================================================
test_start "EC-006" "verify-environment.sh supports --mode workspace"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-environment.sh" "workspace" "Script supports workspace mode"

# ============================================================
# EC-007: verify-environment.sh supports --mode repo
# ============================================================
test_start "EC-007" "verify-environment.sh supports --mode repo"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-environment.sh" "repo" "Script supports repo mode"

# ============================================================
# EC-008: helper-roster reference-only rule is documented
# ============================================================
test_start "EC-008" "helper-roster reference-only rule documented"
assert_file_contains "$ROOT_DIR/.opencode/docs/environment-contract.md" "reference-only" "Environment contract documents helper-roster as reference-only"
assert_file_contains "$ROOT_DIR/.opencode/docs/runtime-contract.md" "REFERENCE" "Runtime contract marks helper-roster as REFERENCE"

# ============================================================
# EC-009: command surface sync rule is documented
# ============================================================
test_start "EC-009" "command surface sync rule documented"
assert_file_contains "$ROOT_DIR/.opencode/docs/sync-contract.md" "command_surface" "Sync contract documents command surface sync"
assert_file_contains "$ROOT_DIR/.opencode/docs/sync-contract.md" "command_surface.commands" "Sync contract references command_surface.commands array"

# ============================================================
# EC-010: generated cache exclusion is documented
# ============================================================
test_start "EC-010" "generated cache exclusion documented"
assert_file_contains "$ROOT_DIR/.opencode/docs/runtime-contract.md" "GENERATED" "Runtime contract marks cache as GENERATED"
assert_file_contains "$ROOT_DIR/.opencode/docs/runtime-contract.md" "must NOT be committed" "Runtime contract states cache must not be committed"

# ============================================================
# EC-011: repo baseline template exists
# ============================================================
test_start "EC-011" "repo baseline template exists"
assert_file_exists "$ROOT_DIR/.opencode/templates/REPO_PROTOCOL_BASELINE.md" "Repo baseline template"

# ============================================================
# EC-012: environment contract defines four layers
# ============================================================
test_start "EC-012" "environment contract defines four layers"
assert_file_contains "$ROOT_DIR/.opencode/docs/environment-contract.md" "Global" "Contract defines Global layer"
assert_file_contains "$ROOT_DIR/.opencode/docs/environment-contract.md" "Workspace" "Contract defines Workspace layer"
assert_file_contains "$ROOT_DIR/.opencode/docs/environment-contract.md" "Repo" "Contract defines Repo layer"
assert_file_contains "$ROOT_DIR/.opencode/docs/environment-contract.md" "Session" "Contract defines Session layer"

# ============================================================
# EC-013: environment contract defines precedence
# ============================================================
test_start "EC-013" "environment contract defines precedence"
assert_file_contains "$ROOT_DIR/.opencode/docs/environment-contract.md" "precedence" "Contract defines precedence rules"

# ============================================================
# EC-014: runtime contract defines fresh clone requirements
# ============================================================
test_start "EC-014" "runtime contract defines fresh clone requirements"
assert_file_contains "$ROOT_DIR/.opencode/docs/runtime-contract.md" "Fresh Clone" "Runtime contract defines fresh clone requirements"

# ============================================================
# EC-015: sync contract defines bootstrap procedure
# ============================================================
test_start "EC-015" "sync contract defines bootstrap procedure"
assert_file_contains "$ROOT_DIR/.opencode/docs/sync-contract.md" "Bootstrap" "Sync contract defines new repo bootstrap"

# ============================================================
# EC-016: sync contract defines drift prevention
# ============================================================
test_start "EC-016" "sync contract defines drift prevention"
assert_file_contains "$ROOT_DIR/.opencode/docs/sync-contract.md" "drift" "Sync contract defines drift prevention"

# ============================================================
# EC-017: runtime contract defines portability rules
# ============================================================
test_start "EC-017" "runtime contract defines portability rules"
assert_file_contains "$ROOT_DIR/.opencode/docs/runtime-contract.md" "Portability" "Runtime contract defines portability rules"
assert_file_contains "$ROOT_DIR/.opencode/docs/runtime-contract.md" "hardcoded" "Runtime contract prohibits hardcoded paths"

# ============================================================
# EC-018: verify-environment.sh checks command surface
# ============================================================
test_start "EC-018" "verify-environment.sh checks command surface"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-environment.sh" "command_surface" "Script checks command surface sync"

# ============================================================
# EC-019: verify-environment.sh checks cache gitignore
# ============================================================
test_start "EC-019" "verify-environment.sh checks cache gitignore"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-environment.sh" "gitignored" "Script checks cache directories are gitignored"

# ============================================================
# EC-020: verify-environment.sh checks helper-roster reference-only
# ============================================================
test_start "EC-020" "verify-environment.sh checks helper-roster reference-only"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-environment.sh" "helper-roster" "Script checks helper-roster reference-only status"

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
