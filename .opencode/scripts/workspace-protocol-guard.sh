#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$ROOT_DIR"

FAILED=0

run_check() {
  local label="$1"
  shift

  printf '\n== %s ==\n' "$label"
  if "$@"; then
    printf '[PASS] %s\n' "$label"
  else
    local code="$?"
    FAILED=1
    printf '[FAIL] %s (exit %s)\n' "$label" "$code"
  fi
}

json_config_check() {
  jq empty \
    .claude/settings.json \
    .claude/templates/repo-settings.json \
    .opencode/brain-config.json \
    .opencode/opencode.json
}

# Detect repo-level settings.json with hooks that shadow the workspace canonical version.
# All repos should inherit hooks from PersonalProjects/.claude/settings.json.
# If a repo has its own .claude/settings.json with "hooks", it's a drift violation.
hook_drift_check() {
  local drift=0
  local registry
  registry=".opencode/registry.yaml"

  # Extract repo paths from registry (lines with "path:" under repositories:)
  while IFS= read -r rel_path; do
    local settings_file="$rel_path/.claude/settings.json"
    if [ -f "$settings_file" ]; then
      # Check if it has hooks (not just settings.local.json or empty config)
      if grep -q '"hooks"' "$settings_file" 2>/dev/null; then
        echo "  DRIFT: $settings_file has hooks that shadow workspace canonical config"
        drift=1
      fi
    fi
  done < <(grep -A1 "^  [a-z]" "$registry" | grep "path:" | sed 's/.*path: *"\{0,1\}//;s/".*//' | sort -u)

  if [ "$drift" -eq 1 ]; then
    echo "  Fix: Delete repo-level .claude/settings.json that only contains hooks."
    echo "       All repos inherit from PersonalProjects/.claude/settings.json automatically."
    return 1
  fi
  return 0
}

yaml_registry_check() {
  ruby -e 'require "yaml"; YAML.load_file(".opencode/registry.yaml")'
}

submodule_metadata_check() {
  git submodule status >/dev/null
}

printf 'Workspace protocol guard\n'
printf 'Root: %s\n' "$ROOT_DIR"
printf 'Started: %s\n' "$(date -Iseconds)"

run_check "JSON config syntax" json_config_check
run_check "Registry YAML syntax" yaml_registry_check
run_check "Submodule metadata" submodule_metadata_check
run_check "Hook drift detection (no repo-level settings.json with hooks)" hook_drift_check
run_check "Workspace hygiene audit" bash .opencode/scripts/workspace-hygiene-audit.sh
run_check "Environment coherence" bash .opencode/conformance/tests/environment-coherence.sh
run_check "Launcher runtime coherence" bash .opencode/conformance/tests/global-opencode-runtime.sh
run_check "v4.5 native alignment" bash .opencode/conformance/tests/opencode-v45-native-alignment.sh
run_check "Brain config coherence" bash .opencode/scripts/brain-config-coherence.sh
run_check "MCP resolvability" bash .opencode/scripts/mcp-resolvability-check.sh
run_check "Protocol coherence Phase 1" bash .opencode/conformance/tests/protocol-coherence-phase1.sh
run_check "Protocol stabilization v4.6.1" bash .opencode/conformance/tests/protocol-stabilization-v461.sh
run_check "Protocol capabilities v4.7.0" bash .opencode/conformance/tests/protocol-capabilities-v470.sh
run_check "Owner memory runtime" bash .opencode/conformance/tests/owner-memory-runtime.sh
run_check "Git-guard compliance" bash .opencode/conformance/tests/git-guard-compliance.sh
run_check "Helper runtime" bash .opencode/conformance/tests/helper-runtime.sh
run_check "Implementation readiness" bash .opencode/conformance/tests/implementation-readiness.sh
run_check "Model routing coherence" bash .opencode/conformance/tests/model-routing-coherence.sh
run_check "Compaction safety" bash .opencode/conformance/tests/compaction-safety.sh
run_check "Visual reviewer non-empty" bash .opencode/conformance/tests/visual-reviewer-non-empty.sh
run_check "v4.17.0 throughput token consistency" bash .opencode/conformance/tests/v417-throughput-token-consistency.sh
run_check "v4.17.2 bootstrap profile drift" bash .opencode/conformance/tests/v4172-bootstrap-profile-drift.sh
run_check "v4.17.2 snapshot lineage" bash .opencode/conformance/tests/v4172-snapshot-lineage.sh
run_check "Smoke" bash .opencode/conformance/tests/smoke.sh

printf '\nFinished: %s\n' "$(date -Iseconds)"

if [[ "$FAILED" -eq 0 ]]; then
  printf '[PASS] Workspace protocol guard passed.\n'
else
  printf '[FAIL] Workspace protocol guard found drift. Fix the failing section before changing agent/runtime contracts.\n'
fi

exit "$FAILED"
