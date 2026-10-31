# Symbol curation, documentation extensions, and symbol linking

This reference provides in-depth guidance for curating DocC topic hierarchies, authoring documentation extension files, resolving symbol links, and disambiguating method overloads.

---

## 1. Documentation catalog architecture

A documentation catalog is a folder with the `.docc` extension placed inside your target's source folder:

```
Sources/MyFramework/
├── MyFramework.docc/
│   ├── MyFramework.md                  # Target landing page
│   ├── Articles/
│   │   ├── GettingStarted.md           # Conceptual guide
│   │   └── ConcurrencyModel.md
│   ├── Extensions/
│   │   └── Coordinate.md               # Documentation extension file
│   └── Resources/
│       ├── images/
│       │   ├── hero-overview.png
│       │   ├── architecture-flow.svg
│       │   └── architecture-flow~dark.svg
│       └── downloads/
├── Coordinate.swift
└── Engine.swift
```

---

## 2. Target landing page curation

The landing page (`<TargetName>.md`) provides the module's executive overview. The top-level heading must match the target's module name wrapped in double backticks:

```markdown
# ``MyFramework``

A high-performance spatial calculation engine with deterministic geodetic indexing.

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

### Spatial computation

- ``SpatialIndex``
- ``BoundingBox``
- <doc:ConcurrencyModel>

### Supporting types

- ``NavigationError``
```

### Why manual curation is required
By default, DocC places all uncurated symbols into generic, auto-generated buckets like "Structures", "Classes", and "Protocols". **Professional documentation replaces auto-generated buckets with intentional, task-oriented topic groups** (`### Essentials`, `### Performing spatial queries`, `### Error handling`).

---

## 3. Documentation extension files

When in-source triple-slash comments become too lengthy, or when you want to curate child symbols without adding hundreds of lines of Markdown to Swift source files, use a **Documentation Extension File**.

Create a Markdown file inside `.docc/Extensions/` (e.g., `Extensions/Coordinate.md`):

```markdown
# ``MyFramework/Coordinate``

Supplemental architectural guide for coordinate precision, projections, and geodetic calculations.

## Overview

While `Coordinate` represents WGS 84 points by default, you can convert coordinates
to projected planar coordinate systems using projection adapters.

### Precision guidelines

Floating-point precision limits can affect calculation accuracy near the poles.
Refer to the geodesic accuracy table below when choosing between Haversine and Vincenty algorithms.

## Topics

### Geodesic calculations

- ``distance(to:unit:)``
- ``bearing(to:)``

### Projection adapters

- ``projectedPoint(using:)``
```

The contents of this file merge directly into the documentation generated from the in-source doc comments attached to `Coordinate`.

---

## 4. Symbol linking and disambiguation

DocC uses double backticks to reference symbols and `<doc:...>` to link articles.

### Symbol reference syntax

| Syntax | Target | Example |
| :--- | :--- | :--- |
| ` ``TypeName`` ` | Type in current target | ` ``Coordinate`` ` |
| ` ``TypeName/property`` ` | Member property | ` ``Coordinate/latitude`` ` |
| ` ``TypeName/method(_:)`` ` | Member method | ` ``Coordinate/distance(to:unit:)`` ` |
| ` ``Module/TypeName`` ` | Type in specific module | ` ``SpatialKit/Coordinate`` ` |

### Disambiguating overloads

When multiple methods share the same base name, specify the argument labels:
- ` ``Engine/start()`` `
- ` ``Engine/start(withConfiguration:)`` `
- ` ``Engine/start(retries:timeout:)`` `

When symbols share identical base names and argument labels, DocC provides disambiguation suffixes based on symbol kind, parameter types, return types, or collision hashes:

| Disambiguation type | Suffix syntax | Example |
| :--- | :--- | :--- |
| **Symbol kind** | `-<kind>` | ` ``Coordinate-struct`` `, ` ``Coordinate-enum`` ` |
| **Parameter types** | `-(<types>)` | ` ``distance(to:)-(Coordinate,_)`` ` |
| **Return type** | `-><type>` | ` ``distance(to:)->Double`` ` |
| **Parameters & return** | `-(<types>)-><type>` | ` ``process(_:)-(Data)->Bool`` ` |
| **Collision hash** | `-<hash>` | ` ``update(value:)-4gcpg`` ` |

---

## 5. Inspecting symbol graphs

DocC operates on symbol graphs emitted by the Swift compiler:
```bash
# Dump JSON symbol graphs to .build/extracted-symbols/
swift package dump-symbol-graph
```

Inspect these JSON files to verify symbol availability, access levels (`public` vs `internal`), and relationship declarations.
