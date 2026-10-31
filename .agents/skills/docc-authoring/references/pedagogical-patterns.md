# Develop in Swift pedagogical patterns and engineering contracts

This reference documents the pedagogical structure, cognitive load limits, and engineering contracts discovered during production review of Apple's modern *Develop in Swift* interactive tutorial curricula (WWDC 2024–2026).

---

## 1. The two-tier learning progression

Modern technical learners experience cognitive friction when forced to configure abstract scaffolding before seeing concrete UI results. To maximize engagement and retention, all major curriculum modules follow a **two-tier learning progression**:

```
┌───────────────────────────────────────────────────────────────────────────┐
│                     The two-tier learning progression                     │
├───────────────────────────────────────────────────────────────────────────┤
│ Tier 1: The micro-prototype (5-minute quick win)                          │
│ • Build a single-file concept prototype (e.g., ChatPrototype.swift).     │
│ • Hardcode sample state inline in the view.                               │
│ • Validate the core interaction in the canvas preview immediately.       │
│                                                                           │
│ Tier 2: Architectural realization (subsequent modules)                    │
│ • Break the prototype into reusable view components.                      │
│ • Introduce formal domain models (@Model, @Observable, Codable).         │
│ • Add persistence, background tasks, and network services.               │
└───────────────────────────────────────────────────────────────────────────┘
```

### Implementing Tier 1: The micro-prototype
1. **Single-file scope**: The learner creates or opens a single file (e.g., `ChatPrototypeView.swift`).
2. **Inline sample data**: Rather than building database schemas or network adapters, hardcode sample text, mock arrays, or simple `@State` properties directly in the view.
3. **Immediate tactile feedback**: Within 3 to 5 steps, the learner interacts with the view in the Xcode Canvas (e.g., tapping a button, toggling a state flag, observing layout reflow).
4. **Pedagogical validation**: Proves that the core user experience works before investing time in structural abstractions.

### Transitioning to Tier 2: Architectural realization
Once the prototype functions:
1. Extract individual UI elements into dedicated component structs (`ChatMessageRow.swift`, `ChatInputBar.swift`).
2. Model persistent domain entities using `@Model` (SwiftData) or `@Observable`.
3. Replace hardcoded `@State` variables with model contexts and dependency injection.

---

## 2. The 3–5 step section rule

Cognitive engineering research demonstrates that working memory degrades rapidly when instructions exceed 5 sequential operations without a cognitive rest point.

### Section size limits
- **Mandatory limit**: Every `@Section` must contain strictly between **3 and 5 steps**.
- **Prohibited**: 8-, 10-, or 15-step marathon sections.
- **Cognitive reset**: After completing 3 to 5 steps, the learner reaches the section boundary, pauses, inspects their running canvas, and solidifies their mental model.

### Splitting multi-step tasks
When an implementation requires more than 5 steps, decompose the feature into logical, self-contained sections:

| Feature task (8 steps total) | ❌ Marathon section | ✅ Apple 2-section split |
| :--- | :--- | :--- |
| Building a photo card with like interaction | `@Section: "Build the photo card"` *(Steps 1–8)* | **Section 1**: *"Assemble the card layout"* *(Steps 1–4)*<br>**Section 2**: *"Add like gesture interactions"* *(Steps 5–8)* |

---

## 3. Dedicated wrap-up pages

Every major volume or curriculum milestone must conclude with a dedicated wrap-up article (`WrapUp.article`). A wrap-up page reinforces mastery through three structured elements:

### 1. Celebrate what was built
Display a high-resolution hero image or device preview showcasing the completed feature running in full fidelity. Validate the effort the learner invested.

### 2. Recap 3–4 key architectural takeaways
Provide an executive bulleted summary of the core engineering decisions made during the module:
- Focus on architectural principles (data flow, single source of truth, actor isolation), not syntax mechanics.
- Explain *why* a particular pattern was chosen over an alternative.

### 3. Curate direct next-step links
Offer 3 to 5 targeted pointers to official Apple resources:
- Relevant WWDC session videos.
- Apple Developer API reference pages.
- Human Interface Guidelines chapters.
- Sample code repositories.

---

## 4. The compilable starter and finisher engineering contract

Parity between tutorial instructions and companion project files is an absolute requirement. Any mismatch breaks the learner's trust and stalls progress.

```
┌───────────────────────────────────────────────────────────────────────────┐
│              Compilable starter and finisher engineering contract         │
├───────────────────────────────────────────────────────────────────────────┤
│ 1. Zero-dependency starter rule                                           │
│    • Starter builds out of the box with 0 errors and 0 warnings.          │
│    • Zero external package dependencies before the tutorial framework.    │
│                                                                           │
│ 2. Strict 1:1 diff contract                                               │
│    • Every line of finisher code is introduced in a numbered @Step.       │
│    • starter + sum(all @Steps) == finisher.                              │
│                                                                           │
│ 3. No magic code                                                          │
│    • Forbid unmentioned utilities, secret extensions, or hidden helpers.  │
│                                                                           │
│ 4. Checkpoint integrity in CI                                             │
│    • Automated `swift build` on every Starter and Finisher checkpoint.    │
└───────────────────────────────────────────────────────────────────────────┘
```

### Zero-dependency starter rule
- The starter Xcode project or Swift package must compile out of the box with **0 errors and 0 warnings**.
- Never require third-party dependencies in the starter before the tutorial's subject framework is introduced.
- Assets catalogs, preview mocks, and target schemes must be pre-configured and valid.

### Strict 1:1 diff contract
The finisher project must be the exact mathematical sum of the starter project plus all tutorial steps:

$$\text{Finisher} \equiv \text{Starter} + \sum_{i=1}^{N} \text{Step}_i$$

If a helper method, model property, or modifier exists in the finisher but was not introduced in a numbered tutorial `@Step`, it represents a defect.

### Standard checkpoint structure
Organize multi-chapter sample code into discrete milestone directories:
```
Checkpoints/
├── 01-Starter/                # Clean starter for Chapter 1
├── 01-Finisher/               # Exact state after completing Chapter 1
├── 02-Starter/                # Starter for Chapter 2 (= 01-Finisher)
└── 02-Finisher/               # Final state after completing Chapter 2
```

### CI verification script
Automate compilation validation across all checkpoints in your test pipeline:
```bash
#!/bin/bash
set -e
for checkpoint in Checkpoints/*/; do
  echo "Verifying compilation for $checkpoint..."
  (cd "$checkpoint" && swift build)
done
echo "All tutorial checkpoints compile cleanly."
```
