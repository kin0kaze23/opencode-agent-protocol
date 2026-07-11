---
description: "Build a read-only structure map for an unfamiliar repo"
---

# /map-repo

**Purpose:** Build a read-only structure map for an unfamiliar repo
**Mode:** Mentor
**Model:** qwen3.7-plus (v1.1-production, Action 4D)
**Tool access:** Layer A (read-only)
**Success output:** Repo map with key files, entry points, dangerous areas

## Behaviour

When invoked, the Owner agent (or Explorer helper):

1. Reads the repo's file tree (top 2-3 levels)
2. Reads package.json / Cargo.toml / Package.swift for stack details
3. Reads AGENTS.md for known hotspots
4. Identifies: entry points, key directories, test locations, config files
5. Outputs a scannable map

## When to use

- Before starting work on an unfamiliar repo
- When the codebase has changed significantly since last session
- When planning a feature that touches multiple areas

## Output format

```
## Repo Map - <repo>

Stack: <stack>
Entry points:
  - <path> - <purpose>

Key directories:
  - <dir>/ - <what lives here>

Test locations:
  - <path>

Config files:
  - <path> - <purpose>

Dangerous areas (from AGENTS.md):
  - <area> - <why>
```
