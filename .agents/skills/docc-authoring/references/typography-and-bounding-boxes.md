# Typography and defensive bounding-box sizing

This reference specifies typography metrics, mathematical anti-overflow calculations, and layout rules for Apple DocC vector diagrams.

---

## 1. Cross-platform font metrics and the overflow hazard

SVG renders text using the host system's installed fonts and text rasterizer:
- **macOS / iOS / iPadOS**: San Francisco Pro (`-apple-system, BlinkMacSystemFont, "SF Pro Text"`)
- **Linux / Android**: Roboto / Ubuntu / Liberation Sans
- **Windows**: Segoe UI / Arial

Different font rasterizers allocate varying character widths and kerning pairs. For example, the character `W` or `M` occupies significantly more horizontal space in Segoe UI than in SF Pro Text. When diagram cards are sized tightly around macOS-rendered text, the text spills over the card border on Windows or Linux browsers.

---

## 2. Mathematical formula: The 10px rule

To guarantee zero overflow across all platforms and font engines:

$$\text{rectWidth} = (\text{maxLineCharacters} \times 10) + 32\text{px}$$

### Derivation
1. **10px per character**:
   At the standard diagram base size of 14px–15px, the average character width in proportional sans-serif fonts is ~7.5px–8.2px. Allocating 10px per character provides an intentional ~20% safety margin that absorbs wider characters (`W`, `M`, `@`) and variations in font rasterizers.
2. **32px horizontal padding**:
   16px margin on the left border + 16px margin on the right border. This ensures text never touches the container's rounded corner radiuses.

### Sizing calculation lookup

| Longest label line | Characters | Minimum formula width | Recommended card width |
| :--- | :--- | :--- | :--- |
| `"User action"` | 11 chars | $(11 \times 10) + 32 = 142\text{px}$ | `160px` |
| `"Persistent store"` | 16 chars | $(16 \times 10) + 32 = 192\text{px}$ | `200px` – `220px` |
| `"SwiftData and SQLite"` | 19 chars | $(19 \times 10) + 32 = 222\text{px}$ | `230px` – `240px` |
| `"@Observable class model"` | 22 chars | $(22 \times 10) + 32 = 252\text{px}$ | `260px` |
| `"Declarative UI updates"` | 22 chars | $(22 \times 10) + 32 = 252\text{px}$ | `260px` |

---

## 3. Stacked `<tspan>` and vertical rhythm

Never place multiline text inside a single `<text>` element without explicit lines.
- Always use `text-anchor="middle"`.
- Set the base `<text>` element's `x` coordinate to the center of the card ($x = \text{rectX} + \text{rectWidth}/2$).
- Anchor the first `<tspan>` at `dy="0"`.
- Offset subsequent `<tspan>` elements with `dy="1.4em"` (for subtitles) or `dy="1.3em"` (for footnotes).

```xml
<text x="360" y="137" class="card-hero-title">
  <tspan x="360" dy="0">State model</tspan>
  <tspan x="360" dy="1.4em" class="card-sub">@Observable source of truth</tspan>
</text>
```

---

## 4. Typography hierarchy tokens

| Role | Font size | Font weight | Light color | Dark color | Text anchor |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Kicker** | `11px` | `600` (letter-spacing: 0.08em) | `#86868B` | `#98989D` | `middle` |
| **Header title** | `22px` | `700` | `#1D1D1F` | `#F5F5F7` | `middle` |
| **Header subtitle** | `13px` | `400` | `#86868B` | `#98989D` | `middle` |
| **Card title** | `15px` | `600` | `#1D1D1F` | `#F5F5F7` | `middle` |
| **Card hero title** | `15px` | `600` | `#0071E3` | `#2997FF` | `middle` |
| **Card subtitle** | `13px` | `400` | `#86868B` | `#98989D` | `middle` |
| **Badge number** | `12px` | `600` | `#1D1D1F` / `#FFFFFF` | `#F5F5F7` / `#FFFFFF` | `middle` |

---

## 5. WebKit continuous squircle corners

In SVG specifications, `rx` and `ry` define corner rounding on `<rect>` elements. While SVG 2 allows `rx` and `ry` to be set via CSS, WebKit (Safari, Xcode canvas, DocC rendering) does **not** consistently support CSS `rx` and `ry`.

**Rule**: Always specify `rx` and `ry` directly as attributes on the `<rect>` element:
```xml
<!-- ✅ Correct: Renders smooth continuous rounded corners in all browsers -->
<rect x="40" y="105" width="220" height="130" rx="16" ry="16" class="card-bg" />
```
