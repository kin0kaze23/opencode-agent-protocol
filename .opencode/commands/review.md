---
description: "Independent code review with skill activation and risk report"
---

# /review

**Mode:** Reviewer
**Model:** opencode-go/glm-5.1
**Tool access:** Layer A (read-only)
**Success output:** Risk report with severity ratings, evidence tags, governing-contract references, and specific recommendations

## Skill Activation (run before reviewing)

| Task domain | Skill file |
|---|---|
| UI / component / page / frontend | `ui-ux-pro-max/SKILL.md` |
| Visual direction / landing page / motion-heavy frontend | `frontend-design/SKILL.md` |
| Visual regression / browser verification | `webapp-testing/SKILL.md` + `visual-regression/SKILL.md` when baseline/reference exists or visual surface materially changed |
| UI/UX quality review | `ui-ux-quality-audit/SKILL.md` |
| Accessibility audit | `accessibility-audit/SKILL.md` |
| Responsive/state audit | `responsive-state-audit/SKILL.md` |
| Platform compliance (iOS/Android/Capacitor) | `platform-guidelines-compliance/SKILL.md` |
| Illustration/graphic direction | `illustration-graphic-direction/SKILL.md` |
| Visual iteration / before-after critique | `visual-iteration-loop/SKILL.md` |
| UI tokens / component reuse / design-system drift | `design-system-governance/SKILL.md` |
| Rust (example-cli) | `rust/SKILL.md` |
| Tests / specs / TDD review | `testing-validation/SKILL.md` |
| Schema / Prisma / Drizzle / database work | `database/SKILL.md` |
| API/client/server contract review | `api-contract-validation/SKILL.md` when API routes, client fetchers, request/response/error/auth shapes, generated types, docs, or tests affect a boundary |
| Deploy/runtime/environment/CI readiness | `infra-validation/SKILL.md` |
| Security / auth / crypto | `security/SKILL.md` |
| Sensitive trust-boundary review | `threat-modeling/SKILL.md` |
| Dependency changes | `dependency-hygiene/SKILL.md` |
| Refactor / structural cleanup review | `technical-debt-prevention/SKILL.md` |
| Debugging-heavy regression review | `systematic-debugging/SKILL.md` |
| Accessibility audit | `accessibility-audit/SKILL.md` |
| Systematic code review checklist | `code-review-checklist/SKILL.md` |
| Performance optimization review | `performance/SKILL.md` |
| Technical debt assessment | `technical-debt-assessment/SKILL.md` |

If no domain matches: proceed without skill activation.

## Subject containers (read for cross-repo context)

Before reviewing, check if any vault subject containers apply:
- Security / auth / crypto → read `vault/subjects/Security.md`
- Architecture scope → read `vault/subjects/Architecture.md`
- TypeScript patterns → read `vault/subjects/TypeScript.md`
- Testing approach → read `vault/subjects/Testing.md`

Only read if clearly applicable. Skip if no match.

## Behaviour

When invoked, the Owner agent:

1. Runs preflight
2. Identifies scope - recent diff, specific files, full feature, or release-readiness audit
   - Use this GLM reviewer path only when risk score is 4+, sensitive paths are touched, auth/security/payment/data/secrets changed, 4+ files changed, release/ship gates are in scope, implementation quality is unclear, or the Owner explicitly requests review.
   - For low-risk DIRECT/FAST work, prefer sampled review or Budget review first unless a trigger above applies.
3. Identifies the governing contract for the review:
   - repo `AGENTS.md`
   - active spec / implementation contract
   - PLAN.md Product Brief / PRD-lite, UI Design Brief, QA Plan, Threat Model, ADR, and Proof of Done where applicable
   - explicit release or acceptance criteria
4. Reviews for: correctness, security risks, regressions, edge cases, architectural fit
4a. **Product/UI review pass for product-facing or UI changes:** If the scope touches user-facing behavior, pages, components, CSS, views, screens, product copy, or frontend interaction, review all of the following against PLAN.md Product Brief / UI Design Brief and the actual diff:
   - product intent alignment: output solves the stated user problem and target user context
   - visual hierarchy: primary action and important information are most prominent
   - spacing and alignment: layout feels intentional and consistent with the product
   - typography: scale, weight, rhythm, and readability fit the design-system source
   - color/contrast: palette is consistent and contrast is sufficient
   - interaction design: hover, focus, disabled, transitions, and motion are purposeful
   - responsive behavior: mobile, tablet, desktop, and wide targets are addressed or explicitly out of scope
   - UI states: loading, empty, error, disabled, and success states exist or are N/A with reason
   - accessibility: keyboard/focus/labels/semantics/reduced-motion risks are checked
   - copy quality: language is clear, product-appropriate, and not placeholder/generic
   - visual evidence: structured browser evidence includes dev URL, screenshot path, viewport, console status, command used, timestamp, and known risks
   - browser route preflight: Playwright MCP state, Python Playwright state, browser binary state, agent-browser state, and selected route are documented before visual evidence is accepted
   - design-system governance: tokens/components/responsive states match the named design-system source or deviations are justified
   - visual-regression evidence: baseline/reference comparison is reviewed for material UI changes when available; otherwise `NOT_RUN` reason and risk are reviewed
   - product polish: flag if the output looks generic, unpolished, or inconsistent with the product's existing visual language
4b. **Specialist artifact review pass:** Review against applicable v4.7.0 active-baseline artifacts using trigger-based scope:
   - PRD / Product Brief: acceptance criteria, non-goals, edge cases, and kill criteria match the diff.
   - Design Brief: visual hierarchy, states, accessibility plan, and copy tone are implemented or explicitly out of scope.
   - QA Plan: gate set, edge cases, and v4.6.1 failure classifications are evidenced.
   - Threat Model: sensitive assets, actors, trust boundaries, mitigations, and residual owner are addressed.
   - ADR: implemented architecture/state/schema/cross-surface decision matches the recorded decision and consequences.
   - Proof of Done: evidence is machine-checkable and does not overclaim.
4c. **Security hardening pass for sensitive paths:**
   - If scope touches auth / payment / schema / crypto / user-data paths:
     - Activate `security/SKILL.md` (non-optional)
     - Audit: unsafe defaults, weak permissions, injection risks, secrets handling, missing validation
     - Document: trust boundaries, user input reaching code, sensitive data accessed
     - Include security summary in review findings
5. Runs API contract review with `api-contract-validation/SKILL.md` when API routes, client fetchers/hooks, request/response/error shapes, auth/permission semantics, generated types, API docs/tests, or client-server compatibility changed; internal-only backend changes are N/A with reason/risk unless a boundary is affected.
 6. Runs infra readiness review with `infra-validation/SKILL.md` when deploy/runtime/env/CI/health/rollback changed; secret evidence must use variable names only and must never include printed/logged/pasted/committed secret values.
 6b. **UI/UX review track (v4.9.0):** If scope includes UI changes:
     - Read Design Intelligence Brief if it exists at `<repo>/docs/design-brief-<feature>.md`
     - Review UI/UX Quality Audit report from implementation
     - Review Accessibility Audit report
     - Review Responsive/State Audit report
     - Review Visual Regression results
     - Include UI/accessibility findings in review output with severity ratings
     - Reviewer output is advisory unless blocking criteria apply (Critical UI/UX or accessibility findings)
     - Evaluate UI quality on: clarity, hierarchy, consistency, accessibility, responsiveness, brand fit, anti-generic quality, tasteful delight, production readiness, and usefulness — not decorative beauty alone
     - Design must support legibility, user-friendly reading, and clear communication; visual polish must not mask usability issues
  6c. **v4.9.1 Design Research and Motion Review:**
      - Did design direction follow design-research methodology? (product context, competitor audit, anti-pattern audit, rationale for choices)
      - Are aesthetic choices project-specific, not generic defaults?
      - Are motion and micro-interactions purposeful (not decorative noise)?
      - Are timing/easing/choreography within spec for use case?
      - Does motion respect `prefers-reduced-motion`?
      - Does visual polish pass the pixel-perfect checklist? (optical balance, rhythm, CTA prominence, alignment, mobile density, dark mode harmony)
  6d. **v4.9.2 Visual Craft + Platform Polish Review:**
      - Platform fit and safe-area handling (notch, home indicator, status bar respected?)
      - Apple HIG / Material 3 / WCAG 2.2 relevance as principles, not imitation
      - Illustration/graphic language fit (visual metaphor, iconography consistent, brand motif present?)
      - Empty-state graphics designed, not blank space
      - Before/after visual iteration evidence provided for material visual changes
      - Did visual polish improve usability or harm it? (NN/g aesthetic-usability check)
      - Does the UI still feel generic, or is it distinctive and context-fit?
 7. Classifies each finding as `VERIFIED`, `INFERRED`, or `OUT-OF-SCOPE`
8. Separates contract/release blockers from deployment gaps and polish when the active spec distinguishes them
9. If the scope is a plan or plan-correction artifact, activate `implementation-readiness-gate/SKILL.md`
10. For implementation-readiness claims, verify all of:
   - runtime authority is explicit and actually matches the mounted path
   - state model is explicit when multi-step form/stateful flows are involved
   - contract touch list is complete for any shape/type/interface changes
   - summary does not overclaim beyond the evidence
11. Reviews gate evidence classifications for all non-pass or skipped gates:
   - `TARGETED_FAILURE` and `BLOCKING_UNKNOWN` require changes.
   - `BROAD_BASELINE_FAILURE` requires proof that the failing area is unrelated; product-code commits still need explicit owner acceptance.
   - `FLAKY_OR_INFRA_FAILURE` requires one retry and documented evidence from both attempts.
   - `NOT_RUN` must state reason, risk, and missing confidence.
   - `ACCEPTED_NON_BLOCKING` must cite explicit owner approval.
12. Reviews dirty workspace inventory and flags hidden or unexplained dirty product-code / unknown-risky changes as a review finding.
13. Outputs a risk report with severity (Critical / High / Medium / Low)
14. For each finding: states the problem, the exact file/line, the evidence tag, the governing-contract reference, and a specific recommendation
15. Gives an overall verdict: Approve / Approve with minor fixes / Requires changes

## Output format

```
## Review: <scope>

Verdict: Approve / Approve with minor fixes / Requires changes

Findings:
  [Critical] <file>:<line> (<VERIFIED|INFERRED|OUT-OF-SCOPE>) - <problem> [contract: <source>] -> <recommendation>
  [High]     <file>:<line> (<VERIFIED|INFERRED|OUT-OF-SCOPE>) - <problem> [contract: <source>] -> <recommendation>
  [Medium]   <file>:<line> (<VERIFIED|INFERRED|OUT-OF-SCOPE>) - <problem> [contract: <source>] -> <recommendation>

Summary: <one paragraph>

Models/helpers used: <agent/model/reason; token/cost/latency if exposed; cheaper route sufficient? yes/no/unknown>

Gate classification review: <accepted / requires changes, with reason>
Dirty workspace inventory review: <accepted / requires changes, with reason>
Specialist artifact review: <PRD / Design Brief / QA Plan / Threat Model / ADR / Proof of Done statuses, or N/A with reason>
```

## Model escalation

Default model is `opencode-go/glm-5.1`. Switch to `opencode-go/qwen3.7-plus` when:
- Context window is large (multi-module diff, 500+ lines of changed code)
- Review requires deep reasoning about auth, schema, or state-model correctness
- Reviewer confidence must be highest for a production-blocking decision

## Do not
- Edit any files
- Run quality gates (use /gates for that)
- Approve if Critical findings exist
- Invent endpoints, commands, or test evidence
- Mix implementation planning into the review output
- Use unsupported readiness percentages without stating a rubric
- Reference retired skill locations, hidden orchestration commands, or dead absolute paths
