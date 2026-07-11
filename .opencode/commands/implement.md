---
description: "Execute a scoped implementation plan with approved touch list and gates"
---

# /implement

**Mode:** Executor
**Model:** opencode-go/qwen3.7-plus (v1.1-production, Action 4D; fallback: qwen3.6-plus)
**Tool access:** Layer A + Layer B for builds
**Success output:** Passing quality gates + committed code + browser evidence for qualifying web UI changes

## Behaviour

When invoked, the Owner agent:

0. **Phase M1 pre-edit safety classifier (mandatory before DIRECT/FAST shortcuts):**
   - Classify the request before editing as one of: `clear_implementation`, `ambiguous_implementation`, `ambiguous_performance`, `unsafe_security`, or `plan_only`.
   - If `ambiguous_implementation`: do not edit. Ask for clarification or create/repair PLAN.md so runtime authority, success criteria, approved touch list, verification command, and rollback path are explicit.
   - If `ambiguous_performance` (for example “make the app faster”, “optimize performance”, “speed this up”): do not edit until the plan includes baseline measurement, target metric, suspected bottleneck, approved touch list, verification command, and rollback path.
   - If `unsafe_security` (for example bypass auth, disable rate limits, loosen CORS broadly, expose secrets, evade detection, or weaken validation): refuse early, avoid unsafe implementation details, and offer a defensive alternative such as threat modeling, least-privilege configuration, scoped allowlists, local-only fixtures, or tests that prove controls remain intact.
   - If the request is blocked here, output the missing fields and stop before running DIRECT/FAST or touching files.

   **Lite Delegation Mode (v4.20):**
   - If DIRECT lane AND lite mode conditions are met (no sensitive paths, no production deploy, no cross-repo, no protocol/config changes):
     - Read target file → Edit → Run lint → Report result in 3-5 lines → Commit → Done
     - Skip steps 3-14 entirely
     - No PLAN.md, no completion summary, no checkpoint, no reviewer
   - If FAST lane AND lite mode conditions are met:
     - Write 3-5 bullet plan inline → Read relevant files (max 3) → Edit → Run relevant gates → 5-field summary → Commit → Lite checkpoint → Done
     - Skip steps 3-6, 8-11, 12b-12j, 13-14
     - No full PLAN.md, no full completion summary, no full checkpoint, no reviewer unless risk expands
   - Lite mode does NOT apply when: sensitive paths touched, production deploy, cross-repo, protocol/registry/config changes
   - **v4.20.1:** Run `bash .opencode/scripts/lite-mode-eligibility.sh <files>` to mechanically verify eligibility
   - If lite mode does not apply, continue to step 1 below

   **Code Intelligence + Lesson Retrieval (v4.21):**
   - **DIRECT Lite:** Skip code index and lesson retrieval — keep it fast. Only use if the target file is unknown.
   - **FAST Lite:** Optionally run `bash .opencode/scripts/search-code-index.sh <repo> "<task keywords>"` when the target files are not obvious from the request.
   - **STANDARD / HIGH-RISK:** Before editing, always run:
     1. `bash .opencode/scripts/search-code-index.sh <repo> "<task keywords>"` — find relevant files and symbols
     2. `bash .opencode/scripts/retrieve-lessons.sh <repo> "<task keywords>"` — retrieve past lessons, risks, and decisions
   - **Escalation from lessons:** If retrieved lessons mention auth, RLS, payment, migration, schema, secrets, crypto, deploy, or production — require reviewer or escalation as appropriate, even if the lite-mode-eligibility classifier allowed Lite Mode.
    - **Lesson-informed touch list:** If retrieved lessons mention a specific file, pattern, or risk, incorporate that into the touch list or verification plan before editing.

   **Test Expectation Rule (v4.22):**
   - Bug fix or logic change: tests required, or explicit no-test justification in completion summary
   - Refactor: existing tests must pass, or characterization tests added
   - DIRECT style/copy change: no test burden
   - HIGH-RISK: full test suite + reviewer required
   - No-test justification format: `Tests: not added — <reason>`

   **Senior Self-Review (v4.22):**
   - Before PR creation for STANDARD/HIGH-RISK (optional for FAST): run `bash .opencode/scripts/senior-self-review.sh`
   - If any checklist answer reveals a problem: fix before PR
   - For CI-first verification: create PR first, let CI validate, then review CI output

   **Test Intelligence (v4.23):**
   - **DIRECT Lite:** Skip test discovery — keep it fast.
   - **FAST:** After candidate files are known, run `bash .opencode/scripts/find-tests.sh <repo> <files>` to discover nearby tests. If bug/logic change: add or update tests. If visual-only: provide no-test justification.
   - **STANDARD / HIGH-RISK:** Always run `bash .opencode/scripts/find-tests.sh <repo> <files>` before editing. Apply test expectation based on change type:
     - Bug fix: regression test required
     - Logic change: unit or integration test required
     - Refactor: existing tests or characterization tests required
     - UI visual-only: no-test justification accepted
     - HIGH-RISK: full suite + reviewer required
   - **No-test justification:** `Tests: not added — <specific reason>` (vague justifications are not accepted)
   - **Run targeted tests:** After implementation, run the test command for changed area (e.g., `pnpm test -- --grep <component>`)

   **Proactive Test Generation (v4.25):**
   - **DIRECT Lite:** Skip untested-code detection — keep it fast.
   - **FAST:** After implementation, run `bash .opencode/scripts/detect-untested.sh <repo> <files>` to find missing coverage. If bug/logic change: add focused regression or unit test. If UI-only: provide no-test justification.
   - **STANDARD / HIGH-RISK:** Always run `bash .opencode/scripts/detect-untested.sh <repo> <files>` after implementation. Apply test generation rules from `/auto-test-generation`:
     - Bug fix: regression test required
     - Logic change: unit/integration test required
     - Refactor: existing tests or characterization tests
     - UI-only: no-test justification accepted
     - HIGH-RISK: full suite + reviewer
   - **Test generation:** Write focused tests covering the specific changed behavior. Place in suggested test file path. Run targeted test command to verify.
   - **No-test justification:** `Tests: not added — <specific reason>` (vague justifications rejected)

   **Pattern Memory (v4.24):**
   - **DIRECT Lite:** Skip pattern search — keep it fast.
   - **FAST:** May use `bash .opencode/scripts/search-patterns.sh "<task keywords>"` when context is unknown or the problem is unfamiliar.
   - **STANDARD / HIGH-RISK:** For architecture, auth, database, state management, payment, infra, deployment, design system, or reusable feature work — always run:
     1. `bash .opencode/scripts/search-patterns.sh "<task keywords>"` — find reusable patterns from other projects
     2. If a relevant pattern exists: reuse it or explain why not
     3. If no pattern exists: proceed with the implementation and note "no reusable pattern found" for future capture
   - **Cross-project lessons:** For STANDARD/HIGH-RISK, also run `bash .opencode/scripts/retrieve-lessons.sh <repo> "<keywords>" --cross-project` to find lessons from other repos
   - **Pattern reuse evidence:** If a pattern was reused, note it in the completion summary: `Pattern reused: <pattern-name> from <source-repo>`

   **Loop awareness reminder (non-enforcing):**
   - If this task is part of a bounded loop, confirm the Loop Eligibility Check has passed, the Loop Run Contract is available when required, and checkpoint/ledger persistence will be handled at completion.
   - If eligibility was not run: DIRECT/trivial FAST may skip loop overhead; meaningful FAST, STANDARD, and HIGH-RISK tasks should confirm eligibility or record the missing eligibility as a checkpoint gap.
   - If a Loop Run Contract exists, follow its touch list, stop conditions, escalation boundaries, rollback path, and maker-checker reviewer triggers.

   **Project registry reminder (non-enforcing):**
   - For production, deploy, hotfix, or repo-specific tasks, check `.opencode/PROJECT_REGISTRY.md` before editing.
   - If the target project is marked `NOT_CLONED`, `archive-candidate`, `local-first`, or `canonical-pending-cleanup`, stop before editing and report the repo identity mismatch.
   - Record wrong-repo blocks in the loop ledger as `WRONG_REPO_BLOCKED` when the task is meaningful.

1. **DIRECT lane check (v4.0):** If task is risk 0, 1 file, no sensitive paths:
   - Not allowed when the Phase M1 classifier returns `ambiguous_implementation`, `ambiguous_performance`, `unsafe_security`, or `plan_only`.
   - Output 5-field preflight (Repo, Mode, Lane: DIRECT, File, Success criteria)
   - Edit file directly — no PLAN.md required
   - Run lint gate only
   - Commit with conventional message — current branch only
   - Skip all remaining steps (no plan, no gates, no review)
   - Proceed to step 13 (final commit)

2. **FAST lane optimization (v4.1):** If task is risk 1-2, ≤3 files, single repo, no sensitive paths, and scope is obvious:
   - Not allowed when the Phase M1 classifier returns `ambiguous_implementation`, `ambiguous_performance`, `unsafe_security`, or `plan_only`.
   - Output 8-field preflight (Repo, Mode, Lane: FAST, Risk score, Autonomy budget, Likely files, Success criteria, Major risks)
   - Edit files directly — PLAN.md optional (skip when scope is crystal clear)
   - Run gates per verification profile
   - Commit with conventional message — current branch only
   - Skip review (not required for FAST)
   - Proceed to step 13 (final commit)

3. **Runs preflight**
   - Reads `<repo>/PLAN.md` to load the Objective, Touch list, and success criteria
   - If PLAN.md is missing: output "No plan found. Run /plan-feature first." and stop
   - If PLAN.md status is `PENDING USER REVIEW`: display the `Objective` and `Touch list`, then prompt inline for `proceed`, `cancel`, or a valid batched approval phrase
     - on approval: update PLAN.md status to `APPROVED` and continue
     - on `cancel`: stop
   - If the repo has planning docs under `docs/` but no active `<repo>/PLAN.md`: refuse execution and state that docs are advisory, while `<repo>/PLAN.md` is the canonical contract
   - If the active PLAN.md mixes UI surface simplification with schema, prompt, validator, or state-contract expansion and does not cite a completed data-path audit: stop and send the plan back to `/plan-feature` for slicing
   - If PLAN.md changes a type/interface/schema/profile contract but the touch list does not explicitly cover constructors, defaults, migrations, helper builders/adapters, and runtime consumers: stop and send the plan back to `/plan-feature` for correction
    - If PLAN.md changes a multi-step form/onboarding/stateful flow but does not explicitly define the active state model (direct write, draft object, reducer/state machine): stop and request plan correction before implementing
    - If PLAN.md is missing lane, risk score, verification profile, autonomy budget, branch strategy, or rollback note for a non-trivial task: stop and return to `/plan-feature`
    - If the rollback note is not structured with Type / Scope / Preconditions / Action / Verify: stop and return to `/plan-feature`
    - If PLAN.md describes net-new feature work, product-facing changes, or ambiguous requests but lacks a Product Brief / PRD-lite section with the required fields: write `<repo>/NOW.md` with `status: blocked` and `blockers: Product Brief missing`, then stop and return to `/analyze` or `/plan-feature`
    - If PLAN.md touches UI, frontend, pages, components, CSS, views, screens, or product-facing copy but lacks a UI Design Brief section with the required fields: write `<repo>/NOW.md` with `status: blocked` and `blockers: UI Design Brief missing`, then stop and return to `/plan-feature`
    - If PLAN.md declares STANDARD/HIGH-RISK or stateful-sensitive work but lacks a QA Plan or explicit compact/N/A rationale: stop and return to `/plan-feature`
    - If PLAN.md touches sensitive paths but lacks a Threat Model: stop and return to `/plan-feature`
    - If PLAN.md makes high-risk architecture/schema/state/cross-surface decisions but lacks an ADR or explicit N/A rationale: stop and return to `/plan-feature`

4. **Applies contract-first synthesis:**
   - Re-state the contract from PLAN.md:
     - Lane: <copy from PLAN.md>
     - Risk score: <copy from PLAN.md>
     - Objective: <copy from PLAN.md>
     - Verification profile: <copy from PLAN.md>
     - Branch strategy: <copy from PLAN.md>
     - Autonomy budget: <copy from PLAN.md>
     - Rollback note: <copy from PLAN.md>
     - Touch list: <copy from PLAN.md>
     - Success criteria: <copy from PLAN.md>
   - Verify contract coherence:
     - Does touch list directly achieve the objective? If not, flag the gap.
     - Are success criteria testable? If not, flag as "needs clarification."
     - Do any files on touch list touch sensitive paths (auth/payment/schema/security/crypto)? Flag for security check.
     - Is runtime authority explicit for the files being changed? If not, flag as "runtime authority unresolved."
     - Is the contract touch list complete for every shape change? If not, flag as "touch list incomplete."
     - Does the branch strategy match the lane? If not, flag as "branch strategy invalid."
     - Are required PRD, Design Brief, QA Plan, Threat Model, and ADR artifacts present or explicitly N/A with reason and risk? If not, flag as "planning artifact incomplete."
     - If artifact strategy is missing, do not invent it during implementation; send the plan back to `/plan-feature`.
   - If any flag is raised: stop and request plan clarification before implementing.

5. **If any file on touch list is in auth / payment / schema / security / crypto path: applies explicit sensitive-path security check**
   - What user input reaches this code? <list>
   - What sensitive data is accessed? <list>
   - What are the trust boundaries? <short description>
   - Activate `security/SKILL.md` (non-optional for sensitive paths)

6. **Design Gate** — before first file edit, verify existing plan artifacts instead of inventing decisions at implementation time. Output gate block with 6 fields:
   - *Product Brief status* — present / N/A with reason / missing BLOCKER
   - *UI Design Brief status* — present / N/A with reason / missing BLOCKER
   - *Architecture decision* — copied from PLAN.md or explicitly N/A; do not create a new architecture direction here
   - *UX states covered* — loading / empty / error / disabled / success from PLAN.md; each designed or N/A with reason
   - *API / interface contract* — request shape, response shape, error format; or N/A
   - *Observability design* — what gets logged, what metric matters, what breaks silently
   - FAST lane: one-liner per item.
   - HIGH-RISK: record architecture decision in PLAN.md under `Design Decision:` field before proceeding.
   - **BLOCK**: if a required Product Brief or UI Design Brief is missing, write `<repo>/NOW.md` with `status: blocked` and `blockers: Design Gate — [reason]`, then stop. Resume with `/implement` only after the PLAN.md artifact is corrected.

7. **Checks task domain and activates the matching skill from `.opencode/skills/`**
   - If no domain matches: proceed without skill activation.
   - **Skill Activation Table:**

| Task domain | Skill file |
|---|---|
| UI / component / page / frontend | `ui-ux-pro-max/SKILL.md` |
| Visual direction / landing page / motion-heavy frontend | `frontend-design/SKILL.md` |
| Rust (example-cli) | `rust/SKILL.md` |
| Tests / specs / TDD | `testing-validation/SKILL.md` |
| Browser verification / UI flows | `webapp-testing/SKILL.md` |
 | Material UI visual change with baseline/reference available | `visual-regression/SKILL.md` |
| UI tokens / component reuse / design-system drift | `design-system-governance/SKILL.md` |
 | Animation, transition, gesture feedback, loading skeletons, page transitions, onboarding entrances, hover/focus effects, micro-interactions | `motion-design/SKILL.md` |
 | iOS / Android / Capacitor / React Native / mobile web targeting | `platform-guidelines-compliance/SKILL.md` |
 | Hero sections, onboarding, empty states, icons, illustrations, brand graphics | `illustration-graphic-direction/SKILL.md` |
 | Material visual changes (landing page, onboarding, dashboard, hero) needing before/after critique | `visual-iteration-loop/SKILL.md` |
 | Schema / Prisma / Drizzle / database work | `database/SKILL.md` |
| API/client/server contract changes | `api-contract-validation/SKILL.md` |
| Deploy/runtime/environment/CI changes | `infra-validation/SKILL.md` |
| Sensitive trust-boundary work | `threat-modeling/SKILL.md` |
| Dependency changes | `dependency-hygiene/SKILL.md` |
| Security / auth / crypto-sensitive code | `security/SKILL.md` |
| Refactor / structural cleanup | `technical-debt-prevention/SKILL.md` |
| Debugging / root-cause analysis | `systematic-debugging/SKILL.md` |
| Accessibility audit | `accessibility-audit/SKILL.md` |
| Error handling / resilience | `error-handling/SKILL.md` |
| Next.js App Router / routes / config | `nextjs/SKILL.md` |
| Observability / logging / metrics | `observability/SKILL.md` |
| Testing patterns / test infrastructure | `testing/SKILL.md` |
| Safe refactoring / extraction | `refactor-clean/SKILL.md` |

8. **Path-based auto-activation** — Before the first file edit:
   - If any touch-list file matches test patterns (`*.test.*`, `*.spec.*`, `tests/`, `e2e/`, `__tests__/`):
     - Read `.opencode/rules/testing.md`
     - Announce: `[Auto-activated rules: testing]`
   - If any touch-list file matches UI patterns (`*.tsx`, `*.css`, `components/`, `pages/`, `views/`, `screens/`, `app/`):
     - Read `.opencode/rules/ui-work.md`
     - Announce: `[Auto-activated rules: ui-work]`
   - If both match: announce both rules.

9. **Implements only the files on the touch list in PLAN.md**
   - If one new required file is discovered, use the `TOUCH LIST EXPANSION` policy below before editing it.

  10. **Multi-Repo Execution (v4.0)** — If PLAN.md declares `Cross-repo dependencies` with 2+ repos, see `.opencode/docs/commands/implement-runbook.md` for the full multi-repo execution procedure.

11. **Runs quality gates using the plan's verification profile; if no profile is declared, default to the full sequence: lint -> typecheck -> test -> build**
    - Classify every non-pass or skipped gate as `TARGETED_FAILURE`, `BROAD_BASELINE_FAILURE`, `FLAKY_OR_INFRA_FAILURE`, `NOT_RUN`, `ACCEPTED_NON_BLOCKING`, or `BLOCKING_UNKNOWN`.
    - `TARGETED_FAILURE` blocks commit until fixed.
    - `BROAD_BASELINE_FAILURE` may validate protocol-only work when documented, but blocks product-code commit unless the owner explicitly accepts the risk.
    - `FLAKY_OR_INFRA_FAILURE` requires exactly one retry and evidence from both attempts before proceeding.
    - `ACCEPTED_NON_BLOCKING` requires explicit owner approval; cite that approval in the completion summary.
    - `BLOCKING_UNKNOWN` is the default when unclear and blocks commit.
    - Run `api-contract-validation/SKILL.md` checks when API/client/server contracts changed.
    - Run `infra-validation/SKILL.md` checks when runtime/deploy/env/CI changed.

12. **If the active repo has a dev port in `WORKSPACE_MAP.md` AND the touch list includes UI files or paths under `app/`, `components/`, `pages/`, or `views/`: run mandatory browser verification before commit and before the final summary:**
    - Activate `webapp-testing/SKILL.md`
    - Run or document browser route preflight first: Playwright MCP state, Python Playwright state, required browser binary state, agent-browser state when configured, and selected route.
    - If Playwright MCP is enabled in `.opencode/opencode.json`, use it as the primary browser route.
    - If Playwright MCP is disabled or unavailable, use the canonical fallback: Python Playwright via `webapp-testing/SKILL.md` or `agent-browser` when that CLI is more reliable for the task.
    - Start the repo's dev server if needed
    - Open the changed page on the repo's dev URL from `WORKSPACE_MAP.md`
    - Verify the page loads
    - Capture a screenshot
    - Surface console-error status if available
    - Report browser evidence as structured fields, not free text:
      - `dev_url`: <URL opened>
      - `screenshot_path`: <absolute or repo-relative path>
      - `viewport`: <width>x<height>
      - `console_errors`: <none / list / unavailable with reason>
      - `accessibility_result`: <pass / fail / not run with reason>
      - `performance_result`: <pass / fail / not run with reason>
      - `command_used`: <exact command or tool route>
      - `timestamp`: <ISO timestamp>
      - `known_visual_risks`: <none / concise list>
    - If required browser evidence cannot be completed or lacks `dev_url`, `screenshot_path`, `viewport`, `console_errors`, `command_used`, and `timestamp`: do NOT claim completion.
    - For material visual-surface changes, activate `visual-regression/SKILL.md` when a baseline/reference exists or a comparison is part of PLAN.md; otherwise record `NOT_RUN` with reason, risk, and missing confidence.

  12b-12j. **UI/UX Quality Audits (v4.9.0–v4.9.2)** — if touch list includes UI files, see `.opencode/docs/commands/implement-runbook.md` for:
       - UI/UX Quality Audit (12b)
       - Accessibility Audit (12c)
       - Responsive/State Audit (12d)
       - Visual Regression (12e)
       - Motion Design (12f)
       - Platform Guidelines Compliance (12h)
       - Illustration/Graphic Direction (12i)
       - Visual Iteration Loop (12j)
       - Performance / Lighthouse (12g)
       Each audit has severity ratings. Critical findings stop and return to plan correction.

 13. **Completion Summary (required before /checkpoint)**
    - What was built: <one paragraph — what the user can now do, not what code was written>
    - Verification profile: <profile used and why>
    - Gate classifications: <classification for every non-pass or skipped gate, with blocking status and evidence>
    - Browser route preflight: <Playwright MCP / Python Playwright / browser binary / agent-browser / selected route or Not required — reason>
    - Browser verification: <structured browser evidence block for qualifying web UI changes; otherwise "Not required — <reason>">
    - Dirty workspace inventory: <OpenCode protocol files / vault protocol-eval files / product-code files / unrelated pre-existing changes / unknown-risky changes>
    - Manual verification: <2–3 steps the user can take to confirm it works>
    - Models/helpers used: <agent/model/reason; token/cost/latency if exposed; cheaper route sufficient? yes/no/unknown>
    - Rollback note: <what to revert or disable if this slice misbehaves>
      - Type: <rollback type>
      - Scope: <exact rollback scope>
      - Preconditions: <what must be true first>
      - Action: <exact command or operator action>
      - Verify: <how rollback success is confirmed>
    - Deviations from plan: <files not on touch list that were changed, with reason; or "None">
    - Unresolved risks: <none or concise list>
    - Proof of Done: follow `.opencode/templates/PROOF_OF_DONE.md` shape when applicable; cite PRD, Design Brief, QA Plan, Threat Model, ADR, browser evidence, and gate classifications as present / N/A with reason.

 14. **Traceability Verification** — after gates pass and before /checkpoint, verify implementation matches PLAN.md. See `.opencode/docs/commands/implement-runbook.md` for the full traceability procedure.

15. **Runs `/checkpoint` local-persistence steps (file mutations only — no commit yet):**
    - Update `<repo>/NOW.md`
    - archive `<repo>/PLAN.md` to `vault/projects/<repo>/archived-plans/`
    - Vault is non-authoritative; repo-local commit proceeds regardless.
    - These file changes are staged for the final commit in step 17.

16. **If reviewer is required (risk 4+, touch list 4+ files, or any file is in an auth / payment / schema / security / crypto path):**
    - Spawn Reviewer helper before the final commit
    - Reviewer output is required before commit.
    - If Reviewer flags issues: stop and return to planning or fix before committing.

17. **Final local task commit only after gates pass, browser verification, Completion Summary, Traceability, /checkpoint file mutations, and Reviewer (if required):**
    - GitGuard: use `.opencode/git-guard/git-guard.sh` wrapper for all mutating git operations
    - The wrapper blocks: --no-verify, --force, -f, direct main/master push, HEAD:main, reset --hard, clean -fd
    - See `.opencode/git-guard/git-guard.md` for the full enforcement contract.
    - Working tree is clean after commit — no uncommitted changes.

18. **Proceed to next slice** if PLAN.md has remaining slices; otherwise:
    - Update `<repo>/NOW.md` with final status
    - Suggest `/ship` if the repo has a deploy target in `WORKSPACE_MAP.md`

# Typical sequence:
# See .opencode/docs/commands/implement-runbook.md for typical gate sequence.

## Touch-List Expansion Policy

See `.opencode/docs/commands/implement-runbook.md` for the full touch-list expansion policy and verification profile selection table.

## Do not

- Edit files not on the touch list.
- Skip quality gates.
- Commit without gates passing.
- Start a second feature during the same session.
- Continue with a mixed-scope plan that should have been split by `/plan-feature`.
- Reference retired skill locations, hidden orchestration commands, or dead absolute paths.
- Execute from docs-only planning artifacts when `<repo>/PLAN.md` is the canonical contract.
