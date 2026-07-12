# Loop Runner Examples

> **Purpose:** Illustrative examples showing the Plan → Act → Verify loop pattern.

## minimal-loop.sh

A safe, illustrative loop runner that demonstrates:

1. Reading a goal from `GOAL.md`
2. Planning (placeholder — real loop calls the model)
3. Acting (placeholder — real loop implements changes)
4. Verifying (runs actual validation scripts if available)
5. Stopping on failure
6. Asking for human review before merge

### What it demonstrates

- The harness/loop separation
- How verification fits into the loop
- Why human review is required before merge
- How state is written to disk between iterations

### What it does NOT do

- Does not call real model APIs
- Does not mutate arbitrary files
- Does not bypass human review
- Does not imply fully autonomous safety
- Does not replace the actual OpenCode runtime

### How to run

```bash
bash examples/loop-runner/minimal-loop.sh
```

This will create a `GOAL.md` template on first run. Edit it and re-run to see the full loop.

### How it maps to the real protocol

| Loop step | Minimal example | Real protocol |
|-----------|----------------|---------------|
| Goal | `GOAL.md` | `PLAN.md` (required for STANDARD/HIGH-RISK) |
| Plan | Placeholder text | Planner helper role creates touch list |
| Act | Placeholder text | Implementer helper role makes bounded changes |
| Verify | Runs `public-surface-scan.sh` and `validate-docs-drift.sh` | CI runs 10 matrix checks (5 jobs × 2 environments) |
| Repair | Stops and asks for human help | Loop Controller (max 2 repair cycles) |
| Review | Asks for human review | Reviewer helper role (required for HIGH-RISK) |
| Merge | Does not merge | Branch protection requires all 10 CI checks |

### See also

- [docs/HARNESS_AND_LOOP.md](../../docs/HARNESS_AND_LOOP.md) — two-layer architecture
- [docs/PROGRESSIVE_ONBOARDING.md](../../docs/PROGRESSIVE_ONBOARDING.md) — progressive setup path
- [docs/LOOP_CONTROLLER.md](../../docs/loop-controller/) — real loop controller conformance tests
