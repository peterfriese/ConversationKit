# Strict sentence case editorial standard

This reference provides the complete editorial guide and capitalization dictionary for writing Apple-grade technical documentation in strict sentence case.

---

## 1. The sentence case mandate

Apple technical documentation strictly uses **sentence case** across all structural and contextual elements. Headings, labels, and titles must read naturally as standard English sentences, avoiding the artificial formality of Title Case.

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

---

## 2. Scope across the documentation catalog

Sentence case applies unconditionally across every catalog surface:
- **Tutorial & article titles**:
  - `@Intro(title: "Configuring the data store")`
  - `@Intro(title: "Building a quick chat prototype")`
  - `# Creating a photo card`
- **Markdown headings**:
  - `# Overview`
  - `## Topics`
  - `### View components`
  - `### Data flow and state`
- **Section headers**:
  - `@Section(title: "Assemble the card layout")`
  - `@Section(title: "Bind the model to the interface")`
- **Table headers**:
  - `| Parameter name | Expected type | Description |`
- **Vector diagram labels**:
  - `<text>User action</text>`
  - `<text>Observable data store</text>`
  - `<text>Single source of truth</text>`
- **Navigation and chapter names**:
  - `@Chapter(name: "Core interface and navigation")`
  - `@Chapter(name: "Persistence and data flow")`

---

## 3. Capitalization dictionary

### Approved proper nouns (always capitalize)
- **Platforms**: `iOS`, `iPadOS`, `macOS`, `watchOS`, `tvOS`, `visionOS`
- **Apple technologies**: `Apple`, `Xcode`, `Swift`, `SwiftUI`, `SwiftData`, `Core Data`, `Core ML`, `Combine`, `Foundation`, `AppKit`, `UIKit`, `Metal`, `CloudKit`, `StoreKit`, `Instruments`, `TestFlight`
- **Hardware & systems**: `Mac`, `MacBook`, `iPhone`, `iPad`, `Apple Watch`, `Apple Vision Pro`, `Apple Silicon`, `Neural Engine`

### Approved technical acronyms (always capitalize)
- `API`, `SDK`, `REST`, `HTTP`, `HTTPS`, `URL`, `URI`, `JSON`, `XML`, `SQL`, `SQLite`, `CLI`, `CI/CD`, `AST`, `HIG`, `ANE`, `GPU`, `CPU`, `UUID`, `RGBA`, `SVG`, `PNG`

### Code identifiers (preserve exact code capitalization in backticks)
- Conforming types: `` `View` ``, `` `ModelContext` ``, `` `Coordinate` ``
- Macros and property wrappers: `` `@Observable` ``, `` `@Model` ``, `` `@State` ``, `` `@Binding` ``, `` `@Environment` ``
- Protocols: `` `Sendable` ``, `` `Identifiable` ``, `` `Hashable` ``

---

## 4. Title case vs. sentence case lookup table

| ❌ Forbidden Title Case | ✅ Required Sentence Case | Rule / Rationale |
| :--- | :--- | :--- |
| *Creating A Custom Card View* | *Creating a custom card view* | Only the initial word is capitalized. |
| *Integrating With Core ML And SwiftData* | *Integrating with Core ML and SwiftData* | Preserve proper nouns (*Core ML*, *SwiftData*). |
| *Fetching Remote JSON Via The HTTP API* | *Fetching remote JSON via the HTTP API* | Preserve technical acronyms (*JSON*, *HTTP*, *API*). |
| *Conforming To The View Protocol* | *Conforming to the `View` protocol* | Code types are identifiers formatted in backticks. |
| *Step 1: Setting Up The Project* | *Step 1: Setting up the project* | Sub-clauses following colons remain in sentence case. |
| *Understanding State And Data Flow* | *Understanding state and data flow* | Conjunctions and prepositions are lowercase. |
| *Configuring Navigation And Toolbar Items* | *Configuring navigation and toolbar items* | Only the first word is capitalized. |
| *Building The Detail View Layout* | *Building the detail view layout* | Lowercase general layout terminology. |
| *Single Source Of Truth* | *Single source of truth* | Lowercase all words after the initial term. |
| *Actions Flow Up* | *Actions flow up* | Diagram text labels follow sentence case. |

---

## 5. Edge cases and punctuation

### Headings with colons
When a heading or title contains a colon, capitalize the first letter following the colon if it introduces an independent clause or sub-title:
- `Step 1: Setting up the project`
- `Getting started: An architectural introduction`

### Version identifiers
Preserve standard numeric and version notation:
- `Updating to Swift 6`
- `Adopting Xcode 16 features`
