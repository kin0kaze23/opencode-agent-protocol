# Harness and Loop

> **Purpose:** Explains the two-layer architecture of the OpenCode Agent Protocol.
> **Last Updated:** 2026-07-12

---

## The Two Layers

The protocol has two layers that work together:

```
┌─────────────────────────────────────────────────┐
│                   HARNESS                        │
│  Stable files, rules, policies, validators, CI    │
│  Changes slowly. Validated by CI.                │
├─────────────────────────────────────────────────┤
│                    LOOP                          │
│  goal → plan → act → verify → repair → review    │
│  Runs per task. Governed by the harness.          │
└─────────────────────────────────────────────────┘
```

**The harness is the kitchen. The loop is the recipe.**

A kitchen with no recipe is unused space. A recipe with no kitchen is wishful thinking. Both fail without the other.

---

## The Harness Layer

The harness is the set of files that do not change between runs. It defines what each iteration is allowed to do.

| Harness File | Role | Changes |
|-------------|------|---------|
| `.opencode/AGENTS.md` | Standing context — project shape, commands, safety rules, lane selection | Rarely |
| `.opencode/rules.md` | OpenCode-specific guardrails — token budgets, compaction, permissions | Rarely |
| `.opencode/brain-config.json` | Routing policy — which model for which task | Occasionally |
| `.opencode/model-registry.yaml` | Model definitions and fallback chains | When models change |
| `.opencode/helper-roster.md` | Sub-agent roles and routing guidance | When agents change |
| `.opencode/config/*.yaml` | Gate matrix, token budgets, reviewer policy, repo profiles | Occasionally |
| `.opencode/skills/*/SKILL.md` | Specialized task instructions (progressive loading) | When new skills added |
| `.opencode/hooks/` | Deterministic scripts that fire on tool events | Rarely |
| `scripts/*.sh` | Validation scripts (privacy scan, docs drift, config schema, claims) | When validators change |
| `.github/workflows/validation.yml` | CI enforcement — 10 required checks on Ubuntu + macOS | Rarely |
| `docs/protocol/PROTOCOL_ATLAS.md` | Visual system map (11 Mermaid diagrams) | When architecture changes |

### What the Harness Does

- **Permissions** decide whether the loop can write to disk
- **Sub-agents** decide whether verification runs in a clean context
- **Skills** decide whether the loop can specialize
- **Hooks** decide whether the loop even gets to fire on the trigger you wanted
- **Validators** decide whether the harness itself is still intact
- **CI** enforces all of the above on every PR

### What the Harness Does Not Do

- It does not execute tasks
- It does not make decisions
- It does not call models
- It defines the rules; the loop runs inside them

---

## The Loop Layer

The loop is what runs inside the harness. It repeats per task.

```
goal → plan → act → verify → repair → review → merge
```

| Step | What happens | Harness component that governs it |
|------|-------------|--------------------------------|
| **Goal** | Define what "done" looks like (PLAN.md) | AGENTS.md requires plans for STANDARD/HIGH-RISK |
| **Plan** | Create touch list, success criteria, rollback path | Planner helper role; AGENTS.md Pattern 3 (Touch List) |
| **Act** | Make bounded code changes within the touch list | Implementer helper role; Git Guard blocks unsafe ops |
| **Verify** | Run validation scripts and conformance tests | CI (10 required checks); Reviewer helper role |
| **Repair** | Fix failures found in verify step | Loop Controller (state machine, stop conditions) |
| **Review** | Independent quality check (required for HIGH-RISK) | Reviewer policy; Senior Self-Review script |
| **Merge** | Squash merge via PR after all checks pass | Branch protection (all 10 checks required) |

### What the Loop Does

- Reads the goal spec each iteration
- Plans against the goal
- Executes within the harness rules
- Verifies in a fresh context (sub-agent)
- Writes state back to disk
- Stops when the goal spec says done

### What the Loop Does Not Do

- It does not change the harness rules
- It does not bypass permissions
- It does not skip verification
- It does not merge without CI passing

---

## How They Interact

```
1. Harness is set up (AGENTS.md, rules, config, skills, agents, hooks, CI)
2. User gives a task to the orchestrator
3. Orchestrator classifies risk and selects a lane (DIRECT/FAST/STANDARD/HIGH-RISK)
4. Loop begins:
   a. Read goal spec (PLAN.md)
   b. Plan (touch list, success criteria)
   c. Act (bounded implementation)
   d. Verify (run validation scripts + conformance tests)
   e. Repair (fix failures, max 2 cycles)
   f. Review (independent check for HIGH-RISK)
5. Create PR
6. CI runs all 10 matrix checks (harness validation)
7. All checks pass → merge
8. State written to NOW.md (what was done, what's next)
```

The harness validates itself through CI. The loop validates its output through verification and review.

---

## Why This Separation Matters

Naming the layer fixes the diagnosis:

| Symptom | Layer | Fix |
|---------|-------|-----|
| Token blowups | Harness | Reduce standing context in AGENTS.md |
| Prompt fatigue | Harness | Prune skills, reduce context load |
| Dropped permissions | Harness | Fix settings.json allow/deny arrays |
| Loop never converges | Loop | Fix goal spec, add stop conditions |
| Verification passes garbage | Loop | Pull review into fresh context (sub-agent) |
| Same step repeats | Loop | Fix state file to capture progress |
| Scheduled runs drift | Loop | Fix scheduler to be dumber, not smarter |

Without this separation, you rewrite prompts when the real bug is a missing permission. Or you add more loop steps when the real issue is a harness file that drifted.

---

## See Also

- [docs/CAPABILITY_CATALOG.md](CAPABILITY_CATALOG.md) — every harness capability mapped
- [docs/RUNTIME_MAP.md](RUNTIME_MAP.md) — which files are authoritative vs generated
- [docs/CONFIGURATION_GUIDE.md](CONFIGURATION_GUIDE.md) — how to customize the harness
- [docs/VALIDATION.md](VALIDATION.md) — how CI validates the harness
- [examples/loop-runner/](../examples/loop-runner/) — minimal executable loop example
