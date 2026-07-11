---
description: "Verify protocol alignment and compliance"
---

# /verify-alignment

**Purpose:** Verify implementation matches spec/PLAN.md before shipping
**Mode:** Reviewer
**Model:** qwen3.7-plus (v1.1-production, Action 4D)
**Tool access:** Layer A (read-only)
**Success output:** Alignment report with gaps, deviations, and verdict

## Behaviour

When invoked, the Owner agent:

1. Identifies the governing contract (in priority order):
   - Active `<repo>/PLAN.md` (canonical contract)
   - Product spec `vault/products/*.md`
   - Repo `AGENTS.md` instructions
   - Documented API contracts
   - Test specifications
2. For each intended behavior in the contract:
   - Implementation status: Implemented / Partial / Missing / Different
   - Evidence: File/line, test result, or observation
   - Alignment: Matches spec / Deviates / Ambiguous
3. Identifies:
   - Matches (implementation aligns with spec)
   - Gaps (spec says X, implementation does nothing)
   - Unintended differences (spec says X, implementation does Y)
   - Ambiguous areas (spec is unclear, implementation made an assumption)
4. For deviations, determines why:
   - Bug (unintentional)
   - Intentional change (should be documented)
   - Misunderstanding (spec was misread)
5. Outputs alignment summary with verdict

## Output format

```
## Alignment Verification — <repo> — <spec/PLAN.md reference>

Governing contract: <file path>

Alignment summary: <percentage> of spec implemented correctly

Matches:
- <behavior> → <file:line> (evidence)
- <behavior> → <file:line> (evidence)

Gaps (spec says X, implementation does nothing):
- [Severity] <behavior> — why missing

Unintended differences (spec says X, implementation does Y):
- [Severity] <behavior> — implementation does Y instead — impact

Ambiguous areas (spec unclear, implementation assumed):
- <behavior> — assumption made — needs clarification

Deviations explanation:
- Bug: <list>
- Intentional (documented): <list>
- Misunderstanding: <list>

Verdict: Aligned / Needs Correction / Major Rework
```

## When to use

- After implementation, before `/ship`
- When drift is suspected between spec and code
- Before merging large features
- When user asks "did you actually build what we planned?"

## Do not

- Use during implementation (wait until feature is complete)
- Use for trivial changes (≤2 files)
- Speculate about why deviations exist without evidence
- Mark complete without citing PLAN.md or spec line numbers

## Protocol alignment

- Uses evidence discipline: VERIFIED / INFERRED / OUT-OF-SCOPE
- References canonical PLAN.md from `.opencode/commands/plan-feature.md`
- Complements `/review` (qualitative) with spec-alignment (contractual)
- Feeds into `/ship` decision
