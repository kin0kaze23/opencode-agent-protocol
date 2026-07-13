# First Run Checklist

> **Purpose:** Get a new user from clone to validated in 15 minutes.
> **Last Updated:** 2026-07-14

---

## Step 1: Clone the Repo (1 minute)

```bash
git clone https://github.com/kin0kaze23/opencode-agent-protocol.git
cd opencode-agent-protocol
```

## Step 2: Run Setup Script (2 minutes)

```bash
bash scripts/setup.sh
```

This checks prerequisites (git, python3, node, jq, OpenCode CLI), detects your OS, and generates shell alias snippets. Address any failures before continuing.

## Step 3: Configure Your Model Provider (2 minutes)

The protocol ships with placeholder model IDs (`YOUR_PROVIDER/YOUR_MODEL_ID`). You must replace these with your own:

1. Read [docs/OWN_MODEL_SETUP.md](OWN_MODEL_SETUP.md) for provider setup
2. Update `.opencode/opencode.json` — replace `YOUR_PROVIDER/YOUR_*_MODEL` with your actual model IDs
3. Set your API key: `export OPENAI_API_KEY="your-key"` (or equivalent)

> **Note:** Protocol validation (Steps 4-7) does not require a configured provider. Only actual OpenCode task execution needs real model IDs.

## Step 4: Run Validation (2 minutes)

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

## Step 5: Run Protocol Conformance Tests (3 minutes)

```bash
bash .opencode/scripts/validate-protocol-atlas.sh
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/conformance/tests/production-hardening.sh
bash .opencode/conformance/tests/loop-controller.sh
bash .opencode/conformance/tests/model-roi.sh
```

Expected: 297+ tests pass, 0 failures.

## Step 6: Read the Capability Catalog (3 minutes)

Read [docs/CAPABILITY_CATALOG.md](CAPABILITY_CATALOG.md) — maps every public capability with status, source files, validation, and CI coverage.

## Step 7: Read the Runtime Map (2 minutes)

Read [docs/RUNTIME_MAP.md](RUNTIME_MAP.md) — shows which files are authoritative vs generated, and the configuration flow.

## Step 8: Inspect the Protocol Atlas (2 minutes)

Read [docs/protocol/PROTOCOL_ATLAS.md](protocol/PROTOCOL_ATLAS.md) — start with the "5-Minute Explanation" section, then browse the 11 Mermaid diagrams.

## Step 9: Review Example Workflows (1 minute)

Browse [examples/workflows/](../examples/workflows/) — 5 sanitized example workflows showing how the protocol works in practice.

## Step 10: Open Feedback (optional)

If you have feedback, open an issue using the "External Review Feedback" template at [Issues](https://github.com/kin0kaze23/opencode-agent-protocol/issues).

---

## Total Time: ~15 minutes

If all steps pass, you have a validated, working clone of the OpenCode Agent Protocol.

## MCP Server First Run

When you start OpenCode for the first time, MCP server packages (context7, exa, sequential-thinking, github) will be downloaded via `npx`. This may take 30-60 seconds. Network access is required. To disable MCP servers you don't need, set `"enabled": false` in `.opencode/opencode.json`.
