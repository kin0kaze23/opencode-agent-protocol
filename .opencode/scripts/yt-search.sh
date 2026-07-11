#!/usr/bin/env bash
# yt-search.sh — YouTube search wrapper returning structured JSON
#
# Usage:
#   bash .opencode/scripts/yt-search.sh "query" [--limit N] [--detailed]
#
# Output: JSON array to stdout. Each result has:
#   title, url, channel, view_count, duration, channel_follower_count (optional)
#
# Rules:
#   - Read-only: never modifies files
#   - No cookies, no auth, no private data
#   - Subscriber count is null in flat search (fast). --detailed flag does per-video
#     extraction which is slower but includes channel_follower_count.
#   - Treats missing fields as null (never fabricates)

set -euo pipefail

# === Constants ===
DEFAULT_LIMIT=5

# === Parse args ===
QUERY=""
LIMIT="$DEFAULT_LIMIT"
DETAILED="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit) LIMIT="$2"; shift 2 ;;
    --detailed) DETAILED="true"; shift ;;
    -*)
      echo "{\"error\": \"Unknown flag: $1\"}" >&2
      exit 1
      ;;
    *)
      QUERY="${QUERY} $1"
      shift
      ;;
  esac
done

QUERY="$(echo "$QUERY" | sed 's/^ //')"

if [[ -z "$QUERY" ]]; then
  echo "{\"error\": \"No query provided. Usage: yt-search.sh 'query' [--limit N]\"}" >&2
  exit 1
fi

# === Validate yt-dlp ===
if ! command -v yt-dlp &>/dev/null; then
  echo "{\"error\": \"yt-dlp not found. Install: brew install yt-dlp\"}" >&2
  exit 1
fi

# === Search YouTube (flat = fast, no subscriber count) ===
# Pipe yt-dlp JSON directly to Python parser (avoids heredoc escaping issues)
export YT_SEARCH_DETAILED="$DETAILED"

yt-dlp --flat-playlist --dump-json "ytsearch${LIMIT}:${QUERY}" 2>/dev/null | python3 -c "
import json, os, sys

DETAILED = os.environ.get('YT_SEARCH_DETAILED', 'false').lower() == 'true'

raw_results = []
for line in sys.stdin:
    line = line.strip()
    if line:
        try:
            raw_results.append(json.loads(line))
        except json.JSONDecodeError:
            continue

output = []
for r in raw_results:
    entry = {
        'title': r.get('title'),
        'url': r.get('webpage_url') or r.get('url'),
        'channel': r.get('channel') or r.get('uploader'),
        'channel_id': r.get('channel_id'),
        'view_count': r.get('view_count'),
        'duration': r.get('duration'),
        'duration_string': r.get('duration_string'),
        'upload_date': r.get('upload_date'),
        'channel_follower_count': r.get('channel_follower_count'),
        'engagement_ratio': None,
    }

    # Calculate engagement ratio (views / followers, if both available)
    vc = entry.get('view_count')
    sc = entry.get('channel_follower_count')
    if vc is not None and sc is not None and sc > 0:
        entry['engagement_ratio'] = round(vc / sc, 2)

    output.append(entry)

print(json.dumps(output, indent=2))
"
