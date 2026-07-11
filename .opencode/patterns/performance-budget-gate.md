# Performance Budget Gate

> **Pattern:** `.opencode/patterns/performance-budget-gate.md`
> **Version:** 1.0.0
> **Created:** 2026-05-22
> **Status:** Active

## Purpose

Defines the lightweight performance budget gate that prevents obvious quality regressions. This gate ensures that visual improvements do not come at the cost of unacceptable performance degradation.

## When to Apply

Trigger when:
- Any visual change is made that could affect bundle size
- New dependencies are added
- Before any production deploy of a user-facing surface
- When a stakeholder requests performance review

## Budget Targets

| Metric | Target | Tool |
|---|---|---|
| Performance | >= 85 | Lighthouse |
| Accessibility | >= 95 | Lighthouse |
| Best Practices | >= 90 | Lighthouse |
| First Contentful Paint | <= 1.8s | Lighthouse |
| Largest Contentful Paint | <= 2.5s | Lighthouse |
| Cumulative Layout Shift | <= 0.1 | Lighthouse |
| Total Bundle Size | No major regression | `pnpm build` output |

## Implementation

### Lightweight Lighthouse Check

Run against a production build (not dev server):

```bash
# 1. Build production
pnpm build

# 2. Start preview server
pnpm preview &

# 3. Run Lighthouse
pnpm dlx lighthouse http://localhost:3000 \
  --output=json \
  --output-path=lighthouse-report.json \
  --chrome-flags="--headless" \
  --only-categories=performance,accessibility,best-practices

# 4. Check results
node scripts/check-lighthouse-budget.js lighthouse-report.json
```

### Budget Check Script

```javascript
// scripts/check-lighthouse-budget.js
const fs = require('fs');
const report = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));

const categories = report.categories;
const audits = report.audits;

const checks = [
  { name: 'Performance', score: categories.performance.score * 100, min: 85 },
  { name: 'Accessibility', score: categories.accessibility.score * 100, min: 95 },
  { name: 'Best Practices', score: categories['best-practices'].score * 100, min: 90 },
  { name: 'FCP', score: audits['first-contentful-paint'].numericValue, min: 1800, lower: true },
  { name: 'LCP', score: audits['largest-contentful-paint'].numericValue, min: 2500, lower: true },
  { name: 'CLS', score: audits['cumulative-layout-shift'].numericValue, min: 0.1, lower: true },
];

let passed = true;
for (const check of checks) {
  const ok = check.lower ? check.score <= check.min : check.score >= check.min;
  if (!ok) {
    console.error(`FAIL: ${check.name} = ${check.score} (min: ${check.min}${check.lower ? ', lower is better' : ''})`);
    passed = false;
  } else {
    console.log(`PASS: ${check.name} = ${check.score}`);
  }
}

process.exit(passed ? 0 : 1);
```

## Bundle Size Check

After `pnpm build`, check the output:

```bash
# Check total JS bundle size
ls -la .next/static/chunks/*.js | awk '{sum += $5} END {print "Total JS: " sum/1024 " KB"}'

# Check for unexpectedly large chunks
find .next/static/chunks -name "*.js" -size +500k -exec ls -lh {} \;
```

## Quality Checklist

- [ ] Lighthouse performance >= 85
- [ ] Lighthouse accessibility >= 95
- [ ] Lighthouse best practices >= 90
- [ ] FCP <= 1.8s
- [ ] LCP <= 2.5s
- [ ] CLS <= 0.1
- [ ] No major bundle size regression
- [ ] No unexpectedly large chunks (>500KB)

## Related Patterns

- `visual-quality-gate.md` — Visual quality gate definition
- `a11y-production-gate.md` — Accessibility gate
- `executive-product-review-rubric.md` — Executive review scoring
