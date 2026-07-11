#!/bin/bash
# OpenCode Metrics Capture Script (P3C)
# Purpose: Lightweight, privacy-safe, non-blocking local metrics capture with cost/token estimation
# Usage: bash .opencode/metrics/capture.sh --task_type conformance --status success --latency_ms 1234 --tokens_in 1000 --tokens_out 500
#
# This script writes JSONL events to .opencode/metrics/raw/
# It NEVER blocks commits or CI. Failures print a warning and exit 0.
# It NEVER logs prompts, responses, secrets, file contents, or private data.
# It estimates cost only if tokens are provided and a local rate card exists.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RAW_DIR="$WORKSPACE_ROOT/.opencode/metrics/raw"
RATE_CARD="$WORKSPACE_ROOT/.opencode/metrics/rate-card.local.json"

# Ensure raw directory exists
mkdir -p "$RAW_DIR"

# Parse arguments
TASK_TYPE=""
STATUS="success"
LATENCY_MS=""
AGENT=""
MODEL_ROUTE=""
ERROR_CATEGORY="none"
CONFORMANCE_STATUS=""
TOKENS_IN=""
TOKENS_OUT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --task_type) TASK_TYPE="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        --latency_ms) LATENCY_MS="$2"; shift 2 ;;
        --agent) AGENT="$2"; shift 2 ;;
        --model_route) MODEL_ROUTE="$2"; shift 2 ;;
        --error_category) ERROR_CATEGORY="$2"; shift 2 ;;
        --conformance_status) CONFORMANCE_STATUS="$2"; shift 2 ;;
        --tokens_in) TOKENS_IN="$2"; shift 2 ;;
        --tokens_out) TOKENS_OUT="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# Gather metadata
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
WORKSPACE=$(basename "$WORKSPACE_ROOT")
GIT_SHA=$(git -C "$WORKSPACE_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown")

# Determine token/cost sources and values
TOKENS_SOURCE="unknown"
COST_SOURCE="unknown"
COST_CONFIDENCE="unknown"
CURRENCY="USD"
RATE_CARD_VERSION="null"
ESTIMATED_COST="null"

if [ -n "$TOKENS_IN" ] || [ -n "$TOKENS_OUT" ]; then
    TOKENS_SOURCE="cli_output"
    if [ -f "$RATE_CARD" ]; then
        COST_SOURCE="configured_rate_card"
        COST_CONFIDENCE="estimated"
        RATE_CARD_VERSION=$(jq -r '.version // "unknown"' "$RATE_CARD" 2>/dev/null || echo "unknown")
        CURRENCY=$(jq -r '.currency // "USD"' "$RATE_CARD" 2>/dev/null || echo "USD")

        # Calculate estimated cost if tokens provided
        if [ -n "$TOKENS_IN" ] || [ -n "$TOKENS_OUT" ]; then
            ESTIMATED_COST=$(jq -n \
                --arg model "${MODEL_ROUTE:-unknown}" \
                --argjson tokens_in "${TOKENS_IN:-0}" \
                --argjson tokens_out "${TOKENS_OUT:-0}" \
                --slurpfile card "$RATE_CARD" \
                '
                ($card[0].models[$model] // null) as $rates |
                if $rates then
                    (($tokens_in / 1000000) * $rates.input_per_million_tokens) +
                    (($tokens_out / 1000000) * $rates.output_per_million_tokens)
                else
                    null
                end
                ' 2>/dev/null || echo "null")
        fi
    fi
fi

# Build JSON event (metadata only, privacy-safe)
EVENT=$(jq -c -n \
    --arg timestamp "$TIMESTAMP" \
    --arg workspace "$WORKSPACE" \
    --arg git_sha "$GIT_SHA" \
    --arg agent "${AGENT:-unknown}" \
    --arg task_type "${TASK_TYPE:-unknown}" \
    --arg model_route "${MODEL_ROUTE:-unknown}" \
    --arg latency_ms "${LATENCY_MS:-null}" \
    --arg status "$STATUS" \
    --argjson tokens_in "${TOKENS_IN:-null}" \
    --argjson tokens_out "${TOKENS_OUT:-null}" \
    --arg tokens_source "$TOKENS_SOURCE" \
    --argjson estimated_cost "$ESTIMATED_COST" \
    --arg cost_source "$COST_SOURCE" \
    --arg cost_confidence "$COST_CONFIDENCE" \
    --arg currency "$CURRENCY" \
    --arg rate_card_version "$RATE_CARD_VERSION" \
    --arg error_category "$ERROR_CATEGORY" \
    --arg conformance_status "${CONFORMANCE_STATUS:-null}" \
    '{
        timestamp: $timestamp,
        workspace: $workspace,
        git_sha: $git_sha,
        agent: $agent,
        task_type: $task_type,
        model_route: $model_route,
        latency_ms: (if $latency_ms == "null" then null else ($latency_ms | tonumber) end),
        status: $status,
        tokens_in: $tokens_in,
        tokens_out: $tokens_out,
        tokens_source: $tokens_source,
        estimated_cost: $estimated_cost,
        cost_source: $cost_source,
        cost_confidence: $cost_confidence,
        currency: $currency,
        rate_card_version: $rate_card_version,
        error_category: $error_category,
        conformance_status: $conformance_status
    }')

# Simple schema validation (check required fields exist)
REQUIRED_FIELDS=("timestamp" "workspace" "git_sha" "agent" "task_type" "model_route" "status")
VALID=true
for field in "${REQUIRED_FIELDS[@]}"; do
    if ! echo "$EVENT" | jq -e "has(\"$field\")" > /dev/null 2>&1; then
        VALID=false
        break
    fi
done

if [ "$VALID" = true ]; then
    # Write to raw JSONL (non-blocking)
    echo "$EVENT" >> "$RAW_DIR/events-$(date +%Y-%m-%d).jsonl" 2>/dev/null || {
        echo "⚠️  Metrics capture failed to write to $RAW_DIR (non-blocking)"
        exit 0
    }
else
    echo "⚠️  Metrics event validation failed (non-blocking)"
    exit 0
fi

exit 0
