---
description: "Reduce token consumption without sacrificing output quality"
---

# Token Usage Optimization

> **Version:** 1.0
> **Scope:** Proactive token consumption reduction without sacrificing output quality
> **Integration:** Works with progressive context loading, lane budgets, and cost telemetry

## When to Activate

Task keywords: `token usage`, `token budget`, `optimize tokens`, `reduce tokens`, `token efficiency`, `cost optimization`, `context management`, `summarize context`

## The Problem

Agents waste tokens by:
1. Reading files they don't need
2. Re-reading the same file multiple times in one session
3. Verbose outputs when summaries would suffice
4. Running redundant checks
5. Keeping stale context instead of refreshing

## Token Budget Enforcement

### Soft Warning Thresholds (from brain-config.json)

| Lane | Threshold | Action |
|------|-----------|--------|
| DIRECT | 50,000 | Warn user if approaching |
| FAST | 50,000 | Warn user if approaching |
| STANDARD | 150,000 | Warn user, suggest summarizing context |
| HIGH-RISK | 300,000 | Warn user, suggest compaction |

### Active Reduction Strategies

#### 1. Summarize Instead of Re-Read

**Before (wasteful):**
```
Read file.ts (1200 lines)
...later in session...
Read file.ts again (1200 lines)
```

**After (optimized):**
```
Read file.ts once
Store key findings in session memory:
- Function signatures
- Key interfaces
- Dependencies
Later: Reference findings instead of re-reading
```

#### 2. Progressive File Reading

**Before (wasteful):**
```
Read entire 500-line file to find one function
```

**After (optimized):**
```
Read first 50 lines (imports, exports)
If target not found: Read specific section
If target found: Stop reading
```

#### 3. Context Compression

When context approaches 70% capacity:

1. **Identify essential context:**
   - Current task objective
   - Active contract (PLAN.md)
   - Key decisions made
   - Current state (NOW.md)

2. **Compress non-essential context:**
   - Replace full file reads with summaries
   - Replace verbose outputs with key findings
   - Replace repeated information with references

3. **Discard stale context:**
   - Previous session data (use NOW.md instead)
   - Completed verification steps
   - Outdated hypotheses

#### 4. Output Optimization

| Situation | Verbose Output | Optimized Output |
|---|---|---|
| Gate results | Full tool output | "lint: PASS (exit 0)" |
| File content | Entire file | Key sections only |
| Error messages | Full stack trace | Root cause + line number |
| Command output | All stdout/stderr | Success/failure + key info |

## Token Tracking

### Per-Task Token Budget

| Task Type | Estimated Tokens | Actual | Variance |
|---|---|---|---|
| Typo fix (DIRECT) | 2,000 | Track | Compare |
| Utility function (FAST) | 8,000 | Track | Compare |
| Feature (STANDARD) | 25,000 | Track | Compare |
| Complex (HIGH-RISK) | 50,000+ | Track | Compare |

### Session Token Summary

At session end (or checkpoint):

```
Token Usage Summary:
  Session total: 45,230 tokens
  Budget (STANDARD): 150,000 tokens
  Utilization: 30% ✅
  Top consumers:
    - File reads: 18,000 (40%)
    - Code generation: 15,000 (33%)
    - Analysis: 8,000 (18%)
    - Other: 4,230 (9%)
```

## Integration with Existing Systems

### Progressive Context Loading

This skill works WITH progressive context loading (already in brain-config.json):
- Progressive loading: Reads minimum at startup
- Token optimization: Continues optimization throughout session

### Lane Budgets

This skill respects lane budgets:
- DIRECT: 4 commands max
- FAST: 8 commands max
- STANDARD: 16 commands max
- HIGH-RISK: 20 commands max

### Cost Telemetry

This skill uses cost telemetry (already in brain-config.json):
- Reports when runtime exposes token usage
- Never fabricates token counts
- Uses UNAVAILABLE when not exposed

## Rules

### Do
- ✅ Summarize instead of re-reading
- ✅ Read files progressively (top-down, stop when found)
- ✅ Compress context when approaching limits
- ✅ Track token usage when available
- ✅ Report token summary at checkpoint

### Don't
- ❌ Re-read files already in context
- ❌ Output full tool output when summary suffices
- ❌ Fabricate token counts
- ❌ Skip required verification to save tokens
- ❌ Compromise output quality for token savings

## Output format

Produce a token optimization report in this exact format:

```
## Token Optimization Report

**Session:** <session ID or description>

### Token usage
- Input tokens: <count or UNAVAILABLE>
- Output tokens: <count or UNAVAILABLE>
- Cache read: <count or UNAVAILABLE>
- Estimated cost: <amount or UNAVAILABLE>

### Optimizations applied
- <optimization>: <description and tokens saved>

### Techniques used
- Progressive reading: <yes/no>
- Context compression: <yes/no>
- Output truncation: <yes/no>
- Smart skip: <yes/no>

### Verification
- [ ] No required information lost
- [ ] Output quality maintained
- [ ] Token counts accurate (not fabricated)
```

## Out of Scope

This skill does NOT:
- Replace application-level performance optimization (use performance/SKILL.md)
- Skip required verification steps to save tokens
- Fabricate token counts when runtime does not expose them
- Replace runtime optimization for command efficiency (use runtime-optimization/SKILL.md)
- Optimize token usage at the cost of output correctness
