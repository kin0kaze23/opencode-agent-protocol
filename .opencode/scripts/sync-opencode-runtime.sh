#!/bin/bash
# Sync the launcher-visible OpenCode runtime under ~/.config/opencode
# from the checked-in workspace canonical helper policy.
#
# Flow per acceptance criteria (OC-L.2B):
#
#   Canonical source (human edits):
#     .opencode/agents/*.md                          → generated mirror
#     .opencode/global-runtime/prompts/orchestrator.md → installed runtime
#
#   Generated mirrors (derived, with GENERATED FILE header):
#     .opencode/global-runtime/prompts/{agent}.md
#
#   Installed runtime (copied from mirror or canonical):
#     ~/.config/opencode/prompts/*.md
#
#   Conformance:
#     Fails if generated mirrors drift from canonical source.
#     Fails if installed prompts drift from generated mirrors (or canonical for orchestrator).
#
# Public-mode guard (v5.5.3):
#   If opencode.json contains placeholder model IDs (YOUR_PROVIDER),
#   and brain-config.json contains non-placeholder model IDs,
#   sync is refused to prevent overwriting user-facing placeholders
##   with author-specific config. Override with --allow-local-sync.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

GLOBAL_DIR="$HOME/.config/opencode"
GLOBAL_PROMPTS_DIR="$GLOBAL_DIR/prompts"
LOCAL_BRAIN="$ROOT_DIR/.opencode/brain-config.json"
LOCAL_AGENTS_DIR="$ROOT_DIR/.opencode/agents"
LOCAL_PROMPTS_DIR="$ROOT_DIR/.opencode/global-runtime/prompts"
ORCHESTRATOR_SOURCE="$LOCAL_PROMPTS_DIR/orchestrator.md"
WORKSPACE_CFG="$ROOT_DIR/.opencode/opencode.json"

# Helper: capitalize first letter (macOS-safe, bash 3.2+)
capitalize() {
  local str="$1"
  local first_char="${str:0:1}"
  local rest="${str:1}"
  local first_upper
  first_upper=$(echo "$first_char" | tr '[:lower:]' '[:upper:]')
  echo "${first_upper}${rest}"
}

# === Pre-checks ===
missing=0
if [ ! -f "$WORKSPACE_CFG" ]; then echo "Missing: $WORKSPACE_CFG" >&2; missing=1; fi
if [ ! -f "$LOCAL_BRAIN" ]; then echo "Missing: $LOCAL_BRAIN" >&2; missing=1; fi
if [ ! -d "$LOCAL_AGENTS_DIR" ]; then echo "Missing: $LOCAL_AGENTS_DIR" >&2; missing=1; fi
if [ ! -f "$ORCHESTRATOR_SOURCE" ]; then echo "Missing: $ORCHESTRATOR_SOURCE" >&2; missing=1; fi

# Check for at least one canonical agent spec
agent_count=0
for f in "$LOCAL_AGENTS_DIR"/*.md; do
  [ -f "$f" ] && agent_count=$((agent_count + 1))
done
if [ "$agent_count" -eq 0 ]; then
  echo "Missing: No canonical agent specs found in $LOCAL_AGENTS_DIR" >&2
  missing=1
fi

if [ "$missing" -eq 1 ]; then
  exit 1
fi

# === Public-mode guard (v5.5.3) ===
# Prevents sync from overwriting placeholder model IDs in opencode.json
# with author-specific values from brain-config.json.
ALLOW_LOCAL_SYNC=0
for arg in "$@"; do
  if [ "$arg" = "--allow-local-sync" ]; then
    ALLOW_LOCAL_SYNC=1
  fi
done

if grep -q "YOUR_PROVIDER" "$WORKSPACE_CFG" 2>/dev/null; then
  if ! grep -q "YOUR_PROVIDER" "$LOCAL_BRAIN" 2>/dev/null; then
    echo "⚠️  Public-mode guard: opencode.json has placeholder model IDs but"
    echo "    brain-config.json has non-placeholder values."
    echo "    Sync would overwrite placeholders with brain-config.json values."
    echo ""
    echo "    To proceed, either:"
    echo "      1. Edit opencode.json directly with your model IDs (recommended)"
    echo "      2. Update brain-config.json with your model IDs, then sync"
    echo "      3. Run with --allow-local-sync to override this guard"
    echo ""
    echo "    See: docs/OWN_MODEL_SETUP.md for provider configuration."
    echo ""
    if [ "$ALLOW_LOCAL_SYNC" -eq 0 ]; then
      echo "[BLOCKED] Sync refused to protect placeholder config."
      exit 1
    else
      echo "  --allow-local-sync detected. Proceeding with sync."
    fi
  fi
fi

# === Backup ===
mkdir -p "$GLOBAL_PROMPTS_DIR"
BACKUP_DIR="$GLOBAL_DIR/backups/$(date +%Y-%m-%d)-sync-opencode-runtime"
mkdir -p "$BACKUP_DIR/prompts"
cp "$WORKSPACE_CFG" "$BACKUP_DIR/opencode.json.bak"
for prompt_file in "$GLOBAL_PROMPTS_DIR"/*.md; do
  [ -f "$prompt_file" ] && cp "$prompt_file" "$BACKUP_DIR/prompts/"
done
echo "Backup: $BACKUP_DIR"

# === Step 1: Generate runtime prompt mirrors from canonical agent specs ===
echo ""
echo "=== Step 1: Generating runtime prompts from canonical agent specs ==="

GENERATED_COUNT=0
mkdir -p "$LOCAL_PROMPTS_DIR"

# Generate mirrors for all approved agents (including visual-reviewer)
for agent_name in architect budget explorer implementer planner reviewer visual-reviewer visual-reviewer-fallback; do
  agent_file="$LOCAL_AGENTS_DIR/$agent_name.md"
  [ -f "$agent_file" ] || continue
  agent_title=$(capitalize "$agent_name")
  target="$LOCAL_PROMPTS_DIR/$agent_name.md"

  {
    echo "# ${agent_title} Helper"
    echo ""
    echo "> GENERATED FILE — DO NOT EDIT DIRECTLY."
    echo "> Canonical source: .opencode/agents/${agent_name}.md"
    echo "> To regenerate: bash .opencode/scripts/sync-opencode-runtime.sh"
    echo ""
    cat "$agent_file"
  } > "$target"

  echo "  Generated: ${agent_name}.md ($(wc -l < "$target") lines from canonical)"
  GENERATED_COUNT=$((GENERATED_COUNT + 1))
done

echo "  Generated ${GENERATED_COUNT} prompt mirrors from ${agent_count} canonical agent specs."

# Verify orchestrator canonical exists (not generated — human-edited)
echo ""
echo "=== Step 2: Verifying orchestrator canonical ==="
if [ -f "$ORCHESTRATOR_SOURCE" ]; then
  echo "  Orchestrator canonical present: $(wc -l < "$ORCHESTRATOR_SOURCE") lines"
else
  echo "  ERROR: orchestrator.md not found at $ORCHESTRATOR_SOURCE" >&2
  exit 1
fi

# === Step 3: Update workspace agent definitions in .opencode/opencode.json ===
echo ""
echo "=== Step 3: Updating workspace agent definitions ==="

WORKSPACE_CFG_PATH="$WORKSPACE_CFG" GLOBAL_CFG_PATH="$GLOBAL_DIR/opencode.json" LOCAL_BRAIN_PATH="$LOCAL_BRAIN" node <<'NODE'
const fs = require('fs');

const workspacePath = process.env.WORKSPACE_CFG_PATH;
const brainPath = process.env.LOCAL_BRAIN_PATH;
const workspaceCfg = JSON.parse(fs.readFileSync(workspacePath, 'utf8'));
const brainCfg = JSON.parse(fs.readFileSync(brainPath, 'utf8'));

const roster = brainCfg.subagents.roster;
const mcpMeta = brainCfg.mcp_servers || {};
const models = {
  orchestrator: brainCfg.orchestrator_mode.default_model,
  explorer: roster.core.explorer.model,
  planner: roster.core.planner.model,
  implementer: roster.core.implementer.model,
  reviewer: roster.core.reviewer.model,
  architect: roster.specialized.architect.model,
  budget: brainCfg.orchestrator_mode.escalation.bulk_review,
  visual_reviewer: roster.specialized['visual-reviewer'].model,
  visual_reviewer_fallback: roster.specialized['visual-reviewer-fallback'].model,
  compaction: brainCfg.compaction?.default_safe_model || 'umans-ai-coding-plan/umans-kimi-k2.7',
  summary: brainCfg.compaction?.default_safe_model || 'umans-ai-coding-plan/umans-kimi-k2.7'
};

const readOnlyPermission = {
  edit: 'deny',
  bash: 'deny',
  task: { '*': 'deny' }
};

const implementerPermission = {
  edit: 'allow',
  bash: {
    '*': 'ask'
  },
  task: { '*': 'deny' }
};

const definitions = {
  orchestrator: {
    model: models.orchestrator,
    mode: 'primary',
    description: 'Primary owner agent. Single front-door authority that follows the checked-in workspace protocol and delegates only to the canonical helper roster.',
    prompt: '{file:prompts/orchestrator.md}',
    permission: {
      edit: 'ask',
      bash: {
        '*': 'ask'
      },
      task: {
        '*': 'deny',
        explorer: 'allow',
        planner: 'allow',
        implementer: 'allow',
        reviewer: 'allow',
        architect: 'allow',
        budget: 'allow',
        'visual-reviewer': 'allow',
        'visual-reviewer-fallback': 'allow'
      }
    },
    temperature: 0.2,
    steps: 120,
    color: '#7C3AED'
  },
  explorer: {
    model: models.explorer,
    mode: 'all',
    description: 'Explorer helper — read-only codebase discovery, dependency mapping, runtime-path search, and hotspot identification before planning unfamiliar work.',
    prompt: '{file:prompts/explorer.md}',
    permission: readOnlyPermission,
    temperature: 0.1,
    steps: 80,
    color: '#2563EB'
  },
  planner: {
    model: models.planner,
    mode: 'all',
    description: 'Planner helper — plan creation, plan correction, scope slicing, and implementation-readiness checks against runtime authority and touch-list completeness.',
    prompt: '{file:prompts/planner.md}',
    permission: readOnlyPermission,
    temperature: 0.2,
    steps: 100,
    color: '#059669'
  },
  implementer: {
    model: models.implementer,
    mode: 'all',
    description: 'Implementer helper — bounded code changes on an approved touch list only, with gate reporting back to the owner.',
    prompt: '{file:prompts/implementer.md}',
    permission: implementerPermission,
    temperature: 0.1,
    steps: 300,
    color: '#DC2626'
  },
  reviewer: {
    model: models.reviewer,
    mode: 'all',
    description: 'Reviewer helper — primary risk review, regression check, and exact next-step recommendation before commit or ship.',
    prompt: '{file:prompts/reviewer.md}',
    permission: readOnlyPermission,
    temperature: 0.1,
    steps: 90,
    color: '#D97706'
  },
  architect: {
    model: models.architect,
    mode: 'all',
    description: 'Architect helper — resolve high-ambiguity auth, schema, state-model, or cross-surface design decisions before implementation.',
    prompt: '{file:prompts/architect.md}',
    permission: readOnlyPermission,
    temperature: 0.2,
    steps: 140,
    color: '#9333EA'
  },
  budget: {
    model: models.budget,
    mode: 'all',
    description: 'Budget helper — cheap read-only alternative for review, planning, and routing summaries using strict resource constraints.',
    prompt: '{file:prompts/budget.md}',
    permission: readOnlyPermission,
    temperature: 0.1,
    steps: 60,
    color: '#6B7280'
  },
  'visual-reviewer': {
    model: models.visual_reviewer,
    mode: 'all',
    description: 'Visual QA specialist (primary) — screenshot analysis, UI/UX review, accessibility visual audit using vision/multimodal capability.',
    prompt: '{file:prompts/visual-reviewer.md}',
    permission: readOnlyPermission,
    temperature: 0.1,
    steps: 60,
    color: '#EC4899'
  },
  'visual-reviewer-fallback': {
    model: models.visual_reviewer_fallback,
    mode: 'all',
    description: 'Visual QA specialist (fallback) — screenshot analysis using a vision-capable model. Used when the primary visual reviewer is unavailable.',
    prompt: '{file:prompts/visual-reviewer-fallback.md}',
    permission: readOnlyPermission,
    temperature: 0.1,
    steps: 60,
    color: '#F472B6'
  },
  summary: {
    model: models.summary,
    mode: 'subagent',
    description: 'Summary helper — dedicated continuity-aware summarizer for long-session compaction. Only a compaction-safe model is allowed.',
    prompt: "You are OpenCode's dedicated continuity-aware summarizer. Read the long session transcript and produce a compact summary preserving the minimum state needed to resume. Output ONLY these fields, each on its own line: Repo:, Current task:, Lane:, Touch list digest:, Blockers:, Latest decision:, Next step:. No markdown, code fences, or commentary. Use concise text only; use 'none' or 'unknown' if a field cannot be determined.",
    permission: readOnlyPermission,
    temperature: 0.1,
    steps: 40,
    color: '#0891B2'
  },
  compaction: {
    model: models.compaction,
    mode: 'subagent',
    description: 'Compaction helper — dedicated agent used to compress full context when sessions exceed the safe token threshold. Only a compaction-safe model is allowed.',
    prompt: "You are OpenCode's dedicated compaction agent. When a session grows too long, produce a compact summary that preserves critical task continuity. Keep recent turns verbatim when provided. Condense older turns into a single structured continuity block. Output ONLY these fields, each on its own line: Repo:, Current task:, Lane:, Touch list digest:, Blockers:, Latest decision:, Next step:. After anchors you may add a brief 'Session notes' paragraph (under 300 tokens) capturing key decisions and unresolved risks. Do not invent facts; use 'none' or 'unknown' if a field cannot be determined.",
    permission: readOnlyPermission,
    temperature: 0.1,
    steps: 40,
    color: '#BE185D'
  }
};

const mcp = workspaceCfg.mcp || {};
if (mcpMeta.exa) {
  if (mcpMeta.exa.transport === 'stdio') {
    mcp.exa = {
      command: String(mcpMeta.exa.command || 'npx -y exa-mcp-server').split(/\s+/).filter(Boolean),
      enabled: Boolean(mcpMeta.exa.enabled),
      type: 'local'
    };
  } else {
    mcp.exa = {
      type: 'remote',
      url: mcpMeta.exa.url,
      enabled: Boolean(mcpMeta.exa.enabled),
      timeout: 10000,
      oauth: false
    };
  }
}

workspaceCfg.agent = definitions;
workspaceCfg.mcp = mcp;
workspaceCfg.model = brainCfg.default_model;
workspaceCfg.small_model = brainCfg.small_model || 'opencode-go/deepseek-v4-flash';
// Sync top-level permission.task with all delegatable helpers
workspaceCfg.permission = workspaceCfg.permission || {};
workspaceCfg.permission.task = {
  explorer: 'allow',
  planner: 'allow',
  implementer: 'allow',
  reviewer: 'allow',
  architect: 'allow',
  budget: 'allow',
  'visual-reviewer': 'allow',
  'visual-reviewer-fallback': 'allow'
};
fs.writeFileSync(workspacePath, JSON.stringify(workspaceCfg, null, 2) + '\n');

// Also update global config with same agent definitions + MCP + model
const globalPath = process.env.GLOBAL_CFG_PATH;
if (globalPath && fs.existsSync(globalPath)) {
  const globalCfg = JSON.parse(fs.readFileSync(globalPath, 'utf8'));
  globalCfg.agent = definitions;
  globalCfg.mcp = mcp;
  globalCfg.model = brainCfg.default_model;
  globalCfg.small_model = brainCfg.small_model || 'opencode-go/deepseek-v4-flash';
  fs.writeFileSync(globalPath, JSON.stringify(globalCfg, null, 2) + '\n');
}
NODE

echo "  Updated agent definitions in $WORKSPACE_CFG (workspace authority)"
echo "  Updated agent definitions in $GLOBAL_DIR/opencode.json (global baseline)"

# === Step 4: Copy all prompts to installed runtime ===
echo ""
echo "=== Step 4: Copying prompts to installed runtime ==="
mkdir -p "$GLOBAL_PROMPTS_DIR"

PROMPT_COPY_COUNT=0
for prompt_name in orchestrator explorer planner implementer reviewer architect budget visual-reviewer visual-reviewer-fallback; do
  prompt_file="$LOCAL_PROMPTS_DIR/$prompt_name.md"
  if [ -f "$prompt_file" ]; then
    cp "$prompt_file" "$GLOBAL_PROMPTS_DIR/"
    PROMPT_COPY_COUNT=$((PROMPT_COPY_COUNT + 1))
  fi
done
echo "  Copied $PROMPT_COPY_COUNT approved prompt files to $GLOBAL_PROMPTS_DIR"

# === Summary ===
echo ""
echo "=== Sync complete ==="
echo "  Global config:         $WORKSPACE_CFG (workspace authority)"
echo "  Global prompts:        $GLOBAL_PROMPTS_DIR"
echo "  Backup:                $BACKUP_DIR"
echo "  Agent mirrors written: $GENERATED_COUNT"
echo "  Orchestrator copied:   canonical (no generated header)"
