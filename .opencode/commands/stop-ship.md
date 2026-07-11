---
description: "Identify release blockers and produce a clear stop-ship decision"
---

# /stop-ship

**Purpose:** Identify showstopper issues that justify blocking release
**Mode:** Reviewer
**Model:** qwen3.7-plus (v1.1-production, Action 4D)
**Tool access:** Layer A (read-only)
**Success output:** Blocker list with severity and ship verdict

## Behaviour

When invoked, the Owner agent:

1. Reviews changes since last `/ship` or branch creation
2. Identifies potential blockers using criteria:
   - **Data loss or corruption risk**
   - **Security vulnerability** (auth bypass, injection, secrets exposure)
   - **Production outage risk** (crash, infinite loop, resource exhaustion)
   - **Regulatory/compliance violation**
   - **Major user-facing bug** affecting core functionality
   - **Missing rollback path** for high-risk changes
3. For each potential blocker:
   - Severity: Critical / High
   - Impact: What breaks for users?
   - Likelihood: How likely is failure?
   - Mitigation: Can it be fixed now, or must we block?
4. Distinguishes blockers from caveats:
   - **Blocker:** Must fix before shipping
   - **Caveat:** Ship with known issue, documented workaround
5. Outputs verdict with clear reasoning

## Output format

```
## Stop-Ship Check — <repo> — <branch/PR>

Blockers found: <count>

[CRITICAL] <file>:<line> — <issue>
- Impact: <what breaks for users>
- Likelihood: <certain/likely/possible>
- Mitigation: <fix now or block>

[HIGH] <file>:<line> — <issue>
- Impact: <what breaks for users>
- Likelihood: <certain/likely/possible>
- Mitigation: <fix now or block>

Not blocking (ship with caveats):
- <issue> — workaround: <description>

Verdict: Ship / Ship with Caveats / Block
```

## Criteria

### Blockers (must fix before ship)

- Data loss or corruption risk
- Security vulnerability (auth bypass, injection, secrets exposure)
- Production outage risk (crash, infinite loop, resource exhaustion)
- Regulatory/compliance violation
- Major user-facing bug affecting core functionality
- Missing rollback path for high-risk changes

### Not blockers (ship with caveats)

- Minor UI polish issues
- Performance optimizations that can wait
- Documentation gaps with workarounds documented
- Test coverage gaps with manual verification done

## When to use

- After `/review`, before `/ship`
- Before merging to main/master
- When confidence is low despite passing gates
- When user asks "should we really ship this?"

## When NOT to use

- Trivial changes (≤2 files, no sensitive paths) — skip to `/ship`
- Early in development — use `/review` instead
- When `/review` already found Critical findings — fix those first

## Protocol alignment

- Complements `/review` (finds issues) with ship/block decision
- Feeds into `/ship` command
- Uses evidence discipline with file/line citations
- Supports red-team review from `evaluation-devils-advocate.md`
