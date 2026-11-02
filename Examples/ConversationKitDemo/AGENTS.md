# Component: ConversationKitDemo

## Component Overview

`ConversationKitDemo` is the interactive showcase application for **ConversationKit v2** on iOS 26+ and macOS 26+. It exercises all four layers of the Stratos Progressive Disclosure architecture in a single self-contained app, including live Liquid Glass style switching, Top-Floating Turn streaming physics, `/commands`, `@mentions`, model and capability selectors, multimodal attachments with simulated upload progress, and agentic timeline primitives (`ThinkingTrace`, `ToolCall`, `Citation`, `AgentPlan`, `ApprovalRequest`, and `MessageError`).

## Key Files and Structure

*   **`ConversationKitDemo/ConversationKitDemoApp.swift`**: Main `@main` entry point of the demo application. Supports launch arguments (`--ui-testing-empty`, `--ui-testing-fast-stream`, `--ui-testing-long-thread`) for deterministic UI automation.
*   **`ConversationKitDemo/ContentView.swift`**: Hosts `ConversationView` and an interactive Inspector/Toolbar switcher allowing live toggling between:
    *   **`MessageComposerStyle`**: `.classicGlass` (default 3-zone bookend sibling layout), `.cardGlass` (2-row AI assistant card), and `.compactGlass` (single-row compact capsule).
    *   **`ThinkingStateStyle`**: `.collapsibleHeader`, `.pill`, and `.minimal`.
    *   **`UserMessageBubbleStyle`**: `.tailedBubble`, `.roundedCard`, and `.capsule`.
    *   **60Hz Streaming Cadence Smoother**: `.streamingCadenceEnabled(_:)`.
    *   **Multimodal Attachments & Upload Simulation**: Photos picker integration (`PhotosPickerItem` -> `PlatformImageBox` -> `ConversationAttachment`) plus one-tap sample image/file attachments and `.onAttachmentUpload` / `.onAttachmentRetry` lifecycle simulation (`ConversationAttachment.UploadState`).
    *   **Structured Prompting**: `/commands` (`SlashCommand`), `@mentions` (`ResourceMention`), suggestion chips (`PromptSuggestion` & `PromptHandoffBehavior`), model picker (`ComposerModelOption`), and capability toggles (`ComposerCapability`).
    *   **Agentic Scenarios**: Simulated multi-phase streaming (reasoning trace -> tool calls -> plan updates -> human-in-the-loop approval card -> 120Hz streaming Markdown with code blocks and citations -> inline retryable `MessageError` simulation).
*   **`ConversationKitDemo/DemoSampleData.swift`**: Pre-populated v2 sample conversations, slash commands, resource mentions, model options, capabilities, prompt suggestions, and programmatic sample image/document attachments.
*   **`ConversationKitDemoUITests/ConversationKitDemoUITests.swift`**: End-to-end XCUITest suite verifying style switching, prompt submission, top-floating turn anchoring, agentic disclosure interactions, and attachment tray behavior.
*   **`ConversationKitDemo.xcodeproj`**: Xcode project file for building and running the demo app and UI test target.

## Dependencies and Relationships

*   Depends solely on the local `ConversationKit` Swift package (`../..`). Zero third-party dependencies.

## Technical Details

*   **Building and Running**: Open `Examples/ConversationKitDemo/ConversationKitDemo.xcodeproj` in Xcode 26+ and run the `ConversationKitDemo` scheme on an iOS 26+ simulator, macCatalyst, or macOS 26+.
