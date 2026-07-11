# Operating Guide

> **How to use the OpenCode Agent Protocol in daily work.**

## Three Operating Modes

| Mode | Command | When to use |
|------|---------|-------------|
| **Autopilot Daily** | `oc` | Normal coding, UI, docs, tests, refactors |
| **Manual Ship** | `oc-manual` | Push, deploy, schema, CI, protocol, secrets |
| **Fresh Start** | `oc-fresh` | After protocol releases, clears stale serve artifacts |

### Autopilot Daily (`oc`)

Auto-approves safe operations. Safety boundaries are enforced by explicit `deny` rules:

- **Auto-approved:** File edits, lint, typecheck, test, build, dev server, git status/diff/log
- **Denied:** Secrets, packages, schema, auth/payment, CI, protocol, deploy configs, raw git mutations, destructive commands

### Manual Ship (`oc-manual`)

All permissions require your approval. Use for:
- Push to remote
- Deploy
- Package changes
- Schema/migration changes
- CI/CD changes
- Protocol changes
- Secret handling

### Fresh Start (`oc-fresh`)

Kills any existing `opencode serve` listener and starts a clean session. Use:
- After protocol releases
- When switching between repos
- When stale context is suspected

## After-Release Restart Rule

After every protocol release:

1. **Restart existing CLI sessions** — they may carry old summarized context
2. **Use `oc-fresh`** for the first new session
3. **Quit/reopen Desktop app** — it connects to shared `opencode serve`
4. **Stop/relaunch Web server**
5. **Open new terminal** or `source ~/.zshrc` if aliases changed

## Risk Lanes

| Lane | Risk | Files | Plan | Reviewer | Checkpoint |
|------|------|-------|------|----------|------------|
| DIRECT | 0 | 1 | None | No | Lite |
| FAST | 1-2 | ≤3 | Inline bullets | Optional | Lite |
| STANDARD | 3-5 | ≤6 | PLAN.md | Recommended | Full |
| HIGH-RISK | 6+ | ≤10 | PLAN.md + ADR | Required | Full |

**Forced HIGH-RISK:** auth, payment, schema, migration, cryptography, destructive action, user data, state model rewrite.

## Release Gates

Every PR goes through:

1. **Pre-commit hooks** — gitleaks, block-internal-files, conformance Tier 1
2. **CI gates** — lint, typecheck, test, build (if configured)
3. **Sensitive change classifier** — content-aware detection of auth/security/payment/schema changes
4. **Reviewer evidence detector** — checks if reviewer evidence exists
5. **Release decision report** — pass/block decision

### Reviewer Evidence

- **HIGH-RISK:** Reviewer evidence required — blocks without it
- **STANDARD:** Reviewer evidence recommended — warns if missing
- **FAST/DIRECT:** Reviewer not required

## Model Routing

Model routing is **advisory only** (`auto_applied: false`):

- Recommendations are generated from eval data
- Confidence levels: `high` (3+ unique tasks), `low` (1-2), `insufficient` (0)
- You must manually review and apply routing changes
- No auto-promotion without evidence

## Protocol Atlas

The [Protocol Atlas](docs/protocol/PROTOCOL_ATLAS.md) provides visual documentation:

- **5-minute explanation** — for anyone
- **15-minute deep dive** — for engineers
- **Non-technical overview** — for stakeholders
- 10 Mermaid diagrams covering the full operating loop

## Daily Workflow

```
User Task → Risk Classifier → Model/Agent Routing → Plan → Implement → Test → Review → Repair Loop → Release Gate → PR → Score → Lesson → ROI → Better Routing
```

1. **Intake:** Task classified by risk score
2. **Routing:** Model/agent selected (advisory)
3. **Plan:** Touch list, success criteria, rollback path
4. **Implement:** Bounded code changes
5. **Test:** Lint, typecheck, unit tests, build
6. **Review:** Reviewer evidence checked
7. **Release Gate:** CI gates, sensitive change classifier
8. **Score:** 7 dimensions + 2 penalties, max 35, pass 24
9. **Learn:** Lessons extracted to JSONL
10. **ROI:** Model performance normalized and analyzed

## How Agents Cooperate

The protocol uses a multi-agent architecture where the Orchestrator delegates to specialized sub-agents:

| Agent | Role | When |
|-------|------|------|
| Orchestrator | Routes tasks, owns strategy | Every session |
| Explorer | Read-only discovery | Before planning (cheap-first) |
| Planner | Creates plans, touch lists | Ambiguous/high-risk work |
| Implementer | Bounded code changes | After plan approval |
| Reviewer | Checks output | HIGH-RISK, sensitive paths |
| Architect | Auth/schema decisions | Architecture questions |
| Budget | Cheap summaries | Routine read-only work |
| Compaction | Context preservation | Long sessions |

All routing is **advisory only** — the Orchestrator makes final decisions. No auto-merge, no auto-push, no self-approval of HIGH-RISK changes.

See the [Protocol Atlas](docs/protocol/PROTOCOL_ATLAS.md#agent-topology--sub-agent-responsibilities) for the full topology diagram.

## What Is Out of Scope

- Unbounded autonomous production editing
- Auto-pushing to real repos
- Auto-merging PRs
- Self-approving HIGH-RISK changes
- Silent production mutation
- protected-repo (always excluded)
- Auto-applying routing or reviewer policy changes
