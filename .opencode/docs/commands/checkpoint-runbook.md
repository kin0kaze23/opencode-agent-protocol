# /checkpoint Runbook — Reference Documentation

> **Purpose:** Detailed runbook sections extracted from `/checkpoint` command.
> **Status:** Reference-only. Loaded on demand. Not loaded at startup.
> **Parent command:** `.opencode/commands/checkpoint.md`

## Vault Persistence Policy (ADR-002)

**Allowlisted files (per active repo):**
- `projects/<repo>/progress.md` — append-only progress log
- `projects/<repo>/benchmark-log.md` — append-only benchmark and ROI telemetry log
- `projects/<repo>/lessons.md` — append-only lessons log
- `projects/<repo>/decisions.md` — narrow decision log for durable choices
- `projects/<repo>/loop-ledger.md` — append-only loop state and outcome log
- `projects/<repo>/archived-plans/**` — plan archives

**CLEAN (PERSISTED):** `git -C vault status --short` shows only allowlisted changes for active repo.

**DIRTY (DEFERRED):** `git -C vault status --short` shows any other changes (global files, other repos, pre-existing edits).

**Note:** Vault is non-authoritative (ADR-001). Vault persistence outcome does NOT block canonical repo-local checkpoint.

## Loop Run Contract Outcome (when applicable)

Include this section when:
- A Loop Run Contract was used during the task, OR
- Task lane was STANDARD or HIGH-RISK, OR
- Task was gate-triage, protocol-maintenance, registry-related, runtime-config-related, or meaningful FAST work

Skip for DIRECT lane or trivial FAST tasks (<3 files, no meaningful pattern).

Capture only key outcome fields (do not duplicate the full Loop Run Contract template):
- Contract used: none/compact/full
- Goal outcome: achieved / partial / failed / not applicable
- Budget outcome: within budget / exceeded / not tracked
- Retry outcome: attempts used / max attempts
- Stop condition reached: `<condition>`
- Escalation boundary crossed: yes/no
- Rollback path changed: yes/no
- Loop ledger summary: 1–3 lines capturing key decisions/outcomes
- PGR reflection: existing PGR used / update candidate / new candidate / none

Keep this section concise (8–12 lines max). Do not auto-edit `.opencode/registry/productivity-gains.yaml` from checkpoint reflection. If PGR reflection suggests an update or new candidate, follow the PGR Reflection workflow.

## PGR Reflection (advisory, skippable)

Skip if: task was DIRECT lane, task was trivial FAST lane (<3 files, no meaningful pattern), PGR Maintenance Workflow already ran this session, user explicitly declined reflection, or task was blocked/interrupted.

If not skipped, ask:
1. Did this completed task reveal a repeatable workflow pattern not covered by existing PGR entries?
2. Did an existing PGR entry prove incomplete or outdated during this task?
3. Did a new tool, script, command, or validation workflow emerge that deserves cataloging?

If yes to any: follow `PGR Maintenance Workflow (v0.1)` in `.opencode/docs/productivity-gains.md` — output a session-only candidate proposal and request explicit owner approval.

Never edit `.opencode/registry/productivity-gains.yaml` without explicit owner approval.

## Behavioral Drift Tracking (v4.0)

- Calculate this session's protocol compliance: (protocol steps completed / protocol steps required) × 100
- Compare against running average from `vault/projects/<repo>/progress.md` if it exists
- If compliance dropped below 80% for 3+ consecutive sessions: flag drift warning in handoff
- Append drift status to `vault/projects/<repo>/progress.md`:
  `| <session> | <date> | <compliance%> | <steps skipped> | <drift warning if any> |`

## Benchmark Telemetry Block

Prepare a benchmark telemetry block for the handoff when feasible:
- Task type
- Lane
- Verification profile
- Outcome (`complete`, `paused`, `blocked`, `rolled-back`)
- Gate summary
- Retries by root cause when known
- Rollback used or not
- Files changed count when known
- Helpers used, models, and durations when known
- Reviewer finding counts when review happened
- Duration in minutes when known
- Never invent durations, costs, or file counts that were not observable

## Native Token Telemetry (non-authoritative support layer)

- Run `opencode stats --days 1` to get current session token usage
- Parse output for: Input tokens, Output tokens, Cache Read, Total Cost
- If stats unavailable or fails: mark as `UNAVAILABLE` and continue (do NOT block checkpoint)
- Never fabricate token or cost counts — use `UNAVAILABLE` when runtime does not expose them

## Branch/Worktree Lifecycle Review

- If the task ran on an isolated branch or worktree, note whether it is `active`, `blocked`, `merged`, `archived`, or ready to delete
- If an isolated branch/worktree has been blocked or stale for roughly 14 days, call for status review in the handoff
- If merge or abandonment makes cleanup safe, say whether the next action is archive or delete

## ROADMAP.md Review

**If phase/milestone completion detected** (PLAN.md archived with phase name, gates passed, user confirmed completion):
- Detect completed phase from archived PLAN.md filename or content
- Read current ROADMAP.md milestones table
- Propose specific update:
  ```
  ROADMAP.md update suggested:
  
  Current state:
  - Phase 5A: 🟡 In Progress
  
  Suggested state:
  - Phase 5A: ✅ Done
  - Phase 5B: 🟡 In Progress (next active phase)
  
  Rationale:
  - PLAN-5A-*.md archived to vault (YYYY-MM-DD)
  - All quality gates passed
  - User confirmed: "Phase 5A is complete"
  
  Reply:
  - 'approved' — Apply suggested updates (runs /update-roadmap --apply)
  - 'edit' — Open ROADMAP.md for manual editing
  - 'skip' — Keep current state, don't ask again this session
  ```

**If strategic direction changed** (new feature direction, pivot, scope change):
- Flag for human review (do NOT propose specific changes):
  "ROADMAP.md may need updating — strategic direction changed"
- Human decides the strategic update

**If unsure:** flag for human review rather than auto-updating.

## Lesson Review

If `vault/projects/<repo>/lessons.md` exists and the current task touched an area covered by an older lesson:
- review whether that lesson is still accurate
- mark it as refreshed, refresh-needed, or obsolete
- update `Last verified: <ISO-date>` when the lesson is confirmed still valid
- Do not bulk-prune unrelated lessons just because they are old

## Fallback: Native Session Export

If vault persistence fails (git error, permission issue, dirty state):
1. Run `opencode export` to save session to JSON
2. Note session ID in handoff: `Native backup: ses_<id>`
3. Continue with repo-local commit (vault is non-authoritative per ADR-001)
4. User can restore session later via `opencode import <session-id>`

**Important:** Native session export is backup continuity only. It does NOT replace:
- `NOW.md` as canonical state (ADR-001)
- Vault persistence for protocol artifacts
- Repo-local commits for code changes

## When to Run

- At the end of every working session
- After completing a major phase
- Any time the session is interrupted
