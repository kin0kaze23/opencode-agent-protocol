# Progressive Onboarding

> **Purpose:** A staged path from clone to first useful workflow.
> **Last Updated:** 2026-07-12

---

## Stage 1: Understand (5 minutes)

1. Read [README.md](../README.md) — what the project is, prerequisites
2. Read [docs/HARNESS_AND_LOOP.md](HARNESS_AND_LOOP.md) — the two-layer architecture
3. Skim [docs/CAPABILITY_CATALOG.md](CAPABILITY_CATALOG.md) — what the protocol can do

**You should understand:** This is a protocol layer for OpenCode, not a bundled runtime.

## Stage 2: Validate (5 minutes)

1. Clone the repo
2. Run validation:

```bash
bash scripts/public-surface-scan.sh
bash scripts/validate-docs-drift.sh
bash scripts/validate-config-schema.sh
bash scripts/validate-claims-evidence.sh
bash .opencode/scripts/validate-protocol-atlas.sh
bash .opencode/conformance/tests/protocol-atlas.sh
```

**You should see:** All scripts exit 0 (PASS).

See [docs/FIRST_RUN_CHECKLIST.md](FIRST_RUN_CHECKLIST.md) for the full validation flow.

## Stage 3: Read the Rules (5 minutes)

1. Read `.opencode/AGENTS.md` — safety rules, lane selection, escalation triggers
2. Read `.opencode/rules.md` — guardrails, token budgets, compaction
3. Skim `.opencode/helper-roster.md` — the 5 helper roles

**You should understand:** How risk is classified and what controls each lane has.

## Stage 4: Configure Your Models (10 minutes)

1. Read [docs/OWN_MODEL_SETUP.md](OWN_MODEL_SETUP.md)
2. Copy templates from `examples/config/`:
   - `brain-config.template.json` → `.opencode/brain-config.json`
   - `model-routing-policy.template.yaml` → `.opencode/config/model-routing-policy.recommended.yaml`
3. Replace placeholder values with your model IDs and provider details
4. Run `bash scripts/validate-config-schema.sh` to verify

**You should have:** A working model routing config with your providers.

## Stage 5: Try a Docs-Only Workflow (5 minutes)

1. Create a branch: `git checkout -b docs/test-change`
2. Make a small docs change (fix a typo, add a note)
3. Run: `bash scripts/public-surface-scan.sh`
4. Commit: `git commit -m "docs: test change"`
5. Observe: This is a DIRECT lane task — minimal gates, but privacy scan still runs

**You should see:** How even the simplest change goes through validation.

See [examples/workflows/docs-only-change.md](../examples/workflows/docs-only-change.md).

## Stage 6: Try a Small Bugfix Workflow (10 minutes)

1. Create a branch: `git checkout -b fix/test-bugfix`
2. Make a small code change (fix a typo in a script)
3. Run validation:
   ```bash
   bash scripts/public-surface-scan.sh
   bash scripts/validate-docs-drift.sh
   bash .opencode/conformance/tests/protocol-atlas.sh
   ```
4. Commit: `git commit -m "fix: test bugfix"`
5. Observe: This is a FAST lane task — tests required, CI runs all checks

**You should see:** How logic changes require tests and CI validation.

See [examples/workflows/small-bugfix.md](../examples/workflows/small-bugfix.md).

## Stage 7: Try the Loop Runner (5 minutes)

1. Run: `bash examples/loop-runner/minimal-loop.sh`
2. Edit the generated `GOAL.md`
3. Re-run to see the full Plan → Act → Verify → Review flow

**You should understand:** How the loop runs inside the harness.

## Stage 8: Enable CI (10 minutes)

1. Fork the repo to your GitHub
2. Enable GitHub Actions
3. Create a PR to see CI in action
4. Observe: 10 matrix checks (5 jobs × 2 environments) must all pass

**You should see:** How CI enforces the harness on every PR.

## Stage 9: Use the Dogfooding Log (ongoing)

1. Copy [docs/DOGFOODING_LOG_TEMPLATE.md](DOGFOODING_LOG_TEMPLATE.md)
2. For each task you complete, record: task type, risk level, time, iterations, checks, issues caught, confidence
3. After 10 tasks, calculate summary statistics

**You should have:** Real evidence of how the protocol affects your work.

## Stage 10: Review Limitations (5 minutes)

1. Read [docs/FAILURE_MODES.md](FAILURE_MODES.md) — 9 known failure modes
2. Read [docs/THREAT_MODEL.md](THREAT_MODEL.md) — 9 threat categories
3. Read [docs/CLAIMS.md](CLAIMS.md) — what we can and cannot claim

**You should understand:** What the protocol does and does not guarantee.

---

## Total Time: ~60 minutes

By the end, you should have:
- A validated clone of the protocol
- Your own model routing configured
- Experience with docs-only and bugfix workflows
- Understanding of the harness/loop architecture
- Awareness of failure modes and limitations
- A dogfooding log started

## What Not to Do

- Do not skip validation to save time
- Do not configure models without reading OWN_MODEL_SETUP.md
- Do not attempt HIGH-RISK tasks without human review
- Do not disable CI or branch protection
- Do not claim guaranteed productivity without measuring
