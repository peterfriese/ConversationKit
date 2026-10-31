# Step anatomy, prohibited vocabulary, and interface terminology

This reference defines the 3-Sentence Step Anatomy, the prohibited vocabulary index, and official Apple interface terminology for technical documentation and interactive tutorials.

---

## 1. The 3-sentence step anatomy

Every instruction `@Step` within an interactive DocC tutorial must strictly adhere to the **3-Sentence Anatomy**:

$$\text{Sentence 1: Imperative Action} \longrightarrow \text{Sentence 2: Context / Principle} \longrightarrow \text{Sentence 3: Observable Feedback}$$

| Sentence | Function | Objective | Example |
| :--- | :--- | :--- | :--- |
| **Sentence 1** | **Imperative Action** | Exact physical instruction with explicit UI coordinates, file names, and imperative verbs. | *"In the Project navigator, select `LandmarkList.swift`."* |
| **Sentence 2** | **Principle / Context** | Single sentence explaining *why* or what this construct represents. | *"Lists organize data into scrollable rows and adapt to system dynamics like dark mode."* |
| **Sentence 3** | **Observable Feedback** | What the learner observes or what updates on the canvas or simulator. | *"The canvas preview updates immediately to display sample landmarks in a vertical list."* |

### Step length discipline
- **1 to 3 sentences maximum per `@Step`**.
- Never write paragraphs, compound multi-step sequences, or conceptual treatises inside a `@Step`.
- If a concept requires in-depth theoretical explanation, place it in an accompanying `@Article` or the section's `@ContentAndMedia` block.

---

## 2. Prohibited vocabulary index

Apple documentation maintains an understated, humble, and authoritative tone. To prevent condescending or bloated language, eliminate three categories of words:

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
Words like *simply*, *just*, and *obviously* alienate readers. If an engineer is stuck or encountering an unfamiliar pattern, being told to *"simply configure the delegate"* is patronizing and unhelpful.

### Prohibited meta-narration
Never describe the act of writing the tutorial itself:
- ❌ *"In this step, we will..."*
- ❌ *"As we saw in the previous section..."*
- ❌ *"Now that you've done that, let's move on to..."*
- ✅ Jump straight into the action: *"Embed the landmark title in an `HStack`."*

---

## 3. Official Apple interface terminology

Always use exact Apple capitalization and nomenclature for IDE controls and system UI:

| Correct Apple term | Incorrect variations to avoid |
| :--- | :--- |
| **Project navigator** | Project explorer, file tree, sidebar, project pane |
| **Canvas** | Preview pane, simulator view, design canvas |
| **Attributes inspector** | Properties panel, attribute tab, inspector window |
| **Library** | Object catalog, component palette, snippet picker |
| **Scheme menu** | Target dropdown, build selector, target bar |
| **Debug bar** | Console controls, runtime tray, debugger bar |
| **Dynamic Type** | System font scaling, dynamic text |
| **Control Center** | Control pane, quick settings |
| **Dock** | App tray, taskbar |
| **Menu bar** | Top bar, system menu |
