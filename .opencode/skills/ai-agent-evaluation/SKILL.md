---
name: ai-agent-evaluation
description: >
  Design, run, and maintain evaluations for LLM features and AI agents. Trigger when
  the user changes a prompt, model, tool definition, agent loop, retrieval pipeline,
  or any code path whose behavior depends on a model — also when results "feel worse"
  after a change, when migrating between models (Opus 4.6 → 4.7, Sonnet 4.5 → 4.6,
  GPT → Claude, Gemini → Claude), when adding a new agent capability, or when the
  user asks to "evaluate", "benchmark", "regression test", "score", "judge", or
  "compare" model output. Required before shipping any prompt or model change to
  production. Covers golden datasets, rule-based and LLM-as-judge scoring, prompt
  regression suites, trace analysis, and CI wiring across this workspace's AI
  products (Hermes, example-orchestrator, example-platform, sample-service, Eliza, example-app).
---

# AI Agent Evaluation

> Activate for: any change to prompts, models, tool definitions, agent loops, RAG pipelines, or anything whose output depends on a model.
> HARD RULE: No prompt or model change ships to production without a regression eval that beats or matches the prior baseline on the same dataset.

---

## Why This Exists

LLM features fail silently. A prompt change can make 80% of cases better and 20% catastrophically worse, and you will not notice from spot-checks. Evals are the only way to know.

Spot-checking 3-5 examples is **not** evaluation — it is confirmation bias dressed as testing. If you cannot point to a dataset, scores, and a comparison against a baseline, you have not evaluated the change.

---

## The Protocol

### Phase 1: Define the quality criterion (before writing any eval code)

Answer in writing:

1. **What does "good" output look like for this feature?** Concrete, observable properties — not "helpful" or "high quality."
2. **What is the failure mode you most fear?** (e.g., hallucinated facts, wrong tool call, unsafe response, off-topic, format break)
3. **Who is the judge?** A rule (regex, schema, exact match), a model (LLM-as-judge with rubric), or a human?
4. **What is the unit of evaluation?** Single response, full conversation trace, end-to-end task success?

If you cannot answer all four, stop and brainstorm with the user. An eval without a defined criterion measures nothing.

### Phase 2: Build the golden dataset

The dataset is the eval. Bad dataset → useless eval no matter how clever the scoring.

**Minimum viable dataset:** 20 cases. Better: 50–200. For high-stakes paths (auth, payments, schema-affecting tool calls): 200+.

**Composition rules:**
- **60% representative happy path** — what users actually send most often
- **30% known failure modes** — cases the system has gotten wrong before (mine these from production logs, support tickets, prior bug reports)
- **10% adversarial** — prompt injection, ambiguous input, edge cases, off-topic requests

**Sources to mine:**
- `vault/agent-protocols/` (workspace AI history)
- `paperclip-PROD/server/src/onboarding-assets/`
- Production traces from Langfuse / LangSmith / Anthropic Console if connected
- Prior git commits that fixed AI bugs — the failing input that triggered the fix is gold

**Storage:** JSONL or CSV at `<repo>/evals/datasets/<feature>.jsonl`. Schema:

```jsonl
{"id": "case_001", "input": "...", "expected": "...", "tags": ["happy_path", "tool_call"], "notes": "real prod ticket #4521"}
```

`expected` is a structured criterion, not a literal string. Examples:
- `{"must_call_tool": "create_order", "must_include": ["confirmation_id"], "must_not_include": ["price"]}`
- `{"format": "json", "schema": "order_schema_v2.json"}`
- `{"rubric": "response correctly summarizes the user's portfolio risk in <80 words, mentions volatility, does not give financial advice"}`

### Phase 3: Choose the scoring method

Match scorer to criterion. Cheaper/faster scorers always win when they suffice.

| Criterion type | Scorer | Cost | Use when |
|---|---|---|---|
| Exact format / schema | JSON schema validation, regex | ~free | Tool-call args, structured output, JSON responses |
| Specific tool was called with right args | Trace inspection (parse `tool_use` blocks) | ~free | Agent loops, function calling |
| Substring / pattern present-or-absent | Regex / string contains | ~free | "Must mention X", "must not say Y" |
| Semantic similarity to reference | Embedding cosine sim | cheap | Translation, paraphrase, "matches gist" |
| Open-ended quality / rubric | LLM-as-judge (Claude Haiku as judge) | $$ | Summaries, explanations, multi-criteria |
| Subjective UX / "does this feel right" | Human review (sample N=20 from full run) | $$$ | Tone, brand voice, sensitive content |

**LLM-as-judge rules:**
- Use a *different* model family than the one being evaluated when possible (avoid in-family bias).
- Provide a numeric rubric (1–5 with anchored descriptions per score), not "rate 1-10."
- Always show the judge the input, the output, and the criterion — never just the output.
- Calibrate: hand-score 20 cases yourself, then check the judge agrees on at least 16/20. If not, fix the rubric before trusting the judge.

### Phase 4: Establish the baseline

Before changing anything:

1. Run the current production prompt/model against the dataset.
2. Save scores to `<repo>/evals/results/<YYYY-MM-DD>-<branch>-baseline.json`.
3. Note: model ID, prompt hash, dataset hash, total cost, p50/p95 latency, pass rate, per-tag breakdown.

If you skip the baseline, you have no way to claim "this is better."

### Phase 5: Iterate, then compare

After your prompt/model change:

1. Run against the same dataset.
2. Save new results alongside baseline.
3. **Compare per-case, not just aggregate.** A 5% pass-rate improvement that breaks 3 previously-passing cases may be a regression in disguise — those 3 broken cases might be the high-value ones.
4. Look at every regression (case that passed before, now fails) — explain each one before declaring victory.

**Ship gates:**
- Pass rate ≥ baseline on every tag (no tag regresses)
- No safety/adversarial case regresses, ever
- p95 latency within 1.5× of baseline (or justified)
- Cost-per-call within 1.5× of baseline (or justified)

If a regression is acceptable (e.g., 1 edge case got worse but 10 happy-path cases got better), document the trade in the commit message.

### Phase 6: Wire into CI (only after evals stabilize)

Once the eval runs reliably and you trust the scoring:

- Add `pnpm eval:<feature>` script that runs the suite and exits non-zero if pass rate < baseline.
- Add a CI workflow that runs evals on PRs touching `prompts/`, `agents/`, `src/llm/`, etc. (path-filtered — evals are expensive).
- Cache results by (prompt_hash, model_id, dataset_hash) to skip reruns.
- Post results as a PR comment.

Don't run evals on every commit — they cost real money and time. Path-filter to LLM-related changes only.

---

## Workspace-Specific Notes

This workspace already has eval infrastructure in several places — **use what exists before building new**:

- `ai-evals-lab/` — workspace-level eval harness (currently `needs_contract`; see if it has reusable rigging)
- `vault/agent-protocols/eval-runner.sh` — reference runner from prior work
- `.opencode/benchmarks/` — model comparison results (9 models × 3 tasks already done)
- Recent commits `f42940b`, `c596b84`, `fa4399c` reference completed model comparison evals — read those first

For Anthropic-API-based evals, prefer the **Anthropic Workbench eval feature** for one-off comparisons, the **`anthropic` SDK with batch API** for large dataset runs (50% cheaper than realtime).

---

## Common Mistakes to Catch

| Mistake | Why it's wrong | Fix |
|---|---|---|
| "Looks better in 3 examples I tried" | Sample size 3 has zero statistical power | Run the full dataset |
| Using the same model as judge AND evaluatee | In-family bias inflates scores | Use a different family; prefer Haiku judging Sonnet/Opus |
| Vague rubric ("rate 1-10 on quality") | Different runs give different scores for the same output | Anchored rubric, 1-5 scale, 1-2 sentence per anchor |
| Dataset = whatever was easy to write | Misses real failure modes | Mine production logs and prior bug reports |
| Comparing aggregate pass rate only | Hides per-segment regressions | Tag cases, compare per-tag |
| Running evals only after shipping | Defeats the purpose | Eval before merge, gate the PR |
| No baseline saved | "Better" is unfalsifiable | Save baseline JSON before any change |

---

## Quick Reference: Tools

- **Anthropic SDK (batch API)** — large dataset runs, 50% cheaper than realtime. Use this for any dataset >100 cases.
- **promptfoo** — TS/JS-friendly eval framework, supports multiple providers, side-by-side diff UI. Good for prompt-engineering iteration.
- **Inspect AI** (UK AISI, OSS) — Python, agent-focused, supports trajectory eval and tool-use scoring. Good for agent loops.
- **Langfuse** (self-host) — trace storage + eval runs against historical traces. Good when you already have production tracing.
- **LangSmith** — managed alternative to Langfuse, tighter LangChain coupling.
- **Anthropic Console eval feature** — quickest path for ad-hoc prompt comparisons; export JSONL when graduating to a real harness.

See `references/scoring-rubric-templates.md` for ready-to-use LLM-judge rubrics.
