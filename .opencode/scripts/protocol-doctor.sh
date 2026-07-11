#!/usr/bin/env bash
# Protocol Doctor — Read-only health check for OpenCode AgentOps protocol
# Usage: bash .opencode/scripts/protocol-doctor.sh
# Output: Markdown report with GREEN/YELLOW/ORANGE/RED classification

set -euo pipefail

# Colors for terminal output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Tracking
ISSUES=()
WARNINGS=()
INFO=()
COMPACTION_NEEDS_HARNESS=0  # Set to 1 when compaction status requires test harness recommendation

log_info() {
  INFO+=("$1")
  echo -e "${BLUE}ℹ${NC} $1"
}

log_warning() {
  WARNINGS+=("$1")
  echo -e "${YELLOW}⚠${NC} $1"
}

log_issue() {
  ISSUES+=("$1")
  echo -e "${RED}✗${NC} $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

echo "# Protocol Doctor Health Check"
echo ""
echo "**Timestamp**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo "**Working Directory**: $(pwd)"
echo ""

# ============================================================================
# 1. Git / Commit-Scope Hygiene
# ============================================================================
echo "## 1. Git / Commit-Scope Hygiene"
echo ""

# Current branch
BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
log_info "Current branch: \`$BRANCH\`"

# Dirty file count
DIRTY_COUNT=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
if [ "$DIRTY_COUNT" -gt 0 ]; then
  log_warning "Working tree has $DIRTY_COUNT dirty files"
else
  log_success "Working tree is clean"
fi

# Staged files
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || true)
if [ -n "$STAGED_FILES" ]; then
  STAGED_COUNT=$(echo "$STAGED_FILES" | wc -l | tr -d ' ')
  log_warning "$STAGED_COUNT files are staged (may indicate incomplete scoped commit):"
  echo "$STAGED_FILES" | sed 's/^/  - /'
else
  log_success "No files staged"
fi

# Last commit scope
LAST_COMMIT=$(git log -1 --format="%h %s" 2>/dev/null || echo "none")
LAST_COMMIT_FILES=$(git log -1 --name-only --format="" 2>/dev/null | wc -l | tr -d ' ')
log_info "Last commit: \`$LAST_COMMIT\` ($LAST_COMMIT_FILES files)"

echo ""

# ============================================================================
# 2. Commit-Scope Guard
# ============================================================================
echo "## 2. Commit-Scope Guard"
echo ""

GUARD_SCRIPT=".opencode/scripts/commit-scope-guard.sh"

# Check if guard script exists
if [ -f "$GUARD_SCRIPT" ]; then
  log_success "Guard script: exists"
else
  log_issue "Guard script: missing"
fi

# Check if executable
if [ -x "$GUARD_SCRIPT" ]; then
  log_success "Guard script: executable"
else
  log_warning "Guard script: not executable"
fi

# Syntax check
if [ -f "$GUARD_SCRIPT" ]; then
  if bash -n "$GUARD_SCRIPT" 2>/dev/null; then
    log_success "Guard script: syntax OK"
  else
    log_issue "Guard script: syntax error"
  fi
fi

# Check staged files
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || true)
if [ -n "$STAGED_FILES" ]; then
  STAGED_COUNT=$(echo "$STAGED_FILES" | wc -l | tr -d ' ')
  log_warning "Staged files: $STAGED_COUNT"
  echo "$STAGED_FILES" | sed 's/^/  - /'
  echo ""
  log_warning "Scoped commits require an explicit allowlist"
  log_info "Recommended command:"
  ALLOWED_LIST=$(echo "$STAGED_FILES" | tr '\n' ' ')
  echo "  $GUARD_SCRIPT --allowed $ALLOWED_LIST"
else
  log_success "Staged files: 0 (clean staged state)"
fi

# Optional: run guard if COMMIT_SCOPE_ALLOWED is set
if [ -n "${COMMIT_SCOPE_ALLOWED:-}" ]; then
  log_info "COMMIT_SCOPE_ALLOWED environment variable set: $COMMIT_SCOPE_ALLOWED"
  # Split space-separated list into array
  read -ra ALLOWED_ARRAY <<< "$COMMIT_SCOPE_ALLOWED"
  if "$GUARD_SCRIPT" --allowed "${ALLOWED_ARRAY[@]}" > /dev/null 2>&1; then
    log_success "Scope validation: PASS"
  else
    log_issue "Scope validation: FAIL"
    log_info "Run '$GUARD_SCRIPT --allowed $COMMIT_SCOPE_ALLOWED' for details"
  fi
else
  log_info "Scope validation: not attempted (COMMIT_SCOPE_ALLOWED not set)"
fi

echo ""

# ============================================================================
# 3. Plugin Health
# ============================================================================
echo "## 3. Plugin Health"
echo ""

# Find latest log
LATEST_LOG=$(ls -t ~/.local/share/opencode/log/*.log 2>/dev/null | head -1 || true)

if [ -z "$LATEST_LOG" ]; then
  log_issue "No OpenCode log files found"
else
  log_info "Latest log: \`$LATEST_LOG\`"

  # Check plugin startup
  if grep -q "brain-hooks plugin initialized" "$LATEST_LOG" 2>/dev/null; then
    log_success "Plugin startup confirmed"
  else
    log_issue "Plugin startup not found in logs"
  fi

  # Compaction hook classification
  if grep -q "compaction hook: context injected" "$LATEST_LOG" 2>/dev/null; then
    log_success "Compaction hook: CONFIRMED_WITH_CONTEXT"
  elif grep -q "compaction hook: no context generated" "$LATEST_LOG" 2>/dev/null; then
    log_warning "Compaction hook: CONFIRMED_NO_CONTEXT"
  elif grep -q "compaction hook entered" "$LATEST_LOG" 2>/dev/null; then
    log_warning "Compaction hook: CONFIRMED (entered but no context log)"
  elif grep -q "session.compaction.*pruned=0.*total=0" "$LATEST_LOG" 2>/dev/null; then
    log_warning "Compaction hook: UNVERIFIED_NO_REAL_COMPACTION (only pruning seen)"
    COMPACTION_NEEDS_HARNESS=1
  elif grep -q "session.compaction" "$LATEST_LOG" 2>/dev/null; then
    log_issue "Compaction hook: BROKEN (compaction occurred but hook did not enter)"
    COMPACTION_NEEDS_HARNESS=1
  else
    log_warning "Compaction hook: UNVERIFIED (no compaction events in log)"
  fi

  # validateResponse metrics
  METRICS_DIR=".opencode/metrics/empty-response"
  if [ -d "$METRICS_DIR" ]; then
    METRIC_COUNT=$(find "$METRICS_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$METRIC_COUNT" -gt 0 ]; then
      log_success "validateResponse: CONFIRMED ($METRIC_COUNT metrics files)"
    else
      log_warning "validateResponse: UNVERIFIED (no metrics files)"
    fi
  else
    log_warning "validateResponse: UNVERIFIED (metrics directory missing)"
  fi

  # chat.message evidence
  if grep -qE "chat\.message|drift|continuity" "$LATEST_LOG" 2>/dev/null; then
    log_success "chat.message: Evidence found"
  else
    log_warning "chat.message: UNVERIFIED (no evidence)"
  fi

  # Plugin errors
  PLUGIN_ERRORS=$(grep -iE "brain-hooks.*error|plugin.*fail|exception.*brain" "$LATEST_LOG" 2>/dev/null | wc -l | tr -d ' ') || PLUGIN_ERRORS=0
  if [ "$PLUGIN_ERRORS" -gt 0 ]; then
    log_issue "Plugin errors: $PLUGIN_ERRORS errors found"
  else
    log_success "Plugin errors: None"
  fi
fi

echo ""

# ============================================================================
# 4. Command Registry
# ============================================================================
echo "## 4. Command Registry"
echo ""

COMMAND_COUNT=$(find .opencode/commands -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
log_info "Total commands: $COMMAND_COUNT"

# Check for missing frontmatter
COMMANDS_NO_FRONTMATTER=()
for cmd in .opencode/commands/*.md; do
  if [ -f "$cmd" ]; then
    FIRST_LINE=$(head -1 "$cmd")
    if [ "$FIRST_LINE" != "---" ]; then
      COMMANDS_NO_FRONTMATTER+=("$(basename "$cmd")")
    fi
  fi
done

if [ ${#COMMANDS_NO_FRONTMATTER[@]} -gt 0 ]; then
  log_warning "Commands missing YAML frontmatter: ${#COMMANDS_NO_FRONTMATTER[@]}"
  printf '  - %s\n' "${COMMANDS_NO_FRONTMATTER[@]}"
else
  log_success "All commands have YAML frontmatter"
fi

# Check for duplicates with .claude/commands
if [ -d ".claude/commands" ]; then
  DUPLICATES=()
  for cmd in .opencode/commands/*.md; do
    BASENAME=$(basename "$cmd")
    if [ -f ".claude/commands/$BASENAME" ]; then
      DUPLICATES+=("$BASENAME")
    fi
  done

  if [ ${#DUPLICATES[@]} -gt 0 ]; then
    log_warning "Duplicate commands (exist in both .opencode/commands and .claude/commands): ${#DUPLICATES[@]}"
    printf '  - %s\n' "${DUPLICATES[@]}"
  else
    log_success "No duplicate commands"
  fi
else
  log_info ".claude/commands directory not found (skipping duplicate check)"
fi

echo ""

# ============================================================================
# 5. Skill Registry
# ============================================================================
echo "## 5. Skill Registry"
echo ""

SKILL_COUNT=$(find .opencode/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
log_info "Total skills: $SKILL_COUNT"

# Check for missing frontmatter
SKILLS_NO_FRONTMATTER=()
for skill in .opencode/skills/*/SKILL.md; do
  if [ -f "$skill" ]; then
    FIRST_LINE=$(head -1 "$skill")
    if [ "$FIRST_LINE" != "---" ]; then
      SKILLS_NO_FRONTMATTER+=("$(basename "$(dirname "$skill")")")
    fi
  fi
done

if [ ${#SKILLS_NO_FRONTMATTER[@]} -gt 0 ]; then
  log_warning "Skills missing YAML frontmatter: ${#SKILLS_NO_FRONTMATTER[@]}"
  printf '  - %s\n' "${SKILLS_NO_FRONTMATTER[@]}"
else
  log_success "All skills have YAML frontmatter"
fi

echo ""

# ============================================================================
# 6. Productivity Gains Registry
# ============================================================================
echo "## 6. Productivity Gains Registry"
echo ""

PGR_YAML=".opencode/registry/productivity-gains.yaml"
PGR_DOCS=".opencode/docs/productivity-gains.md"

# Check existence
if [ -f "$PGR_YAML" ]; then
  log_success "PGR YAML: exists"
else
  log_issue "PGR YAML: missing ($PGR_YAML)"
fi

if [ -f "$PGR_DOCS" ]; then
  log_success "PGR docs: exists"
else
  log_warning "PGR docs: missing ($PGR_DOCS)"
fi

# YAML syntax check
if [ -f "$PGR_YAML" ]; then
  if ruby -e 'require "yaml"; YAML.load_file("'"$PGR_YAML"'")' 2>/dev/null; then
    log_success "PGR YAML: syntax OK"
  else
    log_issue "PGR YAML: syntax error"
  fi

  # Line count and threshold warning
  PGR_LINES=$(wc -l < "$PGR_YAML" | tr -d ' ')
  log_info "PGR YAML: $PGR_LINES lines"
  if [ "$PGR_LINES" -gt 1500 ]; then
    log_warning "PGR YAML: exceeds 1500-line target ($PGR_LINES lines)"
  fi

  # Unique ID check
  PGR_IDS=$(grep -E '^\s+- id:' "$PGR_YAML" 2>/dev/null | sed 's/.*id: *"\{0,1\}//;s/"\{0,1\} *$//' | sort)
  PGR_ID_COUNT=$(echo "$PGR_IDS" | wc -l | tr -d ' ')
  PGR_UNIQUE_COUNT=$(echo "$PGR_IDS" | sort -u | wc -l | tr -d ' ')
  log_info "PGR entries: $PGR_ID_COUNT total, $PGR_UNIQUE_COUNT unique IDs"
  if [ "$PGR_ID_COUNT" -ne "$PGR_UNIQUE_COUNT" ]; then
    log_issue "PGR YAML: duplicate IDs detected"
    DUPLICATE_IDS=$(echo "$PGR_IDS" | sort | uniq -d)
    if [ -n "$DUPLICATE_IDS" ]; then
      echo "$DUPLICATE_IDS" | sed 's/^/  - duplicate: /'
    fi
  else
    log_success "PGR YAML: all IDs unique"
  fi

  # Version consistency check (YAML comment vs docs)
  if [ -f "$PGR_DOCS" ]; then
    YAML_COMMENT_VERSION=$(grep -E '^# Version:' "$PGR_YAML" 2>/dev/null | head -1 | sed 's/.*Version: *//' | tr -d ' ')
    DOCS_VERSION=$(grep -E 'Version:\*\*' "$PGR_DOCS" 2>/dev/null | head -1 | sed 's/.*Version:\*\* *//' | tr -d ' ')
    if [ -n "$YAML_COMMENT_VERSION" ] && [ -n "$DOCS_VERSION" ]; then
      if [ "$YAML_COMMENT_VERSION" = "$DOCS_VERSION" ]; then
        log_success "PGR version: consistent ($YAML_COMMENT_VERSION)"
      else
        log_warning "PGR version: mismatch (YAML: $YAML_COMMENT_VERSION, docs: $DOCS_VERSION)"
      fi
    fi
  fi
fi

echo ""

# ============================================================================
# 7. Protocol Version Drift
# ============================================================================
echo "## 7. Protocol Version Drift"
echo ""

VERSION_FILES=(
  ".opencode/AGENTS.md"
  ".opencode/helper-roster.md"
  ".opencode/brain-config.json"
  ".opencode/model-registry.yaml"
  ".opencode/rules.md"
)

VERSION_LABELS=()
for file in "${VERSION_FILES[@]}"; do
  if [ -f "$file" ]; then
    # Try to extract version label (various patterns)
    VERSION=$(grep -oE "(v[0-9]+\.[0-9]+(\.[0-9]+)?|version.*[0-9]+\.[0-9]+)" "$file" 2>/dev/null | head -1 || true)
    if [ -n "$VERSION" ]; then
      VERSION_LABELS+=("$file: $VERSION")
    fi
  fi
done

if [ ${#VERSION_LABELS[@]} -gt 0 ]; then
  log_info "Version labels found:"
  printf '  - %s\n' "${VERSION_LABELS[@]}"

  # Check for mismatches (simple check: count unique versions)
  UNIQUE_VERSIONS=$(printf '%s\n' "${VERSION_LABELS[@]}" | grep -oE "v[0-9]+\.[0-9]+(\.[0-9]+)?" | sort -u | wc -l | tr -d ' ')
  if [ "$UNIQUE_VERSIONS" -gt 1 ]; then
    log_warning "Version drift detected: $UNIQUE_VERSIONS different version labels"
  else
    log_success "Version labels consistent"
  fi
else
  log_info "No version labels found (skipping drift check)"
fi

echo ""

# ============================================================================
# 8. Runtime / Tooling Availability
# ============================================================================
echo "## 8. Runtime / Tooling Availability"
echo ""

# Playwright CLI
if command -v playwright &> /dev/null; then
  PLAYWRIGHT_VERSION=$(playwright --version 2>/dev/null || echo "unknown")
  log_success "Playwright CLI: $PLAYWRIGHT_VERSION"
else
  log_warning "Playwright CLI: not found"
fi

# Playwright MCP
if [ -f ".opencode/opencode.json" ]; then
  if grep -q '"playwright".*"enabled".*true' .opencode/opencode.json 2>/dev/null; then
    log_success "Playwright MCP: enabled"
  elif grep -q '"playwright"' .opencode/opencode.json 2>/dev/null; then
    log_warning "Playwright MCP: disabled"
  else
    log_info "Playwright MCP: not configured"
  fi
else
  log_info ".opencode/opencode.json not found"
fi

# Pre-commit hook
if [ -f ".git/hooks/pre-commit" ]; then
  log_success "Pre-commit hook: installed"
else
  log_warning "Pre-commit hook: not installed"
fi

# Pre-push hook
if [ -f ".git/hooks/pre-push" ]; then
  log_success "Pre-push hook: installed"
else
  log_warning "Pre-push hook: not installed"
fi

# Git-guard script
if [ -f ".opencode/git-guard/git-guard.sh" ]; then
  log_success "Git-guard script: exists"
else
  log_warning "Git-guard script: missing"
fi

# Prompt parity script
if [ -f ".opencode/scripts/sync-opencode-runtime.sh" ]; then
  log_success "Prompt parity script: exists"
else
  log_warning "Prompt parity script: missing"
fi

echo ""

# ============================================================================
# 9. Repo Contract Completeness
# ============================================================================
echo "## 9. Repo Contract Completeness"
echo ""

if [ -f "WORKSPACE_MAP.md" ]; then
  log_info "WORKSPACE_MAP.md found"

  # Extract active projects (simple heuristic: lines with "✅" or "active")
  ACTIVE_PROJECTS=$(grep -E "✅|active" WORKSPACE_MAP.md 2>/dev/null | grep -oE "[A-Za-z0-9_-]+/" | sed 's/\///' | sort -u || true)

  if [ -n "$ACTIVE_PROJECTS" ]; then
    MISSING_CONTRACTS=()
    while IFS= read -r project; do
      if [ -n "$project" ] && [ -d "$project" ]; then
        if [ ! -f "$project/AGENTS.md" ]; then
          MISSING_CONTRACTS+=("$project/AGENTS.md")
        fi
        if [ ! -f "$project/NOW.md" ]; then
          MISSING_CONTRACTS+=("$project/NOW.md")
        fi
      fi
    done <<< "$ACTIVE_PROJECTS"

    if [ ${#MISSING_CONTRACTS[@]} -gt 0 ]; then
      log_warning "Missing repo contracts: ${#MISSING_CONTRACTS[@]}"
      printf '  - %s\n' "${MISSING_CONTRACTS[@]}"
    else
      log_success "All active projects have AGENTS.md and NOW.md"
    fi
  else
    log_info "No active projects detected in WORKSPACE_MAP.md"
  fi
else
  log_info "WORKSPACE_MAP.md not found (skipping contract check)"
fi

echo ""

# ============================================================================
# 10. Final Recommendation
# ============================================================================
echo "## 10. Final Recommendation"
echo ""

# Determine overall classification
if [ ${#ISSUES[@]} -gt 0 ]; then
  if [ ${#ISSUES[@]} -ge 3 ]; then
    CLASSIFICATION="RED"
  else
    CLASSIFICATION="ORANGE"
  fi
elif [ ${#WARNINGS[@]} -gt 5 ]; then
  CLASSIFICATION="YELLOW"
elif [ ${#WARNINGS[@]} -gt 0 ]; then
  CLASSIFICATION="YELLOW"
else
  CLASSIFICATION="GREEN"
fi

echo "**Overall Classification**: **$CLASSIFICATION**"
echo ""
echo "- Issues: ${#ISSUES[@]}"
echo "- Warnings: ${#WARNINGS[@]}"
echo "- Info: ${#INFO[@]}"
echo ""

# Recommend next commit
echo "### Recommended Next Commit"
echo ""

# NOTE: Do NOT use recursive self-call here (e.g., `bash protocol-doctor.sh`).
# Self-recursion causes infinite recursion and timeout. Use cached state instead.
if [ ${#COMMANDS_NO_FRONTMATTER[@]} -gt 10 ]; then
  echo "**Command frontmatter standardization**"
  echo ""
  echo "Add YAML frontmatter to ${#COMMANDS_NO_FRONTMATTER[@]} commands missing it."
elif [ ${#SKILLS_NO_FRONTMATTER[@]} -gt 5 ]; then
  echo "**Skill frontmatter standardization**"
  echo ""
  echo "Add YAML frontmatter to ${#SKILLS_NO_FRONTMATTER[@]} skills missing it."
elif [ "$COMPACTION_NEEDS_HARNESS" -eq 1 ]; then
  echo "**Compaction test harness**"
  echo ""
  echo "Create a test that triggers real compaction and verifies hook behavior."
elif [ ${#WARNINGS[@]} -gt 0 ]; then
  echo "**Touch-list enforcement hook**"
  echo ""
  echo "Add a plugin hook to enforce touch-list discipline before file edits."
else
  echo "**Commit-scope guard**"
  echo ""
  echo "Add a pre-commit hook that warns when committing files outside declared scope."
fi

echo ""
echo "---"
echo ""
echo "*Report generated by Protocol Doctor v1.0*"
