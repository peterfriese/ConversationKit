//
//  ConversationEnvironment.swift
//  ConversationKit
//
//  Canonical Accessibility Identifiers, @Entry EnvironmentValues, nominal action wrappers,
//  and Stratos Progressive Disclosure view modifiers.
//

import Foundation
import SwiftUI

// MARK: - ConversationAccessibilityID (`§3.3.4`, `[MF-2]`)

/// Canonical accessibility identifier constants used across `ConversationKit` views and
/// FlowDeck UI automation verification (`[MF-2]`, `AC-3`, `AC-4`, `AC-12`, `AC-14`, `AC-15`, `AC-20`).
public enum ConversationAccessibilityID: Sendable {
  // MARK: Static Surface Identifiers

  /// The primary timeline `ScrollView`.
  public static let timelineScrollView = "timeline.scrollView"

  /// The floating Liquid Glass scroll-to-bottom button (`F-10`, `AC-14`).
  public static let scrollToBottomButton = "timeline.scrollToBottomButton"

  /// The empty-state placeholder view shown when a conversation has no messages.
  public static let emptyConversationView = "timeline.emptyConversationView"

  /// The first-turn suggestion chips horizontal bar above the composer (`F-8`, `AC-12`).
  public static let suggestionChipsBar = "composer.suggestionChipsBar"

  /// The floating `/` slash command and `@` resource mention autocomplete popup (`F-5`, `AC-8`).
  public static let popupView = "composer.popup"

  /// The horizontal pending attachments tray inside the composer (`F-4`, `AC-6`, `AC-7`).
  public static let attachmentTray = "composer.attachmentTray"

  /// The `+` attachment menu button in the composer (`F-4`).
  public static let attachmentButton = "composer.attachmentButton"

  /// The vertical-growing prompt `TextField` in the composer.
  public static let textField = "composer.textField"

  /// The integrated AI model selector menu pill in the composer (`F-9`, `AC-13`).
  public static let modelSelector = "composer.modelSelector"

  /// The structured `/command` and `@mention` token pills bar in the composer (`F-5`, `AC-8`, `AC-9`).
  public static let tokensBar = "composer.tokensBar"

  /// The optional voice/dictation button in the composer.
  public static let dictationButton = "composer.dictationButton"

  /// The Send / cooperative Stop button in the composer (`AC-19`).
  public static let submitButton = "composer.submitButton"

  /// The focus-driven circular keyboard dismiss button (`keyboard.chevron.compact.down`, `F-11`, `AC-15`).
  public static let dismissKeyboardButton = "composer.dismissKeyboardButton"

  /// The footer disclaimer label below the composer.
  public static let disclaimerView = "composer.disclaimer"

  /// The pre-first-token assistant working indicator surface.
  public static let workingState = "working.state"

  // MARK: Dynamic Parameterized Identifiers

  /// Accessibility identifier for a turn container (`turn.<id>`).
  public static func turnContainer(_ id: String) -> String { "turn.\(id)" }

  /// Accessibility identifier for a user message bubble (`message.user.<id>`).
  public static func userMessage(_ id: String) -> String { "message.user.\(id)" }

  /// Accessibility identifier for an assistant message canvas (`message.assistant.<id>`).
  public static func assistantMessage(_ id: String) -> String { "message.assistant.\(id)" }

  /// Accessibility identifier for a `WorkingStateView` (`message.working.<id>`).
  public static func workingState(_ id: String) -> String { "message.working.\(id)" }

  /// Accessibility identifier for a `ThinkingStateView` (`message.thinking.<id>`).
  public static func thinkingState(_ id: String) -> String { "message.thinking.\(id)" }

  /// Accessibility identifier for a `ToolCallsGroupView` (`message.toolCalls.<id>`).
  public static func toolCallsGroup(_ id: String) -> String { "message.toolCalls.\(id)" }

  /// Accessibility identifier for an individual `ToolCall` row (`message.toolCall.<id>`).
  public static func toolCallRow(_ id: String) -> String { "message.toolCall.\(id)" }

  /// Accessibility identifier for a `SourceStackView` (`message.sources.<id>`).
  public static func sourceStack(_ id: String) -> String { "message.sources.\(id)" }

  /// Accessibility identifier for an individual `Citation` card (`message.citation.<id>`).
  public static func citationRow(_ id: String) -> String { "message.citation.\(id)" }

  /// Accessibility identifier for an `AgentPlanView` (`message.plan.<id>`).
  public static func agentPlan(_ id: String) -> String { "message.plan.\(id)" }

  /// Accessibility identifier for an `AgentApprovalView` (`message.approval.<id>`).
  public static func agentApproval(_ id: String) -> String { "message.approval.\(id)" }

  /// Accessibility identifier for a `MessageActionBarView` (`message.actions.<id>`).
  public static func messageActionBar(_ id: String) -> String { "message.actions.\(id)" }

  /// Accessibility identifier for an inline message error/retry banner (`message.error.<id>`).
  public static func messageErrorBanner(_ id: String) -> String { "message.error.\(id)" }

  /// Accessibility identifier for a `PromptSuggestion` chip (`composer.suggestionChip.<id>`).
  public static func suggestionChip(_ id: String) -> String { "composer.suggestionChip.\(id)" }

  /// Accessibility identifier for a `ComposerToken` chip (`composer.token.<id>`).
  public static func tokenChip(_ id: String) -> String { "composer.token.\(id)" }

  /// Accessibility identifier for a `ComposerCapability` toggle chip (`composer.capability.<id>`).
  public static func capabilityChip(_ id: String) -> String { "composer.capability.\(id)" }

  /// Accessibility identifier for a `ConversationAttachment` preview card (`composer.attachment.<id>`).
  public static func attachmentCard(_ id: String) -> String { "composer.attachment.\(id)" }

  /// Accessibility identifier for a `ComposerPopupView` autocomplete row (`composer.popupItem.<id>`).
  public static func popupItem(_ id: String) -> String { "composer.popupItem.\(id)" }
}

// MARK: - Nominal Action & Builder Wrapper Types

/// Nominal `@MainActor` action wrapper invoked when an attachment is added and needs upload processing (`F-4`, `AC-7`).
@MainActor
public struct AttachmentUploadAction: Sendable {
  private let handler:
    @MainActor @Sendable (
      ConversationAttachment,
      @escaping @MainActor @Sendable (Double) -> Void
    ) async throws -> ConversationAttachment

  /// Creates an `AttachmentUploadAction` with a progress updater callback and updated attachment return value.
  public nonisolated init(
    _ handler: @escaping @MainActor @Sendable (
      ConversationAttachment,
      @escaping @MainActor @Sendable (Double) -> Void
    ) async throws -> ConversationAttachment
  ) {
    self.handler = handler
  }

  /// Creates an `AttachmentUploadAction` with a simple async handler.
  public nonisolated init(
    _ simpleHandler: @escaping @MainActor @Sendable (ConversationAttachment) async throws -> Void
  ) {
    self.handler = { attachment, updateProgress in
      updateProgress(0.0)
      try await simpleHandler(attachment)
      updateProgress(1.0)
      var completed = attachment
      completed.uploadState = .ready
      return completed
    }
  }

  /// Executes the upload handler on `@MainActor`.
  @MainActor
  public func callAsFunction(
    _ attachment: ConversationAttachment,
    updateProgress: @escaping @MainActor @Sendable (Double) -> Void = { _ in }
  ) async throws -> ConversationAttachment {
    try await handler(attachment, updateProgress)
  }
}

/// Nominal `@MainActor` action wrapper invoked when the user taps Retry on a `.failed` attachment (`AC-7`).
@MainActor
public struct AttachmentRetryAction: Sendable {
  private let handler: @MainActor @Sendable (ConversationAttachment) async -> Void

  /// Creates an `AttachmentRetryAction`.
  public nonisolated init(
    _ handler: @escaping @MainActor @Sendable (ConversationAttachment) async -> Void
  ) {
    self.handler = handler
  }

  /// Invokes the retry handler for the failed `ConversationAttachment`.
  @MainActor
  public func callAsFunction(_ attachment: ConversationAttachment) async {
    await handler(attachment)
  }
}

/// Nominal `@MainActor` action wrapper invoked when the user taps Retry on a failed `ToolCall` (`AC-18`).
@MainActor
public struct ToolCallRetryAction: Sendable {
  private let handler: @MainActor @Sendable (ToolCall) async -> Void

  /// Creates a `ToolCallRetryAction`.
  public nonisolated init(
    _ handler: @escaping @MainActor @Sendable (ToolCall) async -> Void
  ) {
    self.handler = handler
  }

  /// Invokes the retry handler for the failed `ToolCall`.
  @MainActor
  public func callAsFunction(_ toolCall: ToolCall) async {
    await handler(toolCall)
  }
}

/// Nominal `@MainActor` action wrapper invoked when the user resolves an `ApprovalRequest` (`AC-18`).
@MainActor
public struct ApprovalDecisionAction: Sendable {
  private let handler: @MainActor @Sendable (ApprovalRequest, ApprovalRequest.Decision) async -> Void

  /// Creates an `ApprovalDecisionAction`.
  public nonisolated init(
    _ handler: @escaping @MainActor @Sendable (ApprovalRequest, ApprovalRequest.Decision) async -> Void
  ) {
    self.handler = handler
  }

  /// Invokes the decision handler for the given `ApprovalRequest` and `ApprovalRequest.Decision`.
  @MainActor
  public func callAsFunction(_ request: ApprovalRequest, _ decision: ApprovalRequest.Decision) async {
    await handler(request, decision)
  }
}

/// Nominal `@MainActor` action wrapper invoked when the user taps Regenerate on an assistant message (`AC-18`).
@MainActor
public struct RegenerateMessageAction: Sendable {
  private let handler: @MainActor @Sendable (String) async -> Void

  /// Creates a `RegenerateMessageAction`.
  public nonisolated init(
    _ handler: @escaping @MainActor @Sendable (String) async -> Void
  ) {
    self.handler = handler
  }

  /// Invokes the regenerate handler with the target `messageID`.
  @MainActor
  public func callAsFunction(_ messageID: String) async {
    await handler(messageID)
  }
}

/// Nominal `@MainActor` action wrapper invoked when the user rates an assistant message (`Thumbs Up` / `Thumbs Down`).
@MainActor
public struct MessageFeedbackAction: Sendable {
  private let handler: @MainActor @Sendable (String, MessageFeedback?) -> Void

  /// Creates a `MessageFeedbackAction`.
  public nonisolated init(
    _ handler: @escaping @MainActor @Sendable (String, MessageFeedback?) -> Void
  ) {
    self.handler = handler
  }

  /// Invokes the feedback handler with the target `messageID` and updated `MessageFeedback?`.
  @MainActor
  public func callAsFunction(_ messageID: String, _ feedback: MessageFeedback?) {
    handler(messageID, feedback)
  }
}

/// Nominal `@MainActor` action wrapper invoked when the user taps Retry on a failed message banner (`AC-18`).
@MainActor
public struct RetryMessageAction: Sendable {
  private let handler: @MainActor @Sendable (String) async -> Void

  /// Creates a `RetryMessageAction`.
  public nonisolated init(
    _ handler: @escaping @MainActor @Sendable (String) async -> Void
  ) {
    self.handler = handler
  }

  /// Invokes the retry handler with the failed `messageID`.
  @MainActor
  public func callAsFunction(_ messageID: String) async {
    await handler(messageID)
  }
}

/// Nominal `@MainActor` builder wrapper for custom menu items inside the composer's `+` attachment menu (`F-4`).
@MainActor
public struct AttachmentActionsBuilder: Sendable {
  private let builder: @MainActor @Sendable () -> AnyView

  /// Creates an `AttachmentActionsBuilder`.
  public nonisolated init<Content: View>(
    @ViewBuilder _ builder: @escaping @MainActor @Sendable () -> Content
  ) {
    self.builder = { @MainActor in
      AnyView(builder())
    }
  }

  /// Builds the type-erased menu content view on `@MainActor`.
  @MainActor
  public func callAsFunction() -> AnyView {
    builder()
  }
}

/// Nominal `@MainActor` builder wrapper for custom actions appended to `MessageActionBarView`.
@MainActor
public struct MessageActionsBuilder: Sendable {
  private let builder: @MainActor @Sendable (any Message) -> AnyView

  /// Creates a `MessageActionsBuilder` parameterized by the message instance.
  public nonisolated init<Content: View>(
    @ViewBuilder _ builder: @escaping @MainActor @Sendable (any Message) -> Content
  ) {
    self.builder = { @MainActor message in
      AnyView(builder(message))
    }
  }

  /// Creates a `MessageActionsBuilder` with a parameterless view builder.
  public nonisolated init<Content: View>(
    @ViewBuilder _ builder: @escaping @MainActor @Sendable () -> Content
  ) {
    self.builder = { @MainActor _ in
      AnyView(builder())
    }
  }

  /// Builds the custom action bar items for a given `Message`.
  @MainActor
  public func callAsFunction(_ message: any Message) -> AnyView {
    builder(message)
  }
}

/// Nominal `@MainActor` builder wrapper for the empty conversation placeholder view.
@MainActor
public struct EmptyConversationViewBuilder: Sendable {
  private let builder: @MainActor @Sendable () -> AnyView

  /// Creates an `EmptyConversationViewBuilder`.
  public nonisolated init<Content: View>(
    @ViewBuilder _ builder: @escaping @MainActor @Sendable () -> Content
  ) {
    self.builder = { @MainActor in
      AnyView(builder())
    }
  }

  /// Builds the empty conversation placeholder view on `@MainActor`.
  @MainActor
  public func callAsFunction() -> AnyView {
    builder()
  }
}

/// Nominal `@MainActor` builder wrapper for the footer disclaimer view below the composer.
@MainActor
public struct ConversationDisclaimerBuilder: Sendable {
  private let builder: @MainActor @Sendable () -> AnyView

  /// Creates a `ConversationDisclaimerBuilder` from a `LocalizedStringResource`.
  public nonisolated init(resource: LocalizedStringResource) {
    self.builder = { @MainActor in
      AnyView(
        Text(resource)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      )
    }
  }

  /// Creates a `ConversationDisclaimerBuilder` from a plain `String`.
  public nonisolated init(text: String) {
    self.builder = { @MainActor in
      AnyView(
        Text(text)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      )
    }
  }

  /// Creates a `ConversationDisclaimerBuilder` from a custom SwiftUI `@ViewBuilder`.
  public nonisolated init<Content: View>(
    @ViewBuilder _ builder: @escaping @MainActor @Sendable () -> Content
  ) {
    self.builder = { @MainActor in
      AnyView(builder())
    }
  }

  /// Builds the disclaimer view on `@MainActor`.
  @MainActor
  public func callAsFunction() -> AnyView {
    builder()
  }
}

/// Nominal `@MainActor` wrapper holding a two-way binding in `EnvironmentValues`.
@MainActor
public struct EnvironmentBindingBox<Value: Sendable>: Sendable {
  /// Snapshot of `binding.wrappedValue` captured at initialization time for $O(1)$ `Equatable` diffing.
  public let snapshot: Value
  private let getter: @MainActor @Sendable () -> Value
  private let setter: @MainActor @Sendable (Value) -> Void

  /// Wraps a SwiftUI `Binding<Value>` for safe storage inside `EnvironmentValues`.
  public init(_ binding: Binding<Value>) {
    self.snapshot = binding.wrappedValue
    self.getter = { @MainActor in binding.wrappedValue }
    self.setter = { @MainActor newValue in binding.wrappedValue = newValue }
  }

  /// Reconstructs a `Binding<Value>` isolated to `@MainActor`.
  @MainActor
  public var binding: Binding<Value> {
    Binding(
      get: { getter() },
      set: { setter($0) }
    )
  }

  /// Reads or writes the bound value on `@MainActor`.
  @MainActor
  public var wrappedValue: Value {
    get { getter() }
    nonmutating set { setter(newValue) }
  }
}

extension EnvironmentBindingBox: Equatable where Value: Equatable {
  public nonisolated static func == (
    lhs: EnvironmentBindingBox<Value>,
    rhs: EnvironmentBindingBox<Value>
  ) -> Bool {
    guard lhs.snapshot == rhs.snapshot else { return false }
    return MainActor.assumeIsolated {
      lhs.wrappedValue == rhs.wrappedValue
    }
  }
}

// MARK: - EnvironmentValues (`@Entry`)

extension EnvironmentValues {
  // MARK: Suggestion Chips (`F-8`)

  /// First-turn suggestion chips displayed above the composer when the conversation is empty (`F-8`, `AC-12`).
  @Entry public var suggestionChips: [PromptSuggestion] = []

  /// Optional override for how tapping a `PromptSuggestion` chip interacts with the composer (`F-8`).
  @Entry public var suggestionChipHandoffBehavior: PromptHandoffBehavior? = nil

  // MARK: Slash Commands & Resource Mentions (`F-5`)

  /// Available `/` slash commands shown in `ComposerPopupView` (`F-5`, `AC-8`).
  @Entry public var slashCommands: [SlashCommand] = []

  /// Static `@` resource mentions shown in `ComposerPopupView` (`F-5`, `AC-8`).
  @Entry public var resourceMentions: [ResourceMention] = []

  /// Optional async search provider for dynamic `@` resource mentions (`F-5`, `AC-8`).
  @Entry public var resourceMentionProvider: ResourceMentionProvider? = nil

  // MARK: Models, Capabilities & Tokens (`F-9`)

  /// Available AI model options for the composer's integrated Model Selector (`F-9`, `AC-13`).
  @Entry public var composerModels: [ComposerModelOption] = []

  /// Boxed binding to the currently selected `ComposerModelOption?` (`F-9`, `AC-13`).
  @Entry public var selectedComposerModelBox: EnvironmentBindingBox<ComposerModelOption?>? = nil

  /// Available capability toggles (`Think`, `Search`, `Image`, etc.) in the composer (`F-9`, `AC-13`).
  @Entry public var composerCapabilities: [ComposerCapability] = []

  /// Boxed binding to the set of active `ComposerCapability` toggles (`F-9`, `AC-13`).
  @Entry public var activeComposerCapabilitiesBox: EnvironmentBindingBox<Set<ComposerCapability>>? = nil

  /// Boxed binding to the active `[ComposerToken]` pills in the composer (`F-5`, `AC-8`, `AC-9`).
  @Entry public var composerTokensBox: EnvironmentBindingBox<[ComposerToken]>? = nil

  // MARK: Attachments (`F-4`)

  /// Optional builder for custom menu actions inside the composer's `+` attachment menu (`F-4`).
  @Entry public var attachmentActions: AttachmentActionsBuilder? = nil

  /// Indicates whether attachment controls are disabled in the composer.
  @Entry public var attachmentsDisabled: Bool = false

  /// Action invoked when a newly added attachment should be uploaded (`AC-7`).
  @Entry public var onAttachmentUpload: AttachmentUploadAction? = nil

  /// Action invoked when the user taps Retry on a `.failed` attachment in `AttachmentTrayView` (`AC-7`).
  @Entry public var onAttachmentRetry: AttachmentRetryAction? = nil

  // MARK: Agentic & Timeline Actions (`AC-18`)

  /// Action invoked when the user taps Retry on a failed `ToolCall` in `ToolCallsGroupView` (`AC-18`).
  @Entry public var onToolCallRetry: ToolCallRetryAction? = nil

  /// Action invoked when the user resolves an `ApprovalRequest` in `AgentApprovalView` (`AC-18`).
  @Entry public var onApprovalDecision: ApprovalDecisionAction? = nil

  /// Action invoked when the user taps Regenerate on an assistant message (`AC-18`).
  @Entry public var onRegenerateMessage: RegenerateMessageAction? = nil

  /// Action invoked when the user taps Thumbs Up or Thumbs Down on an assistant message.
  @Entry public var onMessageFeedback: MessageFeedbackAction? = nil

  /// Action invoked when the user taps Retry on a failed message banner (`AC-18`).
  @Entry public var onRetryMessage: RetryMessageAction? = nil

  // MARK: Chrome, Empty State, Disclaimer & Streaming Cadence

  /// Optional footer disclaimer builder displayed below the composer inside `.safeAreaBar(edge: .bottom)`.
  @Entry public var conversationDisclaimer: ConversationDisclaimerBuilder? = nil

  /// Optional custom empty-state view builder displayed when `messages` is empty.
  @Entry public var emptyConversationView: EmptyConversationViewBuilder? = nil

  /// Default label text displayed by `WorkingStateView` before the first reasoning trace,
  /// tool call, or Markdown token arrives (defaults to `"Working…"`).
  @Entry public var workingStateTitle: String = "Working…"

  /// Optional custom message action bar builder.
  @Entry public var messageActions: MessageActionsBuilder? = nil

  /// Controls whether `StreamingMarkdownView` smooths bursty token chunks via its 60Hz cadence buffer (`AC-17`).
  @Entry public var isStreamingCadenceEnabled: Bool = true

  /// Controls the haptic feedback cadence and intensity during AI response streaming.
  /// Defaults to `.punchy` out of the box.
  @Entry public var streamingHaptics: StreamingHapticsConfiguration = .punchy
}

// MARK: - Public Stratos View Modifiers

extension View {
  // MARK: 1. Suggestion Chips (`F-8`, `AC-12`)

  /// Configures first-turn suggestion chips shown above the composer before the first user message is sent (`F-8`, `AC-12`).
  ///
  /// - Parameters:
  ///   - chips: Ordered array of `PromptSuggestion` chips to display in `SuggestionChipsBar`.
  ///   - handoff: Optional global `PromptHandoffBehavior` override (`.immediateSend` or `.populateComposer`).
  public func suggestionChips(
    _ chips: [PromptSuggestion],
    handoff: PromptHandoffBehavior? = nil
  ) -> some View {
    environment(\.suggestionChips, chips)
      .environment(\.suggestionChipHandoffBehavior, handoff)
  }

  // MARK: 2. Slash Commands & Resource Mentions (`F-5`, `AC-8`)

  /// Configures `/` slash commands available in `ComposerPopupView` (`F-5`, `AC-8`).
  public func slashCommands(_ commands: [SlashCommand]) -> some View {
    environment(\.slashCommands, commands)
  }

  /// Configures static `@` resource mentions and an optional async search provider (`F-5`, `AC-8`).
  public func resourceMentions(
    _ mentions: [ResourceMention],
    provider: ResourceMentionProvider? = nil
  ) -> some View {
    environment(\.resourceMentions, mentions)
      .environment(\.resourceMentionProvider, provider)
  }

  /// Configures an async `@` resource mention search provider with cooperative task cancellation (`F-5`, `AC-8`).
  public func resourceMentions(
    provider: @escaping ResourceMentionProvider
  ) -> some View {
    environment(\.resourceMentionProvider, provider)
  }

  // MARK: 3. Composer Models, Capabilities & Tokens (`F-9`, `AC-13`)

  /// Configures the integrated Model Selector menu options and active model binding (`F-9`, `AC-13`).
  @MainActor
  public func composerModels(
    _ options: [ComposerModelOption],
    selection: Binding<ComposerModelOption?>
  ) -> some View {
    environment(\.composerModels, options)
      .environment(\.selectedComposerModelBox, EnvironmentBindingBox(selection))
  }

  /// Configures toggleable capability pills (`Think`, `Search`, `Image`, etc.) in the composer (`F-9`, `AC-13`).
  @MainActor
  public func composerCapabilities(
    _ capabilities: [ComposerCapability],
    active: Binding<Set<ComposerCapability>>
  ) -> some View {
    environment(\.composerCapabilities, capabilities)
      .environment(\.activeComposerCapabilitiesBox, EnvironmentBindingBox(active))
  }

  /// Binds the composer's active `/command` and `@mention` `ComposerToken` pills to external state (`F-5`, `AC-8`, `AC-9`).
  @MainActor
  public func composerTokens(
    _ tokens: Binding<[ComposerToken]>
  ) -> some View {
    environment(\.composerTokensBox, EnvironmentBindingBox(tokens))
  }

  // MARK: 4. Attachment Actions, Disablement & Upload/Retry Callbacks (`F-4`, `AC-7`)

  /// Adds custom menu items to the composer's `+` attachment menu alongside built-in Photos/File pickers (`F-4`).
  public func attachmentActions<MenuContent: View>(
    @ViewBuilder _ actions: @escaping @MainActor @Sendable () -> MenuContent
  ) -> some View {
    environment(\.attachmentActions, AttachmentActionsBuilder(actions))
  }

  /// Disables or enables attachment controls in the composer.
  public func disableAttachments(_ disabled: Bool = true) -> some View {
    environment(\.attachmentsDisabled, disabled)
  }

  /// Registers an upload handler invoked when a new `ConversationAttachment` is added to the composer (`AC-7`).
  public func onAttachmentUpload(
    _ action: @escaping @MainActor @Sendable (
      ConversationAttachment,
      @escaping @MainActor @Sendable (Double) -> Void
    ) async throws -> ConversationAttachment
  ) -> some View {
    environment(\.onAttachmentUpload, AttachmentUploadAction(action))
  }

  /// Convenience overload for `.onAttachmentUpload` accepting a single `ConversationAttachment` parameter.
  public func onAttachmentUpload(
    _ action: @escaping @MainActor @Sendable (ConversationAttachment) async throws -> Void
  ) -> some View {
    environment(\.onAttachmentUpload, AttachmentUploadAction(action))
  }

  /// Registers a retry handler invoked when the user taps Retry on a `.failed` attachment in `AttachmentTrayView` (`AC-7`).
  public func onAttachmentRetry(
    _ action: @escaping @MainActor @Sendable (ConversationAttachment) async -> Void
  ) -> some View {
    environment(\.onAttachmentRetry, AttachmentRetryAction(action))
  }

  // MARK: 5. Agentic Timeline & Message Callbacks (`AC-18`)

  /// Registers a retry handler invoked when the user taps Retry on a failed `ToolCall` in `ToolCallsGroupView` (`AC-18`).
  public func onToolCallRetry(
    _ action: @escaping @MainActor @Sendable (ToolCall) async -> Void
  ) -> some View {
    environment(\.onToolCallRetry, ToolCallRetryAction(action))
  }

  /// Registers a decision handler invoked when the user resolves an `ApprovalRequest` in `AgentApprovalView` (`AC-18`).
  public func onApprovalDecision(
    _ action: @escaping @MainActor @Sendable (ApprovalRequest, ApprovalRequest.Decision) async -> Void
  ) -> some View {
    environment(\.onApprovalDecision, ApprovalDecisionAction(action))
  }

  /// Registers a handler invoked when the user taps Regenerate on an assistant message (`AC-18`).
  public func onRegenerateMessage(
    _ action: @escaping @MainActor @Sendable (String) async -> Void
  ) -> some View {
    environment(\.onRegenerateMessage, RegenerateMessageAction(action))
  }

  /// Registers a handler invoked when the user rates an assistant message (`Thumbs Up` / `Thumbs Down`).
  public func onMessageFeedback(
    _ action: @escaping @MainActor @Sendable (String, MessageFeedback?) -> Void
  ) -> some View {
    environment(\.onMessageFeedback, MessageFeedbackAction(action))
  }

  /// Registers a handler invoked when the user taps Retry on a failed message banner (`AC-18`).
  public func onRetryMessage(
    _ action: @escaping @MainActor @Sendable (String) async -> Void
  ) -> some View {
    environment(\.onRetryMessage, RetryMessageAction(action))
  }

  // MARK: 6. Disclaimer, Empty State, Message Actions & Streaming Cadence

  /// Displays a subtle localized footer disclaimer below the composer inside `.safeAreaBar(edge: .bottom)`.
  public func conversationDisclaimer(_ text: LocalizedStringResource?) -> some View {
    environment(
      \.conversationDisclaimer,
      text.map { ConversationDisclaimerBuilder(resource: $0) }
    )
  }

  /// Displays a subtle string footer disclaimer below the composer inside `.safeAreaBar(edge: .bottom)`.
  @_disfavoredOverload
  public func conversationDisclaimer(_ text: String?) -> some View {
    environment(
      \.conversationDisclaimer,
      text.map { ConversationDisclaimerBuilder(text: $0) }
    )
  }

  /// Displays a custom footer disclaimer view below the composer inside `.safeAreaBar(edge: .bottom)`.
  public func conversationDisclaimer<DisclaimerContent: View>(
    @ViewBuilder _ content: @escaping @MainActor @Sendable () -> DisclaimerContent
  ) -> some View {
    environment(\.conversationDisclaimer, ConversationDisclaimerBuilder(content))
  }

  /// Configures a custom placeholder view displayed when the conversation timeline has no messages.
  public func emptyConversationView<EmptyContent: View>(
    @ViewBuilder _ content: @escaping @MainActor @Sendable () -> EmptyContent
  ) -> some View {
    environment(\.emptyConversationView, EmptyConversationViewBuilder(content))
  }

  /// Customizes the default label text displayed by `WorkingStateView` before the first reasoning trace,
  /// tool call, or Markdown token arrives (defaults to `"Working…"`).
  public func workingStateTitle(_ title: LocalizedStringResource) -> some View {
    environment(\.workingStateTitle, String(localized: title))
  }

  /// Customizes the default label text displayed by `WorkingStateView` before the first reasoning trace,
  /// tool call, or Markdown token arrives (defaults to `"Working…"`).
  @_disfavoredOverload
  public func workingStateTitle(_ title: String) -> some View {
    environment(\.workingStateTitle, title)
  }

  /// Configures custom actions displayed alongside each message's action bar, receiving the message instance.
  public func messageActions<Actions: View>(
    @ViewBuilder _ actions: @escaping @MainActor @Sendable (any Message) -> Actions
  ) -> some View {
    environment(\.messageActions, MessageActionsBuilder(actions))
  }

  /// Configures custom actions displayed alongside each message's action bar.
  public func messageActions<Actions: View>(
    @ViewBuilder _ actions: @escaping @MainActor @Sendable () -> Actions
  ) -> some View {
    environment(\.messageActions, MessageActionsBuilder(actions))
  }

  /// Enables or disables the 60Hz adaptive token cadence smoother in `StreamingMarkdownView` (`AC-17`).
  public func streamingCadenceEnabled(_ enabled: Bool = true) -> some View {
    environment(\.isStreamingCadenceEnabled, enabled)
  }

  /// Configures the haptic feedback cadence and intensity during AI response streaming.
  ///
  /// By default, `ConversationView` uses `.punchy` streaming haptics. Pass `.subtle` for
  /// softer taps, `.typewriter` for crisp word/clause feedback, `.milestonesOnly` for lifecycle
  /// transitions only, or `.disabled` to silence streaming haptics.
  ///
  /// - Parameter configuration: The `StreamingHapticsConfiguration` preset or custom configuration.
  public func streamingHaptics(_ configuration: StreamingHapticsConfiguration) -> some View {
    environment(\.streamingHaptics, configuration)
  }

  /// Enables or disables streaming haptic feedback using the `.punchy` preset when enabled.
  ///
  /// - Parameter enabled: Whether streaming haptics are enabled (`true` by default).
  public func streamingHapticsEnabled(_ enabled: Bool = true) -> some View {
    environment(\.streamingHaptics, enabled ? .punchy : .disabled)
  }
}
