---
id: docc-authoring
name: DocC Authoring Standards
author: Peter Friese
platform: apple
repository: peterfriese/swift-docc-skills
path: skills/swift-docc-reference
skills:
  - swift-docc-reference
  - swift-docc-tutorials
  - swift-docc-techwriting
  - swift-docc-diagrams
  - swift-docc-publishing
default: true
description: Apple DocC documentation syntax, symbol references, and API topic curation
---

# DocC Authoring Standards

- Use strict sentence case for headings.
- Format parameter documentation with `- Parameters:` bullet points.
- Include code examples inside fenced code blocks (` ```swift `) in doc comments for all public entry points.
- Ensure all linked symbols use double backticks (e.g. ``MyType/performAction()``).
