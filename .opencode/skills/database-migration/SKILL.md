---
description: "Safe database migrations with Prisma, Drizzle, and raw SQL"
---

# Database Migration

> **Version:** 1.0
> **Scope:** Safe database migrations with Prisma, Drizzle, and raw SQL
> **Integration:** Works with `/plan-feature`, `/implement`, `/ship`, `/deploy-rollback`

## When to Activate

Task keywords: `migration`, `schema change`, `prisma`, `drizzle`, `database`, `sql`, `alter table`, `add column`, `drop column`, `index`, `foreign key`, `seed`, `rollback migration`

## Migration Safety Rules

### Before Any Migration

1. **Backup current state:**
   ```bash
   # Prisma
   pg_dump $DATABASE_URL > backup-$(date +%Y%m%d-%H%M%S).sql
   
   # Drizzle (PostgreSQL)
   pg_dump $DATABASE_URL > backup-$(date +%Y%m%d-%H%M%S).sql
   ```

2. **Check migration history:**
   ```bash
   # Prisma
   prisma migrate status
   
   # Drizzle
   drizzle-kit check
   ```

3. **Verify migration is reversible:**
   - Test `up` migration in development
   - Test `down` migration in development
   - Verify data integrity after rollback

### During Migration

1. **Run migration in development first:**
   ```bash
   # Prisma
   prisma migrate dev --name <migration-name>
   
   # Drizzle
   drizzle-kit generate
   drizzle-kit push
   ```

2. **Verify migration:**
   - Check new columns/tables exist
   - Check data integrity
   - Check indexes are created
   - Check foreign keys are valid

3. **Test rollback:**
   ```bash
   # Prisma
   prisma migrate reset
   
   # Drizzle
   drizzle-kit drop
   drizzle-kit push
   ```

### After Migration

1. **Deploy to staging:**
   ```bash
   # Prisma
   prisma migrate deploy
   
   # Drizzle
   drizzle-kit migrate
   ```

2. **Verify staging:**
   - Run smoke tests
   - Check data integrity
   - Verify rollback works

3. **Deploy to production:**
   ```bash
   # Prisma
   prisma migrate deploy
   
   # Drizzle
   drizzle-kit migrate
   ```

4. **Verify production:**
   - Run smoke tests
   - Check data integrity
   - Monitor for errors

## Migration Types

### Safe Migrations (Can deploy without downtime)

| Operation | Safety | Notes |
|---|---|---|
| Add column with default | ✅ Safe | No data loss |
| Add index | ✅ Safe | No downtime |
| Add nullable column | ✅ Safe | No data loss |
| Add table | ✅ Safe | No data loss |
| Rename column (with alias) | ⚠️ Careful | Requires dual-write period |

### Risky Migrations (Require downtime or careful planning)

| Operation | Risk | Mitigation |
|---|---|---|
| Drop column | 🔴 High | Data loss — backup first |
| Drop table | 🔴 High | Data loss — backup first |
| Change column type | 🔴 High | Data loss — test thoroughly |
| Add NOT NULL without default | 🔴 High | Migration will fail on existing rows |
| Rename table | ⚠️ Medium | Requires code update simultaneously |

## Zero-Downtime Migration Strategy

For risky migrations, use this pattern:

### Phase 1: Add new column (safe)
```sql
ALTER TABLE users ADD COLUMN new_email VARCHAR(255);
```

### Phase 2: Dual-write (code change)
- Write to both old and new columns
- Read from old column

### Phase 3: Backfill data
```sql
UPDATE users SET new_email = email WHERE new_email IS NULL;
```

### Phase 4: Switch reads (code change)
- Read from new column
- Write to new column only

### Phase 5: Remove old column (safe after verification)
```sql
ALTER TABLE users DROP COLUMN email;
```

## Rollback Strategy

### If Migration Fails

1. **Immediate rollback:**
   ```bash
   # Prisma
   prisma migrate resolve --rolled-back <migration-name>
   
   # Drizzle
   drizzle-kit rollback
   ```

2. **Restore from backup (if needed):**
   ```bash
   psql $DATABASE_URL < backup-20260421-140000.sql
   ```

3. **Verify rollback:**
   - Check schema is back to previous state
   - Check data integrity
   - Run smoke tests

## Migration Best Practices

### Do
- ✅ Always backup before migration
- ✅ Always test rollback in development
- ✅ Always deploy to staging first
- ✅ Always monitor after production deployment
- ✅ Use `--safe` flag for Prisma when possible
- ✅ Keep migrations small and focused
- ✅ Document migration purpose and rollback plan

### Don't
- ❌ Run migrations on Fridays or before holidays
- ❌ Run multiple migrations simultaneously
- ❌ Skip backup step
- ❌ Skip rollback testing
- ❌ Deploy migration without code that supports it
- ❌ Drop columns/tables without verifying no code uses them

## Integration with Other Commands

| Command | Integration Point |
|---|---|
| `/plan-feature` | Includes migration steps in plan |
| `/implement` | Runs migration in development |
| `/gates` | Typecheck is critical for schema changes |
| `/ship` | Includes migration notes in PR |
| `/deploy-vercel` | Runs migration before deployment |
| `/deploy-rollback` | Rolls back migration if needed |

## Troubleshooting

### Common Issues

| Issue | Cause | Fix |
|---|---|---|
| Migration fails on production | Different data state than development | Test with production-like data |
| Rollback fails | Migration already applied partially | Restore from backup |
| Typecheck fails after migration | Client not regenerated | Run `prisma generate` or `drizzle-kit generate` |
| Foreign key constraint fails | Referenced data doesn't exist | Add data first, then foreign key |
| Index creation slow | Large table | Create index concurrently (PostgreSQL) |
