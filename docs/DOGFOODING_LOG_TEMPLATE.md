# Dogfooding Log Template

> **Purpose:** Template for recording daily-use evidence of the OpenCode Agent Protocol.
> **Last Updated:** 2026-07-11

---

## How to Use This Template

For each task you complete using the protocol, record the following fields. This builds an evidence base for productivity claims.

**Important:** Do not claim guaranteed productivity gains. Record what actually happened, including failures and manual corrections.

---

## Task Record Template

```
### Task: [task description]
Date: YYYY-MM-DD

| Field | Value |
|-------|-------|
| Task type | [docs / bugfix / feature / refactor / test / release / CI / config] |
| Repo/project | [project name or "this repo"] |
| Risk level | [DIRECT / FAST / STANDARD / HIGH-RISK] |
| Baseline expected time | [estimated time without harness, e.g., "30 min"] |
| Actual time with harness | [actual time, e.g., "20 min"] |
| AI iterations | [number of AI agent iterations] |
| Checks run | [list of validation scripts run] |
| CI result | [PASS / FAIL / N/A] |
| Issues caught | [what the harness caught, e.g., "privacy scan caught stale reference"] |
| Manual fixes needed | [what you had to fix manually] |
| Confidence score | [1-5, where 5 = high confidence in quality] |
| Notes | [any observations] |
```

---

## Example Entry

```
### Task: Fix version regex in protocol-atlas.sh
Date: 2026-07-11

| Field | Value |
|-------|-------|
| Task type | bugfix |
| Repo/project | this repo |
| Risk level | FAST |
| Baseline expected time | 15 min |
| Actual time with harness | 10 min |
| AI iterations | 2 |
| Checks run | public-surface-scan, validate-docs-drift, protocol-atlas.sh |
| CI result | PASS |
| Issues caught | docs-drift validator caught stale git-guard.md reference |
| Manual fixes needed | none |
| Confidence score | 5 |
| Notes | Validator caught a real issue that would have been missed manually |
```

---

## Summary Statistics

After collecting 10+ task records, calculate:

| Metric | How to calculate |
|--------|-----------------|
| Average time saved | (sum of baseline times - sum of actual times) / number of tasks |
| Issues caught per task | total issues caught / number of tasks |
| Manual fix rate | tasks with manual fixes / total tasks |
| Average confidence | sum of confidence scores / number of tasks |
| CI pass rate | tasks with CI PASS / total tasks with CI |

**Do not publish these as guaranteed results.** They are illustrative until measured with controlled methodology.
