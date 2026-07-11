---
description: "Create a feature plan with risk assessment and execution lane"
---

# /plan-feature

**Mode:** Planner
**Model:** qwen3.7-plus (v1.1-production, Action 4D)
**Tool access:** Layer A (shell, file ops, search, git) + Explorer helper if needed
**Success output:** Handoff doc with objective, touch list, risks, phases

## Behaviour

When invoked, the Owner agent:

1. Runs preflight
2. Clarifies scope if needed (one question max)
3. Computes a risk score and selects an execution lane:
   - DIRECT (`0`) for trivial changes: 1 file, no sensitive paths
   - FAST (`1-2`) for very small, low-risk changes
   - STANDARD (`3-5`) for normal feature work
   - HIGH-RISK (`6+`) for sensitive, stateful, destructive, or hard-to-rollback work
   - If auth/payment/schema/crypto/state-model rewrite is in scope: force HIGH-RISK semantics
4. Applies vague-scope clarification (if any pattern matches):
   - **Unclear "done"**: User says "make it better" or "fix the UX"
     - Clarify: "What does 'done' look like from the user's perspective?"
   - **Hidden stakeholders**: "Add admin features"
     - Clarify: "Who is the admin? What can they do today vs. after?"
   - **Unbounded scope**: "Improve performance" or "Add security"
     - Clarify: "Which metric? From what baseline to what target?"
   - **Assumed contracts**: "Integrate with X" where X is unverified
      - Require: verification artifact (API doc, contract, working example)
4b. **Product Brief / PRD-lite Gate:** For net-new features, product-facing changes, or ambiguous requests, require a lightweight Product Brief before implementation readiness can be claimed. Tiny bug fixes may mark this section `N/A` only with a specific reason.
   - Required fields: user problem, target user/persona, job-to-be-done, desired user outcome, product/business objective, success metric, non-goals, acceptance criteria, edge cases, kill criteria, analytics/observability requirement.
   - If a required field is unknown and changes scope, risk, or acceptance criteria: block planning and ask for clarification rather than inventing intent.
4c. **UI Design Brief Gate:** If the task touches UI, frontend, pages, components, CSS, views, screens, or product-facing copy, require a UI Design Brief before implementation readiness can be claimed.
   - Required fields: target user and context, emotional tone, primary user action, visual hierarchy, layout direction, design-system source, responsive target matrix, UI state matrix, accessibility plan, content/copy tone, interaction/motion notes, non-goals.
   - Design-system source must name existing tokens/components to reuse or explicitly propose new tokens/components; do not silently introduce a new visual language.
4d. **v4.7.0 Active Template Selection Matrix:** Select templates by trigger, not by default. Compact/N/A paths remain allowed with reason and risk for DIRECT/FAST work.
   - `.opencode/templates/PRD.md`: required for net-new feature, product-facing, or ambiguous work; DIRECT/FAST tiny fixes may mark `N/A` with reason and risk.
   - `.opencode/templates/DESIGN_BRIEF.md`: required for UI/frontend/page/component/CSS/view/screen/product-copy work; otherwise `N/A` with reason and risk.
   - `.opencode/templates/QA_PLAN.md`: required for STANDARD/HIGH-RISK or stateful-sensitive work; DIRECT/FAST may use compact `N/A` or one-line gate mapping with reason and risk.
   - `.opencode/templates/THREAT_MODEL.md`: required for sensitive auth/payment/schema/security/crypto/user-data or HIGH-RISK paths; otherwise `N/A` with reason and risk.
    - `.opencode/templates/ADR.md`: required for high-risk architecture, schema, state-model, runtime-authority, or cross-surface decisions; otherwise `N/A` with reason.
 4e. **Loop Run Contract (planning guidance, non-enforcing):** For bounded closed-loop execution, reference `.opencode/templates/LOOP_RUN_CONTRACT.md` as planning guidance. This is not enforcement and does not change `/implement` behavior.
    - **DIRECT**: skip (trivial 1-file work, overhead outweighs benefit).
    - **FAST**: optional compact response-only contract when task is meaningful, touches protocol/commands/registry/runtime config, or has retries/gates.
    - **STANDARD**: required as planning guidance — define goal, scope, budget, retries, stop conditions, and gates before execution.
    - **HIGH-RISK**: required as planning guidance with explicit verification and escalation boundaries.
    - Filled Loop Run Contracts remain response-only for now unless a future command explicitly approves storing them in PLAN.md or checkpoint.
    - Do not duplicate the full template inside PLAN.md; reference it and fill key fields in the plan output when applicable.
    - **Read-only planning/triage tasks:** If the task is read-only (diagnostic, analysis, audit), the active touch list must be `None`. Use `Inspection scope` for files that may be read. Use `Possible future patch` for files that may be edited only after separate owner approval. Do not list files under `Modify` unless this plan actually authorizes edits.
 5. Optionally spawns Explorer helper to map unknown areas of the codebase
5b. **Dependency-impact scan for shared logic changes:**
   - If the feature touches shared logic, types, schemas, or core utilities:
     - Map dependent files (what imports or requires this?)
     - Map configs, commands, tests, docs affected
     - Map workflow assumptions and external consumers
     - For each dependent: coupling strength (tight/loose/optional), change impact (breaking/non-breaking/unknown)
     - Include dependency map in PLAN.md under "Dependencies" section
6. Runs runtime-wiring and touch-list audits when needed:
   - If multiple candidate modules/files could be the active implementation: activate `runtime-wiring-audit/SKILL.md`
   - If the plan changes a type/interface/schema/profile contract: activate `contract-touchlist-audit/SKILL.md`
   - If the task is a correction/replan after prior drift: activate `plan-correction-discipline/SKILL.md`
   - If the plan involves database schema changes or zero-downtime migration: activate `migration-patterns/SKILL.md`
   - If the plan defines or changes an API contract: activate `api-design/SKILL.md`
   - If the plan touches UI/design-system tokens, component reuse, responsive states, or visual drift risk: activate `design-system-governance/SKILL.md`
   - If the plan defines or changes API/client/server contracts: activate `api-contract-validation/SKILL.md`
   - If the plan touches deploy/runtime/CI/environment variables/secrets/health/rollback: activate `infra-validation/SKILL.md`
   - If the plan touches sensitive paths or HIGH-RISK trust boundaries: activate `threat-modeling/SKILL.md`
7. **[LIFECYCLE GATE 1] Analysis Gate** — before writing PLAN.md, output gate block with 5 fields:
   - *Current system behavior* — read relevant files to understand what exists today
   - *Dependencies* — APIs, DBs, queues, SDKs, auth providers touched
   - *Failure modes* — timeouts, bad input, missing permissions, partial outages
   - *Tech debt affecting this* — fragile areas or unstable foundations
   - *Migration / compat risk* — breaking changes, schema drift, consumer impact
   - FAST lane: one-liner per item. Gate must be output before PLAN.md regardless of lane.
   - **BLOCK**: write `<repo>/NOW.md` with `status: blocked` and `blockers: Analysis Gate — [reason]`, then stop. Resume with `/plan-feature` next session after the blocker is resolved.
 7b. **[Idempotency Audit]** — before writing PLAN.md, check whether the requested work already exists:
     - For each planned file in the touch list:
       - If file exists: read it, check if the requested function/change is already present
       - If already present: mark as "already done" in the plan
       - If file exists but change not present: label as "Modify" instead of "Create"
       - If file does not exist: proceed as planned
     - If all planned work is already done: report and stop — do not write PLAN.md
     - Include "Existing State" section in PLAN.md when partial overlap detected
      - **BLOCK**: If the agent would create a file that already exists with identical content: stop and report idempotency.
 7b5. **Design Research (v4.9.1)** — for qualifying UI work: net-new UI, major redesign, onboarding, landing pages, dashboards, brand-sensitive surfaces, or user-facing flows where aesthetics/emotion matter:
     - Activate `design-research/SKILL.md`
     - Require: product context, user emotional state, brand adjectives (3-5), competitor/adjacent-product audit, anti-pattern audit
     - Require: mood board to token translation (color, typography, spacing density, border radius, elevation/shadow, icon style, motion personality)
     - Require: selected design direction with rationale, rejected directions with rationale
     - Require: source-backed references as principles, not imitation
     - Require: rationale for every major aesthetic choice
      - Output feeds into Design Intelligence Brief (step 7c)
      - Not required for: bug fixes, minor polish, copy changes, following existing design system patterns
 7b6. **Platform Guidelines Compliance (v4.9.2)** — when target platform is iOS / Android / Capacitor / React Native / mobile web:
     - Activate `platform-guidelines-compliance/SKILL.md`
     - Require: target platform identification, safe area/notch handling plan, touch target sizing plan
     - Require: platform navigation pattern decision (follow convention vs custom brand)
     - Require: dark mode/system preference handling plan
     - Not required for: desktop-only web apps, internal admin tools
 7b7. **Illustration/Graphic Direction (v4.9.2)** — when UI involves hero sections, onboarding, empty states, error pages, brand-sensitive screens, icons, illustrations, or custom visual assets:
     - Activate `illustration-graphic-direction/SKILL.md`
     - Require: visual metaphor selection, iconography style decision, brand motif definition
     - Require: empty-state graphics plan, illustration style decision
     - Require: SVG/asset rules compliance, design-token consistency check
     - Require: avoidance of generic AI graphics
     - Not required for: data-only UI (tables, forms), following established design system patterns
 7b8. **Visual Iteration Loop Planning (v4.9.2)** — when creating or redesigning material visual surfaces (landing page, onboarding, dashboard, welcome screen, hero area):
     - Plan for: screenshot → critique → revise → compare loop
     - Plan for: max 2 iterations, top 5 weaknesses → top 3 revisions
     - Plan for: before/after evidence collection
     - Not required for: bug fixes, copy changes, non-visual work
 7c. **Design Intelligence Brief (v4.9.0)** — for qualifying UI work: net-new UI, major redesign, landing pages, dashboards, onboarding, or major user-facing flows:
    - Write a Design Intelligence Brief to `<repo>/docs/design-brief-<feature>.md`
    - Include: product context, target users, emotional design goal, design references as principles (not imitation), selected direction, rejected directions, typography direction, color direction, interaction/motion direction, accessibility constraints, responsive priorities, success criteria
    - Use official or reputable sources where helpful, such as Apple HIG, Material 3, WCAG 2.2, NN/g, and relevant product/domain references
    - Extract principles: clarity, hierarchy, restraint, accessibility, responsiveness, speed, trust, craft, consistency, and delight
    - Do not copy competitor UI — explain why the selected design direction fits the product context and users
    - Reference this brief in PLAN.md under "Design Reference"
    - Not required for: bug fixes, minor polish, copy changes, existing component tweaks
 8. Writes a feature plan with:
   - Lane (`FAST` / `STANDARD` / `HIGH-RISK`)
   - Risk score (with factor summary)
   - Objective (one sentence)
   - Verification profile:
     - `docs-config`
     - `ui-surface`
     - `logic-backend`
     - `stateful-sensitive`
     - `hotfix`
   - Branch strategy:
     - current branch allowed for FAST only when clean
     - isolated branch/worktree required for STANDARD and HIGH-RISK
   - Autonomy budget:
     - max files
     - max commands before summary
     - max gate retries
     - max touch-list expansions
   - Rollback note (structured recipe):
     - Type: discard-working-tree / revert-commit / drop-branch-or-worktree / disable-flag-or-config / restore-previous-deployment / other
     - Scope: what is being reversed or disabled
     - Preconditions: what must be true before using this rollback
     - Action: exact command or operator action
     - Verify: how to confirm rollback succeeded
   - Touch list (exact files to create or modify, labelled Create/Modify/Test)
   - Risk areas (what could break)
   - Phase breakdown (each phase has an entry condition and done criteria)
    - Success criteria (observable, testable)
    - Product Brief / PRD-lite for net-new features, product-facing changes, and ambiguous requests; or `N/A` with reason for tiny bug fixes
    - UI Design Brief for UI/frontend/page/component work; or `N/A` with reason when no user-facing UI is touched
    - QA Plan for STANDARD/HIGH-RISK or stateful-sensitive work; compact/N/A with reason and risk for DIRECT/FAST when appropriate
    - Threat Model for sensitive paths; or `N/A` with reason and risk
    - ADR for high-risk architecture/schema/state/cross-surface decisions; or `N/A` with reason
    - Explicit runtime authority:
     - active entrypoint / mount path / router / lazy import that proves which implementation is live
   - Explicit state model whenever form state, onboarding flows, or other multi-step data collection is changed:
     - direct-to-model writes vs draft object vs reducer/state machine
   - Complete contract touch list whenever changing a type/interface/schema/profile shape:
     - constructors
     - defaults
     - migrations
     - helper builders/adapters
     - tests/prompts/runtime consumers
   - For each decision, marks decide-now-vs-defer:
     - **Decide now**: Blocks all downstream work; reversible cost is high
     - **Defer**: Can be decided later; reversible cost is low; more info available later
     - Default: defer unless it blocks downstream work
   - Narrow-first slicing (soft rule):
     - First phase should be: testable in isolation, reversible, unblocks learning, user-visible
     - Avoid infrastructure-only/auth-only/schema-only first slices UNLESS:
       - They are the smallest verifiable blocker, OR
       - The task is explicitly foundational (infrastructure IS the feature)
   - If the requested work combines UI/UX surface simplification with schema, type, prompt, validator, or state-contract changes, split it into separate execution slices unless a data-path audit proves the coupling is already safe
   - If the plan depends on confidence scores, evidence links, source display, or any newly surfaced grounded data, require a data-path audit that verifies the data survives validators, state hydration, and UI lookup paths before implementation
   - Prefer the smallest trustworthy slice first when the user goal is product readiness, reduced cognitive load, or trust restoration
   - For release-readiness or audit follow-up work: prioritize evidence-gathering and verification steps before proposing new feature work
   - If a blocker is only inferred, add a prove/disprove step before planning a fix
   - If work depends on a third-party auth, API, runtime, or callback contract, require a named verification artifact before implementation and block code until it is complete
   - Distinguish intended product behavior from verified external behavior when writing the plan
   - Use exact repo routes/commands when known; if an example is illustrative only, label it as pseudocode
   - Before including runnable API examples, verify path/method/field names/status values against route handlers, shared validators, and schema/constants
   - For conflict/error tests, verify that the chosen scenario actually produces that error rather than an idempotent success path or skipped/no-op response
   - If the requested slice spans multiple repos:
     - name one **primary repo** that owns the active `<repo>/PLAN.md`
     - list every dependent repo explicitly under `Cross-repo dependencies`
     - keep a separate touch list and verification note for each dependent repo
     - sequence the work so one repo remains the active execution surface at a time
     - stop and ask for explicit approval before implementation if more than one repo needs code changes in the same slice
     - do not hide cross-repo work inside a single-repo touch list
   - FAST lane may use a compact one-phase plan, but it still writes `<repo>/PLAN.md`
9. Writes the plan to `<repo>/PLAN.md` (creates or overwrites) with status
   `PENDING USER REVIEW`
   - Supporting analysis docs may also be written under `docs/`, but they are never the active implementation contract
   - The active implementation contract must exist at `<repo>/PLAN.md`
10. Outputs to chat: "Plan written to `<repo>/PLAN.md`. Reply 'approved',
   'proceed', or 'Approved, batch next <N> steps' (STANDARD only, `N <= 3`) to
   start implementation."
11. Stops. Does not proceed to implementation.

## Output format

Written to both chat AND `<repo>/PLAN.md`. PLAN.md format:

```
## Feature Plan: <feature name>
Status: PENDING USER REVIEW
Date: <ISO date>

Lane: <DIRECT / FAST / STANDARD / HIGH-RISK>
Risk score: <0-10> (<factor summary>)

Objective: <one sentence>

Existing State: (include only when idempotency audit found overlap)
  - <path>: EXISTS — <description>
  - <path>: EXISTS with partial overlap — <description>
  - Recommendation: <no changes needed / modify existing / create new>

Verification profile: <direct / docs-config / ui-surface / logic-backend / stateful-sensitive / hotfix>
Branch strategy: <current branch allowed / isolated branch / isolated worktree>
Autonomy budget: <files / commands / retries / expansions>
Design Decision: <required for HIGH-RISK, optional otherwise>
Rollback note:
  - Type: <rollback type>
  - Scope: <exact rollback scope>
  - Preconditions: <what must be true first>
  - Action: <exact command or operator action>
  - Verify: <how rollback success is confirmed>

Touch list:
  - Create: <path>
  - Modify: <path>
  - Test: <path>

Phases:
  Phase 1: <name> - <done criteria>
  Phase 2: <name> - <done criteria>

Risks:
  - <risk> -> <mitigation>

Product Brief / PRD-lite:
  - User problem: <problem or N/A with reason>
  - Target user/persona: <user>
  - Job-to-be-done: <job>
  - Desired user outcome: <outcome>
  - Product/business objective: <objective>
  - Success metric: <metric>
  - Non-goals: <explicit exclusions>
  - Acceptance criteria: <criteria>
  - Edge cases: <cases>
  - Kill criteria: <when to stop/reject this direction>
  - Analytics/observability requirement: <events/logs/metrics or N/A with reason>

UI Design Brief:
  - Target user and context: <user/context or N/A with reason>
  - Emotional tone: <tone>
  - Primary user action: <action>
  - Visual hierarchy: <what is most/least prominent>
  - Layout direction: <layout approach>
  - Design-system source: <existing tokens/components or proposed new tokens/components>
  - Responsive target matrix: <mobile / tablet / desktop / wide expectations>
  - UI state matrix: <loading / empty / error / disabled / success>
  - Accessibility plan: <keyboard / focus / labels / contrast / reduced motion>
  - Content/copy tone: <tone>
  - Interaction/motion notes: <hover/focus/transitions or N/A>
  - Non-goals: <visual/product exclusions>

QA Plan:
  - Required gates: <lint/typecheck/test/build/browser/security/contract/infra or N/A with reason>
  - Edge cases: <cases or N/A>
  - Baseline/failure classification strategy: <TARGETED_FAILURE / BROAD_BASELINE_FAILURE / FLAKY_OR_INFRA_FAILURE / NOT_RUN / ACCEPTED_NON_BLOCKING / BLOCKING_UNKNOWN usage>

Threat Model:
  - Assets: <assets or N/A with reason>
  - Actors: <actors or N/A>
  - Trust boundaries: <boundaries or N/A>
  - Sensitive risks: <STRIDE-style risks or N/A>
  - Residual risk owner: <owner or N/A>

ADR:
  - Decision: <decision or N/A with reason>
  - Options considered: <options>
  - Consequences: <tradeoffs>

Loop Run Contract (key fields only; full template remains response-only):
  - Reference: `.opencode/templates/LOOP_RUN_CONTRACT.md`
  - Adoption: <DIRECT: skip / FAST: optional compact / STANDARD: required / HIGH-RISK: required with explicit boundaries>
  - Goal: <one sentence verified outcome>
  - Scope: <allowed files / forbidden files / allowed commands>
  - Budget: <max helper calls / max files inspected / max commands / max retries>
  - Stop conditions: <when to stop regardless of progress>
  - Escalation boundary: <when to escalate to Owner/Reviewer/Architect/user>
  - Inspection scope: <files that may be read for read-only tasks, or "N/A">
  - Possible future patch: <files that may be edited only after separate owner approval, or "N/A">
  - Note: filled contract remains response-only unless a future command explicitly approves storage

Success criteria:
  - <observable outcome>

Cross-repo dependencies:
  - Primary repo: <repo name> -> <touch list> -> <verification note>
  - Dependent repo: <repo name> -> <touch list> -> <verification note>
  - Execution order: <repo1> -> <repo2> -> <repo3>
  - Verification split: <per-repo verification or "Primary repo only">

Dependencies (for shared logic changes):
  - Dependent files: <list>
  - Configs affected: <list>
  - Tests to update: <list>
  - Breaking changes: <list or "None">
  - Non-breaking changes: <list>
```

## Vague-Scope Clarification

Before writing the plan, check for these ambiguity patterns:

1. **Unclear "done"**: User says "make it better" or "fix the UX"
   - Clarify: "What does 'done' look like from the user's perspective?"
2. **Hidden stakeholders**: "Add admin features"
   - Clarify: "Who is the admin? What can they do today vs. after?"
3. **Unbounded scope**: "Improve performance" or "Add security"
   - Clarify: "Which metric? From what baseline to what target?"
4. **Assumed contracts**: "Integrate with X" where X is unverified
   - Require: verification artifact (API doc, contract, working example)

## Decide-Now-vs-Defer Framework

For each decision in the plan, mark:
- **Decide now**: Blocks all downstream work; reversible cost is high
- **Defer**: Can be decided later; reversible cost is low; more info available later
- Default: defer unless it blocks downstream work.

## Narrow-First Slicing Criteria

When prioritizing the first phase:
1. **Testable in isolation**: Can verify without other phases
2. **Reversible**: Undo cost is low if wrong
3. **Unblocks learning**: Teaches something needed for later phases
4. **User-visible**: User can see progress, not just scaffolding

Avoid infrastructure-only/auth-only/schema-only first slices UNLESS:
- They are the smallest verifiable blocker, OR
- The task is explicitly foundational (infrastructure IS the feature)

## Do not
- Write implementation code
- Commit any changes
- Proceed to implementation without explicit user approval
- Invent validation commands or API routes
- Use schema field names, statuses, or activity action names that are not validated against the repo
- Promote non-contract polish items into P0 without citing the governing contract
- Treat an unverified external contract as implementation-ready
- Leave the active plan only in `docs/` or any location other than `<repo>/PLAN.md`
- Mix UI simplification and schema/prompt/state-contract expansion in one slice without an explicit data-path audit or a written reason that the coupling is already safe
- Call a phase `implementation-ready` if runtime authority, state model, or the contract touch list are still implicit or incomplete
- Omit lane, risk score, verification profile, autonomy budget, or rollback note from a non-trivial plan
- Hide multi-repo implementation inside a single-repo plan without naming the primary repo, dependent repos, and per-repo verification
- Claim product-facing or net-new feature work is implementation-ready without a Product Brief / PRD-lite section in PLAN.md
- Claim UI/frontend/page/component work is implementation-ready without a UI Design Brief section in PLAN.md

## Approval gate
After writing PLAN.md and outputting the plan to chat, stop and wait.
Only proceed to implementation when user says 'approved', 'proceed', or a valid
batched approval phrase for the current scoped task.
If `/implement` is run while PLAN.md status is `PENDING USER REVIEW`:
`/implement` displays the Objective and Touch list, then prompts inline for
`proceed`, `cancel`, or a valid batched approval phrase. On approval,
`/implement` updates PLAN.md status to `APPROVED` and continues. On `cancel`, it
stops.
