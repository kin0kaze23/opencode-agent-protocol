---
name: pencil-design
description: Pencil.dev design workflow — verified workflows for AI-powered UI/UX design
---

# Pencil Design Skill

> **Purpose:** Guide for using Pencil.dev with AI assistants  
> **Verified:** 2026-03-28 (tested all workflows)  
> **Official Docs:** https://docs.pencil.dev  
> **Evaluation:** `.opencode/plans/2026-03-28-pencil-workflow-evaluation.md`

---

## Verified Workflows

### Workflow 1: Pencil CLI Agent Mode ✅ RECOMMENDED

**Best for:** Creating designs programmatically, batch operations, reliable file persistence

```bash
# Create new design
pencil --out design.pen --prompt "Create a [SCREEN TYPE] with [SPECIFIC DETAILS]"

# Modify existing
pencil --in existing.pen --out modified.pen --prompt "Add [ELEMENT] and change [PROPERTY]"

# Export to PNG
pencil --in design.pen --export output.png --export-scale 2
```

**Why this works:**
- ✅ Saves to disk automatically
- ✅ Uses Pencil's built-in Claude agent
- ✅ No MCP configuration needed
- ✅ Reliable for production use

**Example:**
```bash
pencil --out onboarding-1.pen \
  --prompt "ONBOARDING SCREEN 1 of 4 - Welcome screen for demo-project meditation app.
  iOS 375x812. Large 'demo-project' logo in Lora serif 40px at top center,
  soft cyan gradient background #ECFEFF to white,
  headline 'Find Your Daily Peace' Lora 32px bold,
  subtitle 'Personalized devotionals for your spiritual journey' Raleway 16px,
  primary green button 'Begin Journey' #059669 rounded full,
  page indicator dots at bottom showing 1 of 4"
```

---

### Workflow 2: Cursor Pencil Extension + Cmd+K ✅

**Best for:** Real-time visual iteration in Cursor IDE

**Requirements:**
- Pencil extension installed in Cursor
- Claude Code CLI authenticated (`claude`)
- `.pen` file open in Cursor

**Steps:**
1. Open `.pen` file in Cursor (Pencil canvas appears)
2. Press `Cmd+K` (opens Claude Code prompt panel IN Pencil)
3. Type design prompt
4. Watch changes appear in real-time

**Why this works:**
- ✅ Real-time visual feedback
- ✅ Claude Code has native MCP access
- ✅ Changes saved via Pencil extension

**Note:** This uses Claude Code, NOT OpenCode

---

### Workflow 3: OpenCode MCP + Pencil Desktop ⚠️

**Best for:** OpenCode integration (with limitations)

**Configuration:**
```json
// ~/.opencode/mcp.json
{
  "mcpServers": {
    "pencil": {
      "command": "/Applications/Pencil.app/Contents/Resources/app.asar.unpacked/out/mcp-server-darwin-arm64",
      "args": ["--app", "desktop"],
      "enabled": true
    }
  }
}
```

**Verified:** 2026-03-28
- ✅ OpenCode can call Pencil MCP tools
- ✅ batch_design, get_screenshot, etc. all work
- ⚠️ **Changes don't persist to disk automatically**
- ⚠️ Requires Pencil Desktop App running
- ⚠️ Must manually save in Desktop App

**Example:**
```bash
opencode run --message "Add a green circle to design.pen"
```

**Limitation:** MCP changes stay in Pencil Desktop memory, don't write to `.pen` file on disk.

---

## What Doesn't Work Reliably

### ❌ Pencil CLI Interactive (Headless)
```bash
# This works but save() is unreliable
pencil interactive -i in.pen -o out.pen
# ...commands...
save()  # May create empty file
```

**Issue:** `save()` in headless mode often creates 0-byte files.

### ❌ OpenCode MCP without Pencil Desktop
- MCP tools require Pencil Desktop/Extension running
- Cannot use headless MCP server

---

## .pen File Format

Based on official docs: https://docs.pencil.dev/for-developers/the-pen-format

**Structure:**
```json
{
  "version": "2.9",
  "children": [
    {
      "id": "unique-id",
      "type": "frame|rectangle|text|ellipse|ref|...",
      "name": "Human-readable name",
      "width": 375,
      "height": 812,
      "fill": "#ECFEFF",
      "layout": "vertical|horizontal|none",
      "children": [...]
    }
  ]
}
```

**Key Concepts:**
- **Components:** Objects with `reusable: true`
- **Instances:** `ref` objects that reuse components
- **Overrides:** `descendants` property customizes instance children
- **Variables:** `$variable-name` for colors, numbers, strings
- **Themes:** Multiple theme values per variable

---

## MCP Tools Reference

Available when MCP is connected:

### Design Operations
| Tool | Purpose |
|------|---------|
| `batch_design` | Insert, update, delete, move, copy, replace nodes |
| `batch_get` | Search and read nodes by pattern or ID |
| `get_variables` | Read design variables |
| `set_variables` | Update design variables |
| `get_editor_state` | Get document metadata and structure |
| `snapshot_layout` | Get document structure with computed bounds |

### Visual Operations
| Tool | Purpose |
|------|---------|
| `get_screenshot` | Render a node to PNG image |
| `export_nodes` | Export nodes to PNG/JPEG/WEBP/PDF |

### Guidelines
| Tool | Purpose |
|------|---------|
| `get_guidelines` | Load design rules and styles |

---

## Effective Prompting

### ❌ Bad Prompts
```
"Make it better"
"Add a form"
"Fix the design"
```

### ✅ Good Prompts
```
"Create a login form with email input, password input,
remember me checkbox, and submit button. Use blue primary
color #3B82F6, 16px padding, 8px border radius."

"Add a navigation bar at the top with logo on left,
5 menu items in center, and user avatar on right.
Height 64px, sticky positioning."
```

### Prompt Templates

#### Create New Screen
```
Create a [SCREEN TYPE] for [APP NAME] with:
- Layout: [mobile-first/desktop/full-width]
- Background: [color/description]
- Header: [content and style]
- Main content: [sections and components]
- CTA buttons: [text, color, placement]
- Style: [minimal/bold/playful/professional]
Dimensions: [width]x[height]
```

#### Modify Existing Design
```
Modify [ELEMENT/SECTION] in design.pen:
- Change [property] from [value] to [value]
- Add [new element] at [position]
- Remove [element]
- Apply [style/design system]
- Maintain [constraint]
```

---

## Best Practices

### File Organization
```
project/
├── design.pen              # Main design file
├── design-system.pen       # Component library
├── screens/
│   ├── onboarding-1.pen
│   ├── home.pen
│   └── settings.pen
└── src/                    # Code implementation
```

### Design System First
1. Create design tokens (colors, typography, spacing)
2. Build reusable components (buttons, inputs, cards)
3. Use components in screens

### Iterative Workflow
1. Broad → Specific: "Create dashboard" → "Add sidebar" → "Style nav"
2. Export PNG previews for review
3. Commit .pen files to Git

---

## Troubleshooting

### "Pencil CLI not found"
```bash
npm install -g @pencil.dev/cli
pencil version
```

### "MCP server not found" (OpenCode)
```bash
# Check config
cat ~/.opencode/mcp.json | grep pencil

# Enable pencil
vi ~/.opencode/mcp.json  # Set "enabled": true

# Restart OpenCode
```

### "Changes not saving to disk"
- Use **Agent Mode** (`pencil --out X.pen --prompt "..."`)
- If using MCP, manually save in Pencil Desktop App

### "Pencil extension not showing in Cursor"
- Create/open a `.pen` file first
- Check extension is enabled
- Cmd+Shift+P → "Pencil: Open Design"

---

## Pencil CLI Best Practices

### Agent Mode (Recommended for Production)

**Always use these flags:**
```bash
# Basic creation
pencil --out design.pen --prompt "Create a [SCREEN] with [DETAILS]"

# With specific model (for cost/performance control)
pencil --out design.pen --model claude-haiku-4-5 --prompt "Simple 404 page"

# With export (create + preview in one command)
pencil --out screen.pen --prompt "Create home screen" --export screen.png --export-scale 2

# Modify existing (always specify --out to preserve original)
pencil --in existing.pen --out modified.pen --prompt "Add blue button"
```

**Model Selection Guide:**
| Model | When to Use | Cost |
|-------|-------------|------|
| `claude-opus-4-6` | Complex screens, detailed layouts | Highest |
| `claude-sonnet-4-6` | Standard screens, balanced quality | Medium |
| `claude-haiku-4-5` | Simple components, quick iterations | Lowest |

**Prompt Best Practices:**
```bash
# ✅ Good: Specific, structured
pencil --out login.pen --prompt "Create login screen with:
- Email input with placeholder
- Password input with show/hide toggle
- Sign In button (primary, full width)
- Forgot password link
- Social login: Google and GitHub
Dimensions: 375x812 (iOS)"

# ❌ Bad: Vague
pencil --out login.pen --prompt "Make a login page"
```

---

### Batch Processing (Multiple Screens)

**For creating multiple designs in one command:**

```json
// batch.json
{
  "tasks": [
    {"out": "onboarding-1.pen", "prompt": "Welcome screen..."},
    {"out": "onboarding-2.pen", "prompt": "Needs selection..."},
    {"out": "onboarding-3.pen", "prompt": "Preferences..."},
    {"out": "onboarding-4.pen", "prompt": "Complete..."}
  ]
}
```

```bash
# Process all
pencil --tasks batch.json

# Export all
for f in onboarding-*.pen; do pencil --in "$f" --export "${f%.pen}.png" --export-scale 2; done
```

---

### Export Best Practices

```bash
# Standard (1x)
pencil --in design.pen --export preview.png

# High quality (2x for retina)
pencil --in design.pen --export preview.png --export-scale 2

# Different formats
pencil --in design.pen --export design.jpeg --export-type jpeg
pencil --in design.pen --export design.webp --export-type webp
pencil --in design.pen --export design.pdf --export-type pdf
```

---

### CI/CD Usage

```bash
# Set CLI key (from Pencil web app Developer Keys)
export PENCIL_CLI_KEY=pencil_cli_xxx

# Run in pipeline
pencil --out design.pen --prompt "Create screen"
```

**Environment Variables:**
| Variable | Purpose |
|----------|---------|
| `PENCIL_CLI_KEY` | CLI API key (overrides session) |
| `ANTHROPIC_API_KEY` | Custom Anthropic API |
| `PENCIL_API_BASE` | Override API endpoint |
| `DEBUG` | Enable debug logging |

---

## Reference

- **Official Docs:** https://docs.pencil.dev
- **.pen Format:** https://docs.pencil.dev/for-developers/the-pen-format
- **CLI Reference:** https://docs.pencil.dev/for-developers/pencil-cli
- **AI Integration:** https://docs.pencil.dev/getting-started/ai-integration
- **Evaluation Report:** `.opencode/plans/2026-03-28-pencil-workflow-evaluation.md`

---

## Quick Start

```bash
# Install Pencil CLI
npm install -g @pencil.dev/cli
pencil login

# Create first design
pencil --out design.pen --prompt "Create a login screen with email and password"

# Export preview
pencil --in design.pen --export design.png

# Open in Cursor
# design.pen will show visual canvas with Pencil extension

## Output format

Produce a Pencil design report in this exact format:

```
## Pencil Design — <screen/component name>

**Tool:** <Pencil MCP / Pencil CLI>
**Output file:** <design.pen path>

### Design created
- <screen name>: <description>

### Operations performed
- <operation>: <details>

### Verification
- [ ] Design file created and valid
- [ ] Screenshots captured for key screens
- [ ] Style guide tags applied
- [ ] Exported preview images (if requested)
```

## Out of Scope

This skill does NOT:
- Replace hand-coding for simple components (use frontend-design/SKILL.md for code-first)
- Audit accessibility of designed screens (that is accessibility-audit/SKILL.md)
- Replace UI/UX design intelligence (that is ui-ux-pro-max/SKILL.md)
- Handle .pen file format validation details (that is pencil-pen-format/SKILL.md)
- Generate production-ready code from designs (that is /implement)
```
