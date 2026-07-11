---
description: "Objective performance measurement for web apps, APIs, and databases"
---

# Performance Profiling

> **Version:** 1.0
> **Scope:** Objective performance measurement for web apps, APIs, and databases
> **Integration:** Works with `/gates`, `/review`, and deployment verification

## When to Activate

Task keywords: `performance`, `slow`, `optimize`, `faster`, `lighthouse`, `bundle`, `bundle size`, `core web vitals`, `LCP`, `CLS`, `FID`, `INP`, `TTFB`, `query`, `database performance`, `API latency`, `profiling`, `benchmark`

## Web Performance (Lighthouse)

### Run Lighthouse Audit

```bash
# CLI audit
npx lighthouse <url> --output json --output-path ./lighthouse-report.json

# CI-friendly
npx lighthouse <url> --output json --quiet --chrome-flags="--headless"
```

### Performance Budget

| Metric | Target | Critical |
|---|---|---|
| **Performance Score** | ≥90 | <75 |
| **LCP (Largest Contentful Paint)** | <2.5s | >4.0s |
| **CLS (Cumulative Layout Shift)** | <0.1 | >0.25 |
| **INP (Interaction to Next Paint)** | <200ms | >500ms |
| **TTFB (Time to First Byte)** | <800ms | >1800ms |

### Bundle Analysis

```bash
# Next.js
ANALYZE=true npm run build

# Vite
npx vite-bundle-visualizer

# Webpack
npx webpack-bundle-analyzer dist/stats.json
```

### Bundle Size Budget

| Type | Budget | Critical |
|---|---|---|
| **Total JS** | <300KB | >500KB |
| **Total CSS** | <50KB | >100KB |
| **Largest chunk** | <100KB | >200KB |
| **Initial load** | <200KB | >400KB |

## API Performance

### Measure API Latency

```bash
# Single request
curl -w "@curl-format.txt" -o /dev/null -s <api-url>

# Multiple requests (average)
for i in {1..10}; do
  curl -s -o /dev/null -w "%{time_total}\n" <api-url>
done | awk '{sum+=$1} END {print "Average: " sum/NR "s"}'
```

### API Performance Budget

| Metric | Target | Critical |
|---|---|---|
| **P50 Latency** | <200ms | >500ms |
| **P95 Latency** | <500ms | >1000ms |
| **P99 Latency** | <1000ms | >2000ms |
| **Error Rate** | <1% | >5% |

## Database Performance

### Query Analysis

```bash
# PostgreSQL - Enable query logging
EXPLAIN ANALYZE <query>;

# Prisma - Enable query logging
export DEBUG="prisma:query"
```

### Database Performance Budget

| Metric | Target | Critical |
|---|---|---|
| **Query Time (simple)** | <10ms | >100ms |
| **Query Time (complex)** | <100ms | >500ms |
| **Connection Pool Usage** | <80% | >95% |
| **Slow Queries (per hour)** | <10 | >100 |

## Integration with Development Workflow

### Pre-Deployment Performance Check

Before deploying to production:

1. Run Lighthouse on preview deployment
2. Check bundle size against budget
3. Run API latency tests
4. If any metric exceeds critical threshold: block deployment

### Post-Deployment Performance Monitoring

After deploying to production:

1. Run Lighthouse on production URL
2. Compare against previous deployment
3. If regression >10%: alert and consider rollback
4. Log performance metrics to vault

### Performance Regression Detection

Compare current deployment against baseline:

| Metric | Baseline | Current | Change | Status |
|---|---|---|---|---|
| Lighthouse Score | 92 | 88 | -4.3% | ⚠️ Warning |
| Bundle Size | 245KB | 280KB | +14.3% | 🔴 Critical |
| API P95 | 320ms | 450ms | +40.6% | 🔴 Critical |

## Optimization Recommendations

### Common Issues and Fixes

| Issue | Fix |
|---|---|
| Large bundle size | Code splitting, tree shaking, remove unused deps |
| Slow LCP | Optimize images, preload critical resources |
| High CLS | Set explicit dimensions, avoid layout shifts |
| Slow API | Add caching, optimize queries, add indexes |
| Slow DB queries | Add indexes, optimize queries, add connection pooling |

### Performance Checklist

Before claiming performance improvement:

- [ ] Measured baseline before change
- [ ] Measured result after change
- [ ] Confirmed improvement is statistically significant
- [ ] Verified no regression in other metrics
- [ ] Documented optimization and results

## Do Not

- Claim performance improvement without measurements
- Optimize without measuring baseline first
- Deploy with bundle size exceeding critical budget
- Ignore Core Web Vitals regressions
- Optimize prematurely without data-driven justification
- Skip rollback planning for performance-critical deployments

## Output format

Produce a profiling report in this exact format:

```
## Performance Profiling — <project/module name>

**Tool:** <Lighthouse / bundle-analyzer / API profiler / DB query profiler>
**Baseline date:** <date>

### Metrics
| Metric | Baseline | Current | Change | Status |
|--------|----------|---------|--------|--------|
| <metric> | <value> | <value> | <delta> | ✅/⚠️/🔴 |

### Bottlenecks identified
- <bottleneck>: <location and impact>

### Recommendations
- <recommendation>: <expected improvement>

### Verification
- [ ] Baseline measured before change
- [ ] Result measured after change
- [ ] Improvement is statistically significant
- [ ] No regression in other metrics
```

## Out of Scope

This skill does NOT:
- Fix performance bugs caused by incorrect logic (that is /debug)
- Replace database migration strategies (that is migration-patterns/SKILL.md)
- Audit infrastructure costs or cloud resource allocation
- Replace the general performance/SKILL.md for optimization guidance
- Write load tests or stress tests (that is testing-validation/SKILL.md)
- Profile production systems without explicit approval
