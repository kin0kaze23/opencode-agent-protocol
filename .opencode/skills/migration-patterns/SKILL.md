---
name: migration-patterns
description: Database migration patterns — versioned migrations, zero-downtime deploys, backward compatibility, schema evolution, and safe rollout strategies.
---

# Migration Patterns

Systematic approach to database schema changes, data migrations, and zero-downtime deployments.

## When to Use

- User mentions "migration", "schema change", "backfill", "data migration"
- Adding/removing columns, tables, or indexes
- Changing data types or constraints
- Moving data between tables or services
- Any change that affects stored data shape

## Core Principles

1. **Versioned migrations only** — never manually mutate production schema
2. **Backward compatibility** — old code must work with new schema during rollout
3. **Split risky changes** — deploy schema, then app, then backfill, then cleanup
4. **Always have a rollback** — every migration must be reversible

## Safe Migration Pattern (Expand-Contract)

### Phase 1: Expand (Add, don't change)
```sql
-- Add new column (nullable or with default)
ALTER TABLE users ADD COLUMN new_email VARCHAR(255);
-- Deploy app that writes to BOTH old and new columns
```

### Phase 2: Backfill
```sql
-- Copy data from old to new
UPDATE users SET new_email = old_email WHERE new_email IS NULL;
-- Run as batch job, not single transaction
```

### Phase 3: Switch
```sql
-- Deploy app that reads from new column only
-- Old column is still there but unused
```

### Phase 4: Contract (Remove)
```sql
-- After confirming new column works in production
ALTER TABLE users DROP COLUMN old_email;
```

## ORM-Specific Patterns

### Prisma
```prisma
// Safe: add optional field
model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  newEmail  String?  // Add as optional first
}
```
```bash
npx prisma migrate dev --name add_new_email
npx prisma migrate deploy  # production
```

### Drizzle
```typescript
// Safe: add column with default
export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  newEmail: varchar('new_email', { length: 255 }), // nullable by default
});
```

## Migration PR Must Include

- Migration purpose
- Affected tables/entities
- Backward compatibility note
- Rollback approach
- Staging verification evidence
- Backfill strategy (if needed)

## Risk Classification

| Risk | Examples | Required |
|---|---|---|
| **Low** | Add nullable column, add index | Migration file + deploy |
| **Medium** | Add NOT NULL column, rename column | Migration + backfill + staging verify |
| **High** | Drop column, change type, split table | Expand-contract + staging + rollback test |
| **Critical** | Delete table, change primary key | Full rollout plan + manual approval |

## Rollback Strategies

| Scenario | Rollback |
|---|---|
| Add column | `ALTER TABLE DROP COLUMN` (safe if no data written) |
| Add index | `DROP INDEX` (safe, no data loss) |
| Rename column | Reverse rename (if supported) |
| Change type | Revert migration, restore from backup |
| Drop column | Restore from backup (destructive) |

## Pre-Deployment Checklist

- [ ] Migration tested on staging with production-like data
- [ ] Rollback migration tested on disposable branch
- [ ] Backfill script tested (if applicable)
- [ ] Old code path still works with new schema
- [ ] New code path works with old schema (during transition)
- [ ] Monitoring in place for migration-related errors
- [ ] Rollback plan documented and tested

## Anti-Patterns (Never Do)

- `DROP TABLE` in production without backup
- Changing column type without expand-contract
- Running migrations as part of app startup (use separate deploy step)
- Mutating production data manually without a runbook
- Skipping staging verification for schema changes
- Deploying app and migration in same step for risky changes
