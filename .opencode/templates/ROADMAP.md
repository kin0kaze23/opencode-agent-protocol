# ROADMAP.md Template

> Copy to `<repo>/ROADMAP.md` (repo root, NOT docs/)
> Keep to ~1 page max. Update on pivots or quarterly.

---

# {{REPO_NAME}} — Roadmap

> **Status:** active | paused | MVP | archived | showcase
> **Status definitions:**
> - `active`: Under active development
> - `paused`: Development paused (awaiting decision/resources)
> - `MVP`: Production MVP, minimal maintenance
> - `archived`: No active development, preserved for reference
> - `showcase`: Demo/reference implementation
> **Last updated:** {{YYYY-MM-DD}}
> **Review trigger:** on strategic pivot or quarterly

## Vision

<One sentence: what world does this create and for whom?>

## Why This, Why Now

<1-2 sentences: the opportunity or problem driving this>

## Current Phase

**{{Phase Name}}** — <what "done" looks like for this phase>

**Target:** {{Q2 2026 or specific date or TBD}}

## Milestones

| Milestone | Target | Status |
|---|---|---|
| {{Phase 1}} | Q1 2026 | ✅ Done |
| {{Phase 2}} | Q2 2026 | 🟡 In Progress |
| {{Phase 3}} | Q3 2026 | ⚪ Planned |

Status: ✅ Done | 🟡 In Progress | 🔴 Blocked | ⚪ Planned

## How We're Guiding This

- {{Strategic pillar 1}}
- {{Strategic pillar 2}}
- {{Technical approach / key constraint}}

## Known Pivots

| Date | From | To | Rationale |
|---|---|---|---|
| {{YYYY-MM-DD}} | <old direction> | <new direction> | <why> |

---

## Agent Integration

**This file is read by agents during startup.**

Placement: repo root (`<repo>/ROADMAP.md`), NOT in `docs/`.
Integration: Listed in `AGENTS.md` startup sequence (step 4b).

## Maintenance

- **Update trigger:** strategic pivot OR quarterly review OR phase completion
- **Update workflow:**
  - Automatic detection: `/checkpoint` flags when phase complete
  - Propose updates: `/update-roadmap --propose`
  - Apply with approval: Reply 'approved' or `/update-roadmap --apply`
  - Manual edit: `/update-roadmap --edit`
- **Time budget:** 30 seconds (approval) / 10 minutes (manual edit)
- **Owner:** Workspace owner (approval) + agents (drafting)
- **Archive:** Old versions stay in git history (no manual archiving needed)

**What agents can update (with approval):**
- ✅ Milestone status (🟡 → ✅, ⚪ → 🟡)
- ✅ "Current Phase" section
- ✅ "Last updated" date

**What stays human-only:**
- ❌ Vision statement
- ❌ "Why This, Why Now" rationale
- ❌ Strategic pillars
- ❌ New milestones (adding)
- ❌ Milestone reordering
- ❌ Pivots table
