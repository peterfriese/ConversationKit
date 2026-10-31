---
name: swift-docc-techwriting
description: The Apple documentation style standard: strict sentence case headings, down-to-earth pragmatic voice, anti-grandiose principle, 3-Sentence Step Anatomy, and hero image standards.
---

# Apple Technical Writing & DocC Style Guide

- Use strict sentence case for all section headings, article titles, and tutorial headings.
- Write in an active, second-person, pragmatic voice ("you" rather than "the developer").
- Avoid marketing superlatives and grandiose adjectives; focus on concrete behavior, trade-offs, and invariants.

---

# Apple documentation tech writing style standard

This skill establishes the writing voice, linguistic rhythm, sentence construction, capitalization standards, pedagogical patterns, vocabulary prohibitions, and visual media guidelines required to author technical documentation and tutorials that mirror Apple's official documentation.

# References
- `references/sentence-case-guide.md`: Consult when checking capitalization across headings, titles, sections, tables, diagram text labels, and topic groups, or verifying approved proper nouns and acronyms.
- `references/step-anatomy-and-prohibitions.md`: Consult when authoring or reviewing tutorial `@Step` text for the 3-Sentence Step Anatomy, auditing prohibited diminutives and marketing buzzwords, or verifying official Xcode UI terminology.

---

## 1. Strict sentence case editorial standard

Apple technical documentation strictly uses **sentence case** across all structural and contextual elements. Sentence case makes technical prose approachable, easy to scan, and consistent with the Apple platform interface style.

```
┌───────────────────────────────────────────────────────────────────────────┐
│                    Strict sentence case editorial mandate                 │
├───────────────────────────────────────────────────────────────────────────┤
│ Capitalize only:                                                          │
│  1. The first letter of the heading, title, label, or item                │
│  2. Proper nouns (Swift, Apple, Xcode, Core ML, SwiftUI, SwiftData)       │
│  3. Standard technical acronyms (API, HTTP, ANE, HIG, URL, UI)            │
│  4. Exact code identifiers and symbols (@Generable, View, ModelContext)   │
│                                                                           │
│ Prohibited: Title case across all headings, titles, sections, and tables  │
└───────────────────────────────────────────────────────────────────────────┘
```

### Scope of the Sentence Case Rule

Sentence case is non-negotiable across every surface of your documentation catalog:
- **Article and tutorial titles**: `# Creating a photo card`, `@Intro(title: "Configuring the data store")`
- **Markdown headings**: `#`, `##`, `###`, `####`
- **Tutorial section headers**: `@Section(title: "Assemble the card layout")`
- **Table headers**: `| Parameter name | Expected type | Description |`
- **Vector diagram text cards**: `<text>Data store</text>`, `<text>Message repository</text>`
- **Navigation labels and topic group headers**: `### View components`, `### Data flow and state`

### Title case vs. sentence case

| ❌ Forbidden Title Case | ✅ Required Sentence Case | Note |
| :--- | :--- | :--- |
| *Creating A Custom Card View* | *Creating a custom card view* | Capitalize only the initial word. |
| *Integrating With Core ML And SwiftData* | *Integrating with Core ML and SwiftData* | Preserve proper nouns (*Core ML*, *SwiftData*). |
| *Fetching Remote JSON Via The HTTP API* | *Fetching remote JSON via the HTTP API* | Preserve acronyms (*JSON*, *HTTP*, *API*). |
| *Conforming To The View Protocol* | *Conforming to the `View` protocol* | Code types are identifiers in backticks. |
| *Step 1: Setting Up The Project* | *Step 1: Setting up the project* | Sub-clauses remain in sentence case. |
| *Understanding State And Data Flow* | *Understanding state and data flow* | Conjunctions and prepositions are lowercase. |

---

## 2. The Apple pedagogical voice and tone

Apple documentation never reads like academic whitepapers, promotional press releases, or informal blog posts. It speaks with the voice of **The Empowering Guide**: warm, clear, calm, collaborative, humble, and authoritative.

```
               ┌────────────────────────────────────────────────────────┐
               │                  The empowering guide                  │
               │  Warm • Clear • Collaborative • Humble • Authoritative  │
               └───────────────────────────┬────────────────────────────┘
                                           │
         ┌─────────────────────────────────┴─────────────────────────────────┐
         ▼                                                                   ▼
┌───────────────────────────────┐                   ┌─────────────────────────────────┐
│     Direct second person      │                   │    Anti-grandiose principle     │
│  "You", "You'll", "In this..."│                   │  Pragmatic, concrete, direct    │
│  Never passive or 3rd-person  │                   │  Zero academic or pompous jargon│
└───────────────────────────────┘                   └─────────────────────────────────┘
```

### The anti-grandiose principle

- **State what the code does; do not preach.**
- Never inflate simple engineering tasks with pretentious, self-important phrasing.
- Explain technical realities plainly. Readers are intelligent professionals seeking clarity, not an academic symposium or marketing pitch.

| ❌ Grandiose / Pretentious Phrasing | ✅ Apple Down-to-Earth Voice |
| :--- | :--- |
| *"This foundational paradigm encapsulates the epistemic duality of state synchronization."* | *"When the state changes, the view updates automatically to display the latest value."* |
| *"We orchestrate a multi-layered architectural abstraction over persistent data stores."* | *"The repository manages saving and loading records from disk."* |
| *"Leveraging cutting-edge heuristics, this method yields optimal computational throughput."* | *"This method caches calculations to avoid redundant computations."* |

---

## 3. Direct address and person

Always write in the **direct second person**:
- Address the reader directly as **"you"** or **"you'll"**.
- Never refer to the reader as *"the user"*, *"the developer"*, or *"the programmer"*.
- Never use the passive voice to avoid naming the actor.
- Never use the universal first-person plural (*"now we will write our code"*).

```markdown
<!-- ❌ Passive Voice -->
A new view model is initialized and bound to the navigation controller.

<!-- ❌ Detached Third Person -->
The developer should select ContentView.swift and add the modifier.

<!-- ❌ We / Us -->
Now let's create our list together.

<!-- ✅ Apple Standard (Direct Second Person) -->
In the Project navigator, select `ContentView.swift`.

Add the `padding()` modifier to inset the view's content from the screen edges.
```

---

## 4. The 3-sentence step anatomy

Every `@Step` in an interactive tutorial must adhere to the **3-Sentence Anatomy**:

$$\text{Sentence 1: Imperative Action} \longrightarrow \text{Sentence 2: Context / Principle} \longrightarrow \text{Sentence 3: Observable Feedback}$$

| Sentence | Function | Objective | Example |
| :--- | :--- | :--- | :--- |
| **Sentence 1** | **Imperative Action** | Exact physical or navigational instruction with explicit UI coordinates and verbs. | *"In the Project navigator, select `LandmarkList.swift`."* |
| **Sentence 2** | **Principle / Context** | Single sentence explaining *why* or what this construct represents. | *"Lists organize data into scrollable rows and adapt to system dynamics like dark mode."* |
| **Sentence 3** | **Observable Feedback** | What the learner observes or what updates on the canvas/simulator. | *"The canvas preview updates immediately to display sample landmarks in a vertical list."* |

### Strict step length rule
- A step consists of **1 to 3 sentences maximum**.
- Never write paragraphs, multi-step compound instructions, or conceptual treatises inside a `@Step`.
- If a concept requires deep explanation, place it in an accompanying `@Article` or the section's `@ContentAndMedia` overview.

---

## 5. Modern Develop in Swift pedagogical structure

Apple's modern *Develop in Swift* curricula (WWDC 2024–2026) follow specific pedagogical structures that maximize learning velocity while minimizing cognitive fatigue.

### The micro-prototype pattern

Learners should experience concrete success within the first few minutes of starting a curriculum. Always adopt a **two-tier learning progression**:

```
┌───────────────────────────────────────────────────────────────────────────┐
│                     The two-tier learning progression                     │
├───────────────────────────────────────────────────────────────────────────┤
│ Tier 1: The micro-prototype (5-minute quick win)                          │
│ • Build a single-file concept prototype (e.g., ChatPrototype,             │
│   SpamPrototype, ColorPickerPrototype).                                   │
│ • Hardcode sample state directly in the view.                             │
│ • Validate the core interaction in the canvas preview immediately.       │
│                                                                           │
│ Tier 2: Architectural realization (multi-file engineering)                │
│ • Break the prototype into reusable view components.                      │
│ • Introduce formal domain models, SwiftData persistence, and networking.  │
│ • Connect shared state through dependency injection or environment values.│
└───────────────────────────────────────────────────────────────────────────┘
```

Never start a beginner or intermediate module by demanding that learners create five empty architecture files, service protocols, and data models before seeing a single visual element on screen.

### The 3–5 step section rule

Strictly limit cognitive load per tutorial section:
- **Every `@Section` must contain 3 to 5 steps.**
- Never author 10-step or 15-step marathon sections.
- If an implementation task requires more than 5 steps, split the task into distinct logical sections (for example: *"Section 1: Construct the card container"* $\to$ *"Section 2: Add interactive controls"*).

### Dedicated wrap-up pages

Every major curriculum milestone, volume, or chapter must conclude with a dedicated `@Article` wrap-up page. Wrap-up pages serve three essential functions:
1. **Celebrate what was built**: Acknowledge the learner's achievement and show a visual rendering of the fully functional milestone.
2. **Recap 3–4 key architectural takeaways**: Summarize the core engineering principles in a bulleted overview (not line-by-line syntax, but architectural insights).
3. **Curate direct next-step links**: Provide targeted links to relevant WWDC session videos, Human Interface Guidelines chapters, and Apple framework API reference pages.

---

## 6. Prohibited vocabulary index

To preserve Apple's signature polish and avoid condescending or bloated language, strictly eliminate three categories of words:

```
┌───────────────────────────────────────────────────────────────────────────┐
│                       Strictly prohibited vocabulary                      │
├─────────────────────────────┬─────────────────────────────┬───────────────┤
│    ❌ Diminutives           │    ❌ Marketing superlatives│ ❌ Academic   │
├─────────────────────────────┼─────────────────────────────┼───────────────┤
│ • simply                    │ • blazing-fast              │ • epistemic   │
│ • just                      │ • revolutionary             │ • paradigm    │
│ • easily                    │ • magical                   │ • dichotomy   │
│ • obviously                 │ • game-changing             │ • ontological │
│ • clearly                   │ • cutting-edge              │ • heuristics  │
│ • trivial                   │ • seamless                  │ • logits      │
│ • naturally                 │ • powerhouse                │ • synergetic  │
└─────────────────────────────┴─────────────────────────────┴───────────────┘
```

### Why diminutives are forbidden
Words like *simply*, *just*, and *obviously* alienate readers. If an engineer is stuck or encountering an unfamiliar pattern, telling them to *"simply configure the delegate"* is patronizing and unhelpful.

### Prohibited meta-narration
Never describe the act of writing the tutorial itself:
- ❌ *"In this step, we will..."*
- ❌ *"As we saw in the previous section..."*
- ❌ *"Now that you've done that, let's move on to..."*
- ✅ Jump straight into the action: *"Embed the landmark title in an `HStack`."*

---

## 7. Visual media standards and hero images

Visual assets anchor the learner in reality. Low-quality, abstract, or clipped graphics undermine the authoritative tone of Apple documentation.

### The hero image standard

```
┌───────────────────────────────────────────────────────────────────────────┐
│                           Hero image criteria                             │
├─────────────────────────────────────┬─────────────────────────────────────┤
│             ✅ Allowed              │             ❌ Forbidden            │
├─────────────────────────────────────┼─────────────────────────────────────┤
│ • High-resolution device mockup     │ • Architecture diagrams             │
│ • Running app screenshot on device  │ • Flowcharts and sequence diagrams  │
│ • Polished component preview render │ • Abstract shapes or icons          │
│ • Realistic photo of physical setup │ • Low-contrast wireframe sketches   │
└─────────────────────────────────────┴─────────────────────────────────────┘
```

> [!IMPORTANT]
> **Hero Slot Requirement**: Hero images (`@Intro` and `@Tutorials` hero banners) must **always** display the **running application or real device mockup**. Never place architectural flowcharts, entity diagrams, or raw text blocks into a hero image slot. Reserve diagrams exclusively for `@Section` `@ContentAndMedia` or conceptual `@Article` pages.

### Visual safe margins (the 32px rule)

When authoring screenshots, UI mockups, or diagrams:
- **Maintain a minimum of $\ge 32\text{px}$ safe margin** around all text labels, badges, and callout boxes within the graphic.
- Never let UI labels touch or get clipped by canvas borders, device bezels, or image edges.
- Provide `@2x` assets with crisp retina resolution (e.g., `hero-mailtriage@2x.png`).
- Ensure high contrast in both Light and Dark appearances.

---

## 8. Apple-grade vector diagram design system and anti-overflow rules

Diagrams in Apple documentation communicate architectural concepts with restraint, high contrast, and typographical precision. For comprehensive geometric formulas, SVG marker mechanics, and architectural topology blueprints, consult the companion skill `swift-docc-diagrams`.

### Defensive bounding-box sizing (the 10px rule)

Because SVG text rendering varies across platforms and font rasterizers (San Francisco on macOS, Roboto on Linux, Segoe UI on Windows), fixed-size text boxes frequently cause text to overflow border edges.

To guarantee that text labels never spill over SVG container boundaries, apply the **10px rule**:

$$\text{rectWidth} = (\text{maxLineCharacters} \times 10) + 32\text{px}$$

- Allocate **10px of width per character** for the longest line of text inside the container (assuming 14–15px base font size).
- Add **32px of total horizontal padding** (16px on the left, 16px on the right).
- Example: For a label with 18 characters (*"State representation"*):
  $$\text{rectWidth} = (18 \times 10) + 32 = 212\text{px}$$

### Stacked `<tspan>` and centered geometry

Never render long, multi-word diagram labels as a single un-wrapped `<text>` element.
- Always use `text-anchor="middle"` with the card's center coordinate ($x = \text{rectX} + \text{rectWidth}/2$).
- Stack multi-line labels using `<tspan>` with relative vertical offsets (`dy="1.3em"`).
- Keep labels under 24 characters per line.

```xml
<text x="160" y="70" text-anchor="middle" class="card-title">
  <tspan x="160" dy="0">Document Store</tspan>
  <tspan x="160" dy="1.3em" class="card-subtitle">Persistent SQLite snapshot</tspan>
</text>
```

### Apple Cupertino technical color palette

Apple technical diagrams use a restrained, high-contrast palette composed of neutral scaffolding and a single purposeful hero accent. Never use multi-colored rainbow pastels or "traffic-light" (red/green) good-vs-bad schemes.

| Component | Light Appearance | Dark Appearance | Purpose |
| :--- | :--- | :--- | :--- |
| **Canvas background** | `#FFFFFF` | `#000000` | Edge-to-edge transparent or neutral background |
| **Card background** | `#F5F5F7` | `#1C1C1E` | High-readability container background |
| **Card border** | `#E5E5EA` | `#38383A` | Subtle 1px boundary stroke |
| **Primary label** | `#1D1D1F` | `#F5F5F7` | Dominant label text |
| **Secondary label** | `#86868B` | `#98989D` | Subtitles, footnotes, dimensions |
| **Accent / Hero** | `#0071E3` | `#2997FF` | Single focal connection or active component |
| **Connector stroke** | `#86868B` | `#636366` | Flow arrows and associations (1.5px stroke) |

### Dark mode asset pairing

DocC provides built-in dark appearance image resolution using the `~dark` filename suffix:
- Provide both `diagram-architecture.svg` and `diagram-architecture~dark.svg` in `Resources/images/`.
- In DocC markdown, reference only the base asset: `@Image(source: "diagram-architecture.svg", alt: "...")`.
- DocC automatically serves `diagram-architecture~dark.svg` when the reader enables dark mode in their browser or system appearance.

---

## 9. Official Apple interface terminology

Always use exact Apple capitalization and nomenclature for IDE controls and system UI:

| Correct Apple Term | Incorrect Variation |
| :--- | :--- |
| **Project navigator** | Project explorer, file tree, sidebar |
| **Canvas** | Preview pane, simulator view |
| **Attributes inspector** | Properties panel, attribute tab |
| **Library** | Object catalog, component palette |
| **Scheme menu** | Target dropdown, build selector |
| **Debug bar** | Console controls, runtime tray |
| **Dynamic Type** | System font scaling |
| **Control Center** | Control pane |

---

## 10. Style and polish review checklist

- [ ] All headings, titles, section names, and table headers are in **strict sentence case**.
- [ ] Written entirely in direct second person (*"you"*, *"you'll"*).
- [ ] Zero passive constructions (*"is created"*, *"are called"*).
- [ ] Anti-grandiose principle respected: zero academic jargon or inflated claims.
- [ ] All `@Step` directives follow the 3-Sentence Anatomy (Action $\to$ Context $\to$ Feedback).
- [ ] Sections contain between 3 and 5 steps (preventing cognitive overload).
- [ ] Major modules conclude with a dedicated wrap-up article.
- [ ] No prohibited diminutives (*simply*, *just*, *obviously*, *easily*).
- [ ] No marketing superlatives (*blazing-fast*, *revolutionary*, *magical*).
- [ ] Hero images exclusively feature running app screenshots or device mockups.
- [ ] Diagrams follow the Cupertino palette and the 10px defensive bounding-box rule.
- [ ] Official Xcode UI terms used with proper capitalization (*Project navigator*, *Canvas*).
