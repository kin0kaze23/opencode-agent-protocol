---
name: yt-search
description: YouTube video search via yt-dlp — returns structured JSON metadata including title, URL, channel, view count, duration, and optional subscriber count
---

# yt-search Skill

> **Canary v0.2** — Part of the Research Pipeline.
> Activated by `/research-pipeline` for YouTube source gathering.

---

## Purpose

Search YouTube for video content related to a research topic and return structured metadata. Uses `yt-dlp` for fast flat-playlist search. Output is JSON for downstream consumption by the research pipeline.

---

## When To Activate

Activate when the request involves:
- "search YouTube" or "find videos about"
- "YouTube research" or "video sources"
- Activated automatically by `/research-pipeline` for YouTube source gathering

---

## How To Use

### Direct invocation (for standalone testing):

```bash
bash .opencode/scripts/yt-search.sh "your search query" [--limit N] [--months M] [--detailed]
```

### Via research pipeline (recommended):

```
/research-pipeline your topic
```

The pipeline calls this skill automatically. No manual invocation needed.

---

## Output Format

The script outputs a JSON array to stdout. Each entry:

```json
{
  "title": "Video Title",
  "url": "https://youtube.com/watch?v=...",
  "channel": "Channel Name",
  "channel_id": "UC_...",
  "view_count": 48741,
  "duration": 135.0,
  "duration_string": "2:15",
  "upload_date": "20260101",
  "channel_follower_count": null,
  "engagement_ratio": null
}
```

**Notes:**
- `channel_follower_count` is `null` by default (flat search). Use `--detailed` to fetch per-video, which is slower.
- `engagement_ratio` = `view_count / channel_follower_count` (only when both are available).
- All fields use `null` when unavailable — never fabricates data.

---

## Dependencies

- **yt-dlp** — required. Install: `brew install yt-dlp`
- **python3** — required for JSON processing (system Python is fine)

---

## Out of Scope

- No video downloading (search only)
- No authentication, cookies, or private YouTube API access
- No comments, likes, or engagement beyond views
- No transcript extraction
- No channel-level analytics or historical data

---

## Integration

This skill is called by the research pipeline command (`/research-pipeline`).
It may also be invoked directly by the Owner for ad-hoc YouTube lookups.

### Wiring

| Invocation | Source |
|---|---|
| `/research-pipeline` (automatic) | `.opencode/commands/research-pipeline.md` |
| Manual / ad-hoc | Owner via `bash .opencode/scripts/yt-search.sh` |
