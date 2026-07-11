#!/bin/bash
# workspace-status.sh — Multi-repo workspace status report
# Usage: bash scripts/workspace-status.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Multi-Repo Workspace Status"
echo "=========================================="
echo "Generated: $(date -Iseconds)"
echo ""

# Control plane status
echo "== Control Plane =="
echo "  Path: $ROOT_DIR"
echo "  Branch: $(git -C "$ROOT_DIR" branch --show-current)"
echo "  Commit: $(git -C "$ROOT_DIR" rev-parse --short HEAD)"
echo "  Remote: $(git -C "$ROOT_DIR" remote get-url origin 2>/dev/null || echo 'none')"
echo "  Status: $(git -C "$ROOT_DIR" status --short | wc -l | tr -d ' ') uncommitted files"
echo "  Tag: $(git -C "$ROOT_DIR" describe --tags --abbrev=0 2>/dev/null || echo 'none')"
echo ""

# Active repos from WORKSPACE_MAP
echo "== Child Repos =="
for repo in protected-repo-prod demo-project example-dashboard example-platform example-app sample-service; do
  if [ -d "$ROOT_DIR/$repo" ]; then
    branch=$(git -C "$ROOT_DIR/$repo" branch --show-current 2>/dev/null || echo 'unknown')
    commit=$(git -C "$ROOT_DIR/$repo" rev-parse --short HEAD 2>/dev/null || echo 'unknown')
    remote=$(git -C "$ROOT_DIR/$repo" remote get-url origin 2>/dev/null || echo 'none')
    dirty=$(git -C "$ROOT_DIR/$repo" status --short 2>/dev/null | wc -l | tr -d ' ')
    has_memory=$([ -f "$ROOT_DIR/$repo/PROJECT_MEMORY.md" ] && echo 'yes' || echo 'NO')
    has_agents=$([ -f "$ROOT_DIR/$repo/AGENTS.md" ] && echo 'yes' || echo 'NO')
    has_now=$([ -f "$ROOT_DIR/$repo/NOW.md" ] && echo 'yes' || echo 'NO')

    echo "  $repo:"
    echo "    branch: $branch"
    echo "    commit: $commit"
    echo "    remote: $remote"
    echo "    dirty: $dirty files"
    echo "    PROJECT_MEMORY: $has_memory"
    echo "    AGENTS.md: $has_agents"
    echo "    NOW.md: $has_now"

    # Warnings
    warnings=""
    [ "$has_memory" = "NO" ] && warnings="$warnings missing-PROJECT_MEMORY"
    [ "$has_agents" = "NO" ] && warnings="$warnings missing-AGENTS.md"
    [ "$has_now" = "NO" ] && warnings="$warnings missing-NOW.md"
    [ "$dirty" -gt 0 ] 2>/dev/null && warnings="$warnings dirty-$dirty-files"
    [ -n "$warnings" ] && echo "    warnings:$warnings"
    echo ""
  else
    echo "  $repo: NOT CLONED"
    echo ""
  fi
done

# Nested repo warnings
echo "== Nested Repo Warnings =="
nested_repos=$(find "$ROOT_DIR" -maxdepth 2 -name ".git" -type d 2>/dev/null | grep -v "$ROOT_DIR/.git\|node_modules\|/.opencode" | head -10)
if [ -n "$nested_repos" ]; then
  for nr in $nested_repos; do
    repo_dir=$(dirname "$nr")
    repo_name=$(basename "$repo_dir")
    tracked=$(git -C "$ROOT_DIR" ls-files --error-unmatch "$repo_name" 2>/dev/null && echo 'tracked' || echo 'untracked')
    in_gitmodules=$(grep "$repo_name" "$ROOT_DIR/.gitmodules" 2>/dev/null | head -1)
    if [ -n "$in_gitmodules" ]; then
      echo "  $repo_name: $tracked, in .gitmodules: yes"
    else
      echo "  $repo_name: $tracked, in .gitmodules: no"
    fi
  done
else
  echo "  none"
fi
echo ""

# Generated files check
echo "== Generated Files Gitignored =="
for path in .opencode/cache/ .opencode/.session-cache/ .opencode/conformance/results/ .opencode/node_modules/; do
  if git -C "$ROOT_DIR" check-ignore "$path" >/dev/null 2>&1; then
    echo "  ✓ $path gitignored"
  else
    echo "  ✗ $path NOT gitignored"
  fi
done
echo ""

# GitHub Actions
echo "== GitHub Actions =="
if command -v gh >/dev/null 2>&1; then
  gh workflow list 2>/dev/null | sed 's/^/  /' || echo "  unable to list"
else
  echo "  gh CLI not available"
fi
echo ""

# Release tag
echo "== Release Tag =="
echo "  Latest tag: $(git -C "$ROOT_DIR" describe --tags --abbrev=0 2>/dev/null || echo 'none')"
pr_list=$(gh pr list --state open 2>/dev/null | head -3 || echo '  unable to list')
echo "  Open PRs:"
echo "$pr_list"
