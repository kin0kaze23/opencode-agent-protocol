---
description: "Get unstuck with 2-3 approaches, trade-offs, and a clear recommendation"
---

# /advise

**Mode:** Mentor
**Model:** qwen3.7-plus (v1.1-production, Action 4D) (escalate to qwen3-max for architecture or rescue)
**Tool access:** Layer A + Layer D for approved research MCPs when needed
**Success output:** Clear recommendation with trade-offs and reasoning

## Behaviour

When invoked, the Owner agent:

1. Runs preflight (repo selection, confidence, mode=Mentor)
2. Detects "I'm stuck" pattern:
   - User says "I'm stuck", "blocked", "unsure what to do", "debugging has stalled"
   - If detected: switch to unblock mode (diagnose blocker → fastest safe path forward)
3. Asks one clarifying question if the direction is genuinely ambiguous
4. Presents 2-3 approaches with trade-offs
5. Applies recommendation rule:
   - **Recommend** when: sufficient context + stakes are reversible
   - **Defer** when: missing critical context OR stakes are irreversible
6. For each approach, states when it's the best choice:
   - "Choose A when: <condition>"
   - "Choose B when: <condition>"
7. For non-trivial decisions, states re-evaluation triggers:
   - "Revisit this advice if: <condition changes>"
8. States the cost of reversal:
   - "If this turns out wrong: <reversal cost>"
9. States what the next concrete action should be

## Output format

```
Recommendation: <one clear direction OR "Defer — <reason>">

Approaches considered:
  A) <option> - <trade-off> - Choose when: <condition>
  B) <option> - <trade-off> - Choose when: <condition>
  C) <option> - <trade-off> - Choose when: <condition> (if applicable)

Why I recommend A: <reasoning>

If this turns out wrong: <reversal cost>
Revisit if: <condition changes> (for non-trivial decisions)

Next action: <one concrete step>
```

## Recommendation Discipline

Before giving advice:

1. State whether recommending or deferring:
   - Recommend: sufficient context + reversible stakes
   - Defer: missing critical context OR irreversible stakes
2. For each approach, state when it's the best choice.
3. For non-trivial decisions, state re-evaluation triggers.
4. State the cost of reversal.

## External Research Limitation

**If /advise request requires web/social/news/recency research:**

Trigger keywords: "what are people saying", "reddit", "twitter", "x", "hacker news", "last 30 days", "community consensus", "best practices in 2026", "market research"

**Required behavior:**
1. If approved search MCPs are available, use only those tools for technical/general web lookup
2. Do NOT use WebFetch, curl, or shell to simulate research
3. Do NOT fabricate citations or community opinions
4. Keep social-sentiment synthesis and unsourced market/pricing claims OUT-OF-SCOPE
5. Suggest manual research alternative when the request still exceeds approved search coverage

**Example response:**
```
OUT-OF-SCOPE: This request requires social/news sentiment research.

**What I can do:**
- Library docs via context7 MCP
- Codebase/internal pattern analysis

**What requires manual research:**
- Reddit/X/HN sentiment
- "Last 30 days" trends
- Community consensus

**Suggested next step:** Manual search on r/webdev, X, Hacker News.
```

## Do not
- Write any code in response to /advise
- Run quality gates
- Spawn helpers unless a read-only codebase scan is needed to answer the question
