# Configuration Guide

> **Purpose:** How to customize the OpenCode Agent Protocol for your workspace.
> **Last Updated:** 2026-07-11

---

## How to Customize Model Routing

Model routing determines which AI model handles which task type.

### Files to edit

| File | Role |
|------|------|
| `.opencode/model-registry.yaml` | Define models, providers, fallback chains |
| `.opencode/brain-config.json` | Set default model roles and routing policy |
| `.opencode/config/model-routing-policy.recommended.yaml` | Generated recommendations (do not edit directly) |

### Steps

1. Add your model to `model-registry.yaml`:
   ```yaml
   your_model_id:
     provider: your_provider
     model: your-model-name
     context_window: 128000
     role: implementation
   ```

2. Update the fallback chain in `brain-config.json`:
   ```json
   "fallback_chains": {
     "implementation": ["your_model_id", "fallback_model_id"]
   }
   ```

3. Run validation:
   ```bash
   bash .opencode/conformance/tests/model-routing-coherence.sh
   ```

### What not to do

- Do not remove the fallback chain — always have a backup model
- Do not route to models with empty-response history (see Empty Response Guardrail)
- Do not change routing without eval evidence

---

## How to Add or Change Agents

The helper roster defines which sub-agents are available.

### Files to edit

| File | Role |
|------|------|
| `.opencode/helper-roster.md` | Helper agent definitions and routing guidance |
| `.opencode/brain-config.json` | Agent routing policy |

### Steps

1. Add the agent to `helper-roster.md` with:
   - Name
   - Role
   - Model assignment
   - When to use
   - When not to use

2. Update `brain-config.json` routing to include the new agent

3. Run validation:
   ```bash
   bash .opencode/conformance/tests/agent-roster-guard.sh
   bash .opencode/conformance/tests/subagent-coherence.sh
   ```

### What not to do

- Do not add agents without defining their model assignment
- Do not add agents without defining when they should not be used

---

## How to Adjust Reviewer Policy

Reviewer policy determines when independent review is required.

### Files to edit

| File | Role |
|------|------|
| `.opencode/config/reviewer-policy.recommended.yaml` | Reviewer trigger rules |
| `.opencode/config/reviewer-trust-policy.yaml` | Trust enforcement rules |

### Steps

1. Edit the trigger rules in `reviewer-policy.recommended.yaml`:
   ```yaml
   triggers:
     - condition: "risk_score >= 4"
       action: "require_reviewer"
     - condition: "sensitive_path_touched"
       action: "require_reviewer"
   ```

2. Run validation:
   ```bash
   bash .opencode/conformance/tests/reviewer-calibration.sh
   ```

### What not to do

- Do not disable reviewer requirements for HIGH-RISK tasks
- Do not auto-approve sensitive path changes

---

## How to Configure Release Gates

Release gates determine what must pass before a release.

### Files to edit

| File | Role |
|------|------|
| `.opencode/config/gate-matrix.yaml` | Risk-based gate selection |
| `.github/workflows/validation.yml` | CI enforcement |

### Steps

1. Edit `gate-matrix.yaml` to add or change gates:
   ```yaml
   - task_type: "logic_change"
     required_gates: [lint, typecheck, test, build]
   ```

2. Update `validation.yml` to add the new check as a CI step

3. Follow `docs/RELEASE_CHECKLIST.md` for each release

---

## How to Add New Privacy Scan Patterns

The privacy scanner blocks personal data from being committed.

### Files to edit

| File | Role |
|------|------|
| `scripts/public-surface-scan.sh` | Pattern definitions and exclusions |

### Steps

1. Add the pattern to the appropriate `scan_category` call:
   ```bash
   scan_category "Personal project names" \
     'YourProjectName|your-project-name|your_project_name'
   ```

2. If the pattern has legitimate uses in docs, add to `EXCLUDE_PATTERN`:
   ```bash
   EXCLUDE_PATTERN='...|^./docs/YOUR_POLICY.md'
   ```

3. Test:
   ```bash
   bash scripts/public-surface-scan.sh
   ```

### What not to do

- Do not add patterns that match common English words
- Do not remove the self-exclusion for the scan script itself

---

## How to Add a New Conformance Test

### Steps

1. Create a new test file in `.opencode/conformance/tests/`:
   ```bash
   #!/usr/bin/env bash
   # .opencode/conformance/tests/your-test.sh
   set -euo pipefail
   ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
   
   TESTS_PASSED=0
   TESTS_FAILED=0
   
   # Your test logic here
   # Use assert_equals, assert_file_exists, etc.
   
   echo "PASSED: $TESTS_PASSED"
   echo "FAILED: $TESTS_FAILED"
   exit $([ "$TESTS_FAILED" -eq 0 ] && echo 0 || echo 1)
   ```

2. Make it executable:
   ```bash
   chmod +x .opencode/conformance/tests/your-test.sh
   ```

3. If it should run in CI, add it to `.github/workflows/validation.yml`:
   ```yaml
   - name: Your test
     run: bash .opencode/conformance/tests/your-test.sh
   ```

4. Test locally:
   ```bash
   bash .opencode/conformance/tests/your-test.sh
   ```

---

## What Should Not Be Customized Casually

| File | Risk |
|------|------|
| `.opencode/AGENTS.md` | Changes affect all protocol behavior |
| `.opencode/rules.md` | Changes affect safety guardrails |
| `.opencode/brain-config.json` | Changes affect model routing |
| `.opencode/model-registry.yaml` | Changes affect fallback chains |
| `scripts/public-surface-scan.sh` | Changes affect privacy enforcement |
| `.github/workflows/validation.yml` | Changes affect CI enforcement |
| `.gitignore` | Changes affect publication exclusions |

Any changes to these files should go through a PR with CI validation.
