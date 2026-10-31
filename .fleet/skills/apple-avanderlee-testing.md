---
id: apple-avanderlee-testing
name: Antoine van der Lee — Swift Testing & XCTest Migration
author: Antoine van der Lee
platform: apple
repository: AvdLee/Swift-Testing-Agent-Skill
path: swift-testing-expert
default: false
description: Testing strategies, test suites, tags, traits, and migration patterns.
---

# Antoine van der Lee — Swift Testing Skill

Techniques for writing maintainable test suites and transitioning from XCTest to Swift Testing.

## Key Guidance

- **Test Suites**: Organize related unit tests into `@Suite` structs and use tags (`.tags(.critical)`) for categorization.
- **Assertions**: Migrate `XCTAssertEqual` to `#expect(a == b)` and `XCTUnwrap` to `try #require(optional)`.
- **Async Testing**: Write native `async` test functions without `XCTestExpectation` or timeout run loops.
