---
name: swift-docc-reference
description: Guide for authoring Swift DocC API reference documentation, in-source doc comments, documentation catalogs, topic curation, symbol graphs, and Xcode agent skills integration.
---

# Swift DocC API Reference & Topic Curation

- Write clear single-sentence summaries on all public symbols using triple-slash (`///`) comments.
- Document parameters (`- Parameters:`), return values (`- Returns:`), and thrown errors (`- Throws:`).
- Organize public APIs logically under `## Topics` and `### Category` headings in the root `.docc` landing page.
- Link symbols deterministically using double backticks (`` ``MyType/method()`` ``).

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
