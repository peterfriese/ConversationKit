---
id: apple-avanderlee-concurrency
name: Antoine van der Lee — Swift Concurrency & Swift 6 Migration
author: Antoine van der Lee
platform: apple
repository: AvdLee/Swift-Concurrency-Agent-Skill
path: skills/swift-concurrency
default: true
description: Advanced Swift 6 strict concurrency migration, data race prevention, actor reentrancy, and AsyncAlgorithms.
---

# Antoine van der Lee — Swift Concurrency Agent Skill

Comprehensive guidance from SwiftLee on navigating Swift 6 strict concurrency checks and migrating legacy GCD/completion handler code.

## Key Guidance

- **Strict Concurrency**: Resolve all compiler warnings under `-strict-concurrency=complete`.
- **Actor Reentrancy**: Never assume actor state is unchanged across an `await` suspension point.
- **Global Actors**: Use `@MainActor` consistently for observable view models.
