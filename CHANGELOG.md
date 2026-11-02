# Changelog

## v2.0.0
- ✨ **Clean-Slate ConversationKit v2 Architecture**: Rebuilt from the ground up for **iOS 26.0+, macCatalyst 26.0+, and macOS 26.0+** with **Swift 6.2** strict concurrency (`Sendable`) and zero external dependencies, following the **Stratos 4-Layer Progressive Disclosure** design system.
- 🪟 **Native iOS 26 / macOS 26 Liquid Glass Chrome**: Introduced `MessageComposerStyle` with three built-in Liquid Glass styles—`.classicGlass` (3-zone bookend sibling layout), `.cardGlass` (2-row AI assistant card), and `.compactGlass` (single-row compact capsule)—built with `GlassEffectContainer`, `.glassEffect(.regular.interactive())`, and `.safeAreaBar(edge: .bottom)` strictly confined to floating chrome.
- 🎨 **Pluggable Style Protocols**: Added `ThinkingStateStyle` (`.collapsibleHeader`, `.pill`, `.minimal`) and `UserMessageBubbleStyle` (`.tailedBubble`, `.roundedCard`, `.capsule`).
- 🎯 **Top-Floating Turn Scroll Physics**: Added `ConversationTurn` grouping (`ConversationTurn.group(_:)`), locked `activeTurnMinHeight` unoccluded viewport runway, single-shot `proxy.scrollTo(turnID, anchor: .top)` on send ($\Delta Y = 0\text{pt}$ during token streaming), and `ScrollToBottomButton` with hysteresis (`>80pt` show / `<24pt` hide).
- ⚡️ **120Hz Incremental Streaming Markdown**: Added `StreamingMarkdownView` (`MarkdownBlock.parse(_:isStreaming:)`) with $O(1)$ committed block memoization (headings, paragraphs, blockquotes, lists, and fenced code blocks with copy actions) and a 60Hz adaptive token cadence smoother (`.streamingCadenceEnabled(_:)`).
- 📎 **Universal Multimodal `ConversationAttachment` & Off-Main-Actor Thumbnailing**: Replaced legacy `Attachment` view-conformance with `ConversationAttachment` supporting `ConversationAttachment.Payload` (`.image(PlatformImageBox)`, `.file(URL)`, and `.data(Data, contentType:filename:)`), upload lifecycle tracking (`ConversationAttachment.UploadState`: `.ready`, `.uploading(progress:)`, `.failed(error:)`), and background thumbnail decoding via `PlatformThumbnailGenerator`.
- ⌨️ **Structured Prompting & Tokenized Composer**: Added `ComposerTextBuffer` for `/` slash command (`SlashCommand`) and `@` resource mention (`ResourceMention`) detection, `ComposerToken` chips, `PromptSuggestion` bars (`.suggestionChips(_:handoff:)` with `PromptHandoffBehavior`), `ComposerModelOption` picker (`.composerModels(_:selection:)`), and `ComposerCapability` toggles (`.composerCapabilities(_:active:)`).
- 🧠 **First-Class Agentic Primitives**: Added `ThinkingTrace` & `ThinkingStateView` (collapsed by default), `ToolCall` & `ToolCallsGroupView`, `Citation` & `SourceStackView` (with `http`/`https` URL allowlist sanitization via `citation.sanitizedURL` and `url.isAllowedConversationURL`), `AgentPlan` (`AgentPlan.Step`) & `AgentPlanView`, and `ApprovalRequest` (`ApprovalRequest.Decision`) & `AgentApprovalView`.
- 🛡️ **Strongly-Typed Submissions & Inline Error Recovery**: Added `ConversationSubmission<MessageType>` and `Message.makeUserMessage(...)` to eliminate `as? DefaultMessage` downcasting, plus `MessageError` (`id`, `message`, `detail`, `isRetryable`) and `.onRetryMessage` for inline error recovery.

## v0.1.1
- 🐛 fix(MessageComposerView): align send button to bottom for long text
- 🐛 fix(ConversationView): address @State initialization error for SDK 27

## v0.1.0
- ✨ feat: Gemini-style 'Sticky Top' Scrolling & Progressive Disclosure UX
- ✨ feat(ui): refine MessageComposerView for native macOS appearance
- 🐛 fix: Add macOS platform support via Chameleon typealias pattern (#22)

## v0.0.4
- 🐛 Fix build on Xcode 16 (#21)

## v0.0.3
- 📝 Update docs
- 🐛 Hide the plus button if no attachment actions are registered (#19)
- ♻️ Simplify attachment previews by conforming `Attachment` to `View` (#20)
- ✨ Add support for attachment previews (#18)
- ⬆️ Use relative paths for dependencies (#16)
- 🤖 Add agents files (#15)
- ✨ Add attachmentPreview for MessageComposerView (#14)

## v0.0.2
- 💄 Fix “add” button size for latest iOS 26 update (#10)
- 🚀 Refactor `Message` to protocol and add robust error handling (#9)
- ✨ Add attachment actions support and UI improvements for iOS 18 (#4)
- ⬇️ Reduce minimum deployment targets to iOS/macCatalyst 17+ (#3)

## v0.0.1
- 🧹 Cleaning up for open source release (#2)
- ✨ Add demo app, support iOS 26, implement more flexible UI (#1)
- 📝 Add README
- ✨ Add support for images
