# Agent Quality Reports

> **Sanitized aggregate scorecards. No raw prompts, no code snippets, no secrets.**

## Monthly Reports

Reports are named `YYYY-MM-scorecard.md` and contain:
- Aggregate metrics from task-outcomes.jsonl
- Success rate, CI first-pass rate, repair cycles
- Model ROI, reviewer value, memory reuse
- Recommendations (if sample size is sufficient)
- Trend comparison with previous month (when available)

## Generation

```bash
bash .opencode/scripts/summarize-agent-quality.sh --days 30 > .opencode/reports/agent-quality/$(date +%Y-%m)-scorecard.md
```

## Privacy

- No individual task details that could expose prompts or code
- No secrets, API keys, or credentials
- Aggregate metrics only
- See `.opencode/docs/telemetry-policy.md` for full policy
