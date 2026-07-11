#!/usr/bin/env bash
# Track Usage (v4.26)
#
# Collects best-effort task usage evidence for ROI analysis.
# Does not make network calls. Uses local config and runtime state only.
# Outputs "unknown" rather than guessing when data is unavailable.
#
# Usage: bash .opencode/scripts/track-usage.sh <repo> <lane> [model] [reviewer-used] [outcome]
# Example: bash .opencode/scripts/track-usage.sh protected-repo-prod STANDARD umans-coder yes pass
#
# Output:
#   USAGE_TRACKING:
#     repo: protected-repo-prod
#     lane: STANDARD
#     model_used: umans-coder
#     provider: umans-ai-coding-plan
#     reviewer_used: yes
#     reviewer_found_issues: (report from agent)
#     premium_model_used: no
#     premium_model_reason: n/a
#     approximate_tokens: unknown
#     elapsed_time: unknown
#     gates_run: (report from agent)
#     ci_used: (report from agent)
#     outcome: pass
#     cheaper_model_would_have_sufficed: (report from agent)
#     routing_recommendation_next_time: (report from agent)

set -uo pipefail

REPO="${1:-unknown}"
LANE="${2:-unknown}"
MODEL="${3:-unknown}"
REVIEWER_USED="${4:-unknown}"
OUTCOME="${5:-unknown}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ============================================================
# Detect provider from model name
# ============================================================

PROVIDER="unknown"
if echo "$MODEL" | grep -q "umans-ai-coding-plan"; then
  PROVIDER="umans-ai-coding-plan"
elif echo "$MODEL" | grep -q "opencode-go"; then
  PROVIDER="opencode-go"
elif echo "$MODEL" | grep -q "opencode/"; then
  PROVIDER="opencode-free-tier"
elif echo "$MODEL" | grep -qE "^umans-(coder|flash|glm|kimi|qwen)"; then
  PROVIDER="umans-ai-coding-plan"
fi

# Determine if premium model was used
PREMIUM_MODEL="no"
PREMIUM_REASON="n/a"
if echo "$MODEL" | grep -q "qwen3.7-plus\|qwen3.6-plus\|glm-5.1\|kimi-k2.6"; then
  PREMIUM_MODEL="yes"
  PREMIUM_REASON="OpenCode Go premium reserve model used"
fi

# ============================================================
# Try to get token usage from opencode stats (best-effort)
# ============================================================

TOKEN_USAGE="unknown"
if command -v opencode &>/dev/null; then
  STATS=$(opencode stats --days 1 2>/dev/null || true)
  if [ -n "$STATS" ]; then
    # Try to extract token counts
    INPUT_TOKENS=$(echo "$STATS" | grep -i "input" | head -1 | sed 's/.*: *//' | tr -d ' ,' || echo "unknown")
    OUTPUT_TOKENS=$(echo "$STATS" | grep -i "output" | head -1 | sed 's/.*: *//' | tr -d ' ,' || echo "unknown")
    if [ "$INPUT_TOKENS" != "unknown" ] && [ "$OUTPUT_TOKENS" != "unknown" ]; then
      TOKEN_USAGE="input=${INPUT_TOKENS} output=${OUTPUT_TOKENS}"
    fi
  fi
fi

# ============================================================
# Try to get elapsed time (best-effort — from session start if available)
# ============================================================

ELAPSED="unknown"
# This is best-effort — the agent should report actual elapsed time

# ============================================================
# Output
# ============================================================

echo "USAGE_TRACKING:"
echo "  repo: $REPO"
echo "  lane: $LANE"
echo "  model_used: $MODEL"
echo "  provider: $PROVIDER"
echo "  reviewer_used: $REVIEWER_USED"
echo "  reviewer_found_issues: (report from agent)"
echo "  premium_model_used: $PREMIUM_MODEL"
echo "  premium_model_reason: $PREMIUM_REASON"
echo "  approximate_tokens: $TOKEN_USAGE"
echo "  elapsed_time: $ELAPSED"
echo "  gates_run: (report from agent)"
echo "  ci_used: (report from agent)"
echo "  outcome: $OUTCOME"
echo "  cheaper_model_would_have_sufficed: (report from agent — yes/no/unknown)"
echo "  routing_recommendation_next_time: (report from agent)"
