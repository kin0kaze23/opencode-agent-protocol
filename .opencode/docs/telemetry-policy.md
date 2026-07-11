# Telemetry Privacy and Retention Policy

> **v4.29.1 — Privacy, retention, and usage rules for agent telemetry data.**

## What We Collect

Task outcome metadata only:
- Task type, lane, outcome, repo, branch
- Model used, reviewer used, premium model used
- CI status, CI first-try, repair cycles
- Tests added/updated, test command run
- Pattern memory used, project memory used
- Human acceptance (accepted/revised/rejected/unknown)
- Timestamp, task ID, free-text notes

## What We Never Collect

| Forbidden Data | Reason |
|---|---|
| Prompts | May contain user intent, business logic, or sensitive context |
| Responses | May contain generated code, analysis, or proprietary output |
| API keys | Secrets — managed exclusively through Doppler |
| Secrets | Never in telemetry, commits, or logs |
| File contents | May contain proprietary code or user data |
| User data | PII, customer data, personal information |
| Raw command output | May contain environment details or secrets |

## Storage

| Data Type | Location | Git Status | Retention |
|---|---|---|---|
| Raw task outcomes | `.opencode/metrics/task-outcomes.jsonl` | Gitignored | 90 days, then rotated |
| Aggregated summaries | `.opencode/metrics/reports/` | May be committed if secret-free | 1 year |
| Scorecard output | Terminal/session only | Not persisted | Ephemeral |

## Retention Guidance

1. **task-outcomes.jsonl**: Review monthly. Delete records older than 90 days.
2. **Aggregated reports**: Review quarterly. Archive to long-term storage after 1 year.
3. **No automatic deletion**: Retention is manual to avoid losing data during active analysis.

## What Can Be Used for Routing Decisions

| Data | Minimum Sample | Usage |
|---|---|---|
| Success rate by task type | 5 tasks per type | Suggest lane or checklist changes |
| CI first-pass rate | 10 tasks total | Suggest pre-commit gate additions |
| Model ROI | 5 tasks per model | Suggest model routing changes |
| Reviewer value | 5 tasks with reviewer | Suggest reviewer trigger adjustments |
| Repair cycles | 10 tasks total | Suggest local gate improvements |

## What Cannot Be Used for Routing Decisions

- Single-task outcomes (sample size too small)
- Human acceptance from unknown status (no signal)
- Failure patterns from fewer than 3 tasks of the same type
- Model comparisons with fewer than 3 tasks per model

## Compliance

- **GDPR/CCPA**: No personal data logged. Metadata only.
- **SOC 2 aligned**: Metadata only, no user content.
- **Internal audit ready**: Clear retention, deletion, and usage rules.

## Schema Validation

All records are validated against `.opencode/schemas/task-outcome.schema.json` before appending. Invalid records are rejected (non-blocking — the task is not affected).

## Non-Perfect Outcome Policy (v4.29.4)

### Rules

1. **Do not fabricate bad outcomes.** Never invent failures, CI repairs, or reverted tasks.
2. **Do not intentionally cause task failures** to satisfy thresholds.
3. **Record real failures when they naturally occur** — CI failures, repair cycles, reverted tasks, and partial outcomes are valuable signal.
4. **Eval fixtures may simulate failures** but must be marked `source_type=eval_fixture` and are excluded from production routing thresholds.
5. **Never label synthetic tasks as real.** `source_type=eval_fixture` records are for testing only.

### Evidence Weighting

| Evidence Level | Weight | Counts Toward Routing? |
|---|---|---|
| `full` | 1.0 | Yes |
| `partial` | 0.5 | Informs trends, but cannot unlock routing changes alone |
| `unknown` | 0 | Excluded from confidence-sensitive metrics |
| `fixture` | 0 | Never counts as production routing evidence |

### Source Type Rules

| Source Type | Counts as Production Evidence? | Can Unlock Routing? |
|---|---|---|
| `live` | Yes | Yes (if evidence_level=full) |
| `retrospective` | Yes (exploratory) | Only for exploratory thresholds, not live routing |
| `eval_fixture` | No | Never |

### Confidence Threshold

- Routing optimization requires ≥70% of records to have `evidence_level=full`.
- If confidence is below 70%, scorecard reports `partially_blocked — low confidence`.

## Review Process

- Monthly: Review telemetry data for accuracy and completeness
- Quarterly: Review retention policy and delete stale data
- Before routing changes: Verify minimum sample sizes are met
- Before routing changes: Verify confidence weight ≥ 70%
