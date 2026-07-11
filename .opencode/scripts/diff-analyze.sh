#!/usr/bin/env bash
# diff-analyze.sh — v4.17.0 Diff-Aware Gate Selection
# Purpose: Analyze git diff to classify the change and recommend which gates to run/skip
#
# Usage:
#   bash .opencode/scripts/diff-analyze.sh [repo_path]
#
# Output: machine-readable lines for agent consumption
#   DIFF_CLASSIFICATION: <text_only|css_color_spacing|css_layout|import_paths|type_annotations|comments_docs|test_files_only|config_non_runtime|component_change|logic_change|security_change|routing_change|config_change|cross_surface>
#   CHANGED_FILES: <count>
#   RECOMMENDED_GATES: lint,typecheck,test,build
#   SKIP_GATES: browser_verification,a11y,visual_regression
#   REASON: <why gates were skipped>

set -euo pipefail

REPO_PATH="${1:-.}"
cd "$REPO_PATH" 2>/dev/null || { echo "DIFF_CLASSIFICATION: error"; echo "REASON: cannot cd to $REPO_PATH"; exit 1; }

# Get changed files (staged + unstaged, not committed)
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || git diff --name-only 2>/dev/null || echo "")
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || echo "")
ALL_FILES=$(echo -e "$CHANGED_FILES\n$STAGED_FILES" | sort -u | grep -v '^$' || echo "")

FILE_COUNT=$(echo "$ALL_FILES" | grep -c '.' 2>/dev/null | tr -d '\n ' || echo "0")

# If no files changed, return default
if [[ "$FILE_COUNT" -eq 0 || -z "$ALL_FILES" ]]; then
  echo "DIFF_CLASSIFICATION: no_changes"
  echo "CHANGED_FILES: 0"
  echo "RECOMMENDED_GATES: lint"
  echo "SKIP_GATES: typecheck,test,build,browser_verification,a11y,visual_regression"
  echo "REASON: no files changed"
  exit 0
fi

echo "CHANGED_FILES: $FILE_COUNT"

# Classify files by type
has_tsx=false
has_ts=false
has_jsx=false
has_js=false
has_css=false
has_test=false
has_config=false
has_md=false
has_py=false
has_rs=false
has_auth=false
has_schema=false
has_route=false
has_deploy=false
has_lockfile=false
has_env=false
has_gate_def=false

# Check each file
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  case "$file" in
    *.tsx) has_tsx=true ;;
    *.ts) has_ts=true ;;
    *.jsx) has_jsx=true ;;
    *.js) has_js=true ;;
    *.css|*.scss|*.less) has_css=true ;;
    *.test.*|*.spec.*|tests/*|e2e/*|__tests__/*) has_test=true ;;
    *.eslintrc*|.prettierrc*|tsconfig*.json|jsconfig*.json) has_config=true ;;
    *.md) has_md=true ;;
    *.py) has_py=true ;;
    *.rs) has_rs=true ;;
  esac
  # Check for sensitive paths
  case "$file" in
    *auth*|*login*|*session*|*password*|*crypto*|*token*) has_auth=true ;;
    *schema*|*migration*|*prisma*|*drizzle*) has_schema=true ;;
    *route*|*router*|*navigation*|*app/*) has_route=true ;;
    *deploy*|*docker*|*Dockerfile*|*docker-compose*|*.env*|*vercel.json*|*wrangler*) has_deploy=true ;;
  esac
  # v4.17.2: Check for lockfile, env, and gate definition changes
  case "$file" in
    *lock*|*package-lock.json|*pnpm-lock.yaml|*yarn.lock|*Cargo.lock|*poetry.lock) has_lockfile=true ;;
    *.env*|*.env.template|*.env.example|*.env.local) has_env=true ;;
    *.opencode/config/*|*.opencode/scripts/*|*.opencode/conformance/*|*.opencode/commands/*) has_gate_def=true ;;
  esac
done <<< "$ALL_FILES"

# Get the actual diff content for deeper analysis
DIFF_CONTENT=$(git diff HEAD 2>/dev/null || git diff 2>/dev/null || echo "")

# Analyze diff content for classification
# Check if changes are only string literals / text content
only_strings=false
only_comments=false
only_imports=false
only_types=false
only_css_color=false

if [[ -n "$DIFF_CONTENT" ]]; then
  # Count added lines (starting with +, excluding +++ headers)
  ADDED_LINES=$(echo "$DIFF_CONTENT" | grep '^+' | grep -v '^+++' | grep -v '^+$' || echo "")
  ADDED_COUNT=$(echo "$ADDED_LINES" | grep -c '.' 2>/dev/null | tr -d '\n ' || echo "0")

  if [[ "$ADDED_COUNT" -gt 0 ]]; then
    # Check if all added lines are string literals or JSX text
    string_only=$(echo "$ADDED_LINES" | grep -vE '^\+.*(const|let|var|function|class|import|export|if|for|while|return|=>|\{|\}|\(|\))' | grep -c '+' 2>/dev/null | tr -d '\n ' || echo "0")
    if [[ "$string_only" -eq "$ADDED_COUNT" ]]; then
      only_strings=true
    fi

    # Check if all added lines are comments
    comment_only=$(echo "$ADDED_LINES" | grep -E '^\+(\s*//|\s*#|\s*\*|\s*/\*)' | grep -c '+' 2>/dev/null | tr -d '\n ' || echo "0")
    if [[ "$comment_only" -eq "$ADDED_COUNT" ]]; then
      only_comments=true
    fi

    # Check if all added lines are import statements
    import_only=$(echo "$ADDED_LINES" | grep -E '^\+.*(import|from|require)' | grep -c '+' 2>/dev/null | tr -d '\n ' || echo "0")
    if [[ "$import_only" -eq "$ADDED_COUNT" ]]; then
      only_imports=true
    fi

    # Check if all added lines are type annotations
    type_only=$(echo "$ADDED_LINES" | grep -E '^\+.*(interface|type |: string|: number|: boolean|: void|<.*>|as )' | grep -c '+' 2>/dev/null | tr -d '\n ' || echo "0")
    if [[ "$type_only" -eq "$ADDED_COUNT" ]]; then
      only_types=true
    fi
  fi
fi

# Determine classification (priority order: security > routing > deploy > content type)
classification="component_change"
skip_gates=""
recommended_gates="lint,typecheck"
reason=""

if [[ "$has_auth" == "true" ]]; then
  classification="security_change"
  recommended_gates="lint,typecheck,test,build,sast,reviewer"
  skip_gates=""
  reason="auth/security path touched — full verification required"
elif [[ "$has_schema" == "true" ]]; then
  classification="security_change"
  recommended_gates="lint,typecheck,test,build,sast,reviewer"
  skip_gates=""
  reason="schema/migration path touched — full verification required"
elif [[ "$has_deploy" == "true" ]]; then
  classification="config_change"
  recommended_gates="lint,config_validate,build"
  skip_gates="test,browser_verification"
  reason="deployment/config change — infra validation required"
elif [[ "$has_route" == "true" ]]; then
  classification="routing_change"
  recommended_gates="lint,typecheck,build,route_smoke"
  skip_gates=""
  reason="routing/navigation changed — route smoke test required"
elif [[ "$only_comments" == "true" ]]; then
  classification="comments_docs"
  recommended_gates="lint"
  skip_gates="typecheck,test,build,browser_verification,a11y,visual_regression"
  reason="only comments/docs changed — no code behavior change"
elif [[ "$only_imports" == "true" ]]; then
  classification="import_paths"
  recommended_gates="lint,typecheck,targeted_test"
  skip_gates="build,browser_verification"
  reason="only import paths changed — no behavior change"
elif [[ "$only_types" == "true" ]]; then
  classification="type_annotations"
  recommended_gates="lint,typecheck"
  skip_gates="test,build,browser_verification"
  reason="only type annotations changed — no runtime behavior change"
elif [[ "$only_strings" == "true" && "$has_tsx" != "true" && "$has_css" != "true" ]]; then
  classification="text_only"
  recommended_gates="lint"
  skip_gates="typecheck,test,build,browser_verification,a11y,visual_regression"
  reason="only string/text content changed — no structural change"
elif [[ "$has_css" == "true" && "$has_tsx" != "true" && "$has_ts" != "true" ]]; then
  # CSS-only change — check if layout properties
  layout_changed=$(echo "$DIFF_CONTENT" | grep -E '^\+.*(display|flex|grid|position|float|clear|overflow|width|height|max-width|min-width)' | grep -c '+' 2>/dev/null | tr -d '\n ' || echo "0")
  if [[ "$layout_changed" -gt 0 ]]; then
    classification="css_layout"
    recommended_gates="lint,typecheck,screenshot,visual_regression"
    skip_gates="a11y_semantics,keyboard,aria"
    reason="CSS layout properties changed — responsive + visual regression required"
  else
    classification="css_color_spacing"
    recommended_gates="lint,typecheck,screenshot"
    skip_gates="a11y_semantics,keyboard,aria,responsive_matrix"
    reason="CSS color/spacing only — visual appearance changed, not structure"
  fi
elif [[ "$has_test" == "true" && "$has_tsx" != "true" && "$has_ts" != "true" && "$has_css" != "true" ]]; then
  classification="test_files_only"
  recommended_gates="lint,typecheck,test"
  skip_gates="build,browser_verification"
  reason="only test files changed — tests don't affect production bundle"
elif [[ "$has_config" == "true" && "$has_tsx" != "true" && "$has_ts" != "true" ]]; then
  classification="config_non_runtime"
  recommended_gates="lint,typecheck"
  skip_gates="test,browser_verification,build"
  reason="non-runtime config changed — doesn't affect runtime behavior"
elif [[ "$FILE_COUNT" -gt 5 ]]; then
  classification="cross_surface"
  recommended_gates="lint,typecheck,test,build,browser_verification,a11y,visual_regression"
  skip_gates=""
  reason="large cross-surface change — full verification required"
else
  # Default: component or logic change
  if [[ "$has_tsx" == "true" || "$has_jsx" == "true" ]]; then
    classification="component_change"
    recommended_gates="lint,typecheck,targeted_test,screenshot"
    skip_gates=""
    reason="component change — targeted UI verification required"
  elif [[ "$has_ts" == "true" || "$has_js" == "true" || "$has_py" == "true" || "$has_rs" == "true" ]]; then
    classification="logic_change"
    recommended_gates="lint,typecheck,targeted_test,build"
    skip_gates="browser_verification"
    reason="logic change — targeted tests + build required"
  fi
fi

# v4.17.2: Conservative fallback — lockfile, env, gate definition, or unknown changes get full suite
if [[ "$has_lockfile" == "true" ]]; then
  classification="lockfile_change"
  recommended_gates="lint,typecheck,test,build"
  skip_gates=""
  reason="lockfile changed — full verification required (dependencies may have shifted)"
elif [[ "$has_env" == "true" ]]; then
  classification="env_change"
  recommended_gates="lint,typecheck,test,build,infra_validation"
  skip_gates=""
  reason="environment file changed — full verification + infra validation required"
elif [[ "$has_gate_def" == "true" ]]; then
  classification="gate_definition_change"
  recommended_gates="lint,typecheck,test,build"
  skip_gates=""
  reason="gate definition changed — full verification required (gate behavior may have shifted)"
elif [[ "$classification" == "component_change" && -z "$reason" ]]; then
  # v4.17.2: Conservative fallback — if classification is still default and no reason was set,
  # escalate to full suite rather than under-testing
  classification="unknown"
  recommended_gates="lint,typecheck,test,build,browser_verification,a11y,visual_regression"
  skip_gates=""
  reason="unknown/ambiguous change — conservative fallback to full suite (v4.17.2)"
fi

echo "DIFF_CLASSIFICATION: $classification"
echo "RECOMMENDED_GATES: $recommended_gates"
if [[ -n "$skip_gates" ]]; then
  echo "SKIP_GATES: $skip_gates"
fi
echo "REASON: $reason"
