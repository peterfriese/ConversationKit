# PRD-0001: ConversationKit v2 — Native Liquid Glass & Agentic Chat Framework

- **Document ID**: `PRD-0001-CONVERSATIONKIT-V2`
- **Status**: Approved for Architecture & Implementation
- **Owner**: Product Manager (`@product-manager`)
- **Architect**: Senior Architect (`@senior-architect`) & Swift SDK Architect (`@swift-sdk-architect`)
- **Target Release**: `v2.0.0` (Branch: `v2`)
- **Target Platforms**: iOS 26.0+, iPadOS 26.0+, macCatalyst 26.0+, macOS 26.0+
- **Language & Concurrency Baseline**: Swift 6.2 (`swift-tools-version: 6.2`), Strict Concurrency, Zero External Package Dependencies

---

## 1. Context & Problem

### 1.1 Background & Current State
`ConversationKit` v1 provided a foundational SwiftUI chat interface for iOS and macOS with basic message bubbles, image attachments, and an optimistic scroll anchor strategy. However, modern conversational AI and agentic applications in the 2026 Apple ecosystem require capabilities that go significantly beyond traditional human-to-human messaging UI:
1. **Scroll Physics Mismatch:** Traditional chat UIs either pin to the bottom (causing violent per-token vertical jitter during streaming) or push the user's prompt off the top of the screen when an AI response exceeds viewport height, forcing the user to scroll back up while reading.
2. **Rigid Bubble Chrome for Long-Form AI Output:** Wrapping multi-paragraph Markdown, tables, code blocks, and agentic tool traces inside a constricted chat bubble wastes horizontal screen estate and degrades readability compared to rendering AI responses directly on the background canvas.
3. **Image-Only Attachment Constraints:** Developers building document-aware and multimodal assistants need universal attachment support (PDFs, audio, code/text files, arbitrary `UTType` documents, URLs, raw `Data`), upload progress states, memory-safe thumbnail downsampling, and native QuickLook inspection.
4. **Lack of Structured Prompting & Agentic Primitives:** Modern AI workflows rely on first-turn suggestion chips, `/` slash commands, `@` resource mentions with removable token pills, inline model/capability selection, collapsible reasoning traces (`ThinkingStateView`), tool execution timelines, source citations, and human-in-the-loop approval cards.
5. **Pre-iOS 26 Visual Language & Rigid Composer Layout:** `ConversationKit` v1 predates iOS 26 / macOS 26 native Liquid Glass APIs (`GlassEffectContainer`, `.glassEffect`, `.safeAreaBar`) and couples composer state management to a single fixed layout rather than exposing native SwiftUI `Style` protocols (`MessageComposerStyle`, `ThinkingStateStyle`, `UserMessageBubbleStyle`).

### 1.2 Target Personas
- **Troposphere App Developer:** Wants a drop-in, zero-boilerplate `ConversationView(messages: $messages)` that immediately delivers Apple-grade Liquid Glass polish, top-floating turn scroll physics, and smooth streaming Markdown out of the box.
- **Stratosphere / Mesosphere Product Engineer:** Configures model selectors, `/` commands, `@` mentions, universal attachments, suggestion chips, and agentic timeline subviews via declarative view modifiers without rebuilding the composer or scroll engine.
- **Thermosphere Design Systems Engineer:** Implements custom `MessageComposerStyle`, `ThinkingStateStyle`, and `UserMessageBubbleStyle` conformances or custom `Message` / `ConversationAttachment` domain models while retaining full keyboard, focus, accessibility, and scroll orchestration.

---

## 2. Goals & Non-Goals

### 2.1 Goals
- **G-1 (Clean-Slate iOS 26+ / macOS 26+ Baseline):** Rebuild `ConversationKit` v2 from a clean slate targeting iOS 26+, iPadOS 26+, macCatalyst 26+, and macOS 26+ with Swift 6.2 strict concurrency (`Sendable`, `@MainActor` isolation) and zero external SwiftPM dependencies.
- **G-2 (Deterministic Top-Floating Turn Scroll Physics):** Guarantee that newly sent user messages float smoothly to the top of the viewport (`anchor: .top`) in a single animation without down-up bounce (`F-1`), and that streaming AI responses grow downward below the user message without ever pushing the user message off the top edge (`F-2`, $\Delta Y = 0\text{pt}$).
- **G-3 (Asymmetric Participant Presentation):** Render user messages in right-aligned stylable bubbles (`UserMessageBubbleStyle`) with attached media grids/file chips, while rendering AI/system responses full-width directly on the background canvas (`F-3`).
- **G-4 (Universal Multimodal Attachments):** Support images, PDFs, audio, source code, text, and arbitrary `UTType` files in both composer and timeline with background `ImageIO` / `QLThumbnailGenerator` downsampling, determinate upload progress rings (`0.0...1.0`), per-item retry, `.quickLookPreview`, and `+N` multi-photo collage grids (`F-4`).
- **G-5 (Structured Composer Ergonomics):** Deliver `/` slash command and `@` resource mention autocomplete in a floating Liquid Glass popup with substring highlighting, static and async providers, removable token pills, double-backspace deletion, and duplicate guards (`F-5`), alongside an integrated Model Selector & capability toggles (`F-9`), first-turn suggestion chips (`F-8`), and a focus-driven keyboard dismiss button (`F-11`).
- **G-6 (Authentic iOS 26+ Liquid Glass Architecture):** Use native `GlassEffectContainer`, `.glassEffect(.regular.interactive(), in: ...)`, `.buttonStyle(.glass)` / `.buttonStyle(.glassProminent)`, `.buttonBorderShape(...)`, and `.safeAreaBar(edge: .bottom)` exclusively on floating/pinned chrome—never inside scrolling timeline cells (`F-6`).
- **G-7 (First-Class Agentic & Streaming Primitives):** Provide collapsed-by-default expandable `ThinkingStateView` (`F-7`), incremental block `StreamingMarkdownView` with cadence smoothing and copyable code blocks, `ToolCallsGroupView`, `SourceStackView`, `AgentPlanView`, `AgentApprovalView`, and `MessageActionBarView`.
- **G-8 (Stratos 4-Layer Progressive Disclosure & Style Protocols):** Expose native SwiftUI `Style` protocols (`MessageComposerStyle` with `.classicGlass`, `.cardGlass`, `.compactGlass`; `ThinkingStateStyle`; `UserMessageBubbleStyle`) and strongly-typed `.onSendMessage` overloads requiring zero downcasting.
- **G-9 (Automated FlowDeck Verification Gate):** Validate build, unit tests, visual states, and zero-jitter scroll physics coordinates on Simulator exclusively via **FlowDeck (`flowdeck`)**.

### 2.2 Non-Goals (Out of Scope for v2.0)
- **NG-1 (Backend / LLM Network Transport):** `ConversationKit` is a pure UI and interaction SDK; it does not bundle networking clients, API key management, or direct LLM provider SDKs inside the core library target (provider integrations belong solely in `Examples/AIChatDemo`).
- **NG-2 (Persistent Database / Cloud Sync):** The caller owns the `messages` and `attachments` collections; CoreData, SwiftData, or CloudKit persistence layers are out of scope.
- **NG-3 (Legacy OS Backward Compatibility):** Pre-iOS 26 / pre-macOS 26 fallback blur shims (`UIBlurEffect` / `.ultraThinMaterial` workarounds for Liquid Glass) are explicitly excluded to keep the codebase 100% native to the 2026 Apple SDKs.
- **NG-4 (Full Audio Waveform Recording Studio):** While `dictationButton` hooks and audio file attachments are supported, real-time multi-track audio recording/editing DSP pipelines are out of scope.

---

## 3. User Stories & Workflows

### 3.1 User Stories
- **US-1 (First-Turn Onboarding & Suggestion Chips):** As an end user opening a new AI conversation, I want to see contextual suggestion chips floating directly above the input box so I can start a conversation with one tap (either sending immediately or populating the composer), and have those chips cleanly disappear once my first message is sent.
- **US-2 (Top-Floating Prompt & Non-Pushing Streaming Response):** As an end user submitting a prompt, I want my sent message to glide smoothly to the top of the screen and stay anchored there while the AI streams a short or multi-page answer downward beneath it, so my prompt is never pushed off-screen and I can start reading immediately from line 1 without chasing moving text.
- **US-3 (Scroll Recovery via Scroll-to-Bottom Button):** As an end user reading an overflowing AI response or inspecting earlier turns in the conversation, I want a floating Liquid Glass scroll-to-bottom button to appear whenever I am more than 80pt from the bottom and hide when I am within 24pt of the bottom.
- **US-4 (Universal File & Photo Attachments):** As an end user attaching high-resolution photos, PDFs, or source files via PhotosPicker, File Importer, pasteboard, or drag-and-drop, I want to see instant downsampled thumbnails, live upload progress rings, per-item retry on upload failure, and QuickLook previews on tap.
- **US-5 (Slash Commands & Resource Mentions):** As a power user typing `/` or `@` at a word boundary, I want a floating Liquid Glass popup with highlighted substring matches (supporting async search for `@mentions`) that inserts structured token pills removable via tap or double-backspace.
- **US-6 (Model & Capability Switching):** As an end user, I want to switch the active AI model (seeing its icon, name, and capability badge) and toggle reasoning/search/image capabilities directly inside the composer.
- **US-7 (Keyboard Focus Dismissal):** As an iOS user typing in the composer, I want a dedicated circular Liquid Glass keyboard-dismiss button (`keyboard.chevron.compact.down`) to morph in on the trailing side of the composer whenever the text field is focused, allowing one-tap keyboard dismissal.
- **US-8 (Inspecting AI Reasoning & Agentic Actions):** As an end user interacting with a reasoning or tool-using agent, I want `ThinkingStateView` to stay compactly collapsed by default with a live monospaced timer (`Thinking · 3.2s` → `Thought for 4s ›`) and expand on tap to reveal the full reasoning trace, alongside collapsible tool call groups, source citation stacks, plans, and approval prompts.
- **US-9 (SDK Consumer Customization):** As an app developer integrating `ConversationKit`, I want strongly-typed `.onSendMessage` callbacks (`MessageType` or `ConversationSubmission<MessageType>`) with zero `as?` downcasting, and the ability to switch between `.classicGlass`, `.cardGlass`, `.compactGlass`, or a custom `MessageComposerStyle` via a single SwiftUI modifier.

### 3.2 Core User Workflows

#### Workflow 1: First-Turn Suggestion Chip → Send → Top-Floating Turn & Streaming
1. **Trigger:** User opens an empty conversation thread (`messages.isEmpty`) configured with `.suggestionChips(...)`.
2. **Step 1 (Suggestion Rail):** `SuggestionChipsBar` renders horizontally snapping Liquid Glass capsules directly above `MessageComposerView` inside the bottom `.safeAreaBar`.
3. **Step 2 (Submission):** User taps a chip (in `.immediateSend` mode) or types a prompt and taps Send.
4. **Step 3 (Same-Transaction Optimistic Anchor & Chip Exit):**
   - Focus is cleared (`@FocusState = false`), morphing out the trailing `keyboard.chevron.compact.down` button.
   - `SuggestionChipsBar` animates out and remains hidden for the rest of the conversation (`hasSentFirstMessage == true`).
   - A new conversational turn container (`User Message + Active Viewport Runway`) is registered and scrolled to `anchor: .top` in a single smooth animation without down-up bounce.
5. **Step 4 (Thinking & Non-Pushing Streaming):**
   - Below the right-aligned user bubble, the assistant turn renders directly on the background canvas.
   - `ThinkingStateView` displays collapsed with a phase-locked breathing mark, alpha sheen, and tabular timer (`Thinking · 1.4s`).
   - As response tokens arrive, `ThinkingStateView` transitions to `Thought for 2s ›`, and `StreamingMarkdownView` reveals blocks downward.
   - When the response exceeds the visible viewport height, it flows off the bottom edge while the user message remains pinned at the top ($\Delta Y = 0\text{pt}$).
   - Once >80pt of content overflows below the viewport, `ScrollToBottomButton` appears above the composer.

#### Workflow 2: `/` Command & `@` Mention Token Composition with Universal Attachments
1. **Trigger:** User focuses the composer text field (`isFocused = true`); the circular `keyboard.chevron.compact.down` button morphs in at the trailing edge of `GlassEffectContainer`.
2. **Step 1 (Trigger Detection):** User types `/sum` or `@PRD` at the start of input or after whitespace.
3. **Step 2 (Autocomplete Popup):** `ComposerPopupView` floats above the composer in Liquid Glass, highlighting matched substrings and awaiting debounced async results for `@` queries.
4. **Step 3 (Token Insertion & Duplicate Guard):** Selecting an item removes the trigger text and inserts a `ComposerToken` pill into `tokensBar`. If the same `@mention` already exists, the existing chip pulses instead of duplicating.
5. **Step 4 (Double-Backspace Removal):** Pressing backspace when the text field is empty highlights the last `ComposerToken` on the first press and removes it on the second press.
6. **Step 5 (Attachment Upload & Gating):** User adds a PDF and 5 photos. `AttachmentTrayView` generates background downsampled thumbnails (`ImageIO` / `QLThumbnailGenerator`) and shows determinate progress rings (`0.0...1.0`). While any attachment is `.uploading`, the Send button is gated (`canSubmit == false`). If an item fails, a per-item retry badge allows retrying before submission.

---

## 4. Functional Requirements

### 4.1 Core User-Requested Features (`F-1` through `F-11`)

- **F-1 (Top-Floating User Messages):**
  - Sending a message MUST immediately float the submitted user message to the top of the visible scroll viewport (`anchor: .top`) in a single smooth animation without down-up bouncing or two-phase layout jumps.
  - Optimistic UI state (`optimisticUserMessage`) and turn runway reservation MUST execute synchronously in the same render transaction as keyboard dismissal, deduplicating seamlessly by `message.id` when the parent view appends the message to `messages`.

- **F-2 (Non-Pushing AI Responses):**
  - The AI/system response MUST render directly below the user's message inside the active turn container.
  - While the AI response is shorter than the remaining viewport height, it fills the turn container's bottom runway without mutating scroll offset.
  - When the AI response grows taller than the visible viewport, it MUST flow downward off the bottom edge of the screen and **MUST NOT** push the user's message upward off the top of the screen ($\Delta Y = 0\text{pt}$ on the user message's top edge during streaming overflow).

- **F-3 (Bubble User Messages vs. Background AI Responses):**
  - `.user` participant messages MUST render inside a right-aligned chat bubble styled via `UserMessageBubbleStyle` (defaulting to a tinted rounded bubble with adaptive corner geometry and above-bubble or inline attachment grids/file chips).
  - `.other` (AI / system) participant messages MUST render full-width directly on the background canvas without a surrounding bubble container.

- **F-4 (Universal Attachments):**
  - Both `MessageComposerView` and timeline `MessageView` MUST support `ConversationAttachment` items representing images, PDFs, audio, code/text, and arbitrary documents backed by `URL` or `Data` + `UTType`.
  - Thumbnails MUST be generated off the main thread via `ImageIO` (`CGImageSourceCreateThumbnailAtIndex`) and `QLThumbnailGenerator` bounded to display pixel size (`maxPixelSize`).
  - Pending attachments in `AttachmentTrayView` MUST support upload lifecycle states (`.ready`, `.uploading(progress: Double)`, `.failed(error: String)`), rendering a determinate progress ring (`0.0...1.0`), per-item remove (`xmark`), per-item retry on failure, and strict submission gating requiring all attachments to be `.ready` (`attachments.allSatisfy { $0.uploadState == .ready }`) so neither `.uploading` nor `.failed` attachments can be submitted (`[MF-5]`).
  - Sent messages MUST render 1–4 image attachments in a proportional collage grid with a `+N` overflow badge when >4 images are attached, and render non-image documents as structured file chips (type icon, filename, formatted byte size / `UTType` label).
  - Tapping any previewable attachment in the composer or timeline MUST open Apple's native `.quickLookPreview` using sanitized temporary file paths (`UUID` subdirectory + `URL(fileURLWithPath: filename).lastPathComponent`) managed by `PlatformThumbnailGenerator` (`[MF-4]`, `[MF-5]`).

- **F-5 (Slash Commands `/` & Resource Mentions `@`):**
  - Typing `/` or `@` at a word boundary (start of text or preceded by whitespace/newline) MUST present a floating Liquid Glass `ComposerPopupView` above the composer with matched-substring highlighting.
  - Both static `[CommandItem]` / `[MentionItem]` collections and async `@Sendable (String) async throws -> [MentionItem]` search providers MUST be supported with automatic task cancellation on query change.
  - Selecting a popup item MUST replace the trigger query with a structured `ComposerToken` chip in `tokensBar`.
  - Selecting an already-attached `@mention` MUST pulse the existing token chip rather than inserting a duplicate.
  - Pressing backspace in an empty text field MUST highlight the trailing `ComposerToken` on first press and remove it on second consecutive press.

- **F-6 (Native iOS 26+ Liquid Glass UI):**
  - All floating and pinned chrome MUST use native iOS 26+ / macOS 26+ Liquid Glass APIs: `GlassEffectContainer`, `.glassEffect(.regular.interactive(), in: ...)`, `.buttonStyle(.glass)`, `.buttonStyle(.glassProminent)`, `.buttonBorderShape(...)`, and `.safeAreaBar(edge: .bottom)`.
  - Liquid Glass modifiers MUST NEVER be applied inside scrolling `ScrollView` timeline cells (`MessageView`, `StreamingMarkdownView`, `ThinkingStateView`, `ToolCallsGroupView`, `SourceStackView`, etc.).

- **F-7 (Collapsible Thinking / Reasoning):**
  - `ThinkingStateView` MUST default to `isExpanded = false` (collapsed by default) and toggle expansion on user tap.
  - The header MUST display a phase-locked breathing mark, a subtle alpha sheen sweep while actively streaming, and a tabular monospaced rolling timer (`Thinking · 3.2s` while active; `Thought for 4s ›` when completed; `Thinking stopped · 2.1s` if cancelled).
  - Visual presentation MUST be customizable via `ThinkingStateStyle` and `ThinkingStateStyleConfiguration`.

- **F-8 (First-Turn Suggestion Chips Above Input Box):**
  - When the conversation thread is empty (`messages.isEmpty && !hasSentFirstMessage`), `SuggestionChipsBar` MUST render a horizontal view-aligned snapping rail of Liquid Glass suggestion chips directly on top of the composer inside the bottom `.safeAreaBar`.
  - Once the first user message is submitted, `SuggestionChipsBar` MUST animate out cleanly and remain hidden for the remainder of the conversation session (resetting only if the thread is cleared back to empty).
  - Each chip (`SuggestionChip`) MUST support `.immediateSend` (submits immediately on tap) and `.populateComposer` (inserts text into the composer and focuses the input field).

- **F-9 (Model Selector in Input Box):**
  - `MessageComposerView` MUST support an integrated model picker menu displaying the selected `ComposerModelOption` (icon, title, subtitle, and optional capability badge such as `"Fast"` or `"Reasoning"`).
  - Optional `ComposerCapability` toggle chips (`Think`, `Search`, `Image`, or custom capabilities) MUST be configurable alongside the model selector and included in `ConversationSubmission`.

- **F-10 (Floating Scroll-to-Bottom Button):**
  - `ConversationView` MUST track scroll geometry via `.onScrollGeometryChange` with hysteresis: showing `ScrollToBottomButton` when distance from the bottom edge exceeds `80pt`, and hiding it when distance from the bottom edge is less than `24pt`.
  - `ScrollToBottomButton` MUST render as a floating Liquid Glass capsule/circle above the composer and smoothly scroll to the bottom of the active conversation when tapped.

- **F-11 (Focus-Driven Keyboard Dismiss Button):**
  - Whenever the composer text field has focus (`@FocusState == true`), a circular Liquid Glass button (`keyboard.chevron.compact.down`) MUST appear at the trailing edge of the composer inside `GlassEffectContainer`, morphing smoothly via `@Namespace` and `.glassEffectID`.
  - Tapping the button MUST clear `@FocusState` to dismiss the software keyboard and smoothly morph the button out.

### 4.2 SwiftUI Styling Architecture (`MessageComposerStyle`, `ThinkingStateStyle`, `UserMessageBubbleStyle`)
- **`MessageComposerStyle` & `MessageComposerStyleConfiguration`:**
  - Exposes type-erased subviews (`textField`, `attachmentButton`, `attachmentsTray`, `tokensBar`, `modelSelector`, `capabilitiesBar`, `dictationButton`, `submitButton`, `dismissKeyboardButton`) and state flags (`isFocused`, `isGenerating`, `canSubmit`, `hasAttachments`, `hasTokens`).
  - Ships with 3 built-in styles (plus `.automatic` alias to `.classicGlass`):
    1. `.classicGlass` (Default / `.automatic`): Detached leading `44×44pt` circular Liquid Glass `+` button, central rounded-rect Liquid Glass pill (`cornerRadius: 22`) housing `attachmentsTray`, `tokensBar`, growing vertical `textField`, `modelSelector`, and trailing circular `.glassProminent` Send/Stop button, plus detached trailing `44×44pt` circular `dismissKeyboardButton` when focused.
    2. `.cardGlass`: Unified two-row modern AI assistant Liquid Glass card (top input/attachments/tokens area + bottom accessory toolbar bar with `+`, capability chips, model selector, Send/Stop, and keyboard dismiss button).
    3. `.compactGlass`: Single-row capsule layout for compact sheets and secondary inspectors.
- **`ThinkingStateStyle` & `ThinkingStateStyleConfiguration` (`[MF-1]`):**
  - Decouples reasoning trace state/timing from visual layout; ships with 3 built-in styles: `.collapsibleHeader` (Default, with `.default` and `.automatic` static aliases), `.pill` (compact tinted pill header), and `.minimal` (inline caption header).
- **`UserMessageBubbleStyle` & `UserMessageBubbleStyleConfiguration` (`[MF-1]`):**
  - Decouples user message bubble chrome from timeline layout without ever applying Liquid Glass inside scrolling cells (`AC-10`); ships with 3 built-in opaque/tinted semantic styles: `.tailedBubble` (Default, with `.standard` and `.automatic` static aliases), `.roundedCard` (continuous 20pt concentric card), and `.capsule` (pill/capsule bubble).

### 4.3 SwiftPieces-Inspired Polish & Agentic Timeline Features
- **Incremental Streaming Markdown (`StreamingMarkdownView`):**
  - Adaptive token cadence buffer that smooths bursty network chunks into a steady visual stream.
  - Incremental block parser that freezes completed blocks (paragraphs, headings, closed fenced code blocks, blockquotes, lists, tables) and only re-parses the active trailing block.
  - Per-word fade reveal using SwiftUI `TextRenderer` and a cap-height inline streaming cursor.
  - Two-tone fenced code blocks with language label header and one-tap **Copy** button with checkmark confirmation.
- **Agentic Timeline Components:**
  - `ToolCallsGroupView`: Collapsible tool execution group with morphing status icons (`.running`, `.succeeded`, `.failed`), live elapsed timers, auto-collapse summary (`"Used N tools · X.Xs"`), expandable JSON input/output inspector, and per-tool retry callback.
  - `SourceStackView`: Overlapping domain badge pill (`"N sources"`) that expands into numbered citation cards (`[1]`, `[2]`) with strict `http`/`https` URL scheme validation.
  - `AgentPlanView`: Multi-step execution checklist with step status indicators (`.pending`, `.inProgress`, `.completed`, `.skipped`, `.failed`).
  - `AgentApprovalView`: Human-in-the-loop permission card with `Allow Once`, `Always Allow`, and `Deny` actions that transition to an immutable resolved badge once decided.
- **Turnkey `MessageActionBarView` & Inline Error/Retry Banner:**
  - Action bar below completed AI messages providing `Copy`, `Regenerate`, `Thumbs Up`, `Thumbs Down`, and `ShareLink`.
  - Inline error card with one-tap `Retry` routed through a token-guarded turn coordinator to prevent duplicate concurrent retries.
- **Built-In Attachment Pickers & Strongly-Typed 2-Generic `ConversationView<MessageType, Content>` API (`[MF-2]`):**
  - `ConversationView<MessageType: Message, Content: View>` standardizes on 2 generic parameters (eliminating a third `AttachmentType` generic parameter since `ConversationAttachment` is the universal multimodal model). When initialized without an explicit `attachments:` binding (e.g., `ConversationView(messages: $messages)`), it automatically falls back to an internal `@State private var internalAttachments: [ConversationAttachment] = []` so built-in `PhotosPicker`, `.fileImporter`, pasteboard paste, and drag-and-drop work out of the box.
  - Built-in support for `PhotosPicker`, `.fileImporter`, pasteboard image/file paste, and drag-and-drop.
  - Strongly-typed `.onSendMessage` overloads accepting `(MessageType) async -> Void` or `(ConversationSubmission<MessageType>) async -> Void` with zero `any Message` downcasting required.

---

## 5. Technical Considerations

### 5.1 Chameleon Cross-Platform Architecture (`Sources/ConversationKit/Platform/`)
- All UIKit vs. AppKit platform divergences (`PlatformImage`, pasteboard access, `ImageIO` / `QLThumbnailGenerator` thumbnailing, semantic colors, and haptic feedback bridges) MUST be centralized inside `Sources/ConversationKit/Platform/PlatformTypes.swift`.
- No files under `Model/`, `Styles/`, or `Views/` may contain scattered `#if canImport(UIKit)` / `#if canImport(AppKit)` blocks where a `Platform/` abstraction belongs.

### 5.2 Swift 6.2 Strict Concurrency & Memory Budgets
- Every model (`DefaultMessage`, `ConversationAttachment`, `ThinkingTrace`, `ToolCall`, `Citation`, `AgentPlan`, `ApprovalRequest`, `ComposerModelOption`, `ComposerCapability`, `CommandItem`, `MentionItem`, `ComposerToken`, `ConversationSubmission`) MUST conform to `Sendable`, `Identifiable`, and `Hashable`/`Equatable`.
- `PlatformImageBox` MUST use a stable `id: UUID` for $O(1)$ `Equatable` and `Hashable` conformance and defer PNG encoding (`lazy` / on-demand `encode(to:)`) off the initializer path (`[MF-4]`).
- UI state coordination and view rendering MUST be explicitly isolated to `@MainActor`, while thumbnail downsampling (`ImageIO` / `QLThumbnailGenerator`), QuickLook temp file resolution, and async `@mention` queries execute concurrently with cooperative task cancellation (`Task.checkCancellation()`).
- High-resolution image and PDF attachments MUST NEVER decode full-size bitmaps on the main thread; thumbnail memory footprint is capped via downsampled pixel dimensions (`maxPixelSize: 320`).
- `activeTurnMinHeight` MUST be stabilized against the unoccluded viewport height so transient keyboard dismissal safe-area/contentInset frames never shrink the active turn runway or shift the top-floating user bubble (`[MF-3]`).

### 5.3 Accessibility, Sensory Feedback & Localization
- Full adaptation for `@Environment(\.accessibilityReduceMotion)` (replaces spring morphs, breathing scale, and sheen sweeps with cross-fades) and `@Environment(\.accessibilityReduceTransparency)` (provides opaque high-contrast surfaces where needed).
- VoiceOver accessibility labels, values, traits, and deterministic `ConversationAccessibilityID` identifiers (`composer.textField`, `composer.submitButton`, `composer.dismissKeyboardButton`, `timeline.scrollToBottomButton`, `message.user.<id>`, `message.assistant.<id>`, etc.) on all interactive controls (`[MF-2]`).
- Native `.sensoryFeedback` triggers on message send, suggestion chip tap, token insertion/removal, copy confirmation, and error occurrence.

### 5.4 Security & Input Validation (`[MF-5]`)
- Both `SourceStackView` (`Citation.sanitizedURL`) and `StreamingMarkdownView` (via a custom `OpenURLAction` and `URL.isAllowedConversationURL`) MUST allowlist `http` and `https` schemes with non-empty hosts only, rejecting `javascript:`, `file:`, `data:`, or arbitrary custom URL schemes from untrusted LLM output.
- Temporary QuickLook files written by `PlatformThumbnailGenerator` MUST sanitize filenames via `URL(fileURLWithPath: filename).lastPathComponent` inside a per-item `UUID` subdirectory to prevent path traversal (`../`), and strip all `\u{200B}` zero-width sentinel characters globally (`replacingOccurrences(of: "\u{200B}", with: "")`) from public text bindings and `ConversationSubmission.text`.
- Attachment file importers and drag-and-drop handlers MUST gracefully handle security-scoped URL access (`startAccessingSecurityScopedResource()` / `defer { stopAccessingSecurityScopedResource() }`).

---

## 6. Numbered Testable Acceptance Criteria (`AC-1` – `AC-20`)

- [ ] **AC-1 (Clean-Slate Package & Platform Baseline):** Given `Package.swift` on branch `v2`, when running `swift build` and `swift test`, then the package compiles with `swift-tools-version: 6.2`, targets `.iOS(.v26)`, `.macCatalyst(.v26)`, and `.macOS(.v26)`, enables Swift 6 strict concurrency with zero warnings/errors, and declares zero external package dependencies.
- [ ] **AC-2 (Chameleon Cross-Platform Isolation):** Given `Sources/ConversationKit/`, when scanning `Model/`, `Styles/`, and `Views/` for `#if canImport(UIKit)` or `#if canImport(AppKit)`, then zero occurrences exist outside `Sources/ConversationKit/Platform/`.
- [ ] **AC-3 (F-1 Top-Floating User Message on Send):** Given an active `ConversationView`, when the user submits a message, then the user's message immediately floats to the top of the visible scroll viewport (`anchor: .top`) in the same render transaction as keyboard dismissal in a single smooth animation without down-up bounce or duplicate message flash.
- [ ] **AC-4 (F-2 Non-Pushing Long AI Response — Zero Jitter Gate):** Given a newly submitted user message anchored at the top of the viewport, when an AI response streams in below it and grows beyond 150% of the screen height, then the AI response flows downward off the bottom edge and the top-floating user message's vertical screen coordinate remains unchanged ($\Delta Y = 0\text{pt}$).
- [ ] **AC-5 (F-3 Bubble User Message vs. Canvas AI Response):** Given a conversation containing both `.user` and `.other` messages, when rendered in `ConversationView`, then `.user` messages are displayed inside a right-aligned bubble (`UserMessageBubbleStyle`) while `.other` (AI/system) messages render full-width directly on the background canvas without a bubble container.
- [ ] **AC-6 (F-4 Universal Attachments & Memory-Safe Thumbnails):** Given `ConversationAttachment` instances for images, PDFs, audio, code/text, and arbitrary `UTType` documents (`URL` or `Data`), when added to `MessageComposerView` or rendered in a sent `MessageView`, then background-downsampled thumbnails (`ImageIO` / `QLThumbnailGenerator`) are generated without main-thread blocking, 5+ photos render as a 4-tile grid with a `+N` badge, non-image files render as metadata file chips, and tapping an attachment opens `.quickLookPreview`.
- [ ] **AC-7 (F-4 Upload Progress Rings, Retry & Send Gating):** Given pending attachments in `AttachmentTrayView` with states `.uploading(progress: 0.45)` and `.failed(error:)`, when inspecting the composer, then `.uploading` items display a determinate progress ring (`0.45`) and disable the Send button (`canSubmit == false`), `.failed` items display a retry control that invokes the retry handler, and `.ready` items enable submission.
- [ ] **AC-8 (F-5 Slash Commands `/` & `@` Mentions Autocomplete):** Given configured `/` commands and static/async `@` mention providers, when the user types `/sum` or `@doc` at a word boundary, then `ComposerPopupView` appears above the composer in Liquid Glass with matched-substring highlighting, and selecting an item replaces the query text with a structured `ComposerToken` chip.
- [ ] **AC-9 (F-5 Token Double-Backspace & Duplicate Mention Guard):** Given active `ComposerToken` pills in the composer, when the user selects an already-attached `@mention`, then no duplicate token is added and the existing token pulses; when the text field is empty and the user presses Backspace twice, the first press highlights the last token and the second press removes it.
- [ ] **AC-10 (F-6 Native Liquid Glass Chrome & Scroll Cell Prohibition):** Given all views in `Sources/ConversationKit/Views/`, when auditing modifier usage, then `GlassEffectContainer`, `.glassEffect`, `.buttonStyle(.glass)`, `.buttonStyle(.glassProminent)`, and `.safeAreaBar(edge: .bottom)` are used on composer/floating chrome, and zero `.glassEffect` modifiers exist inside scrolling timeline cell views (`Timeline/` message rows and `Agentic/` views).
- [ ] **AC-11 (F-7 Collapsed-by-Default Expandable ThinkingStateView):** Given a message with an active or completed `ThinkingTrace`, when `ThinkingStateView` initially renders, then `isExpanded` is `false` (collapsed by default), displaying the phase-locked breathing mark, alpha sheen (while active), and tabular monospaced timer (`Thinking · 3.2s` → `Thought for 4s ›`), and tapping the header expands/collapses the full reasoning text.
- [ ] **AC-12 (F-8 First-Turn Suggestion Chips Lifecycle & Modes):** Given an empty conversation configured with `SuggestionChip` items, when the thread has zero sent user messages, then `SuggestionChipsBar` renders directly above the input box; tapping an `.immediateSend` chip submits the message immediately, tapping a `.populateComposer` chip populates the text field and focuses it, and once the first user message is sent, `SuggestionChipsBar` animates out and does not reappear during the conversation.
- [ ] **AC-13 (F-9 Model Selector & Capability Toggles in Input Box):** Given `[ComposerModelOption]` and `[ComposerCapability]` bound or configured on `ConversationView`, when the user selects a model or toggles a capability (`Think`, `Search`, `Image`), then the composer updates the active model badge/pill and passes the selected model and active capabilities in `ConversationSubmission`.
- [ ] **AC-14 (F-10 Floating Scroll-to-Bottom Button with Hysteresis):** Given a scrollable conversation timeline, when the content below the visible viewport exceeds `80pt`, then the floating Liquid Glass `ScrollToBottomButton` appears above the composer; when the user taps it or scrolls within `24pt` of the bottom edge, the button smoothly hides.
- [ ] **AC-15 (F-11 Focus-Driven Keyboard Dismiss Button):** Given `MessageComposerView` inside `GlassEffectContainer`, when the text input field gains focus (`@FocusState == true`), then a circular Liquid Glass button with symbol `keyboard.chevron.compact.down` appears at the trailing side of the composer; when tapped, `@FocusState` becomes `false`, the keyboard dismisses, and the button morphs out.
- [ ] **AC-16 (SwiftUI Style Protocols — `.classicGlass`, `.cardGlass`, `.compactGlass`):** Given `MessageComposerView`, `ThinkingStateView`, and user bubbles, when applying `.messageComposerStyle(.classicGlass)`, `.messageComposerStyle(.cardGlass)`, `.messageComposerStyle(.compactGlass)`, `.thinkingStateStyle(...)`, or `.userMessageBubbleStyle(...)`, then each style renders its distinct layout contract using `StyleConfiguration` without losing focus, token, or attachment state.
- [ ] **AC-17 (Streaming Markdown & Copyable Code Blocks):** Given streaming Markdown containing headings, lists, bold text, and fenced code blocks (` ```swift `), when rendered via `StreamingMarkdownView`, then completed blocks remain frozen while the trailing block updates incrementally with per-word reveal and streaming cursor, and fenced code blocks render a two-tone header with language title and a working Copy button.
- [ ] **AC-18 (Agentic Timeline Surfaces & URL Allowlisting):** Given a message containing `[ToolCall]`, `[Citation]`, `AgentPlan`, and `ApprovalRequest`, when rendered in `ConversationView`, then `ToolCallsGroupView` supports expand/collapse and per-tool retry, `SourceStackView` and `StreamingMarkdownView` both enforce `URL.isAllowedConversationURL` to block non-`http`/`https` URLs (`[MF-5]`), `AgentPlanView` renders step statuses, and `AgentApprovalView` transitions to a resolved state upon tapping `Allow Once`, `Always Allow`, or `Deny`.
- [ ] **AC-19 (Strongly-Typed 2-Generic `ConversationView<MessageType, Content>` & Cooperative Stop Cancellation):** Given `ConversationView<CustomMessage, Content>`, when the developer registers `.onSendMessage { (submission: ConversationSubmission<CustomMessage>) in ... }`, then `submission.message` is strongly typed as `CustomMessage` with zero downcasting, internal `@State` attachment fallback works when `attachments:` is omitted (`[MF-2]`), the Send button transforms into a Stop button while the async handler runs, and tapping Stop invokes cooperative `Task.cancel()`.
- [ ] **AC-20 (FlowDeck Simulator Build, Test & UI Coordinate Verification Gate):** Given `Examples/ConversationKitDemo`, when verified via FlowDeck (`flowdeck build`, `flowdeck test`, `flowdeck run`, and `flowdeck ui` simulator hierarchy/screenshot inspection), then all unit and UI verification checks pass with zero build errors and confirmed $\Delta Y = 0\text{pt}$ top-floating user bubble stability while streaming long AI responses.

---

## 7. Handoff to `@senior-architect`

This PRD (`docs/specs/PRD-0001-CONVERSATIONKIT-V2.md`) is complete and ready for **Stage 2 Architecture Blueprint & ADR** by `@senior-architect` in `docs/architecture/`.
