#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"

FAILED=0
PASS=0

check_file_exists() {
  local file="$1"
  local label="$2"
  if [[ -f "$file" ]]; then
    printf '[PASS] %s\n' "$label"
    PASS=$((PASS + 1))
  else
    printf '[FAIL] %s\n  missing file: %s\n' "$label" "$file"
    FAILED=$((FAILED + 1))
  fi
}

check_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -Fq "$pattern" "$file"; then
    printf '[PASS] %s\n' "$label"
    PASS=$((PASS + 1))
  else
    printf '[FAIL] %s\n  missing: %s in %s\n' "$label" "$pattern" "$file"
    FAILED=$((FAILED + 1))
  fi
}

check_not_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -Fq "$pattern" "$file"; then
    printf '[FAIL] %s\n  forbidden: %s in %s\n' "$label" "$pattern" "$file"
    FAILED=$((FAILED + 1))
  else
    printf '[PASS] %s\n' "$label"
    PASS=$((PASS + 1))
  fi
}

check_json_equals() {
  local file="$1"
  local jq_expr="$2"
  local expected="$3"
  local label="$4"
  local actual
  actual="$(jq -r "$jq_expr" "$file")"
  if [[ "$actual" == "$expected" ]]; then
    printf '[PASS] %s\n' "$label"
    PASS=$((PASS + 1))
  else
    printf '[FAIL] %s\n  expected: %s\n  actual:   %s\n' "$label" "$expected" "$actual"
    FAILED=$((FAILED + 1))
  fi
}

BRAIN_CONFIG="$ROOT_DIR/.opencode/brain-config.json"
NOW="$ROOT_DIR/NOW.md"
TEMPLATES_DIR="$ROOT_DIR/.opencode/templates"
SKILLS_DIR="$ROOT_DIR/.opencode/skills"
COMMANDS_DIR="$ROOT_DIR/.opencode/commands"
ROLES_DIR="$ROOT_DIR/.opencode/role-profiles"
DOCS_DIR="$ROOT_DIR/docs/opencode/v4.7.0"
GUARD="$ROOT_DIR/.opencode/scripts/workspace-protocol-guard.sh"

printf 'OpenCode v4.27.1 active capability checks\n'
printf 'Root: %s\n' "$ROOT_DIR"
printf 'Status: production core baseline; v4.27.1 active.\n'

printf 'This script is read-only and verifies active v4.27.1 capability surfaces.\n\n'

# v4.27.1: Version checks are now dynamic — read version from brain-config.json
# and verify all surfaces match, rather than hardcoding a specific version.
PROTOCOL_VERSION="$(jq -r '.version' "$BRAIN_CONFIG")"
check_json_equals "$BRAIN_CONFIG" '.version' "$PROTOCOL_VERSION" "active brain-config version is v$PROTOCOL_VERSION"
check_contains "$NOW" "v$PROTOCOL_VERSION" "NOW documents v$PROTOCOL_VERSION active baseline"

for template in README.md PRD.md DESIGN_BRIEF.md QA_PLAN.md THREAT_MODEL.md ADR.md PROOF_OF_DONE.md; do
  check_file_exists "$TEMPLATES_DIR/$template" "template exists: $template"
done
check_contains "$TEMPLATES_DIR/README.md" 'active v4.7.0 senior-specialist workflow' 'templates README marks v4.7.0 active workflow'
check_contains "$TEMPLATES_DIR/README.md" 'compact/N/A paths remain allowed' 'templates README preserves compact/N/A paths'

for skill in design-system-governance visual-regression api-contract-validation infra-validation threat-modeling; do
  check_file_exists "$SKILLS_DIR/$skill/SKILL.md" "skill exists: $skill"
  check_contains "$SKILLS_DIR/registry.md" "| $skill |" "registry lists $skill"
done
check_contains "$SKILLS_DIR/registry.md" 'v4.7.0 active' 'registry marks v4.7.0 skills active'
check_contains "$SKILLS_DIR/registry.md" 'trigger-based gates' 'registry keeps trigger-based enforcement wording'

ANALYZE="$COMMANDS_DIR/analyze.md"
PLAN_FEATURE="$COMMANDS_DIR/plan-feature.md"
IMPLEMENT="$COMMANDS_DIR/implement.md"
REVIEW="$COMMANDS_DIR/review.md"
GATES="$COMMANDS_DIR/gates.md"
SHIP="$COMMANDS_DIR/ship.md"

check_contains "$ANALYZE" 'PRD.md' '/analyze references PRD trigger'
check_contains "$ANALYZE" 'DESIGN_BRIEF.md' '/analyze references design brief trigger'
check_contains "$ANALYZE" 'THREAT_MODEL.md' '/analyze references threat model trigger'
check_contains "$ANALYZE" 'api-contract-validation/SKILL.md' '/analyze references API contract discovery'
check_contains "$ANALYZE" 'infra-validation/SKILL.md' '/analyze references infra discovery'

check_contains "$PLAN_FEATURE" 'v4.7.0 Active Template Selection Matrix' '/plan-feature references template selection matrix'
check_contains "$PLAN_FEATURE" 'QA_PLAN.md' '/plan-feature references QA plan'
check_contains "$PLAN_FEATURE" 'ADR.md' '/plan-feature references ADR'
check_contains "$PLAN_FEATURE" 'design-system-governance/SKILL.md' '/plan-feature references design-system governance'
check_contains "$PLAN_FEATURE" 'api-contract-validation/SKILL.md' '/plan-feature references API contract validation'
check_contains "$PLAN_FEATURE" 'infra-validation/SKILL.md' '/plan-feature references infra validation'
check_contains "$PLAN_FEATURE" 'threat-modeling/SKILL.md' '/plan-feature references threat modeling'

check_contains "$IMPLEMENT" 'PROOF_OF_DONE.md' '/implement references Proof of Done'
check_contains "$IMPLEMENT" 'visual-regression/SKILL.md' '/implement references visual regression'
check_contains "$IMPLEMENT" 'api-contract-validation/SKILL.md' '/implement references API contract validation'
check_contains "$IMPLEMENT" 'infra-validation/SKILL.md' '/implement references infra validation'
for label in TARGETED_FAILURE BROAD_BASELINE_FAILURE FLAKY_OR_INFRA_FAILURE NOT_RUN ACCEPTED_NON_BLOCKING BLOCKING_UNKNOWN; do
  check_contains "$IMPLEMENT" "$label" "/implement references $label"
  check_contains "$GATES" "$label" "/gates references $label"
done

check_contains "$REVIEW" 'Specialist artifact review pass' '/review references specialist artifact review'
check_contains "$REVIEW" 'Proof of Done' '/review references Proof of Done review'
check_contains "$REVIEW" 'design-system-governance/SKILL.md' '/review references design-system governance'
check_contains "$REVIEW" 'visual-regression/SKILL.md' '/review references visual regression'
check_contains "$REVIEW" 'api-contract-validation/SKILL.md' '/review references API contract review'
check_contains "$REVIEW" 'infra-validation/SKILL.md' '/review references infra review'
check_contains "$REVIEW" 'threat-modeling/SKILL.md' '/review references threat modeling'

check_contains "$GATES" 'Risk-based specialist gate mapping' '/gates references risk-based gate mapping'
check_contains "$GATES" 'Visual regression' '/gates maps visual regression'
check_contains "$GATES" 'API contract validation' '/gates maps API contract validation'
check_contains "$GATES" 'Infra validation' '/gates maps infra validation'
check_contains "$GATES" 'Threat modeling' '/gates maps threat modeling'

check_contains "$SHIP" 'PROOF_OF_DONE.md' '/ship references Proof of Done'
check_contains "$SHIP" 'infra-validation/SKILL.md' '/ship references infra validation'
check_contains "$SHIP" 'rollback, health, and infra-validation proof only for deploy/runtime scopes' '/ship scopes deploy/rollback/health proof'
check_contains "$SHIP" 'Owner approval is mandatory' '/ship requires owner approval for exceptions'

check_file_exists "$ROLES_DIR/README.md" 'role profile README exists'
for profile in product-manager ui-ux-designer frontend-engineer backend-engineer qa-engineer security-reviewer technical-architect devops-engineer; do
  file="$ROLES_DIR/$profile.md"
  check_file_exists "$file" "role profile exists: $profile"
  for section in 'Purpose' 'Responsibilities' 'Activation triggers' 'Required artifacts/templates' 'Relevant skills' 'Expected evidence' 'Senior-level quality bar' 'Common blind spots' 'Do not' 'Handoff expectations' 'N/A / compact mode rules' 'Escalation rules' 'Relationship to v4.6.1 gate classifications'; do
    check_contains "$file" "## $section" "$profile includes section: $section"
  done
done
check_contains "$ROLES_DIR/README.md" 'not new agents' 'role README says profiles are not new agents'
check_contains "$ROLES_DIR/README.md" 'do not change model routing' 'role README says no model routing change'
check_contains "$ROLES_DIR/README.md" 'v4.7.0 is active' 'role README says v4.7.0 is active'
check_contains "$ROLES_DIR/README.md" 'not new agents' 'role README keeps advisory role wording'

check_file_exists "$DOCS_DIR/CANDIDATE_PROTOCOL.md" 'candidate protocol doc exists'
check_file_exists "$DOCS_DIR/CANDIDATE_EVAL_PLAN.md" 'candidate eval plan exists'
check_contains "$DOCS_DIR/CANDIDATE_PROTOCOL.md" 'v4.7.0 candidate' 'candidate protocol historical doc exists'
check_contains "$DOCS_DIR/CANDIDATE_PROTOCOL.md" 'Phase F.0 activation-polish requirements' 'candidate protocol records activation-polish requirements'
check_contains "$DOCS_DIR/CANDIDATE_EVAL_PLAN.md" 'Phase E live validation pilot' 'candidate eval plan defines Phase E pilot'
check_contains "$DOCS_DIR/CANDIDATE_EVAL_PLAN.md" 'Phase F.0 activation-polish fixes' 'candidate eval plan records activation prerequisite'

check_contains "$GUARD" 'protocol-capabilities-v470.sh' 'v4.7.0 active conformance is wired into mandatory guard'

printf '\nSummary: %d passed, %d failed\n' "$PASS" "$FAILED"
if [[ "$FAILED" -eq 0 ]]; then
  printf '[PASS] v4.7.0 active capability checks passed. Active baseline verified.\n'
else
  printf '[FAIL] v4.7.0 active capability checks failed. Fix active baseline drift before proceeding.\n'
fi
exit "$FAILED"
