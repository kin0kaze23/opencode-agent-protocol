# Compaction Continuity Safeguard

> **Purpose:** Prevent session death after compaction across ALL models
> **Last Updated:** 2026-07-08
> **Status:** Active Production Safeguard — GLM-5.2 Compaction Primary + Session Budget Guard

## Problem Statement

When OpenCode sessions reach high token usage (70-85% of context window), compaction triggers to compress context. However, some models (especially MiMo V2.5 Free/Pro) fail to continue after compaction, causing:

1. Session appears "dead" — no response after compaction indicator
2. Context loss — task state not properly reconstructed
3. User frustration — forced to restart session

## Root Cause Analysis

### P0 Hook Crash Root Cause — 2026-06-21

The 2026-06-20 broken session showed `compaction hook entered` with `repo=null` and no follow-up `context injected`, `safe skip`, or `compaction completed` event. Workspace-root OpenCode sessions can resolve to `repo=null`; the previous hook then attempted to build paths through an unvalidated repo value, which can throw before native OpenCode compaction continues.

Fix principle:

- Custom context injection is optional; native OpenCode compaction must remain the fallback.
- The compaction hook must never throw an uncaught exception.
- Workspace-root sessions must read workspace-root `NOW.md` / `PLAN.md` safely or skip injection safely.
- Every hook invocation must emit a terminal observable outcome: `success`, `safe_skip`, or `handled_error`.
- Provider unavailability must be observable separately from hook failures.

| Factor | Old Value | Problem | New Value |
|--------|-----------|---------|-----------|
| `reserved` | 20,000 (schema-invalid legacy key previously used) | Too small — compaction triggers too early | 40,000 |
| `prune` | `true` | Aggressive context removal — loses critical task state | `false` |
| `tail_turns` | (not set) | No explicit preservation of recent turns | `3` |
| `preserve_recent_tokens` | (not set) | Recent context not guarded across compaction | `6000` |
| `agent.compaction` | (not set) | Active chat model (possibly weak/unevaluated) performs compaction | `opencode-go/glm-5.2` |
| `agent.summary` | (not set) | No dedicated summarizer | `opencode-go/glm-5.2` |

### Why MiMo V2.5 Fails

MiMo V2.5 Free/Pro models have:
- Smaller effective context window than Qwen models
- Weaker post-compaction reconstruction capability
- More sensitive to aggressive pruning

The combination of early compaction trigger + aggressive pruning = failure to continue.

## Strategic Fix (Model-Agnostic)

### 1. Conservative Compaction Settings

```json
"compaction": {
  "auto": true,                     // Keep auto-compaction enabled
  "prune": false,                   // DISABLE aggressive pruning
  "reserved": 40000,                // Double the buffer (20K → 40K)
  "tail_turns": 3,                  // Preserve recent turns verbatim
  "preserve_recent_tokens": 6000    // Guard recent context bytes
}
```

### 2b. Dedicated compaction/summary agents

```json
"agent": {
  ...
  "summary": {
    "model": "opencode-go/glm-5.2",
    "mode": "subagent",
    "description": "Summary helper — dedicated continuity-aware summarizer. Only a compaction-safe model is allowed.",
    "prompt": "{file:prompts/summary.md}",
    "permission": { "edit": "deny", "bash": "deny", "task": { "*": "deny" } },
    "temperature": 0.1,
    "steps": 40
  },
  "compaction": {
    "model": "opencode-go/glm-5.2",
    "mode": "subagent",
    "description": "Compaction helper — dedicated agent used to compress full context. Only a compaction-safe model is allowed.",
    "prompt": "{file:prompts/compaction.md}",
    "permission": { "edit": "deny", "bash": "deny", "task": { "*": "deny" } },
    "temperature": 0.1,
    "steps": 40
  }
}
```

### 2. Why These Changes Work

| Change | Effect | Benefit |
|--------|--------|---------|
| `prune: false` | Preserves more context history | Model has more data to reconstruct task state |
| `reserved: 40000` | Compaction triggers later (at ~60% instead of ~80%) | More runway before compression needed |
| `tail_turns: 3` + `preserve_recent_tokens: 6000` | Recent turns kept verbatim during compaction | Less dependence on a weak summarizer |
| `agent.compaction` / `agent.summary` = `opencode-go/qwen3.6-plus` | Compaction uses a verified model | Weak active chat model cannot corrupt session memory |

### 3. Token Budget Visualization

```
OLD: [=====20K reserved=====][==========80K usable==========]
     ↑ Compaction triggers early (at 80% usage)

NEW: [=========40K reserved=========][======60K usable======]
     ↑ Compaction triggers later (at 60% usage)
     ↑ More context preserved
```

### 4. Hook Fail-Open Stabilization

`.opencode/plugins/brain-hooks.js` now treats compaction context injection as best-effort:

- `repo=null` / workspace-root sessions resolve to the workspace root instead of throwing.
- The entire `experimental.session.compacting` hook is wrapped in `try/catch`.
- If context generation or injection fails, the hook logs `outcome: "handled_error"` and returns without rethrowing, allowing native OpenCode compaction to continue.
- If no useful context exists or the OpenCode hook output shape is not injectable, the hook logs `outcome: "safe_skip"` and allows native compaction to continue.
- Successful anchor injection logs `outcome: "success"`.
- Recent provider-unavailable signals are logged as `providerStatus` / `outcome: "provider_unavailable"` without printing secrets.

### 5. P0.2 Temporary Compaction Fallback — SEALED 2026-07-08

The P0.2 temporary fallback to `umans-ai-coding-plan/umans-kimi-k2.7` has been **sealed and rolled back**. OpenCode Go provider availability is restored, and `opencode-go/glm-5.2` passed a dedicated compaction eval (2026-07-08).

**Rollback evidence:**
- OpenCode Go preflight: qwen3.6-plus ✅, qwen3.7-plus ✅, glm-5.2 ✅ (all returned non-empty OK)
- GLM-5.2 compaction eval: 32K/64K/128K/256K/512K all PASS, 7/7 fields preserved, fresh-session restoration PASS
- GLM-5.2 has ~1M context window, matching the active chat model (umans-glm-5.2)

**New configuration:**
- `agent.compaction.model = "opencode-go/glm-5.2"` (1M context)
- `agent.summary.model = "opencode-go/glm-5.2"` (1M context)
- `umans-kimi-k2.7` retained as bounded fallback for sessions <=180K tokens only
- `compaction.prune = true` (enabled for long-session token management)
- `compaction.reserved = 200000` (trigger compaction earlier)

**Why GLM-5.2 instead of kimi-k2.7 or qwen3.7-plus:**
- kimi-k2.7 has 256K context — too small for sessions grown by a 1M-context chat model
- qwen3.7-plus has ~128K context — even smaller
- GLM-5.2 has ~1M context — matches the chat model, can handle any session size

## Model-Specific Guidance

### GLM-5.2 (Primary Compaction Model — 1M Context)

- **Safe token range:** 0 - 800K tokens (no compaction needed)
- **Compaction zone:** 800K - 950K tokens (GLM-5.2 can handle this)
- **Danger zone:** 950K+ tokens (approaching 1M limit — checkpoint immediately)

GLM-5.2 has ~1M context window, matching the active chat model (umans-glm-5.2). This eliminates the context-exceeds-model-limit failure that occurred with kimi-k2.7 (256K).

### Kimi K2.7 (Bounded Fallback — 256K Context)

- **Safe fallback range:** 0 - 180K tokens (compaction can use kimi-k2.7)
- **Danger zone:** 180K+ tokens (DO NOT use kimi-k2.7 for compaction — exceeds safe budget)
- **Hard rule:** If session exceeds 180K tokens, GLM-5.2 must be used or force checkpoint + fresh session

### Qwen 3.7 Plus (Bounded Fallback — ~128K Context)

- **Safe fallback range:** 0 - 100K tokens (compaction can use qwen3.7-plus)
- **Danger zone:** 100K+ tokens (DO NOT use qwen3.7-plus for compaction — exceeds safe budget)
- **Hard rule:** If session exceeds 100K tokens, GLM-5.2 must be used or force checkpoint + fresh session

### MiMo V2.5 Free/Pro

- **Safe token range:** 0 - 40K tokens (no compaction needed)
- **Compaction zone:** 40K - 60K tokens (conservative compaction)
- **Danger zone:** 60K+ tokens (may still fail — avoid if possible)

**Recommendation:** Keep sessions under 40K tokens when using MiMo V2.5. Use `/checkpoint` to save progress before hitting 40K.

### Qwen 3.6/3.7 Plus (Premium Models)

- **Safe token range:** 0 - 60K tokens
- **Compaction zone:** 60K - 80K tokens
- **Danger zone:** 80K+ tokens

These models handle compaction better but still benefit from conservative settings.

### DeepSeek V4 Flash (Budget Model)

- **Safe token range:** 0 - 30K tokens
- **Compaction zone:** 30K - 50K tokens
- **Danger zone:** 50K+ tokens

Smallest context window — use for short, focused tasks only. **Not compaction-safe.**

### Unevaluated / Non-Registry Models

Any model not listed in the workspace model registry (for example, providers that are not `opencode-go/*` or `opencode/*`) must be treated as **not compaction-safe** until it passes a dedicated compaction eval. If such a model is active as the chat/orchestrator model, OpenCode routes compaction to `agent.compaction`, which is configured to use a verified compaction-safe model. (`agent.summary` is not used by automatic compaction; it is a separate built-in agent for other summarization surfaces.)

## Prevention Strategies

### 0. Session Budget Guard (HARD RULE)

The session budget guard prevents OpenCode from accidentally sending a giant session to a small compaction model.

| Session Size | Action |
|---|---|
| 0–150K tokens | Normal operation. Any compaction-safe model may be used. |
| 150K–220K tokens | Checkpoint soon. Kimi-k2.7 fallback still safe. |
| 220K–500K tokens | GLM-5.2 compaction only. Do NOT use kimi-k2.7 or qwen3.7-plus. |
| 500K–800K tokens | Force GLM-5.2 compaction + write external checkpoint to `.opencode/session-state/CURRENT.md`. |
| 800K+ tokens | No small-model fallback allowed. Create rescue checkpoint and start fresh session. |

**Hard guard rule:** Small compaction models (kimi-k2.7: 256K, qwen3.7-plus: 128K) must NEVER receive sessions larger than their safe input budget. If session size exceeds the fallback model budget, force GLM-5.2 compaction or write a checkpoint and start a fresh session.

### 0b. Mandatory Checkpoint Packets

Every major slice should write a small durable checkpoint file:

```
.opencode/session-state/CURRENT.md
```

Keep it under 3K–8K tokens. Include:
- Current objective
- Repo/branch/PR
- Latest commit
- Files changed
- Tests run
- Known failures
- Decisions made
- Do-not-exact command

This gives recovery even if compaction fails.

### 0c. One Session Per Slice

Do not let one OpenCode session carry the whole multi-repo rollout forever.

**Operating rule:** One session = one slice, one PR phase, or one bounded fix.

Example:
- Session 1: inspect failure and plan
- Session 2: implement config fix
- Session 3: run eval
- Session 4: update docs/registry/guards
- Session 5: PR final review

### 0d. Externalize Large Tool Outputs

Never let huge logs, test output, generated diffs, or audit reports live only inside chat context.

Instead:
- Write logs to `.agent/reports/`
- Summarize only the important findings into chat
- Keep raw output out of the session

This is one of the highest ROI fixes for compaction reliability.

### 0e. Pin Governance Outside Compaction

Long-horizon compaction can drop important rules ("governance decay"). Keep policy in durable files:

- `.opencode/rules.md`
- `.opencode/COMPACTION-SAFEGUARD.md`
- `.opencode/model-registry.yaml`
- `.opencode/helper-roster.md`

The compactor should summarize state, not be the only place where policy lives.

### 1. Proactive Checkpointing

Before hitting 40K tokens, save your progress:

```
/checkpoint
```

This preserves:
- Current task state
- Touch list
- Decisions made
- Next steps

### 2. Session Segmentation

Break long tasks into smaller sessions:

```
Session 1: Planning (0-30K tokens) → /checkpoint
Session 2: Implementation (0-30K tokens) → /checkpoint
Session 3: Review (0-30K tokens) → /checkpoint
```

### 3. Monitor Token Usage

Watch the status bar for token count:

- **Green zone:** < 40K tokens — safe
- **Yellow zone:** 40K-60K tokens — consider checkpointing
- **Red zone:** > 60K tokens — high risk of compaction failure

Until large-transcript compaction is proven end-to-end, use a stricter operating envelope even on large-context active models:

- **Checkpoint/restart before ~80K–100K tokens.**
- Do not let routine development sessions grow to 200K+ tokens when the dedicated compaction model is only validated around the Qwen safe/compaction range.
- Treat 200K+ sessions as emergency recovery territory, not normal operating mode.

### 3b. Provider Availability Discipline

The configured compaction model is `opencode-go/glm-5.2` (1M context). If OpenCode Go returns quota/balance/provider errors, fall back to `umans-kimi-k2.7` for sessions <=180K tokens only. For sessions >180K tokens, do NOT use kimi-k2.7 — force checkpoint and start a fresh session instead.

1. Run a provider preflight before intentionally starting long sessions.
2. If OpenCode Go is unavailable and session is >180K tokens, either keep the session short enough to avoid compaction or start a fresh session.
3. Emergency mode is native/default compaction with custom hook injection safely skipped or fail-open; it is a continuity fallback, not proof that provider-backed compaction succeeded.

### 4. Use Appropriate Models for Task Size

| Task Size | Recommended Model | Why |
|-----------|-------------------|-----|
| Small (< 20K tokens) | MiMo V2.5 Free | Fast, cheap, reliable for short tasks |
| Medium (20K-40K tokens) | Qwen 3.6 Plus | Better compaction handling |
| Large (> 40K tokens) | Qwen 3.7 Plus | Best context management |

## Recovery Procedure

If compaction failure occurs:

### Step 1: Don't Panic

The session data is NOT lost. It's in OpenCode's snapshot system.

### Step 2: Start New Session

```bash
opencode $WORKSPACE_ROOT
```

### Step 3: Recover

```
/recover
```

This will:
- Load the last snapshot
- Restore task context
- Resume from where you left off

### Step 4: Verify Continuity

Check that the recovered session has:
- [ ] Correct repo context
- [ ] Current task state
- [ ] Touch list (if applicable)
- [ ] Next steps

## Testing the Fix

### Test Case 1: MiMo V2.5 Free — Short Session

1. Start session with MiMo V2.5 Free
2. Do 10-15 tool calls (should stay under 40K tokens)
3. Verify session completes without compaction
4. **Expected:** No compaction triggered, session completes

### Test Case 2: MiMo V2.5 Free — Medium Session

1. Start session with MiMo V2.5 Free
2. Do 20-30 tool calls (should hit 40K-50K tokens)
3. Verify compaction triggers but session continues
4. **Expected:** Compaction at ~40K tokens, session continues

### Test Case 3: Qwen 3.7 Plus — Long Session

1. Start session with Qwen 3.7 Plus
2. Do 40-50 tool calls (should hit 60K-80K tokens)
3. Verify compaction triggers and session continues
4. **Expected:** Compaction at ~60K tokens, session continues

## Runtime Delegation Verification

OpenCode 1.17.8 supports automatic compaction model delegation through the built-in `compaction` agent:

- `agent.compaction.model` — when set, OpenCode routes the **automatic** compaction summary LLM call through this model instead of the active chat model.
- `agent.summary.model` — **not used by automatic compaction**. It configures the separate built-in `summary` agent, which is used for other summarization surfaces (for example, explicit `/summary` functionality) but not the `SessionCompaction.process` path.

This was confirmed by source audit of the OpenCode 1.17.8 bundle (`/Applications/OpenCode.app/Contents/Resources/app.asar`):

```javascript
// SessionCompaction.process (~line 298266 in the 1.17.8 bundle)
const agent = yield* agents2.get("compaction");
const model8 = agent.model
  ? yield* provider102.getModel(agent.model.providerID, agent.model.modelID).pipe(exports_Effect.orDie)
  : yield* provider102.getModel(userMessage.model.providerID, userMessage.model.modelID).pipe(exports_Effect.orDie);
```

Key facts:

- If `agent.compaction.model` is configured, OpenCode uses it.
- Only if the compaction agent has **no** model override does it fall back to the active `userMessage.model`.
- The compaction assistant message is created with the resolved model (`modelID` / `providerID`).
- The `experimental.session.compacting` plugin hook can mutate **prompt/context only**; it cannot change the compaction model.
- `agent.summary` is not read by `SessionCompaction.process`; automatic compaction uses `agent.compaction` only.

### What the plugin can observe

The `.opencode/plugins/brain-hooks.js` plugin logs:

- At initialization: `configuredCompactionModel` and `configuredSummaryModel` read from `.opencode/opencode.json`.
- At `experimental.session.compacting`: that the hook entered and what the configured compaction model is.
- At `session.compacted`: that compaction completed and what the configured compaction model was.

The plugin cannot directly inspect the compaction assistant message `modelID`/`providerID` because the OpenCode plugin API does not expose session messages to `event` hooks. The actual model used is guaranteed by the audited source path, not by plugin observation.

### Conformance guards

The workspace protocol guard enforces this at check-time:

- `CSA-010` resolves `opencode debug config` and asserts that `agent.compaction.model` and `agent.summary.model` point to a `compaction_safe` model.
- `CSA-011` greps the installed OpenCode 1.17.8 `app.asar` and asserts that the `SessionCompaction.process` source still contains the `agent.model` delegation path. This catches upstream regressions on upgrade.

### Manual Spot-Check

```bash
opencode debug config --print-logs=false > /tmp/oc-resolved.json
python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print('compaction:', d['agent']['compaction']['model']); print('summary:', d['agent']['summary']['model'])" /tmp/oc-resolved.json
```

Expected:

```
compaction: opencode-go/glm-5.2
summary: opencode-go/glm-5.2
```

> **Important:** Do not paste full `opencode debug config` output into chat, issues, or docs. Use the filtered snippet above.

## Monitoring and Alerts

### Token Usage Warning Thresholds

| Threshold | Action |
|-----------|--------|
| 30K tokens | Informational — "Approaching compaction zone" |
| 40K tokens | Warning — "Consider /checkpoint" |
| 50K tokens | Critical — "High risk of compaction failure" |
| 60K tokens | Emergency — "Save immediately with /checkpoint" |

### Implementation

Add to your workflow:

```
# Before starting work
echo "Token budget: 40K tokens for MiMo, 60K for Qwen"

# During work
# Watch status bar for token count

# At 30K tokens
/checkpoint

# At 40K tokens (MiMo) or 60K tokens (Qwen)
/checkpoint --force
```

## Rollback Plan

If the conservative settings cause issues (e.g., sessions hitting hard limits more often):

1. Revert to more aggressive pruning (only if conservative settings cause hard-limit issues):
   ```json
   "compaction": {
     "auto": true,
     "prune": true,
     "reserved": 30000,
     "tail_turns": 2,
     "preserve_recent_tokens": 4000
   }
   ```

2. Monitor for 1 week

3. Adjust based on results

## Success Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Compaction failure rate | < 5% | Track sessions that die after compaction |
| Session completion rate | > 95% | Track sessions that complete successfully |
| User satisfaction | > 4/5 | Survey after compaction events |

## FAQ

### Q: Does this mean I can never hit the limit?

**A:** No. You can still hit the hard context limit. The fix makes compaction trigger earlier and preserve more context, reducing the chance of failure — not eliminating the limit.

### Q: Will this slow down my sessions?

**A:** Slightly. Conservative compaction means:
- Compaction triggers later (more tokens used before compression)
- More context preserved (slightly slower model responses)

Trade-off: reliability over speed.

### Q: What if I need very long sessions?

**A:** Use Qwen 3.7 Plus for long sessions (> 60K tokens). MiMo V2.5 is best for medium sessions (< 40K tokens).

### Q: Is there a way to disable compaction entirely?

**A:** Yes, but not recommended:
```json
"compaction": {
  "auto": false,
  "prune": false,
  "reserved": 0
}
```
This will eventually hit the hard limit and crash.

## Plugin Auto-Load Verification

The `brain-hooks.js` plugin lives at `.opencode/plugins/brain-hooks.js`. OpenCode auto-loads local plugins from this directory; no `plugin` array entry is required in `.opencode/opencode.json`.

Runtime evidence:
- OpenCode version: `1.17.8`
- Latest log line: `message="brain-hooks plugin initialized" directory=$WORKSPACE_ROOT`
- Compaction hook entered during this session (`message="compaction hook entered"`).

Because local plugin auto-loading is confirmed, the plugin is **not** registered in global config and its placement remains unchanged.

The plugin now also emits `configuredCompactionModel` at initialization and logs compaction start/completion events with the configured model. This provides runtime observability that compaction occurred while the configured override was active; the actual model used remains governed by the audited OpenCode source path.

As of the P0 hook fail-open patch, the plugin also logs terminal hook outcomes:

- `outcome: "success"` — continuity context was injected.
- `outcome: "safe_skip"` — custom injection was skipped safely and native compaction may continue.
- `outcome: "handled_error"` — hook error was caught and native compaction may continue.
- `outcome: "provider_unavailable"` — recent quota/balance/provider failure signal was detected for the configured compaction model.

## References

- OpenCode Compaction Documentation
- Model Context Window Specifications
- Workspace Protocol: `.opencode/rules.md` (Compaction Continuity section)
- ADR: `adr-opencode-config-authority.md`

```

## OpenCode Go Provider Switchback Procedure

Use this checklist only after P0.2 is sealed (real TUI `/recover` + `/checkpoint` + observed terminal compaction outcome with the Kimi fallback) and **after** OpenCode Go provider availability is restored. This is a deliberate rollback of the temporary P0.2 fallback, not an automatic drift.

1. Verify `opencode-go/qwen3.6-plus` (or `opencode-go/qwen3.7-plus`) provider preflight passes.
2. In `.opencode/opencode.json`, switch both agents back to the verified OpenCode Go compaction-safe model:
   - `agent.compaction.model = "opencode-go/qwen3.6-plus"`
   - `agent.summary.model = "opencode-go/qwen3.6-plus"`
3. In `.opencode/model-registry.yaml`, update the `umans-temporary-compaction` profile status to `inactive_rolled_back` and remove `umans-kimi-k2.7` from `compaction_policy.safe_models` if it is still listed as a permanent safe model (temporary fallback entry under `umans-ai-coding-plan` candidates may be retained for audit history).
4. Run local gates:
   - `node --check .opencode/plugins/brain-hooks.js`
   - `bash .opencode/conformance/tests/compaction-safety.sh`
   - `bash .opencode/scripts/workspace-protocol-guard.sh`
5. Fully restart OpenCode from your workspace root.
6. Start a fresh session and `/recover` if needed; immediately `/checkpoint`.
7. Continue until one auto-compaction fires.
8. Observe logs for a terminal outcome: `success`, `safe_skip`, `handled_error`, or `provider_unavailable`.
9. If the session survives compaction and the configured OpenCode Go model is confirmed in logs, mark the switchback sealed. If any failure or regression occurs, revert to `umans-ai-coding-plan/umans-kimi-k2.7` and keep the 80K–100K cap.

Do **not** perform the switchback without explicit owner approval and a passing provider preflight.

---

**Last verified:** 2026-07-08
**Verified by:** Owner Agent
**Status:** Production Ready — GLM-5.2 compaction primary (1M context, eval passed), kimi-k2.7 bounded fallback (<=180K), session budget guard active, prune enabled, P0.2 sealed
