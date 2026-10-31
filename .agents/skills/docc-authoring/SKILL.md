---
name: docc-authoring
description: Apple DocC documentation syntax, symbol references, and API topic curation
---

# DocC Authoring Standards

- Use strict sentence case for headings.
- Format parameter documentation with `- Parameters:` bullet points.
- Include code examples inside fenced code blocks (` ```swift `) in doc comments for all public entry points.
- Ensure all linked symbols use double backticks (e.g. ``MyType/performAction()``).

---

# Swift DocC API reference documentation

This skill covers the syntax and conventions for writing API reference documentation with Swift DocC—from in-source documentation comments to curated `.docc` documentation catalogs, topic hierarchies, symbol graphs, and Xcode agent skills integration.

# References
- `references/doc-comments-standard.md`: Consult when authoring or reviewing in-source triple-slash (`///`) doc comments, writing single-sentence summaries, structuring parameter/return/throws tags, or formatting callout blocks.
- `references/symbol-curation-and-extensions.md`: Consult when curating target landing pages, defining `## Topics` hierarchies, creating documentation extension files (`Extensions/<Type>.md`), or resolving symbol links and overload disambiguations.
- `references/article-and-metadata-directives.md`: Consult when configuring `@Metadata` blocks, `@TechnologyRoot`, URL redirection with `@Redirected`, multi-column grid layouts with `@Row` and `@Column`, or language switchers with `@TabNavigator`.

---

## 1. In-source documentation comments

Swift DocC extracts API reference documentation directly from doc comments attached to declarations in your Swift source code.

### Comment syntax

- **Always prefer triple slashes (`///`)** over block comments (`/** ... */`). Triple slashes blend cleanly with standard Swift source code formatting.
- Attach the doc comment immediately preceding the declaration with no blank line in between.

```swift
/// An immutable representation of a geographic coordinate.
///
/// A coordinate encapsulates latitude and longitude measured in degrees according
/// to the World Geodetic System 1984 (WGS 84) reference frame.
public struct Coordinate: Sendable, Hashable {
    /// The latitude in degrees.
    public let latitude: Double

    /// The longitude in degrees.
    public let longitude: Double
}
```

### The single-sentence summary rule

The first paragraph of a doc comment serves as the **summary sentence**:
- It appears in Xcode Quick Help tooltips, code completion popovers, and DocC topic listings.
- Write it in the present tense, third person (e.g., *"Creates a new session"*, *"Calculates the distance"*), or as a clear noun phrase (*"An immutable representation..."*).
- Keep it concise (1 sentence, under 120 characters).
- Separate the summary from the extended discussion with an empty `///` line.

### Documenting parameters, returns, and errors

Use standard Markdown list syntax with dedicated parameter tags:

```swift
/// Computes the great-circle distance between this coordinate and another coordinate.
///
/// Uses the Haversine formula to determine distance across a spherical Earth model.
/// For highly accurate geodetic calculations over long distances, use an ellipsoidal model instead.
///
/// - Parameter destination: The target coordinate to measure distance toward.
/// - Parameter unit: The unit of length for the result. Defaults to `.meters`.
/// - Returns: The distance between the two points expressed in the requested unit.
/// - Throws: `NavigationError.invalidCoordinates` if either coordinate contains NaN or infinite values.
public func distance(
    to destination: Coordinate,
    unit: DistanceUnit = .meters
) throws -> Double { ... }
```

When documenting multiple parameters, you may also use a grouped `- Parameters:` block:

```swift
/// - Parameters:
///   - destination: The target coordinate to measure distance toward.
///   - unit: The unit of length for the result.
```

### Callout directives

DocC parses GitHub-style blockquote callouts to highlight notes, warnings, and tips:

```swift
/// > Note:
/// > Coordinates use the standard WGS 84 datum.

/// > Important:
/// > Always check network reachability before initiating batch geocoding.

/// > Warning:
/// > Calling this method from a background thread while the view is animating may cause dropped frames.

/// > Tip:
/// > Cache the computed bounding box if performing repeated hit tests.

/// > Experiment:
/// > Try adjusting the convergence threshold to observe performance differences.
```

Supported callout heads: `Note`, `Important`, `Warning`, `Tip`, `Experiment`.

---

## 2. Documentation catalogs (`.docc`)

A documentation catalog is a folder with the `.docc` extension placed inside your target's source directory (e.g., `Sources/MyFramework/MyFramework.docc`). It holds:
- The target landing page (`MyFramework.md`)
- Conceptual articles (`.article` or `.md`)
- Documentation extension files (`.md`)
- Media assets (`Resources/images/`, `Resources/videos/`)

### Catalog directory layout

```
Sources/
└── MyFramework/
    ├── MyFramework.docc/
    │   ├── MyFramework.md              # Target landing page
    │   ├── Articles/
    │   │   ├── GettingStarted.md       # Conceptual guide
    │   │   └── ConcurrencyModel.md
    │   ├── Extensions/
    │   │   └── Coordinate+Extensions.md # Supplemental symbol doc
    │   └── Resources/
    │       └── hero-overview@2x.png
    ├── Coordinate.swift
    └── Engine.swift
```

---

## 3. The target landing page

The landing page introduces the library or module. The top-level heading must match the module name wrapped in double backticks:

```markdown
# ``MyFramework``

A high-performance geodetic calculation engine with built-in spatial indexers.

## Overview

MyFramework provides spatial primitives and spatial indexing structures for mapping
and route optimization applications. Designed for Swift 6, all public types conform to
`Sendable` and integrate with modern concurrency.

### Key capabilities

- **Deterministic math**: Rigorous Haversine and Vincenty geodesic implementations.
- **Spatial indexing**: Quadtree and R-Tree implementations optimized for low-latency queries.
- **Strict concurrency**: Fully validated under `-strict-concurrency=complete`.

## Topics

### Essentials

- <doc:GettingStarted>
- ``Coordinate``
- ``DistanceUnit``

### Spatial queries

- ``SpatialIndex``
- ``BoundingBox``
- <doc:ConcurrencyModel>

### Supporting types

- ``NavigationError``
```

---

## 4. Symbol links and cross-referencing

DocC uses double backticks to reference symbols and `<doc:...>` to reference articles and pages.

### Symbol reference syntax

| Syntax | Target | Example |
| :--- | :--- | :--- |
| ` ``TypeName`` ` | Type in current module | ` ``Coordinate`` ` |
| ` ``TypeName/property`` ` | Member property | ` ``Coordinate/latitude`` ` |
| ` ``TypeName/method(_:)`` ` | Member method | ` ``Coordinate/distance(to:unit:)`` ` |
| ` ``Module/TypeName`` ` | Scoped to specific module | ` ``SpatialKit/Coordinate`` ` |

### Disambiguating overloads

When multiple methods share the same base name, specify the argument labels:
- ` ``Engine/start()`` `
- ` ``Engine/start(withConfiguration:)`` `
- ` ``Engine/start(retries:timeout:)`` `

When symbols share identical base names and argument labels, DocC provides disambiguation suffixes based on symbol kind, parameter types, return types, or collision hashes:

| Disambiguation Type | Suffix Syntax | Example |
| :--- | :--- | :--- |
| **Symbol Kind** | `-<kind>` | ` ``Coordinate-struct`` `, ` ``Coordinate-enum`` ` |
| **Parameter Types** | `-(<types>)` | ` ``distance(to:)-(Coordinate,_)`` ` |
| **Return Type** | `-><type>` | ` ``distance(to:)->Double`` ` |
| **Parameters & Return** | `-(<types>)-><type>` | ` ``process(_:)-(Data)->Bool`` ` |
| **Unique Identifier Hash** | `-<hash>` | ` ``update(value:)-4gcpg`` ` |

### Article and path links

- Link to articles: `<doc:GettingStarted>` or `<doc:ConcurrencyModel>` (DocC resolves articles by filename without catalog subfolder prefixes)
- Link to external URLs: standard Markdown `[Apple Developer](https://developer.apple.com)`

---

## 5. Topic curation and organization

By default, DocC lists all uncurated symbols under auto-generated headings like "Structures", "Classes", and "Protocols". **High-quality documentation replaces auto-generation with intentional curation.**

### Curating topics on landing pages and symbols

Add a `## Topics` section to any landing page, article, or symbol extension:

```markdown
## Topics

### Spatial computation

- ``Coordinate``
- ``BoundingBox``
- ``distance(from:to:)``

### Data storage

- ``SpatialIndex``
- ``SpatialCache``
```

When a symbol is placed in a `## Topics` section, DocC removes it from the automatic fallback bucket and nests it under your curated task group.

---

## 6. Documentation extension files

When in-source comments become too verbose, or when you want to curate child symbols without cluttering Swift source files, use a **Documentation Extension File**.

Create a Markdown file inside the catalog (e.g., `Extensions/Coordinate.md`):

```markdown
# ``MyFramework/Coordinate``

Supplemental architectural guide for coordinate precision and coordinate systems.

## Overview

While `Coordinate` represents WGS 84 points by default, you can convert coordinates
to projected planar coordinate systems using projection adapters.

### Precision guidelines

Floating-point precision limits can affect calculation accuracy near the poles.
Refer to the geodesic accuracy table below when choosing between Haversine and Vincenty algorithms.

## Topics

### Geodesic distance

- ``distance(to:unit:)``
- ``bearing(to:)``
```

The content in this extension file merges directly with the in-source comments attached to `Coordinate`.

---

## 7. Symbol graphs and compilation

DocC operates on **Symbol Graph JSON files** produced by the Swift compiler:
1. `swift build` or Xcode builds the target with `-emit-symbol-graph`.
2. The compiler writes JSON symbol graphs describing declarations, doc comments, protocols, and relationships.
3. DocC consumes the symbol graphs together with the `.docc` catalog to produce the final website or `.doccarchive`.

To inspect symbol graphs directly via Swift Package Manager:
```bash
swift package dump-symbol-graph
```

This dumps the generated symbol graph JSON files into `.build/extracted-symbols/`.

---

## 8. Documenting the Xcode agent skills ecosystem

Xcode 16 and subsequent releases bundle official coding agent skills authored by Apple engineers. You can inspect or export these built-in agent skills using the Xcode developer tools:

```bash
# Export Apple's built-in coding agent skills to a local directory
xcrun agent skills export --output-dir /path/to/exported-skills
```

### The Apple built-in skills vs. DocC gap

When exported, Xcode provides 10 specialized agent skills:
- `swiftui-specialist` & `swiftui-whats-new-27`: SwiftUI best practices, view lifecycle, `@Observable`, and modern iOS 26/27 APIs.
- `app-intents-specialist` & `app-intents-whats-new-27`: App Intents execution models, entities, queries, and assistant integration.
- `c-bounds-safety` & `adopt-c-bounds-safety`: The `-fbounds-safety` C language extension and buffer hardening.
- `accessibility`: Auditing and remediation for WCAG and accessibility APIs.
- `modernize-tests` / `test-modernizer`: Migration from XCTest to Swift Testing.
- `building-document-based-swiftui-applications`: Modern `Document` protocol architecture.
- `uikit-app-modernization` & `app-resizability`: Multi-window adaptivity, Stage Manager, and foldable displays.

Crucially, **Xcode exports zero skills for Swift DocC, documentation authoring, or interactive tutorial engineering**. Apple's developer tooling relies on community documentation and developer experience workflows to fill this gap.

The `swift-docc-skills` repository serves as the definitive, authoritative suite that complements Apple's built-in Xcode agent skills, equipping AI coding agents and human engineers with the exact standards Apple uses internally for DocC documentation and *Develop in Swift* interactive tutorials.

---

## 9. Reference documentation quality checklist

- [ ] All headings, topics, and titles are written in **strict sentence case**.
- [ ] All public APIs have a single-sentence summary followed by detailed context.
- [ ] Every parameter, return value, and thrown error is explicitly documented.
- [ ] Code examples within doc comments use triple-backtick ```swift blocks.
- [ ] All symbol links (` ``SymbolName`` `) resolve without DocC compile-time warnings.
- [ ] Landing page (`<TargetName>.md`) curates symbols into logical, task-oriented `## Topics`.
- [ ] No uncurated symbols fall into default, auto-generated category buckets.
- [ ] Documentation catalogs adhere to the standard `.docc` folder hierarchy.

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

---

# Swift DocC publishing and deployment

This skill provides step-by-step instructions, CLI flag references, and CI/CD pipelines for compiling Swift DocC documentation into static websites, previewing them locally, and hosting them on GitHub Pages or static web servers.

# References
- `references/hosting-and-ci-cd.md`: Consult when configuring CLI compilation flags, setting `--hosting-base-path` for GitHub Pages, previewing static sites locally, configuring GitHub Actions workflows, or troubleshooting 404/SPA routing issues.

---

## 1. Compilation methods overview

DocC documentation can be compiled using either the **Swift Package Manager DocC Plugin** (`swift-docc-plugin`) or direct invocations of **`xcrun docc`** / **`docc`**.

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          DocC compilation pipeline                       │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     │
         ┌───────────────────────────┴───────────────────────────┐
         ▼                                                       ▼
┌─────────────────────────────────┐             ┌─────────────────────────────────┐
│     Swift Package Manager       │             │       Direct DocC CLI           │
│  swift package                  │             │  xcrun docc convert             │
│  generate-documentation         │             │  (lower-level, custom pipelines)│
└────────────────┬────────────────┘             └────────────────┬────────────────┘
                 │                                               │
                 └───────────────────────┬───────────────────────┘
                                         ▼
                        ┌─────────────────────────────────┐
                        │     Static hosting transform    │
                        │  --transform-for-static-hosting │
                        │  --hosting-base-path <repo>     │
                        │  --output-path <dir>            │
                        └────────────────┬────────────────┘
                                         ▼
                        ┌─────────────────────────────────┐
                        │     Deployment targets          │
                        │  GitHub Pages, Cloudflare, S3   │
                        └─────────────────────────────────┘
```

---

## 2. Essential CLI flags reference

When generating static documentation for the web, three flags are essential:

| Flag | Description | When to Use |
| :--- | :--- | :--- |
| `--transform-for-static-hosting` | Generates a static HTML/JS/CSS client-side router build ready for standard web servers. | **Mandatory** for hosting on GitHub Pages, Cloudflare Pages, Netlify, or Amazon S3. |
| `--hosting-base-path <path>` | Sets the base URL path prefix for all routing, scripts, and media requests (e.g., `<repo-name>`). | **Mandatory** when hosting on GitHub Pages under a project repository URL (`https://<user>.github.io/<repo-name>/`). Omit for root user/org domains. |
| `--output-path <path>` | Specifies the output destination folder where HTML, CSS, JavaScript, and JSON data are written. | Always specify an explicit path (e.g., `.build/docc-static` or `docs`). |
| `--disable-indexing` | Skips client-side search index generation (`index/`). | Optional: use in resource-constrained CI to accelerate builds when search is not needed. |

---

## 3. Compiling with Swift Package Manager

### Using the Swift-DocC plugin

Add the official Swift-DocC plugin to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0"),
]
```

### Compiling static documentation for GitHub Pages

Run `swift package generate-documentation` with the static hosting flags:

```bash
swift package --allow-writing-to-directory ./docs \
    generate-documentation \
    --target MyLibrary \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path my-repo-name \
    --output-path ./docs
```

> [!IMPORTANT]
> **Base Path Formatting**:
> - **Project Pages** (`https://<user>.github.io/<repo-name>/`): Pass `--hosting-base-path <repo-name>` (omit leading and trailing slashes). For `https://peterfriese.github.io/swift-docc-skills/`, use `--hosting-base-path swift-docc-skills`.
> - **User or Organization Pages** (`https://<user>.github.io/`): Omit `--hosting-base-path` entirely so all asset paths resolve from the root domain `/`.

---

## 4. Compiling with `xcrun docc` directly

If you prefer compiling directly using Xcode's embedded toolchain:

```bash
# 1. Dump symbol graphs
swift package dump-symbol-graph

# 2. Convert documentation catalog and symbols into static web output
xcrun docc convert Sources/MyLibrary/MyLibrary.docc \
    --fallback-display-name MyLibrary \
    --fallback-bundle-identifier com.example.MyLibrary \
    --fallback-bundle-version 0.1.0 \
    --additional-symbol-graph-dir .build/extracted-symbols \
    --transform-for-static-hosting \
    --hosting-base-path my-repo-name \
    --output-path ./docs
```

---

## 5. Local live preview

### Option A: Built-in SwiftPM live preview server

The Swift-DocC plugin includes a live development server that automatically rebuilds and refreshes when files change:

```bash
swift package --disable-sandbox preview-documentation --target MyLibrary
```

This starts a local server at `http://localhost:8080/documentation/mylibrary`.

### Option B: Previewing static export via Python HTTP server

To preview the exact static artifact that will be deployed to GitHub Pages:

```bash
# Generate static build with root base path
swift package --allow-writing-to-directory .build/docc-static \
    generate-documentation \
    --target MyLibrary \
    --transform-for-static-hosting \
    --output-path .build/docc-static

# Run local HTTP server
python3 -m http.server 8000 --directory .build/docc-static
```

Open `http://localhost:8000/documentation/mylibrary` or `http://localhost:8000/tutorials/mycurriculum` in your browser.

---

## 6. Automated GitHub Pages CI/CD workflow

Create `.github/workflows/documentation.yml` in your repository:

```yaml
name: Deploy DocC Documentation to GitHub Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

# Sets permissions of the GITHUB_TOKEN to allow deployment to GitHub Pages
permissions:
  contents: read
  pages: write
  id-token: write

# Allow one concurrent deployment
concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: macos-15
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.2.app

      - name: Generate Static DocC Documentation
        run: |
          swift package --allow-writing-to-directory ./docs \
            generate-documentation \
            --target MyLibrary \
            --disable-indexing \
            --transform-for-static-hosting \
            --hosting-base-path "${{ github.event.repository.name }}" \
            --output-path ./docs

      - name: Verify Myers Diff Highlights
        run: |
          if [ -f "scripts/audit-docc-highlights.py" ]; then
            python3 scripts/audit-docc-highlights.py ./docs/data/tutorials --allow-empty
          fi

      - name: Upload GitHub Pages Artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./docs

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

---

## 7. Common deployment troubleshooting

### Issue 1: Blank screen or 404 on CSS/JS assets
- **Cause**: Incorrect `--hosting-base-path`. If your GitHub repository is `username/my-lib`, the site lives at `https://username.github.io/my-lib/`.
- **Solution**: Pass `--hosting-base-path my-lib` during generation.

### Issue 2: Direct page links return 404 on static hosts
- **Cause**: DocC produces a Single Page App (SPA). Navigating directly to `https://site.com/documentation/target/symbol` requires fallback routing to `index.html`.
- **Solution**: `--transform-for-static-hosting` creates routing fallback index files automatically. Ensure your web server does not rewrite paths or strip HTML extensions.

### Issue 3: Interactive tutorials fail to display code highlights
- **Cause**: Myers diff brace shift defect in compiled tutorial JSON files.
- **Solution**: Run `scripts/audit-docc-highlights.py ./docs/data/tutorials` in CI to catch and remediate brace shifts before publishing.
