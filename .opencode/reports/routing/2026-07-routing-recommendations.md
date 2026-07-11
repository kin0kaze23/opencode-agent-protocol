# Routing Recommendations — 2026-07

> **v4.30 Evidence-Based Routing Optimization**
> Generated: 2026-07-05
> Status: advisory_only — no automatic routing changes applied

## Evidence Summary

| Metric | Value |
|---|---|
| Total tasks | 19 |
| Reviewer-involved tasks | 5 |
| Reviewer found issues | 5 |
| Reviewer hit rate | 100% |
| Success rate | 100% |
| CI first-pass rate | 75% |
| Confidence weight | 84% full-evidence |

## Evidence Scope

| Dimension | Value |
|---|---|
| Repos with reviewer | sample-service (5/5) |
| Task types with findings | bugfix (1), feature (3), test (1) |
| Severity distribution | high=1, medium=3, low=1 |
| All findings fixed before merge | Yes |
| Automated gates missed all findings | Yes |

## Recommendations

### Accepted

#### 1. reviewer_required for STANDARD eval/infra/test-boundary work

- **Classification:** reviewer_required
- **Evidence count:** 5 tasks
- **Confidence:** high
- **Applicable task types:** bugfix, feature, test
- **Applicable repos:** sample-service
- **Reason:** 100% hit rate with findings ranging from low to high severity. All findings fixed before merge. Automated gates missed all of them.
- **Risk of overgeneralization:** MEDIUM — evidence is concentrated in sample-service eval/infra tasks. Do not generalize to UI/docs/design tasks without cross-repo evidence.
- **Scope guard:** Do not apply to HIGH-RISK, auth, security, payment, schema, or data tasks — those already require reviewer unconditionally.

#### 2. cheaper_model_ok for repeated eval-pattern tasks

- **Classification:** cheaper_model_ok
- **Evidence count:** 19 tasks (5 with reviewer)
- **Confidence:** medium
- **Conditions:**
  - Established pattern exists (e.g., eval runner reuse)
  - Tests are strong (eval assertions + full test suite)
  - Reviewer is still used
  - No sensitive paths touched (auth, payment, schema, secrets)
- **Reason:** All 5 reviewer-involved tasks used umans-glm-5.2 for implementation and umans-glm-5.1 for review. All succeeded. Reviewer caught real issues that cheaper implementation missed.
- **Risk of overgeneralization:** HIGH — only 5 tasks, all in sample-service. Do not apply to architecture, debugging, or cross-repo work without more evidence.

### Rejected

#### 3. Relax reviewer for all STANDARD tasks

- **Status:** rejected
- **Reason:** Evidence is concentrated in eval/infra/test-boundary work. No evidence for UI/design/docs tasks. No evidence for architecture/auth/security tasks. Generalizing would be unsafe.

#### 4. Change premium model routing

- **Status:** rejected (no_change)
- **Reason:** No evidence supports changing premium model routing. Reserve for architecture, difficult debugging, and final review.

### Unchanged

| Area | Status | Reason |
|---|---|---|
| DIRECT Lite | unchanged | No telemetry collected by design |
| FAST | unchanged | Reviewer remains optional unless sensitive paths or repeated failures |
| HIGH-RISK | unchanged | Reviewer always required, no exceptions |

## Scope Guardrails

1. Do not generalize from sample-service eval/infra evidence to all repos.
2. Do not generalize from eval/infra tasks to UI/design/docs tasks.
3. Require stronger evidence before changing HIGH-RISK rules.
4. DIRECT Lite remains unchanged.
5. FAST remains lightweight unless sensitive paths or repeated failures appear.

## Config Changes Made

None. This is advisory only. The existing `token-budget.yaml` already has:
- STANDARD: `reviewer_required: true` with condition "required for risk 4+, sensitive paths, 4+ files, or release gates; optional otherwise"
- HIGH-RISK: `reviewer_required: true` with condition "always required — no exceptions"

The evidence supports reinforcing the STANDARD reviewer condition to explicitly include eval/infra/test-boundary work as a reviewer-required category, but this config change should be made separately with owner approval.

## Next Data Needed

- Cross-repo reviewer evidence (at least 2 repos beyond sample-service)
- UI/design task reviewer evidence (at least 3 tasks)
- Architecture/auth/security task reviewer evidence (at least 3 tasks)
- Multiple reporting periods for trend analysis
