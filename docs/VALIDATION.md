# Validation

> **Purpose:** Documents all validation scripts, what they check, and how to run them.
> **Last Updated:** 2026-07-11

---

## Validation Tiers

Not all tests are designed to run in every environment. Tests are classified into tiers:

### Tier 1: Public Self-Contained (run anywhere)

These tests run on any fresh clone without workspace-specific setup. All are enforced in CI.

| Script | What it checks | CI job |
|--------|---------------|--------|
| `scripts/public-surface-scan.sh` | Personal data, secrets, forbidden directories | Privacy Scan |
| `scripts/validate-docs-drift.sh` | Documentation references real files, version consistency | Docs Drift |
| `scripts/validate-config-schema.sh` | Required files exist, JSON/YAML validity, agent roles | Config Schema |
| `scripts/validate-claims-evidence.sh` | Claims are evidence-backed, disallowed patterns absent | Claims & Evidence |
| `.opencode/scripts/validate-protocol-atlas.sh` | Protocol Atlas diagrams exist and have rendered SVGs | Protocol Conformance |
| `.opencode/conformance/tests/protocol-atlas.sh` | 48 Protocol Atlas conformance checks | Protocol Conformance |
| `.opencode/conformance/tests/production-hardening.sh` | 53 production hardening checks | Protocol Conformance |
| `.opencode/conformance/tests/loop-controller.sh` | 96 loop controller checks | Protocol Conformance |
| `.opencode/conformance/tests/model-roi.sh` | 100 model ROI checks | Protocol Conformance |

### Tier 2: CI-Required (enforced on PRs)

All Tier 1 tests are CI-required. They run on both Ubuntu and macOS.

| CI Job | Script | Required |
|--------|--------|----------|
| Privacy Scan (ubuntu + macos) | `public-surface-scan.sh` | Yes |
| Docs Drift (ubuntu + macos) | `validate-docs-drift.sh` | Yes |
| Config Schema (ubuntu + macos) | `validate-config-schema.sh` | Yes |
| Claims & Evidence (ubuntu + macos) | `validate-claims-evidence.sh` | Yes |
| Protocol Conformance (ubuntu + macos) | 5 conformance test scripts | Yes |

### Tier 3: Optional Workspace Checks

These tests require a configured workspace with project repos, knowledge base, or runtime state. They are **not** expected to pass on a fresh clone and are **not** part of CI.

| Script | What it requires |
|--------|-----------------|
| `scripts/verify-install.sh` | Local workspace with OpenCode configured |
| `.opencode/conformance/tests/agent-roster-guard.sh` | Workspace with helper agents configured |
| `.opencode/conformance/tests/pattern-memory.sh` | Project repos with PROJECT_MEMORY.md files |
| `.opencode/conformance/tests/task-replay.sh` | Eval fixtures and task definitions |
| `.opencode/conformance/tests/reviewer-calibration.sh` | Reviewer eval context |
| `.opencode/conformance/tests/evidence-based-routing.sh` | Local eval results |
| ~60 other conformance tests | Various workspace-specific state |

**If you are a new user:** Only run Tier 1 tests. Tier 3 tests are for workspaces that have been set up with project repos and runtime state.

---

## How to Run All Tier 1 Validations

```bash
# Privacy scan
bash scripts/public-surface-scan.sh

# Docs drift
bash scripts/validate-docs-drift.sh

# Config schema
bash scripts/validate-config-schema.sh

# Claims & evidence
bash scripts/validate-claims-evidence.sh

# Protocol Atlas
bash .opencode/scripts/validate-protocol-atlas.sh

# Conformance tests
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/conformance/tests/production-hardening.sh
bash .opencode/conformance/tests/loop-controller.sh
bash .opencode/conformance/tests/model-roi.sh
```

---

## What Each Validator Catches

### public-surface-scan.sh
- Personal project names (all variant forms)
- Personal legal names
- Personal `/Users/` paths
- Old repo name references
- Secret patterns
- Forbidden directories (vault, reports, .paperclip)

### validate-docs-drift.sh
- Capability Catalog references non-existent files
- Runtime Map references non-existent files
- Protocol Atlas diagrams missing or incomplete
- Version mismatch between Atlas, NOW.md, and README
- CI workflow files missing
- README doc links broken
- Conformance test scripts missing

### validate-config-schema.sh
- Required protocol files missing
- Required config files missing
- brain-config.json invalid JSON or missing required fields
- model-registry.yaml empty or invalid
- Config YAML files invalid
- Helper roster missing required agent roles
- AGENTS.md missing required sections
- Privacy scan script missing
- CI workflow missing required jobs

### validate-claims-evidence.sh
- CLAIMS.md missing
- EVIDENCE.md missing
- Disallowed claim patterns in docs
- Case studies missing or insufficient
- Failure modes missing or insufficient
- Threat model missing or insufficient

---

## Adding a New Capability Safely

1. Add the capability to `docs/CAPABILITY_CATALOG.md`
2. Ensure all referenced files exist
3. Run `bash scripts/validate-docs-drift.sh` to verify
4. Run `bash scripts/validate-config-schema.sh` to verify
5. Create a PR — CI will run all Tier 1 validators
6. Merge only after all checks pass
