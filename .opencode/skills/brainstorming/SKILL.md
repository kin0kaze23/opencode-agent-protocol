---
name: brainstorming
description: Explore ideas and design approaches before any implementation. Propose 2-3 options with trade-offs. Get approval before writing a single line of code.
---

# Brainstorming Skill

> Activate for: any new feature, unclear requirements, significant architecture decision, or design choice.
> HARD GATE: No code until user approves the design. No exceptions.

---

## Why This Exists

Unexamined assumptions cause more wasted work than anything else. "Simple" tasks are where this matters most — everyone skips the process, then redoes the work. Five minutes of brainstorming saves hours of rework.

---

## Process (in order — do not skip steps)

### 1. Explore Context First
Before asking any questions, read:
- `CLAUDE.md` in the repo (if exists)
- `NOW.md` — current task state
- `<repo>/PLAN.md` — active scoped contract
- Recent git commits: `git log --oneline -10`
- Any existing component/module that's related

### 2. Ask Clarifying Questions — ONE AT A TIME
Never ask multiple questions in one message. Ask the most important question, wait for the answer, then ask the next.

Priority order:
1. What does "done" look like from the user's perspective? (the outcome, not the feature)
2. Who uses this? What's their context/situation when they use it?
3. What constraints exist? (auth, existing patterns, performance, mobile)
4. What's explicitly OUT of scope?
5. MVP or production-quality?

Use multiple-choice when possible — easier to answer than open-ended.

### 3. Propose 2-3 Approaches

Present options with clear trade-offs. Always lead with your recommendation:

```
APPROACH A (Recommended): <name>
What: <1-2 sentences>
Pros: <3 bullets>
Cons: <2 bullets>
Best when: <condition>

APPROACH B: <name>
What: <1-2 sentences>
Pros: <2 bullets>
Cons: <3 bullets>
Best when: <condition>

My recommendation: Approach A because <specific reason tied to their constraints>.
```

### 4. Present Design — Get Approval Section by Section

Scale each section to complexity. Get user approval after each:

For a component: 1-2 sentences per section is enough.
For a feature: a paragraph per section.
For an architecture decision: detailed trade-off analysis.

Sections:
- **What it does** (user-visible behavior)
- **How it's structured** (components, data flow, file locations)
- **Edge cases and error handling**
- **What's explicitly NOT included** (scope guard)

### 5. Write Design Doc

Save to: `<repo>/docs/plans/YYYY-MM-DD-<feature>-design.md`

```markdown
# Design: <Feature Name>
Date: YYYY-MM-DD
Status: APPROVED

## Problem
<what it solves>

## Approach
<chosen approach and why>

## Implementation
- Components/files to create/modify
- Data flow
- Key decisions

## Out of Scope
- <explicit exclusions>

## Success Criteria
- [ ] <measurable outcome>
- [ ] <measurable outcome>
```

---

## YAGNI Ruthlessly

At every step, ask: "Do they actually need this for the MVP?" Remove anything that isn't directly tied to the stated outcome. Features that aren't needed don't need to be built.

---

## After Brainstorming

Once design is approved, transition to execution:
- Call the `plan` agent if it's a multi-phase feature
- Call the `build` agent if it's a single-phase implementation
- NEVER start coding directly from this skill
