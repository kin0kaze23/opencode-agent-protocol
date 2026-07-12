# External Review Guide

> **Purpose:** Helps external reviewers understand, validate, and evaluate the OpenCode Agent Protocol.
> **Last Updated:** 2026-07-11

---

## What This Project Is

OpenCode Agent Protocol is a safety-first AI engineering harness for governed agentic development. It provides:

- Risk classification and lane selection (DIRECT/FAST/STANDARD/HIGH-RISK)
- Model routing policy (advisory)
- Privacy scanning with CI enforcement
- Protocol conformance tests (297+ tests)
- Branch protection and release discipline
- Documented agent topology and capability catalog

## What This Project Is Not

- Not a product codebase — it is a protocol layer
- Not affiliated with or endorsed by OpenCode
- Not a replacement for human review on HIGH-RISK changes
- Not a guaranteed productivity improvement (no measured benchmarks published)
- Not approved by external researchers (no external review conducted yet)

---

## How to Clone and Validate

```bash
git clone https://github.com/kin0kaze23/opencode-agent-protocol.git
cd opencode-agent-protocol

# Run all validation scripts
bash scripts/public-surface-scan.sh
bash scripts/validate-docs-drift.sh
bash scripts/validate-config-schema.sh
bash scripts/validate-claims-evidence.sh

# Run protocol conformance tests
bash .opencode/scripts/validate-protocol-atlas.sh
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/conformance/tests/production-hardening.sh
bash .opencode/conformance/tests/loop-controller.sh
bash .opencode/conformance/tests/model-roi.sh
```

Expected: all scripts exit 0, all tests pass.

---

## What to Inspect First

### 1. Protocol Atlas
Read `docs/protocol/PROTOCOL_ATLAS.md` — the visual system map with 11 Mermaid diagrams. Start with the "5-Minute Explanation" section.

### 2. Capability Catalog
Read `docs/CAPABILITY_CATALOG.md` — maps every public capability to its source files, validation tests, and CI coverage.

### 3. Runtime Map
Read `docs/RUNTIME_MAP.md` — shows which files are authoritative vs generated, and the configuration flow.

### 4. Agent Topology
Read the "How the Orchestrator and Sub-Agents Cooperate" section in `README.md`.

### 5. Claims and Limitations
Read `docs/CLAIMS.md` for allowed/disallowed claims and `docs/FAILURE_MODES.md` for known failure modes.

---

## What Reviewers Should Evaluate

| Area | Questions to ask |
|------|-----------------|
| Safety | Are the safety rules comprehensive? Are there gaps? |
| Privacy | Does the scanner catch all variant forms? Are exclusions too broad? |
| CI | Are the 5 CI jobs sufficient? Are any missing? |
| Docs | Do the docs match the actual files? (Run `validate-docs-drift.sh`) |
| Claims | Are the public claims accurate and evidence-backed? |
| Threat model | Are the 9 threat categories comprehensive? Are mitigations adequate? |
| Failure modes | Are the 8 failure modes realistic? Are mitigations practical? |
| Configurability | Can a user customize routing, agents, and gates safely? |
| Portability | Does the repo work on both Ubuntu and macOS? |

---

## Known Limitations

1. **Privacy scanner only catches known patterns** — new project names must be added manually
2. **Model routing is advisory** — not enforced at runtime
3. **CI checks protocol, not product logic** — product tests are separate
4. **No external benchmarks published** — productivity claims are illustrative
5. **No external review conducted** — all validation is self-conducted
6. **Documentation can drift** — validators reduce but do not eliminate this risk

See `docs/FAILURE_MODES.md` and `docs/THREAT_MODEL.md` for details.

---

## How to Report Feedback

Open an issue using the "External Review Feedback" template:

1. Go to [Issues](https://github.com/kin0kaze23/opencode-agent-protocol/issues)
2. Click "New Issue"
3. Select "External Review Feedback"
4. Fill in the structured fields
5. Submit

We welcome feedback on:
- Safety gaps
- Documentation clarity
- Missing capabilities
- Validation effectiveness
- Threat model completeness
- Configuration usability
