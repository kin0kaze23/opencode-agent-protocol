---
name: visual-iteration-loop
description: Visual iteration loop — screenshot-first critique, before/after comparison, structured revision, max 2 iterations per session
version: v4.9.2
---

# Visual Iteration Loop Skill

> Activate for: material visual surfaces (landing pages, onboarding, dashboards, hero sections)
> HARD RULE: Each iteration must address concrete findings, not "make it pop." Prevent aesthetic polish from masking usability issues.

---

## Purpose

Enforces structured visual quality iteration. Top-company design quality rarely appears in one pass. This skill creates an enforced loop: generate → screenshot → critique → revise → compare → repeat until quality bar met.

---

## The Iteration Loop

### Step 1: Generate / Implement
Implement the UI change or design as planned. Do not optimize for perfection on first pass.

### Step 2: Screenshot
Capture screenshots at minimum viewports:
- Desktop: 1440×900 (or repo-standard desktop)
- Mobile: 375×667 (or repo-standard mobile)

Store as evidence (not committed baselines without approval).

### Step 3: Critique — Identify Top 5 Visual Weaknesses

Use this structured checklist. For each item, rate: PASS / WEAK / FAIL.

| Check | What to Look For |
|---|---|
| **Alignment** | Are elements properly aligned to grid/baseline? (not floating, not off by pixels) |
| **Spacing** | Is whitespace intentional or accidental? (not random gaps, not uneven padding) |
| **Hierarchy** | Is the most important thing most prominent? (eye drawn to right element first) |
| **Color** | Are colors from design system, not random hex? (consistent, semantic, token-based) |
| **Typography** | Does type scale feel intentional? (not mixed sizes, not too many weights) |
| **Optical balance** | Do visual elements feel weighted correctly? (not left-heavy, not top-heavy) |
| **CTA prominence** | Is the primary action clearly the most important thing on screen? |
| **Visual noise** | Are there unnecessary decorative elements? (random lines, gradients, dots) |
| **Mobile density** | Does the mobile view feel appropriately spaced? (not cramped, not wasteful) |
| **Dark mode harmony** | Do colors translate correctly in dark mode? (not washed out, not too bright) |

### Step 4: Revise — Fix Top 3 Issues

Prioritize the top 3 findings from Step 3. Do not try to fix all 5 at once — focus on the most impactful changes.

**Rules:**
- Each revision must have a clear rationale (not "make it pop")
- Each revision should be testable (can be seen in before/after comparison)
- Do not change more than 3 things per iteration (prevents regression)

### Step 5: Compare Before/After

Capture new screenshots at same viewports. Compare:

| Comparison | Question | Answer |
|---|---|---|
| Before vs After | Did the change improve visual quality? | YES / NO + evidence |
| Usability check | Did the change make anything harder to use? | YES / NO + evidence |
| Consistency check | Does the change match the design system? | YES / NO + evidence |

### Step 6: Repeat or Conclude

If still has Critical/High visual weaknesses:
- Iterate again (max 2 iterations per session)
- Focus on remaining issues
- Document what changed and why

If meets quality bar:
- Conclude iteration
- Document final verdict with evidence

---

## Maximum Iterations

| Iteration | When to Use |
|---|---|
| Iteration 1 | First visual pass — fix top 3 issues |
| Iteration 2 | Refinement — fix remaining Critical/High issues |
| Stop | After 2 iterations, conclude even if not perfect |

**Why max 2:** Prevents endless tweaking. If after 2 iterations the UI still has Critical issues, it needs a design rethink, not more polish.

---

## NN/g Aesthetic-Usability Warning

**Critical rule:** Attractive interfaces can make users tolerate or overlook usability issues.

The visual iteration loop must evaluate BOTH:
1. **Visual appeal**: Does it look good? (alignment, spacing, hierarchy, color, typography)
2. **Usability**: Does it still work well? (readable, navigable, accessible, clear)

**If visual polish compromises usability, revert the polish.** Usability always wins.

---

## Evidence Format

```markdown
## Visual Iteration Log

### Iteration 1
Before: [screenshot path — desktop]
Before: [screenshot path — mobile]

Top 5 Visual Weaknesses:
1. [issue] — [WEAK/FAIL] — [specific finding]
2. [issue] — [WEAK/FAIL] — [specific finding]
3. [issue] — [WEAK/FAIL] — [specific finding]
4. [issue] — [WEAK/FAIL] — [specific finding]
5. [issue] — [WEAK/FAIL] — [specific finding]

Revised: [what changed — itemized list]
After: [screenshot path — desktop]
After: [screenshot path — mobile]
Improvement: [specific visual findings — not "looks better"]

### Iteration 2 (if needed)
Before: [screenshot path — desktop]
Before: [screenshot path — mobile]

Remaining Weaknesses:
1. [issue] — [WEAK/FAIL] — [specific finding]
2. [issue] — [WEAK/FAIL] — [specific finding]

Revised: [what changed — itemized list]
After: [screenshot path — desktop]
After: [screenshot path — mobile]
Improvement: [specific visual findings]

### Final Verdict
Visual quality bar met: YES / NO
Remaining issues: [list or "none"]
Usability not compromised by aesthetic changes: YES / NO
Before/after evidence complete: YES / NO
```

---

## Failure Conditions

Visual iteration loop fails (blocks completion) if ANY of:
- After 2 iterations, still has Critical visual weaknesses
- Aesthetic changes broke usability (harder to read, navigate, or understand)
- No before/after evidence provided
- Revisions were vague ("make it pop", "looks nicer") without specific changes

---

## NOT_RUN Rules

Mark as NOT_RUN with reason when:
- Bug fix or copy change — reason: "no visual change"
- Already passed visual iteration in prior session — reason: "iteration complete"
- Non-visual change (backend, API, config) — reason: "no UI surface involved"
- Dev server not available for screenshots — reason: "cannot capture before/after evidence"

---

## Integration with Other Skills

- Referenced by `ui-ux-quality-audit` for before/after screenshot critique
- Referenced by `illustration-graphic-direction` when graphics need critique and revision
- Referenced by `platform-guidelines-compliance` when platform-specific UI needs iteration
- Feeds into `verification-before-completion` structured UI evidence
- Delegates to `visual-regression` for pixel-level comparison when baseline exists
