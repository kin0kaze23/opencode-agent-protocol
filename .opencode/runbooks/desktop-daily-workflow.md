# OpenCode Desktop — Daily Workflow Runbook

> **Runbook:** `.opencode/runbooks/desktop-daily-workflow.md`
> **Purpose:** Daily operator workflow for OpenCode Desktop-as-primary during Release 1 soak.
> **Scope:** Documentation only. No runtime config, model routing, prompt, MCP, plugin, share, submodule, or global config changes.
> **Status:** Draft (pending owner approval)
> **Created:** 2026-06-05
> **Refs:** R1 verdict (`READY_WITH_WARNINGS`); frozen baseline chain `0a1a7db → 7797967`; companion runbooks `opencode-desktop-cli-sync.md` and `daily-ui-agent-workflow.md`.

---

## §1 Operating Model

Release 1 soak has been declared `READY_WITH_WARNINGS`. The operating split is:

| Surface | Role | When to use |
|---|---|---|
| **OpenCode Desktop** | Primary daily build / control surface | Multi-turn work, file diffs, helper agent delegation, design / screenshot review, anything that needs a TUI |
| **OpenCode CLI** | Verification, automation, recovery, sealing surface | `git status`, `pre-commit`, conformance scripts, `oc-status.sh`, scripted workflows, sealing commits |
| **OpenCode TUI** (`opencode` no args) | Same chat surface as Desktop, in a terminal | SSH / tmux / quick terminal sessions when Desktop is not available |
| **IDE extension** (VSCode / Cursor / Zed) | **Not installed** in this workspace | Deferred — in-editor LSP type-check is missing but `oc-status` and pre-commit cover drift detection |

**Key principle:** Desktop reads from the same canonical workspace `.opencode/opencode.json` as the CLI. There is no separate Desktop-side config. The two surfaces are sync-safe at the config level by design (C5.1 sealed).

---

## §2 Daily Start Checklist

Run these four steps at the start of every Desktop session:

1. **Open Desktop in the intended workspace.**
   - Launch OpenCode Desktop.
   - Confirm the working directory is the intended repo root (not a sibling or a stale checkout).
   - The Desktop should be reading the workspace's `.opencode/opencode.json` (verify by opening a session and confirming the agent list shows: `orchestrator, explorer, planner, implementer, reviewer, architect, budget`).

2. **Confirm model and agent context.**
   - Default model: `opencode-go/qwen3.7-plus`
   - Small model: `opencode-go/deepseek-v4-flash`
   - Default agent: `orchestrator`
   - If any of these are different, **stop and run `bash .opencode/scripts/oc-status.sh --full`** before proceeding.

3. **Run `/status` in Desktop.**
   - This is the in-Desktop quick dirty-tree / health summary.
   - Expected: a short list of currently dirty items in the working tree, with no surprises.
   - If `/status` reports something unexpected (CAG / GOR / MRC / PMD failure, prompt drift, missing agent), stop and triage before doing any work.

4. **Optionally run `bash .opencode/scripts/oc-status.sh --full` in CLI.**
   - This is the deeper read-only health check (alias: `oc-status`).
   - Expected: `PASSED: 142 / FAILED: 0` (or current baseline count), all 7 prompts in sync, default model and small model match §2 step 2.
   - Run this at least once per work day. Skip on subsequent `/status` calls if no Desktop-side changes occurred.

**Do NOT start coding until all four steps complete without unexpected output.**

---

## §3 Pre-Commit Checklist

Run these four steps before every commit, regardless of how small the change is:

1. **Run `/status` in Desktop.**
   - Confirms the dirty tree matches your mental model of what changed.

2. **Run relevant tests.**
   - Tier 1: `pnpm lint && pnpm typecheck && pnpm test` (or the repo's equivalent)
   - Tier 2 (UI work): also `pnpm exec playwright test tests/e2e/...` and axe scan
   - See `.opencode/runbooks/daily-ui-agent-workflow.md` §7 for the full Tier 2 / Tier 3 gate list

3. **Run pre-commit on the staged files.**
   ```bash
   pre-commit run --files <changed files>
   ```
   - For full sweep: `pre-commit run --all-files`
   - The OpenCode Tier 1 conformance hook **must pass** (gitleaks, secret-pattern blocks, internal-files block, EOF/trim, OpenCode conformance, SSH/SSL key detection, large file block, merge markers).

4. **Review the dirty tree.**
   ```bash
   git status --short
   git diff --cached --stat
   ```
   - Confirm the staged files are exactly the touch list you intended.
   - Confirm no `.env*`, no secret values, no untracked runtime artifacts.

**Only commit after all four steps pass. The git-guard wrapper at `.opencode/git-guard/git-guard.sh` enforces the safe-commit contract; do not bypass it with `--no-verify`, `--force`, or direct-main push.**

---

## §4 When to Stop and Report

The following are escalation triggers. If any of them appear, **stop the current task immediately, do not edit config, and produce a blocker report before continuing.**

| Trigger | What it means | Action |
|---|---|---|
| **Prompt drift appears** | The v0.2 candidate drift is registered as `ACCEPTED_NON_BLOCKING` (C0-DRIFT-021 through C0-DRIFT-026). Any *new* unclassified drift appearing in `prompt-mirror-drift.sh` is unexpected. | Stop. Do not refresh `prompt-baseline.json`. Surface to owner. v0.2 cleanup is the deferred R2 milestone. |
| **CAG / GOR / MRC / PMD fails unexpectedly** | The 4 Tier 1 conformance suites all passed in R1. A new failure is a real signal. | Stop. Run the failing suite in isolation. Capture the output. Surface to owner. |
| **Global config becomes authoritative** | The global `~/.config/opencode/opencode.json` is `GLOBAL_THIN_IDLE` (only `$schema` and `plugin: []`). If it starts declaring agents, model, or MCPs, the C5.1 sealed state is broken. | Stop. Do not edit either config. The C5.1 architecture is sealed. |
| **Desktop / CLI model routing diverges** | Desktop and CLI both read `.opencode/opencode.json` for routing. If they disagree, the config authority is broken. | Stop. Run `oc-status.sh --full` in CLI. Cross-check Desktop's model picker. Surface divergence. |
| **MCP behavior changes** | Active MCPs (`exa`, `context7`, `github`, `sequential-thinking`) should be stable. If any start returning errors, hanging, or behaving differently, that's a real signal. | Stop. Check `oc-status.sh` for MCP policy state. Surface to owner. The disabled / missing MCPs (`playwright`, `firecrawl`, `pencil`) are intentionally so — do not enable them during soak. `web-tools` was deprecated and removed (2026-07-01). |
| **Secrets or `.env*` files appear in git** | `**/.env.doppler` is gitignored (P1A-C). `.env*` should not be staged. Pre-commit gitleaks will block; if it doesn't, that's a critical failure. | Stop. Unstage. Move to gitignored location. Verify Doppler is the source of truth. Do not commit secret values. |

**When in doubt: stop and report. The frozen baseline chain is a working agreement; we don't change it during soak without owner approval.**

---

## §5 UI / UX Workflow

For UI / design / frontend work, use this daily rhythm:

1. **Use Desktop for screenshot / design review.**
   - Multi-pane diffs, before/after comparisons, accessibility-tree inspection, file-level review.
   - The 116 historical `.playwright-mcp/` page snapshots are still on disk and can be referenced.

2. **Use the `agent-browser` skill as the Playwright stopgap.**
   - Trigger: `agent-browser` skill (`.opencode/skills/agent-browser/`)
   - Why: it uses deterministic element refs (`@e1`, `@e2`, …) instead of fragile CSS selectors. It is already installed, already in the skill roster, and does not require the Playwright MCP.
   - **Do not enable the Playwright MCP during soak.** That's the deferred R3 milestone. The `agent-browser` skill is the interim capability.

3. **Use the `webapp-testing` skill for browser verification.**
   - Trigger: `webapp-testing` skill (`.opencode/skills/webapp-testing/`)
   - Use it for: Playwright test authoring, E2E flow design, browser automation debugging, UI verification.

4. **Use the `frontend-design` skill for design direction.**
   - Trigger: `frontend-design` skill (`.opencode/skills/frontend-design/`)
   - Use it for: motion, typography, spatial composition, distinctive UI/UX that avoids generic AI aesthetics.

5. **Use CLI for verification evidence.**
   - `pre-commit run --all-files` after touching UI files
   - `bash .opencode/conformance/tests/visual-regression.sh` if visual regression is in scope
   - The `.opencode/runbooks/daily-ui-agent-workflow.md` is the canonical UI gate runbook; this runbook is the Desktop-daily complement, not a replacement.

6. **For cross-repo UI work** (e.g., UI changes that touch multiple repos in the workspace): use Desktop as the orchestrator and the existing `/implement`, `/review-ui`, `/gate-ui` commands for the structured workflow.

**Minimum UI/UX setup that gives the highest improvement without destabilizing the baseline:**

- Reuse the existing `agent-browser` and `webapp-testing` skills.
- Use `.playwright-mcp/` historical artifacts as reference data, not as live state.
- Run `.opencode/runbooks/daily-ui-agent-workflow.md` Tier 2 gates on every UI commit.
- Do not enable Playwright / Firecrawl / Pencil MCPs during soak.

---

## §6 Deferred Enhancements (Do Not Touch During Soak)

The following are explicitly out of scope for Release 1 soak. Do not enable, wire, install, or pilot any of these without owner approval.

| Deferred | What it is | Why deferred | When to revisit |
|---|---|---|---|
| **TypeScript LSP re-enable** | `lsp.typescript.disabled: true` in workspace config | Zero risk, but it touches `.opencode/opencode.json` and the user has not approved a config change. | D2 (next safe config-touch stage) |
| **Role-profile agent wiring** | 9 role profiles in `.opencode/role-profiles/` (product-manager, frontend-engineer, ui-ux-designer, etc.) are designed but not loaded as agents | Additive config change; needs owner approval | D2 |
| **Playwright MCP** | C0-DRIFT-001; `mcp.playwright.enabled: false` | Deferred R3 milestone; use `agent-browser` skill as stopgap | R3 |
| **Firecrawl MCP** | C0-DRIFT-002; `mcp.firecrawl.enabled: false` | Deferred R3 milestone; `webfetch` is already allowed | R3 |
| **Pencil MCP** | C0-DRIFT-003; `mcp.pencil.enabled: missing` | Deferred R3 milestone; `pencil-design` and `pencil-pen-format` skills are already installed | R3 |
| **Plugin pilots** | `stuck-retry.js` (disabled backup), `opencode-helicone-session` (not installed), others | Telemetry / behavior-change implications; current 1 plugin (`brain-hooks.js`) is enough | D4 (plugin pilot) |
| **Session `share` enable** | `share: "disabled"` in workspace config | Privacy posture decision; needs explicit owner approval | Owner decision |
| **IDE extension install** | OpenCode extension not installed in VSCode / Cursor / Zed | In-editor LSP type-check is missing; can be approximated by `oc-status` and pre-commit | D5 (cross-device replication) |
| **v0.2 prompt work acceptance/revert** | 6 v0.2 prompt candidate entries in `known-c0-drift.json` (C0-DRIFT-021 through C0-DRIFT-026) | R2 deferred milestone | R2 |
| **Aliyun / Bailian fallback retirement** | Fallback provider still in model-registry | Release 2 / out-of-scope track | R5 (or Release 2) |
| **Claude / Hermes / direct API migration** | Not in workspace routing | Separate integration track | Release 2 (per Release 1 boundary rules) |

**If a real blocker appears that requires touching any of these, stop and surface to owner. The frozen baseline chain is the working agreement.**

---

## §7 Related Runbooks and Commands

**Companion runbooks (read these alongside this one):**

- `.opencode/runbooks/opencode-desktop-cli-sync.md` — Architecture, troubleshooting, recovery procedures for Desktop/CLI sync.
- `.opencode/runbooks/daily-ui-agent-workflow.md` — Tier 1 / 2 / 3 gate definitions for UI work; screenshot updates; component decision rule.
- `.opencode/runbooks/pre-promotion-gate-workflow.md` — Pre-promotion gate workflow for promoting code to production.
- `.opencode/runbooks/production-release-gate.md` — Production release gate workflow.
- `.opencode/runbooks/visual-regression-maintenance.md` — Visual regression baseline maintenance.
- `.opencode/runbooks/ci-pre-promotion-workflow.md` — CI / pre-promotion workflow.
- `.opencode/runbooks/monthly-protocol-recertification.md` — Monthly protocol recertification cadence.

**Useful slash commands (Desktop):**

- `/status` — quick dirty-tree / health summary
- `/quick` — fast read-only check
- `/map-repo` — repo structure map
- `/phase` — current phase / stage
- `/implement` — gated implementation workflow
- `/review` — review workflow
- `/review-ui` — UI review workflow
- `/gate-fast` / `/gate-ui` / `/gate-release` — Tier 1 / 2 / 3 gates
- `/checkpoint` — checkpoint handoff
- `/ship` — release workflow
- `/recover` — recovery workflow
- `/postmortem` — postmortem template
- `/stop-ship` — stop ship workflow
- `/memory-status` / `/memory-save` / `/memory-audit` — Owner memory operations

**Useful CLI commands (verification):**

- `bash .opencode/scripts/oc-status.sh` (alias: `oc-status`) — read-only operator health check
- `bash .opencode/scripts/oc-status.sh --full` — full mode, runs conformance suite
- `pre-commit run --files <changed>` — pre-commit on staged files
- `pre-commit run --all-files` — pre-commit on all files
- `bash .opencode/conformance/tests/global-opencode-runtime.sh` — global runtime conformance
- `bash .opencode/conformance/tests/model-routing-coherence.sh` — model routing coherence
- `bash .opencode/conformance/tests/config-authority-guard.sh` — config authority guard
- `bash .opencode/conformance/tests/prompt-mirror-drift.sh` — prompt mirror drift

**Frozen baseline chain (immutable during soak):**

```
0a1a7db  P1A-A  stale Openclaw-STAGE and example-platform.zip cleanup
001c627  P1A-C2 Doppler config moved to local example
6032117  P1A-B  example-agent submodule pointer bump
6b645b1  P1A-C  workspace ignore safety guard
0a6ec69  P1A-C0b registered pending v0.2 prompt drift handling
71dc989  H1     workspace hygiene cleanup
7797967  C5.1   runtime-aware global config
```

---

## §8 Rollback Note

This file is documentation only. Rollback recipe:

- **Type:** remove-file
- **Scope:** this runbook file only
- **Preconditions:** file is committed (currently uncommitted; in working tree)
- **Action:** `git rm .opencode/runbooks/desktop-daily-workflow.md`
- **Verify:** `bash .opencode/scripts/oc-status.sh` reports no prompt drift and no conformance regression. The runbooks directory continues to function without this file.
- **No protected files touched:** `.opencode/opencode.json` unchanged, `prompt-baseline.json` unchanged, `known-c0-drift.json` unchanged, global config unchanged, submodules unchanged, v0.2 candidate files untouched.

---

**End of runbook. Awaiting owner approval before commit.**
