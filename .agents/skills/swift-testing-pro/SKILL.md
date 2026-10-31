---
name: swift-testing-pro
description: Modern Swift Testing framework (@Suite, @Test,
---

# Swift Testing Framework Architecture

Architectural patterns and idioms for writing high-performance unit test suites using the modern Swift Testing library (`import Testing`).

## Key Principles

1. **Suite Structs & Scopes**: Group related test cases in `@Suite("Title") struct MyFeatureTests`. Use initialization (`init() async throws`) and deinitialization (`deinit`) for setup and teardown rather than override methods.
2. **Assertion Hierarchy**:
   - Use `#expect(condition, "Diagnostic context")` for standard non-terminating assertions.
   - Use `try #require(optional)` when an unwrapped value is essential for the remainder of the test execution, halting execution immediately upon nil.
3. **Parameterized Testing**: Test combinatorial inputs cleanly with `@Test("Matrix validation", arguments: [...]) func validate(input: String)`.
4. **Traits & Metadata**: Annotate tests with tags (`.tags(.networking)`), bug tracker references (`.bug("PROJ-123")`), or conditional execution traits (`.enabled(if: ...)`).
5. **Async Concurrency Safety**: Execute asynchronous test logic natively with async/await. Avoid legacy `XCTestExpectation` polling loops.

## Upstream Reference Documentation

The following reference documents were extracted from `apple/swift-testing`:

- [README.md](references/README.md)
