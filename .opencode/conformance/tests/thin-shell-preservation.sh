#!/bin/bash
# Thin-Shell Preservation Test
# Verifies that sync-opencode-runtime.sh preserves global config as thin shell
# C5 seal: global config must contain only $schema and plugin fields

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
SYNC_SCRIPT="$ROOT_DIR/.opencode/scripts/sync-opencode-runtime.sh"
GLOBAL_CFG="$HOME/.config/opencode/opencode.json"

echo "=========================================="
echo "Thin-Shell Preservation Test"
echo "=========================================="
echo ""

# Check prerequisites
if [ ! -f "$SYNC_SCRIPT" ]; then
  echo "ERROR: Sync script not found at $SYNC_SCRIPT"
  exit 1
fi

if [ ! -f "$GLOBAL_CFG" ]; then
  echo "ERROR: Global config not found at $GLOBAL_CFG"
  exit 1
fi

# Step 1: Verify global config is thin shell before sync
echo "Step 1: Checking global config state BEFORE sync..."
BEFORE_KEYS=$(python3 -c "import json; d=json.load(open('$GLOBAL_CFG')); print(','.join(sorted(d.keys())))")
echo "  Keys before sync: $BEFORE_KEYS"

if [ "$BEFORE_KEYS" != "\$schema,plugin" ]; then
  echo "  WARNING: Global config is not thin shell before sync"
  echo "  Expected: \$schema,plugin"
  echo "  Got: $BEFORE_KEYS"
  echo ""
  echo "  Restoring to thin shell..."
  python3 -c "
import json
d = json.load(open('$GLOBAL_CFG'))
thin = {'\$schema': d.get('\$schema', 'https://opencode.ai/config.json'), 'plugin': d.get('plugin', [])}
with open('$GLOBAL_CFG', 'w') as f:
  json.dump(thin, f, indent=2)
  f.write('\n')
"
  echo "  Restored to thin shell"
fi

# Step 2: Run sync script
echo ""
echo "Step 2: Running sync script..."
bash "$SYNC_SCRIPT" > /tmp/sync-output.txt 2>&1
SYNC_EXIT=$?

if [ $SYNC_EXIT -ne 0 ]; then
  echo "  ERROR: Sync script failed with exit code $SYNC_EXIT"
  echo "  Output:"
  cat /tmp/sync-output.txt
  exit 1
fi

echo "  Sync completed successfully"

# Step 3: Verify global config is still thin shell after sync
echo ""
echo "Step 3: Checking global config state AFTER sync..."
AFTER_KEYS=$(python3 -c "import json; d=json.load(open('$GLOBAL_CFG')); print(','.join(sorted(d.keys())))")
echo "  Keys after sync: $AFTER_KEYS"

# Step 4: Verify no authority fields present
echo ""
echo "Step 4: Verifying no authority fields present..."
FORBIDDEN_FIELDS="model small_model agent mcp provider"
VIOLATIONS=0

for field in $FORBIDDEN_FIELDS; do
  if python3 -c "import json; d=json.load(open('$GLOBAL_CFG')); exit(0 if '$field' in d else 1)" 2>/dev/null; then
    echo "  VIOLATION: Found forbidden field '$field' in global config"
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
done

# Step 5: Verify no model references present
echo ""
echo "Step 5: Verifying no model references present..."
if grep -q "qwen3.6-plus\|qwen3.7-plus" "$GLOBAL_CFG" 2>/dev/null; then
  echo "  VIOLATION: Found model references in global config"
  VIOLATIONS=$((VIOLATIONS + 1))
fi

# Step 6: Verify thin shell structure
echo ""
echo "Step 6: Verifying thin shell structure..."
if [ "$AFTER_KEYS" != "\$schema,plugin" ]; then
  echo "  VIOLATION: Global config is not thin shell after sync"
  echo "  Expected: \$schema,plugin"
  echo "  Got: $AFTER_KEYS"
  VIOLATIONS=$((VIOLATIONS + 1))
fi

# Final result
echo ""
echo "=========================================="
if [ $VIOLATIONS -eq 0 ]; then
  echo "RESULT: PASS"
  echo "  Global config preserved as thin shell"
  echo "  No authority drift detected"
  echo "=========================================="
  exit 0
else
  echo "RESULT: FAIL"
  echo "  Found $VIOLATIONS violation(s)"
  echo "  Global config authority drift detected"
  echo "=========================================="
  exit 1
fi
