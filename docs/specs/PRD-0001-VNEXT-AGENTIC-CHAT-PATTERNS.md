# PRD-0001: ConversationKit vNext — Agentic Chat & Modern AI Interaction Patterns

- **Document ID**: `PRD-0001`
- **Status**: Approved for Engineering & Architecture (Rev 2 — Post-Boardroom Review)
- **Target Branch**: `develop`
- **Platforms**: iOS 17+, macCatalyst 17+, macOS 14+, iOS 26+ / macOS 26+ (Liquid Glass)
- **Author**: `@product-manager`
- **Next Handoff**: `@senior-architect`

---

## 1. Context & Problem

### Background & Current State
`ConversationKit` provides a clean, cross-platform SwiftUI chat timeline and composer (`ConversationView`, `MessageView`, `MessageComposerView`) with native "Push and Pin" optimistic scroll physics (`optimisticUserMessage` deduplication and `.top` scroll target anchoring) and basic image attachment support.

However, the AI application landscape has evolved from simple request-response text bubbles into **agentic, transparent, multi-modal workflows**. Modern conversational AI interfaces (as cataloged in the **SwiftPieces** modern AI chat and agent pattern library) require rich empty-state onboarding, visible chain-of-thought reasoning with live elapsed timers, multi-step tool execution groups, structured execution plans, human-in-the-loop (HITL) permission gates, inline source citations, and multi-mode prompt composers (model pickers, capability toggles, `/` slash commands, and `@` context mentions).

### Pain Points
1. **Cold-Start Friction (`Views/Welcome/`)**: When `messages` is empty, `ConversationView` renders a blank scroll canvas. Developers must build custom empty-state overlays, time-of-day greetings, and starter prompt chips from scratch.
2. **Opaque AI Latency (`Views/Agentic/` & `Views/Timeline/`)**: During extended reasoning or tool use, `MessageView` only offers a static 3-dot `TypingIndicator`, giving users zero visibility into whether the model is thinking, how long it has been reasoning, or how to inspect its chain-of-thought trace. Additionally, common post-generation actions (Copy, Regenerate, Rate, Share, Retry on failure) require boilerplate custom closures.
3. **No Native Agentic Primitives (`Views/Agentic/`)**: Developers building tool-calling agents have no structured UI components for grouped tool invocations (`ToolCallsGroupView`), multi-step task checklists (`AgentPlanView`), interactive safety approvals (`AgentApprovalView`), or grounded citation stacks (`SourceStackView`).
4. **Single-Mode Composer & Untyped Submission Ergonomics (`Views/Composer/` & `Views/Timeline/`)**: `MessageComposerView` only supports plain text and attachment cards. It lacks native affordances for switching models, toggling reasoning/search/image capabilities, invoking `/` slash commands or `@` mentions with inline token pills, and displaying per-attachment upload progress rings. Furthermore, `onSendMessage` passes an erased `any Message`, forcing every call site to write `if let defaultMessage = userMessage as? DefaultMessage` boilerplate and dropping composer context (active capability toggles, tokens, selected model, and attachments).

### Target Personas
- **Primary Persona — Swift App Developer ("Alex")**: Building an iOS/macOS AI assistant or agentic workflow app using SwiftUI. Wants a drop-in, idiomatic `ConversationView` that works in 5 lines of code (Troposphere) without ugly `as? DefaultMessage` downcasts, while progressively disclosing rich agentic primitives via view modifiers and protocol extensions (Stratosphere/Mesosphere).
- **Secondary Persona — End User ("Sam")**: Interacting with an AI assistant on iPhone, iPad, or Mac. Expects responsive 120Hz scrolling, immediate feedback during reasoning and tool calls, clear control over sensitive agent actions, and effortless prompt composition.

---

## 2. Vision, Goals & Non-Goals

### Vision
Elevate `ConversationKit` into the definitive Apple-native SwiftUI toolkit for modern conversational AI and autonomous agent interfaces—combining SwiftPieces-inspired visual polish and micro-interactions with Stratos Progressive Disclosure ergonomics and zero-hitch "Push and Pin" scroll physics.

### Goals
- **G-1 (Pillar 1 — Welcome & Kickstart)**: Deliver an adaptive empty-state welcome surface (`Views/Welcome/` — `ConversationWelcomeView`, `PromptSuggestionChip`, `StarterPromptCard`) featuring time-of-day greetings, horizontal snapping prompt chips, categorized starter cards, shuffle transitions, and configurable chip-to-composer handoff (immediate send vs. populate-and-focus).
- **G-2 (Pillar 2 — Thinking & Streaming Replies)**: Replace opaque loading dots with a live monospaced elapsed-seconds reasoning header (`ThinkingStateView`: `Thinking · 3.2s` → `Thought for 4s` or `Thinking stopped · 2.1s`), collapsible reasoning trace, smooth per-token streaming, turnkey `MessageActionBarView` (`Copy`, `Regenerate`, `Rate`, `Share`), and inline error recovery (`Retry`).
- **G-3 (Pillar 3 — Tool Calling, Plans & Approvals)**: Introduce first-class agentic timeline surfaces (`Views/Agentic/`): auto-expanding/auto-folding `ToolCallsGroupView` (`"Used 4 tools · 3.2s"`), `AgentPlanView` step checklists, `AgentApprovalView` (`Allow once`, `Always`, `Deny` with scoped identifiers), and `SourceStackView` citation badges.
- **G-4 (Pillar 4 — Rich Prompt Input & Composer Modes)**: Upgrade `MessageComposerView` (`Views/Composer/`) with a model picker menu, capability toggle chips (`Think`, `Search`, `Image`), `/` slash command and `@` mention autocomplete popups with inline token chips, and attachment upload progress rings.
- **G-5 (Backwards Compatibility, Type-Safe Call Sites & Progressive Disclosure)**: Preserve 100% source compatibility with existing `ConversationView(messages: $messages)` call sites while introducing strongly-typed `.onSendMessage` overloads (`MessageType` and `MessageSubmission<MessageType, AttachmentType>`), full-message `MessageView(message:)` forwarding, and defaulted `Message`/`Attachment` protocol properties.

### Non-Goals
- **NG-1 (No LLM / Networking Runtime)**: `ConversationKit` remains strictly a UI and interaction state library. It will not bundle LLM SDKs (Firebase AI Logic, OpenAI, Anthropic, FoundationModels) or execute network requests directly.
- **NG-2 (No Persistence Layer)**: `ConversationKit` does not own or persist the `messages` or `attachments` collections to SwiftData, CoreData, or CloudKit.
- **NG-3 (No Audio/Voice Waveform Pipeline in vNext)**: Live voice-mode audio capture and real-time FFT waveform rendering are out of scope for `PRD-0001`.
- **NG-4 (No Arbitrary HTML/WebView Canvas)**: Rich artifacts requiring embedded `WKWebView` sandboxes are deferred to a future specification; vNext focuses on native SwiftUI timeline and composer primitives.

---

## 3. Canonical Vocabulary & Model Contract (`[MF-1]`)

To ensure zero drift between `PRD-0001`, `ADR-0001`, and implementation across all targets, `ConversationKit` vNext standardizes on the following canonical view and model names:

### 3.1 Canonical View Names
- **`Views/Welcome/`**: `ConversationWelcomeView`, `PromptSuggestionChip`, `StarterPromptCard`
- **`Views/Timeline/`**: `ConversationView`, `MessageView`, `MessageActionBarView`
- **`Views/Agentic/`**: `ThinkingStateView`, `ToolCallsGroupView`, `AgentPlanView`, `AgentApprovalView`, `SourceStackView`
- **`Views/Composer/`**: `MessageComposerView`, `AttachmentPreviewScrollView`, `AttachmentPreviewCard`, `ComposerSuggestionPopupView`, `ComposerTokenChip`

### 3.2 Canonical `Message` & `Attachment` Protocol Properties
Every property added to `Message` and `Attachment` in vNext includes a non-breaking default protocol extension:

| Protocol | Property | Type | Default Extension Value | Description |
| :--- | :--- | :--- | :--- | :--- |
| `Message` | `thinking` | `ThinkingTrace?` | `nil` | Reasoning status (`.thinking`, `.completed`, `.cancelled`), summary, transcript, and duration. |
| `Message` | `toolCalls` | `[ToolCall]` | `[]` | Ordered list of tool invocations (`.pending`, `.running`, `.succeeded`, `.failed`, `.cancelled`). |
| `Message` | `citations` | `[Citation]` | `[]` | Grounded source citations rendered by `SourceStackView`. |
| `Message` | `plan` | `AgentPlan?` | `nil` | Multi-step execution plan rendered by `AgentPlanView`. |
| `Message` | `approvalRequest` | `ApprovalRequest?` | `nil` | HITL authorization request rendered by `AgentApprovalView`. |
| `Message` | `isStreaming` | `Bool` | `false` | Indicates active token generation for streaming cursor and action-bar gating. |
| `Message` | `rating` | `MessageRating?` | `nil` | User feedback rating (`.up`, `.down`) reflected in `MessageActionBarView`. |
| `Attachment` | `uploadProgress` | `Double?` | `nil` | Determinate upload progress (`0.0...1.0`); `< 1.0` gates submission. |
| `Attachment` | `uploadError` | `(any Error)?` | `nil` | Optional upload failure surfaced on `AttachmentPreviewCard`. |

---

## 4. User Stories & Functional Requirements (Across the 4 Feature Pillars)

### Pillar 1: Chat Welcome & Kickstart Prompt Chips (`Views/Welcome/`)

#### User Stories
- **US-1.1 (Contextual Welcome)**: As an end user opening a new conversation (`displayedMessages.isEmpty`), I want to see a warm time-of-day greeting (`"Good morning"`, `"Good afternoon"`, `"Good evening"`, or custom title/subtitle) in `ConversationWelcomeView` so the interface feels inviting and alive.
- **US-1.2 (Prompt Discovery & Shuffle)**: As an end user unsure what to ask, I want to browse horizontally snapping `PromptSuggestionChip` pills and categorized `StarterPromptCard` items, and tap a Shuffle control to cycle through fresh suggestions.
- **US-1.3 (Chip-to-Composer Handoff)**: As an app developer, I want to configure whether tapping a starter prompt chip **immediately submits** the prompt (with optimistic scroll anchoring) or **populates the composer text field and focuses the keyboard** so the user can customize a template prompt before sending.

#### Functional Requirements (`Views/Welcome/`)
- **`FR-1.1` (`WelcomeConfiguration` & `ConversationWelcomeView`)**:
  - Automatically rendered inside `ConversationView` when `displayedMessages.isEmpty` and welcome configuration is enabled.
  - Supports dynamic time-of-day greeting resolution based on local `Calendar`/`Date` (`05:00–11:59` → Morning, `12:00–17:59` → Afternoon, `18:00–04:59` → Evening) with optional user display name interpolation (e.g., `"Good afternoon, Peter"`) or explicit static override.
- **`FR-1.2` (Horizontal Snapping `PromptSuggestionChip`)**:
  - Scrollable horizontal rail of compact pill chips (`PromptSuggestionChip`) using `.scrollTargetLayout()` and `.scrollTargetBehavior(.viewAligned)`.
  - Each chip displays an optional SF Symbol icon, concise title, and subtle category tint.
- **`FR-1.3` (Categorized `StarterPromptCard` & Shuffle State)**:
  - Adaptive grid/stack of categorized starter cards (`StarterPromptCard`: category badge, icon, title, subtitle/prompt preview).
  - Includes a `"Shuffle"` button (`arrow.triangle.2.circlepath`) when the developer supplies a pool of suggestions larger than the visible slice, animating transitions with `.snappy` spring physics and sensory feedback (`sensoryFeedback(.selection, trigger:)`).
- **`FR-1.4` (`PromptHandoffBehavior` Mode)**:
  - `.immediateSend`: Selecting a chip/card constructs the user message, triggers `ConversationView.submit()` synchronously with `optimisticUserMessage`, transitions out `ConversationWelcomeView`, and invokes `onSendMessage`.
  - `.populateComposer`: Selecting a chip/card writes the prompt text into `MessageComposerView`'s bound `$message` and sets `@FocusState` to `.message` so the user can edit before sending.

---

### Pillar 2: Thinking States & Streaming Replies (`Views/Agentic/` & `Views/Timeline/`)

#### User Stories
- **US-2.1 (Live Thinking Timer)**: As an end user waiting for a reasoning model, I want to see a live monospaced timer (`Thinking · 3.2s`) that ticks smoothly at 100ms intervals so I know the assistant is actively working.
- **US-2.2 (Collapsible Reasoning Trace & Cancellation)**: As an end user, I want the thinking header to settle into `"Thought for 4s"` once the reply starts streaming (or `"Thinking stopped · 2.1s"` if cancelled), and I want to tap the header to expand or collapse the model's step-by-step chain-of-thought reasoning transcript.
- **US-2.3 (Streaming & Post-Reply Actions)**: As an end user reading an AI response, I want tokens to stream smoothly without layout jumps, and once complete (`isStreaming == false`), I want one-tap access to `Copy`, `Regenerate`, `Rate` (thumbs up/down), and `Share`, or `Retry` if generation failed.

#### Functional Requirements (`Views/Agentic/` & `Views/Timeline/`)
- **`FR-2.1` (`ThinkingStateView`, `ThinkingTrace` & Live Elapsed Timer)**:
  - `ThinkingTrace.Status` supports three explicit states (`[MF-2]`):
    - `.thinking(startedAt: Date)`
    - `.completed(duration: TimeInterval)`
    - `.cancelled(duration: TimeInterval)`
  - Driven by a leaf-scoped `TimelineView(.periodic(from: startedAt, by: 0.1))` while `status` is `.thinking(startedAt:)`.
  - Renders a shimmer/pulse icon alongside `"Thinking · \(elapsed, format: .number.precision(.fractionLength(1)))s"` using `.monospacedDigit()` typography so character widths never jitter during ticking.
  - When reasoning completes (`.completed(duration:)`), displays `"Thought for \(Int(duration.rounded()))s"` with a disclosure chevron (`chevron.right` / `chevron.down`).
  - When reasoning is cancelled via the Stop button (`.cancelled(duration:)`), stops timer ticking immediately and displays `"Thinking stopped · \(duration, format: .number.precision(.fractionLength(1)))s"`.
- **`FR-2.2` (Collapsible Reasoning Trace)**:
  - Expanding `ThinkingStateView` reveals `thinking.summary` and/or `thinking.transcript` styled with muted secondary typography and a leading vertical accent guide bar.
  - Tracks `@State private var hasUserToggled: Bool = false` and automatically folds (`isExpanded = false`) when transitioning from `.thinking` to `.completed` unless the user manually toggled the header (`!hasUserToggled`).
- **`FR-2.3` (Full-Message `MessageView` Forwarding & Per-Token Streaming)**:
  - `MessageView` provides a primary initializer `public init(message: some Message)` (in addition to preserving the legacy 4-parameter initializer for backwards compatibility) so `ConversationView`'s default convenience initializers (`where Content == MessageView`) pass the full `MessageType` instance and automatically render `thinking`, `toolCalls`, `plan`, `approvalRequest`, `citations`, `isStreaming`, and `rating` (`[MF-1]`).
  - `MessageView` renders streaming markdown chunks incrementally without resetting scroll offset or breaking the active `autoScrollTargetID` top-pinning anchor, displaying a subtle streaming indicator while `message.isStreaming == true`.
- **`FR-2.4` (Standardized `MessageActionBarView`)**:
  - Built-in turnkey action bar rendered below completed `.other` messages (`!message.isStreaming && message.error == nil`), while preserving custom `.messageActions { ... }` override support:
    - **Copy**: Copies markdown/plain content to the system clipboard (`UIPasteboard` / `NSPasteboard` via `PlatformTypes`) and swaps the icon to `checkmark` for 1.5 seconds.
    - **Regenerate**: Invokes `@Environment(\.onRegenerateMessageAction)` for the target message through `ConversationView`'s token-guarded turn coordinator.
    - **Rate (Thumbs Up / Thumbs Down)**: Toggles mutually exclusive `MessageRating` state (`.up` / `.down` / `nil`) reflecting `message.rating` and fires `@Environment(\.onRateMessageAction)`.
    - **Share**: Presents native `ShareLink(item:)` for the message text.
- **`FR-2.5` (Failed Reply Banner, Error Equality & Retry Action)**:
  - When `message.error != nil`, `MessageView` renders an inline destructive-tinted error card displaying the localized failure summary, an optional `"More information"` button (`presentErrorAction`), and a prominent `"Retry"` button (`arrow.clockwise`) that invokes `@Environment(\.onRetryMessageAction)` via the token-guarded turn coordinator.
  - `DefaultMessage`'s `Equatable` and `Hashable` conformance MUST include error identity (whether `error != nil`, plus `NSError` domain/code and `localizedDescription` fingerprint) so mutating `message.error` in place reliably triggers SwiftUI view diffing and `onChange(of: displayedMessages)` (`[MF-3]`).

---

### Pillar 3: Tool Calling, Agent Plans & Approvals (`Views/Agentic/`)

#### User Stories
- **US-3.1 (Auto-Expanding / Auto-Folding Tool Call Group)**: As an end user watching an agent invoke multiple tools, I want `ToolCallsGroupView` to automatically expand while tools are running so I can see live progress, and automatically fold into a compact summary (`"Used 4 tools · 3.2s"`) once all tools succeed—unless a tool fails or is cancelled, in which case I want clear status visibility and a `Retry` button for failed tools.
- **US-3.2 (Inspectable Tool Invocations)**: As a power user or developer, I want to tap any tool row inside `ToolCallsGroupView` to inspect its SF Symbol, tool name, human-readable argument summary, execution status/duration, raw JSON input/output payload, and retry a failed tool call.
- **US-3.3 (Agent Execution Plan Checklist)**: As an end user delegating a multi-step task, I want to see an inline `AgentPlanView` checklist that updates step statuses (`pending`, `inProgress`, `completed`, `failed`, `skipped`, `cancelled`) with progress count (`"3 of 5 completed"`).
- **US-3.4 (Human-in-the-Loop Approval Gate with Scoped Always-Allow)**: As an end user, when an agent attempts a sensitive action (e.g., deleting a file, executing a shell command), I want an inline `AgentApprovalView` card with explicit `Allow once`, `Always`, and `Deny` buttons, where `Always` is transparently scoped to `scopeIdentifier` (e.g., `"bash:git status"` or `"mcp:filesystem/read"`).
- **US-3.5 (Grounded & Safe Source Citations)**: As an end user reading a grounded response, I want a compact `SourceStackView` badge pill showing overlapping domain badges and source count (`"4 sources"`) that expands into clickable citation cards restricted to safe web schemes (`http`/`https`).

#### Functional Requirements (`Views/Agentic/`)
- **`FR-3.1` (`ToolCallsGroupView` & `ToolCall`)**:
  - `ToolCall` includes `id`, `name`, `symbolName: String?`, `argumentsSummary: String?`, `resultSummary: String?`, `argumentsJSON: String?`, `resultJSON: String?`, `durationSeconds: TimeInterval?`, and `status: ToolCall.Status` (`.pending`, `.running`, `.succeeded`, `.failed`, `.cancelled`).
  - Header displays aggregate status:
    - While any tool is `.running`: `"Running tools… (2/4)"` with live monospaced elapsed timer and progress spinner.
    - When all tools reach `.succeeded`: `"Used \(count) \(count == 1 ? "tool" : "tools") · \(totalDuration)s"`.
    - When any tool is `.cancelled` (and none `.failed`): `"Tool execution stopped"`.
    - When one or more tools end in `.failed`: `"Tool execution failed (1 of \(count))"` in warning/destructive tint.
  - **Auto-Expand / Auto-Fold State Machine**:
    - Automatically expands (`isExpanded = true`) when the first tool enters `.running`.
    - Automatically folds (`isExpanded = false`) after a brief settle delay (`400ms`) when all tools reach `.succeeded`, **unless** the user manually toggled expansion during execution (`hasUserToggled == true`).
    - Remains expanded (`isExpanded = true`) if any tool ends in `.failed`.
  - **Tool Row Detail**:
    - Displays SF Symbol icon (`symbolName ?? "wrench.and.screwdriver"`), tool name, concise `argumentsSummary`, and right-aligned duration/status badge.
    - Tapping a tool row expands a collapsible JSON payload inspector (`argumentsJSON` / `resultJSON` in a monospaced code block with one-tap copy).
    - Failed tool rows expose an inline `"Retry"` button connected to `@Environment(\.onRetryToolCallAction)` through the turn coordinator.
- **`FR-3.2` (`AgentPlanView` & `AgentPlan`)**:
  - Renders a structured card with plan title, overall progress bar/fraction (`completedCount / totalCount`), and ordered `AgentPlan.Step` rows.
  - `AgentPlan.Step.Status` supports `.pending`, `.inProgress`, `.completed`, `.failed`, `.skipped`, and `.cancelled` (`[MF-2]`).
  - Each step renders a state-specific indicator (empty circle for `.pending`, animated spinner for `.inProgress`, filled checkmark circle for `.completed`, exclamation triangle for `.failed`, strikethrough dash for `.skipped`, stop slash circle for `.cancelled`), step title, and optional detail caption.
- **`FR-3.3` (`AgentApprovalView` & `ApprovalRequest`)**:
  - `ApprovalRequest` includes `id`, `title`, `detail`, `scopeIdentifier: String?` (`[SF-3]`), and `decision: ApprovalRequest.Decision` (`.pending`, `.allowOnce`, `.alwaysAllow`, `.deny`, `.cancelled`).
  - When `decision == .pending`, renders a high-salience card displaying `title`, `detail`, optional `scopeIdentifier` pill (e.g., `"Scope: filesystem.write"`), and three action buttons:
    - **Allow once** (`.allowOnce` — primary prominent button)
    - **Always** (`.alwaysAllow` — secondary bordered button; label/accessibility hint clarifies scope when `scopeIdentifier != nil`)
    - **Deny** (`.deny` — destructive/cancel button)
  - If the active generation task is cancelled while `decision == .pending`, transitions to `.cancelled` (`"Approval cancelled"`).
  - Once resolved, transitions smoothly into a compact read-only resolution badge and invokes `@Environment(\.onAgentApprovalDecision)`.
- **`FR-3.4` (`SourceStackView` & `Citation` URL Scheme Allowlisting)**:
  - Compact collapsed state: Pill badge displaying stacked circular domain/symbol badges + `"N sources"` label.
  - Expanded state: Cards showing source index badge (`[1]`), `title`, domain host, and optional `snippet`.
  - **Security Allowlist (`[SF-2]`)**: `SourceStackView` MUST validate `citation.url?.scheme?.lowercased()` against `["http", "https"]` before enabling link opening (`Link` / `openURL`). Citations with `nil` URLs or non-allowlisted schemes (e.g., `javascript:`, `file:`, `data:`) render as non-interactive text cards and never invoke `openURL`.

---

### Pillar 4: Rich Prompt Input, Call-Site Ergonomics & Composer Modes (`Views/Composer/` & `Views/Timeline/`)

#### User Stories
- **US-4.1 (Strongly-Typed `.onSendMessage` & Submission Context — Federighi Call-Site Fix)**: As a Swift developer using `ConversationView(messages: $messages)`, I want `.onSendMessage` to hand me my concrete `MessageType` (or a rich `MessageSubmission<MessageType, AttachmentType>` containing my message, attachments, active capabilities, tokens, and selected model ID) so I never have to write `if let defaultMessage = userMessage as? DefaultMessage` or manually scrape composer state.
- **US-4.2 (Model Picker Menu)**: As an end user, I want to switch between available AI models (e.g., `"Claude 4.6 Sonnet"`, `"GPT-5"`, `"Gemini 3 Flash"`) directly from a compact pill menu in the composer toolbar.
- **US-4.3 (Capability Toggle Chips)**: As an end user, I want one-tap toggle chips (`Think`, `Search`, `Image`, or custom capabilities) in the composer so I can enable deep reasoning, web search, or image generation for my next prompt.
- **US-4.4 (`/` Slash Commands & `@` Mentions Autocomplete)**: As a power user typing `/` at the start of a command or `@` to reference a file/agent/context item, I want a floating autocomplete popup above the composer that inserts structured token chips (`ComposerTokenChip`) into my prompt.
- **US-4.5 (Attachment Upload Progress Rings & Return-Key Safety)**: As an end user attaching images/files or typing a follow-up draft while the AI is generating, I want each `AttachmentPreviewCard` to show a circular upload progress ring (`0.0...1.0`), prevent submission until uploads finish, and ensure pressing Return while `isGenerating == true` never accidentally stops the active AI stream.

#### Functional Requirements (`Views/Composer/` & `Views/Timeline/`)
- **`FR-4.1` (Strongly-Typed `.onSendMessage` Overloads & `MessageSubmission` — `[MF-1]`)**:
  - `ConversationView` exposes typed view modifiers directly on `ConversationView<Content, MessageType, AttachmentType>`:
    1. **Typed Message Overload**:
       ```swift
       public func onSendMessage(
         _ action: @escaping @MainActor (MessageType) async -> Void
       ) -> Self
       ```
       Eliminates `as? DefaultMessage` downcasting for standard chat flows.
    2. **Enriched Submission Context Overload**:
       ```swift
       public struct MessageSubmission<MessageType: Message, AttachmentType: Attachment>: Sendable {
         public let message: MessageType
         public let attachments: [AttachmentType]
         public let activeCapabilities: Set<ComposerCapability>
         public let tokens: [ComposerTokenChip]
         public let selectedModelID: String?
       }

       public func onSendMessage(
         _ action: @escaping @MainActor (MessageSubmission<MessageType, AttachmentType>) async -> Void
       ) -> Self
       ```
    3. **Legacy Environment Overload Preserved**: The existing `View.onSendMessage(_ action: @escaping @MainActor (any Message) async -> Void)` modifier remains available and functional as a fallback when neither typed closure is supplied on `ConversationView`.
- **`FR-4.2` (Model Picker Menu — `ComposerModelOption`)**:
  - Optional model selector menu displayed inside the composer accessory bar when models are configured via `.composerModels(_:selection:)`.
  - Each `ComposerModelOption` includes `id: String`, `name: String`, optional `subtitle: String?` / badge (e.g., `"Fast"`, `"Reasoning"`), and optional `symbolName: String?`.
- **`FR-4.3` (Capability Toggle Chips — `ComposerCapability`)**:
  - Toggleable capsule chips rendered in the composer's bottom accessory row (`Think` with `brain` symbol, `Search` with `globe` symbol, `Image` with `photo.badge.plus` symbol, plus `.custom(id:title:symbolName:)`).
  - Active chips adopt accent-tinted fill, bold label, and accessibility toggle traits (`.isSelected`).
- **`FR-4.4` (`/` Slash Commands & `@` Mentions Popup + `ComposerTokenChip`)**:
  - Detects active trigger prefixes (`/` or `@`) at the current cursor/word boundary in `MessageComposerView`.
  - Presents a floating, keyboard-navigable (Up/Down/Return/Escape on macOS & iPadOS hardware keyboards; tap on iOS) autocomplete list (`ComposerSuggestionPopupView`) anchored above the composer container.
  - Selecting a `/command` or `@mention` inserts a structured `ComposerTokenChip` (rendered as a distinct removable token pill in the composer) and removes the raw partial trigger query from the plain text buffer.
- **`FR-4.5` (Attachment Upload Progress Rings & Return-Key Safety — `[MF-2]`)**:
  - When `attachment.uploadProgress` is between `0.0` and `< 1.0`, `AttachmentPreviewCard` overlays a translucent dimmed backdrop with a determinate circular progress ring (`accessibilityIdentifier("attachment_upload_progress")`).
  - Composer `canSubmit` evaluates to `false` while any attachment has `uploadProgress != nil && uploadProgress! < 1.0` or `uploadError != nil`.
  - **Return-Key Safety (`[MF-2]`)**: In `MessageComposerView`, `.onSubmit(of: .text)` MUST only invoke `onSubmitAction()` when `!isGenerating && canSubmit`. Pressing Return while `isGenerating == true` MUST be a no-op and MUST NOT call `onStopAction()`. Stopping an active generation requires explicitly tapping the Stop button (`composer_primary_button`) or pressing `Escape` (`KeyEquivalent.escape`).

---

## 5. Non-Functional Requirements & Technical Considerations

### 5.1 Preserving "Push and Pin" Optimistic Scroll Physics & `.safeAreaInset` Geometry (`[SF-1]`)
- **Zero-Frame-Delay Contract**: All prompt submission entry points—including tapping Send in `MessageComposerView`, pressing Return when `!isGenerating`, or tapping an `.immediateSend` starter chip in `ConversationWelcomeView`—**must** execute the synchronous `optimisticUserMessage` assignment inside the same `@MainActor` render transaction as keyboard dismissal and state transition.
- **Dynamic Bottom Inset via `.safeAreaInset(edge: .bottom)` (`[SF-1]`)**:
  - Replace the legacy `ZStack(alignment: .bottom)` + hardcoded `Spacer().frame(height: 100)` in `ConversationView` with `.safeAreaInset(edge: .bottom, spacing: 0)` hosting `MessageComposerView`.
  - As `MessageComposerView` grows or shrinks vertically (due to multi-line text, `AttachmentPreviewScrollView`, capability toggle chips, token chips, or `ComposerSuggestionPopupView`), SwiftUI automatically adjusts the `ScrollView` content inset so the bottom of the conversation thread is never obscured behind the composer.
- **Single Outer Scroll Identity**: Every turn in `ConversationView` retains a single outer `.id(ConversationScrollID.message(message.id))`. Agentic subviews (`ThinkingStateView`, `ToolCallsGroupView`, `AgentPlanView`, `AgentApprovalView`, `SourceStackView`, `MessageActionBarView`) mutate height inside that container without registering competing `ScrollViewTargetLayout` IDs.

### 5.2 Token-Guarded Turn Coordinator & Cancellation Lifecycle (`[MF-2]`)
- **Single Turn Coordinator in `ConversationView`**:
  - `ConversationView` manages a unified `@State private var activeTurnToken: UUID?` alongside `sendingTask: Task<Void, Never>?`.
  - All async turn-initiating actions—`submit()` (`onSendMessage`), `onRegenerateMessage`, `onRetryMessage`, and `onRetryToolCall`—route through this coordinator:
    1. Any existing `sendingTask` is cancelled (`sendingTask?.cancel()`).
    2. A fresh `let turnToken = UUID()` is assigned to `activeTurnToken`.
    3. In the `Task`'s `defer` block, `sendingTask = nil` and `optimisticUserMessage = nil` are only cleared if `self.activeTurnToken == turnToken`, preventing a cancelled task's late cleanup from clobbering a newly started turn.

### 5.3 120Hz Streaming Performance & Fast-Path Value Diffing (`[MF-4]`)
- **`O(1)` Fast-Path Equality on Streaming Types (`[MF-4]`)**:
  - High-frequency token and reasoning updates mutate `DefaultMessage.content`, `ThinkingTrace.transcript`, and `ToolCall.resultSummary` up to 60–120 times per second.
  - `ThinkingTrace` and `ToolCall` custom `==` implementations must compare fixed-size scalar/enum fields (`id`, `status`, `durationSeconds`) and `transcript.utf8.count` / `resultJSON?.utf8.count` before falling back to full string buffer comparison, and `ConversationView` must coalesce `proxy.scrollTo(..., anchor: .top)` calls to at most once per display frame (~8.3ms / 120Hz) during active streaming.
- **Scoped Timer Invalidation**: The `0.1s` `TimelineView` inside `ThinkingStateView` must be isolated to the timer text leaf view so ticks never re-evaluate `Markdown` or sibling agentic views.

### 5.4 Chameleon Cross-Platform Compatibility (`PlatformTypes.swift`)
- **Supported Targets**: iOS 17+, macCatalyst 17+, macOS 14+, with progressive enhancement for iOS 26+ / macOS 26+ Liquid Glass (`GlassEffectContainer` and `.glassEffect`).
- **Zero UIKit/AppKit Leaks in Views**: All platform-specific clipboard operations (`UIPasteboard` vs `NSPasteboard`), colors, haptics, and keyboard shortcuts must be centralized in `Platform/PlatformTypes.swift`.

### 5.5 Stratos Progressive Disclosure API Ergonomics
Following the 4-layer Stratos model:
1. **Troposphere (Zero-Config Drop-In)**:
   ```swift
   ConversationView(messages: $messages)
     .onSendMessage { userMessage in
       messages.append(userMessage) // Strongly typed as DefaultMessage!
     }
   ```
   Compiles with zero downcasting and automatically renders all agentic sub-surfaces via `MessageView(message: message)`.
2. **Stratosphere (Modifier-Based Customization)**:
   Developers progressively opt into vNext features via fluent view modifiers:
   - `.welcomeConfiguration(_:)` / `.starterPrompts(_:handoff:)`
   - `.composerModels(_:selection:)`
   - `.composerCapabilities(_:active:)`
   - `.slashCommands(_:)` / `.mentionSuggestions(_:)`
   - `.onRegenerateMessage(_:)` / `.onRateMessage(_:)` / `.onRetryMessage(_:)`
   - `.onAgentApproval(_:)` / `.onRetryToolCall(_:)`
3. **Mesosphere (Standalone Composable Views)**:
   Every vNext component (`ConversationWelcomeView`, `PromptSuggestionChip`, `StarterPromptCard`, `ThinkingStateView`, `ToolCallsGroupView`, `AgentPlanView`, `AgentApprovalView`, `SourceStackView`, `MessageActionBarView`) is `public` and can be composed independently inside a custom `ConversationView { message in ... }` `@ViewBuilder` closure.
4. **Thermosphere (Custom Protocol Conformance)**:
   The `Message` and `Attachment` protocols provide default extension implementations for all vNext properties (`thinking`, `toolCalls`, `citations`, `plan`, `approvalRequest`, `isStreaming`, `rating`, `uploadProgress`, `uploadError`) so existing custom `Message` types compile without modification.

---

## 6. Numbered Testable Acceptance Criteria

### Pillar 1: Chat Welcome & Kickstart Prompt Chips (`Views/Welcome/`)
- **`AC-1` (Time-of-Day Greeting Resolution)**: Given a `WelcomeConfiguration` using automatic time-of-day greeting, when evaluated at `09:00`, `14:00`, and `20:00` local time, `ConversationWelcomeView` resolves deterministically to morning, afternoon, and evening localized strings respectively, and interpolates the optional user name when provided.
- **`AC-2` (Welcome Surface Visibility)**: Given a `ConversationView` configured with `.welcomeConfiguration(...)`, when `displayedMessages` is empty, `ConversationWelcomeView` is visible (`accessibilityIdentifier("welcome_view")`); as soon as `displayedMessages` becomes non-empty (including via `optimisticUserMessage`), `ConversationWelcomeView` is removed from the hierarchy.
- **`AC-3` (Starter Shuffle State)**: Given a starter prompt pool of 8 items with a visible page size of 4, when the user triggers the Shuffle action (`accessibilityIdentifier("welcome_shuffle_button")`), the displayed slice of `StarterPromptCard` items updates to a new permutation without mutating the underlying source pool count.
- **`AC-4` (Chip-to-Composer Handoff — Immediate vs. Populate)**:
  - When `handoff == .immediateSend`, tapping a `PromptSuggestionChip` or `StarterPromptCard` sets `optimisticUserMessage` synchronously, clears the welcome state, and invokes `onSendMessage` with the chip's prompt text.
  - When `handoff == .populateComposer`, tapping a chip populates `MessageComposerView`'s text binding with the chip's prompt text, focuses the composer input field, and does **not** invoke `onSendMessage`.

### Pillar 2: Thinking States & Streaming Replies (`Views/Agentic/` & `Views/Timeline/`)
- **`AC-5` (Live Monospaced Thinking Timer, Completed & Cancelled Badges)**: Given an AI message with `thinking?.status == .thinking(startedAt:)`, `ThinkingStateView` formats elapsed seconds to 1 decimal place (`"Thinking · 3.2s"`) using `.monospacedDigit()`. When transitioned to `.completed(duration: 4.1)`, the label updates to `"Thought for 4s"` and stops timer invalidation. When transitioned to `.cancelled(duration: 2.1)`, the label updates to `"Thinking stopped · 2.1s"` and stops timer invalidation.
- **`AC-6` (Collapsible Reasoning Trace)**: Given a `ThinkingStateView` with non-empty `thinking.transcript`, tapping the thinking header toggles the visibility of the reasoning trace container (`accessibilityIdentifier("thinking_trace_content")`) and sets `hasUserToggled = true` so subsequent completion does not override the user's manual expansion state.
- **`AC-7` (Message Action Bar Callbacks)**: Given a completed `.other` message (`isStreaming == false`, `error == nil`) displaying `MessageActionBarView`, tapping `Copy` writes the message content to the platform clipboard; tapping `Regenerate` fires `onRegenerateMessageAction` with the target message; tapping `Thumbs Up` or `Thumbs Down` fires `onRateMessageAction` with the corresponding `MessageRating`; and `ShareLink` exposes the message text.
- **`AC-8` (Failed Reply, Error Equality & Retry)**: Given a `DefaultMessage` whose `error` transitions from `nil` to a non-nil `Error`, `DefaultMessage.==` detects the error change (`[MF-3]`), `MessageView` renders the error banner with a `"Retry"` button (`accessibilityIdentifier("message_retry_button")`), and tapping `"Retry"` invokes `onRetryMessageAction` via the token-guarded turn coordinator.

### Pillar 3: Tool Calling, Agent Plans & Approvals (`Views/Agentic/`)
- **`AC-9` (`ToolCallsGroupView` Auto-Expand, Auto-Fold & Cancellation Lifecycle)**:
  - When any `ToolCall` in `message.toolCalls` transitions to `.running`, `ToolCallsGroupView` automatically expands (`isExpanded == true`).
  - When all tools transition to `.succeeded` and the user has not manually overridden expansion, `ToolCallsGroupView` automatically folds (`isExpanded == false`) and displays `"Used N tools · X.Xs"`.
  - When any tool transitions to `.failed`, `ToolCallsGroupView` remains expanded (`isExpanded == true`) and exposes a per-tool `"Retry"` button (`onRetryToolCallAction`).
  - When any tool transitions to `.cancelled`, the row renders a cancelled badge and stops active spinners.
- **`AC-10` (Tool Call Detail & JSON Payload Inspection)**: Given a `ToolCall` with `symbolName`, `name`, `argumentsSummary`, `durationSeconds`, `status`, and `argumentsJSON`/`resultJSON`, tapping the tool row toggles the monospaced JSON payload view (`accessibilityIdentifier("tool_call_json_payload")`).
- **`AC-11` (`AgentPlanView` Checklist Progress)**: Given an `AgentPlan` with 6 steps (3 `.completed`, 1 `.inProgress`, 1 `.pending`, 1 `.cancelled`), `AgentPlanView` accurately computes and displays the `3/6` progress state and renders distinct status indicators for each `AgentPlan.Step.Status` case.
- **`AC-12` (`AgentApprovalView` Decision Flow & Scoped Always-Allow)**: Given an `ApprovalRequest` in `.pending` state with `scopeIdentifier: "mcp:filesystem/write"`, `AgentApprovalView` renders the scope label alongside `Allow once`, `Always`, and `Deny` buttons. Tapping any button invokes `onAgentApprovalDecision` with the matching `ApprovalRequest.Decision` case (`.allowOnce`, `.alwaysAllow`, `.deny`) and transitions the card to its resolved read-only state; cancelling the turn transitions pending requests to `.cancelled`.
- **`AC-13` (`SourceStackView` Citation Badges & Scheme Allowlist)**: Given a message with `citations: [Citation]`, `SourceStackView` renders a collapsed summary badge (`"N sources"`) that expands on tap to reveal citation cards. Citations with `http` or `https` URLs render interactive links, whereas citations with non-allowlisted schemes (`javascript:`, `file:`, `data:`) render as non-interactive cards and never invoke `openURL` (`[SF-2]`).

### Pillar 4: Rich Prompt Input, Call-Site Ergonomics & Composer Modes (`Views/Composer/`)
- **`AC-14` (Model Picker Selection)**: Given a `MessageComposerView` configured with `[ComposerModelOption]` and a selection binding, selecting a model from the menu updates the bound `ComposerModelOption.ID` and displays the active model's short label in the composer pill.
- **`AC-15` (Capability Toggle Chips)**: Given a `MessageComposerView` configured with capability toggles (`.think`, `.search`, `.image`), tapping a capability chip toggles its membership in the bound `Set<ComposerCapability>` state.
- **`AC-16` (`/` Slash Command & `@` Mention Token Resolution)**: Given configured slash commands and `@` mentions, typing `/sum` or `@readme` in the composer filters `ComposerSuggestionPopupView` suggestions case-insensitively; selecting a suggestion inserts the corresponding `ComposerTokenChip` into the composer's active tokens and strips the raw trigger query from the plain text buffer.
- **`AC-17` (Attachment Upload Progress Ring, Send Gating & Return-Key Safety)**:
  - Given an attachment whose `uploadProgress` is `0.45`, `AttachmentPreviewCard` renders the determinate progress ring (`accessibilityIdentifier("attachment_upload_progress")`) and `MessageComposerView` disables the primary Send button until all attachments report `uploadProgress == nil` or `uploadProgress! >= 1.0`.
  - Pressing Return in `MessageComposerView` while `isGenerating == true` does **not** invoke `onStopAction()` (`[MF-2]`).

### Cross-Cutting, Ergonomics & Architecture Criteria
- **`AC-18` (Zero Regression on "Push and Pin" Scroll Physics & `.safeAreaInset`)**: Submitting a message via `MessageComposerView` or a `ConversationWelcomeView` `.immediateSend` chip synchronously sets `optimisticUserMessage`, deduplicates by `Message.ID` in $O(1)$ when the parent appends the message, dynamically insets scroll content via `.safeAreaInset(edge: .bottom)` (`[SF-1]`), and maintains `.top` scroll anchoring with 120Hz frame-coalesced scroll updates (`[MF-4]`).
- **`AC-19` (Strongly-Typed `.onSendMessage` & Backwards-Compatible Default Protocol Implementations)**:
  - `ConversationView(messages: $messages).onSendMessage { message in ... }` provides `message` strongly typed as `MessageType` (and supports the `MessageSubmission<MessageType, AttachmentType>` overload) while `MessageView(message: message)` automatically renders all agentic properties on 1-liner `ConversationView` initializers (`[MF-1]`).
  - Existing types conforming to `Message` and `Attachment` from `ConversationKit` v1 and existing `View.onSendMessage { (any Message) in ... }` call sites compile without modification under Swift 5.10 / Swift 6 strict concurrency across iOS 17+ and macOS 14+.
  - Cancelling a turn and immediately starting a new turn via the token-guarded turn coordinator (`activeTurnToken`) never clears the new turn's `sendingTask` or `optimisticUserMessage` (`[MF-2]`).
