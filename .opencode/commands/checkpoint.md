---
description: "Create a scoped checkpoint with status, evidence, and next-step continuity"
---

# /checkpoint

**Mode:** Any (Mentor / Planner / Executor / Reviewer)
**Model:** qwen3.7-plus (v1.1-production, Action 4D)
**Tool access:** Layer A (file ops, git)
**Success output:** repo-local checkpoint state prepared cleanly + vault persistence resolved or explicitly deferred + one-paragraph handoff summary written to chat

## Behaviour

When invoked, the Owner agent:

0. **Lite Checkpoint gate (v4.20):** If the task was DIRECT lane or trivial FAST (≤2 files, no sensitive paths, no protocol changes, no deployment):
   1. Update `<repo>/NOW.md` only if project state meaningfully changed
   2. One-line summary: what was done, what's next
   3. Done — skip all remaining steps
   
   **When to use full checkpoint instead (steps 1+):**
   - STANDARD or HIGH-RISK lane
   - Multi-session work
   - Deployment or protocol changes
   - Architecture/decision changes
   - Any task that changed project state beyond a simple edit

0b. **PROJECT_MEMORY.md update (v4.21):** During full checkpoint, update `<repo>/PROJECT_MEMORY.md` only when a meaningful change occurred:
   - New architecture decision or design direction
   - New recurring lesson or bug pattern
   - New testing or deploy command discovered
   - New known risk identified
   - Important component or file location changed
   - Major product decision made
   
   **Do NOT update PROJECT_MEMORY.md for:**
   - Trivial typo or UI copy changes
   - Routine bug fixes with no architectural impact
   - Dependency version bumps with no behavior change
   - Test additions that don't reveal new patterns
   
   If no meaningful change occurred, skip PROJECT_MEMORY.md update and note "No PROJECT_MEMORY.md update needed — no meaningful changes" in the checkpoint summary.

0c. **Pattern auto-capture suggestion (v4.25):** After STANDARD/HIGH-RISK work, if:
   - No existing pattern matched during pattern search (search-patterns.sh returned 0 matches), AND
   - A reusable solution was created (new architecture, auth flow, state pattern, data sync, etc.)
   
   Then suggest creating a PATTERN.md entry:
   ```
   Pattern capture suggested: <brief description>
   Template: .opencode/templates/PATTERN.md
   Source repo: <repo>
   ```
   
   Do NOT suggest pattern capture for:
   - Trivial bug fixes
   - UI copy/style changes
   - Config tweaks
   - DIRECT Lite tasks
   
   The agent should suggest, not auto-create. Owner approval required before creating PATTERN.md.

0d. **Usage summary (v4.26):** During full checkpoint (STANDARD/HIGH-RISK only), include a concise usage summary:
   ```
   Usage:
   Model: <model-name> (<provider>)
   Reviewer: <used / skipped — <reason>>
   Premium model: <yes — <reason> / no>
   Approximate tokens: <count / unknown>
   Cheaper model would have sufficed: <yes / no / unknown>
   Routing recommendation next time: <recommendation / same-as-current>
   ```
   
   Keep this to 6-8 lines maximum. Do not bloat Lite checkpoint with usage tracking.
   If token usage is unavailable, report "unknown" — do not fabricate counts.

1. Identifies the active repo from current session context
2. Reads the repo's current `NOW.md` (canonical state)
   - If `NOW.md` is missing but `PHASE_STATE.md` exists: read `PHASE_STATE.md` as legacy state input
3. **[LIFECYCLE GATE 3] Fast Final Gate** — runs before writing the checkpoint summary:

   | Lane | Required items |
   |------|----------------|
   | FAST | Items 1–4 only |
   | STANDARD / HIGH-RISK | All 8 items |

   Gate items:
   1. *Problem solved* — one sentence on what this change solves
   2. *Owner after launch* — who owns this feature/fix post-merge
   3. *What could break* — adjacent systems, consumers, or flows at risk
   4. *Evidence it works* — test name, smoke-test result, or manual check performed
   5. *How to measure success* — KPI or metric confirming the change achieved its goal _(S/HR)_
   6. *Rollback path* — cite from Completion Summary rollback note _(S/HR)_
   7. *Post-deploy observable* — log query, dashboard, or alert confirming health _(S/HR)_
   8. *Intentionally deferred* — known gaps left for a later session _(S/HR)_

   **BLOCK**: write NOW.md with `status: blocked` and `blockers: Fast Final Gate — [item that failed]`, then stop. Resume with `/checkpoint` next session after the blocker is resolved.

4. Updates it with:
   - Current task (from this session's work)
   - Current status (active / paused / blocked / complete)
   - Blockers (any blockers discovered this session)
   - Latest decisions (key decisions made this session)
   - Lane / risk / verification profile if they matter for the next session
   - Rollback note if one exists
   - Immediate next steps (what to do first in the next session)
5. Writes the updated content back to `<repo>/NOW.md`
   - If the repo was on legacy `PHASE_STATE.md` only: create `NOW.md` and report that state tracking was normalized
6. For successful execution sessions, prepare repo-local checkpoint state before
   the final local task commit so `NOW.md` is included in that same commit
 7. Reviews repo memory quality when relevant:
    - If `vault/projects/<repo>/lessons.md` exists and the current task touched an area covered by an older lesson: review whether that lesson is still accurate, mark it as refreshed, refresh-needed, or obsolete, update `Last verified: <ISO-date>` when confirmed still valid
    - See `.opencode/docs/commands/checkpoint-runbook.md` for full lesson review procedure
    - Do not bulk-prune unrelated lessons just because they are old
 8. Reviews branch/worktree lifecycle when relevant:
    - See `.opencode/docs/commands/checkpoint-runbook.md` for branch/worktree lifecycle procedure
 9. **ROADMAP.md review:** See `.opencode/docs/commands/checkpoint-runbook.md` for the ROADMAP.md review procedure.
10. Determines vault persistence outcome (ADR-002):
   - Run `git -C vault status --short` to check vault state
   - **CLEAN** (allowlist-only changes): commit in dedicated vault commit
   - **DIRTY** (unrelated changes exist): write patch to `/tmp/`, report DEFERRED
11. If vault is CLEAN (PERSISTED outcome):
   - Appends a one-line progress note to `vault/projects/<repo>/progress.md`
    - Appends one benchmark telemetry entry to `vault/projects/<repo>/benchmark-log.md` when the session produced meaningful execution evidence
      - include task type, lane, verification profile, helpers used, gate result, retries, rollback used, and outcome
      - include duration, files-changed, helper durations, or reviewer findings only when observed rather than guessed
    - Appends a loop state ledger entry to `vault/projects/<repo>/loop-ledger.md` when a Loop Run Contract was used or the task was STANDARD/HIGH-RISK/meaningful FAST:
      - include: date, repo, task title, lane, PGR used (none/name), eligibility verdict, contract used (none/compact/full), goal outcome (achieved/partial/failed/skipped), accepted change (yes/no), commit hash (if any), files changed count, gates run and result, retry outcome, budget outcome, escalation crossed (yes/no), rollback used (yes/no), PGR reflection (none/existing used/update candidate/new candidate), lesson learned (1-2 lines max), next recommended action, reviewer required (yes/no), reviewer completed (yes/no/not available), reviewer result (pass/concerns/blocking/not run), reviewer gap reason (if not run)
      - skip DIRECT and trivial FAST tasks unless a meaningful reusable lesson emerges
      - keep entries concise and diff-readable (one block per entry, separator between entries)
      - do not duplicate the full Loop Run Contract template
      - do not auto-edit PGR from ledger entries
      - if vault persistence is DEFERRED, mark ledger persistence as DEFERRED and explain why
      - if a task was blocked due to wrong-repo status (checked via `.opencode/PROJECT_REGISTRY.md`), record as `WRONG_REPO_BLOCKED` with: project name, status that caused block, recommended action
   - If this session made an architectural, expensive-to-reverse, or cross-session relevant decision:
     - append one concise entry to `vault/projects/<repo>/decisions.md`
     - include the decision, why it was chosen, and revisit trigger or reversal cost when known
   - If `<repo>/PLAN.md` exists:
     - Creates `vault/projects/<repo>/archived-plans/` if it doesn't exist
     - Copies `<repo>/PLAN.md` to `vault/projects/<repo>/archived-plans/<ISO-date>-<sanitized-feature-name>.md`
     - Deletes `<repo>/PLAN.md` from the product repo
   - Commits vault changes with message: `Protocol: checkpoint <repo> <ISO-date>`
   - Reports commit hash in output
12. If vault is DIRTY (DEFERRED outcome):
   - Writes intended vault changes to patch file: `/tmp/<repo>-vault-checkpoint-<ISO-date>.patch`
   - Does NOT commit vault changes
   - Reports deferral reason and patch path in output
 13. If runtime telemetry exposed unusual token or cost usage during the session:
    - include it in the checkpoint handoff as a soft-warning note
    - do not fabricate token or cost counts when the runtime did not expose them
  14. **Native token telemetry and benchmark telemetry:** See `.opencode/docs/commands/checkpoint-runbook.md` for native token telemetry, benchmark telemetry block, and behavioral drift tracking procedures.
  15. **Task outcome telemetry (v4.29):** For STANDARD/HIGH-RISK full checkpoints only:
      - Record task outcome using `bash .opencode/scripts/record-task-outcome.sh`
      - Include: repo, lane, task-type, outcome, model, reviewer, CI status, repair cycles, tests, memory usage, human acceptance
      - If a scorecard is available, include a concise summary line: `Scorecard: success_rate=X%, ci_first_pass=Y%, avg_repair=Z`
      - Do NOT record telemetry for DIRECT Lite or trivial FAST checkpoints
      - Telemetry is non-blocking: if recording fails, continue with checkpoint
  16. If a recent compaction anchor set exists or the current session resumed after compaction:
   - compare the anchor summary against live `NOW.md` / `PLAN.md` when feasible
   - output an explicit continuity confidence line: `OK`, `SUSPECT`, or `UNKNOWN`
   - if continuity looks suspect, say so explicitly in the handoff and name the drift
   - if continuity cannot be verified from live state, say `UNKNOWN` rather than assuming continuity
17. Checks NOW.md for active/blocked state — if active work is pending after
     checkpoint preparation, outputs a PENDING WORK WARNING (see Session-End
     Checkpoint in rules.md)
     - If NOW.md is missing: check for legacy PHASE_STATE.md, warn if neither exists
18. Uses GitGuard wrapper (`.opencode/git-guard/git-guard.sh`) for all mutating
     git operations (NOW.md commit, vault commit, PLAN.md archive)
19. Outputs checkpoint summary with explicit vault persistence outcome:

```
## Checkpoint — <repo> — <date>

Checkpoint prepared.

**Vault persistence:** PERSISTED / DEFERRED

<If PERSISTED:>
Vault commit: <hash>
Files: <list>

<If DEFERRED:>
Reason: <specific reason>
Patch: /tmp/<repo>-vault-checkpoint-<ISO-date>.patch
To apply: git apply /tmp/<repo>-vault-checkpoint-<ISO-date>.patch

Handoff: <one paragraph including unresolved risks, rollback note, branch/worktree lifecycle note when applicable, and any compaction continuity concern>

Continuity: <OK / SUSPECT / UNKNOWN>

Benchmark telemetry:
- Task type: <HOTFIX / FEATURE / REFACTOR / RESEARCH / DEPLOY / DESIGN / unknown>
- Lane: <FAST / STANDARD / HIGH-RISK>
- Verification profile: <profile or full>
- Outcome: <complete / paused / blocked / rolled-back>
- Gates: <summary>
- Helpers: <helper:model[:duration] list or None>
- Reviewer findings: <critical/high/medium/low counts or n/a>
- Retries: <root-cause counts or n/a>
- Rollback used: <yes/no + type if yes>
- Files changed: <count or unknown>
- Duration: <minutes or unknown>
- Native token stats (non-authoritative):
  - Input: <count or UNAVAILABLE>
  - Output: <count or UNAVAILABLE>
  - Cache Read: <count or UNAVAILABLE>
   - Cost: <amount or UNAVAILABLE>

Loop Run Contract Outcome (when applicable):
- Contract used: <none/compact/full>
- Goal outcome: <achieved / partial / failed / not applicable>
- Budget outcome: <within budget / exceeded / not tracked>
- Retry outcome: <attempts used> / <max attempts>
- Stop condition reached: <condition or N/A>
- Escalation boundary crossed: <yes/no>
- Rollback path changed: <yes/no>
- Loop ledger summary: <1–3 lines capturing key decisions/outcomes or N/A>
- PGR reflection: <existing PGR used / update candidate / new candidate / none>
  ```

 19b. **Loop Run Contract Outcome (when applicable):** See `.opencode/docs/commands/checkpoint-runbook.md` for the full Loop Run Contract Outcome fields and PGR Reflection workflow.

## Vault Persistence Policy (ADR-002)

See `.opencode/docs/commands/checkpoint-runbook.md` for the full vault persistence policy, allowlisted files, and CLEAN/DIRTY determination.

## When to run

See `.opencode/docs/commands/checkpoint-runbook.md` for when to run and fallback native session export.

## Output format

```
## Checkpoint — <repo> — <date>

Checkpoint prepared.

**Vault persistence:** PERSISTED / DEFERRED

<If PERSISTED:>
Vault commit: <hash>
Files: <list>

<If DEFERRED:>
Reason: <specific reason>
Patch: /tmp/<repo>-vault-checkpoint-<ISO-date>.patch
To apply: git apply /tmp/<repo>-vault-checkpoint-<ISO-date>.patch

Handoff: <one paragraph summarizing what was done, where things stand, unresolved risks, rollback note when applicable, branch/worktree lifecycle note when applicable, any compaction continuity concern, and vault persistence outcome>

Continuity: <OK / SUSPECT / UNKNOWN>

Benchmark telemetry:
- Task type: <...>
- Lane: <...>
- Verification profile: <...>
- Outcome: <...>
- Gates: <...>
- Helpers: <...>
- Reviewer findings: <...>
- Retries: <...>
- Rollback used: <...>
- Files changed: <...>
- Duration: <...>

Loop Run Contract Outcome (when applicable):
- Contract used: <none/compact/full>
- Goal outcome: <achieved / partial / failed / not applicable>
- Budget outcome: <within budget / exceeded / not tracked>
- Retry outcome: <attempts used / max attempts>
- Stop condition reached: <condition or N/A>
- Escalation boundary crossed: <yes/no>
- Rollback path changed: <yes/no>
- Loop ledger summary: <1–3 lines or N/A>
- PGR reflection: <existing PGR used / update candidate / new candidate / none>
```

## Fallback: Native Session Export

See `.opencode/docs/commands/checkpoint-runbook.md` for the native session export fallback procedure.

---

## Do not
- Skip this at end of session
- Let NOW.md go more than one session stale
- Leave PLAN.md in the repo after a feature is complete — archive it
- Leave successful repo-local runs ending without explicit vault persistence outcome
- Leave benchmark telemetry implicit when enough execution evidence existed to record it
- Turn `decisions.md` into a full diary — log only durable decisions
- Assume compaction continuity without checking anchors against live state when verification is feasible
- Use `git status vault/` from root — always use `git -C vault status --short`
- Print large diffs to chat — write patch to `/tmp/` instead
- Treat native session export as authoritative protocol state
- End session without checking NOW.md for active/blocked state — output PENDING WORK WARNING if found
