# SVG marker mechanics and anti-protrusion standards

This reference specifies the geometry, mathematical formulas, and SVG definitions required to render clean, razor-sharp arrowheads on Apple-grade technical diagrams without stroke cap protrusion or awkward spacing.

---

## 1. The tip-anchored marker defect

In SVG, markers attached via `marker-end="url(#id)"` are positioned relative to the final coordinate `(x2, y2)` of a line or path using the marker's `refX` and `refY` attributes.

When `refX` is anchored to the tip of an arrowhead (for example, `refX="12"` when the tip is at $x=12$):
1. The underlying path's stroke is rendered all the way to `(x2, y2)`.
2. Path lines have physical thickness (e.g., `stroke-width="1.5"` or `2.0"`), which terminates in a flat square cap (`stroke-linecap: butt`) or rounded cap (`stroke-linecap: round`).
3. The sharp tip of the triangle marker has zero width at its apex.
4. Because the line stroke underneath is 1.5px–2px wide at the exact same coordinate, the squared end of the line extends past or blunts the apex of the triangle, creating an ugly protrusion defect:

```
❌ Tip-Anchored Marker Defect (refX = 12):
Line stroke extends all the way to apex ───────► █ <-- Square line end pokes through tip!

✅ Base-Anchored Marker (refX = 2):
Line stroke terminates inside base ──────► (Triangle body extends cleanly forward to apex)
```

---

## 2. The base-anchoring standard

To guarantee razor-sharp arrow tips across all SVG renderers:
1. Anchor `refX` at the **base** of the arrowhead ($x = 2$).
2. Let the arrowhead body extend forward from $x = 2$ to $x = 12$ (a length of exactly **10px**).
3. Use `markerUnits="userSpaceOnUse"` so the marker size is defined in absolute canvas pixels, preventing unexpected scaling when stroke widths change.
4. Add a subtle curved back (`C 3.5 9 3.5 5 2 2.5`) to create an authentic Apple-style acute pointer.

### Standard SVG definitions

```xml
<defs>
  <!-- Neutral Flow Arrowhead -->
  <marker id="arrow" viewBox="0 0 14 14" refX="2" refY="7" 
          markerUnits="userSpaceOnUse" markerWidth="14" markerHeight="14" orient="auto">
    <path d="M 2 2.5 L 12 7 L 2 11.5 C 3.5 9 3.5 5 2 2.5 Z" fill="#86868B" />
  </marker>

  <!-- Hero Accent Flow Arrowhead -->
  <marker id="hero-arrow" viewBox="0 0 14 14" refX="2" refY="7" 
          markerUnits="userSpaceOnUse" markerWidth="14" markerHeight="14" orient="auto">
    <path d="M 2 2.5 L 12 7 L 2 11.5 C 3.5 9 3.5 5 2 2.5 Z" fill="#0071E3" />
  </marker>

  <!-- Dark Mode Neutral Arrowhead -->
  <marker id="arrow-dark" viewBox="0 0 14 14" refX="2" refY="7" 
          markerUnits="userSpaceOnUse" markerWidth="14" markerHeight="14" orient="auto">
    <path d="M 2 2.5 L 12 7 L 2 11.5 C 3.5 9 3.5 5 2 2.5 Z" fill="#636366" />
  </marker>

  <!-- Dark Mode Hero Accent Arrowhead -->
  <marker id="hero-arrow-dark" viewBox="0 0 14 14" refX="2" refY="7" 
          markerUnits="userSpaceOnUse" markerWidth="14" markerHeight="14" orient="auto">
    <path d="M 2 2.5 L 12 7 L 2 11.5 C 3.5 9 3.5 5 2 2.5 Z" fill="#2997FF" />
  </marker>
</defs>
```

---

## 3. Breathing-room gap rules

Arrows should never collide directly with the border stroke of cards or containers. Always maintain **10px to 12px of breathing room**:
- A **10px–12px gap** between the exit border of the source box and the start of the arrow line.
- A **10px–12px gap** between the tip of the arrowhead and the entry border of the target box.

---

## 4. Direction-aware coordinate formulas

Because the arrowhead extends **10px forward** from the line's endpoint (`refX="2"` to tip `12`), line endpoints must account for arrow length:

$$\text{Arrow Length} = \text{tip} - \text{refX} = 12 - 2 = 10\text{px}$$

### 1. Pointing right ($\to$)
- Source box right edge: $x_{\text{source\_right}}$
- Target box left edge: $x_{\text{target\_left}}$
- Start point: $x_1 = x_{\text{source\_right}} + \text{gap}$
- Target tip position: $x_{\text{tip}} = x_{\text{target\_left}} - \text{gap}$
- Line endpoint: $x_2 = x_{\text{tip}} - 10 = x_{\text{target\_left}} - \text{gap} - 10$

*Example*: Source box ends at $x=200$, target box starts at $x=360$, gap = 12px:
- $x_1 = 200 + 12 = 212$
- $x_{\text{tip}} = 360 - 12 = 348$
- $x_2 = 348 - 10 = 338$
- `<line x1="212" y1="100" x2="338" y2="100" marker-end="url(#arrow)" />`

### 2. Pointing left ($\leftarrow$)
- Source box left edge: $x_{\text{source\_left}}$
- Target box right edge: $x_{\text{target\_right}}$
- Start point: $x_1 = x_{\text{source\_left}} - \text{gap}$
- Target tip position: $x_{\text{tip}} = x_{\text{target\_right}} + \text{gap}$
- Line endpoint: $x_2 = x_{\text{tip}} + 10 = x_{\text{target\_right}} + \text{gap} + 10$

*Example*: Source box leaves at $x=480$, target box right edge is at $x=480$, gap = 10px:
- $x_1 = 480 + 10 = 490$ (leaves going right, loops around)
- Target tip reaches $x=490$ (10px from card right edge 480)
- $x_2 = 490 + 10 = 500$
- `<path d="... L 500 140" marker-end="url(#arrow)" />`

### 3. Pointing down ($\downarrow$)
- Source box bottom edge: $y_{\text{source\_bottom}}$
- Target box top edge: $y_{\text{target\_top}}$
- Start point: $y_1 = y_{\text{source\_bottom}} + \text{gap}$
- Target tip position: $y_{\text{tip}} = y_{\text{target\_top}} - \text{gap}$
- Line endpoint: $y_2 = y_{\text{tip}} - 10 = y_{\text{target\_top}} - \text{gap} - 10$

*Example*: Target card top edge is at $y=196$, gap = 10px:
- $y_{\text{tip}} = 196 - 10 = 186$
- $y_2 = 186 - 10 = 176$
- `<path d="M 150 164 L 150 176" marker-end="url(#arrow)" />`

### 4. Pointing up ($\uparrow$)
- Source box top edge: $y_{\text{source\_top}}$
- Target box bottom edge: $y_{\text{target\_bottom}}$
- Start point: $y_1 = y_{\text{source\_top}} - \text{gap}$
- Target tip position: $y_{\text{tip}} = y_{\text{target\_bottom}} + \text{gap}$
- Line endpoint: $y_2 = y_{\text{tip}} + 10 = y_{\text{target\_bottom}} + \text{gap} + 10$
