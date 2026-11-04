# ConversationKit

`ConversationKit` is a native SwiftUI conversational AI and agentic chat SDK for **iOS 26.0+, macCatalyst 26.0+, and macOS 26.0+**, built with **Swift 6.2** strict concurrency (`Sendable`) and **zero external dependencies**.

It pairs native iOS 26 / macOS 26 **Liquid Glass** floating chrome with deterministic **Top-Floating Turn Physics**, **120Hz Incremental Streaming Markdown**, multimodal attachments, structured prompting (`/commands`, `@mentions`, model & capability selectors), and first-class agentic timeline primitives (`ThinkingTrace`, `ToolCall`, `Citation`, `AgentPlan`, `ApprovalRequest`) organized around the **Stratos 4-Layer Progressive Disclosure** architecture.

## ✨ Key Features

- 🪟 **Native iOS 26 / macOS 26 Liquid Glass Chrome**: Built on `GlassEffectContainer`, `.glassEffect(.regular.interactive())`, and `.safeAreaBar(edge: .bottom)`. Liquid Glass is strictly confined to floating chrome (composer, suggestion chips, popups, and scroll-to-bottom button) and never applied inside scrolling timeline cells.
- 🎯 **Top-Floating Turn Physics & Non-Pushing AI Responses**: Groups consecutive messages into `ConversationTurn` pairs (`ConversationTurn.group(_:)`), allocates a locked `activeTurnMinHeight` unoccluded viewport runway for the active turn, and performs a single-shot `proxy.scrollTo(turnID, anchor: .top)` on send. Streaming tokens expand downward into the pre-allocated runway with $\Delta Y = 0\text{pt}$ and zero per-token `scrollTo` jitter.
- ⚡️ **120Hz Incremental Streaming Markdown**: `StreamingMarkdownView` (`MarkdownBlock.parse(_:isStreaming:)`) memoizes completed paragraph, heading, blockquote, list, and fenced code blocks in $O(1)$ per token while re-parsing only the active tail block, paired with a 60Hz adaptive token cadence smoother (`.streamingCadenceEnabled(_:)`).
- 🧩 **Stratos 4-Layer Progressive Disclosure**:
  - **Layer 1 (Troposphere — Drop-in)**: `ConversationView(messages: $messages)` with strongly-typed `.onSendMessage { submission in ... }` or `.onSendMessage { message in ... }` (zero `as? DefaultMessage` downcasting).
  - **Layer 2 (Stratosphere — Modifiers & Built-in Styles)**: Swap composer, thinking, and bubble styles or enable structured prompting via declarative modifiers.
  - **Layer 3 (Mesosphere — Composable Views & Agentic Primitives)**: Embed standalone agentic views (`ThinkingStateView`, `ToolCallsGroupView`, `SourceStackView`, `AgentPlanView`, `AgentApprovalView`, `StreamingMarkdownView`) directly in custom layouts.
  - **Layer 4 (Thermosphere — Custom Protocols & Styles)**: Conform your own domain models to `Message` and implement custom `MessageComposerStyle`, `ThinkingStateStyle`, and `UserMessageBubbleStyle` protocols.
- 📎 **Universal Multimodal Attachments**: `ConversationAttachment` supports `ConversationAttachment.Payload` cases `.image(PlatformImageBox)`, `.file(URL)`, and `.data(Data, contentType: UTType, filename: String)` with off-main-actor thumbnail decoding (`PlatformThumbnailGenerator`) and explicit upload lifecycle states (`ConversationAttachment.UploadState`: `.ready`, `.uploading(progress: Double)`, `.failed(error: String)`).
- ⌨️ **Structured Prompting & Tokenization**: Built-in `/command` and `@mention` autocomplete popups (`ComposerTextBuffer`), suggestion chips (`PromptSuggestion` + `.suggestionChips(_:handoff:)`), model selector (`ComposerModelOption` + `.composerModels(_:selection:)`), and capability toggles (`ComposerCapability` + `.composerCapabilities(_:active:)`).
- 🧠 **First-Class Agentic Primitives**: Native timeline support for chain-of-thought reasoning (`ThinkingTrace`, collapsed by default), parallel tool execution (`ToolCall`), grounded citations (`Citation` with `http`/`https` URL sanitization via `citation.sanitizedURL` and `url.isAllowedConversationURL`), multi-step execution checklists (`AgentPlan`), and human-in-the-loop tool approvals (`ApprovalRequest`).
- 🛑 **Cooperative Cancellation**: Automatic Send-to-Stop button morphing with cooperative `Task` cancellation when `onSendMessage` is in flight.

## 📋 Requirements

- **iOS 26.0+** / **macCatalyst 26.0+** / **macOS 26.0+**
- **Swift 6.2+**
- **Xcode 26.0+**

## 📦 Installation

Add `ConversationKit` to your `Package.swift` dependencies using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/peterfriese/ConversationKit.git", from: "2.0.0")
]
```

Or track the `v2` branch directly:

```swift
dependencies: [
    .package(url: "https://github.com/peterfriese/ConversationKit.git", branch: "v2")
]
```

Then add `"ConversationKit"` to your target's dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["ConversationKit"]
)
```

---

## 🚀 Stratos 4-Layer Progressive Disclosure

### Layer 1: Troposphere (Drop-In Experience)

Start with 5 lines of code using `DefaultMessage` and strongly-typed `.onSendMessage`—no `as? DefaultMessage` downcasting required:

```swift
import SwiftUI
import ConversationKit

struct ChatView: View {
    @State private var messages: [DefaultMessage] = [
        DefaultMessage(content: "Hello! How can I help you today?", participant: .other)
    ]

    var body: some View {
        NavigationStack {
            ConversationView(messages: $messages)
                .onSendMessage { submission in
                    // 1. Append the strongly-typed user message (preserving submission.message.id)
                    messages.append(submission.message)

                    // 2. Append an assistant placeholder (renders the thinking/loading indicator)
                    var response = DefaultMessage(content: nil, participant: .other)
                    messages.append(response)
                    let index = messages.count - 1

                    // 3. Stream tokens with cooperative cancellation support
                    for word in ["Here ", "is ", "a ", "streamed ", "response!"] {
                        try? await Task.sleep(for: .milliseconds(80))
                        guard !Task.isCancelled else { return }
                        response.content = (response.content ?? "") + word
                        messages[index] = response
                    }
                }
                .navigationTitle("Assistant")
        }
    }
}
```

You can also use the convenience overload that receives `MessageType` directly:

```swift
ConversationView(messages: $messages)
    .onSendMessage { userMessage in
        messages.append(userMessage)
    }
```

---

### Layer 2: Stratosphere (View Modifiers & Built-In Styles)

Customize visual presentation, structured prompting, attachments, and timeline callbacks using idiomatic SwiftUI modifiers.

#### Built-in Style Protocols

- **`MessageComposerStyle`**:
  - `.classicGlass` *(default)*: 3-zone bookend sibling layout (`[+]` button + central glass field + trailing send/stop button inside a unified `GlassEffectContainer`).
  - `.cardGlass`: 2-row AI assistant card with the text editor on top and an integrated accessory/action toolbar on the bottom row.
  - `.compactGlass`: Single-row ultra-compact capsule composer.
- **`ThinkingStateStyle`**:
  - `.collapsibleHeader` *(default)*: Expandable disclosure card showing status, duration badge, and monospace reasoning transcript.
  - `.pill`: Compact capsule indicator.
  - `.minimal`: Lightweight inline status row.
- **`WorkingStateStyle`**:
  - `.inline` / `.inline(title:)` *(default)*: Pre-first-token breathing `sparkles` indicator and `"Working…"` subheadline label.
  - `.pill` / `.pill(title:)`: Compact accent-tinted capsule indicator.
  - `.minimal` / `.minimal(title:)`: Ultra-lightweight inline caption row.
  - Customize the default working title globally via `.workingStateTitle(_:)`.
- **`UserMessageBubbleStyle`**:
  - `.tailedBubble` *(default)*: iMessage/Gemini-inspired bubble with an asymmetric bottom-trailing corner.
  - `.roundedCard`: Uniform rounded card with subtle border.
  - `.capsule`: Pill-shaped user prompt bubble.

```swift
ConversationView(messages: $messages, attachments: $attachments)
    .messageComposerStyle(.cardGlass)
    .thinkingStateStyle(.collapsibleHeader)
    .workingStateStyle(.inline)
    .workingStateTitle("Working…")
    .userMessageBubbleStyle(.tailedBubble)
    .streamingCadenceEnabled(true)
```

#### Structured Prompting (`/Commands`, `@Mentions`, Models, Capabilities & Chips)

```swift
@State private var selectedModel: ComposerModelOption? = ComposerModelOption(
    id: "gemini-2.5-pro",
    name: "Gemini 2.5 Pro",
    subtitle: "Deep reasoning & coding",
    badge: "Pro",
    symbolName: "sparkles"
)
@State private var activeCapabilities: Set<ComposerCapability> = [.think, .search]
@State private var tokens: [ComposerToken] = []

ConversationView(messages: $messages, attachments: $attachments)
    .suggestionChips(
        [
            PromptSuggestion(
                title: "Summarize PR",
                prompt: "Summarize the latest pull request",
                symbolName: "doc.text.magnifyingglass",
                behavior: .populateComposer
            ),
            PromptSuggestion(
                title: "Audit Concurrency",
                prompt: "Audit strict Swift 6.2 Sendable conformance",
                symbolName: "checkmark.shield",
                behavior: .immediateSend
            )
        ],
        handoff: .populateComposer // PromptHandoffBehavior: .populateComposer or .immediateSend
    )
    .slashCommands([
        SlashCommand(
            trigger: "summarize",
            title: "Summarize",
            description: "Condense into key takeaways",
            symbolName: "text.redaction"
        ),
        SlashCommand(
            trigger: "plan",
            title: "Create Plan",
            description: "Draft a step-by-step execution plan",
            symbolName: "checklist"
        )
    ])
    .resourceMentions([
        ResourceMention(
            queryHandle: "ConversationView.swift",
            title: "ConversationView.swift",
            subtitle: "Sources/ConversationKit/Views/Timeline",
            symbolName: "swift",
            kind: .file
        )
    ])
    .composerModels(
        [
            ComposerModelOption(
                id: "gemini-2.5-pro",
                name: "Gemini 2.5 Pro",
                subtitle: "Deep reasoning & coding",
                badge: "Pro",
                symbolName: "sparkles"
            ),
            ComposerModelOption(
                id: "gemini-2.5-flash",
                name: "Gemini 2.5 Flash",
                subtitle: "Fast multimodal responses",
                badge: "Fast",
                symbolName: "bolt.fill"
            )
        ],
        selection: $selectedModel
    )
    .composerCapabilities(
        [.think, .search, .image],
        active: $activeCapabilities
    )
    .composerTokens($tokens)
```

#### Multimodal Attachments & Upload Lifecycle

Bind `[ConversationAttachment]` and register custom attachment actions or upload handlers:

```swift
ConversationView(messages: $messages, attachments: $attachments)
    .attachmentActions {
        Button("Photos", systemImage: "photo.on.rectangle.angled") {
            showingPhotoPicker = true
        }
        Button("Files", systemImage: "folder") {
            showingFileImporter = true
        }
    }
    .onAttachmentUpload { attachment, updateProgress in
        // Report upload progress and return the updated ConversationAttachment
        updateProgress(0.5)
        try await Task.sleep(for: .milliseconds(250))
        updateProgress(1.0)
        var updated = attachment
        updated.uploadState = .ready
        return updated
    }
    .onAttachmentRetry { failedAttachment in
        // Retry failed upload
    }
    // Or hide the attachment button completely:
    // .disableAttachments()
```

#### Timeline Callbacks & Chrome Customization

```swift
ConversationView(messages: $messages)
    .onRegenerateMessage { messageID in
        await regenerate(messageID: messageID)
    }
    .onMessageFeedback { messageID, feedback in
        // feedback is MessageFeedback? (.thumbsUp, .thumbsDown, or nil when cleared)
        recordFeedback(for: messageID, feedback: feedback)
    }
    .onRetryMessage { messageID in
        await retryMessage(messageID: messageID)
    }
    .onToolCallRetry { failedToolCall in
        await retryToolCall(failedToolCall)
    }
    .onApprovalDecision { request, decision in
        // decision is ApprovalRequest.Decision (.allowOnce, .alwaysAllow, .deny, etc.)
        await handleApproval(request: request, decision: decision)
    }
    .messageActions { message in
        Button("Share", systemImage: "square.and.arrow.up") {
            share(message)
        }
    }
    .emptyConversationView {
        ContentUnavailableView("Ask Anything", systemImage: "sparkles")
    }
    .conversationDisclaimer {
        Text("AI responses may be inaccurate. Verify important details.")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
```

---

### Layer 3: Mesosphere (Composable Views & Agentic Primitives)

Every agentic timeline component in `ConversationKit` is a standalone public `View` backed by `Sendable`, `Hashable`, `Codable` value types:

- **`WorkingStateView`**: Pre-first-token assistant breathing indicator styled via `WorkingStateStyle` (`.inline`, `.pill`, `.minimal`) and `.workingStateTitle(_:)`.
- **`ThinkingTrace` & `ThinkingStateView`**: Chain-of-thought reasoning indicator. Collapsed by default (`ThinkingTrace.defaultExpanded == false`) to preserve vertical reading space.
- **`ToolCall` & `ToolCallsGroupView`**: Displays function/tool invocations (`ToolCall.Status`: `.pending`, `.running(startedAt:)`, `.succeeded(duration:)`, `.failed(error:duration:)`, `.cancelled(duration:)`), arguments JSON, result JSON, and retry buttons.
- **`Citation` & `SourceStackView`**: Grounded source cards with automatic `http`/`https` URL allowlist validation (`citation.sanitizedURL` and `url.isAllowedConversationURL`—rejecting `javascript:`, `data:`, and `file:` schemes).
- **`AgentPlan` & `AgentPlanView`**: Multi-step execution checklist (`AgentPlan.Step`) with live completion progress.
- **`ApprovalRequest` & `AgentApprovalView`**: Human-in-the-loop confirmation card (`ApprovalRequest.Decision`: `.pending`, `.allowOnce`, `.alwaysAllow`, `.deny`, `.cancelled`) with risk badges (`.low`, `.medium`, `.high`).
- **`MessageActionBarView`**, **`StreamingMarkdownView`**, and **`ScrollToBottomButton`**.

```swift
let assistantMessage = DefaultMessage(
    content: "I audited the package and verified strict concurrency compliance.",
    participant: .other,
    thinkingTrace: ThinkingTrace(
        status: .completed(duration: 1.8),
        summary: "Analyzed 24 Swift files for Sendable and MainActor isolation.",
        transcript: "1. Inspected Model types\n2. Verified MainActor view isolation"
    ),
    toolCalls: [
        ToolCall(
            name: "swift_build_check",
            symbolName: "hammer.fill",
            status: .succeeded(duration: 0.9),
            argumentsSummary: "strictConcurrency: complete",
            resultSummary: "Build complete! (0 warnings, 0 errors)",
            argumentsJSON: #"{"strictConcurrency": "complete"}"#,
            resultJSON: #"{"warnings": 0, "errors": 0}"#
        )
    ],
    citations: [
        Citation(
            index: 1,
            title: "Swift Concurrency Documentation",
            domain: "docs.swift.org",
            snippet: "Sendable types can be safely shared across arbitrary concurrent contexts.",
            url: URL(string: "https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/")
        )
    ],
    plan: AgentPlan(
        title: "Verification Plan",
        steps: [
            AgentPlan.Step(title: "Audit public types for Sendable", status: .completed),
            AgentPlan.Step(title: "Run unit test suite", status: .completed)
        ]
    ),
    approvalRequest: ApprovalRequest(
        id: "deploy-preview-1",
        title: "Publish Documentation Preview",
        detail: "Uploads generated DocC archive to staging.",
        riskLevel: .medium,
        scopeIdentifier: "docs.example.com",
        changePreview: "Upload ConversationKit.doccarchive (4.2 MB)",
        decision: .pending
    )
)
```

---

### Layer 4: Thermosphere (Custom Protocols & Styles)

#### Custom `Message` Model

To use your own domain model with `ConversationView`, conform to `Message` and implement `makeUserMessage(id:content:attachments:tokens:selectedModelID:)`. Preserving the `id` passed into `makeUserMessage` guarantees seamless optimistic UI deduplication:

```swift
import ConversationKit
import Foundation

struct CustomChatMessage: Message {
    var id: String
    var content: String?
    var participant: Participant
    var createdAt: Date = .now
    var attachments: [ConversationAttachment] = []
    var tokens: [ComposerToken] = []
    var selectedModelID: String?
    var messageError: MessageError?

    // Custom domain metadata
    var totalTokensUsed: Int?

    static func makeUserMessage(
        id: String,
        content: String?,
        attachments: [ConversationAttachment],
        tokens: [ComposerToken],
        selectedModelID: String?
    ) -> CustomChatMessage {
        CustomChatMessage(
            id: id,
            content: content,
            participant: .user,
            attachments: attachments,
            tokens: tokens,
            selectedModelID: selectedModelID
        )
    }
}
```

#### Custom Style Conformances

Implement `MessageComposerStyle`, `ThinkingStateStyle`, or `UserMessageBubbleStyle` to build bespoke visual treatments while reusing `ConversationKit`'s state and layout engine:

```swift
struct CustomBannerThinkingStyle: ThinkingStateStyle {
    func makeBody(configuration: ThinkingStateStyleConfiguration) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: configuration.toggleExpanded) {
                HStack {
                    configuration.headerIcon
                    Text(configuration.title)
                        .font(.caption.weight(.medium))
                    Spacer()
                    if !configuration.formattedElapsed.isEmpty {
                        Text(configuration.formattedElapsed)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            if configuration.isExpanded {
                configuration.transcriptContent
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }
}
```

---

## 📐 Top-Floating Turn Physics & Optimistic UI

`ConversationKit` v2 replaces fragile per-token scroll observers with a deterministic **Top-Floating Turn Engine**:

1. **Turn Grouping (`ConversationTurn.group(_:)`)**: Consecutive timeline messages are paired into cohesive turns (`userMessage` + `assistantMessages`, or standalone system/greeting turns).
2. **Locked Active Runway (`activeTurnMinHeight`)**: The active latest turn is given a minimum height equal to the unoccluded scroll viewport height (`max(0, viewportHeight - safeAreaTop - safeAreaBottom)`).
3. **Single-Shot Top Anchor**: When the user submits a prompt, `ConversationView` records an optimistic user message synchronously in the same render transaction as keyboard dismissal and scrolls the new `ConversationTurn.id` to `anchor: .top`.
4. **Zero-Jitter Streaming ($\Delta Y = 0\text{pt}$)**: As the AI streams tokens, expands reasoning traces, or updates tool calls, content grows downward into the pre-allocated `activeTurnMinHeight` runway without calling `scrollTo` on every token.

> **Important ID Contract:** When appending the user's message inside `.onSendMessage`, always append `submission.message` directly (or preserve `submission.message.id` when mapping). `ConversationView` deduplicates its optimistic user message placeholder against your `messages` array by `id`.

---

## 🤖 AI Integration Examples

The following examples match the complete reference implementations in [`Examples/AIChatDemo/`](Examples/AIChatDemo).

### Firebase AI Logic (`FirebaseAI`)

```swift
import ConversationKit
import FirebaseAI
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
final class FirebaseAILogicChatViewModel {
    var messages: [DefaultMessage] = []
    var attachments: [ConversationAttachment] = []
    var selectedItems: [PhotosPickerItem] = []

    private let model: GenerativeModel
    private let chat: Chat

    init() {
        let firstMessage = DefaultMessage(
            content: "Hello! How can I help you today?",
            participant: .other
        )
        self.messages = [firstMessage]

        model = FirebaseAI
            .firebaseAI(backend: .googleAI())
            .generativeModel(modelName: "gemini-2.5-flash")

        let history = [
            ModelContent(role: "model", parts: firstMessage.content ?? "")
        ]
        chat = model.startChat(history: history)
    }

    func sendMessage(_ submission: ConversationSubmission<DefaultMessage>) async {
        messages.append(submission.message)

        let responseText: String
        do {
            let imageParts: [InlineDataPart] = submission.attachments.compactMap { attachment in
                switch attachment.payload {
                case .image(let imageBox):
                    #if canImport(UIKit)
                    if let jpegData = imageBox.image.jpegData(compressionQuality: 0.85) {
                        return InlineDataPart(data: jpegData, mimeType: "image/jpeg")
                    }
                    #endif
                    if let pngData = imageBox.pngData() {
                        return InlineDataPart(data: pngData, mimeType: "image/png")
                    }
                    return nil

                case .data(let data, let contentType, _):
                    let mimeType = contentType.preferredMIMEType ?? "application/octet-stream"
                    return InlineDataPart(data: data, mimeType: mimeType)

                case .file(let url):
                    guard let data = try? Data(contentsOf: url) else { return nil }
                    let mimeType = attachment.contentType.preferredMIMEType ?? "application/octet-stream"
                    return InlineDataPart(data: data, mimeType: mimeType)
                }
            }

            let parts: [PartsRepresentable] = imageParts + [submission.text]
            let response = try await chat.sendMessage(parts)
            responseText = response.text ?? ""
        } catch {
            responseText = "I'm sorry, I don't understand that. Please try again. \(error.localizedDescription)"
        }

        let response = DefaultMessage(content: responseText, participant: .other)
        messages.append(response)
    }
}

struct FirebaseAILogicChatView: View {
    @State private var viewModel = FirebaseAILogicChatViewModel()
    @State private var showingPhotoPicker = false

    var body: some View {
        NavigationStack {
            ConversationView(messages: $viewModel.messages, attachments: $viewModel.attachments)
                .onSendMessage { submission in
                    await viewModel.sendMessage(submission)
                }
                .attachmentActions {
                    Button("Photos", systemImage: "photo.on.rectangle.angled") {
                        showingPhotoPicker = true
                    }
                }
                .navigationTitle("Firebase AI Chat")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .photosPicker(
                    isPresented: $showingPhotoPicker,
                    selection: $viewModel.selectedItems,
                    maxSelectionCount: 5,
                    matching: .images
                )
                .onChange(of: viewModel.selectedItems) {
                    Task { @MainActor in
                        for (index, item) in viewModel.selectedItems.enumerated() {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let imageBox = PlatformImageBox(data: data)
                            {
                                viewModel.attachments.append(
                                    ConversationAttachment(
                                        imageBox: imageBox,
                                        filename: "Photo-\(index + 1).jpg"
                                    )
                                )
                            }
                        }
                        viewModel.selectedItems.removeAll()
                    }
                }
        }
    }
}
```

### Apple Foundation Models (`FoundationModels`)

```swift
import ConversationKit
import FoundationModels
import SwiftUI

@available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *)
struct FoundationModelChatView: View {
    @State private var messages: [DefaultMessage] = [
        DefaultMessage(content: "Hello! How can I help you today?", participant: .other)
    ]

    private let session = LanguageModelSession()

    var body: some View {
        NavigationStack {
            ConversationView(messages: $messages)
                .onSendMessage { submission in
                    messages.append(submission.message)

                    let responseMessage: DefaultMessage
                    do {
                        let response = try await session.respond(to: submission.text)
                        responseMessage = DefaultMessage(
                            content: response.content,
                            participant: .other
                        )
                    } catch {
                        responseMessage = DefaultMessage(
                            content: "An error has occurred. Try again later.",
                            participant: .other,
                            error: error
                        )
                    }
                    messages.append(responseMessage)
                }
                .navigationTitle("On-Device Chat")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
        }
    }
}
```

---

## ⚠️ Error Handling

`ConversationKit` v2 models message-level errors with the `Sendable`, `Hashable`, `Codable` `MessageError` value type:

```swift
public struct MessageError: Identifiable, Hashable, Sendable, Codable {
    public let id: String
    public var message: String
    public var detail: String?
    public var isRetryable: Bool
}
```

You can attach a structured `MessageError` or any Swift `Error` directly to `DefaultMessage`:

```swift
// Using a structured MessageError:
let errorMessage = DefaultMessage(
    content: "Generation interrupted while contacting the model endpoint.",
    participant: .other,
    messageError: MessageError(
        message: "Rate limit exceeded (HTTP 429)",
        detail: "Quota exhausted for gemini-2.5-pro. Retry in 15 seconds.",
        isRetryable: true
    )
)

// Or convenience initializer wrapping any Swift Error:
let fallbackMessage = DefaultMessage(
    content: "An error has occurred. Try again later.",
    participant: .other,
    error: error
)
```

When a message has a non-nil `messageError`, `MessageView` renders an inline error banner with the error summary, optional diagnostic details, and an interactive **Retry** button (when `isRetryable == true`). Handle retry taps with `.onRetryMessage`:

```swift
ConversationView(messages: $messages)
    .onRetryMessage { failedMessageID in
        await retryGeneration(for: failedMessageID)
    }
```

---

## 📄 License

ConversationKit is licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for details.
