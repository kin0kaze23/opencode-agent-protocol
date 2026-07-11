#!/bin/bash
# Model Snapshot — Read-only model availability + Zen Free fallback detection
# Phase 1: Availability detection + Free fallback roster tracking
#
# Usage: bash .opencode/scripts/model-snapshot.sh
#
# Output (ALL under .opencode/benchmarks/model-snapshots/):
#   YYYY-MM-DD-go.json              — Go endpoint model list
#   YYYY-MM-DD-zen.json             — Zen endpoint model list
#   YYYY-MM-DD-diff.md              — Dual-track drift report:
#                                      Track 1: Go production model drift
#                                      Track 2: Zen Free fallback roster drift
#   canary-suggestions.md           — New Go models flagged for paid-tier evaluation
#   free-fallback-suggestions.md    — Zen Free fallback role classification + privacy warnings
#
# SAFETY:
#   - Does NOT modify model-registry.yaml or any config file
#   - Does NOT invoke any model (no billing impact)
#   - Does NOT require API key (public /models endpoint)
#   - Writes ONLY to .opencode/benchmarks/model-snapshots/
#
# Exit codes:
#   0 = success
#   1 = endpoint failure
#   2 = JSON parse failure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SNAPSHOT_DIR="$WORKSPACE_ROOT/.opencode/benchmarks/model-snapshots"
REGISTRY="$WORKSPACE_ROOT/.opencode/model-registry.yaml"
TODAY=$(date +%Y-%m-%d)
TIMESTAMP=$(date -Iseconds)

mkdir -p "$SNAPSHOT_DIR"

# ─── Endpoint URLs ───────────────────────────────────────────────────────────
GO_URL="https://opencode.ai/zen/go/v1/models"
ZEN_URL="https://opencode.ai/zen/v1/models"

# ─── Expected Zen Free Roster (TEMPORARY Phase 1 baseline) ───────────────────
# This hardcoded list is a Phase 1 temporary baseline.
# Phase 2 will move this to model-registry.yaml §expected_zen_free_set.
# Last verified: 2026-06-13 from Zen endpoint + Zen docs.
EXPECTED_ZEN_FREE_ROSTER=(
    "deepseek-v4-flash-free"
    "mimo-v2.5-free"
    "north-mini-code-free"
    "nemotron-3-ultra-free"
    "big-pickle"
    "qwen3.6-plus-free"
    "minimax-m3-free"
)

# ─── Deprecation map (from Zen docs, updated 2026-06-14) ────────────────────
# Format: model_id|deprecation_date (YYYY-MM-DD)
# Models with dates in the past are already deprecated.
# Models with dates in the future are scheduled for deprecation.
DEPRECATION_MAP=(
    "glm-5|2026-05-14"
    "claude-sonnet-4|2026-06-15"
    "gpt-5.2-codex|2026-07-23"
    "gpt-5.1-codex|2026-07-23"
    "gpt-5.1-codex-max|2026-07-23"
    "gpt-5.1-codex-mini|2026-07-23"
    "gpt-5-codex|2026-07-23"
    "glm-4.7|2026-03-15"
    "glm-4.6|2026-03-15"
    "gemini-3-pro|2026-03-09"
    "kimi-k2-thinking|2026-03-06"
    "kimi-k2|2026-03-06"
    "claude-haiku-3.5|2026-02-16"
    "qwen3-coder-480b|2026-02-06"
    "minimax-m2.1|2026-03-15"
)

# ─── Helper: get deprecation date for a model ────────────────────────────────
get_deprecation_date() {
    local model="$1"
    for entry in "${DEPRECATION_MAP[@]}"; do
        local m="${entry%%|*}"
        if [ "$m" = "$model" ]; then
            echo "${entry#*|}"
            return
        fi
    done
    echo ""
}

# ─── Helper: get deprecation status for a model ──────────────────────────────
# Returns: "deprecated" if date < TODAY, "scheduled_deprecation" if date >= TODAY
# Returns: "" if model is not in the deprecation map
get_deprecation_status() {
    local model="$1"
    local dep_date
    dep_date=$(get_deprecation_date "$model")
    if [ -z "$dep_date" ]; then
        echo ""
        return
    fi
    # Compare dates as strings (YYYY-MM-DD format is lexicographically comparable)
    if [[ "$dep_date" < "$TODAY" ]]; then
        echo "deprecated"
    else
        echo "scheduled_deprecation"
    fi
}

# ─── Helper: get deprecation label for display ───────────────────────────────
get_deprecation_label() {
    local model="$1"
    local status
    status=$(get_deprecation_status "$model")
    local dep_date
    dep_date=$(get_deprecation_date "$model")
    case "$status" in
        deprecated)
            echo "**DEPRECATED** (since $dep_date)"
            ;;
        scheduled_deprecation)
            echo "**SCHEDULED DEPRECATION** ($dep_date)"
            ;;
        *)
            echo ""
            ;;
    esac
}

# ─── Helper: check if model is in deprecation map ────────────────────────────
is_deprecated_or_scheduled() {
    local model="$1"
    local status
    status=$(get_deprecation_status "$model")
    [ -n "$status" ]
}

# ─── Free model privacy classifications ──────────────────────────────────────
# Based on Zen docs privacy section (verified 2026-06-13).
# Format: model_id|privacy_tier|docs_status|warning_text
FREE_PRIVACY_MAP=(
    "deepseek-v4-flash-free|free-training-exception|docs_listed|Data MAY be used to improve the model during free period"
    "mimo-v2.5-free|free-training-exception|docs_listed|Data MAY be used to improve the model during free period"
    "north-mini-code-free|free-training-exception|docs_listed|Data MAY be used to improve the model during free period"
    "nemotron-3-ultra-free|free-nvidia-logged|docs_listed|Sessions logged for security + NVIDIA product improvement. Do NOT submit confidential data"
    "big-pickle|free-stealth-training|docs_listed|Stealth model identity. Data MAY be used for improvement during free period"
    "qwen3.6-plus-free|free-unspecified|docs_free_text_missing|Not named in Zen docs free-model text. Endpoint-present but no explicit privacy statement. Assume unsafe for sensitive context"
    "minimax-m3-free|free-unspecified|docs_free_text_missing|Not named in Zen docs free-model text. Endpoint-present but no explicit privacy statement. Assume unsafe for sensitive context"
)

# ─── Free model fallback classifications (based on existing local evidence) ──
# Format: model_id|fallback_role|evidence_basis
FREE_FALLBACK_MAP=(
    "deepseek-v4-flash-free|candidate_budget_explorer|Registry: candidate_eval_pending. Same family as production explorer (deepseek-v4-flash). Canary required."
    "mimo-v2.5-free|candidate_readonly_helper|Registry: eval_passed_manual_only (Phase 2C, 6/6 PASS, 4.7/5). Allowed for non-sensitive read-only work. Re-evaluate after Go quota reset."
    "qwen3.6-plus-free|candidate_planning_helper|Newly detected in endpoint. Same family as production fallback (qwen3.6-plus). Canary required. No prior eval. Docs free text missing."
    "minimax-m3-free|candidate_ui_qa_helper|Newly detected in endpoint. Same family as approved UI specialist (minimax-m3, Phase 3C passed). Canary required. No direct eval. Docs free text missing."
    "north-mini-code-free|candidate_budget_explorer|Registry: candidate_eval_pending. No prior eval. Canary required."
    "nemotron-3-ultra-free|avoid_for_sensitive_context|Registry: candidate_eval_pending. NVIDIA trial logging warning. Do NOT use for confidential work."
    "big-pickle|avoid_for_sensitive_context|Registry: candidate_eval_pending. Stealth model + training exception. Do NOT use for production or private work."
)

# ─── Fetch function ──────────────────────────────────────────────────────────
fetch_models() {
    local url="$1"
    local output_file="$2"
    local label="$3"

    echo "Fetching $label models from $url ..."

    HTTP_CODE=$(curl -s -o "$output_file" -w "%{http_code}" \
        -H "Content-Type: application/json" \
        --max-time 15 \
        "$url" 2>/dev/null) || {
        echo "ERROR: Failed to fetch $label models (curl exit $?)"
        return 1
    }

    if [ "$HTTP_CODE" != "200" ]; then
        echo "ERROR: $label endpoint returned HTTP $HTTP_CODE"
        return 1
    fi

    # Validate JSON structure
    if ! jq -e '.data[].id' "$output_file" > /dev/null 2>&1; then
        echo "ERROR: $label response is not valid model list JSON"
        return 2
    fi

    MODEL_COUNT=$(jq '.data | length' "$output_file")
    echo "  → $MODEL_COUNT models found"

    # Add metadata wrapper
    jq --arg ts "$TIMESTAMP" --arg url "$url" --argjson count "$MODEL_COUNT" \
        '{snapshot_timestamp: $ts, endpoint_url: $url, model_count: $count, models: [.data[].id] | sort}' \
        "$output_file" > "${output_file}.tmp" && mv "${output_file}.tmp" "$output_file"

    return 0
}

# ─── Extract registry expected set ───────────────────────────────────────────
extract_registry_models() {
    if [ ! -f "$REGISTRY" ]; then
        echo "WARNING: model-registry.yaml not found at $REGISTRY"
        echo ""
        return
    fi

    awk '
        /expected_official_set:/ { found=1; next }
        found && /^      - / {
            line = $0
            gsub(/^      - /, "", line)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            print line
            next
        }
        found && /^    [a-zA-Z_]/ { found=0 }
    ' "$REGISTRY"
}

# ─── Helper: check if value is in array ──────────────────────────────────────
in_array() {
    local needle="$1"
    shift
    for item in "$@"; do
        [ "$item" = "$needle" ] && return 0
    done
    return 1
}

# ─── Helper: get privacy info for a free model ───────────────────────────────
get_privacy_info() {
    local model="$1"
    for entry in "${FREE_PRIVACY_MAP[@]}"; do
        local m="${entry%%|*}"
        if [ "$m" = "$model" ]; then
            echo "$entry" | cut -d'|' -f2-
            return
        fi
    done
    echo "unknown|unknown|No privacy information available"
}

# ─── Helper: get fallback info for a free model ──────────────────────────────
get_fallback_info() {
    local model="$1"
    for entry in "${FREE_FALLBACK_MAP[@]}"; do
        local m="${entry%%|*}"
        if [ "$m" = "$model" ]; then
            echo "$entry" | cut -d'|' -f2-
            return
        fi
    done
    echo "unknown_until_canary|No prior evaluation evidence"
}

# ─── Generate dual-track diff report ─────────────────────────────────────────
generate_diff() {
    local go_snapshot="$1"
    local zen_snapshot="$2"
    local diff_file="$SNAPSHOT_DIR/${TODAY}-diff.md"

    # Get model lists
    local GO_MODELS
    GO_MODELS=$(jq -r '.models[]' "$go_snapshot" | sort)
    local ZEN_MODELS
    ZEN_MODELS=$(jq -r '.models[]' "$zen_snapshot" | sort)
    local REGISTRY_MODELS
    REGISTRY_MODELS=$(extract_registry_models | sort)

    # Compute Go drift
    local NEW_IN_GO REMOVED_FROM_GO
    NEW_IN_GO=$(comm -23 <(echo "$GO_MODELS") <(echo "$REGISTRY_MODELS"))
    REMOVED_FROM_GO=$(comm -13 <(echo "$GO_MODELS") <(echo "$REGISTRY_MODELS"))

    # Compute Zen Free drift
    local ZEN_FREE_IN_ENDPOINT=()
    while IFS= read -r model; do
        [ -z "$model" ] && continue
        if [[ "$model" == *"-free" ]] || [[ "$model" == "big-pickle" ]]; then
            ZEN_FREE_IN_ENDPOINT+=("$model")
        fi
    done <<< "$ZEN_MODELS"

    local NEW_FREE_MODELS=()
    local REMOVED_FREE_MODELS=()
    local TRACKED_FREE_MODELS=()

    # Find new free models (in endpoint, not in expected roster)
    for model in "${ZEN_FREE_IN_ENDPOINT[@]}"; do
        if ! in_array "$model" "${EXPECTED_ZEN_FREE_ROSTER[@]}"; then
            NEW_FREE_MODELS+=("$model")
        fi
    done

    # Find removed free models (in expected roster, not in endpoint)
    for model in "${EXPECTED_ZEN_FREE_ROSTER[@]}"; do
        if ! in_array "$model" "${ZEN_FREE_IN_ENDPOINT[@]}"; then
            REMOVED_FREE_MODELS+=("$model")
        fi
    done

    # Find tracked free models (in both)
    for model in "${ZEN_FREE_IN_ENDPOINT[@]}"; do
        if in_array "$model" "${EXPECTED_ZEN_FREE_ROSTER[@]}"; then
            TRACKED_FREE_MODELS+=("$model")
        fi
    done

    # ─── Write diff report ───────────────────────────────────────────────────
    cat > "$diff_file" << HEADER
# Model Drift Report — $TODAY

Generated: $TIMESTAMP
Go endpoint: $GO_URL
Zen endpoint: $ZEN_URL

---

## Track 1: Go Production Model Drift

Go endpoint models: $(echo "$GO_MODELS" | wc -l | tr -d ' ')
Registry expected set: $(echo "$REGISTRY_MODELS" | wc -l | tr -d ' ')

HEADER

    # New in Go
    if [ -n "$NEW_IN_GO" ]; then
        echo "### 🆕 New in Go endpoint (not in registry) — UNEVALUATED, DO NOT ROUTE" >> "$diff_file"
        echo "" >> "$diff_file"
        while IFS= read -r model; do
            [ -z "$model" ] && continue
            if is_deprecated_or_scheduled "$model"; then
                local dep_label
                dep_label=$(get_deprecation_label "$model")
                echo "- ~~$model~~ — $dep_label (in endpoint, listed in Zen deprecation schedule)" >> "$diff_file"
            else
                echo "- $model — **UNEVALUATED — DO NOT ROUTE**" >> "$diff_file"
            fi
        done <<< "$NEW_IN_GO"
        echo "" >> "$diff_file"
    else
        echo "### New in Go endpoint: none" >> "$diff_file"
        echo "" >> "$diff_file"
    fi

    # Removed from Go
    if [ -n "$REMOVED_FROM_GO" ]; then
        echo "### ❌ Removed from Go endpoint (was in registry)" >> "$diff_file"
        echo "" >> "$diff_file"
        while IFS= read -r model; do
            [ -z "$model" ] && continue
            echo "- $model" >> "$diff_file"
        done <<< "$REMOVED_FROM_GO"
        echo "" >> "$diff_file"
    else
        echo "### Removed from Go endpoint: none" >> "$diff_file"
        echo "" >> "$diff_file"
    fi

    # Tracked in both
    echo "### ✅ Tracked in both registry and endpoint" >> "$diff_file"
    echo "" >> "$diff_file"
    while IFS= read -r model; do
        [ -z "$model" ] && continue
        if is_deprecated_or_scheduled "$model"; then
            local dep_label
            dep_label=$(get_deprecation_label "$model")
            echo "- $model — ⚠️ $dep_label (still in endpoint + registry)" >> "$diff_file"
        else
            echo "- $model" >> "$diff_file"
        fi
    done < <(comm -12 <(echo "$GO_MODELS") <(echo "$REGISTRY_MODELS"))
    echo "" >> "$diff_file"

    # ─── Track 2: Zen Free Fallback Roster Drift ────────────────────────────
    cat >> "$diff_file" << FREEHEADER

---

## Track 2: Zen Free Fallback Roster Drift

Expected free roster (Phase 1 baseline): ${#EXPECTED_ZEN_FREE_ROSTER[@]} models
Free models in Zen endpoint: ${#ZEN_FREE_IN_ENDPOINT[@]} models

> **SAFETY: All free models are limited-time, not for sensitive context.**
> **Never send private repo code, secrets, customer data, or proprietary planning to free/trial models.**

FREEHEADER

    # New free models
    if [ ${#NEW_FREE_MODELS[@]} -gt 0 ]; then
        echo "### 🆕 New free models (not in expected roster) — UNEVALUATED" >> "$diff_file"
        echo "" >> "$diff_file"
        for model in "${NEW_FREE_MODELS[@]}"; do
            local privacy_info
            privacy_info=$(get_privacy_info "$model")
            local tier="${privacy_info%%|*}"
            local rest="${privacy_info#*|}"
            local docs_status="${rest%%|*}"
            local warning="${rest#*|}"
            echo "- $model — **NEW — $warning**" >> "$diff_file"
        done
        echo "" >> "$diff_file"
    else
        echo "### New free models: none" >> "$diff_file"
        echo "" >> "$diff_file"
    fi

    # Removed free models
    if [ ${#REMOVED_FREE_MODELS[@]} -gt 0 ]; then
        echo "### ❌ Removed free models (was in expected roster)" >> "$diff_file"
        echo "" >> "$diff_file"
        for model in "${REMOVED_FREE_MODELS[@]}"; do
            echo "- $model — **UNAVAILABLE** (was expected, no longer in endpoint)" >> "$diff_file"
        done
        echo "" >> "$diff_file"
    else
        echo "### Removed free models: none" >> "$diff_file"
        echo "" >> "$diff_file"
    fi

    # Tracked free models
    echo "### ✅ Tracked free models (in both roster and endpoint)" >> "$diff_file"
    echo "" >> "$diff_file"
    for model in "${TRACKED_FREE_MODELS[@]}"; do
        local privacy_info
        privacy_info=$(get_privacy_info "$model")
        local tier="${privacy_info%%|*}"
        local rest="${privacy_info#*|}"
        local docs_status="${rest%%|*}"
        local warning="${rest#*|}"

        local docs_marker=""
        if [ "$docs_status" = "docs_free_text_missing" ]; then
            docs_marker=" — ⚠️ **NOT IN ZEN DOCS FREE TEXT**"
        fi

        echo "- $model — \`$tier\` — $warning$docs_marker" >> "$diff_file"
    done
    echo "" >> "$diff_file"

    # Deprecated cross-reference
    cat >> "$diff_file" << DEPHEADER

---

## Deprecated Models Cross-Reference

DEPHEADER
    local found_deprecated=false
    for entry in "${DEPRECATION_MAP[@]}"; do
        local model="${entry%%|*}"
        local dep_label
        dep_label=$(get_deprecation_label "$model")
        if echo "$GO_MODELS" | grep -qx "$model"; then
            echo "- $model — ⚠️ **STILL IN GO ENDPOINT** — $dep_label" >> "$diff_file"
            found_deprecated=true
        fi
        if echo "$ZEN_MODELS" | grep -qx "$model"; then
            echo "- $model — ⚠️ **STILL IN ZEN ENDPOINT** — $dep_label" >> "$diff_file"
            found_deprecated=true
        fi
    done
    if [ "$found_deprecated" = false ]; then
        echo "No deprecated models found in live endpoints." >> "$diff_file"
    fi
    echo "" >> "$diff_file"

    echo "---" >> "$diff_file"
    echo "*Report generated by model-snapshot.sh — read-only, no config changes*" >> "$diff_file"

    echo "Diff report: $diff_file"
}

# ─── Generate canary suggestions (Go production models) ──────────────────────
generate_canary_suggestions() {
    local go_snapshot="$1"
    local canary_file="$SNAPSHOT_DIR/canary-suggestions.md"

    local GO_MODELS
    GO_MODELS=$(jq -r '.models[]' "$go_snapshot" | sort)
    local REGISTRY_MODELS
    REGISTRY_MODELS=$(extract_registry_models | sort)
    local NEW_IN_GO
    NEW_IN_GO=$(comm -23 <(echo "$GO_MODELS") <(echo "$REGISTRY_MODELS"))

    if [ -n "$NEW_IN_GO" ]; then
        cat > "$canary_file" << CANARY
# Canary Suggestions — $TODAY

Generated: $TIMESTAMP

The following models were detected in the Go endpoint but are NOT in the model registry.
They require evaluation before any routing consideration.

**SAFETY: These are suggestions only. Manual registry edit required after owner approval.**
**SAFETY: Do NOT route any production task to these models until canary evaluation passes.**

CANARY

        while IFS= read -r model; do
            [ -z "$model" ] && continue
            if is_deprecated_or_scheduled "$model"; then
                local dep_label
                dep_label=$(get_deprecation_label "$model")
                cat >> "$canary_file" << ENTRY
## $model

- Status: $dep_label — **Do not add to canary queue**
- Reason: Listed in Zen deprecation schedule
- Action: Consider removing from registry expected_official_set if present

ENTRY
            else
                cat >> "$canary_file" << ENTRY
## $model

- Status: **UNEVALUATED — DO NOT ROUTE**
- Detected in: Go endpoint ($TODAY)
- Pricing status: Unknown (check OpenCode Go docs)
- Suggested canary roles: TBD after pricing and capability evaluation
- Promotion gates: ALL 9 gates required before any routing consideration
- Action: Owner to review and manually add to model-registry.yaml canary_queue if warranted

ENTRY
            fi
        done <<< "$NEW_IN_GO"

        echo "---" >> "$canary_file"
        echo "*Generated by model-snapshot.sh — advisory only, no config changes*" >> "$canary_file"
    else
        cat > "$canary_file" << EMPTY
# Canary Suggestions — $TODAY

Generated: $TIMESTAMP

No new Go production models detected. Registry is in sync with Go endpoint.
EMPTY
    fi

    echo "Canary suggestions: $canary_file"
}

# ─── Generate free fallback suggestions ──────────────────────────────────────
generate_free_fallback_suggestions() {
    local zen_snapshot="$1"
    local fallback_file="$SNAPSHOT_DIR/free-fallback-suggestions.md"

    local ZEN_MODELS
    ZEN_MODELS=$(jq -r '.models[]' "$zen_snapshot" | sort)

    # Collect free models from endpoint
    local ZEN_FREE_IN_ENDPOINT=()
    while IFS= read -r model; do
        [ -z "$model" ] && continue
        if [[ "$model" == *"-free" ]] || [[ "$model" == "big-pickle" ]]; then
            ZEN_FREE_IN_ENDPOINT+=("$model")
        fi
    done <<< "$ZEN_MODELS"

    cat > "$fallback_file" << HEADER
# Free Fallback Suggestions — $TODAY

Generated: $TIMESTAMP

This report classifies Zen Free models as fallback candidates for when OpenCode Go
quota is exhausted (\$12/5h, \$30/week, \$60/month limits reached).

## ⚠️ SAFETY RULES — READ BEFORE USING ANY FREE MODEL

1. **Free models are for non-sensitive work only unless explicitly approved by owner.**
2. **Do NOT send private repo code, secrets, customer data, or proprietary planning to free/trial models.**
3. **Free models are available on a limited-time basis. They may disappear without notice.**
4. **Several free models collect data for model improvement or logging.**
5. **Use free models only after Go quota is exhausted or for deliberately low-risk/budget tasks.**
6. **All free model fallbacks require canary evaluation before production use.**
7. **Go subscription models (zero-retention) are always preferred over free models for any sensitive work.**

---

## Go Quota Exhaustion Context

OpenCode Go limits are dollar-value based:
- 5-hour limit: \$12 of usage
- Weekly limit: \$30 of usage
- Monthly limit: \$60 of usage

Cheaper models (deepseek-v4-flash: ~31,650 req/5h) last much longer than expensive
models (glm-5.1: ~880 req/5h). When limits are reached, free models remain available
but with reduced privacy guarantees.

---

## Free Model Fallback Classifications

HEADER

    for model in "${ZEN_FREE_IN_ENDPOINT[@]}"; do
        local fallback_info
        fallback_info=$(get_fallback_info "$model")
        local role="${fallback_info%%|*}"
        local evidence="${fallback_info#*|}"

        local privacy_info
        privacy_info=$(get_privacy_info "$model")
        local privacy_tier="${privacy_info%%|*}"
        local rest="${privacy_info#*|}"
        local docs_status="${rest%%|*}"
        local privacy_warning="${rest#*|}"

        # Determine emoji/status by role
        local status_emoji="🔶"
        case "$role" in
            candidate_budget_explorer|candidate_readonly_helper|candidate_planning_helper|candidate_ui_qa_helper)
                status_emoji="🟢"
                ;;
            avoid_for_sensitive_context)
                status_emoji="🔴"
                ;;
            unknown_until_canary)
                status_emoji="🟡"
                ;;
        esac

        # Check if newly detected (not in expected roster)
        local new_marker=""
        if ! in_array "$model" "${EXPECTED_ZEN_FREE_ROSTER[@]}"; then
            new_marker=" — **NEWLY DETECTED**"
        fi

        # Check docs status
        local docs_marker=""
        if [ "$docs_status" = "docs_free_text_missing" ]; then
            docs_marker=" — ⚠️ **NOT IN ZEN DOCS FREE TEXT**"
        fi

        cat >> "$fallback_file" << ENTRY
### $status_emoji $model$new_marker$docs_marker

| Field | Value |
|---|---|
| Fallback role | \`$role\` |
| Privacy tier | \`$privacy_tier\` |
| Docs status | \`$docs_status\` |
| Privacy warning | $privacy_warning |
| Evidence | $evidence |
| Sensitive context safe? | ❌ No — free/trial model |

ENTRY

        # Add role-specific guidance
        case "$role" in
            candidate_budget_explorer)
                cat >> "$fallback_file" << GUIDANCE
**When to consider:** Read-only repo exploration, dependency mapping, debug loop iteration, cheap validation — when Go quota is exhausted and the work involves no sensitive code.

**When to avoid:** Any task touching secrets, auth, payment, customer data, or proprietary logic.

GUIDANCE
                ;;
            candidate_readonly_helper)
                cat >> "$fallback_file" << GUIDANCE
**When to consider:** Non-sensitive read-only audit, planning review, repo exploration — when Go quota is exhausted. Previously eval-passed for non-sensitive work.

**When to avoid:** Runtime orchestration, protocol seal, security review, production deployment, schema changes, secret-bearing work, irreversible writes.

GUIDANCE
                ;;
            candidate_planning_helper)
                cat >> "$fallback_file" << GUIDANCE
**When to consider:** Non-sensitive planning or helper fallback — when Go quota is exhausted. Same model family as production fallback (qwen3.6-plus). Canary evaluation required before use.

**When to avoid:** Any sensitive context. No prior eval evidence. Docs free text missing.

GUIDANCE
                ;;
            candidate_ui_qa_helper)
                cat >> "$fallback_file" << GUIDANCE
**When to consider:** Non-sensitive UI/QA helper fallback — when Go quota is exhausted. Same model family as approved UI specialist (minimax-m3). Canary evaluation required before use.

**When to avoid:** Any sensitive context. No direct eval evidence for this free variant. Docs free text missing.

GUIDANCE
                ;;
            avoid_for_sensitive_context)
                cat >> "$fallback_file" << GUIDANCE
**When to consider:** Only for deliberately public/non-sensitive experimentation when no other option is available.

**When to avoid:** ALL production work, ALL private repo context, ALL tasks involving secrets, auth, payment, customer data, or proprietary logic.

GUIDANCE
                ;;
            unknown_until_canary)
                cat >> "$fallback_file" << GUIDANCE
**When to consider:** Not yet. Requires canary evaluation before any fallback use.

**When to avoid:** Everything until canary evaluation passes.

GUIDANCE
                ;;
        esac
    done

    # Summary table
    cat >> "$fallback_file" << SUMMARY

---

## Summary: Free Fallback Roster

| Model | Fallback Role | Privacy Tier | Docs Status | Sensitive Safe? | Status |
|---|---|---|---|---|---|
SUMMARY

    for model in "${ZEN_FREE_IN_ENDPOINT[@]}"; do
        local fallback_info
        fallback_info=$(get_fallback_info "$model")
        local role="${fallback_info%%|*}"

        local privacy_info
        privacy_info=$(get_privacy_info "$model")
        local privacy_tier="${privacy_info%%|*}"
        local rest="${privacy_info#*|}"
        local docs_status="${rest%%|*}"

        local sensitive="❌ No"
        local status="Canary required"
        case "$role" in
            candidate_readonly_helper) status="Eval passed (non-sensitive only)" ;;
            candidate_budget_explorer|candidate_planning_helper|candidate_ui_qa_helper) status="Canary required" ;;
            avoid_for_sensitive_context) status="Avoid unless no alternative" ;;
            unknown_until_canary) status="Not yet evaluated" ;;
        esac

        echo "| $model | \`$role\` | \`$privacy_tier\` | \`$docs_status\` | $sensitive | $status |" >> "$fallback_file"
    done

    echo "" >> "$fallback_file"
    echo "---" >> "$fallback_file"
    echo "*Generated by model-snapshot.sh — advisory only, no config changes*" >> "$fallback_file"
    echo "*Free models are NOT production routing. Go subscription models are always preferred.*" >> "$fallback_file"

    echo "Free fallback suggestions: $fallback_file"
}

# ─── Main ────────────────────────────────────────────────────────────────────
echo "=== Model Snapshot — $TODAY ==="
echo ""

GO_FILE="$SNAPSHOT_DIR/${TODAY}-go.json"
ZEN_FILE="$SNAPSHOT_DIR/${TODAY}-zen.json"

# Fetch both endpoints
fetch_models "$GO_URL" "$GO_FILE" "Go" || exit $?
fetch_models "$ZEN_URL" "$ZEN_FILE" "Zen" || exit $?

echo ""

# Generate all reports
generate_diff "$GO_FILE" "$ZEN_FILE"
generate_canary_suggestions "$GO_FILE"
generate_free_fallback_suggestions "$ZEN_FILE"

echo ""
echo "=== Snapshot complete ==="
echo ""
echo "Output files:"
echo "  Go snapshot:               $GO_FILE"
echo "  Zen snapshot:              $ZEN_FILE"
echo "  Diff report:               $SNAPSHOT_DIR/${TODAY}-diff.md"
echo "  Canary suggestions:        $SNAPSHOT_DIR/canary-suggestions.md"
echo "  Free fallback suggestions: $SNAPSHOT_DIR/free-fallback-suggestions.md"
echo ""
echo "SAFETY: No config files were modified."
echo "Review all reports before any registry edits."

exit 0
