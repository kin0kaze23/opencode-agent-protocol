#!/bin/bash
# Empty Response Guardrail Runtime Enforcement
# This script validates model responses and retries with qwen3.6-plus if empty.
# Usage: bash .opencode/scripts/empty-response-guard.sh <model> <task_type> <prompt_hash> <latency> <tokens> <response_content>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$ROOT_DIR/metrics/empty-response"
mkdir -p "$LOG_DIR"

# Arguments
MODEL="${1:-}"
TASK_TYPE="${2:-}"
PROMPT_HASH="${3:-}"
LATENCY="${4:-}"
TOKENS="${5:-}"
RESPONSE_CONTENT="${6:-}"

TIMESTAMP=$(date -Iseconds)
LOG_FILE="$LOG_DIR/empty-response-$(date +%Y%m%d-%H%M%S).json"

# ─── Validation ───────────────────────────────────────────────────────────────

if [ -z "$MODEL" ] || [ -z "$RESPONSE_CONTENT" ]; then
    echo "ERROR: Missing required arguments. Usage: $0 <model> <task_type> <prompt_hash> <latency> <tokens> <response_content>"
    exit 1
fi

# Check if response is empty or whitespace-only
if [ -z "$(echo "$RESPONSE_CONTENT" | tr -d '[:space:]')" ]; then
    echo "EMPTY RESPONSE DETECTED"
    echo "Model: $MODEL"
    echo "Task: $TASK_TYPE"
    echo "Timestamp: $TIMESTAMP"

    # Log the failure
    cat > "$LOG_FILE" <<EOF
{
    "timestamp": "$TIMESTAMP",
    "model": "$MODEL",
    "task_type": "$TASK_TYPE",
    "prompt_hash": "$PROMPT_HASH",
    "latency_seconds": "$LATENCY",
    "token_usage": "$TOKENS",
    "failure_reason": "empty_content",
    "action": "retry_with_qwen3.6-plus",
    "retry_status": "pending"
}
EOF

    echo "Logged to: $LOG_FILE"
    echo "ACTION: Retry with opencode-go/qwen3.6-plus"
    echo "RULE: Never allow empty response to pass as successful task completion."

    exit 2  # Signal that retry is needed
else
    echo "RESPONSE VALID"
    echo "Model: $MODEL"
    echo "Content length: $(echo "$RESPONSE_CONTENT" | wc -c) bytes"
    exit 0  # Response is valid
fi
