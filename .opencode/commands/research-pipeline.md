---
description: "Research pipeline: gather YouTube + web sources, analyze, save structured research note to vault"
---

# /research-pipeline

**Mode:** Executor
**Model:** qwen3.7-plus (v1.1-production)
**Tool access:** Layer A (read-only sources; write only to `vault/research/`)
**Success output:** Research note saved to `vault/research/YYYY-MM-DD/<slug>.md`
**Canary:** v0.2

---

## Overview

`/research-pipeline` runs a structured research workflow:

1. **Gather sources** — YouTube (via yt-dlp) and web (via websearch or Exa MCP)
2. **Synthesize analysis** — produce key findings, gaps, and conclusions
3. **Save structured output** — markdown research note + JSON source record to vault
4. **Show in chat** — summary of what was found

This is a **safe, read-only pipeline**. It does not:
- Modify any source code
- Auto-update owner-memory
- Download or archive video/audio content
- Expose credentials or auth tokens

---

## Usage

```
/research-pipeline <topic description>
```

Optional flags:

| Flag | Effect |
|------|--------|
| `--youtube-only` | Skip web search, YouTube sources only |
| `--web-only` | Skip YouTube search, web sources only |
| `--sources N` | Number of sources per adapter (default: 5) |
| `--notebooklm` | Enable NotebookLM analysis if authenticated (canary, optional) |

### Examples

```
/research-pipeline AI agent frameworks in 2026 — which frameworks are developers actually adopting
/research-pipeline Solana DeFi yield strategies Q2 2026 --sources 3
/research-pipeline emerging UI paradigms in developer tools --youtube-only
```

---

## Behaviour

### 1. Preflight

Before gathering sources, validate:

- Target repo is set (default: vault/ if no repo specified)
- yt-dlp is available if YouTube sources are required
- Exa MCP is running if web sources are required
- `vault/research/` exists (create if not)
- `vault/protocols/research/RESEARCH_OUTPUT_CONTRACT.md` exists
- If `--notebooklm` is set: verify `notebooklm-py` is installed; warn if not and fall back gracefully

Output abbreviated preflight:

```
Repo:             vault
Lane:             RESEARCH
Risk score:       1 (read-only, no code mutation, no secrets)
Sources:          youtube[:N] [+ web[:N]]
NotebookLM:       enabled | disabled | not available
Output:           vault/research/<date>/<slug>.md
```

### 2. Gather Sources

**YouTube sources** (unless `--web-only`):
1. Run: `bash .opencode/scripts/yt-search.sh "<topic>" --limit <N>`
2. Parse JSON output
3. Log count of results returned; warn if < 3

**Web sources** (unless `--youtube-only`):

Adapter policy (v0.2.1 production-core, confirmed by 10-run soak 2026-06-18):

| Adapter | Role | When to use |
|---------|------|-------------|
| `websearch` | **Canonical primary** | Default discovery; always available, no secrets required |
| Manual web fetch / open | Fallback verification/recovery | Direct URL verification when a websearch result fails or needs confirmation; alternate authoritative URLs for blocked pages |
| Exa MCP | Optional semantic enhancement | Only when `EXA_API_KEY` is configured; not required |

Fallback: If Exa MCP is unavailable or returns an error, continue with `websearch`. Missing Exa is not a failure.

1. Use `websearch` as the default discovery path.
2. If `EXA_API_KEY` is configured, optionally augment with Exa MCP for semantic results; do not block on Exa.
3. Use manual web fetch as verification/recovery when a result needs direct confirmation, returns 403/404, or an alternate authoritative URL is required.
4. Search for the topic; prioritize technical documentation, articles, analysis pieces.
5. Log count of results returned; warn if < 3.

If no web sources can be gathered after all fallback paths, stop and report the failure.

### 3. Synthesize Analysis

Read the gathered sources and produce:

- **Source quality scoring**: Score each source 0–10 using the rubric in RESEARCH_OUTPUT_CONTRACT.md (relevance 0–3, recency 0–2, authority 0–2, specificity 0–2, diversity 0–1)
- **YouTube relevance filtering**: Label each YouTube source as `direct`, `supporting`, `background`, or `discard` based on title relevance to the query
- **Summary**: one-paragraph overview (only from direct + supporting sources)
- **Key Findings**: bullet list with source citations (only from direct + supporting sources)
- **Gaps & Uncertainties**: what the pipeline could not find
- **Conclusions**: actionable takeaways and further research suggestions

Analysis is performed by the agent (no external AI service by default).

**Filtering rules:**
1. If total `direct` + `supporting` sources < 3, promote top `background` sources to `supporting`
2. Never discard all YouTube results — keep at least 2 even if all are `background`
3. `discard`-labeled sources appear in sources.json only, not in the research note

### 4. Build Structured Output

Create a research note matching the contract at `vault/protocols/research/RESEARCH_OUTPUT_CONTRACT.md`.

**Directory:**
```
vault/research/YYYY-MM-DD/
```

**File name:** `<slug>.md` where slug is kebab-case from the topic.

**Frontmatter:** title, created date, valid_until (1 month for AI/tooling, 3 months for protocol), freshness (current-sensitive), sources table with type, url, title, relevance, quality_score, metadata.

**Body:** Summary → Sources table (with Relevance and Quality columns) → Key Findings (direct + supporting only) → Gaps → Conclusions → Pipeline Metadata section.

**Companion JSON file:** `<slug>.sources.json` with raw source metadata, quality scores, and relevance labels.

**Index update:** Append a row to `vault/research/INDEX.md` with date, topic, slug, source count, types, avg quality, freshness, valid_until, key decision, and status.

### 5. Save and Report

1. Write the `.md` research note to the vault
2. Write the `.sources.json` companion file
3. Update `vault/research/INDEX.md` with a new row
4. Output research summary in chat
5. Print the exact vault path for easy opening in Obsidian

---

## Output Format (Chat Summary)

```
## Research Pipeline — <topic>

**Sources:** <N> YouTube (<N> direct, <N> supporting, <N> background), <N> web
**Avg quality:** <N>/10
**NotebookLM:** <used | not used>
**Output:** `vault/research/YYYY-MM-DD/<slug>.md`
**Index:** updated

### Summary
<1-2 paragraphs>

### Key Findings
- <finding 1>
- <finding 2>
- <finding 3>

### Gaps
- <gap 1>
- <gap 2>

### Next Steps
<actionable recommendation>
```

---

## NotebookLM Integration (Canary, Optional)

NotebookLM is supported as an optional analysis adapter. It is **disabled by default**.

To use:
```
/research-pipeline <topic> --notebooklm
```

If `notebooklm-py` is installed and authenticated:
- The pipeline creates a new NotebookLM notebook
- Adds all YouTube URLs and web page text as sources
- Requests analysis + one deliverable type (infographic, mindmap, etc.)
- Downloads the analysis and incorporates it into the research note

If `notebooklm-py` is NOT installed:
- The pipeline prints install instructions and proceeds without NotebookLM
- No hard failure

**Caveats (documented in the output):**
- notebooklm-py is unofficial; its API may break without notice
- Google's NotebookLM free tier limits: 100 notebooks, 50 sources/notebook, 3 audio overviews/day
- NotebookLM Enterprise API is Pre-GA and requires enterprise licensing

---

## Limitations (Canary v0.1)

| Limitation | Reason | Planned for v0.2 |
|---|---|---|
| No PDF source support | Requires PDF text extraction adapter | Likely |
| No local file analysis | Restricted to search-only for v0.1 | Maybe |
| No automatic memory mutation | Protocol guard; requires review | Manual command only |
| NotebookLM is optional canary | Unofficial API, may break | Wait for official API GA |
| No persistent research index | No cross-session knowledge graph | Phase 2 consideration |
| Subscriber count optional (yt-dlp) | Flat search doesn't include it | Use --detailed flag |

---

## Safety Guards

1. **No code mutation** — the pipeline only writes to `vault/research/` and never touches source code
2. **No credential exposure** — the script never reads or prints env vars, API keys, or tokens
3. **No auto-memory** — owner-memory is never modified by the pipeline
4. **NotebookLM is off by default** — requires explicit `--notebooklm` flag
5. **Vault-research-only output** — all output is confined to the vault research directory
6. **Source count limits** — default 5, max 20 (prevents runaway search)
7. **Dependency preflight** — warns if yt-dlp or notebooklm-py are missing

## Adapter Policy (v0.2.1 production-core)

The pipeline must remain usable without secrets. This is a hard design constraint.

**Canonical primary web adapter:** `websearch` (built-in, no API key required). This is the default path for discovering web sources.

**Manual web fetch / open web page:** Fallback and verification/recovery mechanism only. Use a direct URL fetch or open when a specific result needs verification, a websearch result fails, or a source block (403/404) requires an alternate authoritative URL. Manual web fetch is **not** the primary discovery adapter because it is less deterministic and more agent-dependent.

**Optional semantic adapter:** Exa MCP, only when `EXA_API_KEY` is configured in the environment. Exa provides higher-quality semantic search but introduces API-key management. Missing or unauthenticated Exa is **not a failure**.

**Fallback behavior:** If Exa MCP is unavailable, not authenticated, or returns an error, silently fall back to `websearch`. Do not block the pipeline.

**Secret rule:** The pipeline works without any secrets. Exa is an enhancement, not a requirement. NotebookLM, Firecrawl, PDF ingestion, plugin hooks, and memory distillation remain deferred.

---

## Related

| Resource | Location |
|---|---|
| Research Output Contract | `vault/protocols/research/RESEARCH_OUTPUT_CONTRACT.md` |
| yt-search skill | `.opencode/skills/yt-search/SKILL.md` |
| yt-search script | `.opencode/scripts/yt-search.sh` |
| Existing research notes | `vault/research/` |
