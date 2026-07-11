# /implement Runbook — Reference Documentation

> **Purpose:** Detailed runbook sections extracted from `/implement` command.
> **Status:** Reference-only. Loaded on demand. Not loaded at startup.
> **Parent command:** `.opencode/commands/implement.md`

## Multi-Repo Execution (v4.0)

If PLAN.md declares `Cross-repo dependencies` with 2+ repos:
- Identify primary repo (owns PLAN.md) and dependent repos
- Execute in declared order (primary first, then dependents):
  a. Switch to repo directory
  b. Output repo-local preflight (abbreviated for dependents)
  c. Execute repo's touch list from PLAN.md
  d. Run repo's quality gates per verification note
  e. Commit repo-local changes on isolated branch
- If any repo fails gates: stop, report "Multi-repo execution halted at [repo]: [gate] failed", do NOT proceed to next repo
- After all repos succeed: output multi-repo completion summary with per-repo commit hashes
- Final commit in primary repo references all dependent repo commit hashes
- Partial failure policy: halt and report — user decides whether to fix and retry or skip repo.

## UI/UX Quality Audit (v4.9.0)

If touch list includes UI files:
- Activate `ui-ux-quality-audit/SKILL.md`
- Audit: visual hierarchy, layout/grid/alignment, spacing rhythm, typography scale, color/token usage, component consistency, UX states (loading/empty/error/success/disabled), responsiveness, accessibility, motion/reduced-motion, microcopy quality, brand fit, anti-generic quality, delight, production readiness
- Capture screenshots at mobile (375px) and desktop (1440px)
- Output structured audit report with severity ratings (Critical/High/Medium/Low)
- If any Critical finding: stop and return to plan correction

## Accessibility Audit (v4.9.0)

If touch list includes UI files:
- Activate `accessibility-audit/SKILL.md`
- If repo-native axe-core/Playwright setup exists: run WCAG 2.2 AA scan
- If dependencies missing: mark NOT_RUN with reason, propose setup as separate approved task
- Check: contrast, focus order, keyboard navigation, labels/roles/landmarks, modal focus trapping, touch target size, prefers-reduced-motion, color not sole indicator
- Output structured a11y report with severity ratings
- Critical/High findings: stop and return to plan correction

## Responsive/State Audit (v4.9.0)

If touch list includes UI files:
- Activate `responsive-state-audit/SKILL.md`
- Test viewport matrix (375×667, 414×896, 768×1024, 1024×768, 1440×900, 1920×1080)
- Verify UX states (loading, empty, error, success, disabled, skeleton/shimmer where appropriate)
- Output structured report with pass/fail per area
- Responsive breakage at any breakpoint: stop and return to plan correction

## Visual Regression (v4.9.0, risk-based)

Per `visual-regression/SKILL.md`:
- Required: major UI surface, design-system change, layout change, landing page, dashboard, onboarding
- Advisory: minor style tweak
- NOT_RUN: text-only change, no UI change (document reason)
- If no baseline exists: capture screenshots as evidence only, not committed baselines
- Do NOT commit baseline screenshots without explicit approval
- Report pixel diff and manual review flag if threshold exceeded

## Motion Design (v4.9.1)

If touch list includes animation, transition, gesture feedback, loading skeletons, page transitions, onboarding entrances, hover/focus effects, or micro-interactions:
- Activate `motion-design/SKILL.md`
- Require: timing/easing rationale for each animation
- Require: `prefers-reduced-motion` handling
- Require: "when not to animate" check — motion must support clarity, not decoration
- Check: choreography (parent before child, staggered, focus-first, avoid all-at-once)
- Check: timing within spec for use case (100-150ms feedback, 150-250ms hover, 250-400ms entrance, 400-700ms ambient)
- Check: easing appropriate (ease-out for entrance, ease-in for exit, spring for physical feedback, linear only for progress)

## Platform Guidelines Compliance (v4.9.2)

If touch list includes UI targeting iOS / Android / Capacitor / React Native / mobile web:
- Activate `platform-guidelines-compliance/SKILL.md`
- Check: safe areas (notch, home indicator, status bar), touch targets (44×44pt Apple / 48×48dp Material / 24×24 WCAG minimum)
- Check: platform navigation patterns, native-feeling motion, dark mode/system preference handling
- Verify: platform vs custom brand decisions documented
- If any Critical platform violation: stop and return to plan correction

## Illustration/Graphic Direction (v4.9.2)

If touch list includes hero sections, onboarding, empty states, error pages, brand-sensitive screens, icons, illustrations, or custom visual assets:
- Activate `illustration-graphic-direction/SKILL.md`
- Require: visual metaphor, iconography style, brand motif, empty-state graphics defined
- Require: SVG/asset rules compliance, design-token consistency
- Require: no generic AI graphics, no copyrighted competitor visuals
- Do NOT generate or commit image assets without explicit approval
- If Critical graphic mismatch: stop and return to plan correction

## Visual Iteration Loop (v4.9.2)

After first browser screenshot for material visual changes (landing page, onboarding, dashboard, welcome screen, hero area):
- Activate `visual-iteration-loop/SKILL.md`
- Run: screenshot → critique top 5 weaknesses → revise top 3 → compare before/after
- Max 2 iterations per session
- Require: before/after evidence, no vague "make it pop" edits
- Verify: usability not harmed by aesthetic changes (NN/g aesthetic-usability effect)
- If after 2 iterations still has Critical visual weaknesses: stop and return to design rethink

## Performance / Lighthouse (v4.9.0, advisory)

Per `performance/SKILL.md`:
- For performance work that began from a vague optimization request, do not edit unless PLAN.md already names baseline measurement, target metric, suspected bottleneck, approved touch list, verification command, and rollback path.
- If repo-native LHCI/Lighthouse available: run and report
- If unavailable: mark NOT_RUN with reason
- Advisory only — does not block in v4.9.0

## Traceability Verification

After gates pass and before /checkpoint, verify implementation matches PLAN.md:
- Compare actual working-tree changes against the touch list in PLAN.md
- Verify every file on the touch list was touched
- Flag any files changed that are not on the touch list (unapproved scope expansion)
- Verify each success criterion has observable evidence
- Report traceability status:
  - **Aligned**: all touch-list files changed, no unapproved files, all success criteria evidenced
  - **Partial**: some touch-list files untouched or some success criteria not fully evidenced — state which
  - **Deviated**: unapproved files changed or scope expanded beyond plan — stop and ask user whether to proceed
- If Deviated: do NOT proceed to /checkpoint until user approves or the deviation is resolved

## Touch-List Expansion Policy

1. **Emit before editing:**
   - Files: <path>
   - Why needed: <reason>
   - Risk delta: <none / explain>
   - Verification impact: <none / explain>
   - Approval required: yes / no.

2. **Amend `<repo>/PLAN.md`**
   - Recompute lane and risk score if scope changed.
   - Stop and return to `/plan-feature` or the user if:
     - the expansion hits a sensitive path
     - the risk score increases enough to change lane
     - the autonomy budget would be exceeded
     - more than one expansion is needed without fresh approval.

## Verification Profile Selection

Use the plan's verification profile to determine the minimum required checks.

| Profile | Minimum required proof |
|---|---|
| `docs-config` | format/lint + targeted sanity check; add build if runtime config changed |
| `ui-surface` | lint + typecheck + build + browser verification + targeted UI smoke |
| `logic-backend` | lint + typecheck + targeted tests; add build if packaging/runtime changed |
| `stateful-sensitive` | lint + typecheck + full tests + build + security review + rollback note |
| `hotfix` | reproduce issue + targeted proof + regression check + rollback note |
| `default` | lint -> typecheck -> test -> build |

## Subject Containers

Before executing, check if any vault subject containers apply:
- Security / auth / crypto task → read `vault/subjects/Security.md`
- TypeScript / JavaScript task → read `vault/subjects/TypeScript.md`
- Architecture decision → read `vault/subjects/Architecture.md`
- Deployment work → read `vault/subjects/Deployment.md`
- Tests / TDD → read `vault/subjects/Testing.md`

Only read the subject file if the task clearly falls in that domain. Skip if no match.

## Skill Duplication Discipline

1. **Search existing skills** for overlapping behavior
   - Use `grep` or file search on `.opencode/skills/` for relevant keywords
   - Check if 70%+ of intended behavior exists in an existing skill
   - Review skill descriptions and when-to-use sections.

2. **If overlap found:**
   - Update existing skill instead of creating new
   - Add use-case section if new scenario needed
   - Document why existing skill was insufficient if proceeding with new skill.

3. **If proceeding with new skill:**
   - Justify why existing skills won't cover the use case
   - Keep skill focused (recommended < 500 tokens)
   - Ensure skill has clear when-to-use guidance.

## Reviewer Cost Guard

After gates pass, spawn Reviewer helper before commit if ANY of:
- Risk score is `4+`
- Touch list has 4+ files
- Any file is in an auth / payment / schema / security / crypto path
- The scope includes auth / security / payment / data / secrets changes
- Release or ship gates are in scope
- Implementation quality is unclear after gates
- Owner explicitly requests Reviewer.

State this intent once PLAN.md has been read. Reviewer output is required before commit.

For low-risk DIRECT/FAST work that does not match those triggers, sample review instead of spawning `opencode-go/glm-5.1` every time. Record `Reviewer: not required — <reason>` in the completion summary.

## Model Escalation

Default OpenCode model is `opencode-go/qwen3.7-plus` for the Owner/Planner path (v1.1-production). The bounded implementation helper is `opencode-go/qwen3.7-plus` (v1.1-production; reviewer-gated; fallback: qwen3.6-plus). Use `opencode-go/deepseek-v4-flash` only for cheap read-only classification/routing, not implementation.

## Typical Gate Sequence

```bash
npm run lint       # or: pnpm lint / cargo clippy / swiftlint
npm run typecheck  # or: tsc --noEmit
npm run test       # or: cargo test / swift test
npm run build      # or: cargo build / swift build
```
