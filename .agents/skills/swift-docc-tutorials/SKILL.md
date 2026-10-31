---
name: swift-docc-tutorials
description: Guide and syntax reference for authoring interactive DocC tutorials, multi-chapter curricula, step-by-step code walkthroughs, micro-prototypes, compilable starter/finisher contracts, and knowledge assessments.
---

# Swift DocC Interactive Tutorials

- Structure tutorials with `@Tutorials` table of contents, `@Chapter` groupings, and `@Tutorial` walkthroughs.
- Follow the 3-Sentence Step Anatomy for every `@Step`: context sentence, action sentence, and result sentence.
- Pair `@Code` directives with compilable progressive code snapshots so Myers diff highlights only the new lines added in each step.

---

# Swift DocC interactive tutorials

DocC interactive tutorials provide multi-page, step-by-step interactive learning experiences with synchronized code diffs, canvas media, and interactive knowledge checks—identical to Apple's official tutorials (*SwiftUI Tutorials*, *SwiftData Essentials*).

# References
- `references/pedagogical-patterns.md`: Consult when designing curriculum progression, authoring single-file micro-prototypes, capping sections with the 3–5 step rule, authoring milestone wrap-up pages, or validating the starter/finisher compilability contract.
- `references/myers-diff-mechanics.md`: Consult when authoring sequential code listings in `Resources/code/`, preventing or diagnosing shifted closing brace highlight defects, or running `audit-docc-highlights.py`.
- `references/directives-catalog.md`: Consult for the complete syntax reference and parent-child nesting rules of `@Tutorials`, `@Tutorial`, `@Article`, `@Section`, `@Steps`, `@Step`, `@Code`, and `@Assessments`.

---

## 1. Directory structure and file hierarchy

DocC tutorials must be placed inside a `.docc` documentation catalog adhering to this exact directory hierarchy:

```
Sources/MyTarget/
└── MyTarget.docc/
    ├── MyTarget.md                            # Reference landing page
    ├── Tutorials/
    │   ├── MyCurriculum.tutorial              # Table of Contents (@Tutorials root)
    │   ├── 01-Essentials/
    │   │   ├── 01-CreatingViews.tutorial      # Interactive step-by-step (@Tutorial)
    │   │   └── 02-HandlingState.tutorial
    │   └── 02-Advanced/
    │       ├── 01-CustomLayouts.tutorial
    │       └── 02-DataFlow.article            # Conceptual tutorial article
    └── Resources/
        ├── code/                              # Incremental code listings (.swift)
        │   ├── 01-view-step1.swift
        │   ├── 01-view-step2.swift
        │   └── 01-view-step3.swift
        ├── images/                            # Hero images and canvas previews
        │   ├── hero-essentials@2x.png
        │   ├── canvas-step1@2x.png
        │   └── canvas-step2@2x.png
        └── downloads/                         # Starter / Finisher archives
            ├── Essentials-Starter.zip
            └── Essentials-Finisher.zip
```

---

## 2. Directive architecture and nesting tree

DocC enforces strict parent-child relationships between directives. Violating these nesting hierarchies produces compilation errors.

### The curriculum tree (`@Tutorials`)

```
@Tutorials(name: "...")                 [Root directive for the curriculum]
├── @Intro(title: "...")                [Required: Overview banner & hero image]
│   └── @Image(source: "...", alt: "...")
├── @Volume(name: "...")                [Optional: Groups chapters into volumes]
├── @Chapter(name: "...")               [Required: 1 or more chapters]
│   ├── @Image(source: "...", alt: "...")
│   ├── @TutorialReference(tutorial: "...")  [Links to @Tutorial or @Article]
│   └── @TutorialReference(...)
└── @Resources                          [Required: Resource collection footer]
    ├── @Downloads(destination: "...")
    ├── @Documentation(destination: "...")
    ├── @SampleCode(destination: "...")
    ├── @Videos(destination: "...")
    └── @Forums(destination: "...")
```

### The interactive page tree (`@Tutorial`)

```
@Tutorial(time: <minutes>, projectFiles: "...")  [Root directive for step-by-step tutorial]
├── @XcodeRequirement(title: "...", destination: "...") [Optional requirement notice]
├── @Intro(title: "...")                        [Required: Hero introduction]
│   ├── @Image(source: "...", alt: "...")
│   └── @Video(source: "...", poster: "...")    [Alternative to @Image]
├── @Section(title: "...")                      [Required: 1 or more task sections]
│   ├── @ContentAndMedia                        [Required: Conceptual section overview]
│   │   └── @Image(source: "...", alt: "...")
│   ├── @Steps                                  [Required: Ordered list of steps]
│   │   ├── @Step                               [Individual instruction step]
│   │   │   ├── @Code(name: "...", file: "...") [Synchronized code diff]
│   │   │   ├── @Image(source: "...", alt: "...")
│   │   │   └── @Video(source: "...", poster: "...")
│   │   └── @Step
│   └── @Stack                                  [Alternative 2-column layout]
└── @Assessments                                [Required: Knowledge checks]
    └── @MultipleChoice                         [1 or more questions]
        ├── Question markdown text
        ├── @Choice(isCorrect: true)
        │   ├── Choice text
        │   └── @Justification(reaction: "...")
        └── @Choice(isCorrect: false)
            ├── Choice text
            └── @Justification(reaction: "...")
```

### The conceptual article tree (`@Article`)

```
@Article(time: <minutes>)                       [Root directive for conceptual tutorial article]
├── @Intro(title: "...")                        [Required: Hero introduction & overview banner]
│   ├── @Image(source: "...", alt: "...")
│   └── @Video(source: "...", poster: "...")
├── @ContentAndMedia                            [1 or more conceptual overview blocks]
│   └── @Image(source: "...", alt: "...")
├── @Stack                                      [Optional horizontal multi-column container]
│   ├── @ContentAndMedia                        [1 to 3 columns required inside @Stack]
│   │   └── @Image(source: "...", alt: "...")
│   └── @ContentAndMedia
│       └── @Image(source: "...", alt: "...")
└── @Assessments                                [Optional knowledge checks]
    └── @MultipleChoice
```

---

## 3. Directives reference

### `@Tutorials` (table of contents)

Defines the landing page for your tutorial curriculum.

```markdown
@Tutorials(name: "PhotoJournal Essentials") {
    @Intro(title: "Building PhotoJournal") {
        Learn how to craft a modern, responsive photo journaling app for iOS and macOS.
        You'll start by building views, wire them to SwiftData persistence, and finish
        with interactive animations.

        @Image(source: "hero-photojournal.png", alt: "PhotoJournal running on an iPhone display.")
    }

    @Chapter(name: "Layout and views") {
        Create the core visual building blocks and compose dynamic lists.

        @Image(source: "chapter-layout.png", alt: "An iPad screen showing a grid of photos.")

        @TutorialReference(tutorial: "doc:01-CreatingViews")
        @TutorialReference(tutorial: "doc:02-BuildingLists")
    }

    @Resources {
        Explore developer guides, complete project downloads, and community forums.

        @Downloads(destination: "downloads/PhotoJournal-Starter.zip") {
            Download starter and completed Xcode project bundles.

            - [PhotoJournal Starter Project](downloads/PhotoJournal-Starter.zip)
            - [PhotoJournal Completed Project](downloads/PhotoJournal-Finisher.zip)
        }

        @Documentation(destination: "https://developer.apple.com/documentation/swiftui") {
            Browse official Apple documentation for SwiftUI and SwiftData:

            - [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
            - [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
        }
    }
}
```

### `@Tutorial` (step-by-step tutorial page)

Defines an individual tutorial page with step-by-step instructions.

- `time`: Estimated completion time in minutes (integer, e.g., `time: 20`).
- `projectFiles`: Name of the starter ZIP archive located in `Resources/downloads/`.

```markdown
@Tutorial(time: 15, projectFiles: "PhotoJournal-Starter.zip") {
    @XcodeRequirement(title: "Xcode 16.0+", destination: "https://developer.apple.com/xcode/")

    @Intro(title: "Creating a photo card") {
        Build a reusable photo card view that displays a formatted image, title caption,
        and date stamp.

        @Image(source: "hero-photocard.png", alt: "The finished PhotoCard component.")
    }

    @Section(title: "Assemble the card layout") {
        @ContentAndMedia {
            Photo cards display an image framed with a rounded border and overlaid metadata.
            In this section, you’ll construct the component using SwiftUI layout stacks.

            @Image(source: "section-layout.png", alt: "A wireframe diagram of the card view.")
        }

        @Steps {
            @Step {
                In the Project navigator, create a new SwiftUI view file named `PhotoCard.swift`.

                SwiftUI files declare a `View` structure and a `#Preview` block.

                The canvas renders an initial preview displaying a placeholder text view.

                @Code(name: "PhotoCard.swift", file: "01-card-step1.swift")
            }

            @Step {
                Replace the default `Text` view with an `Image` view that loads the cover photo.

                Image views display bitmap assets stored in your asset catalog using asset name identifiers.

                The canvas preview updates immediately to render the unclipped photo.

                @Code(name: "PhotoCard.swift", file: "01-card-step2.swift")
            }

            @Step {
                Apply the `clipShape(_:)` modifier to give the image rounded corners.

                Clipping constrains the view's rendered bounds without modifying the underlying asset geometry.

                The image corners smooth into uniform rounded edges in the preview.

                @Code(name: "PhotoCard.swift", file: "01-card-step3.swift")
            }
        }
    }

    @Assessments {
        @MultipleChoice {
            Which layout container places child views along a horizontal axis?

            @Choice(isCorrect: true) {
                `HStack`

                @Justification(reaction: "Correct!") {
                    `HStack` arranges views horizontally in a line from leading to trailing.
                }
            }

            @Choice(isCorrect: false) {
                `VStack`

                @Justification(reaction: "Try again.") {
                    `VStack` arranges views vertically in a column from top to bottom.
                }
            }

            @Choice(isCorrect: false) {
                `ZStack`

                @Justification(reaction: "Try again.") {
                    `ZStack` overlays views on top of each other along the z-axis.
                }
            }
        }
    }
}
```

---

## 4. Modern Develop in Swift pedagogical patterns

Apple's production tutorial curricula (WWDC 2024–2026) follow strict cognitive engineering standards designed to maximize learner agency and retention.

### The micro-prototype pattern

Never confront learners with heavy architectural ceremonies, protocol abstractions, or multi-file scaffolding on Step 1. Instead, structure milestones using a **two-tier learning progression**:

```
┌───────────────────────────────────────────────────────────────────────────┐
│                     The two-tier learning progression                     │
├───────────────────────────────────────────────────────────────────────────┤
│ 1. Tier 1: Micro-prototype (first 5 minutes)                              │
│    • Single-file rapid concept prototype (e.g., ChatPrototype.swift).     │
│    • Hardcoded sample state inline in the view.                           │
│    • Immediate visual payoff and interactivity in the Xcode Canvas.       │
│                                                                           │
│ 2. Tier 2: Architectural realization (subsequent modules)                 │
│    • Extract modular views and dedicated components.                      │
│    • Introduce formal data models (@Model, @Observable, Codable).         │
│    • Add persistence, background tasks, and network services.             │
└───────────────────────────────────────────────────────────────────────────┘
```

The micro-prototype guarantees an early psychological win: within 5 minutes, the learner has a working prototype reacting to user gestures in the Xcode Canvas.

### The 3–5 step section rule

To prevent cognitive exhaustion and keep instruction units digestible:
- **Every `@Section` must contain between 3 and 5 steps.**
- Long sections with 10–15 steps cause fatigue, lost context, and disorientation.
- If a feature takes 8 steps to assemble, split it cleanly into two separate `@Section` directives with distinct milestones (for example: *"Construct the card layout"* followed by *"Add interactive gestures"*).

### Dedicated wrap-up pages

Every major chapter or volume in a tutorial curriculum must culminate in a dedicated wrap-up `@Article` page. A wrap-up article reinforces mastery through three structured elements:
1. **Celebrate what was built**: Display a hero rendering of the fully functional milestone and validate the learner's achievement.
2. **Recap 3–4 key architectural takeaways**: Provide a concise summary of the core engineering patterns practiced during the chapter.
3. **Curate direct next-step links**: Offer targeted pointers to WWDC session videos, Apple developer documentation, and HIG design guidelines.

---

## 5. The compilable starter and finisher engineering contract

Tutorial integrity depends on absolute parity between the written instructions and the accompanying project files. Violating this contract breaks trust and stalls the learner.

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
The starter Xcode project or Swift package must compile cleanly out of the box (`0 errors`, `0 warnings`) with zero external package dependencies prior to adding the framework or library taught in the tutorial. All asset catalogs, app icons, and target configurations must be functional immediately upon opening the project.

### Strict 1:1 diff contract
Every single line of code present in the completed finisher project must be introduced in a numbered `@Step` of the tutorial.
$$\text{Finisher} \equiv \text{Starter} + \sum_{i=1}^{N} \text{Step}_i$$
If code appears in the finisher project that was not explicitly added or edited in a `@Step`, that constitutes a defect in the tutorial.

### No magic code
Strictly forbid unexplained helper utilities, pre-baked mystery files, hidden extensions, or surprise mock data files that appear without pedagogical introduction. If a helper is required, teach it, generate it in a dedicated step, or explain its presence in the starter overview.

### Checkpoint directory structure and CI verification
Standardize multi-part tutorial code into clear checkpoint directories:
```
Checkpoints/
├── 01-Starter/                # Clean starter for Chapter 1
├── 01-Finisher/               # Exact state after completing Chapter 1
├── 02-Starter/                # Clean starter for Chapter 2
└── 02-Finisher/               # Final curriculum milestone
```

Automate compilation checks in your CI pipeline to ensure that every checkpoint compiles without errors:
```bash
# Verify all tutorial starter and finisher checkpoints compile
for dir in Checkpoints/*/; do
    echo "Verifying $dir..."
    (cd "$dir" && swift build)
done
```

---

## 6. Code directives and Myers diff mechanics

### `@Code` directives and parameters

- `name`: Display name shown in the interactive editor header tab (e.g., `"ContentView.swift"`).
- `file`: Path relative to `Resources/code/` (e.g., `"01-card-step1.swift"`).
- `reset`: Set to `true` (`reset: true`) to render the full file fresh without calculating an incremental diff against the previous step.
- `previousFile`: Explicitly names the predecessor file against which DocC computes the diff (e.g., `previousFile: "01-card-step1.swift"`).

### How DocC diffing works

Between Step $N$ (`fileA.swift`) and Step $N+1$ (`fileB.swift`), DocC executes a Myers diff:
1. Lines identified as insertions are highlighted in yellow/green in the tutorial viewer.
2. Unchanged lines remain neutral.
3. The reader sees a clean animated transition focusing their attention on the new code.

### The Myers diff brace shift defect and prevention

Because the Myers diff algorithm has no syntax awareness, appending a new block ending with `}` right after an existing block ending with `}` frequently causes an ambiguous edit graph. DocC often highlights the *preceding* closing brace and leaves the *new* closing brace unhighlighted:

```swift
// ❌ Shifted Diff Defect:
   func existingMethod() {
   } // <-- DocC highlights this brace erroneously!
   
   func newMethod() {
       process()
   } // <-- DocC fails to highlight this brace!
```

To prevent this defect:
1. **Rule of Prefix Stability**: Never modify or reorder lines above the insertion point between step $N$ and $N+1$.
2. **Intermediate Scope Anchoring**: Always leave at least one empty blank line between scopes.
3. **Use `reset: true` on structural refactors**: If a step significantly restructures a file, suppress diff calculations using `@Code(name: "...", file: "...", reset: true)`.

---

## 7. Knowledge assessments (`@Assessments`)

Every interactive tutorial must culminate in an `@Assessments` block:
- Include 1–3 `@MultipleChoice` questions.
- Every question must test a **conceptual rule, framework principle, or behavioral nuance**, never superficial syntax details.
- Exactly one `@Choice(isCorrect: true)` per question.
- Every `@Choice` must include a `@Justification(reaction: "...")`:
  - For correct choices: `@Justification(reaction: "Correct!")` explaining *why* it is right.
  - For incorrect choices: `@Justification(reaction: "Try again.")` explaining the misconception.

---

## 8. Tutorial authoring checklist

- [ ] All headings, titles, and section headers are formatted in **strict sentence case**.
- [ ] Catalog contains `@Tutorials` table of contents linking every `@Tutorial`.
- [ ] Curricula begin with a rapid micro-prototype (Tier 1) before multi-file architecture.
- [ ] Every `@Tutorial` includes `time` and `projectFiles` attributes.
- [ ] Every `@Section` has a `@ContentAndMedia` block with an illustration.
- [ ] Every `@Section` contains strictly between 3 and 5 steps (the 3–5 step rule).
- [ ] Every `@Step` adheres to the 3-Sentence Anatomy (Action $\to$ Context $\to$ Feedback).
- [ ] Starter compiles with 0 errors, 0 warnings, and zero external dependencies.
- [ ] Strict 1:1 diff contract maintained: finisher matches starter plus tutorial steps with zero magic code.
- [ ] Checkpoints compile cleanly in CI (`swift build` across all checkpoints).
- [ ] Major modules conclude with a dedicated wrap-up article.
- [ ] Code files in `Resources/code/` change 1–5 lines per step.
- [ ] All code steps pass `scripts/audit-docc-highlights.py` with 0 shifted braces.
- [ ] Assessment questions provide clear justifications for all choices.
