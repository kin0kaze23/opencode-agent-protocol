#!/usr/bin/env bash
# Visual Reviewer Non-Empty Output Canary
# Ensures the delegated visual-reviewer agent returns a structured, non-empty
# visual review when given a screenshot. Empty output is treated as a failure.
#
# Trigger: wired into workspace-protocol-guard.sh
# Added: v4.15.2 after primary visual-reviewer (opencode-go/minimax-m3) returned
#        "Insufficient balance" and the task tool surfaced it as empty output.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
OPENCODE_JSON="$ROOT_DIR/.opencode/opencode.json"
TMP_DIR="${TMPDIR:-/tmp}/opencode-vr-canary-$$"
PASS=0
FAIL=0

pass() { printf '[PASS] %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$TMP_DIR"

printf '==========================================\n'
printf 'Visual Reviewer Non-Empty Output Canary\n'
printf '==========================================\n'
printf 'Root: %s\n' "$ROOT_DIR"
printf 'Temp: %s\n\n' "$TMP_DIR"

# --- 1. Model routing sanity ---
# The v4.15.2 hotfix routes visual-reviewer away from OpenCode Go minimax-m3
# because that model returned Insufficient balance during the protected-repo canary.
# v4.16 routes visual-reviewer-fallback to opencode-go/kimi-k2.6 for provider+model diversity.
primary_model="$(jq -r '.agent["visual-reviewer"].model // empty' "$OPENCODE_JSON")"
if [[ "$primary_model" == "opencode-go/minimax-m3" ]]; then
  fail "visual-reviewer is still routed to opencode-go/minimax-m3 (quota-unavailable model)"
else
  pass "visual-reviewer is routed to a non-OpenCode-Go model: $primary_model"
fi

# --- 2. Fallback diversity check ---
# v4.16 requires visual-reviewer-fallback to be a different provider or model than primary.
fallback_model="$(jq -r '.agent["visual-reviewer-fallback"].model // empty' "$OPENCODE_JSON")"
if [[ -z "$fallback_model" ]]; then
  fail "visual-reviewer-fallback model is not configured"
elif [[ "$fallback_model" == "$primary_model" ]]; then
  fail "visual-reviewer-fallback uses the same model as primary ($fallback_model == $primary_model) — no diversity"
else
  pass "visual-reviewer-fallback is routed to a different model: $fallback_model (diversity from primary: $primary_model)"
fi

# --- 3. Runtime availability ---
if ! command -v opencode >/dev/null 2>&1; then
  fail "opencode CLI not found in PATH"
  printf 'Summary: %d passed, %d failed\n' "$PASS" "$FAIL"
  exit 1
fi
pass "opencode CLI available"

# --- 4. Generate a synthetic screenshot fixture ---
# We generate the fixture on demand so fresh clones do not need to carry binary
# screenshot files and pre-commit large-file checks stay green.
if ! command -v npx >/dev/null 2>&1; then
  fail "npx not found; cannot generate screenshot fixture"
  printf 'Summary: %d passed, %d failed\n' "$PASS" "$FAIL"
  exit 1
fi

cat > "$TMP_DIR/fixture.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Visual Reviewer Fixture</title>
<style>
  body { margin: 0; padding: 20px; font-family: system-ui, sans-serif; background: #f0f7ff; }
  .card { max-width: 320px; margin: 40px auto; padding: 24px; background: #fff; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
  h1 { font-size: 20px; margin: 0 0 12px; color: #0f172a; }
  p { color: #334155; line-height: 1.5; }
  button { width: 100%; padding: 12px; margin-top: 16px; background: #2563eb; color: #fff; border: none; border-radius: 8px; font-weight: 600; cursor: pointer; }
</style>
</head>
<body>
  <main class="card">
    <h1>Visual Reviewer Fixture</h1>
    <p>This synthetic UI fixture verifies non-empty, structured visual-reviewer output.</p>
    <button>Primary Action</button>
  </main>
</body>
</html>
EOF

if ! npx playwright screenshot --viewport-size=390,844 "file://$TMP_DIR/fixture.html" "$TMP_DIR/fixture.png" >/dev/null 2>&1; then
  fail "playwright screenshot command failed"
  printf 'Summary: %d passed, %d failed\n' "$PASS" "$FAIL"
  exit 1
fi

fixture_size="$(stat -f%z "$TMP_DIR/fixture.png" 2>/dev/null || stat -c%s "$TMP_DIR/fixture.png" 2>/dev/null || echo 0)"
if [[ "$fixture_size" -lt 1024 ]]; then
  fail "generated fixture screenshot is too small (${fixture_size} bytes)"
  printf 'Summary: %d passed, %d failed\n' "$PASS" "$FAIL"
  exit 1
fi
pass "generated synthetic screenshot fixture (${fixture_size} bytes)"

# --- 5. Run visual-reviewer and capture output ---
output_file="$TMP_DIR/visual-reviewer-output.txt"
set +e
opencode run \
  --agent visual-reviewer \
  --file "$TMP_DIR/fixture.png" \
  --title 'VisualReviewerNonEmptyCanary' \
  'Analyze this UI screenshot and return the structured visual review format.' \
  >"$output_file" 2>&1
run_exit=$?
set -e

if [[ "$run_exit" -ne 0 ]]; then
  fail "opencode run --agent visual-reviewer exited with code $run_exit"
  printf '--- captured output ---\n'
  tail -n 40 "$output_file" || true
  printf '--- end output ---\n'
  printf 'Summary: %d passed, %d failed\n' "$PASS" "$FAIL"
  exit 1
fi
pass "opencode run --agent visual-reviewer completed"

# --- 6. Non-empty structured output validation ---
output_len="$(wc -c <"$output_file")"
if [[ "$output_len" -lt 50 ]]; then
  fail "visual-reviewer output is empty or near-empty (${output_len} bytes)"
  printf '--- captured output ---\n'
  cat "$output_file" || true
  printf '--- end output ---\n'
  printf 'Summary: %d passed, %d failed\n' "$PASS" "$FAIL"
  exit 1
fi
pass "visual-reviewer output is non-empty (${output_len} bytes)"

required_patterns=("VISUAL REVIEW" "Verdict:" "Checklist results:" "Issues found:")
missing=0
for pattern in "${required_patterns[@]}"; do
  if grep -q "$pattern" "$output_file"; then
    pass "output contains required section: '$pattern'"
  else
    fail "output missing required section: '$pattern'"
    missing=$((missing + 1))
  fi
done

if [[ "$missing" -gt 0 ]]; then
  printf '--- captured output ---\n'
  tail -n 60 "$output_file" || true
  printf '--- end output ---\n'
  printf 'Summary: %d passed, %d failed\n' "$PASS" "$FAIL"
  exit 1
fi

printf '\n==========================================\n'
printf 'PASSED: %d\n' "$PASS"
printf 'FAILED: %d\n' "$FAIL"
printf '==========================================\n'

exit 0
