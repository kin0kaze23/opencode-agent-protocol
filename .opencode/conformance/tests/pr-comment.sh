#!/usr/bin/env bash
# pr-comment.sh — v4.39 PR Comment Conformance Tests
#
# Tests for post-release-gate-comment.sh sticky comment behavior,
# markdown generation, and failure handling.
#
# Usage: bash .opencode/conformance/tests/pr-comment.sh

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

reset_counters

echo "=== v4.39 PR Comment Conformance Tests ==="
echo ""

# ─── PC-001: post-release-gate-comment.sh exists ────────────────────────
test_start "PC-001" "comment script exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Comment script exists"

# ─── PC-002: sticky marker exists in script ─────────────────────────────
test_start "PC-002" "sticky marker defined"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "opencode-release-gate-comment" "Script has sticky comment marker"

# ─── PC-003: script has --strict flag ───────────────────────────────────
test_start "PC-003" "script supports --strict"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "--strict" "Script has --strict flag"

# ─── PC-004: script handles missing PR number ───────────────────────────
test_start "PC-004" "script handles missing PR number"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "No PR number" "Script handles missing PR number"

# ─── PC-005: script handles permission failure ──────────────────────────
test_start "PC-005" "script handles permission failure"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Failed to" "Script handles comment failure"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "permission denied" "Script detects permission issues"

# ─── PC-006: script finds existing comment ─────────────────────────────
test_start "PC-006" "script finds existing comment for update"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "EXISTING_COMMENT_ID" "Script searches for existing comment"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Updating existing" "Script updates existing comment"

# ─── PC-007: script creates new comment ─────────────────────────────────
test_start "PC-007" "script creates new comment"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Creating new comment" "Script creates new comment"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "gh pr comment" "Script uses gh pr comment"

# ─── PC-008: script generates markdown with release status ──────────────
test_start "PC-008" "comment includes release status"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Release Status" "Comment includes release status field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "RELEASE_STATUS" "Comment uses RELEASE_STATUS variable"

# ─── PC-009: comment includes risk level ────────────────────────────────
test_start "PC-009" "comment includes risk level"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Risk Level" "Comment includes risk level field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "RISK_ICON" "Comment has risk icon"

# ─── PC-010: comment includes reviewer evidence ─────────────────────────
test_start "PC-010" "comment includes reviewer evidence"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Reviewer Evidence" "Comment includes reviewer evidence section"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Evidence Found" "Comment includes evidence found field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Evidence Trusted" "Comment includes evidence trusted field"

# ─── PC-011: comment includes protection status ─────────────────────────
test_start "PC-011" "comment includes protection status"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Protection Status" "Comment includes protection status section"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "CODEOWNERS" "Comment includes CODEOWNERS status"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Branch Protection" "Comment includes branch protection status"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Trust Policy" "Comment includes trust policy status"

# ─── PC-012: comment includes owner next action ────────────────────────
test_start "PC-012" "comment includes owner next action"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Owner Next Action" "Comment includes owner next action section"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "OWNER_ACTION" "Comment uses OWNER_ACTION variable"

# ─── PC-013: block status has unblock instruction ───────────────────────
test_start "PC-013" "block status has unblock instruction"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "BLOCKED" "Comment has BLOCKED text for block status"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "approving review" "Comment has unblock instruction for approving review"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "reviewer-approved" "Comment mentions reviewer-approved label"

# ─── PC-014: advisory status has recommended text ───────────────────────
test_start "PC-014" "advisory status has recommended text"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Medium-risk" "Comment has medium-risk advisory text"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Reviewer recommended" "Comment says reviewer recommended for medium"

# ─── PC-015: pass status has concise text ───────────────────────────────
test_start "PC-015" "pass status has concise text"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "No action required" "Comment has pass text"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "safe to merge" "Comment says safe to merge for pass"

# ─── PC-016: branch protection unknown is not called protected ──────────
test_start "PC-016" "unknown branch protection not called protected"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "unknown" "Comment says unknown for branch protection"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "permission limited" "Comment says permission limited"

# ─── PC-017: comment has timestamp ─────────────────────────────────────
test_start "PC-017" "comment has timestamp"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "TIMESTAMP" "Comment has timestamp variable"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Updated:" "Comment shows update timestamp"

# ─── PC-018: comment has version tag ────────────────────────────────────
test_start "PC-018" "comment has version tag"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "v4.39" "Comment references v4.39"

# ─── PC-019: workflow has pull-requests write permission ───────────────
test_start "PC-019" "workflow has pull-requests write permission"
assert_file_contains "$ROOT_DIR/.github/workflows/pr-release-gate.yml" "pull-requests: write" "Workflow has write permission for comments"

# ─── PC-020: workflow has post comment step ─────────────────────────────
test_start "PC-020" "workflow has post comment step"
assert_file_contains "$ROOT_DIR/.github/workflows/pr-release-gate.yml" "Post PR comment" "Workflow has post comment step"
assert_file_contains "$ROOT_DIR/.github/workflows/pr-release-gate.yml" "post-release-gate-comment.sh" "Workflow calls comment script"

# ─── PC-021: installer includes comment script ──────────────────────────
test_start "PC-021" "installer includes comment script"
assert_file_contains "$ROOT_DIR/.opencode/scripts/install-release-gate.sh" "post-release-gate-comment.sh" "Installer includes comment script"

# ─── PC-022: comment failure is non-blocking by default ─────────────────
test_start "PC-022" "comment failure is non-blocking by default"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "STRICT" "Script has STRICT mode"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" 'STRICT.*true.*exit 1' "Script only fails in strict mode"

# ─── PC-023: script uses gh api for comment management ───────────────────
test_start "PC-023" "script uses gh api for comment management"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "gh api" "Script uses gh api"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "issues/comments" "Script uses issues/comments endpoint"

# ─── PC-024: comment includes sensitive areas ───────────────────────────
test_start "PC-024" "comment includes sensitive areas"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Sensitive Areas" "Comment includes sensitive areas field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "SENSITIVE_AREAS" "Comment uses SENSITIVE_AREAS variable"

# ─── PC-025: comment includes detection type ────────────────────────────
test_start "PC-025" "comment includes detection type"
assert_file_contains "$ROOT_DIR/.opencode/scripts/post-release-gate-comment.sh" "Detection Type" "Comment includes detection type field"

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
