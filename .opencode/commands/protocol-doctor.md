---
description: Run read-only health check on OpenCode AgentOps protocol
agent: orchestrator
model: opencode-go/qwen3.7-plus
---

# /protocol-doctor

Runs `.opencode/scripts/protocol-doctor.sh` to perform a comprehensive read-only health check of the OpenCode AgentOps protocol.

## What it checks

1. **Git/commit-scope hygiene** — branch, dirty files, staged files, last commit scope
2. **Plugin health** — brain-hooks.js startup, compaction hook, validateResponse, chat.message
3. **Command registry** — count, missing frontmatter, duplicates with .claude/commands
4. **Skill registry** — count, missing frontmatter
5. **Protocol version drift** — version label mismatches across key files
6. **Runtime/tooling availability** — Playwright, hooks, git-guard, prompt parity
7. **Repo contract completeness** — missing AGENTS.md/NOW.md for active projects
8. **Final recommendation** — next best commit

## Usage

```bash
bash .opencode/scripts/protocol-doctor.sh
```

The script outputs a markdown report with overall classification: **GREEN** / **YELLOW** / **ORANGE** / **RED**.

## Classification criteria

- **GREEN**: All checks pass, no critical issues
- **YELLOW**: Minor issues (missing frontmatter, version drift, unverified hooks)
- **ORANGE**: Significant issues (plugin errors, broken hooks, missing contracts)
- **RED**: Critical failures (plugin not loaded, security issues, broken runtime)
