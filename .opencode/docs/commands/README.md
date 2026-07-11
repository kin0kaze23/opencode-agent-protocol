# Command Documentation Index

> **Purpose:** Index of runtime-facing command files and reference-only runbooks.

## Runtime-Facing Command Files

These files are loaded by the OpenCode runtime when the corresponding slash command is invoked. They contain the steps the agent must execute.

| Command File | Purpose |
|---|---|
| `commands/implement.md` | `/implement` — lane selection, Lite Mode, code intelligence, test intelligence, pattern memory, proactive quality, usage-aware autonomy |
| `commands/checkpoint.md` | `/checkpoint` — lite/full checkpoints, PROJECT_MEMORY update, usage summary, pattern auto-capture |
| `commands/gates.md` | `/gates` — quality gate runner |
| `commands/quick-ship.md` | `/quick-ship` — fast PR workflow with CI repair |
| `commands/review.md` | `/review` — code review |
| `commands/debug.md` | `/debug` — systematic debugging |
| `commands/plan-feature.md` | `/plan-feature` — feature planning |
| `commands/ship.md` | `/ship` — ship gate |
| `commands/analyze.md` | `/analyze` — analysis |
| `commands/auto-test-generation.md` | `/auto-test-generation` — test generation guidance |
| `commands/test-intelligence.md` | `/test-intelligence` — test discovery and review |

## Reference-Only Runbooks

These files are **not** loaded at startup or command invocation. They are loaded on demand when the agent needs detailed reference information.

| Runbook File | Parent Command | Content |
|---|---|---|
| `docs/commands/implement-runbook.md` | `/implement` | Multi-repo execution, UI/UX audits (12b-12j), traceability verification, touch-list expansion, verification profiles, subject containers, skill duplication, reviewer cost guard, model escalation, gate sequence |
| `docs/commands/checkpoint-runbook.md` | `/checkpoint` | Vault persistence policy, Loop Run Contract Outcome, PGR Reflection, behavioral drift tracking, benchmark telemetry, native token telemetry, branch/worktree lifecycle, ROADMAP.md review, lesson review, native session export fallback |

## When Agents Should Read Runbooks

- **During `/implement` step 10:** Read `implement-runbook.md` if multi-repo execution is needed
- **During `/implement` step 12b-12j:** Read `implement-runbook.md` if touch list includes UI files
- **During `/implement` step 14:** Read `implement-runbook.md` for traceability verification
- **During `/checkpoint` step 7-8:** Read `checkpoint-runbook.md` for lesson review and ROADMAP.md review
- **During `/checkpoint` step 14:** Read `checkpoint-runbook.md` for token telemetry and benchmark telemetry
- **During `/checkpoint` step 19b:** Read `checkpoint-runbook.md` for Loop Run Contract Outcome

## How to Add a New Runbook

1. Create `docs/commands/<command>-runbook.md`
2. Move detailed reference content from the command file to the runbook
3. Replace the extracted content in the command file with a short reference: `See .opencode/docs/commands/<command>-runbook.md for ...`
4. Update this README index
5. Run conformance tests to verify no behavior change
