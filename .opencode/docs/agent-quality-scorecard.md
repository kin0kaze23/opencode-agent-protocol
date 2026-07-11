# Agent Quality Scorecard

> **Practical scoring rubric for evaluating agent task quality.**
> Version: v4.29 — 2026-07-04

## Purpose

This rubric defines how to evaluate agent task quality using telemetry data from `task-outcomes.jsonl`. It is practical, not academic — designed to surface actionable insights for routing and workflow optimization.

## Scoring Dimensions

### 1. Task Success (weight: 25%)

| Score | Criteria |
|---|---|
| 5 | Task completed, all gates pass, human accepted without revision |
| 4 | Task completed, gates pass, human accepted with minor revision |
| 3 | Task completed but required significant rework or gate repair |
| 2 | Task partially completed, some gates failed |
| 1 | Task failed or reverted |

### 2. Correctness (weight: 20%)

| Score | Criteria |
|---|---|
| 5 | No bugs found in review or after merge |
| 4 | Minor issues found in review, fixed before merge |
| 3 | Issues found after merge but within 24h |
| 2 | Issues found after merge, required hotfix |
| 1 | Regression introduced |

### 3. Test Discipline (weight: 15%)

| Score | Criteria |
|---|---|
| 5 | Tests added/updated for all logic changes, tests pass |
| 4 | Tests added for most logic changes, tests pass |
| 3 | Existing tests pass, no new tests (justified) |
| 2 | Existing tests pass, no new tests (unjustified) |
| 1 | Tests failed or skipped |

### 4. CI Reliability (weight: 10%)

| Score | Criteria |
|---|---|
| 5 | CI passed on first try |
| 4 | CI passed after 1 repair cycle |
| 3 | CI passed after 2 repair cycles |
| 2 | CI passed after 3+ repair cycles |
| 1 | CI never passed (manual merge) |

### 5. Reviewer Usefulness (weight: 10%)

| Score | Criteria |
|---|---|
| 5 | Reviewer found material issue that would have caused regression |
| 4 | Reviewer found improvement, not a blocker |
| 3 | Reviewer confirmed quality, no issues |
| 2 | Reviewer was unnecessary (low-risk task) |
| 1 | Reviewer was not used when it should have been |

### 6. Model Cost/ROI (weight: 5%)

| Score | Criteria |
|---|---|
| 5 | Cheapest sufficient model used, task succeeded |
| 4 | Appropriate model used, task succeeded |
| 3 | Premium model used unnecessarily |
| 2 | Premium model used, task still needed rework |
| 1 | Premium model used, task failed |

### 7. Speed (weight: 5%)

| Score | Criteria |
|---|---|
| 5 | Task completed in expected time for lane |
| 4 | Slightly slower than expected |
| 3 | Noticeably slow but acceptable |
| 2 | Unacceptably slow |
| 1 | Timed out or abandoned |

### 8. Memory Reuse (weight: 5%)

| Score | Criteria |
|---|---|
| 5 | Pattern memory or project memory directly helped the task |
| 4 | Memory was consulted and confirmed approach |
| 3 | Memory was available but not relevant |
| 2 | Memory was not consulted |
| 1 | Memory would have helped but was not consulted |

### 9. Human Acceptance (weight: 5%)

| Score | Criteria |
|---|---|
| 5 | Accepted without revision |
| 4 | Accepted with minor revision |
| 3 | Accepted with major revision |
| 2 | Rejected and redone |
| 1 | Rejected, task abandoned |

## Overall Score Calculation

```
overall = (success * 0.25) + (correctness * 0.20) + (test_discipline * 0.15) +
          (ci_reliability * 0.10) + (reviewer_usefulness * 0.10) +
          (model_roi * 0.05) + (speed * 0.05) + (memory_reuse * 0.05) +
          (human_acceptance * 0.05)
```

| Range | Rating | Action |
|---|---|---|
| 4.5–5.0 | Excellent | Document pattern, share approach |
| 3.5–4.4 | Good | Normal operation |
| 2.5–3.4 | Needs Improvement | Review routing, checklist, or model choice |
| 1.0–2.4 | Poor | Stop and investigate root cause before next task |

## Usage

### Automated Scorecard

```bash
bash .opencode/scripts/summarize-agent-quality.sh --days 30
```

### Manual Scoring

After a STANDARD or HIGH-RISK task, score each dimension 1-5 during `/checkpoint`. Record the overall score in the task outcome telemetry.

### Trend Analysis

Compare scorecards over time:
- Weekly: identify routing or model issues early
- Monthly: identify systemic patterns (e.g., test discipline declining)
- Quarterly: evaluate whether lane thresholds or reviewer triggers need adjustment

## Privacy

- No prompts, responses, file contents, or secrets in telemetry
- Only metadata: task type, outcome, model, gates, timing
- See `.opencode/metrics/README.md` for full privacy rules
