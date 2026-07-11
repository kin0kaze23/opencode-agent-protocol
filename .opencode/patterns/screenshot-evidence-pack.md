# Screenshot Evidence Pack

> **Pattern:** `.opencode/patterns/screenshot-evidence-pack.md`
> **Version:** 1.2.0 (V1.1A: Playwright CLI/runtime default route + target-repo-aware preflight)
> **Created:** 2026-05-22
> **Updated:** 2026-06-03
> **Status:** Active

## Purpose

Defines the structure and workflow for producing screenshot evidence packs that document visual changes before and after implementation. This ensures every visual change is reviewable, auditable, and reversible.

## Browser Route Selection

Run `bash .opencode/scripts/browser-verification-preflight.sh` before capturing evidence. The script selects the best available route:

| Route | Priority | When |
|---|---|---|
| Playwright MCP | 1st | When enabled in `.opencode/opencode.json` (OpenCode-integrated browser control) |
| **Playwright CLI/runtime** | **2nd** | **When repo-local Node Playwright is available with browser binaries installed (V1.1A default route)** |
| Python Playwright | 3rd | When browser binaries are installed in Python venv (fallback) |
| agent-browser | 4th | When CLI is available (basic visual evidence fallback) |
| NOT_RUN | Fallback | When no route is available — document exact blocker |

**V1.1A status:** Playwright CLI/runtime is the active default route when repo-local Playwright is detected. It provides multi-viewport screenshots, axe-core scanning, keyboard tests, ARIA snapshots, and visual diff automation. Playwright MCP is disabled. Python Playwright has a version mismatch but is a fallback-only route. agent-browser remains available as a last-resort fallback.

**Important distinction:**
- **Playwright browser/runtime** enables multi-viewport capture, axe-core scanning, keyboard tests, ARIA snapshots, and visual diff automation
- **Playwright MCP** enables OpenCode-integrated browser control (session-level integration, not the test runner itself)
- **agent-browser** provides basic desktop screenshot capture only — it cannot run axe, keyboard, ARIA, or visual diff tests

## When to Apply

Trigger when:
- Any visual change is made to a user-facing surface
- A UI pilot or polish pass is completed
- Before submitting a PR with visual changes
- When a stakeholder requests visual review

## Evidence Pack Structure

```
artifacts/visual-review-v<N>/
├── README.md                    # What changed and why
├── route.md                     # Browser route used + preflight output
├── before/                      # Screenshots before changes
│   ├── <page>-mobile.png
│   ├── <page>-tablet.png
│   └── <page>-desktop.png
├── after/                       # Screenshots after changes
│   ├── <page>-mobile.png
│   ├── <page>-tablet.png
│   └── <page>-desktop.png
├── diff/                        # Visual diffs (if available)
│   └── <page>-mobile-diff.png
└── axe-reports/                 # Accessibility reports
    ├── onboarding-axe.json
    └── today-axe.json
```

## Workflow — Playwright CLI/Runtime Route (V1.1A Default)

### 1. Run Preflight

```bash
# From target repo directory
bash ../.opencode/scripts/browser-verification-preflight.sh
# Confirm: Selected route: Playwright CLI/runtime

# Or from workspace root with explicit target
bash .opencode/scripts/browser-verification-preflight.sh <repo-name>
```

### 2. Capture Evidence

```bash
# Start dev server (if applicable)
pnpm dev

# Run Playwright visual snapshot tests
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts --project=chromium

# Run accessibility tests
pnpm exec playwright test tests/e2e/a11y-keyboard-smoke.spec.ts --project=chromium
pnpm exec playwright test tests/e2e/a11y-aria-snapshots.spec.ts --project=chromium
```

### 3. Document Evidence

Each test run in the evidence pack must include:

| Field | Example |
|---|---|
| `route` | `Playwright CLI/runtime (pnpm exec playwright v1.60.0)` |
| `viewport` | `mobile (390x844), tablet (768x1024), desktop (1440x900)` |
| `screenshot_path` | `tests/e2e/visual-snapshots.spec.ts-snapshots/today-mobile-chromium-linux.png` |
| `url` | `http://localhost:3004/today` |
| `timestamp` | `2026-06-03T18:32:00+08:00` |
| `command_used` | `pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts --project=chromium` |
| `console_errors` | `0 serious errors across all routes` |
| `axe_result` | `0 violations on onboarding and today pages` |

## Workflow — agent-browser Route (Fallback)

Use agent-browser only when Playwright CLI/runtime is not available for the target repo.

### 1. Run Preflight

```bash
bash .opencode/scripts/browser-verification-preflight.sh
# Confirm: Selected route: agent-browser
```

### 2. Capture Evidence

```bash
# Start dev server (if applicable)
pnpm dev

# Navigate and capture
agent-browser open http://localhost:<port>/<page>
agent-browser snapshot --json --screenshot before-<page>-desktop.png
agent-browser screenshot before-<page>-desktop.png

# For mobile viewport, use agent-browser's viewport option if available
# or note the viewport limitation in route.md
```

### 3. Document Evidence

Each screenshot entry in the evidence pack must include:

| Field | Example |
|---|---|
| `route` | `agent-browser 0.26.0 (fallback — Playwright not available)` |
| `viewport` | `desktop (default) — mobile/tablet NOT_RUN: agent-browser viewport limitation` |
| `screenshot_path` | `artifacts/visual-review-v1/before/landing-desktop.png` |
| `url` | `http://localhost:3000/` |
| `timestamp` | `2026-06-03T10:30:00+08:00` |
| `command_used` | `agent-browser open http://localhost:3000 && agent-browser screenshot landing-desktop.png` |
| `console_errors` | `agent-browser logs` output or "not captured — agent-browser limitation" |
| `limitations` | "agent-browser does not support multi-viewport capture in a single session" |

## Workflow — Playwright Route (When Available)

### 1. Capture Before State

```bash
# Start dev server
pnpm dev

# Run screenshot capture script
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts --reporter=list
```

### 2. Make Changes

Implement visual changes following the design system and accessibility constraints.

### 3. Capture After State

```bash
# Restart dev server to pick up changes
pnpm dev

# Run screenshot capture again
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts --reporter=list --update-snapshots
```

### 4. Review Diffs

Compare before/after screenshots. Accept only intentional changes.

### 5. Document

Update the README.md with:
- What changed
- Why it changed
- Which screenshots show the change
- Any known issues or trade-offs

## Screenshot Standards

### Viewport Matrix

| Viewport | Width | Height | Device Target | agent-browser Support |
|---|---|---|---|---|
| Mobile | 390px | 844px | iPhone 14 | ⚠️ Limited — document limitation |
| Tablet | 768px | 1024px | iPad | ⚠️ Limited — document limitation |
| Desktop | 1440px | 900px | Standard laptop | ✅ Full support |

### Screenshot Settings (Playwright)

```typescript
await expect(page).toHaveScreenshot("name.png", {
  maxDiffPixels: 100,        // Allow minor pixel differences
  threshold: 0.1,            // 10% color difference threshold
  fullPage: false,           // Capture viewport only
  animations: "disabled",    // Disable animations for consistency
  caret: "hide",             // Hide text caret
  scale: "device",           // Use device pixel ratio
});
```

### Timing

- Wait for network idle: `waitUntil: "networkidle"`
- Wait for hydration: `waitForTimeout(1000)`
- Wait for animations: `waitForTimeout(500)` after interactions

## Quality Checklist

- [ ] Browser route preflight run and documented in `route.md`
- [ ] Before screenshots captured at available viewports
- [ ] After screenshots captured at available viewports
- [ ] Viewport limitations documented (if agent-browser route)
- [ ] Diffs reviewed and intentional changes approved (if Playwright route)
- [ ] Accessibility preserved (axe 0 violations, if gate available)
- [ ] Performance not degraded (Lighthouse >= 85, if gate available)
- [ ] README.md updated with change documentation
- [ ] Evidence pack committed to artifacts/

## Related Patterns

- `visual-quality-gate.md` — Visual quality gate definition
- `executive-product-review-rubric.md` — Executive review scoring
- `a11y-production-gate.md` — Accessibility gate
