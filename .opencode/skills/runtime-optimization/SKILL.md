---
description: "Improve execution efficiency through parallelization, caching, and smart skipping"
---

# Runtime Optimization

> **Version:** 1.0
> **Scope:** Execution efficiency improvements — parallelization, caching, skip logic
> **Integration:** Works with lane budgets, gate validation, and multi-repo execution

## When to Activate

Task keywords: `runtime optimization`, `execution efficiency`, `parallel`, `cache`, `skip redundant`, `optimize execution`, `command deduplication`, `smart skip`

## The Problem

Agents waste time and resources by:
1. Running checks sequentially when they could run in parallel
2. Re-running checks that already passed
3. Executing redundant commands
4. Not caching results within session
5. Following protocol steps mechanically when shortcuts exist

## Optimization Strategies

### 1. Parallel Execution

**Before (sequential):**
```bash
npm run lint
npm run typecheck
npm run test
npm run build
```

**After (parallel when independent):**
```bash
# Lint and typecheck can run in parallel
npm run lint & npm run typecheck & wait
# Then test (depends on types)
npm run test
# Then build (depends on all above)
npm run build
```

**Rules for parallelization:**
- Can parallelize: Independent checks (lint + typecheck)
- Must sequence: Dependent checks (test after typecheck, build after all)
- Never parallelize: Commands that modify shared state

### 2. Smart Skip Logic

**Skip rules:**

| Situation | Skip | Reason |
|---|---|---|
| Lint passed in last step | Skip if no code changed | Redundant |
| Typecheck passed, no type changes | Skip | Redundant |
| Test passed, only comments changed | Skip | No behavior change |
| Build passed, no source changed | Skip | Redundant |
| File already read this session | Use cached content | Redundant I/O |
| Gate already passed this session | Skip unless code changed | Redundant |

**Implementation:**
```
Session state tracking:
- Files read: {path → content_hash}
- Gates passed: {gate_name → timestamp}
- Checks run: {check_name → result, inputs_hash}
```

### 3. Command Deduplication

**Before (duplicate):**
```bash
# Step 1: Check file exists
ls src/utils/file.ts
# Step 2: Read file
cat src/utils/file.ts
# Step 3: Check file again (unnecessary)
ls src/utils/file.ts
```

**After (deduplicated):**
```bash
# Step 1: Read file (also confirms existence)
cat src/utils/file.ts
# Use cached result for existence check
```

### 4. Session Caching

**Cache structure:**
```json
{
  "files": {
    "path/to/file.ts": {
      "content": "...",
      "hash": "abc123",
      "read_at": "2026-04-21T15:00:00Z"
    }
  },
  "checks": {
    "lint": { "passed": true, "at": "2026-04-21T15:01:00Z" },
    "typecheck": { "passed": true, "at": "2026-04-21T15:01:30Z" }
  },
  "decisions": {
    "lane": "FAST",
    "risk_score": 2
  }
}
```

**Cache invalidation:**
- File cache: Invalidate when file modified
- Check cache: Invalidate when source files changed
- Decision cache: Never invalidate during session

### 5. Efficient File Operations

**Batch operations:**
```bash
# Before: Multiple separate operations
ls file1.ts
ls file2.ts
ls file3.ts

# After: Single operation
ls file1.ts file2.ts file3.ts
```

**Smart file selection:**
```
# Before: Read entire directory
ls -la src/

# After: Targeted read
ls src/utils/*.ts  # Only what's needed
```

## Integration with Existing Systems

### Lane Budgets

This skill helps stay within lane budgets:
- DIRECT: 4 commands → Optimized to 2-3
- FAST: 8 commands → Optimized to 4-6
- STANDARD: 16 commands → Optimized to 10-12
- HIGH-RISK: 20 commands → Optimized to 14-16

### Gate Validation

Works with gate validation (VERIFIED/PLACEHOLDER/SKIPPED):
- Skips PLACEHOLDER gates when no real tooling
- Re-runs VERIFIED gates only when source changed
- Parallelizes independent gates

### Multi-Repo Execution

Optimizes multi-repo workflows:
- Parallelizes independent repo operations
- Caches shared configuration across repos
- Reuses common checks across repos

## Rules

### Do
- ✅ Parallelize independent checks
- ✅ Skip redundant verification
- ✅ Cache file contents within session
- ✅ Batch similar operations
- ✅ Track session state to avoid duplicates

### Don't
- ❌ Parallelize dependent operations
- ❌ Skip required verification
- ❌ Cache stale data across sessions
- ❌ Sacrifice correctness for speed
- ❌ Skip protocol steps that add value

## Performance Metrics

Track these to measure optimization effectiveness:

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| Commands per task | Baseline | Track | -20% |
| Redundant operations | Baseline | Track | -50% |
| Parallel execution rate | 0% | Track | >30% |
| Cache hit rate | 0% | Track | >40% |

## Output format

Produce an optimization report in this exact format:

```
## Runtime Optimization Report

**Session:** <session ID or description>
**Optimizations applied:** <list>

### Metrics
| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Commands used | <count> | <count> | <delta> |
| Parallel operations | <count> | <count> | <delta> |
| Cache hits | <count> | <count> | <delta> |
| Skipped redundant ops | <count> | <count> | <delta> |

### Techniques used
- <technique>: <description and impact>

### Verification
- [ ] No correctness sacrificed for speed
- [ ] All required verification steps completed
- [ ] Cache invalidated when source changed
- [ ] No stale data used across sessions
```

## Out of Scope

This skill does NOT:
- Replace application-level performance optimization (use performance/SKILL.md)
- Skip required protocol steps that add value
- Cache stale data across sessions
- Sacrifice correctness for speed
- Replace token optimization strategies (use token-optimization/SKILL.md)
