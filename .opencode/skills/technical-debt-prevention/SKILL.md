---
name: technical-debt-prevention
description: Refactor and structural cleanup guidelines — prevents debt accumulation during implementation and identifies existing debt hotspots.
---

# Technical Debt Prevention Skill

> **Purpose:** Detect and prevent structural code quality degradation at every stage — planning, execution, and QA.
> **Auto-Load:** During EXECUTE (before writing code) and QA (during review)
> **Authority:** Mandatory companion to `development` skill and QA workflow

---

## The Non-Negotiable Rule

**Code that passes all gates but degrades the codebase is not shippable.** Lint, typecheck, test, and build measure functional correctness. This skill measures structural health. Both must pass.

---

## The 7 Debt Detectors

Every agent must check these during EXECUTE (self-review) and QA (formal review). If ANY detector fires, the issue must be flagged.

### Detector 1: Complexity Debt

| Metric | WARN | BLOCK |
|--------|------|-------|
| Function body | > 50 lines | > 80 lines |
| File length | > 400 lines | > 600 lines |
| Function parameters | > 4 | > 6 |
| Nesting depth | > 4 levels | > 6 levels |

### Detector 2: Duplication Debt (DRY)

- Same logic in 2+ places (>10 lines identical) → Extract shared utility
- Similar components with 80%+ overlap → Create base component with variants
- Same API call pattern repeated in 3+ files → Create shared hook/service

### Detector 3: Dead Code Debt

- Commented-out code blocks → Delete (git has history)
- Unused imports/functions → Remove
- TODO/FIXME/HACK without ticket → Convert to tracked issue or fix now
- Feature flags permanently on/off → Remove flag, keep winning path

**Rule:** Every TODO must have a ticket ID or removal date.

### Detector 4: Naming & Convention Debt

- Boolean props without `is/has/should` prefix → Rename
- Generic names (`data`, `result`, `temp`) → Use domain-specific names
- Abbreviated names (`btn`, `usr`) → Spell out
- Inconsistent file naming → Align to repo convention

### Detector 5: Error Handling Debt

- API route without try-catch → Add error handling
- React component fetching data without error boundary → Add ErrorBoundary
- Promise without `.catch()` → Handle rejections
- Empty catch blocks → At minimum: log the error
- Missing loading/empty states in data-fetching components → Add all 3 states

### Detector 6: Dependency Debt

- `*` or `latest` version → Pin to specific version
- Dependencies not in TECH_STACK.md → Document or remove
- Multiple libraries for same purpose → Consolidate to one
- High/critical vulnerabilities in `npm audit` → Fix before shipping

### Detector 7: Architecture Debt

- Business logic in UI components → Extract to hooks/services
- Direct DB calls bypassing service layer → Route through service
- Prop drilling > 3 levels → Use context/store
- Circular imports → Break with interface extraction
- Inconsistent API response shapes → Standardize envelope

---

## Debt Scoring

| Detector | No issues | Minor (WARN) | Major (BLOCK) |
|----------|-----------|-------------|---------------|
| Complexity | 0 | +1 per WARN | +3 per BLOCK |
| Duplication | 0 | +1 per instance | +3 per instance |
| Dead code | 0 | +1 per item | +2 per item |
| Naming | 0 | +1 per inconsistency | +2 per inconsistency |
| Error handling | 0 | +1 per gap | +3 per gap |
| Dependencies | 0 | +1 per issue | +3 per issue |
| Architecture | 0 | +2 per violation | +5 per violation |

**Thresholds:**
- Score 0-3: Clean — ship it
- Score 4-8: Acceptable — ship with debt register entries
- Score 9-15: Fix before shipping — SOFT_ISSUES in QA
- Score 16+: HARD_BLOCKER — too much debt in one change

---

## Integration with QA

Add this to `evidence.md` after gate results:

```markdown
### Structural Quality Review
- Complexity: PASS/WARN/FAIL (details)
- Duplication: PASS/WARN/FAIL (details)
- Dead code: PASS/WARN/FAIL (details)
- Error handling: PASS/WARN/FAIL (details)
- Naming: PASS/WARN/FAIL (details)
- Dependencies: PASS/WARN/FAIL (details)
- Architecture: PASS/WARN/FAIL (details)
Structural verdict: PASS/SOFT_ISSUES (N warnings, M blockers)
```

**Rule:** If any structural check is FAIL (BLOCK-level), QA verdict must be SOFT_ISSUES minimum, even if all gates pass.

---

## Anti-Patterns to Reject Instantly

```
❌ Functions > 80 lines
❌ Files > 600 lines
❌ Copy-paste blocks > 10 lines in 2+ locations
❌ Empty catch blocks: catch(e) {}
❌ TODO/FIXME without ticket reference
❌ Generic variable names: data, result, temp
❌ God components (render > 100 lines, > 5 useState)
❌ npm audit critical vulnerabilities
❌ Dependencies with * or latest version
❌ Business logic directly in UI components
```

---

## Commands to Check Debt

```bash
# Find long functions
rg -c "^(export )?(async )?(function|const \w+ = (async )?\()" --type ts

# Find TODOs without tickets
rg "TODO|FIXME|HACK|XXX" --type ts

# Check for unused dependencies
npx depcheck

# Check vulnerabilities
npm audit --audit-level=high

# Rust complexity
cargo clippy --all-targets --all-features -- -W clippy::too_many_lines
```

---

*Skill document for OpenCode auto-loading*
