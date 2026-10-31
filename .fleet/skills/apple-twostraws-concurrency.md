---
id: apple-twostraws-concurrency
name: TwoStraws Swift Concurrency Agent Skill
author: Paul Hudson
platform: apple
repository: twostraws/Swift-Concurrency-Agent-Skill
path: swift-concurrency-pro
default: true
description: Modern Swift concurrency, async/await, actors, Task cancellation, and Sendable safety.
---

# TwoStraws Swift Concurrency Agent Skill

Covers Swift structured concurrency best practices, avoiding data races, and mastering async/await.

## Key Guidance

- Always mark UI-updating classes and view models with `@MainActor`.
- Use `nonisolated` for functions that do not touch actor-isolated state.
- Ensure all types passed across concurrency boundaries conform to `Sendable`.
