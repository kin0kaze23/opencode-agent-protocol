---
name: performance
description: Frontend and backend performance optimization
---

# Performance Skill

Optimization guide for React, Next.js, and Node.js applications.

## Procedure

Before optimizing, read the following:

1. Read the repo's `WORKSPACE_MAP.md` to confirm the stack and dev port
2. Read the target module/component to identify the performance bottleneck
3. Read the existing performance monitoring setup (if any) in the codebase
4. Run a baseline measurement (Lighthouse, bundle analysis, or API timing) before making changes

Then apply optimizations following these patterns:

1. Start with quick wins: images, fonts, third-party scripts, caching
2. Apply component-level optimizations: memo, code splitting, virtualization
3. Optimize data fetching: server components, static generation, streaming
4. Fix database queries: indexing, eager loading, pagination
5. Measure after each change — only keep optimizations that show measurable improvement

---

## React 19 / Vite Performance

### Component Optimization
```typescript
// Memoize expensive computations
import { useMemo, useCallback } from 'react'

function ExpensiveComponent({ data }) {
  const processed = useMemo(() =>
    data.map(item => heavyCalculation(item)),
    [data]
  )

  const handleClick = useCallback((id: string) => {
    console.log(id)
  }, [])

  return <List items={processed} onClick={handleClick} />
}
```

### Code Splitting
```typescript
import { lazy, Suspense } from 'react'

const HeavyChart = lazy(() => import('./HeavyChart'))

function Dashboard() {
  return (
    <Suspense fallback={<ChartSkeleton />}>
      <HeavyChart data={data} />
    </Suspense>
  )
}
```

### Image Optimization
```typescript
import { Image } from '@unpic/react'

// Automatic WebP/AVIF, lazy loading, srcset
<Image
  src="https://example.com/image.jpg"
  layout="constrained"
  width={800}
  height={600}
/>
```

## Next.js 14 Performance

### Server Components (Default)
```typescript
// This is a Server Component by default
async function Page() {
  const data = await fetchData() // No client JS sent

  return <Display data={data} />
}
```

### Static Generation
```typescript
// Generate at build time
export async function generateStaticParams() {
  const posts = await getPosts()
  return posts.map(post => ({ slug: post.slug }))
}
```

### Streaming
```typescript
import { Suspense } from 'react'

async function Page() {
  return (
    <div>
      <Hero />
      <Suspense fallback={<Skeleton />}>
        <SlowComponent />
      </Suspense>
    </div>
  )
}
```

## Bundle Analysis

```bash
# Analyze bundle
npm run build && npx vite-bundle-visualizer

# Check with esbuild
npx esbuild bundle-analyzer dist/client/assets/*.js
```

## Backend Performance (Express/Hono)

### Caching
```typescript
import { cors, cache } from 'hono'

// Redis cache
app.use('*', cache({ cacheName: 'api-cache' }))

// In-memory for hot paths
const cache = new Map<string, { data: unknown; expiry: number }>()

function getCached(key: string) {
  const item = cache.get(key)
  if (item && item.expiry > Date.now()) {
    return item.data
  }
  return null
}
```

### Database Query Optimization
```typescript
// N+1 problem - BAD
const users = await db.select().from(users)
for (const user of users) {
  user.posts = await db.select().from(posts).where(eq(posts.userId, user.id))
}

// Eager loading - GOOD
const users = await db.query.users.findMany({
  with: {
    posts: true
  }
})
```

### Connection Pooling (PostgreSQL)
```typescript
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL + '?connection_limit=10'
    }
  }
})
```

## Database Performance

### Indexing Strategy
```sql
-- For frequently queried columns
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

-- Composite index
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
```

### Query Optimization
```typescript
// Select only needed columns
const users = await db.query.users.findMany({
  columns: { id: true, name: true } // Not all columns
})

// Pagination
const page = await db.query.users.findMany({
  limit: 20,
  offset: (page - 1) * 20
})
```

## Performance Metrics

| Metric | Target | Tool |
|--------|--------|------|
| LCP | < 2.5s | Lighthouse |
| FID | < 100ms | Lighthouse |
| CLS | < 0.1 | Lighthouse |
| TTFB | < 600ms | Lighthouse |
| API Response | < 200ms | Custom |

## Monitoring

```bash
# Core Web Vitals
npm install web-vitals

# Node.js profiling
node --inspect server.js
# Then open chrome://inspect
```

## Quick Wins

1. **Images**: Use WebP, lazy load, specify dimensions
2. **Fonts**: Use `font-display: swap`, preload critical
3. **Third-party**: Defer non-critical scripts
4. **API**: Implement caching, pagination
5. **Bundle**: Code split, remove unused deps

## Output format

Produce a performance report in this exact format:

```
## Performance Optimization — <module/feature name>

**Stack:** <React / Next.js / Express / Database>
**Baseline:** <metric name and value before optimization>

### Optimizations applied
- <optimization>: <what was changed and why>
- <optimization>: <what was changed and why>

### Results
- <metric name>: <baseline> → <after> (<improvement>)

### Verification
- [ ] Lighthouse score improved (or unchanged if not UI)
- [ ] Bundle size decreased (or unchanged if not applicable)
- [ ] No regressions in functionality
- [ ] No regressions in accessibility
```

## Out of Scope

This skill does NOT:
- Fix correctness bugs masked as performance issues (that is /debug)
- Replace database migration strategies (that is migration-patterns/SKILL.md)
- Audit infrastructure costs or cloud resource allocation
- Replace performance-profiling/SKILL.md for detailed profiling workflows
- Write load tests or stress tests (that is testing-validation/SKILL.md)
---

## Lighthouse / Core Web Vitals (v4.9.0 — Advisory)

> Lighthouse is ADVISORY in v4.9.0. Not a blocking gate.
> Safety: Use repo-native setup. Do NOT install dependencies without approval.

### When to Run

- UI surface changes (landing pages, dashboards, onboarding)
- Performance-sensitive features (data-heavy pages, image-heavy layouts)
- Ship readiness check for qualifying repos

### How to Run

**Use repo-native Lighthouse/LHCI command if available.**

Check for existing setup:
```bash
# Check for LHCI config
ls .lighthouserc.js .lighthouserc.json lighthouserc.* 2>/dev/null

# Check for Lighthouse script in package.json
grep -i lighthouse package.json 2>/dev/null

# Check for LHCI binary
which lhci 2>/dev/null
```

If repo-native command exists, use it. Example:
```bash
# If LHCI configured
lhci autorun

# If Lighthouse available directly
npx lighthouse <url> --output=json --output-path=reports/lighthouse.json
```

### If Dependencies Are Missing

**Do NOT install automatically.**

Mark as `NOT_RUN` with reason:
```
Lighthouse: NOT_RUN — Lighthouse/LHCI not available in this repo.
  Proposed setup: npm install -D @lhci/cli (requires approval)
```

### Core Web Vitals Targets (Reference)

| Metric | Good | Needs Improvement | Poor |
|---|---|---|---|
| LCP | < 2.5s | < 4.0s | > 4.0s |
| INP | < 200ms | < 500ms | > 500ms |
| CLS | < 0.1 | < 0.25 | > 0.25 |

**Note:** FID replaced by INP in Core Web Vitals 2024.

### Evidence Format

```markdown
## Lighthouse / Core Web Vitals — [Page/URL]

Result: PASS / FAIL / NOT_RUN (<reason>)

Performance: <score> / 90 target
Accessibility: <score> / 90 target
Best Practices: <score> / 90 target
SEO: <score> / 90 target

Core Web Vitals:
- LCP: <value> / 2.5s target
- INP: <value> / 200ms target
- CLS: <value> / 0.1 target

Report: <path or "not generated">
```

### Integration

- Referenced by `ui-ux-quality-audit` for performance section
- Referenced by `verification-before-completion` for structured UI evidence
- Advisory only in v4.9.0 — does not block ship
- May become blocking in v5.0
