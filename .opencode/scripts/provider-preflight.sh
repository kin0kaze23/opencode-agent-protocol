#!/bin/bash
# Provider Availability / Quota Preflight — v0.1
# Checks provider reachability and quota status before model-dependent tasks.
# Usage: bash .opencode/scripts/provider-preflight.sh <provider> <model> [base_url] [timeout] [mode]
#
# v0.1 scope: OpenCode Go only, reachability mode only.
# Smoke completion deferred — may consume quota.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Arguments ────────────────────────────────────────────────────────────────

PROVIDER="${1:-}"
MODEL="${2:-}"
BASE_URL="${3:-}"
TIMEOUT="${4:-10}"
MODE="${5:-reachability}"

# ─── Validation ───────────────────────────────────────────────────────────────

if [ -z "$PROVIDER" ] || [ -z "$MODEL" ]; then
    echo '{"provider":"","model":"","reachable":false,"usable":false,"http_code":null,"quota_status":"unknown","quota_remaining":null,"latency_ms":null,"error":"Missing required arguments: provider and model","recommendation":"invalid_input","mode":"reachability","timestamp":"'"$(date -Iseconds)"'"}'
    exit 4
fi

# ─── Provider-specific config ─────────────────────────────────────────────────

case "$PROVIDER" in
    opencode-go)
        API_KEY="${OPENCODE_GO_API_KEY:-}"
        if [ -z "$BASE_URL" ]; then
            BASE_URL="${OPENCODE_GO_BASE_URL:-https://opencode.ai/zen/go/v1}"
        fi
        ;;
    *)
        echo '{"provider":"'"$PROVIDER"'","model":"'"$MODEL"'","reachable":false,"usable":false,"http_code":null,"quota_status":"unknown","quota_remaining":null,"latency_ms":null,"error":"Unsupported provider: '"$PROVIDER"' (v0.1 supports opencode-go only)","recommendation":"invalid_input","mode":"'"$MODE"'","timestamp":"'"$(date -Iseconds)"'"}'
        exit 4
        ;;
esac

# ─── Mode check ───────────────────────────────────────────────────────────────

if [ "$MODE" != "reachability" ]; then
    echo '{"provider":"'"$PROVIDER"'","model":"'"$MODEL"'","reachable":false,"usable":false,"http_code":null,"quota_status":"unknown","quota_remaining":null,"latency_ms":null,"error":"Unsupported mode: '"$MODE"' (v0.1 supports reachability only)","recommendation":"invalid_input","mode":"'"$MODE"'","timestamp":"'"$(date -Iseconds)"'"}'
    exit 4
fi

# ─── Secret check ─────────────────────────────────────────────────────────────

if [ -z "$API_KEY" ]; then
    echo '{"provider":"'"$PROVIDER"'","model":"'"$MODEL"'","reachable":false,"usable":false,"http_code":null,"quota_status":"unknown","quota_remaining":null,"latency_ms":null,"error":"OPENCODE_GO_API_KEY not set","recommendation":"missing_secret","mode":"'"$MODE"'","timestamp":"'"$(date -Iseconds)"'"}'
    exit 2
fi

# ─── HTTP reachability check ──────────────────────────────────────────────────

CHECK_URL="${BASE_URL}/models"
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

HTTP_CODE=$(curl -s -o "$TMPFILE" -w "%{http_code}" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    --max-time "$TIMEOUT" \
    "$CHECK_URL" 2>/dev/null) || CURL_EXIT=$?

CURL_EXIT="${CURL_EXIT:-0}"
LATENCY_MS=$(curl -s -o /dev/null -w "%{time_total}" \
    -H "Authorization: Bearer $API_KEY" \
    --max-time "$TIMEOUT" \
    "$CHECK_URL" 2>/dev/null | awk '{printf "%.0f", $1 * 1000}') || LATENCY_MS="null"

# Handle curl failures
if [ "$CURL_EXIT" -eq 28 ] || [ "$CURL_EXIT" -eq 7 ]; then
    ERROR_MSG="Connection failed or timed out (curl exit $CURL_EXIT)"
    if [ "$CURL_EXIT" -eq 28 ]; then
        RECOMMENDATION="fallback"
        EXIT_CODE=5
    else
        RECOMMENDATION="fallback"
        EXIT_CODE=1
    fi
    echo '{"provider":"'"$PROVIDER"'","model":"'"$MODEL"'","reachable":false,"usable":false,"http_code":null,"quota_status":"unknown","quota_remaining":null,"latency_ms":null,"error":"'"$ERROR_MSG"'","recommendation":"'"$RECOMMENDATION"'","mode":"'"$MODE"'","timestamp":"'"$(date -Iseconds)"'"}'
    exit $EXIT_CODE
fi

# ─── Classify response ────────────────────────────────────────────────────────

REACHABLE=false
USABLE=false
QUOTA_STATUS="unknown"
QUOTA_REMAINING="null"
ERROR="null"
RECOMMENDATION="retry_later"
EXIT_CODE=1

case "$HTTP_CODE" in
    200)
        REACHABLE=true
        USABLE=true
        QUOTA_STATUS="ok"
        RECOMMENDATION="proceed"
        EXIT_CODE=0
        ;;
    401|403)
        REACHABLE=true
        USABLE=false
        RECOMMENDATION="missing_secret"
        ERROR="Authentication failed (HTTP $HTTP_CODE)"
        EXIT_CODE=2
        ;;
    429)
        REACHABLE=true
        USABLE=false
        QUOTA_STATUS="exceeded"
        RECOMMENDATION="retry_later"
        ERROR="Rate limit or quota exceeded (HTTP 429)"
        EXIT_CODE=3
        ;;
    5*)
        REACHABLE=true
        USABLE=false
        RECOMMENDATION="retry_later"
        ERROR="Provider server error (HTTP $HTTP_CODE)"
        EXIT_CODE=1
        ;;
    000)
        REACHABLE=false
        USABLE=false
        RECOMMENDATION="fallback"
        ERROR="No response received"
        EXIT_CODE=1
        ;;
    *)
        REACHABLE=true
        USABLE=false
        RECOMMENDATION="retry_later"
        ERROR="Unexpected HTTP status: $HTTP_CODE"
        EXIT_CODE=1
        ;;
esac

# ─── Output JSON ──────────────────────────────────────────────────────────────

jq -n \
    --arg provider "$PROVIDER" \
    --arg model "$MODEL" \
    --argjson reachable "$REACHABLE" \
    --argjson usable "$USABLE" \
    --argjson http_code "$HTTP_CODE" \
    --arg quota_status "$QUOTA_STATUS" \
    --argjson quota_remaining "$QUOTA_REMAINING" \
    --argjson latency_ms "$LATENCY_MS" \
    --arg error "$ERROR" \
    --arg recommendation "$RECOMMENDATION" \
    --arg mode "$MODE" \
    --arg timestamp "$(date -Iseconds)" \
    '{
        provider: $provider,
        model: $model,
        reachable: $reachable,
        usable: $usable,
        http_code: $http_code,
        quota_status: $quota_status,
        quota_remaining: $quota_remaining,
        latency_ms: $latency_ms,
        error: $error,
        recommendation: $recommendation,
        mode: $mode,
        timestamp: $timestamp
    }'

exit $EXIT_CODE
