import { execFileSync } from "child_process";
import { existsSync, readFileSync, writeFileSync, mkdirSync } from "fs";
import { createHash } from "crypto";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PORTFOLIO_ROOT = join(__dirname, "..", "..");
const METRICS_DIR = join(PORTFOLIO_ROOT, ".opencode", "metrics", "empty-response");
const OPENCODE_LOG = join(process.env.HOME || process.env.USERPROFILE || "", ".local", "share", "opencode", "log", "opencode.log");

// Ensure metrics directory exists
try { mkdirSync(METRICS_DIR, { recursive: true }); } catch (_) {}

// ─── helpers ────────────────────────────────────────────────────────────────

function notify(title, body) {
  try {
    const script = `display notification "${body.replace(/"/g, "'")}" with title "${title.replace(/"/g, "'")}" sound name "Glass"`;
    execFileSync("osascript", ["-e", script], { timeout: 5000 });
  } catch (_) {
    // Notifications are best-effort; never crash the plugin.
  }
}

function guessRepo(directory) {
  if (!directory || typeof directory !== "string") return null;
  const rel = directory.replace(PORTFOLIO_ROOT, "").replace(/^\//, "");
  return rel.split("/")[0] || null;
}

function getRepoRoot(repo) {
  if (!repo || repo === "." || repo === "workspace-root") return PORTFOLIO_ROOT;
  return join(PORTFOLIO_ROOT, repo);
}

function getRepoLabel(repo) {
  if (!repo || repo === "." || repo === "workspace-root") return "workspace-root";
  return repo;
}

function modelIDFromConfig(model) {
  if (!model || typeof model !== "string") return null;
  return model.split("/").pop() || model;
}

function detectRecentProviderUnavailable(model) {
  const modelID = modelIDFromConfig(model);
  if (!modelID || !existsSync(OPENCODE_LOG)) {
    return { status: "unknown", model, reason: "no_model_or_log" };
  }

  try {
    const raw = readFileSync(OPENCODE_LOG, "utf8");
    const tail = raw.slice(-250000);
    const unavailablePattern = /(Insufficient balance|quota|rate limit|provider unavailable|429)/i;
    const modelPattern = new RegExp(`modelID=${modelID.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}|llm\\.model=${modelID.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`, "i");

    if (modelPattern.test(tail) && unavailablePattern.test(tail)) {
      return { status: "recent_provider_unavailable", model, modelID };
    }
    return { status: "unknown_no_recent_failure", model, modelID };
  } catch (error) {
    return {
      status: "unknown_log_read_error",
      model,
      modelID,
      errorName: error?.name || "Error",
      errorCode: error?.code || "unknown",
    };
  }
}

function readFileSafe(path) {
  if (!existsSync(path)) return null;
  try {
    return readFileSync(path, "utf8").trim();
  } catch (_) {
    return null;
  }
}

function normalizeInline(text) {
  return String(text || "")
    .replace(/\s+/g, " ")
    .trim();
}

function clip(text, max = 160) {
  const normalized = normalizeInline(text);
  if (normalized.length <= max) return normalized;
  return `${normalized.slice(0, max - 1)}…`;
}

function getConfiguredAgentModel(name) {
  const cfgPath = join(PORTFOLIO_ROOT, ".opencode", "opencode.json");
  const raw = readFileSafe(cfgPath);
  if (!raw) return null;
  try {
    const cfg = JSON.parse(raw);
    return cfg?.agent?.[name]?.model || null;
  } catch (_) {
    return null;
  }
}

function collectInlineOrHeadingSection(text, options) {
  if (!text) return null;
  const lines = text.split("\n");
  const inlineLabels = options.inlineLabels || [];
  const headingLabels = options.headingLabels || [];
  const stopMatchers = options.stopMatchers || [];

  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    let collected = [];
    let matched = false;

    for (const label of inlineLabels) {
      const re = new RegExp(`^${label}:\\s*(.*)$`, "i");
      const match = line.match(re);
      if (match) {
        matched = true;
        if (match[1]) collected.push(match[1]);
        for (let j = i + 1; j < lines.length; j += 1) {
          const next = lines[j];
          if (stopMatchers.some((reStop) => reStop.test(next))) break;
          collected.push(next);
        }
        break;
      }
    }
    if (matched) {
      const value = collected.join("\n").trim();
      return value || null;
    }

    for (const label of headingLabels) {
      const re = new RegExp(`^#{1,6}\\s*${label}\\s*$`, "i");
      if (re.test(line)) {
        for (let j = i + 1; j < lines.length; j += 1) {
          const next = lines[j];
          if (/^#{1,6}\s+/.test(next)) break;
          collected.push(next);
        }
        const value = collected.join("\n").trim();
        return value || null;
      }
    }
  }

  return null;
}

function extractPlanField(text, label) {
  if (!text) return null;
  const match = text.match(new RegExp(`^${label}:\\s*(.+)$`, "mi"));
  return match ? normalizeInline(match[1]) : null;
}

function extractTouchListLines(text) {
  if (!text) return [];
  const match = text.match(/^Touch list:\s*([\s\S]*?)(?=^\S[^:\n]*:|^##\s+|\Z)/mi);
  if (!match) return [];
  return match[1]
    .split("\n")
    .map((line) => normalizeInline(line.replace(/^[-*]\s*/, "")))
    .filter(Boolean);
}

function buildContinuitySnapshot(repo, nowText, planText) {
  if (!repo) return null;

  const stopMatchers = [
    /^Repo:/i,
    /^Status:/i,
    /^Current task:/i,
    /^Blockers:/i,
    /^Latest decisions:/i,
    /^Immediate next steps:/i,
    /^##\s+/,
  ];

  const currentTask = collectInlineOrHeadingSection(nowText, {
    inlineLabels: ["Current task"],
    headingLabels: ["Current Task"],
    stopMatchers,
  });
  const blockers = collectInlineOrHeadingSection(nowText, {
    inlineLabels: ["Blockers", "Blocked By"],
    headingLabels: ["Blockers", "Blocked By"],
    stopMatchers,
  });
  const latestDecision = collectInlineOrHeadingSection(nowText, {
    inlineLabels: ["Latest decisions"],
    headingLabels: ["Latest Decisions"],
    stopMatchers,
  });
  const nextStep = collectInlineOrHeadingSection(nowText, {
    inlineLabels: ["Immediate next steps"],
    headingLabels: ["Immediate Next Steps"],
    stopMatchers,
  });

  const lane = extractPlanField(planText, "Lane");
  const touchListLines = extractTouchListLines(planText);
  const touchListDigest = touchListLines.length
    ? createHash("sha1").update(touchListLines.join("|")).digest("hex").slice(0, 8)
    : null;
  const touchListShort = touchListLines.length
    ? touchListLines.slice(0, 3).join(" | ")
    : null;

  return {
    repo,
    currentTask: currentTask ? clip(currentTask) : null,
    lane: lane || null,
    touchListDigest: touchListDigest || null,
    touchListShort: touchListShort ? clip(touchListShort, 220) : null,
    blockers: blockers ? clip(blockers) : null,
    latestDecision: latestDecision ? clip(latestDecision) : null,
    nextStep: nextStep ? clip(nextStep) : null,
  };
}

function buildContinuityAnchors(snapshot) {
  if (!snapshot?.repo) return null;

  const lines = ["=== CONTINUITY ANCHORS (injected before compaction) ==="];
  lines.push(`Repo: ${snapshot.repo}`);
  if (snapshot.currentTask) lines.push(`Current task: ${snapshot.currentTask}`);
  if (snapshot.lane) lines.push(`Lane: ${snapshot.lane}`);
  if (snapshot.touchListDigest) lines.push(`Touch list digest: ${snapshot.touchListDigest}`);
  if (snapshot.touchListShort) lines.push(`Touch list short: ${snapshot.touchListShort}`);
  if (snapshot.blockers) lines.push(`Blockers: ${snapshot.blockers}`);
  if (snapshot.latestDecision) lines.push(`Latest decision: ${snapshot.latestDecision}`);
  if (snapshot.nextStep) lines.push(`Next step: ${snapshot.nextStep}`);
  lines.push("=== END CONTINUITY ANCHORS ===");

  return lines.length > 2 ? lines.join("\n") : null;
}

function diffContinuitySnapshots(previous, current) {
  if (!previous || !current) return [];
  const fields = ["repo", "currentTask", "lane", "touchListDigest", "blockers", "nextStep"];
  return fields.filter((field) => (previous[field] || null) !== (current[field] || null));
}

function buildPhaseContext(repo) {
  const repoRoot = getRepoRoot(repo);
  const repoLabel = getRepoLabel(repo);
  const lines = [];

  const now = readFileSafe(join(repoRoot, "NOW.md"));
  if (now) {
    lines.push("=== NOW.md (injected before compaction) ===");
    lines.push(now);
    lines.push("=== END NOW.md ===");
  } else {
    const phase = readFileSafe(join(repoRoot, "PHASE_STATE.md"));
    if (phase) {
      lines.push("=== LEGACY PHASE_STATE (injected before compaction; normalize to NOW.md on next checkpoint) ===");
      lines.push(phase);
      lines.push("=== END LEGACY PHASE_STATE ===");
    }
  }

  const plan = readFileSafe(join(repoRoot, "PLAN.md"));
  if (plan) {
    lines.push("=== ACTIVE PLAN (repo-root PLAN.md excerpt) ===");
    lines.push(plan.slice(0, 2000));
    lines.push("=== END ACTIVE PLAN ===");
  }

  const anchors = buildContinuityAnchors(buildContinuitySnapshot(repoLabel, now, plan));
  if (anchors) lines.push(anchors);

  return lines.length > 0 ? lines.join("\n") : null;
}

// ─── Empty Response Guardrail ────────────────────────────────────────────────

function isEmptyResponse(content) {
    return !content || typeof content !== "string" || content.trim().length === 0;
}

function logEmptyResponse(model, taskType, promptHash, latency, tokens) {
    const timestamp = new Date().toISOString();
    const logEntry = {
        timestamp,
        model,
        task_type: taskType || "unknown",
        prompt_hash: promptHash || "unknown",
        latency_seconds: latency || "unknown",
        token_usage: tokens || "unknown",
        failure_reason: "empty_content",
        action: "retry_with_qwen3.6-plus",
        retry_status: "logged",
    };

    const logFile = join(METRICS_DIR, `empty-response-${Date.now()}.json`);
    try {
        writeFileSync(logFile, JSON.stringify(logEntry, null, 2), "utf8");
    } catch (_) {
        // Logging is best-effort; never crash the plugin.
    }

    return logEntry;
}

function validateResponse(content, model, taskType, promptHash, latency, tokens) {
    if (isEmptyResponse(content)) {
        const logEntry = logEmptyResponse(model, taskType, promptHash, latency, tokens);
        return {
            valid: false,
            action: "retry_with_qwen3.6-plus",
            log_entry: logEntry,
            message: `Empty response from ${model}. Retry with opencode-go/qwen3.6-plus.`,
        };
    }

    return {
        valid: true,
        action: "proceed",
        message: `Response from ${model} is valid (${content.length} bytes).`,
    };
}

export const BrainHooksPlugin = async ({ client, directory }) => {
  const sessions = new Map();
  const configuredCompactionModel = getConfiguredAgentModel("compaction");
  const configuredSummaryModel = getConfiguredAgentModel("summary");

  // ── Startup instrumentation ──────────────────────────────────────────
  try {
    await client.app.log({
      body: {
        service: "brain-hooks",
        level: "info",
        message: "brain-hooks plugin initialized",
        extra: {
          directory,
          repo: guessRepo(directory),
          configuredCompactionModel,
          configuredSummaryModel,
          hooks: [
            "event (session.created, session.idle, session.status, session.deleted, session.compacted)",
            "experimental.session.compacting",
            "chat.message (UNVERIFIED)",
            "validateResponse (UNVERIFIED)",
          ],
        },
      },
    });
  } catch (_) { /* logging is best-effort */ }

  function getSession(sessionID) {
    if (!sessions.has(sessionID)) {
      sessions.set(sessionID, {
        agent: null,
        repo: guessRepo(directory),
        startedAt: Date.now(),
        lastContinuitySnapshot: null,
        continuityChecked: false,
        continuityStatus: "UNKNOWN",
        continuityDrift: [],
      });
    }
    return sessions.get(sessionID);
  }

  return {
    event: async ({ event }) => {
      if (event.type === "session.created") {
        const sessionID = event.properties?.sessionID;
        if (!sessionID) return;

        const session = getSession(sessionID);
        session.startedAt = Date.now();
        return;
      }

      // ── Notification when agent becomes idle ──────────────────────────
      if (event.type === "session.idle") {
        const sessionID = event.properties?.sessionID;
        if (!sessionID) return;

        const session = getSession(sessionID);
        const agent = session.agent || "Agent";
        const repo = session.repo || "project";
        const elapsed = Math.round((Date.now() - session.startedAt) / 1000);
        const mins = Math.floor(elapsed / 60);
        const secs = elapsed % 60;
        const duration = mins > 0 ? `${mins}m ${secs}s` : `${secs}s`;

        notify(`OpenCode — ${agent} done`, `${repo} · ${duration}`);
        return;
      }

      // ── Track active agent per session ────────────────────────────────
      if (event.type === "session.status") {
        const sessionID = event.properties?.sessionID;
        if (!sessionID) return;
        const agent = event.properties?.status?.agent;
        if (agent) getSession(sessionID).agent = agent;
        return;
      }

      if (event.type === "session.deleted") {
        const id = event.properties?.info?.id;
        if (id) sessions.delete(id);
      }

      // ── Compaction completion observability ─────────────────────────────
      if (event.type === "session.compacted" || event.type === "session.next.compaction.ended") {
        const sessionID = event.properties?.sessionID;
        if (!sessionID) return;

        const session = getSession(sessionID);
        const repo = session.repo;

        try {
          await client.app.log({
            body: {
              service: "brain-hooks",
              level: "info",
              message: "compaction completed event received",
              extra: {
                eventType: event.type,
                sessionID,
                repo,
                configuredCompactionModel,
                note: "OpenCode uses agent.compaction.model when set; source path audited in SessionCompaction.process",
              },
            },
          });
        } catch (_) {}
        return;
      }
    },

    // ── Inject NOW.md / PLAN.md context into compaction summary ──────────
    "experimental.session.compacting": async (input, output) => {
      let sessionID = null;
      let repo = null;
      let providerStatus = { status: "unknown" };

      try {
        sessionID = input?.sessionID;
        if (!sessionID) {
          try {
            await client.app.log({
              body: {
                service: "brain-hooks",
                level: "warn",
                message: "compaction hook: safe skip missing sessionID",
                extra: { outcome: "safe_skip", reason: "missing_sessionID" },
              },
            });
          } catch (_) {}
          return;
        }

        const session = getSession(sessionID);
        repo = getRepoLabel(session.repo);
        providerStatus = detectRecentProviderUnavailable(configuredCompactionModel);

        try {
          await client.app.log({
            body: {
              service: "brain-hooks",
              level: "info",
              message: "compaction hook entered",
              extra: {
                repo,
                outcome: "entered",
                configuredCompactionModel,
                providerStatus,
                note: "OpenCode uses agent.compaction.model when set; source path audited in SessionCompaction.process",
              },
            },
          });
        } catch (_) {}

        if (providerStatus.status === "recent_provider_unavailable") {
          try {
            await client.app.log({
              body: {
                service: "brain-hooks",
                level: "warn",
                message: "compaction hook: provider unavailable recently detected",
                extra: { repo, outcome: "provider_unavailable", configuredCompactionModel, providerStatus },
              },
            });
          } catch (_) {}
        }

        if (!configuredCompactionModel) {
          try {
            await client.app.log({
              body: {
                service: "brain-hooks",
                level: "warn",
                message: "compaction hook: agent.compaction.model is not configured; OpenCode will fall back to the active chat model",
                extra: { repo, outcome: "provider_unavailable", reason: "missing_configured_compaction_model" },
              },
            });
          } catch (_) {}
        }

        const repoRoot = getRepoRoot(session.repo);
        const now = readFileSafe(join(repoRoot, "NOW.md"));
        const plan = readFileSafe(join(repoRoot, "PLAN.md"));
        session.lastContinuitySnapshot = buildContinuitySnapshot(repo, now, plan);
        session.continuityChecked = false;
        session.continuityStatus = "UNKNOWN";
        session.continuityDrift = [];

        const ctx = buildPhaseContext(session.repo);
        if (!ctx) {
          try {
            await client.app.log({
              body: {
                service: "brain-hooks",
                level: "info",
                message: "compaction hook: safe skip no context generated",
                extra: { repo, outcome: "safe_skip", reason: "no_context_generated" },
              },
            });
          } catch (_) {}
          return;
        }

        // OpenCode compaction hook contract: mutate output.context / output.prompt, do not return a replacement object.
        const contextBefore = output?.context?.length || 0;
        if (Array.isArray(output?.context)) {
          output.context.push(ctx);
          const contextAfter = output.context.length;

          try {
            await client.app.log({
              body: {
                service: "brain-hooks",
                level: "info",
                message: "compaction hook: context injected",
                extra: { repo, outcome: "success", contextBefore, contextAfter, contextLength: ctx.length },
              },
            });
          } catch (_) {}
        } else {
          try {
            await client.app.log({
              body: {
                service: "brain-hooks",
                level: "warn",
                message: "compaction hook: safe skip output.context is not an array; native compaction allowed to continue",
                extra: { repo, outcome: "safe_skip", reason: "output_context_not_array", outputType: typeof output?.context },
              },
            });
          } catch (_) {}
        }
      } catch (error) {
        try {
          await client.app.log({
            body: {
              service: "brain-hooks",
              level: "warn",
              message: "compaction hook: handled error; native compaction allowed to continue",
              extra: {
                repo: repo || "unknown",
                outcome: "handled_error",
                configuredCompactionModel,
                providerStatus,
                errorName: error?.name || "Error",
                errorCode: error?.code || "unknown",
                errorMessage: error?.message ? String(error.message).slice(0, 200) : "unknown",
              },
            },
          });
        } catch (_) {}
        return;
      }
    },

    // ── Track agent from outgoing messages ────────────────────────────────
    // UNVERIFIED: "chat.message" is not listed in current OpenCode plugin docs
    // (https://opencode.ai/docs/plugins). Kept for now — may be an undocumented
    // internal event. If it never fires, drift detection will be silent.
    // Candidate documented replacements: message.updated, session.compacted.
    // Decision deferred to Commit 2 after runtime evidence is collected.
    "chat.message": async (input) => {
      const sessionID = input?.sessionID;
      if (!sessionID) return;
      const agent = input?.agent;
      const session = getSession(sessionID);
      if (agent) session.agent = agent;
      if (!session.lastContinuitySnapshot || session.continuityChecked) return;

      const repo = getRepoLabel(session.repo);
      const repoRoot = getRepoRoot(session.repo);
      const currentSnapshot = buildContinuitySnapshot(
        repo,
        readFileSafe(join(repoRoot, "NOW.md")),
        readFileSafe(join(repoRoot, "PLAN.md")),
      );
      const drift = diffContinuitySnapshots(session.lastContinuitySnapshot, currentSnapshot);
      session.continuityChecked = true;
      session.continuityDrift = drift;
      session.continuityStatus = drift.length > 0 ? "SUSPECT" : "OK";

      if (drift.length > 0) {
        notify("OpenCode — continuity drift", `${repo} · ${drift.join(", ")}`);
      }
    },

    // ── Empty Response Guardrail ──────────────────────────────────────────
    validateResponse: (content, model, taskType, promptHash, latency, tokens) => {
      return validateResponse(content, model, taskType, promptHash, latency, tokens);
    },
  };
};
