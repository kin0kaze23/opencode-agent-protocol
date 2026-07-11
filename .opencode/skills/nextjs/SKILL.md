---
name: nextjs
description: Next.js 14+ full-stack development - App Router, Server Components, API routes
---

# Next.js Full-Stack Skill

Comprehensive guide for Next.js 14+ development using App Router.

## Procedure

Before writing Next.js code, read the following:

1. Read the repo's `AGENTS.md` to confirm the Next.js version, dev port, and deploy target
2. Read the `app/` directory structure to understand the current routing setup
3. Read `package.json` to confirm scripts, dependencies, and Next.js version
4. Read 1-2 existing page/component files to match the project's patterns

Then execute the Next.js development:

1. Use Server Components by default (only add `'use client'` when interactivity is required)
2. Use the App Router file conventions (`page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`)
3. Use route handlers (`route.ts`) for API endpoints
4. Apply performance best practices (streaming, static generation, code splitting)
5. Run gates before shipping: `lint -> typecheck -> build`

---

## Project Context

This skill is used for **ClearPathOS** — the primary Next.js project in this portfolio.

## Prerequisites

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

## Next.js 14+ Key Patterns

### App Router Structure

```
app/
├── page.tsx              # Route page (React Server Component)
├── layout.tsx            # Root/layout (must be Server Component)
├── loading.tsx           # Loading UI
├── error.tsx             # Error boundary
├── not-found.tsx         # 404 page
├── globals.css           # Global styles
├── api/
│   └── route.ts          # API Route Handler (GET, POST, etc.)
└── [folder]/
        └── page.tsx      # Dynamic route segment
```

### Server Components vs Client Components

**Server Components (Default):**
- `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`
- Run on server — no client JS bundle
- Can directly access: databases, file system, secrets

**Client Components:**
- Add `'use client'` at top
- Use for: interactivity, hooks, browser APIs
- Example: `components/Button.tsx`

```tsx
'use client'

import { useState } from 'react'

export function Counter() {
  const [count, setCount] = useState(0)
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>
}
```

### Data Fetching

**Server Components (recommended):**
```tsx
async function getData() {
  const res = await fetch('https://api.example.com/data', {
    cache: 'no-store' // or 'force-cache' for static
  })
  return res.json()
}

export default async function Page() {
  const data = await getData()
  return <div>{data.name}</div>
}
```

**Client Components:**
```tsx
'use client'

import { useEffect, useState } from 'react'

export function DataComponent() {
  const [data, setData] = useState(null)

  useEffect(() => {
    fetch('/api/data').then(r => r.json()).then(setData)
  }, [])

  return <div>{data?.name}</div>
}
```

### API Routes (Route Handlers)

```ts
// app/api/users/route.ts
import { NextResponse } from 'next/server'

export async function GET() {
  const users = await db.user.findMany()
  return NextResponse.json(users)
}

export async function POST(request: Request) {
  const body = await request.json()
  const user = await db.user.create({ data: body })
  return NextResponse.json(user)
}
```

### Dynamic Segments

```tsx
// app/users/[id]/page.tsx
export default async function UserPage({
  params
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const user = await getUser(id)
  return <h1>{user.name}</h1>
}
```

### Static Site Generation (SSG)

```tsx
// Generate static paths at build time
export async function generateStaticParams() {
  const posts = await getPosts()
  return posts.map((post) => ({ slug: post.slug }))
}
```

### Incremental Static Regeneration (ISR)

```tsx
export const revalidate = 60 // Revalidate every 60 seconds

export default async function Page() {
  const data = await getData()
  return <div>{data.content}</div>
}
```

## ClearPathOS Specific Patterns

### Database with Prisma

```ts
// lib/prisma.ts
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient }
export const prisma = globalForPrisma.prisma || new PrismaClient()
if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
```

### Authentication with Clerk

```tsx
// middleware.ts
import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server'

const isProtectedRoute = createRouteMatcher(['/dashboard(.*)'])

export default clerkMiddleware((auth, req) => {
  if (isProtectedRoute(req)) auth().protect()
})

export const config = {
  matcher: ['/((?!.*\\..*|_next).*)', '/', '/(api|trpc)(.*)'],
}
```

### Environment Variables

```env
# .env.local
DATABASE_URL="postgresql://user:pass@localhost:5432/clearpath"
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_..."
CLERK_SECRET_KEY="sk_test_..."
```

## Common Issues & Solutions

### Hydration Mismatch

**Problem:** Server and client HTML don't match

**Solution:** Use `suppressHydrationWarning` or ensure client-side rendering matches server:

```tsx
<div suppressHydrationWarning>{new Date().toLocaleTimeString()}</div>
```

### `params` is a Promise

**Problem:** Next.js 15+ requires awaiting params

**Solution:**
```tsx
// Next.js 15+
export default async function Page({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params
}
```

### Font Optimization

```tsx
import { Inter } from 'next/font/google'
const inter = Inter({ subsets: ['latin'] })

export default function RootLayout({ children }) {
  return (
    <html lang="en" className={inter.className}>
      <body>{children}</body>
    </html>
  )
}
```

## Testing Next.js

```bash
# Unit tests with Vitest
npm run test

# E2E with Playwright
npx playwright test

# Component tests
npm run test:ui
```

## Build & Deployment

```bash
# Production build
npm run build

# Analyze bundle
npm run analyze

# Type check
npm run typecheck
```

## Useful Commands

| Command | Purpose |
|---------|---------|
| `npm run dev` | Start dev server (port 3000) |
| `npm run build` | Production build |
| `npm run start` | Start production server |
| `npm run lint` | Run ESLint |
| `npm run typecheck` | Run TypeScript check |

## Output format

Produce a Next.js development report in this exact format:

```
## Next.js Development — <route/component name>

**Route:** <app path or component path>
**Type:** <Server Component / Client Component / Route Handler / Layout>

### Changes
- <file>: <what was added or modified>

### Next.js checks
- [ ] Server Component used by default (only client when needed)
- [ ] Route conventions followed (page.tsx, layout.tsx, etc.)
- [ ] `params` awaited if Next.js 15+
- [ ] No hydration mismatches expected

### Verification
- [ ] `npm run dev` — page loads without errors
- [ ] `npm run typecheck` — no type errors
- [ ] `npm run build` — production build succeeds
```

## Out of Scope

This skill does NOT:
- Write database schemas or migrations (that is database/SKILL.md)
- Fix authentication bugs in Clerk or other providers (that is /debug)
- Replace performance profiling and optimization (that is performance/SKILL.md)
- Audit security of API routes (that is security/SKILL.md)
- Write tests (that is testing-validation/SKILL.md)
- Deploy to production (that is deployment/SKILL.md)

## Related Skills

- [[database]] — PostgreSQL + Prisma patterns
- [[testing]] — Test patterns
- [[performance]] — Optimization tips