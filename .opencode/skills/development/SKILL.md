---
name: development
description: Coding patterns, clean code thresholds, and immutability rules enforced across all portfolio projects.
---

# Development Skill

> This checked-in OpenCode skill is the live version for OpenCode sessions.

## Procedure

Before writing code, read the following:

1. Read the target repo's `CLAUDE.md` or `AGENTS.md` for repo-specific coding standards
2. Read the `package.json` or equivalent to confirm the stack, scripts, and dependencies
3. Read 1-2 existing source files to match the project's import order, naming, and error handling patterns
4. Read any existing `FRONTEND_GUIDELINES.md`, `BACKEND_STRUCTURE.md`, or similar canonical docs

Then execute the development:

1. Confirm canonical docs exist (`PRD.md`, `APP_FLOW.md`, `TECH_STACK.md`) — do not implement features until they do
2. Apply clean code thresholds (see below) — refactor before shipping if exceeded
3. Enforce immutability rules — never mutate existing state
4. Apply structured error handling — never silently swallow errors
5. Follow import order conventions (see below)
6. Use TypeScript strict mode — never use `any`

---

## Documentation-First

Do not implement features until canonical docs exist:
- `PRD.md`, `APP_FLOW.md`, `TECH_STACK.md`
- `FRONTEND_GUIDELINES.md`, `BACKEND_STRUCTURE.md`, `IMPLEMENTATION_PLAN.md`

Always read `CLAUDE.md` in the target repo before touching any code.

---

## Clean Code Thresholds (Hard Limits)

| Metric | WARN | BLOCK |
|--------|------|-------|
| Function body | >50 lines | >80 lines |
| File length | >400 lines | >600 lines |
| Nesting depth | >3 levels | >5 levels |
| Function parameters | >3 params | >5 params |

Code exceeding BLOCK must be refactored before shipping.

---

## Immutability (CRITICAL)

Always create new objects, NEVER mutate existing ones:
```typescript
// WRONG
state.users.push(newUser);

// CORRECT
return { ...state, users: [...state.users, newUser] };
```

---

## Error Handling (REQUIRED)

```typescript
// Server-side: full context
logger.error("Failed to process payment", {
  userId, orderId, error: err.message, stack: err.stack
});

// Client-facing: user-friendly only
throw new AppError("Payment failed. Please try again.", 400);
```

Never silently swallow errors. Never expose stack traces to users.

---

## Import Order

```typescript
// 1. Node built-ins
import { readFile } from 'fs/promises';
// 2. External packages
import express from 'express';
// 3. Internal absolute
import { db } from '@/lib/database';
// 4. Internal relative
import { validateUser } from './validators';
// 5. Types
import type { User } from './types';
```

---

## Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Variables/functions | camelCase | `getUserById` |
| Classes/interfaces | PascalCase | `UserService` |
| Constants | SCREAMING_SNAKE | `MAX_RETRY_COUNT` |
| Files | kebab-case | `user-service.ts` |
| DB columns | snake_case | `created_at` |

---

## TypeScript Strictness

```json
{
  "strict": true,
  "noImplicitAny": true,
  "noUncheckedIndexedAccess": true,
  "exactOptionalPropertyTypes": true
}
```

Never use `any`. Use `unknown` + type narrowing instead.

## Output format

Produce a development report in this exact format:

```
## Development Report — <module/feature name>

**Repo:** <repo name>
**Stack:** <TypeScript / Python / Rust / etc>

### Files changed
- <file>: <what was added or modified>

### Code quality checks
- Function length: <within limits / exceeded — <details>>
- File length: <within limits / exceeded — <details>>
- Nesting depth: <within limits / exceeded — <details>>
- Immutability: <enforced / violations found>

### TypeScript
- Strict mode: <enabled / disabled>
- No `any` used: <yes / no — <details>>

### Verification
- [ ] `lint` passes
- [ ] `typecheck` passes
- [ ] Code follows import order convention
- [ ] Naming conventions followed
```

## Out of Scope

This skill does NOT:
- Implement features without canonical docs (stop and require docs first)
- Write database migrations (that is database/SKILL.md)
- Fix security vulnerabilities (that is security/SKILL.md)
- Replace refactoring for structural debt (that is technical-debt-prevention/SKILL.md)
- Write tests (that is testing-validation/SKILL.md)
- Deploy code (that is deployment/SKILL.md)
