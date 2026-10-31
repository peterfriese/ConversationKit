---
id: swift-testing-pro
name: Swift Testing Pro
author: Paul Hudson (twostraws)
platform: apple
repository: https://github.com/twostraws/swift-testing-agent-skill
path: skills/swift-testing-pro
branch: main
default: true
description: "Modern Swift Testing framework (@Suite, @Test, #expect, #require, parameterized tests, and traits)."
---

# Skill: Swift Testing Pro

## Core Directives
1. **Modern Framework**: Always use Swift's modern `Testing` framework (`import Testing`) instead of `XCTest` for new unit and integration tests.
2. **Assertions**: Use `#expect(...)` for standard boolean and value checks, and `try #require(...)` to unwrap optionals or halt execution when a precondition fails.
3. **Organization**: Group related tests using `@Suite("...") struct ...` and annotate test functions with `@Test("...")`.
4. **Parameterized Testing**: Replace repetitive test cases with `@Test(arguments: [...])` to test boundary conditions cleanly.
