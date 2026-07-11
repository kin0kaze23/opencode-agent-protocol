---
description: "Run validation gates and classify results before shipping"
---

# /gates

**Purpose:** Formal pass/fail validation for the active repo
**Mode:** Executor
**Model:** qwen3-coder-plus
**Tool access:** Layer A
**Success output:** All gates pass, or specific failures listed with exit codes

## v4.17.0 Throughput Optimization (active)

Before running gates, the Owner agent applies these v4.17.0 optimizations:

### Session Gate Cache
1. Run `bash .opencode/scripts/session-cache.sh gate-skip <gate_name> "checking cache"` for each gate
2. If output starts with `CACHED`: skip the gate, report `CACHED (source unchanged since <timestamp>)`
3. If output is `NOT_CACHED` or `STALE`: run the gate normally
4. After each gate runs: `bash .opencode/scripts/session-cache.sh gate-set <gate_name> <pass|fail> <exit_code>`
5. **Always re-run** (never skip): first invocation per session, after git operations, release lane, auth/security/RLS changes

### Diff-Aware Gate Selection
1. Run `bash .opencode/scripts/diff-analyze.sh <repo_path>` to classify the change
2. Read `DIFF_CLASSIFICATION` and `RECOMMENDED_GATES` from output
3. Read `SKIP_GATES` from output (if present)
4. Skip gates listed in `SKIP_GATES` with classification `NOT_RUN` and reason from `REASON` field
5. Run only gates in `RECOMMENDED_GATES`
6. **Override**: if verification profile is `stateful-sensitive` or lane is HIGH-RISK, run full suite regardless of diff classification

### Parallel Gate Execution
When running multiple independent gates, execute them in parallel phases:

**Phase 1 (parallel):** lint + typecheck + unit tests
```bash
pnpm lint & pnpm typecheck & pnpm test & wait
```

**Phase 2 (after typecheck):** build
```bash
pnpm build
```

**Phase 3 (parallel, after build, if UI):** a11y + visual screenshots + console clean
```bash
# Run independent UI checks in parallel
```

**Phase 4 (parallel):** reviewer + deploy preview (when applicable)

**Never parallelize:** dependent operations, shared-state mutations, gates that modify the same files

## Behaviour

When invoked, the Owner agent:

1. Reads the active repo's AGENTS.md for the exact gate commands
2. Reads the active plan's verification profile when one exists
3. **Gate script validation (v4.0):** For each gate script in package.json:
   - If script starts with `echo` or is a no-op: mark as PLACEHOLDER — warn "Gate [name] uses echo-only script — no real verification"
   - If no script defined for this gate: mark as SKIPPED — note "Gate [name] not configured"
   - If real tooling present (eslint, tsc, vitest, etc.): proceed normally — will report as VERIFIED
3b. **Deployment gate check (v4.1):** If task includes deployment:
   - Verify deployment CLI is available (`vercel`, `wrangler`, `gh`, `docker`)
   - If not available: report "Deployment CLI not installed — install before deploying"
   - Verify environment variables are configured (check for `.env` or platform config)
   - If missing: report "Environment variables not configured — set up before deploying"
4. Determines whether scoped SAST is mandatory for this task:
   - Require SAST when the verification profile is `stateful-sensitive` AND any of these are true:
     - auth, payment, schema, security, crypto, or user-data paths are touched
     - dependency manifests or lockfiles changed
     - exposed API handlers or request validators changed
   - If mandatory, SAST is part of the gate set and is blocking
5. Runs the smallest sufficient gate set for that profile, preserving order:
   - `direct` -> lint only
   - `docs-config` -> lint -> targeted sanity check -> build only if runtime config changed
    - `ui-surface` -> lint -> typecheck -> build -> browser verification -> UI/UX Quality Audit -> Accessibility Audit -> Responsive/State Audit -> Visual Regression (if triggered) -> Lighthouse (advisory) -> targeted UI smoke
   - `logic-backend` -> lint -> typecheck -> targeted tests -> build only if packaging/runtime changed
   - `stateful-sensitive` -> lint -> typecheck -> full test -> build -> scoped SAST when required
   - `hotfix` -> reproduce failing case -> targeted test -> regression check
   - If no profile exists: lint -> typecheck -> test -> build
5a. **Risk-based specialist gate mapping (v4.7.0 active baseline):** Add these gates only when their trigger applies:
    - Visual regression: required when a baseline/reference exists or a material visual surface changed; otherwise advisory or `NOT_RUN` with reason, risk, and missing confidence. It is not mandatory for every tiny UI change.
    - Accessibility: required for customer-facing UI changes; advisory for internal-only UI unless the risk profile requires it.
    - Lighthouse/performance: advisory by default; required for performance-focused work or public-page performance changes.
    - API contract validation: required when API routes/handlers, client fetchers/hooks, validators, generated types, API docs/tests, request/response/error formats, auth/permission behavior, or compatibility contracts changed; mark internal-only backend edits `N/A` with reason/risk when no boundary is affected.
    - Infra validation: required when deploy, runtime config, CI, environment variables, secrets handling, health checks, Docker, or rollback configuration changed. Secret evidence must use variable names only; never print/log/paste/commit values or stage `.env`, `.env.doppler`, credentials, or token-bearing files without explicit owner approval.
    - Threat modeling: required for sensitive HIGH-RISK paths including auth, payment, schema, security, crypto, and user-data trust boundaries.
    - ADR presence: required for high-risk architecture, state, schema, runtime-authority, or cross-surface decisions.
     - QA Plan: required for STANDARD/HIGH-RISK; DIRECT/FAST may use compact/N/A rationale with reason and risk.
 5a.1. **v4.9.0 UI/UX gate extensions for `ui-surface` profile:**
     - UI/UX Quality Audit: activate `ui-ux-quality-audit/SKILL.md` for all UI surface changes
     - Accessibility Audit: activate `accessibility-audit/SKILL.md` for all UI surface changes
     - Responsive/State Audit: activate `responsive-state-audit/SKILL.md` for all UI surface changes
     - Visual Regression: per `visual-regression/SKILL.md` — required for major UI surface, design-system change, layout change, landing page, dashboard, onboarding; advisory for minor style tweak; NOT_RUN for text-only/no UI changes
     - Lighthouse/Core Web Vitals: per `performance/SKILL.md` — advisory only in v4.9.0
 5a.2. **UI/UX blocking rules:**
     - Critical UI/UX findings → BLOCK
     - Critical/High accessibility findings → BLOCK
     - Responsive breakage at any breakpoint → BLOCK
     - Unresolved required visual regression issue → BLOCK or MANUAL_REVIEW
     - Console errors on UI surface → BLOCK unless explicitly accepted
     - Critical design-research mismatch (UI contradicts approved Design Intelligence Brief) → BLOCK
     - Motion that harms accessibility (flashing, no reduced-motion, motion required to understand) → BLOCK
     - Major visual polish failures → BLOCK as Critical/High UI/UX findings
     - Lighthouse failure → ADVISORY in v4.9.0 (not blocking)
  5a.3. **UI/UX NOT_RUN rules (do not block):**
      - Accessibility audit NOT_RUN (dependencies missing) → pass with warning and setup proposal
      - Visual regression NOT_RUN (no UI change) → pass
      - Lighthouse NOT_RUN (tool unavailable) → pass with warning
  5a.4. **v4.9.2 Visual Craft + Platform Polish gate extensions:**
      - Platform Guidelines Compliance: activate `platform-guidelines-compliance/SKILL.md` for platform-sensitive UI
      - Illustration/Graphic Direction: activate `illustration-graphic-direction/SKILL.md` for brand-sensitive surfaces
      - Visual Iteration Loop: activate `visual-iteration-loop/SKILL.md` for material visual changes
  5a.5. **v4.9.2 Additional blocking rules:**
      - Safe-area violation (content obscured by notch/home indicator) → BLOCK
      - Platform touch-target violation (below 24×24 CSS px WCAG minimum) → BLOCK
      - Navigation pattern contradicts platform expectation without justification → BLOCK
      - Generic/cliché graphics on brand-sensitive surface → BLOCK as High/Critical UI/UX finding
      - Illustration/graphic inconsistency with design tokens or brand direction → BLOCK for brand-sensitive surface
      - Missing visual iteration evidence for material visual changes → BLOCK
      - Aesthetic polish that harms usability → BLOCK
  5a.6. **v4.9.2 Additional NOT_RUN rules (do not block):**
      - Platform compliance NOT_RUN (desktop-only web app) → pass with reason
      - Illustration/graphic NOT_RUN (no graphics needed) → pass with reason
      - Visual iteration NOT_RUN (no material visual change) → pass with reason
5b. **Browser route preflight for UI-surface work:** Before accepting browser evidence, document the browser route preflight:
    - Playwright MCP state: enabled / disabled / unavailable.
    - Python Playwright state: usable / unavailable, with error summary if unavailable.
    - Required browser binary state: installed / missing / unknown.
    - agent-browser state when configured: usable / revision mismatch / unavailable.
    - Selected route: Playwright MCP when enabled and healthy; otherwise Python Playwright; otherwise agent-browser if usable; otherwise `NOT_RUN` with reason and risk.
    - Do not force-enable Playwright MCP or install browser dependencies during `/gates` without explicit owner approval.
5c. **Structured browser evidence check for UI-surface work:** If the verification profile is `ui-surface` or the touch list includes UI/frontend paths, verify the completion evidence includes these machine-checkable fields before accepting browser verification as complete:
    - `dev_url`
    - `screenshot_path`
    - `viewport`
    - `console_errors`
    - `accessibility_result` (may be `not run` with reason)
    - `performance_result` (may be `not run` with reason)
    - `command_used`
    - `timestamp`
    - `known_visual_risks`
    - If any required field is missing, mark browser verification as FAIL even if free-text says it passed.
6. **Gate diagnosis (v4.1):** When a gate fails, diagnose root cause before reporting:
   - Exit code 127 ("command not found"): check if tool is in package.json devDependencies
     - If yes but not installed: "Tool [name] is in devDependencies but node_modules not populated. Run `npm install` or `pnpm install` first."
     - If not in package.json: "Tool [name] is not installed or declared in dependencies."
   - Exit code 1 (tool ran, found issues): report actual errors from tool output
   - If tool ran from global binary (not local node_modules): note "Tool ran globally, not from repo's node_modules — verify local install for CI"
7. **Failure classification (v4.6.1):** If any gate fails, is skipped, or is not run, assign exactly one of these classifications and include evidence:
   - `TARGETED_FAILURE`: the changed area, touched path, or declared success criterion failed; blocks commit and ship.
   - `BROAD_BASELINE_FAILURE`: unrelated pre-existing broad-suite failure; may validate protocol-only work when documented, but blocks product-code commit unless the owner explicitly accepts the risk.
   - `FLAKY_OR_INFRA_FAILURE`: network timeout, service outage, ECONNREFUSED, port conflict, browser revision mismatch, temp file lock, or test that passes on retry; retry exactly once, then document both attempts, commands, exit codes, and evidence.
   - `NOT_RUN`: gate was skipped or unavailable; include reason, risk, and missing confidence.
   - `ACCEPTED_NON_BLOCKING`: only after explicit owner approval; cite the approval.
   - `BLOCKING_UNKNOWN`: default when the failure cannot be confidently classified; blocks commit and ship.
8. Stops at the first `TARGETED_FAILURE` or `BLOCKING_UNKNOWN` and reports it. For `FLAKY_OR_INFRA_FAILURE`, perform the single required retry before final classification.
9. If all pass: outputs "All gates PASS" with verification quality per gate:
    - Each gate reports: VERIFIED (real tooling), PLACEHOLDER (echo-only), or SKIPPED (not configured)
10. If any fail: outputs the failed gate, exit code, root-cause diagnosis, and v4.6.1 failure classification.

## Difference from /review

/gates = formal pass/fail validation (runs commands, checks exit codes)
/review = qualitative critique (reads code, applies judgement)

## Verification profile rule

If a plan declares a verification profile, `/gates` must respect it.
If the work expanded beyond the planned scope, fall back to the full suite.
If scoped SAST is mandatory for the current work, `/gates` may not skip it.

## Output format

```
Gates: <repo>
Profile: <verification profile or full>

<gate-name>: PASS / FAIL (exit <code>)
<gate-name>: PASS / FAIL (exit <code>)
<gate-name>: PASS / FAIL (exit <code>)

Classifications:
- <gate-name>: <TARGETED_FAILURE|BROAD_BASELINE_FAILURE|FLAKY_OR_INFRA_FAILURE|NOT_RUN|ACCEPTED_NON_BLOCKING|BLOCKING_UNKNOWN> — <evidence and blocking status>

Browser route preflight: <Playwright MCP / Python Playwright / browser binary / agent-browser / selected route or Not required>

Specialist gates: <visual regression / accessibility / performance / API contract / infra / threat model / ADR / QA Plan statuses, each PASS / FAIL / NOT_RUN with reason>

Result: ALL PASS / FAILED at <gate>
First error: <error line if failed>
```

## Gate failure escalation

If a gate fails and the attempted fix also fails (two failures, same gate):
1. Stop. Do not attempt a third fix independently.
2. Output: "Gate [name] failed twice. Running /postmortem before continuing."
3. Run /postmortem inline: identify root cause, assign a concise root-cause fingerprint, record fix, state prevention rule.
4. Append the lesson to `vault/projects/<repo>/lessons.md`.
5. Only then attempt the fix documented in the postmortem.

If the documented recovery fails again with the same root-cause fingerprint:
1. Trigger the circuit breaker immediately
2. Stop implementation and do not attempt another independent fix
3. Output that the same root cause recurred after postmortem-guided recovery
4. Escalate to `/debug`, `/plan-feature`, or the user with the fingerprint and current evidence
5. Treat this as a diagnosis failure, not a retry candidate

If the lane autonomy budget is exhausted before a fix is proven:
1. Stop and summarize current evidence
2. State whether the issue should move to `/debug`, `/plan-feature`, or user escalation
3. Do not continue with unbounded retries

Rationale: Two failures on the same gate with different approaches signals
wrong-level diagnosis, not unlucky execution. Capture the lesson first.
