# Component: A2UIConversationDemo

## Component Overview

`A2UIConversationDemo` is a multiplatform reference application demonstrating how to integrate **ConversationKit v2** with **Google A2UI v1.0** (`A2UISwiftCore`, `A2UISwiftUI`, `BasicCatalog`, `BasicCatalogSwiftUI`), **Firebase AI Logic** (Gemini 3 Flash / 3.1 Pro), and the **A2A JSON-RPC Agent Protocol** on iOS 26.0+ and macOS 26.0+.

Every assistant turn pairs incremental conversational Markdown (`StreamingMarkdownView`) and agentic timeline disclosures (`ThinkingTrace`, `ToolCall`) with live, interactive **A2UI v1.0 Basic Catalog** surfaces rendered directly inside the conversation timeline.

## Key Files and Structure

*   **`A2UIConversationDemo/A2UIConversationDemoApp.swift`**: Main `@main` entry point launching `ContentView`.
*   **`A2UIConversationDemo/Models/A2UIChatMessage.swift`**: Defines `A2UIChatMessage: Message` (implementing `static func makeUserMessage(id:content:attachments:tokens:selectedModelID:) -> A2UIChatMessage`) with `surfaceIDs: [String]`, `rawA2UIMessages: [String]`, `actionBadge: String?`, `A2UIEventLog`, and `A2UIDemoPresets` (Gemini 3 & A2A `ComposerModelOption` items, `/commands`, and `PromptSuggestion` chips).
*   **`A2UIConversationDemo/Services/A2UISystemPrompt.swift`**: System instruction teaching Gemini 3 how to emit strict A2UI v1.0 Basic Catalog JSON (`createSurface` → `updateComponents` → `updateDataModel`) wrapped in `<a2ui-json>[...]</a2ui-json>`, plus the incremental streaming extractor (`parseAccumulatedText(_:)`).
*   **`A2UIConversationDemo/Services/A2AClient.swift`**: A2A JSON-RPC client (`message/stream`) connecting to local A2UI agent servers (`http://localhost:10002/a2a/json-rpc`).
*   **`A2UIConversationDemo/Services/CatalogExamplesStore.swift`**: Loads bundled A2UI v1.0 Basic Catalog specification examples and rewrites `surfaceId` values per turn so multiple turns in the same timeline own independent surface instances.
*   **`A2UIConversationDemo/ViewModels/A2UIConversationViewModel.swift`**: `@MainActor @Observable` coordinator managing `MessageProcessor`, Firebase AI Logic `Chat` sessions, A2A turns, deterministic `/commands`, schema validation self-correction, and two-way `ActionHandling` callbacks (`ConversationA2UIActionBridge`).
*   **`A2UIConversationDemo/Views/A2UIMessageRowView.swift`**: Composes `ConversationKit`'s `MessageView(message:)` with inline `A2UISwiftUI.Surface` cards and an **Inspect JSON** header button (adhering to the Liquid Glass scrolling cell rule).
*   **`A2UIConversationDemo/Views/A2UIInspectorSheet.swift`**: Live DataModel JSON & raw A2UI protocol message inspector sheet, plus the A2UI v1.0 Catalog browser and A2A server configuration sheet.
*   **`A2UIConversationDemo/Views/ContentView.swift`**: Main `ConversationView` host with live switching between `.cardGlass`, `.classicGlass`, and `.compactGlass` composer styles.
*   **`A2UIConversationDemo.xcodeproj`**: Multiplatform Xcode project file for the application.

## Dependencies and Relationships

This component depends on the local `ConversationKit` package (`../..`) and:

*   **`A2UISwiftCore` / `A2UISwiftUI` / `BasicCatalog` / `BasicCatalogSwiftUI`**: Google A2UI Swift implementation (`../../../A2UI/a2ui`).
*   **`FirebaseAI` / `FirebaseAppCheck`**: Google Gemini 3 integration via Firebase AI Logic.

## Technical Details

*   **Building and Running**: Open `Examples/A2UIConversationDemo/A2UIConversationDemo.xcodeproj` in Xcode 26+ (or run via FlowDeck) on an iOS 26+ simulator or macOS 26+.
*   **Zero-Leak Credential Hygiene**: `GoogleService-Info.plist` is ignored by `.gitignore` and never committed to source control. If `GoogleService-Info.plist` is absent from the bundle, `A2UIConversationViewModel.configureFirebaseIfNeeded()` skips `FirebaseApp.configure()` gracefully so all bundled A2UI v1.0 `/commands` (`/coffee`, `/invitation`, `/dashboard`, `/workout`, `/music`), the Catalog Browser, and the Local A2A Agent mode run out-of-the-box without credentials.
*   **Two-Way Surface Actions**: When a user interacts with inputs (`TextField`, `ChoicePicker`, `CheckBox`, `Slider`, `DateTimeInput`) and taps an A2UI `Button` on any surface, `ConversationA2UIActionBridge` captures the `ResolvedAction` and live `DataModel` JSON and routes a follow-up turn back to Gemini 3 or the Local A2A Agent.
