---
id: swift-docc-reference
name: Swift DocC API Reference & Topic Curation
author: Peter Friese
platform: apple
repository: peterfriese/swift-docc-skills
path: skills/swift-docc-reference
default: true
description: "Guide for authoring Swift DocC API reference documentation, in-source doc comments, documentation catalogs, topic curation, symbol graphs, and Xcode agent skills integration."
---

# Swift DocC API Reference & Topic Curation

- Write clear single-sentence summaries on all public symbols using triple-slash (`///`) comments.
- Document parameters (`- Parameters:`), return values (`- Returns:`), and thrown errors (`- Throws:`).
- Organize public APIs logically under `## Topics` and `### Category` headings in the root `.docc` landing page.
- Link symbols deterministically using double backticks (`` ``MyType/method()`` ``).
