# Component: AIChatDemo

## Component Overview

`AIChatDemo` is a reference application demonstrating how to integrate **ConversationKit v2** with real-world cloud and on-device AI SDKs (**Firebase AI Logic** and **Apple Foundation Models**) on iOS 26+, macCatalyst 26+, and macOS 26+.

## Key Files and Structure

*   **`AIChatDemo/AIChatDemoApp.swift`**: Main `@main` entry point configuring a `TabView` with three live AI chat experiences.
*   **`AIChatDemo/FirebaseAILogicChatView.swift`**: Demonstrates Layer 1/2 integration with `FirebaseAI` (`gemini-2.5-flash`) using `DefaultMessage`, `[ConversationAttachment]`, `PhotosPicker`, `PlatformImageBox`, and strongly-typed `.onSendMessage { (submission: ConversationSubmission<DefaultMessage>) in ... }`.
*   **`AIChatDemo/FirebaseAILogicChatWithMetadataView.swift`**: Demonstrates Layer 4 custom model integration by defining `ChatMessage: Message` (implementing `static func makeUserMessage(id:content:attachments:tokens:selectedModelID:) -> ChatMessage`) to capture and render Gemini `UsageMetadata` (token counts), `FinishReason`, `CitationMetadata`, `GroundingMetadata`, and `PromptFeedback` alongside `MessageView(message: message)`.
*   **`AIChatDemo/FoundationModelChatView.swift`**: Demonstrates on-device Apple Intelligence integration using `FoundationModels` (`LanguageModelSession`), `ConversationSubmission<DefaultMessage>`, and `DefaultMessage(content:participant:error:)` error surfacing.
*   **`AIChatDemo.xcodeproj`**: Xcode project file for the application.

## Dependencies and Relationships

This component depends on the local `ConversationKit` package (`../..`) and:

*   **`FirebaseAI`**: Google Gemini integration via Firebase AI Logic.
*   **`FoundationModels`**: Apple's on-device language model framework (iOS 26.0+ / macCatalyst 26.0+ / macOS 26.0+).

## Technical Details

*   **Building and Running**: Open `Examples/AIChatDemo/AIChatDemo.xcodeproj` in Xcode 26+, add your `GoogleService-Info.plist` for Firebase AI Logic, and run on an iOS 26+ simulator or device.
*   **Strongly-Typed v2 Submission Flow**: All three views use `ConversationView`'s v2 `.onSendMessage { submission in ... }` modifier, appending `submission.message` directly (preserving `submission.message.id` for optimistic UI deduplication and zero downcasting).
*   **Multimodal Attachment Conversion**: In `FirebaseAILogicChatViewModel` and `FirebaseAILogicChatWithMetadataViewModel`, `submission.attachments` (`[ConversationAttachment]`) are mapped across all three `ConversationAttachment.Payload` cases (`.image(PlatformImageBox)`, `.data(Data, contentType:filename:)`, and `.file(URL)`) into `FirebaseAI`'s `InlineDataPart` values and sent alongside `submission.text`.
