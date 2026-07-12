# First Run Checklist

> **Purpose:** Get a new user from clone to validated in 15 minutes.
> **Last Updated:** 2026-07-11

---

## Step 1: Clone the Repo (1 minute)

```bash
git clone https://github.com/kin0kaze23/opencode-agent-protocol.git
cd opencode-agent-protocol
```

## Step 2: Run Validation (2 minutes)

```bash
# Privacy scan — checks for personal data
bash scripts/public-surface-scan.sh

# Docs drift — checks docs reference real files
bash scripts/validate-docs-drift.sh

# Config schema — checks config files are valid
bash scripts/validate-config-schema.sh

# Claims & evidence — checks claims are backed by evidence
bash scripts/validate-claims-evidence.sh
```

All should exit 0 (PASS).

## Step 3: Run Protocol Conformance Tests (3 minutes)

```bash
bash .opencode/scripts/validate-protocol-atlas.sh
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/conformance/tests/production-hardening.sh
bash .opencode/conformance/tests/loop-controller.sh
bash .opencode/conformance/tests/model-roi.sh
```

Expected: 297+ tests pass, 0 failures.

## Step 4: Read the Capability Catalog (3 minutes)

Read [docs/CAPABILITY_CATALOG.md](CAPABILITY_CATALOG.md) — maps every public capability with status, source files, validation, and CI coverage.

## Step 5: Read the Runtime Map (2 minutes)

Read [docs/RUNTIME_MAP.md](RUNTIME_MAP.md) — shows which files are authoritative vs generated, and the configuration flow.

## Step 6: Inspect the Protocol Atlas (2 minutes)

Read [docs/protocol/PROTOCOL_ATLAS.md](protocol/PROTOCOL_ATLAS.md) — start with the "5-Minute Explanation" section, then browse the 11 Mermaid diagrams.

## Step 7: Review Example Workflows (1 minute)

Browse [examples/workflows/](../examples/workflows/) — 5 sanitized example workflows showing how the protocol works in practice.

## Step 8: Check Privacy Scan Behavior (1 minute)

```bash
# Verify the scanner catches blocked patterns
echo "BabyGuide test" > /tmp/test-blocked.txt
cp /tmp/test-blocked.txt .
bash scripts/public-surface-scan.sh  # should FAIL
rm test-blocked.txt
bash scripts/public-surface-scan.sh  # should PASS again
```

## Step 9: Review Claims and Limitations (1 minute)

Read [docs/CLAIMS.md](CLAIMS.md) — what we can and cannot claim.
Read [docs/FAILURE_MODES.md](FAILURE_MODES.md) — 8 known failure modes.
Read [docs/THREAT_MODEL.md](THREAT_MODEL.md) — 9 threat categories.

## Step 10: Open Feedback (optional)

If you have feedback, open an issue using the "External Review Feedback" template at [Issues](https://github.com/kin0kaze23/opencode-agent-protocol/issues).

---

## Total Time: ~15 minutes

If all steps pass, you have a validated, working clone of the OpenCode Agent Protocol.
