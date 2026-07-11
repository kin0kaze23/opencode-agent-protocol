#!/bin/bash
# OpenCode Metrics Baseline Report Generator (P3D)
# Purpose: Read local raw metrics JSONL and produce sanitized baseline reports
# Usage: bash .opencode/metrics/report.sh [--date YYYY-MM-DD] [--output-dir .opencode/metrics/reports/]
#
# This script NEVER logs prompts, responses, secrets, file contents, or private data.
# It produces metadata-only reports suitable for commit if sanitized.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RAW_DIR="$WORKSPACE_ROOT/.opencode/metrics/raw"
OUTPUT_DIR="$WORKSPACE_ROOT/.opencode/metrics/reports"
DATE=$(date +%Y-%m-%d)

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --date) DATE="$2"; shift 2 ;;
        --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Find raw log file for date
RAW_FILE="$RAW_DIR/events-${DATE}.jsonl"
if [ ! -f "$RAW_FILE" ]; then
    echo "⚠️  No raw metrics found for $DATE"
    echo "Generating sample report instead..."
    RAW_FILE=""
fi

# Sample-size rules
get_sample_status() {
    local count=$1
    if [ "$count" -lt 20 ]; then
        echo "INSUFFICIENT_SAMPLE_SIZE"
    elif [ "$count" -lt 50 ]; then
        echo "SOFT_OBSERVATIONS"
    elif [ "$count" -lt 100 ]; then
        echo "CANDIDATE_THRESHOLDS"
    else
        echo "NON_BLOCKING_WARNINGS"
    fi
}

# Generate report
REPORT_FILE="$OUTPUT_DIR/baseline-${DATE}.json"

if [ -n "$RAW_FILE" ] && [ -f "$RAW_FILE" ]; then
    # Calculate metrics from raw data
    TOTAL=$(wc -l < "$RAW_FILE" | tr -d ' ')
    SAMPLE_STATUS=$(get_sample_status "$TOTAL")

    # Count by task_type
    TASK_TYPES=$(jq -s 'group_by(.task_type) | map({type: .[0].task_type, count: length})' "$RAW_FILE" 2>/dev/null || echo "[]")

    # Count by agent
    AGENTS=$(jq -s 'group_by(.agent) | map({agent: .[0].agent, count: length})' "$RAW_FILE" 2>/dev/null || echo "[]")

    # Count by model_route
    MODELS=$(jq -s 'group_by(.model_route) | map({model: .[0].model_route, count: length})' "$RAW_FILE" 2>/dev/null || echo "[]")

    # Success/failure rate
    SUCCESS_COUNT=$(jq -s '[.[] | select(.status == "success")] | length' "$RAW_FILE" 2>/dev/null || echo "0")
    FAIL_COUNT=$(jq -s '[.[] | select(.status == "fail")] | length' "$RAW_FILE" 2>/dev/null || echo "0")

    # Latency percentiles (p50, p75, p95)
    LATENCY_STATS=$(jq -s '[.[].latency_ms | select(. != null)] | sort |
        {
            p50: .[length * 0.5 | floor],
            p75: .[length * 0.75 | floor],
            p95: .[length * 0.95 | floor],
            min: .[0],
            max: .[-1],
            avg: (add / length)
        }' "$RAW_FILE" 2>/dev/null || echo '{"p50":null,"p75":null,"p95":null,"min":null,"max":null,"avg":null}')

    # Token totals
    TOKENS_IN_TOTAL=$(jq -s '[.[].tokens_in | select(. != null)] | add // 0' "$RAW_FILE" 2>/dev/null || echo "0")
    TOKENS_OUT_TOTAL=$(jq -s '[.[].tokens_out | select(. != null)] | add // 0' "$RAW_FILE" 2>/dev/null || echo "0")
    UNKNOWN_TOKENS=$(jq -s '[.[] | select(.tokens_in == null or .tokens_out == null)] | length' "$RAW_FILE" 2>/dev/null || echo "0")

    # Cost totals
    COST_TOTAL=$(jq -s '[.[].estimated_cost | select(. != null)] | add // 0' "$RAW_FILE" 2>/dev/null || echo "0")
    UNKNOWN_COST=$(jq -s '[.[] | select(.estimated_cost == null)] | length' "$RAW_FILE" 2>/dev/null || echo "0")

    # Error distribution
    ERRORS=$(jq -s 'group_by(.error_category) | map({category: .[0].error_category, count: length})' "$RAW_FILE" 2>/dev/null || echo "[]")

    # Build report
    jq -n \
        --arg date "$DATE" \
        --arg generated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --argjson total "$TOTAL" \
        --arg sample_status "$SAMPLE_STATUS" \
        --argjson task_types "$TASK_TYPES" \
        --argjson agents "$AGENTS" \
        --argjson models "$MODELS" \
        --argjson success_count "$SUCCESS_COUNT" \
        --argjson fail_count "$FAIL_COUNT" \
        --argjson latency_stats "$LATENCY_STATS" \
        --argjson tokens_in_total "$TOKENS_IN_TOTAL" \
        --argjson tokens_out_total "$TOKENS_OUT_TOTAL" \
        --argjson unknown_tokens "$UNKNOWN_TOKENS" \
        --argjson cost_total "$COST_TOTAL" \
        --argjson unknown_cost "$UNKNOWN_COST" \
        --argjson errors "$ERRORS" \
        '{
            date: $date,
            generated: $generated,
            total_events: $total,
            sample_status: $sample_status,
            by_task_type: $task_types,
            by_agent: $agents,
            by_model_route: $models,
            success_fail_rate: {
                success: $success_count,
                fail: $fail_count,
                success_rate: (if $total > 0 then ($success_count / $total * 100) else 0 end)
            },
            latency_percentiles: $latency_stats,
            tokens: {
                total_in: $tokens_in_total,
                total_out: $tokens_out_total,
                unknown_count: $unknown_tokens
            },
            cost: {
                total_estimated_usd: $cost_total,
                unknown_count: $unknown_cost
            },
            error_distribution: $errors,
            notes: [
                "This report contains metadata only. No prompts, responses, secrets, or private data.",
                "Sample status: \($sample_status). Thresholds are not enforced until 100+ samples."
            ]
        }' > "$REPORT_FILE"

    echo "✅ Report generated: $REPORT_FILE"
    echo "   Total events: $TOTAL"
    echo "   Sample status: $SAMPLE_STATUS"
else
    # Generate sample report with placeholder data
    jq -n \
        --arg date "$DATE" \
        --arg generated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '{
            date: $date,
            generated: $generated,
            total_events: 0,
            sample_status: "INSUFFICIENT_SAMPLE_SIZE",
            by_task_type: [],
            by_agent: [],
            by_model_route: [],
            success_fail_rate: { success: 0, fail: 0, success_rate: 0 },
            latency_percentiles: { p50: null, p75: null, p95: null, min: null, max: null, avg: null },
            tokens: { total_in: 0, total_out: 0, unknown_count: 0 },
            cost: { total_estimated_usd: 0, unknown_count: 0 },
            error_distribution: [],
            notes: [
                "SAMPLE REPORT: No raw metrics available for this date.",
                "This report contains metadata only. No prompts, responses, secrets, or private data.",
                "Thresholds are not enforced until 100+ samples."
            ]
        }' > "$REPORT_FILE"

    echo "⚠️  Sample report generated (no raw data): $REPORT_FILE"
fi

exit 0
