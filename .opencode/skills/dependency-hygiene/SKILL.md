---
name: dependency-hygiene
description: Dependency management best practices — version pinning, audit, lockfile hygiene, and supply chain security.
---

# Dependency Hygiene Skill

> **Purpose:** Prevent dependency rot — the silent accumulation of outdated, vulnerable, abandoned, or unnecessary packages.
> **Auto-Load:** When adding dependencies, during monthly maintenance, or when `npm audit` fires
> **Authority:** Works with `mvp-defaults` skill for stack decisions

---

## The Non-Negotiable Rule

**Every dependency is a liability.** Add deliberately. Audit regularly. Remove aggressively.

---

## Before Adding Any Dependency (5-Point Check)

### 1. Is it necessary?
- Can this be done with existing deps or stdlib?
- If implementable in < 50 lines without edge cases → don't add dep

### 2. Is it maintained?
```bash
npm view <package> time.modified  # Should be < 6 months
npm view <package> --json | jq '.downloads'  # Should be > 10,000/week
```

| Signal | Healthy | Concerning | Abandon Risk |
|--------|---------|------------|-------------|
| Last publish | < 6 months | 6-18 months | > 18 months |
| Weekly downloads | > 10,000 | 1,000-10,000 | < 1,000 |

### 3. Is it safe?
```bash
npm audit --json | jq '.vulnerabilities["<package>"]'
npx bundlephobia <package>  # Check bundle impact
```

### 4. Is it compatible?
- Check license (MIT, Apache 2.0, ISC = safe; GPL = review)
- Check peer dependency conflicts

### 5. Is it documented?
- Add to `TECH_STACK.md` with justification
- If replacing something → remove old entry

---

## Monthly Dependency Audit Commands

### Node.js Projects
```bash
# Vulnerability scan
npm audit

# Outdated packages
npm outdated

# Unused dependencies
npx depcheck

# Bundle size (Vite)
npx vite-bundle-visualizer

# Duplicate dependencies
npm ls --all | grep -E "deduped|invalid"
```

### Rust Projects
```bash
cargo audit          # Vulnerabilities
cargo outdated       # Outdated crates
cargo udeps --all-targets  # Unused deps
cargo deny check licenses  # License check
```

---

## Dependency Budget Per Project

| Project Type | Max Direct Dependencies |
|-------------|------------------------|
| Simple app | 20 |
| Standard app | 40 |
| Complex app | 60 |
| Monorepo total | 80 |

```bash
# Count dependencies
jq '.dependencies | length' package.json
```

---

## Red Flags (Reject Immediately)

| Red Flag | Action |
|----------|--------|
| `*` or `latest` version | Pin to specific version |
| Last published > 2 years | Find maintained alternative |
| Known critical CVE | Do not install |
| Pulls > 50 transitive deps for simple functionality | Write yourself |
| Two packages for same purpose | Remove one |
| Git URL dependency (not npm) | Reject unless forked |
| GPL/AGPL without review | Review license first |

---

## Update Strategy

| Level | Risk | Action |
|-------|------|--------|
| Patch (1.0.x → 1.0.y) | Safe | Update immediately |
| Minor (1.x.0 → 1.y.0) | Low | Schedule next sprint |
| Major (x.0.0 → y.0.0) | Breaking | Create dedicated task |

```bash
# Safe updates
npm update

# Specific package to latest
npm install <package>@latest

# Interactive update
npx npm-check-updates --interactive
```

---

## Recording in execution.md

```markdown
### Dependency Changes
| Action | Package | Version | Justification |
|--------|---------|---------|---------------|
| Added | zod | ^3.22.0 | Input validation |
| Removed | joi | — | Replaced by zod |
| Updated | react | 18→19 | Server actions |
```

---

*Skill document for OpenCode auto-loading*
