#!/usr/bin/env bash
# Check Provider Status (v4.26)
#
# Reports provider/model availability and quota status from local config.
# Does NOT make network calls. Uses local configuration and env var presence only.
#
# Usage: bash .opencode/scripts/check-provider-status.sh
#
# Output:
#   PROVIDER_STATUS:
#     umans-ai-coding-plan:
#       configured: yes
#       api_key_present: yes/no
#       quota_status: unknown (no local quota API)
#       recommendation: primary capacity provider — use for routine work
#     opencode-go:
#       configured: yes
#       api_key_present: yes/no
#       quota_status: unknown (no local quota API)
#       recommendation: premium reserve — preserve for high-risk tasks
#     fallback_recommendation: umans-ai-coding-plan (capacity-first)
#     notes:
#       - Provider quota is not locally queryable. Use track-usage.sh for post-task evidence.
#       - If a provider returns 429/insufficient_balance during a task, switch provider immediately.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OPENCODE_JSON="$ROOT_DIR/.opencode/opencode.json"

echo "PROVIDER_STATUS:"

# ============================================================
# Check Umans AI Coding Plan
# ============================================================

echo "  umans-ai-coding-plan:"
UMANS_CONFIGURED="no"
UMANS_KEY_PRESENT="no"

# Check if any agent uses umans models
if [ -f "$OPENCODE_JSON" ]; then
  if grep -q "umans-ai-coding-plan" "$OPENCODE_JSON" 2>/dev/null; then
    UMANS_CONFIGURED="yes"
  fi
fi

# Check env var presence (name only, never value)
if [ -n "${UMANS_API_KEY:-}" ]; then
  UMANS_KEY_PRESENT="yes"
fi

echo "    configured: $UMANS_CONFIGURED"
echo "    api_key_present: $UMANS_KEY_PRESENT"
echo "    quota_status: unknown (no local quota API)"
echo "    recommendation: primary capacity provider — use for routine work"

# ============================================================
# Check OpenCode Go
# ============================================================

echo "  opencode-go:"
OCGO_CONFIGURED="no"
OCGO_KEY_PRESENT="no"

if [ -f "$OPENCODE_JSON" ]; then
  if grep -q "opencode-go" "$OPENCODE_JSON" 2>/dev/null; then
    OCGO_CONFIGURED="yes"
  fi
fi

if [ -n "${OPENCODE_GO_API_KEY:-}" ]; then
  OCGO_KEY_PRESENT="yes"
fi

echo "    configured: $OCGO_CONFIGURED"
echo "    api_key_present: $OCGO_KEY_PRESENT"
echo "    quota_status: unknown (no local quota API)"
echo "    recommendation: premium reserve — preserve for high-risk tasks"

# ============================================================
# Fallback recommendation
# ============================================================

echo "  fallback_recommendation: umans-ai-coding-plan (capacity-first)"

# ============================================================
# Notes
# ============================================================

echo "  notes:"
echo "    - Provider quota is not locally queryable. Use track-usage.sh for post-task evidence."
echo "    - If a provider returns 429/insufficient_balance during a task, switch provider immediately."
echo "    - Umans resets approximately every 5 hours. OpenCode Go has monthly quota."
echo "    - Do not spend OpenCode Go on routine implementation/planning unless Umans fails quality checks."
