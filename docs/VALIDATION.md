# Validation

> **Purpose:** Documents all validation scripts, what they check, and how to run them.
> **Last Updated:** 2026-07-11

---

## Validation Scripts

| Script | What it checks | CI job |
|--------|---------------|--------|
| `scripts/public-surface-scan.sh` | Personal data, secrets, forbidden directories | Privacy Scan |
| `scripts/validate-docs-drift.sh` | Documentation references real files, version consistency, diagram integrity | Docs Drift |
| `scripts/validate-config-schema.sh` | Required files exist, JSON/YAML validity, required fields, agent roles, CI jobs | Config Schema |
| `scripts/validate-claims-evidence.sh` | Claims are evidence-backed, disallowed patterns absent, evidence docs exist | Claims & Evidence |
| `.opencode/scripts/validate-protocol-atlas.sh` | Protocol Atlas diagrams exist, are non-empty, have valid syntax, have rendered SVGs | Protocol Conformance |
| `.opencode/conformance/tests/protocol-atlas.sh` | 48 Protocol Atlas conformance checks | Protocol Conformance |
| `.opencode/conformance/tests/production-hardening.sh` | 53 production hardening checks | Protocol Conformance |
| `.opencode/conformance/tests/loop-controller.sh` | 96 loop controller checks | Protocol Conformance |
| `.opencode/conformance/tests/model-roi.sh` | 100 model ROI checks | Protocol Conformance |

---

## How to Run All Validations

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

## CI Enforcement

All validation scripts run in CI on every PR and push to main:

| CI Job | Script | Required |
|--------|--------|----------|
| Privacy Scan | `public-surface-scan.sh` | Yes |
| Docs Drift | `validate-docs-drift.sh` | Yes |
| Config Schema | `validate-config-schema.sh` | Yes |
| Claims & Evidence | `validate-claims-evidence.sh` | Yes |
| Protocol Conformance | Protocol Atlas + production-hardening + loop-controller + model-roi | Yes |

Branch protection requires all jobs to pass before merge.

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
5. Create a PR — CI will run all validators
6. Merge only after all checks pass
