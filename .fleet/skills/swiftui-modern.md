---
id: swiftui-modern
name: Modern SwiftUI Standards
author: Paul Hudson / Stratos
platform: apple
repository: twostraws/SwiftUI-Agent-Skill
path: swiftui-pro
default: true
description: Modern declarative SwiftUI patterns, @Observable macro, and view composition standards
---

# Modern SwiftUI Standards

- Use the `@Observable` macro for view models; avoid legacy `ObservableObject` and `@Published`.
- Use `#Preview` macros with lightweight mock states.
- Avoid heavyweight computation or allocations in view body evaluation.
- Keep view hierarchies modular with localized subviews.
