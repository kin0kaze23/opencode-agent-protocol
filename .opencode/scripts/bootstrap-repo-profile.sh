#!/usr/bin/env bash
# bootstrap-repo-profile.sh — v4.17.2
# Purpose: Detect repo type and assign profile from repo-profiles.yaml
# Used by: /bootstrap-repo command
#
# Usage:
#   bash .opencode/scripts/bootstrap-repo-profile.sh <repo_path>
#
# Output: machine-readable lines for agent consumption
#   REPO_TYPE: <type>
#   REPO_PROFILE: <profile_name>
#   PACKAGE_MANAGER: <pnpm|npm|cargo|pip|none>
#   DEFAULT_LANE: <DIRECT|FAST|STANDARD|HIGH-RISK>
#   VERIFICATION_PROFILE: <profile>
#   GATE_LINT: <command>
#   GATE_TYPECHECK: <command>
#   GATE_TEST: <command>
#   GATE_BUILD: <command>
#   DEPLOY_TARGETS: <list>
#   BROWSER_VERIFICATION: <true|false>

set -euo pipefail

REPO_PATH="${1:-}"
if [[ -z "$REPO_PATH" ]]; then
  echo "Usage: bootstrap-repo-profile.sh <repo_path>" >&2
  exit 1
fi

if [[ ! -d "$REPO_PATH" ]]; then
  echo "ERROR: directory not found: $REPO_PATH" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROFILES_FILE="$ROOT_DIR/.opencode/config/repo-profiles.yaml"

if [[ ! -f "$PROFILES_FILE" ]]; then
  echo "ERROR: repo-profiles.yaml not found at $PROFILES_FILE" >&2
  exit 1
fi

# --- Repo type detection ---
detect_repo_type() {
  local dir="$1"

  # Check for protocol repo (workspace .opencode itself)
  if [[ -f "$dir/.opencode/AGENTS.md" && -f "$dir/.opencode/rules.md" ]]; then
    echo "protocol_repo"
    return 0
  fi

  # Check for Rust
  if [[ -f "$dir/Cargo.toml" ]]; then
    echo "rust"
    return 0
  fi

  # Check for Python
  if [[ -f "$dir/requirements.txt" || -f "$dir/pyproject.toml" || -f "$dir/setup.py" ]]; then
    echo "python"
    return 0
  fi

  # Check for Node.js / JS / TS
  if [[ -f "$dir/package.json" ]]; then
    local has_vite has_next has_express has_hono has_fastify
    has_vite=$(python3 -c "import json; d=json.load(open('$dir/package.json')); deps={**d.get('dependencies',{}),**d.get('devDependencies',{})}; print('yes' if 'vite' in deps else 'no')" 2>/dev/null || echo "no")
    has_next=$(python3 -c "import json; d=json.load(open('$dir/package.json')); deps={**d.get('dependencies',{}),**d.get('devDependencies',{})}; print('yes' if 'next' in deps else 'no')" 2>/dev/null || echo "no")
    has_express=$(python3 -c "import json; d=json.load(open('$dir/package.json')); deps={**d.get('dependencies',{}),**d.get('devDependencies',{})}; print('yes' if 'express' in deps else 'no')" 2>/dev/null || echo "no")
    has_hono=$(python3 -c "import json; d=json.load(open('$dir/package.json')); deps={**d.get('dependencies',{}),**d.get('devDependencies',{})}; print('yes' if 'hono' in deps else 'no')" 2>/dev/null || echo "no")
    has_fastify=$(python3 -c "import json; d=json.load(open('$dir/package.json')); deps={**d.get('dependencies',{}),**d.get('devDependencies',{})}; print('yes' if 'fastify' in deps else 'no')" 2>/dev/null || echo "no")

    if [[ "$has_vite" == "yes" ]]; then
      echo "react_vite"
      return 0
    fi
    if [[ "$has_next" == "yes" ]]; then
      echo "nextjs"
      return 0
    fi
    if [[ "$has_express" == "yes" || "$has_hono" == "yes" || "$has_fastify" == "yes" ]]; then
      echo "node_backend"
      return 0
    fi
    # Default for package.json without known frameworks
    echo "node_backend"
    return 0
  fi

  # Check for docs-only (only .md files, no code)
  local has_code
  has_code=$(find "$dir" -maxdepth 2 -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.rs' -o -name '*.go' \) 2>/dev/null | head -1)
  if [[ -z "$has_code" ]]; then
    echo "docs_only"
    return 0
  fi

  echo "unknown"
}

# --- Read profile from YAML using ruby ---
read_profile_field() {
  local profile="$1"
  local field="$2"
  ruby -e "
require 'yaml'
data = YAML.load_file('$PROFILES_FILE')
profiles = data['profiles'] || {}
p = profiles['$profile'] || {}
value = p['$field']
if value.is_a?(Array)
  puts value.join(',')
else
  puts value || ''
end
" 2>/dev/null || echo ""
}

read_gate_command() {
  local profile="$1"
  local gate="$2"
  ruby -e "
require 'yaml'
data = YAML.load_file('$PROFILES_FILE')
profiles = data['profiles'] || {}
p = profiles['$profile'] || {}
gates = p['gate_commands'] || {}
puts gates['$gate'] || ''
" 2>/dev/null || echo ""
}

# --- Main ---
REPO_TYPE=$(detect_repo_type "$REPO_PATH")
PROFILE="$REPO_TYPE"

PACKAGE_MANAGER=$(read_profile_field "$PROFILE" "package_manager")
DEFAULT_LANE=$(read_profile_field "$PROFILE" "default_lane")
VERIFICATION_PROFILE=$(read_profile_field "$PROFILE" "default_verification_profile")
BROWSER_VERIFICATION=$(read_profile_field "$PROFILE" "browser_verification_required")
DEPLOY_TARGETS=$(read_profile_field "$PROFILE" "deploy_targets")

GATE_LINT=$(read_gate_command "$PROFILE" "lint")
GATE_TYPECHECK=$(read_gate_command "$PROFILE" "typecheck")
GATE_TEST=$(read_gate_command "$PROFILE" "test")
GATE_BUILD=$(read_gate_command "$PROFILE" "build")

echo "REPO_TYPE: $REPO_TYPE"
echo "REPO_PROFILE: $PROFILE"
echo "PACKAGE_MANAGER: $PACKAGE_MANAGER"
echo "DEFAULT_LANE: $DEFAULT_LANE"
echo "VERIFICATION_PROFILE: $VERIFICATION_PROFILE"
echo "GATE_LINT: $GATE_LINT"
echo "GATE_TYPECHECK: $GATE_TYPECHECK"
echo "GATE_TEST: $GATE_TEST"
echo "GATE_BUILD: $GATE_BUILD"
echo "DEPLOY_TARGETS: $DEPLOY_TARGETS"
echo "BROWSER_VERIFICATION: $BROWSER_VERIFICATION"
