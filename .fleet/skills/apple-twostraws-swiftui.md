---
id: apple-twostraws-swiftui
name: TwoStraws SwiftUI Agent Skill
author: Paul Hudson
platform: apple
repository: twostraws/SwiftUI-Agent-Skill
path: swiftui-pro
default: true
description: Best practices for modern SwiftUI layout, state management, animations, and navigation.
---

# TwoStraws SwiftUI Agent Skill

Expert guidance by Paul Hudson on building idiomatic, high-performance SwiftUI applications for iOS 17+.

## Key Guidance

- **State Management**: Use `@State` for local view state, `@Binding` for two-way child bindings, and `@Observable` classes for domain state.
- **View Composition**: Break large views into smaller private computed properties or subviews to optimize SwiftUI body evaluation.
- **Navigation**: Use type-safe `NavigationStack(path:)` with `.navigationDestination(for:)`.
