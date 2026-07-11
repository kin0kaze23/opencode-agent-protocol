---
name: ecosystem-scan
description: Scans the broader ecosystem for library alternatives, community consensus, and competitive analysis when out-of-scope keywords are detected.
---

# Ecosystem Scan Skill

**Model:** qwen3.6-plus (escalate to qwen3.6-plus for large-scale codebase scanning)
**Access:** Read-only (no file writes, no commits)
**Purpose:** Codebase + library ecosystem analysis using available tools only

---

## When To Activate

Activate when the request involves:
- "ecosystem scan" or "ecosystem analysis"
- "library analysis" or "dependency alternatives"
- "internal patterns" or "codebase conventions"
- "what libraries do we use" or "what's our stack"
- "find similar patterns" or "where is X implemented"

**ALSO activate for OUT-OF-SCOPE clarification** when request contains:
- "what are people saying", "reddit", "twitter", "x", "hacker news", "hn"
- "last 30 days", "community consensus", "best practices in 2026"
- "market research", "competitive analysis"

For out-of-scope requests, activate this skill to clarify limitations (see Out-Of-Scope section).

---

## Available Sources

### Tier 1: VERIFIED Sources

| Source | What It Provides | Citation Format |
|--------|------------------|-----------------|
| **context7 MCP** | Library docs, API reference | `context7: <library>@<version>` |
| **Exa MCP** | Approved technical + general web search | `exa: <url or result id>` |
| **Repo files** | Code, architecture, state | `<repo>/<path>:<line>` |
| **Git history** | Commit history, blame | `git:<repo>@<commit-hash>` |
| **vault/lessons.md** | Internal lessons learned | `vault/projects/<repo>/lessons.md` |
| **vault/subjects/*.md** | Cross-repo knowledge | `vault/subjects/<subject>.md` |

### Tier 2: INFERRED Sources (Discovery Only)

| Source | What It Provides | Citation Format |
|--------|------------------|-----------------|
| **`gh search`** | GitHub code matches | `gh search: <query>` |
| **`npm search`** | Package metadata | `npm: <package>@<version>` |

### Tier 3: OUT-OF-SCOPE (Cannot Access)

| Source | Why Unavailable |
|--------|-----------------|
| **General web search (without approved MCP)** | No approved search tool available |
| **Reddit/X/HN sentiment synthesis** | No social API access and no safe consensus synthesis |
| **Broad news/trends without cited pages** | No safe recency summary without direct sources |
| **Vendor comparisons** | No market research tools |
| **StackOverflow** | No API access |

---

## Workflow

1. **Identify request type** — Is it in-scope or out-of-scope?
2. **Gather from Tier 1 sources** — context7, approved Exa, repo files, vault
3. **Optional: Tier 2 discovery** — `gh search` / `npm search` for leads
4. **Classify claims** — VERIFIED (Tier 1) vs. INFERRED (Tier 2)
5. **Document out-of-scope** — List what requires manual research
6. **Return structured report**

---

## Output Format

```markdown
## Ecosystem Scan Report — <topic>

### VERIFIED Findings (Tier 1 Sources)

| Finding | Source | Confidence |
|---------|--------|------------|
| <claim> | <context7/repo/vault citation> | High |

### INFERRED Leads (Tier 2 Discovery)

| Lead | Source | Next Step |
|------|--------|-----------|
| <potential match> | gh search: <query> | Manual verification needed |

### OUT-OF-SCOPE (Requires Manual Research)

| Request | Why Out of Scope | Suggested Alternative |
|---------|-----------------|----------------------|
| <what user asked> | <reason> | <manual research path> |

### Summary

**What I found:** <brief summary of VERIFIED findings>

**What requires manual research:** <brief summary of out-of-scope items>

**Recommended next step:** <actionable advice>
```

---

## Evidence Discipline

### VERIFIED Claims

**Can be labeled VERIFIED when:**
- Source is Tier 1 (context7, approved Exa result with exact source URL, repo files, git, vault)
- Citation includes exact path/line/hash/version
- Claim is directly supported by source content

**Example:**
```
VERIFIED: @hono/hono@4.7.5 supports WebSocket via upgradeWebSocket()
Source: context7: @hono/hono@4.7.5 — WebSocket class documentation
Confidence: High
```

### INFERRED Claims

**Must be labeled INFERRED when:**
- Source is Tier 2 (`gh search`, `npm search`)
- No direct URL/hash citation available
- Claim is based on pattern matching, not direct evidence

**Example:**
```
INFERRED: Most Hono examples use upgradeWebSocket() for WebSocket
Source: gh search: "hono upgradeWebSocket" (5 results, no URL citation)
Confidence: Medium
Next Step: Manual verification of linked repos recommended
```

### OUT-OF-SCOPE Claims

**Must be labeled OUT-OF-SCOPE when:**
- Source would require unapproved web/social/news access
- Recency is required but not available
- Market/competitive analysis requested
- Social/community sentiment is requested without exact supplied posts/pages

**Example:**
```
OUT-OF-SCOPE: "What are the best WebSocket libraries in 2026?"
Reason: Requires web search + recency-aware sources (not available)
Suggested Alternative: Manual research on GitHub Trends, State of JS survey, or vendor documentation
```

---

## Constraints

**CRITICAL: Do NOT simulate external research via WebFetch, curl, shell, or any unapproved tool.**

- Do NOT use WebFetch against Reddit, X, Hacker News, forums, or news sites
- Do NOT use curl or shell commands to scrape social/news sites
- Do NOT claim recency-awareness ("last 30 days", "2026 best practices") unless supported by directly cited search results
- Do NOT fabricate URLs or citations
- Do NOT claim social/community sentiment from search snippets alone
- Do NOT compare vendors on pricing/business terms
- Always include OUT-OF-SCOPE section when request exceeds capability
- Return findings to Owner — do not act on them independently

**This skill clarifies limitations — it does NOT bypass them.**

---

## Example Activations

### In-Scope Request

**User:** "Scan our ecosystem for WebSocket implementations"

**Skill Response:**
```markdown
## Ecosystem Scan Report — WebSocket Implementations

### VERIFIED Findings (Tier 1 Sources)

| Finding | Source | Confidence |
|---------|--------|------------|
| @hono/hono@4.7.5 supports WebSocket via upgradeWebSocket() | context7: @hono/hono@4.7.5 | High |
| sample-service uses upgradeWebSocket() in src/ws/handler.ts | sample-service/src/ws/handler.ts:12-45 | High |
| Previous WebSocket lesson: connection pooling improved latency | vault/projects/sample-service/lessons.md | High |

### INFERRED Leads (Tier 2 Discovery)

| Lead | Source | Next Step |
|------|--------|-----------|
| Similar pattern in example-orchestratorNuggie | gh search: "example-orchestrator upgradeWebSocket" | Manual verification |

### OUT-OF-SCOPE (Requires Manual Research)

| Request | Why Out of Scope | Suggested Alternative |
|---------|-----------------|----------------------|
| "Is this the best library in 2026?" | No recency-aware sources | Manual research on GitHub Trends, State of JS |

### Summary

**What I found:** sample-service uses Hono's upgradeWebSocket() with connection pooling (per vault lessons).

**What requires manual research:** Whether Hono is "best" in 2026 requires external trend research.

**Recommended next step:** Review sample-service/src/ws/handler.ts for implementation details; manual research for library comparison.
```

### Out-Of-Scope Request

**User:** "What are people saying about Hono WebSocket on Reddit?"

**Skill Response:**
```markdown
## Ecosystem Scan Report — Hono WebSocket Community Sentiment

### VERIFIED Findings (Tier 1 Sources)

| Finding | Source | Confidence |
|---------|--------|------------|
| @hono/hono@4.7.5 supports WebSocket via upgradeWebSocket() | context7: @hono/hono@4.7.5 | High |

### INFERRED Leads (Tier 2 Discovery)

N/A — Social sentiment not available via Tier 2 sources.

### OUT-OF-SCOPE (Requires Manual Research)

| Request | Why Out of Scope | Suggested Alternative |
|---------|-----------------|----------------------|
| "What people are saying on Reddit" | No Reddit API access | Manual Reddit search: r/hono, r/webdev |
| "Community consensus" | No social/discussion API | Manual GitHub Issues, Discord, Twitter search |

### Summary

**What I found:** Hono supports WebSocket via upgradeWebSocket() (per context7 docs).

**What requires manual research:** Community sentiment on Reddit, Twitter, Discord requires manual browsing.

**Recommended next step:** Manual search on r/hono, r/webdev, Hono Discord server.
```

---

## Integration With Owner

The Owner may activate this skill during:
- `/advise` sessions (when research informs recommendations)
- `/plan-feature` sessions (when understanding ecosystem before planning)
- `/implement` sessions (when checking library capabilities)

Skill output is advisory — Owner decides how to use findings.
