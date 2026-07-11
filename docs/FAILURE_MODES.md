# Failure Modes

> **Purpose:** Documents known failure modes, their risks, mitigations, and validation commands.
> **Last Updated:** 2026-07-11

---

## 1. Privacy Scanner False Negatives

| Field | Value |
|-------|-------|
| **Symptom** | Personal project name or identity appears in a tracked file but the scanner does not catch it |
| **Risk** | Personal data leaked to public repo |
| **Cause** | Pattern not in the scanner's pattern list, or new naming variant not covered |
| **Mitigation** | Add the pattern to `scripts/public-surface-scan.sh` in the appropriate `scan_category` call. Include all variant forms (PascalCase, camelCase, space, kebab, snake, lowercase) |
| **Validation** | `bash scripts/public-surface-scan.sh` |
| **Owner responsibility** | Review scan patterns before each release. Add new patterns when new project names are introduced |

---

## 2. Overbroad Exclusion Risk

| Field | Value |
|-------|-------|
| **Symptom** | Scanner passes but personal data exists in excluded files |
| **Risk** | Personal data in policy docs or examples that are excluded from scanning |
| **Cause** | `EXCLUDE_PATTERN` in `scripts/public-surface-scan.sh` is too broad |
| **Mitigation** | Exclusions must be narrow and path-specific. Never use broad glob exclusions. Each exclusion must be documented with a reason |
| **Validation** | Review `EXCLUDE_PATTERN` in `scripts/public-surface-scan.sh` — every entry should have a comment explaining why it is excluded |
| **Owner responsibility** | Audit exclusions before each release |

---

## 3. Stale Documentation vs Runtime Config

| Field | Value |
|-------|-------|
| **Symptom** | `docs/CAPABILITY_CATALOG.md` or `docs/RUNTIME_MAP.md` references files that no longer exist or misses new files |
| **Risk** | Users follow outdated documentation and encounter errors |
| **Cause** | Documentation was not updated when config files were added, renamed, or removed |
| **Mitigation** | Manual review during release process. Future v5.3 will add machine-checkable doc/config consistency validation |
| **Validation** | Manually verify that all files referenced in docs exist: `grep -oE '\.opencode/[a-zA-Z._/-]+' docs/RUNTIME_MAP.md \| sort -u \| while read f; do test -f "$f" \|\| echo "MISSING: $f"; done` |
| **Owner responsibility** | Update docs when changing config files |

---

## 4. Model Routing Is Advisory

| Field | Value |
|-------|-------|
| **Symptom** | Agent uses a suboptimal model for a task because routing recommendations were not followed |
| **Risk** | Lower quality output, higher cost, or slower execution |
| **Cause** | Model routing is advisory — the underlying runtime may not enforce recommendations |
| **Mitigation** | Review routing policy periodically. Run `bash .opencode/conformance/tests/model-routing-coherence.sh` to verify policy consistency |
| **Validation** | `bash .opencode/conformance/tests/model-routing-coherence.sh` |
| **Owner responsibility** | Ensure runtime config matches recommended routing policy |

---

## 5. Reviewer Calibration Limits

| Field | Value |
|-------|-------|
| **Symptom** | Reviewer approves a change that should have been blocked, or rejects a change that should have been approved |
| **Risk** | Quality regression or unnecessary friction |
| **Cause** | Reviewer policy is advisory — human or AI reviewer judgment may differ from policy |
| **Mitigation** | Reviewer calibration tests validate policy consistency, not reviewer judgment. Human review is still required for HIGH-RISK changes |
| **Validation** | `bash .opencode/conformance/tests/reviewer-calibration.sh` |
| **Owner responsibility** | Periodically review calibration scorecard and adjust policy |

---

## 6. CI Can Pass While Product Logic Is Wrong

| Field | Value |
|-------|-------|
| **Symptom** | All CI checks pass but the change introduces a bug or incorrect behavior |
| **Risk** | Defective code merged to main |
| **Cause** | CI checks protocol conformance and privacy — it does not validate product logic or business correctness |
| **Mitigation** | Product-level tests must be added by the developer. CI catches protocol regressions, not logic bugs |
| **Validation** | Run product-specific tests in addition to protocol conformance tests |
| **Owner responsibility** | Ensure product code has its own test suite |

---

## 7. Human Approval Still Required for High-Risk Changes

| Field | Value |
|-------|-------|
| **Symptom** | Agent attempts to make a HIGH-RISK change without human approval |
| **Risk** | Unsafe changes to auth, payment, schema, secrets, or destructive operations |
| **Cause** | Protocol rules are advisory — the agent may attempt to bypass them |
| **Mitigation** | Git guard blocks direct pushes. Branch protection requires PR. Reviewer policy recommends independent review for HIGH-RISK. But ultimate enforcement is human |
| **Validation** | `bash .opencode/conformance/tests/production-hardening.sh` |
| **Owner responsibility** | Never auto-approve HIGH-RISK changes. Always review touch list, rollback path, and test evidence |

---

## 8. Generated Artifacts Should Not Be Trusted as Source of Truth

| Field | Value |
|-------|-------|
| **Symptom** | Decisions are made based on generated reports or cached data that is stale |
| **Risk** | Incorrect routing, stale evidence, outdated recommendations |
| **Cause** | Generated files (reports, scorecards, cached results) are not authoritative |
| **Mitigation** | Always check the source config file, not the generated output. See `docs/RUNTIME_MAP.md` for the authoritative vs generated classification |
| **Validation** | Compare generated files against their source configs |
| **Owner responsibility** | Treat generated files as informational only. Regenerate before relying on them |
