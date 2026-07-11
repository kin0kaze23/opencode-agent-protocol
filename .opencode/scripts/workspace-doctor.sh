#!/usr/bin/env bash
set -u
set -o pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CATALOG="$ROOT/WORKSPACE_CATALOG.yaml"
NAV="$ROOT/docs/workspace-audit/AGENT_NAV_INDEX.md"
FRESHNESS="$ROOT/DOCS_FRESHNESS.yaml"
PROTOCOL_VERSION="v4.15.0"

warn_count=0
fail_count=0

pass() { printf 'PASS: %s\n' "$1"; }
warn() { warn_count=$((warn_count + 1)); printf 'WARN: %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL: %s\n' "$1"; }
section() { printf '\n== %s ==\n' "$1"; }

section "Workspace Doctor v0.1 — read-only"
printf 'Root: %s\n' "$ROOT"
printf 'Protocol expected: %s\n' "$PROTOCOL_VERSION"

section "YAML parse checks"
if ruby -e "require 'yaml'; YAML.load_file(ARGV[0])" "$CATALOG" >/dev/null 2>&1; then
  pass "WORKSPACE_CATALOG.yaml parses"
else
  fail "WORKSPACE_CATALOG.yaml does not parse"
fi

if ruby -e "require 'yaml'; YAML.load_file(ARGV[0])" "$FRESHNESS" >/dev/null 2>&1; then
  pass "DOCS_FRESHNESS.yaml parses"
else
  fail "DOCS_FRESHNESS.yaml does not parse"
fi

section "Catalog structural checks"
ruby - "$ROOT" "$CATALOG" <<'RUBY'
require 'yaml'
require 'set'
root, catalog_path = ARGV
catalog = YAML.load_file(catalog_path)
entries = catalog.fetch('top_level_entries', [])
ids = entries.map { |e| e['id'] }
counts = Hash.new(0)
ids.each { |id| counts[id] += 1 }
dupes = counts.select { |_k, v| v > 1 }.keys
if dupes.empty?
  puts 'PASS: no duplicate repo/folder IDs'
else
  puts "FAIL: duplicate IDs: #{dupes.join(', ')}"
end

catalog_paths = entries.map { |e| e['path'] }.compact.to_set

top_dirs = Dir.children(root).select { |name| File.directory?(File.join(root, name)) && name != '.git' }.sort
missing_catalog = top_dirs.reject { |name| catalog_paths.include?(name) }
if missing_catalog.empty?
  puts "PASS: every observed top-level directory is represented (#{top_dirs.length})"
else
  puts "WARN: observed top-level directories missing from catalog: #{missing_catalog.join(', ')}"
end

bad_paths = []
entries.each do |entry|
  path = entry['path']
  next if path.nil? || path == '.'
  lifecycle = entry['lifecycle'].to_s
  exists = File.exist?(File.join(root, path))
  allowed_absent = lifecycle.include?('missing') || lifecycle.include?('archive') || lifecycle.include?('retired')
  bad_paths << "#{entry['id']}:#{path}:#{lifecycle}" if !exists && !allowed_absent
end
if bad_paths.empty?
  puts 'PASS: catalog paths exist or are explicitly marked missing/archive/retired'
else
  puts "WARN: catalog paths absent without explicit missing/archive lifecycle: #{bad_paths.join('; ')}"
end

contract_warnings = []
entries.each do |entry|
  lifecycle = entry['lifecycle'].to_s
  kind = entry['kind'].to_s
  path = entry['path']
  next unless path && path != '.' && File.directory?(File.join(root, path))
  next unless lifecycle == 'active' || lifecycle == 'operational'
  next unless kind.include?('repo') || kind.include?('project')
  ag = File.join(root, path, 'AGENTS.md')
  now = File.join(root, path, 'NOW.md')
  contract_warnings << "#{entry['id']} missing AGENTS.md" unless File.exist?(ag)
  contract_warnings << "#{entry['id']} missing NOW.md" unless File.exist?(now)
end
if contract_warnings.empty?
  puts 'PASS: active/operational repo entries have AGENTS.md and NOW.md or are not classified as active repos'
else
  puts "WARN: repo contract warnings: #{contract_warnings.join('; ')}"
end
RUBY

section "Agent nav reference checks"
if [[ -f "$NAV" ]]; then
  ruby - "$ROOT" "$NAV" <<'RUBY'
root, nav = ARGV
text = File.read(nav)
tokens = text.scan(/`([^`]+)`/).flatten
pathish = tokens.select do |token|
  token =~ %r{[/.]} &&
    token !~ /\s/ &&
    token !~ /^</ &&
    token !~ %r{^/} &&
    token !~ /\|/ &&
    token !~ /[()]/
end
generated_placeholders = %w[node_modules/ dist/ build/ .next/ .pytest_cache/ .turbo/]
missing = pathish.uniq.reject do |token|
  generated_placeholders.include?(token) || token.include?('<repo>') || token.include?('<skill>') || File.exist?(File.join(root, token))
end
if missing.empty?
  puts "PASS: docs/workspace-audit/AGENT_NAV_INDEX.md backtick path references resolve or are template placeholders"
else
  puts "WARN: docs/workspace-audit/AGENT_NAV_INDEX.md unresolved path-like references: #{missing.join(', ')}"
end
RUBY
else
  fail "docs/workspace-audit/AGENT_NAV_INDEX.md missing"
fi

section "Protocol version checks"
if [[ -f "$ROOT/vault/protocols/opencode/CURRENT.md" ]] && ruby -e "exit(File.read(ARGV[0]).include?(ARGV[1]) ? 0 : 1)" "$ROOT/vault/protocols/opencode/CURRENT.md" "$PROTOCOL_VERSION"; then
  pass "vault/protocols/opencode/CURRENT.md references $PROTOCOL_VERSION"
else
  fail "CURRENT.md does not reference $PROTOCOL_VERSION"
fi
if [[ -f "$ROOT/.opencode/AGENTS.md" ]] && ruby -e "exit(File.read(ARGV[0]).include?(ARGV[1]) ? 0 : 1)" "$ROOT/.opencode/AGENTS.md" "$PROTOCOL_VERSION"; then
  pass ".opencode/AGENTS.md references $PROTOCOL_VERSION"
else
  warn ".opencode/AGENTS.md does not visibly reference $PROTOCOL_VERSION"
fi

section "Legacy directories detected, not moved"
for dir in .agent .ai .cursor .qwen .superpowers; do
  if [[ -d "$ROOT/$dir" ]]; then
    warn "legacy/tool directory present: $dir"
  else
    pass "legacy/tool directory absent: $dir"
  fi
done

section "Generated artifact directory counts, not deleted"
ruby - "$ROOT" <<'RUBY'
require 'find'
root = ARGV[0]
patterns = %w[node_modules dist build .next __pycache__ .pytest_cache .turbo .playwright-mcp]
counts = Hash.new(0)
Find.find(root) do |path|
  rel = path.sub(root + '/', '')
  parts = rel.split('/')
  if parts.include?('.git') || parts.include?('vault') && parts.include?('.git')
    Find.prune if File.directory?(path)
    next
  end
  next unless File.directory?(path)
  base = File.basename(path)
  if patterns.include?(base)
    counts[base] += 1
    Find.prune
  end
end
patterns.each { |name| puts "INFO: generated artifact dirs named #{name}: #{counts[name]}" }
RUBY

section "Stale vault project candidates, not moved"
ruby - "$ROOT" "$CATALOG" <<'RUBY'
require 'yaml'
root, catalog_path = ARGV
catalog = YAML.load_file(catalog_path)
paths = catalog.fetch('top_level_entries', []).map { |e| File.basename(e['path'].to_s) }.uniq
projects_dir = File.join(root, 'vault', 'projects')
if File.directory?(projects_dir)
  candidates = Dir.children(projects_dir).select { |name| File.directory?(File.join(projects_dir, name)) && !name.start_with?('.') }.sort.reject { |name| paths.include?(name) }
  if candidates.empty?
    puts 'PASS: no vault project directories outside catalog basename set'
  else
    puts "WARN: vault project dirs without direct catalog basename match: #{candidates.join(', ')}"
  end
else
  puts 'WARN: vault/projects directory missing'
end
RUBY

section "Registry inventory"
ruby - "$ROOT" "$CATALOG" <<'RUBY'
require 'yaml'
root, catalog_path = ARGV
catalog = YAML.load_file(catalog_path)
catalog.fetch('registry_inventory', []).each do |entry|
  path = entry['path']
  status = entry['status']
  exists = File.exist?(File.join(root, path))
  marker = exists ? 'present' : 'missing'
  puts "INFO: #{path} — #{status} — #{marker}"
end
RUBY

section "Summary"
printf 'Warnings: %s\n' "$warn_count"
printf 'Failures: %s\n' "$fail_count"
if [[ "$fail_count" -gt 0 ]]; then
  exit 1
fi
exit 0
