//
// ConversationEnvironment.swift
// ConversationKit
//
// Created by Peter Friese on 08.04.26.
//

import SwiftUI

// MARK: - Message Actions

public struct MessageActions {
  private let handler: @MainActor (any Message) -> AnyView

  public init(handler: @escaping @MainActor (any Message) -> AnyView) {
    self.handler = handler
  }

  @MainActor
  public func callAsFunction(_ message: any Message) -> AnyView {
    handler(message)
  }
}

public extension EnvironmentValues {
  @Entry var messageActions: MessageActions? = nil
}

public extension View {
  /// Defines a custom view to be displayed below AI messages (e.g. thumbs up/down, copy, regenerate).
  /// - Parameter actions: A closure that takes a `Message` and returns a View.
  @MainActor
  func messageActions<V: View>(@ViewBuilder actions: @escaping @MainActor (any Message) -> V) -> some View {
    environment(\.messageActions, MessageActions(handler: { message in AnyView(actions(message)) }))
  }
}

// MARK: - Conversation Disclaimer

public extension EnvironmentValues {
  @Entry var conversationDisclaimer: AnyView? = nil
}

public extension View {
  /// Defines a custom disclaimer view to be displayed at the bottom of the conversation thread,
  /// but only if the most recent message is from the AI (`.other`).
  func conversationDisclaimer<V: View>(@ViewBuilder disclaimer: @escaping () -> V) -> some View {
    environment(\.conversationDisclaimer, AnyView(disclaimer()))
  }
}

// MARK: - Welcome Configuration

public extension EnvironmentValues {
  @Entry var welcomeConfiguration: WelcomeConfiguration? = nil
}

public extension View {
  /// Configures the empty-state welcome screen (`ConversationWelcomeView`) displayed when the conversation has no messages.
  func welcomeConfiguration(_ configuration: WelcomeConfiguration?) -> some View {
    environment(\.welcomeConfiguration, configuration)
  }

  /// Convenience modifier to configure starter prompt suggestions on the empty-state welcome screen.
  func starterPrompts(
    _ suggestions: [PromptSuggestion],
    userName: String? = nil,
    subtitle: String? = nil,
    visibleCount: Int = 4,
    allowsShuffle: Bool = true,
    handoff: PromptHandoffBehavior = .immediateSend
  ) -> some View {
    environment(
      \.welcomeConfiguration,
      WelcomeConfiguration(
        userName: userName,
        subtitle: subtitle,
        suggestions: suggestions,
        visibleCount: visibleCount,
        allowsShuffle: allowsShuffle,
        handoff: handoff
      )
    )
  }
}

// MARK: - Turnkey Message Action Handlers

public struct OnRegenerateMessageAction: Equatable {
  public let id: UUID
  private let handler: @MainActor (any Message) async -> Void

  public init(id: UUID = UUID(), handler: @escaping @MainActor (any Message) async -> Void) {
    self.id = id
    self.handler = handler
  }

  public static func == (lhs: OnRegenerateMessageAction, rhs: OnRegenerateMessageAction) -> Bool {
    lhs.id == rhs.id
  }

  @MainActor
  public func callAsFunction(_ message: any Message) async {
    await handler(message)
  }
}

public struct OnRateMessageAction: Equatable {
  public let id: UUID
  private let handler: @MainActor (any Message, MessageRating?) -> Void

  public init(id: UUID = UUID(), handler: @escaping @MainActor (any Message, MessageRating?) -> Void) {
    self.id = id
    self.handler = handler
  }

  public static func == (lhs: OnRateMessageAction, rhs: OnRateMessageAction) -> Bool {
    lhs.id == rhs.id
  }

  @MainActor
  public func callAsFunction(_ message: any Message, _ rating: MessageRating?) {
    handler(message, rating)
  }
}

public struct OnRetryMessageAction: Equatable {
  public let id: UUID
  private let handler: @MainActor (any Message) async -> Void

  public init(id: UUID = UUID(), handler: @escaping @MainActor (any Message) async -> Void) {
    self.id = id
    self.handler = handler
  }

  public static func == (lhs: OnRetryMessageAction, rhs: OnRetryMessageAction) -> Bool {
    lhs.id == rhs.id
  }

  @MainActor
  public func callAsFunction(_ message: any Message) async {
    await handler(message)
  }
}

public struct OnRetryToolCallAction: Equatable {
  public let id: UUID
  private let handler: @MainActor (ToolCall) async -> Void

  public init(id: UUID = UUID(), handler: @escaping @MainActor (ToolCall) async -> Void) {
    self.id = id
    self.handler = handler
  }

  public static func == (lhs: OnRetryToolCallAction, rhs: OnRetryToolCallAction) -> Bool {
    lhs.id == rhs.id
  }

  @MainActor
  public func callAsFunction(_ toolCall: ToolCall) async {
    await handler(toolCall)
  }
}

public struct OnAgentApprovalAction: Equatable {
  public let id: UUID
  private let handler: @MainActor (ApprovalRequest, ApprovalRequest.Decision) async -> Void

  public init(
    id: UUID = UUID(),
    handler: @escaping @MainActor (ApprovalRequest, ApprovalRequest.Decision) async -> Void
  ) {
    self.id = id
    self.handler = handler
  }

  public static func == (lhs: OnAgentApprovalAction, rhs: OnAgentApprovalAction) -> Bool {
    lhs.id == rhs.id
  }

  @MainActor
  public func callAsFunction(_ request: ApprovalRequest, _ decision: ApprovalRequest.Decision) async {
    await handler(request, decision)
  }
}

public extension EnvironmentValues {
  @Entry var onRegenerateMessageAction: OnRegenerateMessageAction? = nil
  @Entry var onRateMessageAction: OnRateMessageAction? = nil
  @Entry var onRetryMessageAction: OnRetryMessageAction? = nil
  @Entry var onRetryToolCallAction: OnRetryToolCallAction? = nil
  @Entry var onAgentApprovalAction: OnAgentApprovalAction? = nil
  @Entry var showsStandardMessageActions: Bool = false

  /// Alias for `onAgentApprovalAction` supporting `onAgentApprovalDecision` naming.
  var onAgentApprovalDecision: OnAgentApprovalAction? {
    get { onAgentApprovalAction }
    set { onAgentApprovalAction = newValue }
  }
}

public extension View {
  /// Opts into displaying the built-in `MessageActionBarView` below completed `.other` messages.
  func standardMessageActions(_ enabled: Bool = true) -> some View {
    environment(\.showsStandardMessageActions, enabled)
  }

  /// Registers a callback invoked when the user taps the Regenerate action on a completed AI message.
  @MainActor
  func onRegenerateMessage(_ action: @escaping @MainActor (any Message) async -> Void) -> some View {
    environment(\.onRegenerateMessageAction, OnRegenerateMessageAction(handler: action))
  }

  /// Registers a callback invoked when the user rates an AI message with thumbs up or thumbs down.
  @MainActor
  func onRateMessage(_ action: @escaping @MainActor (any Message, MessageRating?) -> Void) -> some View {
    environment(\.onRateMessageAction, OnRateMessageAction(handler: action))
  }

  /// Registers a callback invoked when the user taps Retry on a failed message turn.
  @MainActor
  func onRetryMessage(_ action: @escaping @MainActor (any Message) async -> Void) -> some View {
    environment(\.onRetryMessageAction, OnRetryMessageAction(handler: action))
  }

  /// Registers a callback invoked when the user taps Retry on a failed tool call row.
  @MainActor
  func onRetryToolCall(_ action: @escaping @MainActor (ToolCall) async -> Void) -> some View {
    environment(\.onRetryToolCallAction, OnRetryToolCallAction(handler: action))
  }

  /// Registers a callback invoked when the user resolves a human-in-the-loop `ApprovalRequest`.
  @MainActor
  func onAgentApproval(
    _ action: @escaping @MainActor (ApprovalRequest, ApprovalRequest.Decision) async -> Void
  ) -> some View {
    environment(\.onAgentApprovalAction, OnAgentApprovalAction(handler: action))
  }
}

// MARK: - Composer Environment Configuration

public extension EnvironmentValues {
  @Entry var composerModels: [ComposerModelOption] = []
  @Entry var selectedComposerModelID: Binding<String?>? = nil
  @Entry var availableComposerCapabilities: [ComposerCapability] = []
  @Entry var activeComposerCapabilities: Binding<Set<ComposerCapability>>? = nil
  @Entry var slashCommands: [ComposerTokenChip] = []
  @Entry var mentionSuggestions: [ComposerTokenChip] = []
  @Entry var activeComposerTokens: Binding<[ComposerTokenChip]>? = nil
}

public extension View {
  /// Configures selectable AI models in `MessageComposerView`.
  func composerModels(
    _ models: [ComposerModelOption],
    selection: Binding<String?>? = nil
  ) -> some View {
    environment(\.composerModels, models)
      .environment(\.selectedComposerModelID, selection)
  }

  /// Configures selectable AI models in `MessageComposerView` with a non-optional selection binding.
  func composerModels(
    _ models: [ComposerModelOption],
    selection: Binding<String>
  ) -> some View {
    let optionalBinding = Binding<String?>(
      get: { selection.wrappedValue },
      set: { newValue in
        if let newValue {
          selection.wrappedValue = newValue
        }
      }
    )
    return environment(\.composerModels, models)
      .environment(\.selectedComposerModelID, optionalBinding)
  }

  /// Configures toggleable capability chips (`Think`, `Search`, `Image`, or custom) in `MessageComposerView`.
  func composerCapabilities(
    _ capabilities: [ComposerCapability],
    active: Binding<Set<ComposerCapability>>? = nil
  ) -> some View {
    environment(\.availableComposerCapabilities, capabilities)
      .environment(\.activeComposerCapabilities, active)
  }

  /// Configures `/` slash command autocomplete suggestions in `MessageComposerView`.
  func slashCommands(
    _ commands: [ComposerTokenChip],
    activeTokens: Binding<[ComposerTokenChip]>? = nil
  ) -> some View {
    environment(\.slashCommands, commands)
      .environment(\.activeComposerTokens, activeTokens)
  }

  /// Configures `@` mention autocomplete suggestions in `MessageComposerView`.
  func mentionSuggestions(
    _ suggestions: [ComposerTokenChip],
    activeTokens: Binding<[ComposerTokenChip]>? = nil
  ) -> some View {
    environment(\.mentionSuggestions, suggestions)
      .environment(\.activeComposerTokens, activeTokens)
  }

  /// Binds the active structured token chips (`/` slash commands and `@` mentions) in `MessageComposerView`.
  func composerTokens(_ tokens: Binding<[ComposerTokenChip]>) -> some View {
    environment(\.activeComposerTokens, tokens)
  }
}
