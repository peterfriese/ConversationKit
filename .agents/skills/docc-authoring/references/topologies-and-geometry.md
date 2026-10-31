# Architectural topologies and SVG blueprints

This reference provides complete, production-ready SVG blueprints for the four primary architectural topologies used in Apple developer documentation and DocC tutorials.

---

## 1. Linear processing pipeline

Used to represent sequential data processing, compilation steps, or multi-stage pipelines (e.g. `Storage` $\to$ `Observable state` $\to$ `Views`).

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ Persistent store│ ────► │ Observable state│ ────► │  SwiftUI views  │
└─────────────────┘       └─────────────────┘       └─────────────────┘
```

### Layout coordinates (Canvas 840 × 260)
- **Card 1**: `x="40" y="105" width="220" height="130" rx="16" ry="16"` (Right edge = 260)
- **Card 2 (Hero)**: `x="310" y="105" width="220" height="130" rx="16" ry="16"` (Left edge = 310, right edge = 530)
- **Card 3**: `x="580" y="105" width="220" height="130" rx="16" ry="16"` (Left edge = 580)
- **Connector 1 $\to$ 2**:
  - Gap between cards: $310 - 260 = 50\text{px}$
  - Start (12px gap from Card 1): $x_1 = 260 + 12 = 272$
  - Line end (12px gap to Card 2, tip at 298): $x_2 = 298 - 10 = 288$
  - `<path d="M 272 170 L 288 170" class="connector" marker-end="url(#arrow)" />`
- **Connector 2 $\to$ 3**:
  - Start: $x_1 = 530 + 12 = 542$
  - Line end (tip at 568): $x_2 = 568 - 10 = 558$
  - `<path d="M 542 170 L 558 170" class="connector" marker-end="url(#arrow)" />`

---

## 2. Tree and fan-out branching

Used for single source of truth models, dependency injection containers, or routing dispatchers distributing state to multiple dependent views.

```
                  ┌─────────────────────────┐
                  │  Central source of truth│
                  └────────────┬────────────┘
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
   ┌─────────────────┐                   ┌─────────────────┐
   │View A (nav)     │                   │View B (detail)  │
   └─────────────────┘                   └─────────────────┘
```

### Layout coordinates (Canvas 760 × 280)
- **Central Model Pill**: `x="260" y="96" width="240" height="42" rx="21" ry="21"` (Bottom edge = 138)
- **Stem line**: Leaves central pill at `y = 138 + 10 = 148`, drops to horizontal bus bar at `y = 164`:
  `<path d="M 380 148 L 380 164" class="connector" />`
- **Horizontal bus bar**: Spans the centers of the outer cards:
  `<path d="M 150 164 L 610 164" class="connector" />`
- **Dependent cards**: `y="196" height="60" rx="14" ry="14"` (Top edge = 196)
  - Card A: `x="50"` (Center $x = 150$)
  - Card B: `x="280"` (Center $x = 380$)
  - Card C: `x="510"` (Center $x = 610$)
- **Drop connectors**: Stop 10px before card top ($y_{\text{tip}} = 196 - 10 = 186 \implies y_2 = 176$):
  - `<path d="M 150 164 L 150 176" class="connector" marker-end="url(#arrow)" />`
  - `<path d="M 380 164 L 380 176" class="connector" marker-end="url(#arrow)" />`
  - `<path d="M 610 164 L 610 176" class="connector" marker-end="url(#arrow)" />`

---

## 3. Bidirectional cyclic feedback loop

Used for unidirectional data flow architectures where state values flow down into the view hierarchy and user actions flow back up to mutate the model.

```
       ┌────────────────────────┐
  ┌─── │      State model       │ ◄───┐
  │    └────────────────────────┘     │
  │ State flows down      Actions flow up
  ▼    ┌────────────────────────┐     │
  └──► │     View hierarchy     │ ────┘
       └────────────────────────┘
```

### Layout coordinates (Canvas 720 × 340)
- **Top Card (Hero)**: `x="240" y="105" width="240" height="70" rx="14" ry="14"`
  - Left edge = 240, right edge = 480, mid $y = 140$.
- **Bottom Card**: `x="240" y="235" width="240" height="70" rx="14" ry="14"`
  - Left edge = 240, right edge = 480, mid $y = 270$.
- **Downward branch (Hero Blue)**:
  - Leaves top card left edge with 10px gap: $x_1 = 240 - 10 = 230$.
  - Runs left to bus $x = 170$, down to $y = 270$, and turns right toward bottom card left edge ($x=240$).
  - Target tip is at $x = 240 - 10 = 230 \implies x_2 = 230 - 10 = 220$:
    `<path d="M 230 140 L 170 140 L 170 270 L 220 270" class="hero-connector" marker-end="url(#hero-arrow)" />`
- **Upward branch (Neutral)**:
  - Leaves bottom card right edge with 10px gap: $x_1 = 480 + 10 = 490$.
  - Runs right to bus $x = 550$, up to $y = 140$, and turns left toward top card right edge ($x=480$).
  - Target tip is at $x = 480 + 10 = 490 \implies x_2 = 490 + 10 = 500$:
    `<path d="M 490 270 L 550 270 L 550 140 L 500 140" class="connector" marker-end="url(#arrow)" />`

---

## 4. Adaptive device mockups

Used to show UI hierarchy previews, multi-column navigation layouts, and split-screen behavior.

### Blueprint structure
```xml
<!-- iPad Outer Bezel -->
<rect x="150" y="105" width="460" height="345" rx="28" ry="28" class="device-frame" />

<!-- Sidebar Navigation Column -->
<rect x="165" y="120" width="125" height="315" rx="18" ry="18" class="sidebar-bg" />

<!-- Active Hero Selection Item -->
<rect x="175" y="135" width="105" height="22" rx="8" ry="8" class="active-pill" />
<circle cx="186" cy="146" r="3.5" class="active-dot" />

<!-- Content Grid Cards -->
<rect x="305" y="120" width="140" height="150" rx="16" ry="16" class="content-card" />
<rect x="455" y="120" width="140" height="150" rx="16" ry="16" class="content-card" />
<rect x="305" y="285" width="140" height="150" rx="16" ry="16" class="content-card" />
<rect x="455" y="285" width="140" height="150" rx="16" ry="16" class="content-card" />
```
