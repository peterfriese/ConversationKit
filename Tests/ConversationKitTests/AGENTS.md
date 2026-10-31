# Component: ConversationKitTests

## Component Overview

This component contains the unit tests for the `ConversationKit` library across iOS and macOS. It uses the modern **Swift Testing** framework (`import Testing`, `@Test`, `#expect`) rather than `XCTest`.

## Key Files and Structure

*   **`ConversationKitTests.swift`**: The primary test suite for `ConversationKit`, containing unit tests for data models, attachments, error handling mechanisms, and cross-platform utilities.

## Current Test Coverage

`ConversationKitTests` covers the following areas:

1.  **Message Models (`DefaultMessage`)**:
    *   `defaultMessageInitialization`: Verifies `DefaultMessage` initialization and property assignments (`content`, `participant`, `imageURL`, and `error`).
    *   `defaultMessageEquality`: Verifies `Equatable` and `Hashable` conformance on `DefaultMessage`, specifically confirming that equality and hashing ignore the `error` field and update when `content` changes.
2.  **Attachments (`ImageAttachment` & `EmptyAttachment`)**:
    *   `imageAttachment`: Verifies `ImageAttachment` unique `UUID` identity generation and `Equatable` conformance using platform-native images (`UIImage` on UIKit, `NSImage` on AppKit).
    *   `emptyAttachment`: Verifies `EmptyAttachment` unique identification (`id`) and inequality across distinct instances.
3.  **Error Handling (`ErrorWrapper` & `PresentErrorAction`)**:
    *   `errorWrapper`: Verifies that `ErrorWrapper` encapsulates underlying `Error` instances and assigns a unique `UUID` identifier.
    *   `presentErrorAction`: Verifies that invoking `PresentErrorAction` forwards the error to its handler closure.
4.  **Platform Helpers (`PlatformImage`)**:
    *   `platformImageSymbolResolution`: Verifies that `PlatformImage.systemSymbol(_:)` resolves SF Symbols (e.g., `"star.fill"`) into a non-nil platform image.

## Dependencies and Relationships

This test target depends on the `ConversationKit` library (`@testable import ConversationKit`).

## Technical Details

*   **Testing Framework**: Uses the **Swift Testing** framework (`import Testing`, `@Test`, `#expect`). Do not introduce legacy `XCTestCase` classes or `XCTAssert*` macros unless required for specific UI/performance harness interoperability.
*   **Running Tests**:
    *   **CLI**: Run `swift test` from the package root directory.
    *   **Xcode**: Open `Package.swift` in Xcode and press **Command-U** (`⌘U`).

## Planned vNext Test Areas

As `ConversationKit` expands with vNext capabilities, add Swift Testing suites covering:

*   **Welcome & Prompt Suggestions**: Empty-state welcome configuration, prompt suggestion model identity, and selection callback handling.
*   **ThinkingState**: Reasoning/thinking state lifecycle (streaming, duration tracking, collapsed/expanded states, and equatability).
*   **ToolCall Groups**: Tool invocation state transitions (pending, running, completed, failed), grouping behavior, and result formatting.
*   **Composer Modes**: Multi-mode composer state transitions, input validation, attachment synchronization, and send/stop cancellation behavior.
