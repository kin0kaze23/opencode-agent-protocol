# Public Sync Manifest

> **Version:** v5.5.4
> **Last Updated:** 2026-07-15

This document tracks which files in the public repository have been sanitized for public release and what sanitization was applied.

## Sanitization Categories

| Category | Description |
|----------|-------------|
| **Model IDs** | Author-specific model IDs replaced with `YOUR_PROVIDER/YOUR_*_MODEL` placeholders |
| **Provider names** | Author-specific provider names replaced with generic "your provider" language |
| **Secret references** | Secret manager references genericized |
| **Internal paths** | Internal vault/knowledge-base paths replaced with generic equivalents |
| **Personal project names** | Personal project names anonymized |
| **Eval scores** | Internal model eval scores and comparisons removed |
| **Protocol sync** | Visual QA protocol synced from internal repo in sanitized form |

## Sanitized Files

### Control Files

| File | Sanitization Applied |
|------|---------------------|
| `.opencode/AGENTS.md` | Version bump to v5.5.4; all model IDs replaced with `YOUR_PROVIDER/YOUR_*_MODEL` placeholders; session banner updated to v5.x history; Visual QA & Design Review Protocol section added; internal references genericized |
| `.opencode/rules.md` | Version bump to v5.5.4; all model IDs replaced with placeholders; `Doppler`/`nuggie-be`/`Alibaba`/`Bailian`/`example-agent` references removed; Visual QA protocol section added; model-specific token budget tables replaced with generic categories; `vault/evals/` references replaced with generic knowledge-base references |
| `.opencode/helper-roster.md` | All model IDs replaced with `YOUR_PROVIDER/YOUR_*_MODEL` placeholders; `Doppler`/`nuggie-be`/`Alibaba`/`Bailian`/`example-agent` references removed; `vault/evals/` references removed; specific model eval scores removed; visual reviewer fallback section made provider-agnostic; model comparison helpers genericized |

### Agent Definitions

| File | Sanitization Applied |
|------|---------------------|
| `.opencode/agents/visual-reviewer.md` | Visual QA verdicts synced from internal repo; `READY TO SHIP`/`NEEDS FIXES` replaced with `TECHNICAL_VISUAL_PASS`/`TECHNICAL_VISUAL_FAIL`; author-specific model IDs cleaned |
| `.opencode/agents/visual-reviewer-fallback.md` | Same Visual QA verdict sync as primary visual-reviewer |
| `.opencode/global-runtime/prompts/visual-reviewer.md` | Prompt mirror synced with agent definition |
| `.opencode/global-runtime/prompts/visual-reviewer-fallback.md` | Prompt mirror synced with agent definition |

### Scripts

| File | Purpose |
|------|---------|
| `scripts/validate-public-sync.sh` | Drift detection script — checks version consistency, forbidden author-specific strings, visual reviewer verdicts, stale v4 banners, placeholder model IDs, vault/evals references, and prompt mirror existence |

### Version Files

| File | Version Updated |
|------|----------------|
| `NOW.md` | v5.5.4 |
| `README.md` | v5.5.4 |
| `CHANGELOG.md` | v5.5.4 entry added |
| `docs/protocol/PROTOCOL_ATLAS.md` | v5.5.4 |

### CI

| File | Change |
|------|--------|
| `.github/workflows/validation.yml` | Added `public-sync-validation` job running `scripts/validate-public-sync.sh` on both Ubuntu and macOS |

## Forbidden Patterns

The `validate-public-sync.sh` script checks for these forbidden patterns in control files:

| Pattern | Reason |
|---------|--------|
| `umans-ai-coding-plan/` | Author-specific provider namespace |
| `opencode-go/` | Author-specific provider namespace |
| `nuggie-be` | Author-specific project name |
| `Doppler` | Author-specific secret manager |
| `Alibaba` | Author-specific provider name |
| `Bailian` | Author-specific provider name |
| `example-agent` | Author-specific reference |

## Validation

Run the drift detection script before every public release:

```bash
bash scripts/validate-public-sync.sh
```

The script checks:
1. Version consistency across AGENTS.md, rules.md, NOW.md, README.md, PROTOCOL_ATLAS.md
2. No forbidden author-specific strings in control files
3. Visual reviewer agent files use `TECHNICAL_VISUAL_PASS`/`FAIL` verdicts
4. No stale v4 session banners
5. `YOUR_PROVIDER` placeholders present in control files
6. No `vault/evals/` references
7. All prompt mirrors exist for declared agents

## CI Integration

The `public-sync-validation` job runs on every PR and push to main, on both Ubuntu and macOS. This ensures drift is caught before merge.
