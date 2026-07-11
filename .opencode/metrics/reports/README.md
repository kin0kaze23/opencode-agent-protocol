# OpenCode Metrics Reports

**Version:** 1.0.0
**Date:** 2026-05-26
**Phase:** P3D (Performance Baselines & Reporting)

---

## Purpose

This directory contains sanitized baseline reports generated from local raw metrics. Reports are metadata-only and safe to commit.

---

## Sample-Size Rules

| Sample Count | Status | Action |
|---|---|---|
| < 20 | `INSUFFICIENT_SAMPLE_SIZE` | Report only. No thresholds. |
| 20–49 | `SOFT_OBSERVATIONS` | Soft observations only. |
| 50–99 | `CANDIDATE_THRESHOLDS` | Candidate thresholds only. |
| 100+ | `NON_BLOCKING_WARNINGS` | Non-blocking warnings allowed. |
| 200+ | `BLOCKING_CONSIDERATION` | Consider blocking only for severe regressions, after owner approval. |

---

## How to Generate Reports

```bash
# Generate report for today
bash .opencode/metrics/report.sh

# Generate report for specific date
bash .opencode/metrics/report.sh --date 2026-05-26

# Generate report to custom directory
bash .opencode/metrics/report.sh --output-dir /path/to/reports/
```

---

## How to Interpret Reports

### Sample Status
- `INSUFFICIENT_SAMPLE_SIZE`: Not enough data to draw conclusions. Collect more events.
- `SOFT_OBSERVATIONS`: Some patterns emerging, but not statistically significant.
- `CANDIDATE_THRESHOLDS`: Enough data to propose thresholds, but not enforce them.
- `NON_BLOCKING_WARNINGS`: Enough data to warn on severe regressions, but not block.

### Latency Percentiles
- `p50`: Median latency (50% of events faster than this)
- `p75`: 75th percentile latency
- `p95`: 95th percentile latency (only 5% of events slower than this)

### Token/Cost Data
- `unknown_count`: Number of events where token/cost data was unavailable
- High unknown counts indicate need for better provider integration

---

## Privacy Reminders

- Reports contain **metadata only**
- No prompts, responses, secrets, file contents, or private data
- Raw logs remain gitignored (`.opencode/metrics/raw/`)
- Only sanitized reports in this directory may be committed

---

## Threshold Eligibility

Thresholds become eligible only after:
1. 100+ samples collected
2. Baseline report generated with `NON_BLOCKING_WARNINGS` status
3. Owner reviews and approves proposed thresholds
4. Thresholds are added to `.opencode/metrics/thresholds.json` (future phase)

**Current status:** Thresholds are NOT enforced. Reports are for observation only.
