---
name: pencil-pen-format
description: .pen Pencil format best practices — authoritative guide for creating valid Pencil design files
---

# Pencil .pen Format Best Practices

> **Purpose:** Authoritative guide for creating and manipulating .pen files via MCP  
> **Source:** Official Pencil docs (https://docs.pencil.dev/for-developers/the-pen-format)  
> **Version:** 2.9 (current .pen schema)  
> **For:** OpenCode MCP + Cursor Pencil extension workflow

---

## Document Structure

```json
{
  "version": "2.9",
  "themes": { ... },           // Optional: theme axes
  "imports": { ... },          // Optional: import other .pen files
  "variables": { ... },        // Optional: design tokens
  "children": [...]            // Required: top-level objects
}
```

### CRITICAL Rules

| Rule | Requirement | Example |
|------|-------------|---------|
| **ID uniqueness** | Every object MUST have unique `id` (no slashes) | `"id": "abc123"` ✅ |
| **ID generation** | If omitted, auto-generated | Let Pencil generate |
| **Type required** | Every object needs `type` field | `"type": "frame"` |
| **Position** | Top-level objects need `x`, `y` | `"x": 0, "y": 0` |
| **Parent-relative** | Nested objects positioned relative to parent | Inside frame at x:20 |

---

## Object Types Reference

### Frame (Container)

**Use for:** Screens, sections, layout containers

```javascript
// batch_design operation example
frame=I(document,{
  type:"frame",
  id:"mainScreen",
  name:"Home Screen",
  x:0,
  y:0,
  width:375,
  height:812,
  fill:"#ECFEFF",
  layout:"vertical",
  gap:24,
  padding:[24,24,24,24],
  justifyContent:"start",
  alignItems:"center",
  clip:false,
  children:[
    // child elements here
  ]
})
```

**Key Properties:**
| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `layout` | `"none"|"vertical"|"horizontal"` | `"none"` | Flexbox layout |
| `gap` | number | `0` | Space between children |
| `padding` | number|[number,number]|[number,number,number,number] | Inside spacing |
| `justifyContent` | `"start"|"center"|"end"|"space_between"|"space_around"` | `"start"` | Main axis alignment |
| `alignItems` | `"start"|"center"|"end"` | `"start"` | Cross axis alignment |
| `clip` | boolean | `false` | Clip overflow content |

**⚠️ IMPORTANT:** When parent uses `layout`, children's `x` and `y` are IGNORED. Use flexbox properties instead.

---

### Rectangle

**Use for:** Buttons, backgrounds, dividers, cards

```javascript
rect=I(parentId,{
  type:"rectangle",
  id:"submitBtn",
  name:"Submit Button",
  width:327,
  height:56,
  fill:"#059669",
  cornerRadius:28,
  stroke:{
    align:"inside",
    thickness:2,
    fill:"#047857"
  },
  effect:[
    {
      type:"shadow",
      shadowType:"outer",
      offset:{x:0,y:2},
      blur:4,
      spread:0,
      color:"rgba(0,0,0,0.1)"
    }
  ]
})
```

**Key Properties:**
| Property | Type | Description |
|----------|------|-------------|
| `cornerRadius` | number | Border radius (use 9999 for pill/circle) |
| `fill` | string | Color, gradient, or variable |
| `stroke` | object | Border configuration |
| `effect` | array | Shadows, blurs |

---

### Text

**Use for:** Headlines, labels, paragraphs, buttons

```javascript
text=I(parentId,{
  type:"text",
  id:"headline",
  name:"Main Headline",
  content:"Find Your Daily Peace",
  fontFamily:"Lora",
  fontSize:32,
  fontWeight:"700",
  fill:"#1F2937",
  textAlign:"center",
  textAlignVertical:"middle",
  lineHeight:1.2,
  textGrowth:"fixed-width",
  width:"fill_container"
})
```

**⚠️ CRITICAL: textGrowth Property**

MUST set `textGrowth` BEFORE using `width` or `height`:

| Value | Behavior |
|-------|----------|
| `"auto"` | Box grows with text, no wrap |
| `"fixed-width"` | Width fixed, text wraps, height grows |
| `"fixed-width-height"` | Both fixed, text may overflow |

**Without textGrowth, width/height are IGNORED!**

**Text Styling Properties:**
| Property | Type | Example |
|----------|------|---------|
| `fontFamily` | string | `"Lora"`, `"Inter"`, `"Raleway"` |
| `fontSize` | number | `16`, `24`, `32` |
| `fontWeight` | string | `"400"`, `"600"`, `"700"` |
| `letterSpacing` | number | `0.5`, `-0.5` |
| `lineHeight` | number | `1.2`, `1.5` (multiplier) |
| `textAlign` | `"left"|"center"|"right"|"justify"` | `"center"` |
| `textAlignVertical` | `"top"|"middle"|"bottom"` | `"middle"` |
| `underline` | boolean | `true`, `false` |
| `strikethrough` | boolean | `true`, `false` |

---

### Ellipse (Circle/Ring)

**Use for:** Profile pictures, loading spinners, decorative elements

```javascript
ellipse=I(parentId,{
  type:"ellipse",
  id:"avatar",
  name:"User Avatar",
  width:80,
  height:80,
  fill:"#3B82F6",
  innerRadius:0,          // 0 = solid, 0.5 = ring
  startAngle:0,           // Start angle in degrees
  sweepAngle:360          // Arc length (negative = clockwise)
})
```

---

### Icon (Font-based)

**Use for:** Navigation icons, action buttons, status indicators

```javascript
icon=I(parentId,{
  type:"icon_font",
  id:"settingsIcon",
  name:"Settings",
  width:24,
  height:24,
  iconFontFamily:"lucide",
  iconFontName:"settings",
  fill:"#6B7280",
  weight:400
})
```

**Supported Icon Fonts:**
- `"lucide"` (recommended)
- `"feather"`
- `"Material Symbols Outlined"`
- `"Material Symbols Rounded"`
- `"Material Symbols Sharp"`
- `"phosphor"`

**Find icons:** Browse font websites (lucide.dev, phosphoricons.com)

---

### Ref (Component Instance)

**Use for:** Reusing components (buttons, cards, nav items)

```javascript
// First, create a reusable component
button=I(document,{
  type:"frame",
  id:"primaryButton",
  reusable:true,          // ← Mark as reusable component
  layout:"horizontal",
  width:327,
  height:56,
  fill:"#059669",
  cornerRadius:28,
  alignItems:"center",
  justifyContent:"center",
  children:[
    {
      type:"text",
      id:"label",
      content:"Submit",
      fill:"#FFFFFF"
    }
  ]
})

// Then create instances
btn1=I(document,{
  type:"ref",
  ref:"primaryButton",    // ← Reference component
  x:0,
  y:100
})

// Override properties on instance
btn2=I(document,{
  type:"ref",
  ref:"primaryButton",
  x:0,
  y:180,
  fill:"#3B82F6"          // ← Override fill
})

// Override descendant (nested child)
btn3=I(document,{
  type:"ref",
  ref:"primaryButton",
  descendants:{
    label:{
      content:"Cancel"    // ← Override child's content
    }
  }
})
```

**Instance Customization:**

1. **Property Override:** Change inherited properties
```javascript
descendants:{
  childId:{
    fill:"#FF0000"        // Override fill only
  }
}
```

2. **Object Replacement:** Replace entire child
```javascript
descendants:{
  label:{
    id:"icon",
    type:"icon_font",     // ← type indicates replacement
    iconFontFamily:"lucide",
    icon:"check"
  }
}
```

3. **Nested Override:** Path notation for deep nesting
```javascript
descendants:{
  "sidebar/content/home-button/label":{
    content:"Dashboard"
  }
}
```

---

## Variables & Themes

### Design Tokens

```json
{
  "variables": {
    "color.primary": {
      "type": "color",
      "value": "#059669"
    },
    "color.background": {
      "type": "color",
      "value": "#ECFEFF"
    },
    "spacing.md": {
      "type": "number",
      "value": 16
    },
    "font.heading": {
      "type": "string",
      "value": "Lora"
    }
  },
  "children": [
    {
      "type": "frame",
      "fill": "$color.primary",        // ← Use variable
      "padding": "$spacing.md"
    }
  ]
}
```

### Themed Variables

```json
{
  "themes": {
    "mode": ["light", "dark"],
    "spacing": ["regular", "condensed"]
  },
  "variables": {
    "color.background": {
      "type": "color",
      "value": [
        { "value": "#FFFFFF", "theme": { "mode": "light" } },
        { "value": "#1F2937", "theme": { "mode": "dark" } }
      ]
    }
  },
  "children": [
    {
      "type": "frame",
      "fill": "$color.background"     // Auto-resolves based on theme
    },
    {
      "type": "frame",
      "theme": { "mode": "dark" },    // Force dark theme for subtree
      "fill": "$color.background"     // = "#1F2937"
    }
  ]
}
```

**Theme Resolution:** Last matching theme wins. Default is first value in themes array.

---

## Graphics Properties

### Fills

**Solid Color:**
```javascript
fill: "#3B82F6"
// OR
fill: {
  type: "color",
  color: "#3B82F6",
  blendMode: "normal"
}
```

**Gradient:**
```javascript
fill: {
  type: "gradient",
  gradientType: "linear",     // "linear"|"radial"|"angular"
  rotation: 90,               // Degrees, counter-clockwise
  colors: [
    { color: "#3B82F6", position: 0 },
    { color: "#8B5CF6", position: 1 }
  ]
}
```

**Image:**
```javascript
fill: {
  type: "image",
  url: "./background.png",    // Relative to .pen file
  mode: "fit"                 // "stretch"|"fill"|"fit"
}
```

### Strokes

```javascript
stroke: {
  align: "inside",            // "inside"|"center"|"outside"
  thickness: 2,
  join: "round",              // "miter"|"bevel"|"round"
  cap: "round",               // "none"|"round"|"square"
  fill: "#047857",
  dashPattern: [8, 4]         // Optional: dashed line
}
```

### Effects

**Drop Shadow:**
```javascript
effect: [
  {
    type: "shadow",
    shadowType: "outer",      // "inner"|"outer"
    offset: { x: 0, y: 4 },
    blur: 8,
    spread: 0,
    color: "rgba(0,0,0,0.1)",
    blendMode: "normal"
  }
]
```

**Blur:**
```javascript
effect: [
  {
    type: "blur",
    radius: 8
  }
]
```

**Background Blur:**
```javascript
effect: [
  {
    type: "background_blur",
    radius: 16
  }
]
```

---

## Layout Best Practices

### Mobile-First Screen (iOS)

```javascript
screen=I(document,{
  type:"frame",
  id:"mobileScreen",
  width:375,                // iPhone width
  height:812,               // iPhone height
  layout:"vertical",
  padding:[24,24,24,24],
  gap:24,
  children:[
    // Header
    {
      type:"frame",
      id:"header",
      width:"fill_container",
      height:64,
      layout:"horizontal",
      justifyContent:"space_between",
      alignItems:"center"
    },
    // Content (grows to fill)
    {
      type:"frame",
      id:"content",
      width:"fill_container",
      height:"fill_container",
      layout:"vertical",
      gap:16
    }
  ]
})
```

### Responsive Button Row

```javascript
buttonRow=I(parentId,{
  type:"frame",
  layout:"horizontal",
  gap:16,
  width:"fill_container",
  justifyContent:"center",   // Center buttons
  children:[
    // Buttons here
  ]
})
```

### Card Grid (2 columns)

```javascript
cardGrid=I(parentId,{
  type:"frame",
  layout:"vertical",
  gap:16,
  children:[
    {
      type:"frame",
      layout:"horizontal",
      gap:16,
      children:[
        { type:"frame", width:"fill_container", ... },  // Card 1
        { type:"frame", width:"fill_container", ... }   // Card 2
      ]
    },
    // More rows...
  ]
})
```

---

## MCP batch_design Operations

### Insert (I)

```javascript
// Insert into document root
node=I(document,{type:"frame",...})

// Insert into parent
child=I(parentId,{type:"text",...})

// With binding for later reference
button=I("content",{type:"frame",name:"Button",...})
```

### Update (U)

```javascript
// Update existing node
U("nodeId",{fill:"#FF0000",width:200})

// Update nested in component instance
U("instanceId/childId",{content:"New text"})
```

### Replace (R)

```javascript
// Replace entire node
newChild=R("parentId",{type:"text",content:"Replaced"})

// Replace child in instance
R("instanceId/slotId",{type:"ref",ref:"newComponent"})
```

### Move (M)

```javascript
// Move to different parent
M("nodeId","newParentId")

// Move to specific index
M("nodeId","parentId",0)    // Move to first position
```

### Delete (D)

```javascript
D("nodeId")
```

### Copy (C)

```javascript
// Copy with new parent
copied=C("sourceId","parentId")

// Copy with modifications
copied=C("sourceId","parentId",{
  descendants:{
    "childId":{fill:"#FF0000"}
  }
})
```

---

## Common Patterns

### Status Bar (iOS)

```javascript
statusBar=I(screenId,{
  type:"frame",
  id:"statusBar",
  width:"fill_container",
  height:44,
  layout:"horizontal",
  justifyContent:"space_between",
  alignItems:"center",
  padding:[0,20,0,20],
  children:[
    {type:"text",id:"time",content:"9:41",fontSize:15,fontWeight:"600"},
    {
      type:"frame",
      layout:"horizontal",
      gap:5,
      children:[
        {type:"icon_font",iconFontFamily:"lucide",iconFontName:"signal"},
        {type:"icon_font",iconFontFamily:"lucide",iconFontName:"wifi"},
        {type:"icon_font",iconFontFamily:"lucide",iconFontName:"battery-full"}
      ]
    }
  ]
})
```

### Primary Button

```javascript
primaryBtn=I(parentId,{
  type:"frame",
  layout:"horizontal",
  width:327,               // 375 - 48 padding
  height:56,
  fill:"#059669",
  cornerRadius:28,         // Half of height = pill shape
  alignItems:"center",
  justifyContent:"center",
  children:[
    {
      type:"text",
      content:"Continue",
      fill:"#FFFFFF",
      fontSize:18,
      fontWeight:"600"
    }
  ]
})
```

### Input Field

```javascript
inputField=I(parentId,{
  type:"frame",
  width:"fill_container",
  height:56,
  fill:"#FFFFFF",
  cornerRadius:12,
  stroke:{align:"inside",thickness:1,fill:"#E5E7EB"},
  padding:[0,16,0,16],
  layout:"horizontal",
  alignItems:"center",
  children:[
    {
      type:"text",
      content:"Email",
      fill:"#6B7280",
      fontSize:16
    }
  ]
})
```

### Card Component

```javascript
card=I(parentId,{
  type:"frame",
  width:"fill_container",
  layout:"vertical",
  gap:12,
  fill:"#FFFFFF",
  cornerRadius:16,
  padding:24,
  effect:[
    {
      type:"shadow",
      shadowType:"outer",
      offset:{x:0,y:2},
      blur:8,
      color:"rgba(0,0,0,0.08)"
    }
  ],
  children:[
    {type:"text",id:"title",fontSize:18,fontWeight:"700"},
    {type:"text",id:"description",fontSize:14,fill:"#6B7280"}
  ]
})
```

---

## Validation Checklist

Before finalizing any .pen file:

- [ ] All IDs are unique (no duplicates)
- [ ] No IDs contain slash (`/`) character
- [ ] Every object has `type` field
- [ ] Text elements have `textGrowth` set
- [ ] Flexbox parents don't rely on child `x`/`y`
- [ ] Colors are valid hex (6 or 8 digits)
- [ ] Variables use `$` prefix when referenced
- [ ] Component instances use correct `ref` ID
- [ ] Nested descendant paths use `/` separator
- [ ] Version is `"2.9"`

---

## Common Mistakes to Avoid

| Mistake | Problem | Fix |
|---------|---------|-----|
| Setting `width`/`height` without `textGrowth` | Ignored on text | Always set `textGrowth` first |
| Using `x`/`y` in flexbox parent | Ignored | Use `layout`, `gap`, `padding` |
| Duplicate IDs | Unpredictable behavior | Ensure unique IDs |
| ID contains `/` | Breaks descendant paths | Use alphanumeric only |
| Wrong variable syntax | Not resolved | Use `$variableName` |
| Missing `type` in descendant override | Treated as property override | Include `type` for replacement |

---

## Reference

- **Official Schema:** https://docs.pencil.dev/for-developers/the-pen-format
- **TypeScript Schema:** See bottom of official docs
- **CLI Reference:** https://docs.pencil.dev/for-developers/pencil-cli

## Output format

Produce a .pen file validation report in this exact format:

```
## .pen File Report — <file name>

**File:** <path>
**Version:** <pen format version>

### Structure
- Total nodes: <count>
- Reusable components: <count>
- Screens: <count>

### Validation
- [ ] All IDs unique
- [ ] No IDs contain '/' character
- [ ] Every object has 'type' field
- [ ] Text elements have 'textGrowth' set
- [ ] Flexbox parents don't use child x/y
- [ ] Colors are valid hex
- [ ] Variables use '$' prefix
- [ ] Version is "2.9"

### Issues found
- <issue>: <location and fix>
```

## Out of Scope

This skill does NOT:
- Create designs from scratch (that is pencil-design/SKILL.md)
- Replace the official Pencil documentation for API usage
- Handle runtime Pencil MCP operations (use pencil-design/SKILL.md)
- Generate UI code from .pen files (that is /implement)
- Audit the visual quality of designs (that is ui-ux-pro-max/SKILL.md)
- **MCP Tools:** https://docs.pencil.dev/for-developers/mcp-tools
