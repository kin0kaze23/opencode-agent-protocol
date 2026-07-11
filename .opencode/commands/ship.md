---
description: "Prepare a release with gates, evidence, rollback, and ship/no-ship decision"
---

# /ship

**Mode:** Reviewer -> Executor
**Model:** qwen3.7-plus (v1.1-production, Action 4D)
**Tool access:** Layer A + Layer B (git, GitHub CLI)
**Success output:** Gates pass + changelog entry + PR created or merge confirmed

## Behaviour

When invoked, the Owner agent:

1. Runs preflight - confirms repo and branch
1b. Runs GitGuard doctor check for the active repo:
    - Verifies pre-push hook is installed and matches canonical source
    - Verifies git-guard.sh wrapper is present
    - Verifies NOW.md exists and is coherent
    - If any FAIL: output warning and ask user whether to proceed
    - If only WARN: proceed but include warning in ship summary
1c. **Ship-domain skill activation:**
    - If the repo deploys to Vercel or similar: activate `deployment/SKILL.md`
    - If the repo uses Docker containers: activate `docker/SKILL.md`
    - If ship scope touches deploy/runtime/CI/environment variables/secrets/health/rollback: activate `infra-validation/SKILL.md`; secret evidence must name variables only and must never print, log, paste, or commit values or stage `.env`, `.env.doppler`, credentials, or token-bearing files without explicit owner approval.
2. Runs /gates sequence (lint -> typecheck -> test -> build)
   **v4.17.0 Session Gate Cache:** Before re-running gates, check the session cache:
   - Run `bash .opencode/scripts/session-cache.sh gate-skip lint "ship gate cache check"` for each gate
   - If output starts with `CACHED`: skip the gate, report `CACHED (source unchanged since <timestamp>)`
   - If output is `NOT_CACHED` or `STALE`: run the gate normally
   - **Always re-run for release lane**: if this is a production release, run full suite regardless of cache
   - **Always re-run after git operations**: if any git operation occurred since gates last ran, invalidate cache first:
     `bash .opencode/scripts/session-cache.sh invalidate "git operation before ship"`
3. If gates fail, are skipped, or are not run: classify each non-pass as `TARGETED_FAILURE`, `BROAD_BASELINE_FAILURE`, `FLAKY_OR_INFRA_FAILURE`, `NOT_RUN`, `ACCEPTED_NON_BLOCKING`, or `BLOCKING_UNKNOWN`.
   - `TARGETED_FAILURE` blocks shipping.
   - `BROAD_BASELINE_FAILURE` blocks product-code shipping unless the owner explicitly accepts the risk; protocol-only shipping may proceed only when the unrelated baseline evidence is documented.
   - `FLAKY_OR_INFRA_FAILURE` requires exactly one retry and evidence from both attempts before shipping can continue.
   - `ACCEPTED_NON_BLOCKING` requires explicit owner approval and must be cited in the ship summary.
   - `BLOCKING_UNKNOWN` blocks shipping.
   - `NOT_RUN` must include reason, risk, and missing confidence; it blocks shipping unless explicitly accepted by the owner.
4. If gates pass: inspects the current ship scope from the working diff and the
   branch's unmerged changes
5. Applies the same Reviewer rule used by `/implement` to that current scope:
   - Reviewer is required if risk score is 4 or more
   - Reviewer is required if the ship scope touches 4 or more files
   - Reviewer is required if any touched file is in an auth / payment / schema /
     security / crypto path
6. If Reviewer is required:
   - Run `/review` inline on the current ship scope before PR creation
   - Do NOT create a PR until review returns no Critical findings and does not
     end in "Requires changes"
6b. **UI/UX Quality Gate (v4.9.0) — for scopes with UI changes:**
    - Check for unresolved Critical UI/UX Quality Audit findings
    - Check for unresolved Critical/High Accessibility Audit findings
    - Check for unresolved responsive breakage
    - Check for unresolved visual regression issues
    - Check for unresolved console errors on UI surfaces
    - If any unresolved Critical finding: block ship and report
 6c. **v4.9.1 Motion and Design Research Gate — for scopes with UI changes:**
     - Check for unresolved Critical design direction mismatch (UI contradicts approved Design Intelligence Brief)
     - Check for unresolved Critical visual polish issues (optical balance, rhythm, CTA prominence, alignment)
     - Check for accessibility-harming motion (flashing, strobing, no reduced-motion support)
     - Check for motion-only comprehension (information only conveyed through motion)
     - If any unresolved Critical finding: block ship and report
 6d. **v4.9.2 Visual Craft + Platform Polish Gate — for scopes with UI changes:**
     - Check for unresolved Critical platform compliance issue (safe-area violation, touch-target below minimum)
     - Check for unresolved Critical graphic/illustration mismatch (generic AI graphics, brand direction contradiction)
     - Check for missing visual iteration evidence on material visual surfaces
     - Check for visual changes that reduce usability (aesthetic-usability effect violation)
     - If any unresolved Critical finding: block ship and report
7. Runs GitGuard check — use `.opencode/git-guard/git-guard.sh` wrapper for all
   mutating git operations. Blocks: force push, direct main/master push,
   --no-verify commits, HEAD:main/master refspecs, reset --hard, clean -fd
8. Checks for uncommitted changes and reports dirty workspace inventory grouped as OpenCode protocol files, vault protocol/eval files, product-code files, unrelated pre-existing changes, and unknown/risky changes
9. Reads recent commits to draft a changelog entry
10. Requires a structured rollback note in the ship summary:
    - Type
    - Scope
    - Preconditions
    - Action
    - Verify
10b. **Proof of Done / release-evidence check:** Require `.opencode/templates/PROOF_OF_DONE.md`-shaped evidence where applicable:
    - PRD / Product Brief acceptance criteria status
    - Design Brief, browser, accessibility, and visual-regression evidence for UI changes
    - QA Plan and v4.6.1 gate classifications
    - Threat Model / ADR evidence when sensitive or architectural scope applies
    - Deploy, rollback, health, and infra-validation proof only for deploy/runtime scopes
10c. Owner approval is mandatory before shipping with `ACCEPTED_NON_BLOCKING` failures, skipped high-confidence gates, or high-risk release exceptions; cite that approval in the ship summary.
11. Creates a PR (via `gh pr create`) or confirms direct merge for hotfix branches
12. Checks NOW.md for active/blocked state — if active work is pending, outputs
    a PENDING WORK WARNING (see Session-End Checkpoint in rules.md)
13. Outputs a one-paragraph handoff summary with PR URL, rollback note, branch/worktree lifecycle next step, and next steps
14. **Deployment automation (v4.1+):** If the repo has a deployment platform configured:
    - For Vercel repos: suggest `/deploy-preview` for PR review, then `/deploy-vercel --prod` after merge
    - For Cloudflare Workers repos: suggest `/deploy-workers` after merge
    - For Docker repos: suggest deployment via `docker compose up -d`
    - Include deployment instructions in handoff summary

## Ship is NOT the same as /deploy-vercel or /deploy-workers

/ship = release readiness + PR creation + handoff
/deploy-vercel = actual Vercel deployment (run after PR merges)
/deploy-workers = actual Wrangler deployment (run after PR merges)

## Approval boundary

`Approved, continue end to end` for a local task does NOT authorize `/ship`.
Because `/ship` creates remote side effects such as PR creation, it still
requires separate user approval before execution.

## Branch rule

- Non-hotfix work should ship from an isolated feature or fix branch
- Hotfix branches should use `hotfix/<repo>/<task-slug>`
- Direct merge is reserved for hotfix branches with explicit approval and a rollback note

## Ship summary

The ship summary must include:

- PR URL or merge confirmation
- Gate classifications for every non-pass or skipped gate
- Proof of Done evidence summary, including applicable PRD / Design Brief / QA Plan / Threat Model / ADR statuses or `N/A` with reason
- Infra-validation, deploy/rollback/health proof only when deploy/runtime scope is present
- Dirty workspace inventory and whether any remaining dirty files are unrelated pre-existing changes or blockers
- Rollback note:
  - Type
  - Scope
  - Preconditions
  - Action
  - Verify
- Branch/worktree lifecycle next step:
  - keep active
  - archive
  - delete after merge
- Immediate next steps

## Do not
- Deploy to production directly (that is /deploy-vercel or /deploy-workers)
- Skip gates
- Skip Reviewer when the current ship scope meets the `/implement` Reviewer rule
- Ship without a PR on non-hotfix branches
- Ship without running GitGuard check
- Ship when NOW.md shows active/blocked work without outputting PENDING WORK WARNING
