---
description: "Assess code quality, test coverage, dependency health, and complexity"
---

# Technical Debt Assessment

> **Version:** 1.0
> **Scope:** Automated assessment of code quality, test coverage, dependency health, and complexity
> **Integration:** Works with `/review`, `/checkpoint`, and periodic repo health checks

## When to Activate

Task keywords: `technical debt`, `code quality`, `complexity`, `refactor`, `debt`, `stale`, `outdated dependencies`, `test coverage`, `code smell`, `maintainability`

## Assessment Categories

### 1. Code Complexity

**Tools:** `eslint --ext .ts,.tsx --config .eslintrc.json`, `ts-prune`, `madge`

**Metrics:**
- Cyclomatic complexity per function
- File length (lines of code)
- Function length (lines of code)
- Nesting depth
- Number of imports per file

**Thresholds:**

| Metric | Good | Warning | Critical |
|---|---|---|---|
| Cyclomatic complexity | <10 | 10-20 | >20 |
| File length | <300 lines | 300-500 lines | >500 lines |
| Function length | <50 lines | 50-100 lines | >100 lines |
| Nesting depth | <4 levels | 4-6 levels | >6 levels |
| Imports per file | <15 | 15-25 | >25 |

### 2. Test Coverage

**Tools:** `vitest --coverage`, `jest --coverage`

**Metrics:**
- Statement coverage
- Branch coverage
- Function coverage
- Line coverage

**Thresholds:**

| Metric | Good | Warning | Critical |
|---|---|---|---|
| Statement coverage | >80% | 60-80% | <60% |
| Branch coverage | >70% | 50-70% | <50% |
| Function coverage | >80% | 60-80% | <60% |
| Line coverage | >80% | 60-80% | <60% |

### 3. Dependency Health

**Tools:** `npm outdated`, `npm audit`, `depcheck`

**Metrics:**
- Outdated dependencies
- Security vulnerabilities
- Unused dependencies
- Missing dependencies

**Thresholds:**

| Metric | Good | Warning | Critical |
|---|---|---|---|
| Outdated deps | <5 | 5-15 | >15 |
| Critical vulnerabilities | 0 | 1-2 | >2 |
| Unused deps | 0 | 1-3 | >3 |
| Deps not updated >1 year | <3 | 3-10 | >10 |

### 4. Code Duplication

**Tools:** `jscpd`, `eslint-plugin-no-duplicate-imports`

**Metrics:**
- Duplicate code percentage
- Duplicate lines count
- Duplicate blocks count

**Thresholds:**

| Metric | Good | Warning | Critical |
|---|---|---|---|
| Duplication % | <5% | 5-10% | >10% |

### 5. Dead Code

**Tools:** `ts-prune`, `knip`

**Metrics:**
- Unused exports
- Unused imports
- Unreachable code

**Thresholds:**

| Metric | Good | Warning | Critical |
|---|---|---|---|
| Unused exports | 0 | 1-5 | >5 |
| Unused imports | 0 | 1-10 | >10 |

## Assessment Execution

### Run Full Assessment

```bash
# 1. Complexity
npx madge --circular --warning src/

# 2. Test Coverage
npm run test -- --coverage

# 3. Dependencies
npm outdated
npm audit
npx depcheck

# 4. Duplication
npx jscpd src/ --threshold 5

# 5. Dead Code
npx ts-prune
npx knip
```

### Generate Assessment Report

```markdown
# Technical Debt Assessment — <repo>

## Summary
- **Overall Health:** Good / Warning / Critical
- **Complexity Score:** X/100
- **Test Coverage:** X%
- **Dependency Health:** X/100
- **Duplication:** X%
- **Dead Code:** X issues

## Critical Issues
1. <Issue 1>
2. <Issue 2>

## Warning Issues
1. <Issue 1>
2. <Issue 2>

## Recommendations
1. <Recommendation 1>
2. <Recommendation 2>
```

## Integration with Development Workflow

### Pre-Refactor Assessment

Before refactoring:
1. Run full assessment
2. Document current state
3. Identify specific areas to improve
4. Set measurable goals

### Post-Refactor Assessment

After refactoring:
1. Run full assessment again
2. Compare against baseline
3. Verify improvement in target areas
4. Document results

### Periodic Assessment

Run assessment:
- Weekly for active repos
- Monthly for stable repos
- Before major releases
- After significant changes

## Debt Prioritization

### Priority Matrix

| Impact | Effort | Priority |
|---|---|---|
| High | Low | Do Now |
| High | High | Plan |
| Low | Low | Fill In |
| Low | High | Avoid |

### Common High-Impact, Low-Effort Fixes

- Remove unused dependencies
- Fix critical security vulnerabilities
- Add missing return type annotations
- Extract long functions
- Add missing test coverage for critical paths

## Do Not

- Claim code quality improvement without measurements
- Refactor without measuring current state first
- Ignore critical security vulnerabilities
- Deploy with test coverage below critical threshold
- Add dependencies without checking health
- Leave dead code in the codebase
