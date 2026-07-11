---
description: "Apply ROADMAP.md milestone status updates with human approval"
---

# /update-roadmap

**Purpose:** Apply ROADMAP.md milestone status updates with human approval
**Mode:** Executor
**Model:** qwen3.7-plus (v1.1-production, Action 4D)
**Tool access:** Layer A (file ops, git)
**Success output:** ROADMAP.md updated with approval + committed

---

## Behaviour

When invoked, the Owner agent:

### Mode 1: `--propose` (Default)

1. Reads current `ROADMAP.md` milestones table
2. Detects completed phases from:
   - Recently archived PLAN.md files (check `vault/projects/<repo>/archived-plans/`)
   - Checkpoint outputs mentioning phase completion
   - User confirmations in session logs
3. Compares detected completions with ROADMAP.md current status
4. Outputs suggestions:
   ```
   ROADMAP.md update proposed:
   
   Current state:
   - Phase 5A: 🟡 In Progress
   
   Suggested state:
   - Phase 5A: ✅ Done
   - Phase 5B: 🟡 In Progress (next active phase)
   
   Rationale:
   - PLAN-5A-ONBOARDING-ALIGNMENT.md archived (2026-03-28)
   - All quality gates passed
   - User confirmed: "Phase 5A is complete"
   
   Reply:
   - 'approved' — Apply suggested updates
   - 'edit' — Open ROADMAP.md for manual editing
   - 'skip' — Keep current state, defer update
   ```
5. Waits for approval

### Mode 2: `--apply`

1. Checks for pending suggestions (from `--propose` or /checkpoint)
2. If none: outputs "No pending suggestions. Run /update-roadmap --propose first"
3. If exist: applies the updates to `ROADMAP.md`:
   - Update milestone status (🟡 → ✅)
   - Update "Current Phase" section
   - Update "Last updated" date
4. Commits with message: `docs: Update ROADMAP.md — <Phase> complete`
5. Reports commit hash

### Mode 3: `--edit`

1. Opens `ROADMAP.md` for editing (or displays current content)
2. Waits for user to provide updated content
3. Applies changes
4. Commits with user-provided message

---

## Detection Logic

**Phase completion detected when ALL of:**

1. ✅ PLAN.md archived to `vault/projects/<repo>/archived-plans/<date>-<phase>.md`
2. ✅ Quality gates passed (from checkpoint output)
3. ✅ User confirmation in session (e.g., "Phase 5A is complete")
4. ✅ ROADMAP.md shows phase as 🟡 In Progress (not already ✅ Done)

**If ANY condition missing:**
- Output: "Cannot auto-detect phase completion. Please update ROADMAP.md manually with /update-roadmap --edit"

**Pivot detection:**
- New feature direction explicitly stated
- Strategic goal changed
- Phase skipped or reordered

**Action:**
- Flag for human review (never propose pivot automatically)
- Output: "ROADMAP.md may need updating — strategic pivot detected. Use /update-roadmap --edit for manual update"

---

## Guardrails

### Must Verify Before Proposing

- [ ] Phase name matches (PLAN.md title matches ROADMAP milestone)
- [ ] User confirmed completion (explicit statement in session)
- [ ] Gates actually passed (checkpoint shows ALL PASS)
- [ ] Not already marked done (ROADMAP.md doesn't show ✅ Done)

### Must NOT Do

- [ ] Auto-update without approval
- [ ] Propose vision changes (Vision, Why This Why Now, pillars)
- [ ] Mark milestones done based on code alone (need user confirmation)
- [ ] Reorder milestones (strategic prioritization)
- [ ] Add new milestones (strategic planning)
- [ ] Update pivot table (strategic decisions)

### Allowed Updates

- ✅ Milestone status (🟡 In Progress → ✅ Done, ⚪ Planned → 🟡 In Progress)
- ✅ "Current Phase" section
- ✅ "Last updated" date
- ✅ "Next active phase" identification

### Human-Only Updates

- ❌ Vision statement
- ❌ "Why This, Why Now" rationale
- ❌ New milestones (adding)
- ❌ Milestone reordering
- ❌ Strategic pillars
- ❌ Pivots table (From → To → Rationale)

---

## Approval Workflow

```
User: /update-roadmap --propose

Agent:
"ROADMAP.md update proposed:

Current: Phase 5A: 🟡 In Progress
Update to: Phase 5A: ✅ Done

Current: Phase 5B: ⚪ Planned
Update to: Phase 5B: 🟡 In Progress

Reply 'approved' to apply, 'edit' to manually edit, 'skip' to defer"

User: approved

Agent:
✅ Updates ROADMAP.md
✅ Commits: "docs: Update ROADMAP.md — Phase 5A complete"
✅ Reports: "ROADMAP.md updated. Commit: abc1234"
```

---

## Output Format

### `--propose` mode
```
ROADMAP.md update proposed:

Current state:
- Phase 5A: 🟡 In Progress

Suggested state:
- Phase 5A: ✅ Done
- Phase 5B: 🟡 In Progress (next active phase)

Rationale:
- PLAN-5A-ONBOARDING-ALIGNMENT.md archived (2026-03-28)
- All quality gates passed
- User confirmed: "Phase 5A is complete"

Reply:
- 'approved' — Apply suggested updates
- 'edit' — Open ROADMAP.md for manual editing
- 'skip' — Keep current state, defer update
```

### `--apply` mode (after approval)
```
ROADMAP.md updated:
- Phase 5A: 🟡 In Progress → ✅ Done
- Phase 5B: ⚪ Planned → 🟡 In Progress
- Last updated: 2026-03-28

Commit: abc1234 "docs: Update ROADMAP.md — Phase 5A complete"
```

### `--edit` mode
```
ROADMAP.md opened for manual editing.

Current content:
<show current ROADMAP.md content>

Provide updated content or describe changes.
```

---

## Examples

### Example 1: Phase completion detected
```
User: /update-roadmap --propose

Agent proposes:
"ROADMAP.md update proposed:
 Phase 5A: 🟡 In Progress → ✅ Done
 Phase 5B: ⚪ Planned → 🟡 In Progress

Reply 'approved' to apply"

User: approved

Agent:
✅ Updates ROADMAP.md
✅ Commits
```

### Example 2: No completion detected
```
User: /update-roadmap --propose

Agent:
"No phase completions detected.
Criteria:
- PLAN.md archived: ❌ No
- Gates passed: ✅ Yes
- User confirmed: ❌ No

ROADMAP.md is current. No updates needed."
```

### Example 3: Strategic pivot (human-only)
```
User: /update-roadmap --propose

Agent:
"Strategic pivot detected (new feature direction).
This requires manual update.

Use: /update-roadmap --edit"
```

---

## Do not
- Auto-update without approval
- Propose vision or strategy changes
- Mark milestones done without user confirmation
- Skip detection logic verification
- Update pivot table automatically

---

## Integration with /checkpoint

When `/checkpoint` detects phase completion (step 7b), it outputs:
```
ROADMAP.md update suggested:
- Phase 5A: 🟡 In Progress → ✅ Done

Reply:
- 'approved' — Apply suggested updates (runs /update-roadmap --apply)
- 'edit' — Open ROADMAP.md for manual editing
- 'skip' — Keep current state, don't ask again this session
```

On 'approved', /checkpoint invokes `/update-roadmap --apply` internally.
