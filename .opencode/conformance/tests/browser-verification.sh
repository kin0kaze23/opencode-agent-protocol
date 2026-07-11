#!/bin/bash
# Browser Verification Behavior Tests
# Tests protocol behavior around browser evidence for UI changes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/browser-verification-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Browser Verification Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

# ============================================================
# BROWSER-001: UI changes trigger browser verification requirement
# ============================================================
test_start "BROWSER-001" "UI changes trigger browser verification"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "UI files" "UI files mentioned"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "browser verification" "Browser verification required"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "app/" "app/ paths"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "components/" "components/ paths"

# ============================================================
# BROWSER-002: Completion blocked without browser evidence
# ============================================================
test_start "BROWSER-002" "Completion blocked without browser evidence"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "do NOT claim completion" "Completion blocking"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "cannot be completed" "Incomplete verification"

# ============================================================
# BROWSER-003: Screenshot capture required
# ============================================================
test_start "BROWSER-003" "Screenshot capture required"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "screenshot" "Screenshot mentioned"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "Capture" "Capture action"

# ============================================================
# BROWSER-004: Console status surfaced
# ============================================================
test_start "BROWSER-004" "Console status surfaced"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "console" "Console mentioned"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "error" "Error status"

# ============================================================
# BROWSER-005: Non-UI changes skip browser verification
# ============================================================
test_start "BROWSER-005" "Non-UI changes skip browser verification"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "Not required" "Not required option"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "qualifying" "Qualifying changes only"

# ============================================================
# BROWSER-006: Browser verification before commit
# ============================================================
test_start "BROWSER-006" "Browser verification before commit"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "before commit" "Before commit"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "Completion Summary" "Completion Summary mentioned"

# ============================================================
# BROWSER-007: Preflight hardens MCP against false positives
# ============================================================
test_start "BROWSER-007" "Preflight hardens MCP against false positives"
assert_file_contains "$ROOT_DIR/.opencode/scripts/browser-verification-preflight.sh" "detect_mcp_browser_availability" "MCP browser detection function exists"
assert_file_contains "$ROOT_DIR/.opencode/scripts/browser-verification-preflight.sh" "mcp_browser_state" "MCP browser state tracked"
assert_file_contains "$ROOT_DIR/.opencode/scripts/browser-verification-preflight.sh" "playwright_mcp_enabled_but_browser_missing" "MCP enabled but browser missing detail"

# ============================================================
# BROWSER-008: Preflight does not attempt installs
# ============================================================
test_start "BROWSER-008" "Preflight does not attempt installs"
assert_file_not_contains "$ROOT_DIR/.opencode/scripts/browser-verification-preflight.sh" "playwright install" "No playwright install command"
assert_file_not_contains "$ROOT_DIR/.opencode/scripts/browser-verification-preflight.sh" "npm install" "No npm install command"
assert_file_not_contains "$ROOT_DIR/.opencode/scripts/browser-verification-preflight.sh" "pip install" "No pip install command"

# ============================================================
# BROWSER-009: MCP browser availability checks Chromium cache and Chrome channel
# ============================================================
test_start "BROWSER-009" "MCP browser availability checks Chromium cache and Chrome channel"
assert_file_contains "$ROOT_DIR/.opencode/scripts/browser-verification-preflight.sh" "chromium_cache" "Checks for Chromium cache"
assert_file_contains "$ROOT_DIR/.opencode/scripts/browser-verification-preflight.sh" "chrome_channel" "Checks for Chrome channel"
assert_file_contains "$ROOT_DIR/.opencode/scripts/browser-verification-preflight.sh" "Google Chrome.app" "Checks system Chrome"

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
