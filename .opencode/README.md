# .opencode/ — OpenCode Workspace Protocol

> **Version:** v4.27 — Information Architecture Cleanup
> **Status:** No-behavior-change cleanup of the v4.20–v4.26 capability stack.

## What This Directory Is

This directory holds the OpenCode workspace protocol: the behavioral rules,
model routing, commands, scripts, conformance tests, and configuration that
govern how AI agents operate in this workspace.

It is **not** a product codebase. It is a protocol layer.

## What Is Loaded at Startup

Only these files are mandatory at startup:

| File | Purpose |
|---|---|
| `.opencode/AGENTS.md` | Protocol kernel, lane selection, harness patterns, senior operator loop |
| `.opencode/rules.md` | OpenCode-specific guardrails, token efficiency, session cache, provider fallback |
| `.opencode/opencode.json` | Runtime config: agents, model routing, MCP policy, permissions |
| `.opencode/brain-config.json` | Orchestration policy: routing, budgets, eval policy |

Everything else is **reference-only** — loaded on demand when a task needs it.

## Directory Structure

```
.opencode/
  AGENTS.md                  # Protocol kernel (startup-loaded)
  rules.md                   # OpenCode guardrails (startup-loaded)
  opencode.json             # Runtime config (startup-loaded)
  brain-config.json          # Orchestration policy (startup-loaded)
  helper-roster.md           # Helper agent routing (reference-only)
  model-registry.yaml        # Model definitions and routing (reference-only)
  COMPACTION-SAFEGUARD.md    # Compaction safety guide (reference-only)
  PROTOCOL_RUNBOOK.md        # Protocol runbook (reference-only)
  PROJECT_REGISTRY.md        # Project registry (advisory)
  COMPACTION-SAFEGUARD.md    # Compaction safety (reference-only)

  agents/                    # Helper agent prompt sources
    architect.md
    budget.md
    explorer.md
    implementer.md
    planner.md
    reviewer.md
    visual-reviewer.md
    visual-reviewer-fallback.md

  commands/                  # OpenCode slash commands
    implement.md             # /implement — Lite Mode, code intelligence, test intelligence
    checkpoint.md            # /checkpoint — Lite/full checkpoints, usage summary
    gates.md                 # /gates — Quality gate runner
    quick-ship.md             # /quick-ship — Fast PR workflow
    review.md                # /review — Code review
    debug.md                 # /debug — Systematic debugging
    plan-feature.md          # /plan-feature — Feature planning
    ship.md                  # /ship — Ship gate
    ... (30+ commands)

  config/                    # Configuration files
    token-budget.yaml        # Lane-level token/reviewer/premium-model budgets
    gate-matrix.yaml         # Risk-based gate selection matrix
    repo-profiles.yaml       # Repo type detection profiles
    gate-health-baseline.yaml
    telemetry-schema.yaml

  conformance/               # Conformance test suite
    tests/                   # Test definitions (60 tests)
    assert.sh                # Test assertion library
    guard-assert.sh          # Guard assertion library
    fixtures/                # Test fixture repos
    results/                 # Test output (gitignored)

  scripts/                   # Shell scripts (46 scripts)
    lite-mode-eligibility.sh # v4.20: Mechanical Lite Mode classifier
    build-code-index.sh      # v4.21: Code intelligence
    search-code-index.sh     # v4.21: Code search
    retrieve-lessons.sh      # v4.21: Lesson retrieval
    senior-self-review.sh    # v4.22: Senior self-review checklist
    find-tests.sh            # v4.23: Test discovery
    detect-untested.sh       # v4.25: Untested change detection
    build-pattern-index.sh   # v4.24: Pattern memory
    search-patterns.sh       # v4.24: Pattern search
    track-usage.sh            # v4.26: Usage telemetry
    check-provider-status.sh # v4.26: Provider status check
    workspace-protocol-guard.sh
    git-guard/               # Git guard wrapper
    ...

  skills/                    # Skill library (67 skills)
    registry.md              # Skill classification and activation table
    accessibility-audit/
    agent-browser/
    database/
    deployment/
    nextjs/
    security/
    testing/
    ...

  templates/                 # Document templates
    PLAN.md
    ADR.md
    LOOP_RUN_CONTRACT.md
    PROJECT_MEMORY.md
    ...

  archive/                   # Archived/historical files
    MANIFEST.md              # Archive manifest with rollback notes
    protocol-phases/         # Historical protocol phase docs
    ...

  policies/                  # JSON policy files (runtime-referenced)
  patterns/                  # UI/UX pattern definitions
  runbooks/                  # Operational runbooks
  role-profiles/             # Senior-specialist role profiles
  adr/                       # Architecture Decision Records
  git-guard/                 # Git guard wrapper and docs
  plugins/                   # Runtime plugins
  global-runtime/            # Generated runtime prompt mirrors
```

## How to Run Conformance Tests

```bash
# Run the v4.20–v4.26 capability suite
for test in lite-delegation-mode code-intelligence-lesson-retrieval \
  senior-operator-loop test-intelligence-review pattern-memory \
  auto-test-proactive usage-aware-autonomy protocol-coherence-phase1 \
  git-guard-compliance model-routing-coherence; do
  bash .opencode/conformance/tests/$test.sh
done

# Run the full suite (includes all tests)
bash .opencode/conformance/tests/run-all.sh
```

## How to Add a Command

1. Create `.opencode/commands/<name>.md`
2. Follow the pattern of existing commands (preface, steps, output format)
3. If the command has a conformance test, add `.opencode/conformance/tests/<name>.sh`
4. Run `bash .opencode/scripts/sync-opencode-runtime.sh` to sync runtime mirrors

## How to Add a Script

1. Create `.opencode/scripts/<name>.sh`
2. Make it executable: `chmod +x .opencode/scripts/<name>.sh`
3. If the script has a conformance test, add `.opencode/conformance/tests/<name>.sh`
4. Reference the script from the appropriate command file

## How to Add a Skill

1. Create `.opencode/skills/<name>/SKILL.md`
2. Update `.opencode/skills/registry.md` with classification
3. Wire the skill into command activation tables if needed

## Capability Stack (v4.20–v4.26)

| Version | Capability | Key Scripts |
|---|---|---|
| v4.20 | Lite Delegation Mode | `lite-mode-eligibility.sh` |
| v4.20.1 | Mechanical risk classification | `lite-mode-eligibility.sh` |
| v4.21 | Code intelligence + lesson retrieval | `build-code-index.sh`, `search-code-index.sh`, `retrieve-lessons.sh` |
| v4.22 | Senior operator loop + CI-first | `senior-self-review.sh`, `quick-ship.md` |
| v4.23 | Test intelligence + evidence-based review | `find-tests.sh` |
| v4.24 | Senior memory + pattern reuse | `build-pattern-index.sh`, `search-patterns.sh` |
| v4.25 | Proactive quality + auto-test guidance | `detect-untested.sh`, `auto-test-generation.md` |
| v4.26 | Usage-aware autonomy + model ROI | `track-usage.sh`, `check-provider-status.sh` |

## Files That Are Not Runtime Authority

Per workspace protocol, these are **not** treated as runtime authority:

- `.opencode/archive/` — historical files
- `.opencode/benchmarks/` — benchmark cases and simulations
- `.opencode/conformance/results/` — test output (gitignored)
- `.opencode/evals/` — model evaluation data
- `.opencode/node_modules/` — dependencies (gitignored)
- `.opencode/cache/` — ephemeral caches (gitignored)
- `.opencode/.session-cache/` — session cache (gitignored)
