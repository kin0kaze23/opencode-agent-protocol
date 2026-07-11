# Reviewer Calibration Policy

> **v4.29.4 — How to calibrate reviewer value and use it for routing optimization.**

## Purpose

The reviewer is a critical component of the agent protocol. Before routing optimization can adjust reviewer triggers, we need calibrated data on reviewer value across at least 5 tasks.

## Reviewer Sampling Plan

Until 5 reviewer-involved tasks are recorded:

1. **Use reviewer on every STANDARD and HIGH_RISK task.**
2. **Record reviewer outcome in telemetry** using `record-task-outcome.sh --reviewer <model>`.
3. **Classify reviewer value** in `senior-self-review.sh` using the fields below.

## Reviewer Value Classification

Each reviewer-involved task must classify the reviewer's contribution:

| Classification | Meaning | Action |
|---|---|---|
| `material_issue_found` | Reviewer found an issue that would have caused regression or data loss | Fix before commit. Record as reviewer value: high. |
| `minor_issue_found` | Reviewer found an improvement but not a blocker | Fix if easy. Record as reviewer value: medium. |
| `no_material_findings` | Reviewer confirmed quality, no issues found | Proceed. Record as reviewer value: low (but confirms quality). |
| `false_positive` | Reviewer flagged something that was actually correct | Ignore flag. Record as reviewer value: negative. |
| `not_used` | Reviewer was not invoked | N/A. |

## When to Use Reviewer

| Lane | Files | Sensitive Paths | Reviewer Required? |
|---|---|---|---|
| DIRECT | 1 | No | No |
| FAST | ≤3 | No | Optional (sample 1 in 3) |
| STANDARD | ≤6 | No | Yes |
| STANDARD | ≤6 | Yes | Yes (mandatory) |
| HIGH-RISK | ≤10 | Any | Yes (mandatory) |

## Reviewer Model Selection

| Risk | Primary | Fallback |
|---|---|---|
| Routine | `umans-glm-5.1` | `opencode-go/glm-5.1` |
| Sensitive paths | `opencode-go/glm-5.1` | `opencode-go/kimi-k2.6` |
| Release/ship | `opencode-go/glm-5.1` | `opencode-go/kimi-k2.6` |

## Calibration Thresholds

| Metric | Minimum | Purpose |
|---|---|---|
| Reviewer-involved tasks | 5 | Before any reviewer routing optimization |
| Material issues found | 1 | To validate reviewer is catching real problems |
| False positives | ≤2 | To ensure reviewer is not over-flagging |

## Non-Fabrication Rule

- Do not fabricate reviewer findings.
- Do not intentionally introduce bugs to test the reviewer.
- Do not skip the reviewer on STANDARD/HIGH-RISK tasks to "save time."
- If the reviewer is unavailable, document the reason and proceed with extra self-review.

## Integration with Telemetry

After each reviewer-involved task, record:
```bash
bash .opencode/scripts/record-task-outcome.sh \
  --repo <repo> --lane <lane> --task-type <type> --outcome <outcome> \
  --reviewer <model> \
  --notes "reviewer_value: <classification>"
```

After `/checkpoint`, the scorecard will show:
- `reviewer_value: N tasks with reviewer, M found issues`
- `thresholds: reviewer: N/5 ✓/✗`
