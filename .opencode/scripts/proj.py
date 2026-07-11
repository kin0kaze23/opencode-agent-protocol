#!/usr/bin/env python3
"""proj — multi-repo status CLI for PersonalProjects workspace.

Reads .opencode/registry.yaml to discover repos, then reads each repo's
NOW.md to report status, task, lane, blockers, and last update.

Subcommands:
  status  — table view of all repos on disk
  digest  — one-line summary for quick scanning
"""

import os
import re
import sys
import json

WORKSPACE = os.path.expanduser("~/Developer/PersonalProjects")
REGISTRY = os.path.join(WORKSPACE, ".opencode", "registry.yaml")

# Minimal YAML parser — only needs the repos section (no nested dicts beyond 2 levels)
def parse_registry(path):
    repos = []
    in_repos = False
    current = None
    with open(path) as f:
        for line in f:
            stripped = line.rstrip()
            if stripped == "repositories:":
                in_repos = True
                continue
            if in_repos and stripped and not stripped.startswith(" ") and not stripped.startswith("#"):
                in_repos = False
                continue
            if not in_repos:
                continue
            # Repo key (2-space indent, ends with colon)
            m = re.match(r"^  (\w[\w_-]*):$", stripped)
            if m:
                current = {"key": m.group(1)}
                repos.append(current)
                continue
            if current is None:
                continue
            # Key-value pairs (4-space indent)
            m = re.match(r"^    (\w[\w_-]*):\s*(.*)$", stripped)
            if m:
                key, val = m.group(1), m.group(2).strip().strip('"')
                if key == "note":
                    current[key] = val
                else:
                    current[key] = val
    return repos


def parse_now_md(path):
    """Parse NOW.md in any of the 3 known formats.

    Format A: YAML frontmatter (--- delimited)
    Format B: Markdown headers (# Current State — X / **Status:** ...)
    Format C: Bare key: value lines before --- (example-orchestrator-PROD style)
    """
    if not os.path.isfile(path):
        return None

    with open(path) as f:
        content = f.read()

    result = {"status": "unknown", "task": "", "lane": "", "blockers": [], "updated": ""}

    # Format C: Bare key: value lines (no --- at start, but key: value before first ---)
    if not content.startswith("---"):
        # Check if it has bare key: value lines at the top
        first_lines = content.splitlines()[:10]
        has_bare_keys = any(
            re.match(r"^(status|task|lane|objective|blockers|updated)\s*:", line)
            for line in first_lines
        )
        if has_bare_keys:
            for line in first_lines:
                line = line.strip()
                m = re.match(r"^(\w[\w_-]*)\s*:\s*(.+)$", line)
                if m:
                    key, val = m.group(1), m.group(2).strip()
                    if key in result:
                        if key == "blockers":
                            result["blockers"] = [val] if val.lower() != "none" else []
                        else:
                            result[key] = val
            return result

    # Format A: YAML frontmatter
    if content.startswith("---"):
        end = content.find("---", 3)
        if end == -1:
            return result
        frontmatter = content[3:end]
        for line in frontmatter.splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if ":" in line:
                key, _, val = line.partition(":")
                key = key.strip()
                val = val.strip()
                if key in result:
                    if key == "blockers":
                        if val.startswith("["):
                            try:
                                result["blockers"] = json.loads(val)
                            except json.JSONDecodeError:
                                result["blockers"] = [val.strip("[]").strip('"')]
                        else:
                            result["blockers"] = [val] if val else []
                    else:
                        result[key] = val
        return result

    # Format B: Markdown headers
    status_match = re.search(r"\*\*Status:\*\*\s*(.+)$", content, re.MULTILINE)
    if status_match:
        result["status"] = status_match.group(1).strip().rstrip("`").strip()
    task_match = re.search(r"(?:task|objective)[:\s]+(.+)$", content, re.MULTILINE | re.IGNORECASE)
    if task_match:
        result["task"] = task_match.group(1).strip()
    lane_match = re.search(r"(?:lane)[:\s]+(\w+)", content, re.MULTILINE | re.IGNORECASE)
    if lane_match:
        result["lane"] = lane_match.group(1).strip()
    return result


def cmd_status(repos):
    """Print a status table of all repos on disk."""
    header = f"{'Repo':<25} {'Status':<12} {'Lane':<10} {'Updated':<12} {'Task'}"
    print(header)
    print("─" * 100)

    active_count = 0
    blocked_count = 0
    idle_count = 0

    for repo in repos:
        disk_status = repo.get("disk_status", "")
        if disk_status != "present":
            continue

        repo_path = os.path.join(WORKSPACE, repo.get("path", ""))
        now_path = os.path.join(repo_path, "NOW.md")
        info = parse_now_md(now_path)

        name = repo.get("name", repo.get("key", "?"))
        if info is None:
            status = "no NOW.md"
            lane = "—"
            updated = "—"
            task = "—"
        else:
            status = info["status"]
            lane = info.get("lane", "") or "—"
            updated = info.get("updated", "") or "—"
            task = info.get("task", "") or "—"

        if info:
            if info["blockers"]:
                blocked_count += 1
            elif status == "active":
                active_count += 1
            else:
                idle_count += 1
        else:
            idle_count += 1

        status_display = status[:12]
        task_display = task[:60] + ("…" if len(task) > 60 else "")
        print(f"{name:<25} {status_display:<12} {lane:<10} {updated:<12} {task_display}")

    print("─" * 100)
    total = active_count + blocked_count + idle_count
    print(f"  {total} on disk: {active_count} active, {blocked_count} blocked, {idle_count} idle/paused")
    missing = sum(1 for r in repos if r.get("disk_status") != "present")
    if missing:
        print(f"  {missing} missing from disk (registered but not on this machine)")


def cmd_digest(repos):
    """Print a one-line digest summary."""
    statuses = {"active": 0, "paused": 0, "blocked": 0, "unknown": 0, "no_now_md": 0}

    for repo in repos:
        if repo.get("disk_status") != "present":
            continue
        repo_path = os.path.join(WORKSPACE, repo.get("path", ""))
        now_path = os.path.join(repo_path, "NOW.md")
        info = parse_now_md(now_path)

        if info is None:
            statuses["no_now_md"] += 1
        else:
            status = info["status"]
            if info["blockers"]:
                statuses["blocked"] += 1
            elif status in statuses:
                statuses[status] += 1
            else:
                statuses["unknown"] += 1

    total = sum(statuses.values())
    parts = [f"{total} repos on disk"]
    if statuses["active"]:
        parts.append(f"{statuses['active']} active")
    if statuses["blocked"]:
        parts.append(f"{statuses['blocked']} blocked")
    if statuses["paused"]:
        parts.append(f"{statuses['paused']} paused")
    if statuses["no_now_md"]:
        parts.append(f"{statuses['no_now_md']} no NOW.md")

    print(", ".join(parts))


def main():
    if len(sys.argv) < 2:
        print("Usage: proj <status|digest>")
        print("  status  — table view of all repos on disk")
        print("  digest  — one-line summary for quick scanning")
        sys.exit(1)

    command = sys.argv[1]
    if command not in ("status", "digest"):
        print(f"Unknown command: {command}")
        print("Available: status, digest")
        sys.exit(1)

    if not os.path.isfile(REGISTRY):
        print(f"Error: registry not found at {REGISTRY}")
        sys.exit(1)

    repos = parse_registry(REGISTRY)
    if command == "status":
        cmd_status(repos)
    elif command == "digest":
        cmd_digest(repos)


if __name__ == "__main__":
    main()
