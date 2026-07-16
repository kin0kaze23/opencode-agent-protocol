#!/bin/bash
# validate-public-sync.sh v5 — Two-mode public sync validation
#
# Canonical path: scripts/validate-public-sync.sh
# Usage:
#   bash scripts/validate-public-sync.sh --mode internal   # Check manifest, templates, export mappings
#   bash scripts/validate-public-sync.sh --mode public     # Invoke canonical privacy scan + target-scoped supplementary scan
#   bash scripts/validate-public-sync.sh                   # Run both modes
#
# Public mode invokes scripts/public-surface-scan.sh as the canonical sanitation authority.
# The supplementary manifest scan is strictly target-scoped: it scans only declared
# public targets, not policy files, manifests, or test fixtures.

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

# Build scan target list from manifest declarations only
# This prevents self-scan false positives where the manifest's own
# pattern definitions are detected as leaks.
get_scan_targets() {
    # From exports: public_target
    grep 'public_target:' "$MANIFEST" | sed 's/.*public_target: *//' | tr -d ' '
    # From retained_public_files: path
    sed -n '/^retained_public_files:/,$ p' "$MANIFEST" | grep '^[[:space:]]*- path:' | sed 's/.*path: *//' | tr -d ' '
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
    echo "== Templates (exist and are clean) =="
    for tmpl in .opencode/templates/brain-config.public.json .opencode/templates/model-registry.public.yaml .opencode/templates/opencode.public.json; do
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

    # 1. Canonical privacy scan — delegates to public-surface-scan.sh
    echo "== Canonical Privacy Scan (public-surface-scan.sh) =="
    if [ -f "$ROOT_DIR/scripts/public-surface-scan.sh" ]; then
        if bash "$ROOT_DIR/scripts/public-surface-scan.sh" 2>&1; then
            pass "Canonical privacy scan: PASS"
        else
            fail "Canonical privacy scan: FAIL — see output above"
        fi
    else
        fail "scripts/public-surface-scan.sh not found — cannot run canonical privacy scan"
    fi

    # 2. Supplementary forbidden pattern scan — TARGET-SCOPED only
    # Scans only declared public targets, not policy files or manifests.
    # This prevents self-scan false positives where the manifest's own
    # pattern definitions are detected as leaks.
    echo ""
    echo "== Supplementary Forbidden Pattern Scan (declared public targets only) =="

    local scan_targets=()
    while IFS= read -r target; do
        [ -n "$target" ] && scan_targets+=("$target")
    done < <(get_scan_targets)

    pass "Scan targets: ${#scan_targets[@]} declared public files"

    for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
        local found=0
        local found_in=""
        for target in "${scan_targets[@]}"; do
            local full_path="$ROOT_DIR/$target"
            if [ -f "$full_path" ] && grep -q "$pattern" "$full_path" 2>/dev/null; then
                found=1
                found_in="$found_in $(basename "$full_path")"
            fi
        done
        if [ "$found" -eq 0 ]; then
            pass "No forbidden pattern '$pattern' in public targets"
        else
            fail "Forbidden pattern '$pattern' found in:$found_in"
        fi
    done

    # 3. Required canonical files exist
    echo ""
    echo "== Required Canonical Files =="
    for reqfile in .opencode/brain-config.json .opencode/model-registry.yaml .opencode/opencode.json .opencode/AGENTS.md .opencode/rules.md .opencode/helper-roster.md; do
        if [ -f "$ROOT_DIR/$reqfile" ]; then
            pass "$reqfile: exists"
        else
            fail "$reqfile: missing"
        fi
    done

    # 4. Placeholder model IDs in templated files
    echo ""
    echo "== Placeholder Model IDs (templated files) =="
    for reqfile in .opencode/brain-config.json .opencode/model-registry.yaml .opencode/opencode.json; do
        if [ -f "$ROOT_DIR/$reqfile" ]; then
            if grep -q "YOUR_PROVIDER" "$ROOT_DIR/$reqfile" 2>/dev/null; then
                pass "$(basename "$reqfile"): uses YOUR_PROVIDER placeholders"
            else
                warn "$(basename "$reqfile"): no YOUR_PROVIDER found (may not need placeholders)"
            fi
        fi
    done

    # 5. Drift detection (only for files with templates)
    echo ""
    echo "== Template-to-Target Drift Detection =="
    for pair in \
        ".opencode/templates/brain-config.public.json:.opencode/brain-config.json" \
        ".opencode/templates/model-registry.public.yaml:.opencode/model-registry.yaml" \
        ".opencode/templates/opencode.public.json:.opencode/opencode.json"; do
        local tmpl="${pair%%:*}"
        local target="${pair##*:}"
        if [ -f "$ROOT_DIR/$tmpl" ] && [ -f "$ROOT_DIR/$target" ]; then
            if diff -q "$ROOT_DIR/$tmpl" "$ROOT_DIR/$target" >/dev/null 2>&1; then
                pass "$(basename "$target"): template matches public target (no drift)"
            else
                fail "$(basename "$target"): template-to-target drift detected"
            fi
        fi
    done
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
