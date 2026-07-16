#!/bin/bash
# validate-public-sync.sh v3 — Two-mode public sync validation
#
# Canonical path: scripts/validate-public-sync.sh
# Usage:
#   bash scripts/validate-public-sync.sh --mode internal   # Check manifest, templates, export mappings
#   bash scripts/validate-public-sync.sh --mode public     # Materialize staging tree, validate zero failures
#   bash scripts/validate-public-sync.sh                   # Run both modes
#
# Internal source mode does NOT scan internal canonical files for forbidden patterns.
# Public tree mode materializes sanitized templates into a staging tree and validates that.

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ "$(basename "$SCRIPT_DIR")" = "scripts" ]; then
    ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    ROOT_DIR="$SCRIPT_DIR"
fi

MANIFEST="$ROOT_DIR/.opencode/config/public-sync-manifest.yaml"
MODE="${1:-both}"
MODE="${MODE#--mode=}"
if [ "$MODE" = "--mode" ]; then
    MODE="${2:-both}"
fi

PASS=0
FAIL=0
WARN=0

pass() { printf '  PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }
warn() { printf '  WARN: %s\n' "$1"; WARN=$((WARN + 1)); }

FORBIDDEN_PATTERNS=()
load_forbidden_patterns() {
    while IFS= read -r line; do
        pattern=$(echo "$line" | sed 's/.*pattern: *"\([^"]*\)".*/\1/')
        if [ -n "$pattern" ]; then
            FORBIDDEN_PATTERNS+=("$pattern")
        fi
    done < <(grep '^\s*- pattern:' "$MANIFEST")
}

check_forbidden() {
    local file="$1"
    local found=0
    for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
        if grep -q "$pattern" "$file" 2>/dev/null; then
            found=$((found + 1))
        fi
    done
    echo "$found"
}

# ── Internal source mode ────────────────────────────────────────────────────
run_internal_mode() {
    echo "=========================================="
    echo "Public Sync Validation — Internal Source Mode"
    echo "=========================================="
    echo ""

    echo "== Manifest =="
    if [ ! -f "$MANIFEST" ]; then
        fail "public-sync-manifest.yaml not found"
        return
    fi
    pass "Manifest found"
    load_forbidden_patterns
    pass "Loaded ${#FORBIDDEN_PATTERNS[@]} forbidden patterns"

    echo ""
    echo "== Export Mappings (templates exist and are clean) =="

    local template_paths=()
    while IFS= read -r line; do
        template=$(echo "$line" | sed 's/.*public_template: *//' | tr -d ' ')
        if [ -n "$template" ]; then
            template_paths+=("$template")
        fi
    done < <(grep 'public_template:' "$MANIFEST")

    for tmpl in "${template_paths[@]}"; do
        local full_path="$ROOT_DIR/$tmpl"
        if [ ! -f "$full_path" ]; then
            fail "Template not found: $tmpl"
            continue
        fi
        local forbidden_count=$(check_forbidden "$full_path")
        if [ "$forbidden_count" -eq 0 ]; then
            pass "$(basename "$tmpl"): sanitized (0 forbidden patterns)"
        else
            fail "$(basename "$tmpl"): contains $forbidden_count forbidden patterns"
        fi
    done

    echo ""
    echo "== Version Domains =="
    for vfield in protocol_release protocol_kernel brain_config_revision model_registry_schema; do
        if grep -q "$vfield:" "$MANIFEST"; then
            local vval=$(grep "$vfield:" "$MANIFEST" | head -1 | sed 's/.*: *"\{0,1\}\([^"]*\)"\{0,1\}/\1/')
            pass "$vfield: $vval"
        else
            fail "Version domain '$vfield' not declared in manifest"
        fi
    done

    echo ""
    echo "== Internal-Only File Coverage =="
    for f in brain-config.json model-registry.yaml opencode.json AGENTS.md rules.md helper-roster.md; do
        local template_path=""
        case "$f" in
            brain-config.json) template_path=".opencode/templates/brain-config.public.json" ;;
            model-registry.yaml) template_path=".opencode/templates/model-registry.public.yaml" ;;
            opencode.json) template_path=".opencode/templates/opencode.public.json" ;;
            AGENTS.md) template_path=".opencode/templates/AGENTS.public.md" ;;
            rules.md) template_path=".opencode/templates/rules.public.md" ;;
            helper-roster.md) template_path=".opencode/templates/helper-roster.public.md" ;;
        esac
        if [ -f "$ROOT_DIR/$template_path" ]; then
            pass "$f: public template exists"
        else
            fail "$f: no public template found"
        fi
    done

    echo ""
    echo "== Prompt Mirrors =="
    for agent in orchestrator explorer planner implementer reviewer architect budget visual-reviewer visual-reviewer-fallback; do
        if [ -f "$ROOT_DIR/.opencode/global-runtime/prompts/$agent.md" ]; then
            pass "Prompt mirror: $agent.md exists"
        else
            fail "Prompt mirror: $agent.md missing"
        fi
    done
}

# ── Public tree mode ────────────────────────────────────────────────────────
run_public_mode() {
    echo "=========================================="
    echo "Public Sync Validation — Public Tree Mode"
    echo "=========================================="
    echo ""

    load_forbidden_patterns

    echo "== Materializing Staging Tree =="
    STAGING_DIR=$(mktemp -d /tmp/public-sync-staging-XXXXXX)
    pass "Staging directory: $STAGING_DIR"

    mkdir -p "$STAGING_DIR/.opencode/agents"
    mkdir -p "$STAGING_DIR/.opencode/global-runtime/prompts"
    mkdir -p "$STAGING_DIR/.opencode/templates"

    # Materialize from templates
    materialize() {
        local template="$1"
        local target="$2"
        local full_template="$ROOT_DIR/$template"
        local full_target="$STAGING_DIR/$target"

        if [ -f "$full_template" ]; then
            mkdir -p "$(dirname "$full_target")"
            cp "$full_template" "$full_target"
            pass "Materialized: $target"
        else
            fail "Cannot materialize $target — template missing: $template"
        fi
    }

    materialize ".opencode/templates/brain-config.public.json" ".opencode/brain-config.json"
    materialize ".opencode/templates/model-registry.public.yaml" ".opencode/model-registry.yaml"
    materialize ".opencode/templates/opencode.public.json" ".opencode/opencode.json"
    materialize ".opencode/templates/AGENTS.public.md" ".opencode/AGENTS.md"
    materialize ".opencode/templates/rules.public.md" ".opencode/rules.md"
    materialize ".opencode/templates/helper-roster.public.md" ".opencode/helper-roster.md"
    materialize ".opencode/templates/visual-reviewer.public.md" ".opencode/agents/visual-reviewer.md"
    materialize ".opencode/templates/visual-reviewer-fallback.public.md" ".opencode/agents/visual-reviewer-fallback.md"
    materialize ".opencode/templates/prompt-visual-reviewer.public.md" ".opencode/global-runtime/prompts/visual-reviewer.md"
    materialize ".opencode/templates/prompt-visual-reviewer-fallback.public.md" ".opencode/global-runtime/prompts/visual-reviewer-fallback.md"

    # Forbidden pattern scan
    echo ""
    echo "== Forbidden Pattern Scan (staging tree) =="

    STAGING_FILES=$(find "$STAGING_DIR" -type f \( -name "*.md" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) 2>/dev/null)

    for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
        local found=0
        local found_in=""
        while IFS= read -r f; do
            if grep -q "$pattern" "$f" 2>/dev/null; then
                found=1
                found_in="$found_in $(basename "$f")"
            fi
        done <<< "$STAGING_FILES"
        if [ "$found" -eq 0 ]; then
            pass "No forbidden pattern '$pattern' in staging tree"
        else
            fail "Forbidden pattern '$pattern' found in:$found_in"
        fi
    done

    # Required canonical files
    echo ""
    echo "== Required Canonical Files =="
    for reqfile in .opencode/brain-config.json .opencode/model-registry.yaml .opencode/opencode.json .opencode/AGENTS.md .opencode/rules.md .opencode/helper-roster.md; do
        if [ -f "$STAGING_DIR/$reqfile" ]; then
            pass "$reqfile: exists in staging tree"
        else
            fail "$reqfile: missing from staging tree"
        fi
    done

    # Placeholder model IDs
    echo ""
    echo "== Placeholder Model IDs =="
    for reqfile in .opencode/brain-config.json .opencode/model-registry.yaml .opencode/opencode.json; do
        if [ -f "$STAGING_DIR/$reqfile" ]; then
            if grep -q "YOUR_PROVIDER" "$STAGING_DIR/$reqfile" 2>/dev/null; then
                pass "$(basename "$reqfile"): uses YOUR_PROVIDER placeholders"
            else
                warn "$(basename "$reqfile"): no YOUR_PROVIDER found (may not need placeholders)"
            fi
        fi
    done

    # Agent verdicts
    echo ""
    echo "== Agent Verdicts =="
    for f in visual-reviewer visual-reviewer-fallback; do
        if [ -f "$STAGING_DIR/.opencode/agents/$f.md" ]; then
            if grep -q "READY TO SHIP" "$STAGING_DIR/.opencode/agents/$f.md" 2>/dev/null; then
                fail "$f.md: still has 'READY TO SHIP' verdict"
            else
                pass "$f.md: uses TECHNICAL_VISUAL_PASS/FAIL"
            fi
        fi
    done

    # Drift detection
    echo ""
    echo "== Template-to-Target Drift Detection =="
    for pair in \
        ".opencode/templates/brain-config.public.json:.opencode/brain-config.json" \
        ".opencode/templates/model-registry.public.yaml:.opencode/model-registry.yaml" \
        ".opencode/templates/opencode.public.json:.opencode/opencode.json" \
        ".opencode/templates/AGENTS.public.md:.opencode/AGENTS.md" \
        ".opencode/templates/rules.public.md:.opencode/rules.md" \
        ".opencode/templates/helper-roster.public.md:.opencode/helper-roster.md"; do
        local tmpl="${pair%%:*}"
        local target="${pair##*:}"
        if [ -f "$ROOT_DIR/$tmpl" ] && [ -f "$STAGING_DIR/$target" ]; then
            if diff -q "$ROOT_DIR/$tmpl" "$STAGING_DIR/$target" >/dev/null 2>&1; then
                pass "$(basename "$target"): template matches public target (no drift)"
            else
                fail "$(basename "$target"): template-to-target drift detected"
            fi
        fi
    done

    rm -rf "$STAGING_DIR"
}

# ── Main ────────────────────────────────────────────────────────────────────
case "$MODE" in
    internal) run_internal_mode ;;
    public)   run_public_mode ;;
    both)     run_internal_mode; echo ""; run_public_mode ;;
    *)        echo "Usage: $0 [--mode internal|public|both]"; exit 1 ;;
esac

echo ""
echo "=========================================="
printf '  PASSED: %d\n' "$PASS"
printf '  FAILED: %d\n' "$FAIL"
printf '  WARNED: %d\n' "$WARN"
echo "=========================================="

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "[FAIL] Public sync validation failed. Fix issues above."
    exit 1
else
    echo ""
    echo "[PASS] Public sync validation passed."
    exit 0
fi
