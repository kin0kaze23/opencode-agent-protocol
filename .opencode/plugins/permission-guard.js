/**
 * Permission Guard Plugin — v4.38.0
 *
 * Runtime-level permission enforcement that denies dangerous file edits
 * and bash commands regardless of per-agent config restoration.
 *
 * This plugin intercepts tool.execute.before for edit, read, and bash tools.
 * It enforces the same deny-lists defined in opencode.json, but at the
 * plugin level — bypassing per-agent edit/bash overrides entirely.
 *
 * Safety boundaries enforced:
 * - .env files: denied for edit, read, and bash read commands
 * - Package/lockfiles: denied for edit (all languages)
 * - Protocol files: denied for edit (.opencode/, AGENTS.md)
 * - Schema/migrations: denied for edit
 * - Auth/payment/billing: denied for edit
 * - CI/deploy configs: denied for edit
 * - Raw git mutations: denied for bash (git push, git commit, git add, etc.)
 * - Package installs: denied for bash (npm install, pnpm add, cargo add, etc.)
 * - Deploy commands: denied for bash (vercel, wrangler, supabase, etc.)
 * - Destructive commands: denied for bash (rm -rf, chmod, chown)
 * - Secret reads: denied for bash (cat .env*, grep * .env*, etc.)
 *
 * See: .opencode/AGENTS.md — Safe Autopilot Permission Profile
 */

// ─── Deny-list patterns ───────────────────────────────────────────────────

// File paths that must never be edited
const EDIT_DENY_PATTERNS = [
  // Secrets
  /^\.env(\.|$)/,
  /\/\.env(\.|$)/,
  // Package files (all languages)
  /(^|\/)package\.json$/,
  /(^|\/)package-lock\.json$/,
  /(^|\/)pnpm-lock\.yaml$/,
  /(^|\/)yarn\.lock$/,
  /(^|\/)bun\.lock$/,
  /(^|\/)bun\.lockb$/,
  /(^|\/)Cargo\.toml$/,
  /(^|\/)Cargo\.lock$/,
  /(^|\/)requirements\.txt$/,
  /(^|\/)pyproject\.toml$/,
  /(^|\/)poetry\.lock$/,
  /(^|\/)go\.mod$/,
  /(^|\/)go\.sum$/,
  /(^|\/)Gemfile$/,
  /(^|\/)Gemfile\.lock$/,
  // Protocol files
  /(^|\/)AGENTS\.md$/,
  /(^|\/)\.opencode\//,
  // CI/CD
  /(^|\/)\.github\//,
  // Schema/migrations
  /(^|\/)supabase\//,
  /(^|\/)prisma\//,
  /(^|\/)drizzle\//,
  /(^|\/)migrations\//,
  /(^|\/)schema\.sql$/,
  // Auth/payment/billing
  /(^|\/)auth\//,
  /(^|\/)payment\//,
  /(^|\/)payments\//,
  /(^|\/)billing\//,
  /(^|\/)secrets\//,
  // Infra
  /(^|\/)terraform\//,
  /\.tf$/,
  /(^|\/)kubernetes\//,
  /(^|\/)k8s\//,
  /(^|\/)helm\//,
  // Deploy configs
  /(^|\/)vercel\.json$/,
  /(^|\/)wrangler\.toml$/,
  /(^|\/)firebase\.json$/,
  /(^|\/)netlify\.toml$/,
  /(^|\/)railway\.json$/,
  /(^|\/)Dockerfile/,
  /(^|\/)docker-compose.*\.ya?ml$/,
  /(^|\/)Makefile$/,
  /(^|\/)Procfile$/,
];

// File paths that must never be read (secrets only)
const READ_DENY_PATTERNS = [
  /^\.env(\.|$)/,
  /\/\.env(\.|$)/,
];

// File paths that are always allowed to read even if they match .env patterns
const READ_ALLOW_PATTERNS = [
  /\.env\.example$/,
];

// Bash command prefixes that must be denied
const BASH_DENY_PREFIXES = [
  // Git mutations — prefix matches (with args)
  "git add ",
  "git commit ",
  "git push ",
  "git reset --hard",
  "git clean ",
  // Git mutations — exact bare commands (no args)
  "git push$",
  "git commit$",
  "git add$",
  "git clean$",
  // Destructive
  "rm -rf ",
  "chmod ",
  "chown ",
  // Package installs (all languages) — including shorthands
  "npm install",
  "npm i ",           // shorthand for npm install
  "npm i$",           // bare "npm i"
  "npm uninstall",
  "npm un",
  "npm update",
  "npm up",
  "pnpm add ",
  "pnpm remove ",
  "pnpm install",
  "pnpm i ",          // shorthand
  "yarn add ",
  "yarn install",
  "bun add ",
  "cargo add ",
  "cargo install ",
  "pip install ",
  "python -m pip install ",
  "poetry add ",
  "poetry install ",
  "go get ",
  "bundle install ",
  "gem install ",
  // Deploy commands
  "vercel ",
  "wrangler ",
  "supabase ",
  "firebase ",
  "railway ",
  "fly ",
  // PR merge/release
  "gh pr merge",
  "gh release",
  // Pipe to shell
  "curl ",
  "wget ",
];

// Bash commands that read secrets — denied even though cat/grep/rg are allowed
// Matches .env anywhere in the argument path (e.g., .autopilot-canary/.env)
const BASH_SECRET_READ_PATTERNS = [
  // Common secret-read tools: cat, less, more, head, tail, grep, rg, awk, sed
  /^(cat|less|more|head|tail|grep|rg|awk|sed)\s+.*\.env/,
  // git show with .env path (e.g., git show HEAD:.env or git show HEAD:.autopilot-canary/.env)
  /^git\s+show\s+.*\.env/,
];

// ─── Matching logic ───────────────────────────────────────────────────────

function matchesEditDeny(filePath) {
  if (!filePath || typeof filePath !== "string") return false;
  return EDIT_DENY_PATTERNS.some((pattern) => pattern.test(filePath));
}

function matchesReadDeny(filePath) {
  if (!filePath || typeof filePath !== "string") return false;
  // Check allow patterns first
  if (READ_ALLOW_PATTERNS.some((pattern) => pattern.test(filePath))) return false;
  return READ_DENY_PATTERNS.some((pattern) => pattern.test(filePath));
}

function matchesBashDeny(command) {
  if (!command || typeof command !== "string") return false;

  // Check secret-read patterns (cat .env, grep .env, etc.) against full command
  if (BASH_SECRET_READ_PATTERNS.some((pattern) => pattern.test(command))) {
    return true;
  }

  // Split on command chaining operators: && || ; | and newlines
  // This catches: "cd app && git push", "echo hi; rm -rf /", etc.
  const segments = command.split(/&&|\|\||;|\n|\|/);

  for (let segment of segments) {
    segment = segment.trim();
    if (!segment) continue;

    // Strip leading "cd ..." patterns — the real command is what follows
    // But we already split on && so cd segments are separate
    // Just check this segment directly

    // Check for subshell wrappers: bash -lc "...", sh -c "...", eval "..."
    const subshellMatch = segment.match(/(?:bash|sh|zsh)\s+(?:-lc|-c)\s+["'](.+?)["']/);
    if (subshellMatch) {
      // Recursively check the inner command
      if (matchesBashDeny(subshellMatch[1])) return true;
      continue;
    }

    const evalMatch = segment.match(/eval\s+["'](.+?)["']/);
    if (evalMatch) {
      if (matchesBashDeny(evalMatch[1])) return true;
      continue;
    }

    // Check deny prefixes against this segment
    for (const prefix of BASH_DENY_PREFIXES) {
      // Handle "$" suffix for exact match (e.g., "npm i$" matches "npm i" but not "npm install")
      if (prefix.endsWith("$")) {
        const exact = prefix.slice(0, -1);
        if (segment === exact || segment.startsWith(exact + " ")) {
          if (prefix === "curl " || prefix === "wget ") {
            if (segment.includes("| sh") || segment.includes("|bash") || segment.includes("| bash")) {
              return true;
            }
            continue;
          }
          return true;
        }
      } else {
        if (segment.startsWith(prefix)) {
          // Special case: curl/wget are only denied when piped to sh
          if (prefix === "curl " || prefix === "wget ") {
            if (segment.includes("| sh") || segment.includes("|bash") || segment.includes("| bash")) {
              return true;
            }
            continue;
          }
          return true;
        }
      }
    }
  }

  return false;
}

// ─── Plugin export ─────────────────────────────────────────────────────────

export const PermissionGuard = async ({ project, client, $, directory, worktree }) => {
  // Startup diagnostic — visible in logs and helps verify plugin is loaded
  console.error("[PermissionGuard] Plugin loaded — enforcing deny-lists for edit, read, bash");

  return {
    "tool.execute.before": async (input, output) => {
      const tool = input?.tool;
      const args = output?.args || {};

      // ── Edit tool enforcement ──────────────────────────────────────────
      if (tool === "edit" || tool === "write") {
        const filePath = args.filePath || args.path || "";
        if (matchesEditDeny(filePath)) {
          throw new Error(
            `PermissionGuard: EDIT DENIED — file matches a protected pattern: ${filePath}\n` +
            `This file is on the deny-list for the Safe Autopilot Permission Profile.\n` +
            `Use oc-manual (Manual Ship mode) for this change.`
          );
        }
      }

      // ── Read tool enforcement ─────────────────────────────────────────
      if (tool === "read") {
        const filePath = args.filePath || args.path || "";
        if (matchesReadDeny(filePath)) {
          throw new Error(
            `PermissionGuard: READ DENIED — file matches a secret protection pattern: ${filePath}\n` +
            `.env files are protected from reading under the Safe Autopilot Permission Profile.\n` +
            `Use oc-manual (Manual Ship mode) if you need to read this file.`
          );
        }
      }

      // ── Bash tool enforcement ──────────────────────────────────────────
      if (tool === "bash") {
        const command = args.command || "";
        if (matchesBashDeny(command)) {
          throw new Error(
            `PermissionGuard: BASH DENIED — command matches a protected pattern: ${command}\n` +
            `This command is on the deny-list for the Safe Autopilot Permission Profile.\n` +
            `Use oc-manual (Manual Ship mode) for this operation.`
          );
        }
      }
    },
  };
};
