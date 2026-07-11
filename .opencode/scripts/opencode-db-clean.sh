#!/bin/bash
# OpenCode DB Cleaner — Aggressive cleanup
# Run ONLY when all opencode sessions are closed
# Usage: bash .opencode/scripts/opencode-db-clean.sh [--keep N] [--no-backup]
# Canonical location: .opencode/scripts/opencode-db-clean.sh

DB="$HOME/.local/share/opencode/opencode.db"
KEEP_SESSIONS="${1:-3}"  # Default: keep 3 most recent sessions
MAX_DB_SIZE_MB=500       # Warn if DB exceeds this after cleanup

echo "=== OpenCode DB Cleaner ==="
echo "DB size before: $(du -sh $DB | cut -f1)"
echo ""

# Step 0: Delete old backup files (these accumulate and waste disk)
echo "→ Cleaning old backup files..."
BACKUP_SIZE=$(du -sh ~/.local/share/opencode/opencode.db.backup-* 2>/dev/null | awk '{sum += $1} END {print sum}')
BACKUP_COUNT=$(ls ~/.local/share/opencode/opencode.db.backup-* 2>/dev/null | wc -l | tr -d ' ')
if [ "$BACKUP_COUNT" -gt 0 ]; then
    echo "  Found $BACKUP_COUNT backup files ($BACKUP_SIZE total)"
    rm -v ~/.local/share/opencode/opencode.db.backup-*
    echo "  ✅ Backups deleted"
else
    echo "  ✅ No backup files found"
fi
echo ""

# Step 1: Checkpoint WAL into main DB
echo "→ Checkpointing WAL..."
sqlite3 "$DB" "PRAGMA wal_checkpoint(TRUNCATE);"

# Step 2: Show current state
SESSIONS_BEFORE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM session;")
PARTS_BEFORE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM part;")
echo "  Sessions: $SESSIONS_BEFORE, Parts: $PARTS_BEFORE"

# Step 3: Delete ALL parts from sessions older than KEEP_SESSIONS most recent
echo "→ Deleting all parts from sessions older than $KEEP_SESSIONS most recent..."
sqlite3 "$DB" "
DELETE FROM part
WHERE session_id NOT IN (
  SELECT id FROM session ORDER BY time_updated DESC LIMIT $KEEP_SESSIONS
);
"

# Step 4: Delete old sessions themselves
echo "→ Deleting old sessions..."
sqlite3 "$DB" "
DELETE FROM session
WHERE id NOT IN (
  SELECT id FROM session ORDER BY time_updated DESC LIMIT $KEEP_SESSIONS
);
"

# Step 5: Delete orphaned parts
echo "→ Removing orphaned parts..."
sqlite3 "$DB" "
DELETE FROM part WHERE session_id NOT IN (SELECT id FROM session);
"

# Step 6: VACUUM to reclaim disk space
echo "→ Running VACUUM (this may take a moment)..."
sqlite3 "$DB" "VACUUM;"

# Summary
SESSIONS_AFTER=$(sqlite3 "$DB" "SELECT COUNT(*) FROM session;")
PARTS_AFTER=$(sqlite3 "$DB" "SELECT COUNT(*) FROM part;")
DB_SIZE=$(du -sh $DB | cut -f1)

echo ""
echo "=== Done ==="
echo "Sessions: $SESSIONS_BEFORE → $SESSIONS_AFTER"
echo "Parts: $PARTS_BEFORE → $PARTS_AFTER"
echo "DB size: $DB_SIZE"

# Warn if DB is still large
DB_SIZE_MB=$(du -m $DB | cut -f1)
if [ "$DB_SIZE_MB" -gt "$MAX_DB_SIZE_MB" ]; then
    echo ""
    echo "⚠️  DB is still ${DB_SIZE_MB}MB (threshold: ${MAX_DB_SIZE_MB}MB)"
    echo "   Consider reducing KEEP_SESSIONS or running again."
fi

echo ""
echo "Tip: Run this weekly or when DB exceeds 500MB"
echo "  bash .opencode/scripts/opencode-db-clean.sh"
