#!/bin/bash
# validate-public-sync.sh — Public drift detection for OpenCode Agent Protocol
# Usage: bash scripts/validate-public-sync.sh
#
# Checks that public-facing control files are sanitized and version-aligned.
# Run before every public release.

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
WARN=0

pass() { printf '  \033[0;32m✓\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }
warn() { printf '  \033[0;33m⚠\033[0m %s\n' "$1"; WARN=$((WARN + 1)); }

echo "=========================================="
echo "Public Sync Validation"
echo "=========================================="

# ── 1. Version consistency ────────────────────────────────────────────────────
echo ""
echo "== Version Consistency =="

VERSION_FILES=(
    "$ROOT_DIR/.opencode/AGENTS.md"
    "$ROOT_DIR/.opencode/rules.md"
    "$ROOT_DIR/NOW.md"
    "$ROOT_DIR/README.md"
    "$ROOT_DIR/docs/protocol/PROTOCOL_ATLAS.md"
)

EXPECTED_VERSION=""
for f in "${VERSION_FILES[@]}"; do
    if [ ! -f "$f" ]; then
        fail "$(basename "$f"): file not found"
        continue
    fi
    VERSION=$(grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' "$f" | head -1)
    if [ -z "$VERSION" ]; then
        warn "$(basename "$f"): no version found"
        continue
    fi
    if [ -z "$EXPECTED_VERSION" ]; then
        EXPECTED_VERSION="$VERSION"
        pass "$(basename "$f"): $VERSION"
    elif [ "$VERSION" = "$EXPECTED_VERSION" ]; then
        pass "$(basename "$f"): $VERSION"
    else
        fail "$(basename "$f"): $VERSION (expected $EXPECTED_VERSION)"
    fi
done

# ── 2. Forbidden author-specific strings ─────────────────────────────────────
echo ""
echo "== Forbidden Author-Specific Strings =="

FORBIDDEN_PATTERNS=(
    'umans-ai-coding-plan/'
    'opencode-go/'
    'nuggie-be'
    'Doppler'
    'Alibaba'
    'Bailian'
    'example-agent'
)

CHECK_FILES=(
    "$ROOT_DIR/.opencode/AGENTS.md"
    "$ROOT_DIR/.opencode/rules.md"
    "$ROOT_DIR/.opencode/helper-roster.md"
    "$ROOT_DIR/.opencode/opencode.json"
)

for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    FOUND=0
    for f in "${CHECK_FILES[@]}"; do
        if [ ! -f "$f" ]; then continue; fi
        if grep -q "$pattern" "$f" 2>/dev/null; then
            fail "Forbidden pattern '$pattern' found in $(basename "$f")"
            FOUND=1
        fi
    done
    if [ "$FOUND" -eq 0 ]; then
        pass "No forbidden pattern '$pattern' in control files"
    fi
done

# ── 3. Agent definitions check ────────────────────────────────────────────────
echo ""
echo "== Agent Definitions =="

AGENT_FILES=(
    "$ROOT_DIR/.opencode/agents/visual-reviewer.md"
    "$ROOT_DIR/.opencode/agents/visual-reviewer-fallback.md"
    "$ROOT_DIR/.opencode/global-runtime/prompts/visual-reviewer.md"
    "$ROOT_DIR/.opencode/global-runtime/prompts/visual-reviewer-fallback.md"
)

for f in "${AGENT_FILES[@]}"; do
    if [ ! -f "$f" ]; then
        fail "$(basename "$f"): file not found"
        continue
    fi
    if grep -q "READY TO SHIP" "$f" 2>/dev/null; then
        fail "$(basename "$f"): still has 'READY TO SHIP' verdict"
    else
        pass "$(basename "$f"): uses TECHNICAL_VISUAL_PASS/FAIL"
    fi
    if grep -q "TECHNICAL_VISUAL_PASS" "$f" 2>/dev/null; then
        pass "$(basename "$f"): has TECHNICAL_VISUAL_PASS verdict"
    else
        warn "$(basename "$f"): missing TECHNICAL_VISUAL_PASS"
    fi
done

# ── 4. Stale v4 banners ───────────────────────────────────────────────────────
echo ""
echo "== Stale v4 Banners =="

for f in "${VERSION_FILES[@]}"; do
    if [ ! -f "$f" ]; then continue; fi
    if grep -q "v4\.[0-9]" "$f" 2>/dev/null; then
        # Check if it's a historical reference (not a current version banner)
        if grep -q "Protocol: OpenCode v4\." "$f" 2>/dev/null; then
            fail "$(basename "$f"): has stale v4 session banner"
        else
            pass "$(basename "$f"): v4 references are historical"
        fi
    else
        pass "$(basename "$f"): no stale v4 banners"
    fi
done

# ── 5. Placeholder model IDs ─────────────────────────────────────────────────
echo ""
echo "== Placeholder Model IDs =="

if grep -q "YOUR_PROVIDER" "$ROOT_DIR/.opencode/opencode.json" 2>/dev/null; then
    pass "opencode.json uses YOUR_PROVIDER placeholders"
else
    warn "opencode.json may have real model IDs (no YOUR_PROVIDER found)"
fi

if grep -q "YOUR_PROVIDER" "$ROOT_DIR/.opencode/AGENTS.md" 2>/dev/null; then
    pass "AGENTS.md uses YOUR_PROVIDER placeholders"
else
    warn "AGENTS.md may have real model IDs"
fi

if grep -q "YOUR_PROVIDER" "$ROOT_DIR/.opencode/rules.md" 2>/dev/null; then
    pass "rules.md uses YOUR_PROVIDER placeholders"
else
    warn "rules.md may have real model IDs"
fi

if grep -q "YOUR_PROVIDER" "$ROOT_DIR/.opencode/helper-roster.md" 2>/dev/null; then
    pass "helper-roster.md uses YOUR_PROVIDER placeholders"
else
    warn "helper-roster.md may have real model IDs"
fi

# ── 6. Vault/evals references ─────────────────────────────────────────────────
echo ""
echo "== Vault/Evals References =="

for f in "${CHECK_FILES[@]}"; do
    if [ ! -f "$f" ]; then continue; fi
    if grep -q "vault/evals/" "$f" 2>/dev/null; then
        fail "$(basename "$f"): has vault/evals/ reference"
    else
        pass "$(basename "$f"): no vault/evals/ references"
    fi
done

# ── 7. Prompt mirrors exist ───────────────────────────────────────────────────
echo ""
echo "== Prompt Mirrors =="

PROMPT_AGENTS="orchestrator explorer planner implementer reviewer architect budget visual-reviewer visual-reviewer-fallback"
for agent in $PROMPT_AGENTS; do
    if [ -f "$ROOT_DIR/.opencode/global-runtime/prompts/$agent.md" ]; then
        pass "Prompt mirror: $agent.md exists"
    else
        fail "Prompt mirror: $agent.md missing"
    fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
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
