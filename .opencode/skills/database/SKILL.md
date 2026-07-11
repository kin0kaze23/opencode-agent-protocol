---
name: database
description: PostgreSQL, Prisma, Drizzle best practices
---

# Database Skill

Database guide for PostgreSQL, Prisma, and Drizzle.

## Procedure

Before modifying database code, read the following:

1. Read the current schema file (`schema.prisma` or Drizzle schema definition)
2. Read the migration history to understand existing schema state
3. Read 1-2 existing query files to match the project's query patterns
4. Read any seed or fixture files to understand test data conventions

Then execute the database changes:

1. Update the schema definition (Prisma schema.prisma or Drizzle schema file)
2. Generate and review the migration file
3. Update any affected query code (services, resolvers, or handlers)
4. Update or create test fixtures if the schema changed
5. Run the migration locally and verify it applies cleanly
6. Run the test suite to confirm no regressions

---

## Projects Using Database

| Project | ORM | Database |
|---------|-----|----------|
| ClearPathOS | Prisma | PostgreSQL |
| sample-service | Drizzle | PostgreSQL |
| example-dashboard | Drizzle | PostgreSQL |

## Prisma (ClearPathOS)

### Schema Best Practices
```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  posts     Post[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([email])
}

model Post {
  id        String   @id @default(cuid())
  title     String
  content   String?
  authorId  String
  author    User     @relation(fields: [authorId], references: [id])
  published Boolean  @default(false)

  @@index([authorId])
  @@index([published, createdAt])
}
```

### Queries
```typescript
// Create
const user = await prisma.user.create({
  data: { email: 'test@example.com', name: 'Test' }
})

// Read with relations
const userWithPosts = await prisma.user.findUnique({
  where: { id: userId },
  include: { posts: true }
})

// Update
const updated = await prisma.user.update({
  where: { id: userId },
  data: { name: 'New Name' }
})

// Delete
await prisma.user.delete({ where: { id: userId } })
```

### Transactions
```typescript
const result = await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({ data: { email: 'new@example.com' } })
  await tx.post.create({
    data: { title: 'First Post', authorId: user.id }
  })
  return user
})
```

## Drizzle (sample-service, example-dashboard)

### Schema Definition
```typescript
import { pgTable, text, timestamp, boolean, uuid } from 'drizzle-orm/pg-core'

export const users = pgTable('users', {
  id: uuid('id').defaultRandom().primaryKey(),
  email: text('email').notNull().unique(),
  name: text('name'),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow()
})

export type User = typeof users.$inferSelect
export type NewUser = typeof users.$inferInsert
```

### Queries
```typescript
import { eq, desc, sql } from 'drizzle-orm'

// Select
const result = await db.select().from(users).where(eq(users.email, 'test@example.com'))

// Insert
const [user] = await db.insert(users).values({ email: 'test@example.com' }).returning()

// Update
await db.update(users).set({ name: 'New Name' }).where(eq(users.id, user.id))

// Delete
await db.delete(users).where(eq(users.id, user.id))

// Complex queries
const recentPosts = await db.select()
  .from(posts)
  .leftJoin(users, eq(posts.authorId, users.id))
  .where(eq(posts.published, true))
  .orderBy(desc(posts.createdAt))
  .limit(10)
```

### Relations in Drizzle
```typescript
// Define relations
export const usersRelations = relations(users, ({ many }) => ({
  posts: many(posts)
}))

export const postsRelations = relations(posts, ({ one }) => ({
  author: one(users, {
    fields: [posts.authorId],
    references: [users.id]
  })
}))

// Query with relations
const userWithPosts = await db.query.users.findFirst({
  with: { posts: true }
})
```

## Migrations

### Prisma
```bash
# Create migration
npx prisma migrate dev --name add_user_field

# Apply migrations (production)
npx prisma migrate deploy

# Reset (dev only)
npx prisma migrate reset
```

### Drizzle
```bash
# Generate migration
npx drizzle-kit generate:pg

# Push schema (dev)
npx drizzle-kit push:pg

# Migrate (production)
npx drizzle-kit migrate
```

## Common Issues

### N+1 Queries
```typescript
// BAD - N+1
const users = await db.select().from(users)
for (const user of users) {
  const posts = await db.select().from(posts).where(eq(posts.authorId, user.id))
}

// GOOD - Single query with JOIN
const usersWithPosts = await db.select()
  .from(users)
  .leftJoin(posts, eq(users.id, posts.authorId))
```

### Connection Pool Exhaustion
```typescript
// Prisma - check connection limit
const prisma = new PrismaClient({
  log: ['query'],
  datasources: {
    db: { url: process.env.DATABASE_URL + '?connection_limit=5' }
  }
})

// Always disconnect in serverless
export async function GET() {
  try {
    const users = await prisma.user.findMany()
    return Response.json(users)
  } finally {
    await prisma.$disconnect()
  }
}
```

## Indexing Checklist

- [ ] Primary keys indexed automatically
- [ ] Foreign keys indexed
- [ ] Columns in WHERE clauses indexed
- [ ] Columns in ORDER BY indexed
- [ ] Composite indexes for multi-column queries

## Output format

Produce a database change report in this exact format:

```
## Database Change — <change description>

**ORM:** <Prisma / Drizzle>
**Project:** <project name>

### Schema changes
- <table>: <what changed — added column / changed type / added index / etc>

### Migration
- Migration name: <name>
- Migration file: <path>
- Applied locally: <yes/no>

### Query changes
- <file>: <what query changed>

### Verification
- [ ] Migration applies cleanly
- [ ] `prisma validate` or `drizzle-kit check` passes
- [ ] Test suite passes
- [ ] No N+1 queries introduced
```

## Out of Scope

This skill does NOT:
- Write application logic or API handlers (that is /implement)
- Fix database performance issues in production (that is performance/SKILL.md)
- Replace a full database migration strategy for zero-downtime deploys (use migration-patterns/SKILL.md)
- Audit data security or PII handling (that is security/SKILL.md)
- Manage database infrastructure (use deployment/SKILL.md for infra)