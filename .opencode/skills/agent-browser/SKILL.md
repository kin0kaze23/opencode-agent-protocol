---
name: agent-browser
description: AI-optimized browser automation CLI for live verification, auth flows, form interaction, and debugging. Uses deterministic element refs (@e1, @e2) instead of fragile CSS selectors.
license: Complete terms in LICENSE.txt
---

# Agent Browser — AI-Optimized Browser Automation

> **Tool:** `agent-browser` CLI (Vercel Labs)
> **Purpose:** Live browser verification, auth flow testing, form interaction, debugging
> **Alternative:** Playwright (for regression suites, mocks, scripted tests)

---

## 🎯 When to Use Agent Browser vs Playwright

| Use `agent-browser` | Use `playwright` |
|---------------------|------------------|
| Live browser verification (ad hoc UI checks) | Regression test suites |
| Auth flow testing (with session persistence) | Network mocking |
| Form interaction testing (stable `@e1`, `@e2` refs) | Multi-tab scenarios |
| Browser debugging (live viewport) | CI/CD scripted tests |
| Screenshot verification | Existing scripted flows |

**Rule of thumb:**
- **agent-browser** = AI-driven, interactive, ad hoc verification
- **playwright** = Scripted, regression, CI/CD, mocks

---

## 🚀 Installation (One-Time)

```bash
npm install -g agent-browser
agent-browser install  # Downloads Chrome
```

---

## 📋 Core Workflow — The Agent Browser Loop

```
┌─────────────────┐
│  1. NAVIGATE    │ → agent-browser open <url>
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  2. SNAPSHOT    │ → agent-browser snapshot --json
│  (Get refs)     │ → Returns: @e1, @e2, @e3...
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  3. INTERACT    │ → agent-browser click @e1
│  (Use refs)     │ → agent-browser fill @e2 "text"
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  4. RE-SNAPSHOT │ → Page changed? SNAPSHOT AGAIN!
│  (CRITICAL!)    │ → Get NEW refs for new state
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  5. VERIFY      │ → agent-browser screenshot
│  (Outcome)      │ → Confirm expected state
└─────────────────┘
```

**⚠️ CRITICAL RULE:** After ANY page change (navigation, form submit, modal open), you MUST re-snapshot to get updated element references. Never use old refs after page state changes.

---

## 🔧 Commands Reference

### Navigation
```bash
agent-browser open <url>
agent-browser open --headed <url>  # Visible browser
```

### Observation (AI Eyes)
```bash
agent-browser snapshot --json       # Get accessibility tree with refs
agent-browser snapshot --json --screenshot page.png  # With annotated screenshot
```

### Interaction (AI Hands)
```bash
agent-browser click @e1
agent-browser fill @e2 "text value"
agent-browser select @e3 "option-value"
agent-browser hover @e4
agent-browser press Enter
```

### Verification
```bash
agent-browser screenshot <output.png>
agent-browser title
agent-browser url
agent-browser exists @e1
```

### Session Management
```bash
agent-browser session save authenticated.json
agent-browser session load authenticated.json
agent-browser session clear
```

---

## 📝 Example Workflows

### Workflow 1: UI Verification After Deploy

```bash
agent-browser open https://myapp.vercel.app
agent-browser snapshot --json
# → {@e1: "Hero Title", @e2: "CTA Button", @e3: "Feature Section"}

agent-browser screenshot landing-verify.png
agent-browser close
```

### Workflow 2: Auth Flow Testing

```bash
agent-browser open http://localhost:3000/login
agent-browser snapshot --json
# → {@e1: "Email", @e2: "Password", @e3: "Sign In"}

agent-browser fill @e1 "test@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3

# WAIT for navigation - MUST re-snapshot!
sleep 2
agent-browser snapshot --json  # Get NEW refs
agent-browser screenshot logged-in.png
agent-browser session save auth-state.json
```

### Workflow 3: Form Interaction

```bash
agent-browser open http://localhost:3000/signup
agent-browser snapshot --json
# → {@e1: "Name", @e2: "Email", @e3: "Password", @e4: "Submit"}

agent-browser fill @e1 "John"
agent-browser fill @e2 "john@example.com"
agent-browser fill @e3 "SecurePass123!"
agent-browser click @e4

# Re-snapshot after page change
sleep 2
agent-browser snapshot --json
agent-browser screenshot signup-result.png
```

### Workflow 4: Browser Debugging

```bash
agent-browser open --headed http://localhost:3000  # Visible for debugging
agent-browser snapshot --json
agent-browser click @e3  # Observe in real-time
agent-browser logs  # Check console errors
agent-browser screenshot button-issue.png
```

---

## 🛡️ Security & Best Practices

### Credential Security (Non-Negotiable)

```bash
# ❌ WRONG: Exposing credentials
agent-browser fill @e2 "MySecretPassword123"

# ✅ RIGHT: Use session persistence
agent-browser session load auth-state.json
```

### Element Reference Rules

1. **NEVER hardcode refs** — Always get from snapshot
2. **ALWAYS re-snapshot after page change** — Refs are state-specific
3. **NEVER use CSS selectors** — Use `@e1`, `@e2` refs only
4. **Verify ref exists** — `agent-browser exists @e1`

---

## ⚠️ Common Pitfalls

| Problem | Cause | Solution |
|---------|-------|----------|
| "Element @e3 not found" | Old ref after page change | Re-snapshot after every page change |
| "Click failed" | Element not ready | Wait, then re-snapshot |
| "Session lost" | Didn't save auth | `session save` after login |
| "Timeout" | Page load slow | Add `sleep 2` before snapshot |

---

## 🔗 Integration with Playwright

**Use both tools:**
- `agent-browser` for: Live verification, debugging, ad hoc tests
- `playwright` for: Regression suites, CI/CD, mocks

**Example workflow:**
```bash
# Use agent-browser for live debugging
agent-browser open --headed http://localhost:3000
# ... interact and debug ...

# Use playwright for regression
npx playwright test e2e/regression.spec.ts
```

---

## ✅ Quick Reference Card

```
┌─────────────────────────────────────────────────────┐
│  AGENT BROWSER — AI WORKFLOW                        │
├─────────────────────────────────────────────────────┤
│  1. open <url>         → Navigate                  │
│  2. snapshot --json    → Get refs (@e1, @e2...)    │
│  3. click @e1          → Interact with refs        │
│  4. [PAGE CHANGED]     → RE-SNAPSHOT (MANDATORY!)  │
│  5. screenshot out.png → Verify outcome            │
│  6. session save       → Persist (optional)        │
└─────────────────────────────────────────────────────┘

CRITICAL: Re-snapshot after EVERY page change!
```

---

**Last Updated:** 2026-03-26  
**Skill For:** OpenCode CLI, Qwen CLI, Claude Code, Gemini CLI
