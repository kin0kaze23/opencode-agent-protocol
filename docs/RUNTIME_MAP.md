# Runtime Map

> **Purpose:** Maps runtime configuration files to their roles, showing which are authoritative and which are generated or explanatory.
> **Last Updated:** 2026-07-11

---

## Authority Model

| Layer | Responsibility | Files |
|-------|---------------|-------|
| **Protocol source** | Behavioral rules, lanes, gates, safety | `.opencode/AGENTS.md`, `.opencode/rules.md` |
| **Orchestration policy** | Routing, budgets, eval policy | `.opencode/brain-config.json` |
| **Model registry** | Model definitions, fallback chains | `.opencode/model-registry.yaml` |
| **Helper roster** | Sub-agent routing guidance | `.opencode/helper-roster.md` |
| **Configuration** | Gate matrix, token budgets, profiles | `.opencode/config/*.yaml` |
| **Conformance tests** | Protocol validation | `.opencode/conformance/tests/*.sh` |
| **Scripts** | Automation, validation, scanning | `scripts/*.sh`, `.opencode/scripts/*.sh` |
| **CI workflows** | Automated enforcement | `.github/workflows/*.yml` |
| **Documentation** | Human-readable guides | `docs/*.md`, `README.md` |
| **Protocol Atlas** | Visual system map | `docs/protocol/PROTOCOL_ATLAS.md` + diagrams |

---

## File Authority Classification

### Authoritative (source of truth)

| File | Role |
|------|------|
| `.opencode/AGENTS.md` | Canonical protocol rules, lanes, safety, startup sequence |
| `.opencode/rules.md` | OpenCode-specific guardrails, token efficiency, compaction |
| `.opencode/brain-config.json` | Orchestration policy, routing, budgets |
| `.opencode/model-registry.yaml` | Model definitions, fallback chains, eval status |
| `.opencode/helper-roster.md` | Helper agent routing guidance |
| `.opencode/CORE_V1_MANIFEST.md` | Core v1 hardening manifest |
| `.opencode/config/gate-matrix.yaml` | Risk-based gate selection matrix |
| `.opencode/config/token-budget.yaml` | Per-lane token budgets |
| `.opencode/config/repo-profiles.yaml` | Repo type detection profiles |
| `.opencode/config/model-routing-policy.recommended.yaml` | Recommended model routing |
| `.opencode/config/reviewer-policy.recommended.yaml` | Recommended reviewer policy |
| `.opencode/config/reviewer-trust-policy.yaml` | Reviewer trust enforcement policy |
| `scripts/public-surface-scan.sh` | Privacy scan patterns and exclusions |
| `.github/workflows/validation.yml` | CI enforcement definition |

### Generated/Explanatory (not source of truth)

| File | Role |
|------|------|
| `.opencode/config/model-routing-policy.recommended.yaml` | Generated from model-registry.yaml |
| `.opencode/config/branch-protection-evidence.yaml` | Evidence snapshot (not config) |
| `docs/protocol/PROTOCOL_ATLAS.md` | Documentation of the system (not runtime config) |
| `docs/protocol/diagrams/*.mmd` | Mermaid diagram sources |
| `docs/protocol/diagrams/rendered/*.svg` | Rendered SVGs (generated from .mmd) |
| `docs/CAPABILITY_CATALOG.md` | This catalog (documentation) |
| `docs/RUNTIME_MAP.md` | This map (documentation) |
| `NOW.md` | Current state (ephemeral) |
| `CHANGELOG.md` | Release history (documentation) |

---

## Configuration Flow

```
.opencode/AGENTS.md (protocol rules)
    ↓
.opencode/brain-config.json (routing policy)
    ↓
.opencode/model-registry.yaml (model definitions)
    ↓
.opencode/config/model-routing-policy.recommended.yaml (generated recommendations)
    ↓
.opencode/helper-roster.md (helper routing guidance)
```

---

## CI Enforcement Flow

```
PR created → .github/workflows/validation.yml triggers
    ↓
    ├─ Privacy Scan job → scripts/public-surface-scan.sh
    └─ Protocol Conformance job → .opencode/scripts/validate-protocol-atlas.sh
                                   .opencode/conformance/tests/protocol-atlas.sh
                                   .opencode/conformance/tests/production-hardening.sh
                                   .opencode/conformance/tests/loop-controller.sh
                                   .opencode/conformance/tests/model-roi.sh
    ↓
Both must pass → PR can merge (enforced by GitHub ruleset)
```

---

## What Not to Edit Casually

| File | Why |
|------|-----|
| `.opencode/AGENTS.md` | Canonical protocol — changes affect all behavior |
| `.opencode/rules.md` | Guardrails — changes affect safety boundaries |
| `.opencode/brain-config.json` | Routing policy — changes affect model selection |
| `.opencode/model-registry.yaml` | Model definitions — changes affect fallback chains |
| `scripts/public-surface-scan.sh` | Privacy patterns — changes affect what is blocked |
| `.github/workflows/validation.yml` | CI definition — changes affect what is enforced |
| `.gitignore` | Publication exclusions — changes affect what can be committed |
