---
name: refactor-clean
description: Safe, targeted refactoring and cleanup with behavior preservation. Extract, simplify, and clean without changing functionality. Test before and after.
---

# Refactor Clean Skill

> Activate for: "clean up this code," "refactor," "simplify," "this is getting complex," "extract this."
> HARD RULE: Refactoring preserves behavior. If behavior changes, it's a bug or a feature — not a refactor.

---

## Before Touching Anything

1. Run all gates — they must pass BEFORE refactoring:
   Use the native OpenCode gate flow: `/gates`
2. Read the code in full (this is when you're allowed to read a whole file)
3. Identify the specific problem: too long? too coupled? duplicated? confusing names?
4. Plan the minimum change that fixes it

---

## Refactoring Techniques by Problem

### File Too Long (>400 lines)
→ Extract by responsibility, not by type
```
WRONG: extract all types to types.ts, all utils to utils.ts
RIGHT: extract UserAuth to user-auth.ts (owns its types + utils + logic)
```

### Function Too Long (>50 lines)
→ Extract sub-functions with clear names
→ The name should describe WHAT it does, not HOW
→ Each sub-function should be independently testable

### Duplicated Code (DRY)
→ Only extract when you have 3+ identical or near-identical instances
→ "Two is a coincidence, three is a pattern"
→ Parameterize the difference, not the similarity

### Deep Nesting (>3 levels)
→ Early return / guard clause pattern:
```typescript
// BEFORE
function process(user) {
  if (user) {
    if (user.active) {
      if (user.hasPermission) {
        return doThing(user);
      }
    }
  }
}

// AFTER
function process(user) {
  if (!user) return null;
  if (!user.active) return null;
  if (!user.hasPermission) return null;
  return doThing(user);
}
```

### Confusing Names
→ Names should reveal intent, not implementation
→ Functions: verb + noun (`getUser`, `validateEmail`, `formatDate`)
→ Booleans: `is`, `has`, `can` prefix (`isActive`, `hasPermission`, `canEdit`)
→ Constants: SCREAMING_SNAKE for true constants, camelCase for computed

### Mutation
→ Replace every mutation with immutable update:
```typescript
// BEFORE: mutates
items.push(newItem);
user.name = newName;

// AFTER: immutable
const newItems = [...items, newItem];
const updatedUser = { ...user, name: newName };
```

---

## The Refactor Sequence

1. Write a test that characterizes current behavior (if not already tested)
2. Run it — confirm it passes
3. Make the smallest refactor
4. Run the test — confirm it still passes
5. Repeat for next refactor
6. Run all gates at the end

Never refactor multiple things at once. One change at a time.

---

## What NOT to Do

- Don't change behavior "while you're in there"
- Don't add new features during a refactor
- Don't optimize for performance during a refactor (that's a separate task)
- Don't rename things AND change logic in the same commit
- Don't refactor code you don't understand yet

---

## RESULT Block

```
RESULT
status: COMPLETE
agent: build
refactor_type: [extract-function | split-file | remove-duplication | flatten-nesting | rename | immutability]
files_changed: <count>
lines_before: <approx>
lines_after: <approx>
behavior_preserved: YES — same tests pass before and after
gates: lint [pass] typecheck [pass] test [pass] build [pass]
```
