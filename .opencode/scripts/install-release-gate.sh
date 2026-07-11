#!/usr/bin/env bash
# install-release-gate.sh — v4.37 Multi-Repo Release Gate Installer
#
# Copies the PR release gate workflow, scripts, trust policy, and docs
# into a target repo. Supports dry-run mode and refuses legacy repos.
#
# Usage:
#   bash install-release-gate.sh <target-repo-path> [--dry-run]
#
# Non-blocking: exits 0 on success, 1 on error.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TARGET_REPO=""
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN="true"; shift ;;
    *) TARGET_REPO="$1"; shift ;;
  esac
done

if [[ -z "$TARGET_REPO" ]]; then
  echo "Usage: bash install-release-gate.sh <target-repo-path> [--dry-run]"
  echo ""
  echo "Options:"
  echo "  --dry-run  Show what would be installed without making changes"
  exit 1
fi

# ─── Validate target repo ───────────────────────────────────────────────
if [[ ! -d "$TARGET_REPO" ]]; then
  echo "ERROR: Target repo does not exist: $TARGET_REPO"
  exit 1
fi

if [[ ! -d "$TARGET_REPO/.git" ]]; then
  echo "ERROR: Target is not a git repo: $TARGET_REPO"
  exit 1
fi

# ─── Refuse legacy/reference-only repos ──────────────────────────────────
REPO_NAME=$(basename "$TARGET_REPO")
case "$REPO_NAME" in
  protected-repo|protected-repo-prod)
    echo "ERROR: $REPO_NAME is legacy/reference-only — refusing to install"
    echo "protected-repo is archived. Do not touch protected-repo."
    exit 1
    ;;
  *sandbox*|*-sandbox*)
    echo "ERROR: $REPO_NAME is a sandbox repo — refusing to install"
    exit 1
    ;;
esac

# Check for legacy/reference markers in AGENTS.md or NOW.md
if [[ -f "$TARGET_REPO/NOW.md" ]]; then
  if grep -qi "legacy\|reference-only\|archived\|do-not-touch" "$TARGET_REPO/NOW.md" 2>/dev/null; then
    echo "ERROR: $REPO_NAME appears to be legacy/reference-only (NOW.md marker)"
    exit 1
  fi
fi

echo "=== Release Gate Installer ==="
echo "Target: $TARGET_REPO ($REPO_NAME)"
echo "Mode: $([ "$DRY_RUN" == "true" ] && echo "DRY RUN" || echo "INSTALL")"
echo ""

# ─── Files to install ───────────────────────────────────────────────────
declare -a FILES_TO_INSTALL=(
  ".opencode/scripts/sensitive-change-classifier.sh:.github/scripts/sensitive-change-classifier.sh"
  ".opencode/scripts/release-decision-report.sh:.github/scripts/release-decision-report.sh"
  ".opencode/scripts/reviewer-evidence-detector.sh:.github/scripts/reviewer-evidence-detector.sh"
  ".opencode/scripts/pr-release-gate-action.sh:.github/scripts/pr-release-gate-action.sh"
  ".opencode/scripts/post-release-gate-comment.sh:.github/scripts/post-release-gate-comment.sh"
  ".opencode/scripts/validate-release-gate.sh:.github/scripts/validate-release-gate.sh"
  ".github/workflows/pr-release-gate.yml:.github/workflows/pr-release-gate.yml"
  ".opencode/config/reviewer-trust-policy.yaml:.opencode/config/reviewer-trust-policy.yaml"
  "docs/PR_RELEASE_GATE.md:docs/PR_RELEASE_GATE.md"
  "docs/BRANCH_PROTECTION.md:docs/BRANCH_PROTECTION.md"
)

# ─── Install files ───────────────────────────────────────────────────────
INSTALLED=0
SKIPPED=0
BACKED_UP=0

for entry in "${FILES_TO_INSTALL[@]}"; do
  SRC="${entry%%:*}"
  DST="${entry#*:}"
  SRC_PATH="$WORKSPACE_ROOT/$SRC"
  DST_PATH="$TARGET_REPO/$DST"

  if [[ ! -f "$SRC_PATH" ]]; then
    echo "  ⚠️  Source not found: $SRC — skipping"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY RUN] Would install: $SRC → $DST"
    INSTALLED=$((INSTALLED + 1))
    continue
  fi

  # Create destination directory
  DST_DIR=$(dirname "$DST_PATH")
  mkdir -p "$DST_DIR"

  # Backup existing file if it exists
  if [[ -f "$DST_PATH" ]]; then
    cp "$DST_PATH" "${DST_PATH}.bak"
    BACKED_UP=$((BACKED_UP + 1))
  fi

  # Copy file
  cp "$SRC_PATH" "$DST_PATH"

  # Make scripts executable
  case "$DST" in
    *.sh) chmod +x "$DST_PATH" ;;
  esac

  # Fix paths for target repo (.opencode/scripts/ → .github/scripts/)
  if [[ "$DST" == .github/scripts/* ]]; then
    sed -i.bak 's|\.opencode/scripts/sensitive-change-classifier\.sh|.github/scripts/sensitive-change-classifier.sh|g' "$DST_PATH" 2>/dev/null || true
    sed -i.bak 's|\.opencode/scripts/release-decision-report\.sh|.github/scripts/release-decision-report.sh|g' "$DST_PATH" 2>/dev/null || true
    sed -i.bak 's|\.opencode/scripts/reviewer-evidence-detector\.sh|.github/scripts/reviewer-evidence-detector.sh|g' "$DST_PATH" 2>/dev/null || true
    rm -f "${DST_PATH}.bak" 2>/dev/null || true
  fi

  # Fix workflow path: .opencode/scripts/ → .github/scripts/
  if [[ "$DST" == ".github/workflows/pr-release-gate.yml" ]]; then
    sed -i.bak 's|\.opencode/scripts/pr-release-gate-action\.sh|.github/scripts/pr-release-gate-action.sh|g' "$DST_PATH" 2>/dev/null || true
    rm -f "${DST_PATH}.bak" 2>/dev/null || true
  fi

  # Fix docs paths: .opencode/scripts/ → .github/scripts/
  if [[ "$DST" == docs/PR_RELEASE_GATE.md ]]; then
    sed -i.bak 's|\.opencode/scripts/sensitive-change-classifier\.sh|.github/scripts/sensitive-change-classifier.sh|g' "$DST_PATH" 2>/dev/null || true
    sed -i.bak 's|\.opencode/scripts/release-decision-report\.sh|.github/scripts/release-decision-report.sh|g' "$DST_PATH" 2>/dev/null || true
    sed -i.bak 's|\.opencode/scripts/pr-release-gate-action\.sh|.github/scripts/pr-release-gate-action.sh|g' "$DST_PATH" 2>/dev/null || true
    sed -i.bak 's|\.opencode/scripts/post-release-gate-comment\.sh|.github/scripts/post-release-gate-comment.sh|g' "$DST_PATH" 2>/dev/null || true
    rm -f "${DST_PATH}.bak" 2>/dev/null || true
  fi

  # Fix trust policy path in detector
  if [[ "$DST" == ".github/scripts/reviewer-evidence-detector.sh" ]]; then
    sed -i.bak 's|POLICY_FILE="$SCRIPT_DIR/../config/reviewer-trust-policy.yaml"|POLICY_FILE="$SCRIPT_DIR/../../.opencode/config/reviewer-trust-policy.yaml"|g' "$DST_PATH" 2>/dev/null || true
    rm -f "${DST_PATH}.bak" 2>/dev/null || true
  fi

  echo "  ✅ Installed: $DST"
  INSTALLED=$((INSTALLED + 1))
done

echo ""
echo "=== Summary ==="
echo "Installed: $INSTALLED files"
echo "Skipped: $SKIPPED files"
echo "Backed up: $BACKED_UP files"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Dry run complete. Run without --dry-run to install."
else
  echo "Installation complete."
  echo ""
  echo "Next steps:"
  echo "  1. Run: bash .github/scripts/validate-release-gate.sh"
  echo "  2. Configure branch protection (see docs/BRANCH_PROTECTION.md)"
  echo "  3. Create a test PR to verify the gate works"
  echo "  4. Customize .opencode/config/reviewer-trust-policy.yaml if needed"
fi
