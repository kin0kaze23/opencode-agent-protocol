# OpenCode v4.7.0 Phase E Live Validation Evidence

Status: Phase E evidence draft created from controlled dry-run/tabletop pilots. Active protocol remains v4.6.1. v4.7.0 remains candidate/prep only.

## Execution Boundary

- Controlling local plan: `PLAN.md` (local execution control only; do not commit).
- Candidate protocol reference: `docs/opencode/v4.7.0/CANDIDATE_PROTOCOL.md`.
- Candidate eval reference: `docs/opencode/v4.7.0/CANDIDATE_EVAL_PLAN.md`.
- Evidence archive: `docs/opencode/v4.7.0/PHASE_E_LIVE_VALIDATION_EVIDENCE.md`.
- Product code changed: no.
- Product code committed: no.
- v4.7.0 activated: no.
- Model routing changed: no.
- Agents changed or added: no.
- `.opencode/brain-config.json`, `NOW.md`, `.opencode/AGENTS.md`, `.opencode/scripts/workspace-protocol-guard.sh`, and vault docs changed: no.
- Secret handling: `.env.doppler` was observed as untracked and excluded from staging/evidence; no secret values were printed.

## Preflight Results

| Check | Result | Evidence |
|---|---|---|
| Active protocol version | PASS | `jq -r '.version' .opencode/brain-config.json` returned `4.6.1`. |
| Scoped protected-file status | PASS with known dirty exclusion | `git status --short -- PLAN.md docs/opencode/v4.7.0/PHASE_E_LIVE_VALIDATION_EVIDENCE.md .env.doppler .opencode/brain-config.json NOW.md .opencode/AGENTS.md .opencode/scripts/workspace-protocol-guard.sh` showed `M PLAN.md` and `?? .env.doppler` before evidence creation. |
| Browser route preflight | PASS | `bash .opencode/scripts/browser-verification-preflight.sh`: Playwright MCP `false`; Python Playwright `usable`; browser binary `installed`; agent-browser `available` (`0.13.0`); selected route `Python Playwright`. |
| Pilot mode | PASS | Dry-run/tabletop only; no product-code implementation. |

## Pilot A — UI/Product-Facing Lifecycle Validation

### Scenario

Dry-run a product-facing UI change request: improve a workspace empty state so a new user understands why no workspaces are visible, what action to take next, and how to recover if they lack permission. This is a safe mock scenario; no product files were edited.

### Artifacts Used

| Artifact | Mode | Evidence |
|---|---|---|
| PRD / PRD-lite | Compact | User problem, success criteria, non-goals, and kill criteria were scoped for a single empty-state improvement. |
| DESIGN_BRIEF | Compact | Visual hierarchy, information architecture, responsive states, and accessibility intent were required before implementation. |
| QA_PLAN | Compact | Empty, loading, error, permission-denied, and successful create-entry states were enumerated. |
| PROOF_OF_DONE | Compact | Required changed-file list, planned-vs-actual touch list, browser evidence, dirty inventory, and rollback note. |
| THREAT_MODEL | N/A | Reason: UI empty-state copy/layout does not touch auth, secrets, user data flows, payments, callbacks, or trust boundaries. Risk: low; permission-state display should still avoid leaking tenant existence. |
| ADR | N/A | Reason: no architecture/runtime/state-model decision in the dry run. Risk: none. |

### Templates Triggered

- `.opencode/templates/PRD.md`
- `.opencode/templates/DESIGN_BRIEF.md`
- `.opencode/templates/QA_PLAN.md`
- `.opencode/templates/PROOF_OF_DONE.md`

### Skills Triggered

- `design-system-governance`: checked that a real implementation would identify existing tokens/components, cover state/responsive behavior, document dark/light mode support or N/A, and classify missing design evidence with v4.6.1 labels.
- `visual-regression`: checked that a real implementation would run browser route preflight, use baseline/reference screenshots when available, classify visual diffs, and mark missing baseline as advisory/`BASELINE_MISSING` rather than blocking every small UI task.

### Role Profiles Triggered

- UI/UX Designer: visual hierarchy, interaction quality, accessibility, and design-system fit.
- Frontend Engineer: component/state coverage, accessibility semantics, responsive behavior, browser evidence, and minimal coupling.

### Gates and v4.6.1 Classifications

| Gate | Result | Classification | Evidence |
|---|---|---|---|
| Product-fit artifact | PASS | N/A | PRD-lite expectations produced a user problem, success criteria, and non-goals before implementation. |
| Design-system governance | PASS for dry run | N/A | Required design-system source identification and state/responsive checklist were clear. |
| Visual regression screenshot | SKIPPED | NOT_RUN | No product UI was changed and no baseline/current screenshot was needed for this mock. Missing confidence: actual pixel comparison for a real route. Risk: low for dry run; would be required/advisory based on real UI risk. |
| Browser route preflight | PASS | N/A | Python Playwright route available. |
| Product-code tests | SKIPPED | NOT_RUN | No product code changed. Missing confidence: no repo-native test result for a real implementation. Risk: none for tabletop evidence. |

### Useful

- PRD-lite and Design Brief prevented jumping straight to layout by forcing user problem, state matrix, accessibility, and visual hierarchy first.
- Design-system governance made token/component reuse explicit and would reduce visual drift.
- Visual regression was appropriately risk-based: advisory when no baseline exists and no implementation happened.

### Bureaucratic

- Full PRD, full QA Plan, and full visual regression would be too heavy for DIRECT copy-only UI fixes.
- The candidate must keep compact/N/A language prominent for small UI changes.

### Gaps Before Activation

- Add or preserve command wording that `BASELINE_MISSING` is not automatically blocking for low-risk/internal UI, but must be documented with risk.
- Keep browser route preflight required before screenshot evidence, not as an unconditional dependency install trigger.

## Pilot B — API/Backend Contract Dry Run

### Scenario

Dry-run an API contract review for a hypothetical workspace-list endpoint consumed by a frontend page. The endpoint returns workspace summaries and may return auth/permission errors. This is a contract tabletop only; no route handlers, clients, schemas, tests, or docs were edited.

### Artifacts Used

| Artifact | Mode | Evidence |
|---|---|---|
| PRD / PRD-lite | Compact | Product behavior focused on what the consumer can rely on: list items, empty result, and permission failure semantics. |
| QA_PLAN | Compact | Success, empty, unauthenticated, unauthorized, malformed query, and server-error cases were enumerated. |
| PROOF_OF_DONE | Compact | Required endpoint list, changed files, gates, classifications, and rollback note. |
| DESIGN_BRIEF | N/A | Reason: no UI implementation in this pilot. Risk: none. |
| THREAT_MODEL | N/A for dry run | Reason: no real auth/permission code changed; auth semantics were reviewed as contract notes only. Risk: low; real permission contract changes should trigger threat modeling. |
| ADR | N/A | Reason: no cross-surface architecture decision or compatibility break approved. Risk: none. |

### Templates Triggered

- `.opencode/templates/PRD.md`
- `.opencode/templates/QA_PLAN.md`
- `.opencode/templates/PROOF_OF_DONE.md`

### Skills Triggered

- `api-contract-validation`: request, response, error, auth, compatibility, client/server/docs/test alignment, and repo-native contract sources. The skill correctly avoided assuming OpenAPI, Zod, or Pact.

### Role Profiles Triggered

- Backend Engineer: API contracts, consistency, auth semantics, migrations/state impact if relevant, and observability.
- QA Engineer: risk-based verification, edge/error paths, regression confidence, and clear skipped-gate classifications.

### Contract Notes

| Contract Area | Dry-Run Evidence |
|---|---|
| Request | `GET /workspaces` style list request; query/pagination must be explicit in a real repo contract. |
| Success response | Array/list of workspace summaries; nullability and optional fields must be documented. |
| Empty response | Empty list should be distinguishable from permission failure. |
| Error response | Unauthenticated, unauthorized, validation, and server errors need stable envelope/status semantics. |
| Auth/permission | Tenant/company boundary must be explicit; no existence leaks across tenants. |
| Compatibility | Removing or renaming response fields requires migration/owner approval; additive fields are safer. |
| Tests/docs/client alignment | Real implementation must compare route handler, client fetcher/hook, fixtures/tests, and docs. |

### Gates and v4.6.1 Classifications

| Gate | Result | Classification | Evidence |
|---|---|---|---|
| API contract validation | PASS for dry run | N/A | Contract checklist covered request, response, errors, auth, compatibility, and client/server/docs/tests. |
| Repo-native API tests | SKIPPED | NOT_RUN | No product endpoint or client changed. Missing confidence: no real repo contract tests. Risk: none for tabletop; would block real API change if targeted tests were absent. |
| Docs/client/server alignment | SKIPPED | NOT_RUN | No repo files inspected beyond candidate protocol inputs. Missing confidence: actual code alignment. Risk: low for dry run; real work must inspect touched paths. |

### Useful

- The api-contract-validation skill produced the right senior behavior: start from repo-native sources, not a preferred contract framework.
- It made error and auth semantics first-class instead of only checking happy-path response fields.

### Bureaucratic

- For backend internals with no boundary change, this would be overkill and should be N/A with reason/risk.
- Requiring examples for every endpoint would be heavy; at least one success and one error path is a better practical bar.

### Gaps Before Activation

- Command docs should continue saying contract validation is triggered by boundary/client/server/docs/test changes, not every backend edit.
- Keep compatibility-break owner approval explicit.

## Pilot C — Security/Infra Tabletop

### Scenario

Tabletop a runtime/environment readiness review for a hypothetical deployment-sensitive change that adds a required environment variable for a workspace service integration. This is a security/infra tabletop only; no env files, runtime config, CI, deploy files, or code were edited.

### Artifacts Used

| Artifact | Mode | Evidence |
|---|---|---|
| THREAT_MODEL | Compact | Assets, actors, trust boundaries, STRIDE risks, mitigations, residual risk, and owner acceptance expectations were mapped. |
| QA_PLAN | Compact | Runtime smoke, health, rollback, and env-name coverage were required. |
| PROOF_OF_DONE | Compact | Required gate classifications, dirty inventory, secret safety, and rollback note. |
| ADR | Conditional N/A | Reason: no actual runtime architecture decision was made. Risk: none for tabletop. Technical Architect profile would require ADR if state model/runtime authority/cross-surface tradeoff became ambiguous. |
| PRD / DESIGN_BRIEF | N/A | Reason: no user-facing product or UI change in this pilot. Risk: none. |

### Templates Triggered

- `.opencode/templates/THREAT_MODEL.md`
- `.opencode/templates/QA_PLAN.md`
- `.opencode/templates/PROOF_OF_DONE.md`
- `.opencode/templates/ADR.md` as conditional/N/A when no architecture decision exists.

### Skills Triggered

- `threat-modeling`: assets, actors, trust boundaries, data flows, STRIDE, mitigations, residual risk, owner acceptance.
- `infra-validation`: deploy target, runtime surfaces, CI/CD, env/secrets names only, healthcheck, rollback, no expensive installs by default.

### Role Profiles Triggered

- Security Reviewer: trust boundaries, secrets, permissions, residual risk, and classification of skipped/unresolved security gates.
- DevOps Engineer: runtime authority, env variable names, deploy target, CI/CD expectations, health checks, rollback, and secret safety.
- Technical Architect: relevant conditionally if runtime authority or cross-surface design decisions are ambiguous.

### Threat/Infra Tabletop Notes

| Area | Dry-Run Evidence |
|---|---|
| Assets | Secret values, workspace data, permissions, availability, auditability. |
| Actors | Normal user, workspace admin, service account, third-party service, malicious tenant, anonymous attacker. |
| Trust boundaries | Local env to runtime, server to external service, tenant/company boundary, CI/deploy environment. |
| Example variable names | `WORKSPACE_SERVICE_API_KEY`, `WORKSPACE_SERVICE_BASE_URL` (names only; no values). |
| STRIDE focus | Spoofing via bad credentials, tampering with callback/base URL, information disclosure through logs, DoS via dependency outage, elevation through tenant boundary confusion. |
| Mitigations | Secret manager binding, redacted logs, env example names only, healthcheck/smoke, rollback action, tenant-scoped auth checks. |
| Residual risk | External service outage and misconfigured env remain owner/operator risks before ship. |

### Gates and v4.6.1 Classifications

| Gate | Result | Classification | Evidence |
|---|---|---|---|
| Threat model tabletop | PASS | N/A | Assets, actors, trust boundaries, STRIDE risks, mitigations, and residual risk were documented. |
| Infra validation tabletop | PASS | N/A | Deploy/runtime/env/health/rollback checklist used; secret values not printed. |
| Secret scanning | SKIPPED | NOT_RUN | No code/env files changed or staged. Missing confidence: no scanner result for a real commit. Risk: none for tabletop; required for real secret-adjacent commits. |
| External deploy inspection | SKIPPED | NOT_RUN | No deploy target changed; no external platform inspection authorized. Missing confidence: external runtime state. Risk: low for tabletop. |

### Useful

- Threat modeling before scanning captured design risks that scanners cannot see.
- Infra validation emphasized secret names only, health/rollback, and no expensive installs without approval.
- Technical Architect conditional use avoided turning every env review into an ADR.

### Bureaucratic

- Full STRIDE table for local-only config comments would be too heavy; compact mode is important.
- Requiring external platform inspection by default would slow routine local validation and risk secret exposure.

### Gaps Before Activation

- Keep secret-safety wording very explicit: names only, no raw resolved config output, no `.env*` staging without explicit review.
- Keep expensive scanners advisory unless sensitive code/files are actually changed or owner approves.

## Cross-Pilot Findings

### What Felt Useful

- The candidate pushes work toward senior-operator habits: define the problem, state non-goals, identify runtime authority, plan verification, classify gate gaps, and prove rollback.
- Role profiles worked as quality bars rather than new agents.
- Skills added concrete checklists without requiring model routing changes.
- v4.6.1 gate classifications remained the right active result language.
- Compact and N/A modes are essential and made the candidate usable for non-HIGH-RISK work.

### What Felt Bureaucratic

- Full templates would be excessive for DIRECT/FAST typo, copy-only, or backend-internal changes.
- Visual regression can become overbearing without the advisory/no-baseline path.
- API contract validation can be too heavy unless tightly scoped to boundary changes.
- Security/infra tabletop can become ceremony unless tied to trust boundaries, runtime config, secrets, or deploy risk.

### Gaps to Fix Before Activation

1. Ensure command text consistently preserves compact/N/A paths for DIRECT/FAST or low-risk tasks.
2. Keep visual regression risk-based and avoid treating missing baselines as automatic blockers for low-risk changes.
3. Keep API contract validation tied to request/response/error/auth/client/server/docs/test boundaries.
4. Keep infra validation secret-safe and prohibit printing raw resolved config output.
5. Keep role profiles explicitly advisory and not new agents or routing changes.

## Validation Results

Validation was run after evidence creation and then recorded here.

| Gate | Command | Result | Classification | Evidence |
|---|---|---|---|---|
| Candidate conformance | `bash .opencode/conformance/tests/protocol-capabilities-v470.sh` | PASS | N/A | 191 passed / 0 failed. Script confirmed v4.7.0 remains candidate/prep only and active protocol remains v4.6.1. |
| Workspace protocol guard | `bash .opencode/scripts/workspace-protocol-guard.sh` | PASS | N/A | Guard passed, including environment coherence, launcher runtime coherence, v4.5 native alignment, brain-config coherence, MCP resolvability, protocol coherence Phase 1, v4.6.1 stabilization, Owner memory runtime, GitGuard compliance, helper runtime, implementation readiness, and smoke checks. |
| Browser verification preflight | `bash .opencode/scripts/browser-verification-preflight.sh` | PASS | N/A | Playwright MCP `false`; Python Playwright `usable`; browser binary `installed`; agent-browser `available` (`0.13.0`); selected route `Python Playwright`. |
| Diff whitespace | `git diff --check -- docs/opencode/v4.7.0 PLAN.md` | PASS after fix | N/A | First run reported trailing whitespace in `PLAN.md`; fixed immediately, rerun passed with no output. The initial non-pass was a targeted formatting issue in the allowed local plan file and was resolved before completion. |
| Status inventory | `git status --short` | PASS with known dirty workspace | N/A | Broad workspace remains dirty from pre-existing/unrelated changes. Phase E scoped changes are local `PLAN.md` and ignored evidence file `docs/opencode/v4.7.0/PHASE_E_LIVE_VALIDATION_EVIDENCE.md`; `.env.doppler` remains untracked/excluded. |

## Dirty Workspace Inventory

- OpenCode protocol files: expected local `PLAN.md`; final evidence file exists at `docs/opencode/v4.7.0/PHASE_E_LIVE_VALIDATION_EVIDENCE.md` and is ignored by current git rules, so later commit would require exact-path forced staging if approved. Unrelated existing OpenCode protocol/archive dirtiness remains outside this task, including untracked `.opencode/archive/QCC-1/` observed in final status.
- Vault protocol/eval files: pre-existing `vault` dirty state remains unrelated and excluded.
- Product-code files: no product-code files were edited by this pilot.
- Unrelated pre-existing changes: broad workspace dirtiness existed before this pilot and remains excluded.
- Unknown/risky changes: `.env.doppler` remains untracked and excluded.

## Activation Recommendation

Recommendation: promote with small fixes.

Rationale: Phase E dry-run/tabletop validation shows the v4.7.0 candidate improves senior-operator behavior without requiring activation, model routing changes, new agents, product-code edits, or guard wiring. The candidate should proceed to audit/commit consideration only if final validation passes and the small wording gaps above are accepted or addressed before Phase F activation.

Do not activate v4.7.0 during Phase E. Phase F still requires explicit approval and a separate promotion touch list.
