#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$ROOT_DIR"

FAIL=0

section() {
  printf '\n== %s ==\n' "$1"
}

flag() {
  local label="$1"
  shift
  FAIL=1
  printf '[WARN] %s\n' "$label"
  printf '%s\n' "$@"
}

ROOT_CONTRACTS=(
  "AGENTS.md"
  "CLAUDE.md"
  "GEMINI.md"
  ".claude/rules/workflow.md"
  ".opencode/AGENTS.md"
  ".opencode/rules.md"
  ".opencode/opencode.json"
  ".opencode/brain-config.json"
  ".opencode/registry.yaml"
  ".ai/codex/config.json"
)

RUNTIME_TREES=(
  "example-agent/.hermes-local"
  "Openclaw-PROD/workspace"
  "Openclaw-PROD/workspace.backup"
  "Openclaw-STAGE/workspace"
  "practice-repos/example-toolchain-DEV/openclaw/.openclaw-mission-control"
  ".claude/validation"
  ".opencode/archive"
  ".opencode/conformance/results"
  "vault/archive"
)

section "Wrong-Scope Authority Files"
wrong_scope="$(find "${RUNTIME_TREES[@]}" -type f \( -name 'AGENTS.md' -o -name 'CLAUDE.md' -o -name 'NOW.md' \) 2>/dev/null | sort || true)"
if [[ -n "$wrong_scope" ]]; then
  tracked_wrong_scope=""
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
      tracked_wrong_scope+="${file}"$'\n'
    fi
  done < <(printf '%s\n' "$wrong_scope")
  wrong_scope="$tracked_wrong_scope"
fi
if [[ -n "$wrong_scope" ]]; then
  flag "Tracked authority-like files found under runtime/archive trees" "$wrong_scope"
else
  echo "[OK] No tracked AGENTS.md / CLAUDE.md / NOW.md files under runtime/archive roots."
fi

section "Legacy .agent Runtime References"
legacy_refs="$(rg -n '\.agent/PROTOCOLS/REPO_REGISTRY\.yaml|\.agent/scripts|\.agent/skills|\.agent/PROTOCOLS' .opencode AGENTS.md CLAUDE.md GEMINI.md \
  --glob '!**/archive/**' \
  --glob '!**/conformance/results/**' \
  --glob '!**/node_modules/**' \
  --glob '!**/tests/**' || true)"
legacy_refs="$(printf '%s\n' "$legacy_refs" | grep -v '^.opencode/scripts/workspace-hygiene-audit.sh:' || true)"
if [[ -n "$legacy_refs" ]]; then
  flag "Live contracts/runtime files still reference root .agent paths" "$legacy_refs"
else
  echo "[OK] No live runtime/contract references to root .agent paths."
fi

section "Repo Contract Shape"
repo_agents="$(find . -maxdepth 2 -type f -name 'AGENTS.md' \
  -not -path './.opencode/*' \
  -not -path './.claude/*' \
  -not -path './.agent/*' \
  | sort || true)"
repo_now="$(find . -maxdepth 2 -type f -name 'NOW.md' \
  -not -path './.opencode/*' \
  -not -path './.claude/*' \
  -not -path './.agent/*' \
  | sort || true)"
echo "[INFO] Repo-root AGENTS count: $(printf '%s\n' "$repo_agents" | sed '/^$/d' | wc -l | tr -d ' ')"
echo "[INFO] Repo-root NOW count: $(printf '%s\n' "$repo_now" | sed '/^$/d' | wc -l | tr -d ' ')"

section "Repo .claude Settings Drift"
template=".claude/templates/repo-settings.json"
drift=""
repo_settings_files="$(rg --files -g '*/.claude/settings.json' \
  -g '!Openclaw-PROD/workspace/**' \
  -g '!Openclaw-PROD/workspace.backup/**' \
  -g '!Openclaw-STAGE/workspace/**' \
  -g '!example-agent/.hermes-local/**' \
  -g '!practice-repos/example-toolchain-DEV/openclaw/.openclaw-mission-control/**' \
  -g '!vault/**' || true)"
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  [[ "$file" == ".claude/settings.json" ]] && continue
  if ! cmp -s "$template" "$file"; then
    drift+="${file}"$'\n'
  fi
done < <(printf '%s\n' "$repo_settings_files")
if [[ -n "$drift" ]]; then
  flag "Repo .claude/settings.json drift from canonical template" "$drift"
else
  echo "[OK] Repo .claude/settings.json files match canonical template."
fi

section "Tracked Runtime-State Files"
tracked_runtime="$(git ls-files \
  'example-agent/.hermes-local/**' \
  'Openclaw-PROD/workspace/**' \
  'Openclaw-PROD/workspace.backup/**' \
  'Openclaw-STAGE/workspace/**' \
  'practice-repos/example-toolchain-DEV/openclaw/.openclaw-mission-control/**' \
  '.claude/settings.local.json' \
  '.claude/scheduled_tasks.lock' \
  '.claude/agent-memory-local/**' \
  '.opencode/node_modules/**' \
  '.opencode/conformance/results/**' 2>/dev/null || true)"
if [[ -n "$tracked_runtime" ]]; then
  flag "Tracked runtime-state files detected" "$tracked_runtime"
else
  echo "[OK] No tracked runtime-state files matched the audit patterns."
fi

section "Secret-Like Literals"
secret_hits="$(
  {
    rg -n \
    -g '!**/.git/**' \
    -g '!**/node_modules/**' \
    -g '!**/archive/**' \
    -g '!**/conformance/results/**' \
    -g '!**/tests/**' \
    -g '!**/__tests__/**' \
    -g '!**/docs/**' \
    -g '!**/website/**' \
    -g '!**/references/**' \
    -g '!vault/**' \
  -e '(^|[^A-Za-z0-9])sk-[A-Za-z0-9_-]{12,}' \
  -e '(^|[^A-Za-z0-9])fc-[A-Za-z0-9_-]{12,}' \
  -e '"token"[[:space:]]*:[[:space:]]*"[A-Za-z0-9_-]{24,}"' \
  -e '"apiKey"[[:space:]]*:[[:space:]]*"[^"]{12,}"' \
  . || true
  } | grep -Evi '(_LOCAL_ONLY"|OPENROUTER_API_KEY"|NVIDIA_API_KEY"|free"|sk-body-link-color|sk-no-key-required|YOUR_KEY_HERE|your-key|sk-xxxxxxxx)' || true
)"
if [[ -n "$secret_hits" ]]; then
  flag "Secret-like literals found in current files" "$secret_hits"
else
  echo "[OK] No secret-like literals matched the current-file scan."
fi

section "Generated Trees Treated As Authority"
generated_refs=""
for contract in "${ROOT_CONTRACTS[@]}"; do
  [[ -f "$contract" ]] || continue
  hits="$(rg -n 'example-agent/\.hermes-local|Openclaw-PROD/workspace|Openclaw-PROD/workspace\.backup|Openclaw-STAGE/workspace|\.openclaw-mission-control|\.claude/validation|\.opencode/archive|\.opencode/conformance/results|vault/archive' "$contract" || true)"
  if [[ -n "$hits" ]]; then
    generated_refs+="$hits"$'\n'
  fi
done
if [[ -n "$generated_refs" ]]; then
  echo "[INFO] Contract mentions of runtime/archive trees:"
  printf '%s' "$generated_refs"
else
  echo "[OK] No root contracts mention generated/archive trees."
fi

section "Summary"
if [[ "$FAIL" -eq 0 ]]; then
  echo "[PASS] Workspace hygiene audit found no blocking drift."
else
  echo "[FAIL] Workspace hygiene audit found drift or cleanup candidates."
fi

exit "$FAIL"
