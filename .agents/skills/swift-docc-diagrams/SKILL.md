---
name: swift-docc-diagrams
description: Design system, geometry standards, and SVG engineering rules for Apple-grade DocC technical diagrams with Cupertino color palette and dark mode asset pairing.
---

# Swift DocC Cupertino Vector Diagrams

- Maintain a minimum 10px anti-overflow margin inside the SVG `viewBox` bounding box.
- Use the Cupertino semantic color palette and provide light and dark mode SVG variants (`diagram.svg` and `diagram~dark.svg`).
- Keep typography legible with SF Pro / system-ui fonts and clean orthogonal connector routing.

---

# Swift DocC technical diagram design system

This skill establishes the engineering rules, geometric formulas, typography standards, color palettes, and SVG marker mechanics required to design technical diagrams that match Apple's official developer documentation and *Develop in Swift* interactive tutorials.

# References
- `references/marker-mechanics.md`: Consult when creating, editing, or calculating arrowhead markers, connector paths, breathing-room gaps, or eliminating line protrusion defects through arrow tips.
- `references/topologies-and-geometry.md`: Consult when constructing standard diagrams (linear pipelines, fan-out trees, bidirectional loops, or device wireframes) for copy-pasteable SVG coordinate blueprints.
- `references/typography-and-bounding-boxes.md`: Consult when determining card widths, calculating the 10px rule, formatting multiline `<tspan>` labels, or ensuring continuous squircle corners.

---

## 1. Cupertino technical color palette and aesthetics

Apple technical diagrams communicate system architecture with visual restraint, high contrast, and photographic clarity. Diagrams serve as conceptual scaffolding, not decorative illustrations.

```
┌───────────────────────────────────────────────────────────────────────────┐
│                    Cupertino technical palette principles                 │
├───────────────────────────────────────────────────────────────────────────┤
│ • 90% monochromatic neutral scaffolding (white/gray cards & subtle borders│
│ • Single purposeful hero accent (Apple System Blue #0071E3 / #2997FF)     │
│ • Strictly forbidden: "traffic-light" multi-color palettes (red/green/etc)│
│ • Dual appearance: every graphic must pair diagram.svg & diagram~dark.svg│
└───────────────────────────────────────────────────────────────────────────┘
```

### Color tokens reference

Always use these semantic tokens across SVG styles:

| Component | Light appearance | Dark appearance | Purpose |
| :--- | :--- | :--- | :--- |
| **Canvas background** | `#FFFFFF` | `#000000` | Full diagram canvas backdrop |
| **Card background** | `#F5F5F7` | `#1C1C1E` | High-legibility component container |
| **Hero card background** | `#F5F5F7` | `#1C1C1E` | Focused active container |
| **Card border** | `#E5E5EA` | `#38383A` | Subtle 1.5px structural container border |
| **Hero card border** | `#0071E3` | `#2997FF` | 2px focal container border |
| **Primary label** | `#1D1D1F` | `#F5F5F7` | Component titles, card headers (weight 600) |
| **Hero label** | `#0071E3` | `#2997FF` | Active component titles (weight 600) |
| **Secondary label** | `#86868B` | `#98989D` | Subtitles, footnotes, type descriptors (weight 400) |
| **Badge background** | `#E5E5EA` | `#38383A` | Step number badge or icon backing |
| **Hero badge background**| `#0071E3` | `#2997FF` | Active step badge backing |
| **Connector stroke** | `#86868B` | `#636366` | Flow arrows and associations (1.5px stroke) |
| **Hero connector stroke**| `#0071E3` | `#2997FF` | Primary active data flow (1.5px stroke) |

---

## 2. Defensive bounding-box sizing and typography

Because SVG text rendering varies across OS platforms and font engines (San Francisco on macOS/iOS, Roboto on Linux, Segoe UI on Windows), fixed-size text boxes frequently cause text to overflow border edges.

### The 10px rule

To guarantee that text labels never spill over SVG container boundaries regardless of the user's rendering engine, apply the **10px rule**:

$$\text{rectWidth} = (\text{maxLineCharacters} \times 10) + 32\text{px}$$

- Allocate **10px of width per character** for the longest line of text inside the container (assuming a standard 14–15px base font).
- Add **32px of total horizontal padding** (16px on the left, 16px on the right).
- Example: For a label with 22 characters (*"@Observable class model"*):
  $$\text{rectWidth} = (22 \times 10) + 32 = 252\text{px} \longrightarrow 260\text{px}$$

### Stacked `<tspan>` and centered geometry

Never render long, multi-word diagram labels as a single un-wrapped `<text>` element.
- Always use `text-anchor="middle"` with the card's horizontal center coordinate ($x = \text{rectX} + \text{rectWidth}/2$).
- Stack multi-line labels using `<tspan>` with relative vertical offsets (`dy="1.4em"`).
- Keep individual lines under 24 characters.

```xml
<text x="360" y="137" class="card-title">
  <tspan x="360" dy="0">State model</tspan>
  <tspan x="360" dy="1.4em" class="card-sub">@Observable source of truth</tspan>
</text>
```

### Presentation attributes for continuous corners

In WebKit (Safari, Xcode Documentation viewer, DocC web rendering), SVG presentation attributes like `rx` and `ry` placed inside a CSS `<style>` block are often ignored. 

**Always specify `rx` and `ry` directly on `<rect>` tags**:
```xml
<!-- ❌ May render with sharp 90-degree corners in WebKit -->
<rect x="40" y="105" width="220" height="130" class="card-bg" />

<!-- ✅ Guaranteed continuous rounded corners across all platforms -->
<rect x="40" y="105" width="220" height="130" rx="16" ry="16" class="card-bg" />
```

Standard corner radiuses:
- Component cards: `rx="14"` or `rx="16"`
- Outer device frames: `rx="24"` or `rx="28"`
- Badges and pills: `rx="6"` to `rx="21"` (pill half-height)

---

## 3. Arrowhead marker engineering and anti-protrusion standards

In SVG, default markers scale with line stroke width (`markerUnits="strokeWidth"`), and placing the alignment anchor at the tip (`refX = tip`) causes a severe rendering defect: **the line's square stroke cap protrudes right through the sharp tip of the triangle**.

```
❌ Tip-Anchored Marker Defect:
Line stroke extends to tip ───────────────► █ <-- Square line end pokes through tip!

✅ Base-Anchored Marker:
Line stroke terminates here ───► (Arrowhead body extends cleanly forward to tip)
```

### The base-anchoring rule

To eliminate line protrusion and ensure razor-sharp arrow tips, anchor the marker at the **base** of the arrowhead (`refX="2"`):

```xml
<defs>
  <!-- Neutral Flow Arrowhead: refX=2 stops line stroke at base -->
  <marker id="arrow" viewBox="0 0 14 14" refX="2" refY="7" markerUnits="userSpaceOnUse" markerWidth="14" markerHeight="14" orient="auto">
    <path d="M 2 2.5 L 12 7 L 2 11.5 C 3.5 9 3.5 5 2 2.5 Z" class="arrowhead" />
  </marker>

  <!-- Hero Accent Flow Arrowhead -->
  <marker id="hero-arrow" viewBox="0 0 14 14" refX="2" refY="7" markerUnits="userSpaceOnUse" markerWidth="14" markerHeight="14" orient="auto">
    <path d="M 2 2.5 L 12 7 L 2 11.5 C 3.5 9 3.5 5 2 2.5 Z" class="hero-arrowhead" />
  </marker>
</defs>
```

- `markerUnits="userSpaceOnUse"`: Fixes the marker size to exactly 14px $\times$ 14px regardless of line stroke thickness.
- `refX="2"`: The line terminates at $x=2$ (inside the base of the arrowhead).
- Arrow length: The tip is at $x=12$. From base ($x=2$) to tip ($x=12$), the arrowhead extends **10px forward**.
- Curved back (`C 3.5 9 3.5 5 2 2.5`): Produces an authentic, elegant Apple-style acute pointer.

### The breathing-room gap rule (10px–12px)

Never connect an arrow line directly to the border of a box. Always maintain **10px to 12px of breathing room**:
- 10px–12px gap between the source box and the start of the arrow shaft.
- 10px–12px gap between the tip of the arrowhead and the target box.

### Direction-aware coordinate formulas

Since the arrowhead extends 10px forward from the line's endpoint (`refX="2"` to tip `12`), calculate line endpoints according to direction:

| Direction | Source exit point | Target entry point | Line endpoint formula | Tip location |
| :--- | :--- | :--- | :--- | :--- |
| **Pointing right ($\to$)** | $x_1 = x_{\text{source}} + \text{gap}$ | $x_{\text{target}}$ | $x_2 = (x_{\text{target}} - \text{gap}) - 10$ | $x_2 + 10$ |
| **Pointing left ($\leftarrow$)** | $x_1 = x_{\text{source}} - \text{gap}$ | $x_{\text{target}}$ | $x_2 = (x_{\text{target}} + \text{gap}) + 10$ | $x_2 - 10$ |
| **Pointing down ($\downarrow$)** | $y_1 = y_{\text{source}} + \text{gap}$ | $y_{\text{target}}$ | $y_2 = (y_{\text{target}} - \text{gap}) - 10$ | $y_2 + 10$ |
| **Pointing up ($\uparrow$)** | $y_1 = y_{\text{source}} - \text{gap}$ | $y_{\text{target}}$ | $y_2 = (y_{\text{target}} + \text{gap}) + 10$ | $y_2 - 10$ |

---

## 4. Standard architectural topology blueprints

### Topology 1: Linear processing pipeline
Used for sequential data processing, compilation steps, or layer stacks.

```xml
<!-- Gap = 50px between cards. Margin = 12px on each side. -->
<!-- Card 1 right edge: 260. Card 2 left edge: 310. -->
<path d="M 272 170 L 288 170" class="connector" marker-end="url(#arrow)" />
```

### Topology 2: Tree / fan-out branching
Used for single source of truth, model-to-view distribution, or hierarchical routing.

```xml
<!-- Stem leaves central pill with 10px gap -->
<path d="M 380 148 L 380 164" class="connector" />
<path d="M 150 164 L 610 164" class="connector" />
<!-- Drop lines stop 10px before card top (card y = 196) -->
<path d="M 150 164 L 150 176" class="connector" marker-end="url(#arrow)" />
<path d="M 380 164 L 380 176" class="connector" marker-end="url(#arrow)" />
<path d="M 610 164 L 610 176" class="connector" marker-end="url(#arrow)" />
```

### Topology 3: Bidirectional cyclic feedback loop
Used for unidirectional data flow (state flowing down, user actions flowing up).

```xml
<!-- Downward branch (Hero Blue): leaves top card at 230, enters bottom at 220 (tip reaches 230) -->
<path d="M 230 140 L 170 140 L 170 270 L 220 270" class="hero-connector" marker-end="url(#hero-arrow)" />
<!-- Upward branch (Neutral): leaves bottom card at 490, enters top at 500 (tip reaches 490) -->
<path d="M 490 270 L 550 270 L 550 140 L 500 140" class="connector" marker-end="url(#arrow)" />
```

### Topology 4: Adaptive device mockups
Used for chapter preview cards and multi-column navigation wireframes.
- Outer iPad frame: `rx="28" ry="28"`, subtle drop shadow.
- Sidebar column: `rx="18" ry="18"`, hero pill selection indicator (`#0071E3`).
- Content grid: rounded card placeholders (`rx="16" ry="16"`).

---

## 5. Dark mode asset pairing and deployment

DocC features native appearance-aware asset resolution using the `~dark` filename convention:

```
Sources/MyTarget/MyTarget.docc/Resources/images/
├── flow-overview.svg          # Light appearance variant
└── flow-overview~dark.svg     # Dark appearance variant
```

In your tutorial or article markdown, reference only the base filename:
```markdown
@Image(source: "flow-overview.svg", alt: "Data flow architecture diagram connecting persistent storage to views.")
```
DocC automatically switches to `flow-overview~dark.svg` when the system or browser prefers dark mode.

---

## 6. Vector diagram quality checklist

Before adding an SVG diagram to your `.docc` catalog:
- [ ] All titles, subtitles, card headers, and captions are written in **strict sentence case**.
- [ ] Every container card width satisfies the 10px rule: $\text{rectWidth} \ge (\text{maxChars} \times 10) + 32\text{px}$.
- [ ] Multiline labels use centered `text-anchor="middle"` with stacked `<tspan dy="1.4em">`.
- [ ] Corner radiuses (`rx` and `ry`) are defined as direct presentation attributes on `<rect>` tags.
- [ ] Palette adheres to Cupertino standards: 90% neutral scaffolding + single hero accent (`#0071E3`).
- [ ] Zero "traffic-light" (red/green) multi-colored connectors.
- [ ] Arrowhead markers use base-anchoring (`refX="2"`, `markerUnits="userSpaceOnUse"`).
- [ ] Zero line stroke protrusion through arrowhead tips.
- [ ] Connectors maintain 10px–12px breathing-room gaps from source and target boxes.
- [ ] Paired `~dark.svg` companion asset exists with verified dark appearance tokens.
