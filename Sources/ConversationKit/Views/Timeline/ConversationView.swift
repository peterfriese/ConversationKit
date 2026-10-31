//
// ConversationView.swift
//
// Created by Peter Friese on 20.02.24.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI
import MarkdownUI

public struct OnSendMessageAction {
  private let handler: @MainActor (any Message) async -> Void

  public init(handler: @escaping @MainActor (any Message) async -> Void) {
    self.handler = handler
  }

  @MainActor
  public func callAsFunction(_ message: any Message) async {
    await handler(message)
  }
}

extension EnvironmentValues {
  @Entry var onSendMessageAction: OnSendMessageAction = OnSendMessageAction(handler: { _ in })
}

public extension View {
  /// Defines the action to be executed when the user sends a new message.
  ///
  /// This action is executed asynchronously in a background task managed by `ConversationView`.
  /// While this task runs, the composer's "Send" button becomes a "Stop" button.
  ///
  /// - Important: `ConversationView` utilizes an Optimistic UI state to ensure flawless layout
  ///   anchor physics when the keyboard dismisses. It instantly displays the user's message locally.
  ///   When this action fires, you **must** append the provided `message` instance to your array to
  ///   permanently store it. The exact `id` of the `message` parameter must be preserved; if you copy
  ///   the content into a different model with a new UUID, the internal deduplication will fail and
  ///   the message will briefly appear twice.
  @MainActor
  func onSendMessage(_ action: @escaping @MainActor (_ message: any Message) async -> Void) -> some View {
    environment(\.onSendMessageAction, OnSendMessageAction(handler: action))
  }
}

public struct ConversationView<Content, MessageType: Message, AttachmentType: Attachment & View>: View where Content: View {
  @Binding var messages: [MessageType]
  @Binding var attachments: [AttachmentType]

  enum ConversationScrollID: Hashable {
    case message(MessageType.ID)
    case bottomMarker
  }

  private struct ScrollSyncTrigger<M: Equatable>: Equatable {
    let count: Int
    let lastMessage: M?
  }

  private func scrollSyncTrigger(for list: [MessageType]) -> ScrollSyncTrigger<MessageType> {
    ScrollSyncTrigger(count: list.count, lastMessage: list.last)
  }

  // Custom scroll tracking
  @State private var isAutoScrollingTop: Bool = false
  @State private var autoScrollTargetID: MessageType.ID?

  /// Stable identity used for Equatable action wrappers so `EnvironmentValues` never invalidates the ScrollView on re-renders.
  @State private var coordinatorID = UUID()

  /// The task currently executing an async turn (`onSendMessage`, `onRegenerateMessage`, `onRetryMessage`, or `onRetryToolCall`).
  @State private var sendingTask: Task<Void, Never>?

  /// Unique token guarding `sendingTask` and `optimisticUserMessage` against late cleanup from a cancelled task (`[MF-2]`).
  @State private var activeTurnToken: UUID?

  /// A temporary copy of the user's message used to instantly update the UI.
  /// SwiftUI's `.scrollPosition` requires the layout to update synchronously with keyboard dismissal
  /// for perfect "Sticky Top" physics. However, the SDK does not own the `messages` array, meaning
  /// we must wait for the developer to append the message via the async `onSendMessage` action, which delays layout.
  /// To fix this, we hold the message here optimistically to trick the layout engine into correct physics,
  /// then seamlessly swap it out once the developer's data catches up.
  @State private var optimisticUserMessage: MessageType?

  /// Strongly-typed submission handler configured directly on `ConversationView` (`[MF-1]`).
  private var typedOnSendMessageAction: (@MainActor (MessageSubmission<MessageType, AttachmentType>) async -> Void)?

  /// A dynamically computed list combining the developer's source of truth with our optimistic state.
  private var displayedMessages: [MessageType] {
    if let opt = optimisticUserMessage {
      // O(1) fast path: The developer almost certainly appended the message to the end of the array.
      if let last = messages.last, last.id == opt.id {
        return messages
      }
      // O(N) fallback path just in case the array is sorted differently.
      if !messages.contains(where: { $0.id == opt.id }) {
        return messages + [opt]
      }
    }
    return messages
  }

  @State private var message: String
  @State private var fallbackSelectedModelID: String?
  @State private var fallbackActiveCapabilities: Set<ComposerCapability> = []
  @State private var fallbackActiveTokens: [ComposerTokenChip] = []
  @FocusState private var focusedField: FocusedField?
  enum FocusedField {
    case message
  }

  @Environment(\.onSendMessageAction) private var onSendMessageAction
  @Environment(\.messageActions) private var messageActions
  @Environment(\.conversationDisclaimer) private var conversationDisclaimer
  @Environment(\.welcomeConfiguration) private var welcomeConfiguration
  @Environment(\.showsStandardMessageActions) private var showsStandardMessageActions
  @Environment(\.onRegenerateMessageAction) private var onRegenerateMessageAction
  @Environment(\.onRateMessageAction) private var onRateMessageAction
  @Environment(\.onRetryMessageAction) private var onRetryMessageAction
  @Environment(\.onRetryToolCallAction) private var onRetryToolCallAction
  @Environment(\.activeComposerCapabilities) private var activeComposerCapabilities
  @Environment(\.availableComposerCapabilities) private var availableComposerCapabilities
  @Environment(\.activeComposerTokens) private var activeComposerTokens
  @Environment(\.selectedComposerModelID) private var selectedComposerModelID
  @Environment(\.composerModels) private var composerModels

  private let content: (MessageType) -> Content

  public init(
    messages: Binding<[MessageType]>,
    attachments: Binding<[AttachmentType]>,
    userPrompt: String? = "",
    @ViewBuilder content: @escaping (MessageType) -> Content
  ) {
    self.content = content
    self._messages = messages
    self._attachments = attachments
    self.message = userPrompt ?? ""
    self.typedOnSendMessageAction = nil
  }

  private var shouldShowStandardActionBar: Bool {
    showsStandardMessageActions || onRegenerateMessageAction != nil || onRateMessageAction != nil
  }

  private var regenerateCallback: (@MainActor (any Message) -> Void)? {
    guard let onRegenerateMessageAction else { return nil }
    return { targetMessage in
      startTurnTask {
        await onRegenerateMessageAction(targetMessage)
      }
    }
  }

  public var body: some View {
    let currentMessages = displayedMessages

    ZStack(alignment: .bottom) {
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(spacing: 16) {
            if currentMessages.isEmpty, let welcomeConfig = welcomeConfiguration {
              ConversationWelcomeView(configuration: welcomeConfig) { suggestion in
                switch welcomeConfig.handoff {
                case .immediateSend:
                  message = suggestion.prompt
                  submit()
                case .populateComposer:
                  message = suggestion.prompt
                  focusedField = .message
                }
              }
            }

            ForEach(currentMessages) { message in
              VStack(alignment: .leading, spacing: 8) {
                content(message)

                // Message Actions: Custom override takes precedence; otherwise standard action bar when opted in ([SF-3])
                if message.participant == .other {
                  if let actions = messageActions {
                    actions(message)
                  } else if !message.isStreaming && message.error == nil && shouldShowStandardActionBar {
                    MessageActionBarView(
                      message: message,
                      onRegenerate: regenerateCallback
                    )
                  }
                }
              }
              .padding(.horizontal)
              .id(ConversationScrollID.message(message.id))
              .accessibilityIdentifier("message_row")
            }

            // Disclaimer View
            if let lastMessage = currentMessages.last,
               lastMessage.participant == .other,
               let disclaimer = conversationDisclaimer {
              disclaimer
                .padding(.horizontal)
                .padding(.top, 8)
                .accessibilityIdentifier("conversation_disclaimer")
            }

            Spacer()
              .frame(height: (!composerModels.isEmpty || !availableComposerCapabilities.isEmpty) ? 140 : 100)
              .id(ConversationScrollID.bottomMarker)
          }
          .scrollTargetLayout()
          .accessibilityIdentifier("conversation_list")
        }
        .accessibilityIdentifier("conversation_scroll_view")
        .scrollTargetBehavior(.viewAligned)
        .scrollBounceBehavior(.always)
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
          DragGesture().onChanged { _ in
            // Stop sticky top anchoring if the user touches/scrolls the view
            isAutoScrollingTop = false
            autoScrollTargetID = nil
          }
        )
        .onChange(of: scrollSyncTrigger(for: currentMessages)) { oldValue, newValue in
          if newValue.count == 0 {
            isAutoScrollingTop = false
            autoScrollTargetID = nil
            return
          }

          // 1. Detect if a single brand new message was submitted by the user
          let wasSingleUserMessageAppended = (newValue.count == oldValue.count + 1) && (newValue.lastMessage?.participant == .user)

          if wasSingleUserMessageAppended, let lastID = newValue.lastMessage?.id {
            isAutoScrollingTop = true
            autoScrollTargetID = lastID
            withAnimation(.easeOut(duration: 0.25)) {
              proxy.scrollTo(ConversationScrollID.message(lastID), anchor: .top)
            }
          }
          // 2. If we are currently anchored, and new tokens are arriving on the same thread
          else if isAutoScrollingTop, let targetID = autoScrollTargetID {
            proxy.scrollTo(ConversationScrollID.message(targetID), anchor: .top)

            if sendingTask == nil || (newValue.lastMessage?.participant == .other && newValue.lastMessage?.isStreaming == false) {
              isAutoScrollingTop = false
              autoScrollTargetID = nil
            }
          }
        }
        .environment(
          \.onRegenerateMessageAction,
          onRegenerateMessageAction.map { action in
            OnRegenerateMessageAction(id: coordinatorID) { targetMessage in
              startTurnTask {
                await action(targetMessage)
              }
            }
          }
        )
        .environment(
          \.onRetryMessageAction,
          onRetryMessageAction.map { action in
            OnRetryMessageAction(id: coordinatorID) { targetMessage in
              startTurnTask {
                await action(targetMessage)
              }
            }
          }
        )
        .environment(
          \.onRetryToolCallAction,
          onRetryToolCallAction.map { action in
            OnRetryToolCallAction(id: coordinatorID) { toolCall in
              startTurnTask {
                await action(toolCall)
              }
            }
          }
        )
      }

      MessageComposerView(message: $message, attachments: $attachments)
        .padding(.bottom, 10) // keep distance from keyboard
        .focused($focusedField, equals: .message)
        .isGenerating(sendingTask != nil)
        .environment(\.selectedComposerModelID, selectedComposerModelID ?? $fallbackSelectedModelID)
        .environment(\.activeComposerCapabilities, activeComposerCapabilities ?? $fallbackActiveCapabilities)
        .environment(\.activeComposerTokens, activeComposerTokens ?? $fallbackActiveTokens)
        .onStopAction {
          sendingTask?.cancel()
        }
        .onSubmitAction {
          submit()
        }
    }
  }

  /// Token-guarded turn coordinator (`[MF-2]`).
  /// Ensures a cancelled turn's `defer` block never clears a newly started turn's `sendingTask` or `optimisticUserMessage`.
  @MainActor
  func startTurnTask(_ operation: @escaping @MainActor () async -> Void) {
    sendingTask?.cancel()
    let token = UUID()
    activeTurnToken = token

    sendingTask = Task { @MainActor in
      defer {
        if self.activeTurnToken == token {
          self.sendingTask = nil
          self.optimisticUserMessage = nil
          self.activeTurnToken = nil
        }
      }
      await operation()
    }
  }

  @MainActor
  func submit() {
    let userMessage = MessageType(content: message, imageURL: nil, participant: .user)
    let resolvedCapabilities = activeComposerCapabilities?.wrappedValue ?? fallbackActiveCapabilities
    let resolvedTokens = activeComposerTokens?.wrappedValue ?? fallbackActiveTokens
    let resolvedModelID = selectedComposerModelID?.wrappedValue ?? fallbackSelectedModelID ?? composerModels.first?.id

    let submission = MessageSubmission(
      message: userMessage,
      attachments: attachments,
      activeCapabilities: resolvedCapabilities,
      tokens: resolvedTokens,
      selectedModelID: resolvedModelID
    )

    // Set the optimistic message synchronously so it immediately appears in the layout
    // for perfect "Sticky Top" scrolling physics when the keyboard dismisses.
    // It will be seamlessly replaced by the developer's actual message update since
    // `displayedMessages` deduplicates by ID.
    optimisticUserMessage = userMessage

    withAnimation {
      message = ""
      if let activeComposerTokens {
        activeComposerTokens.wrappedValue.removeAll()
      } else {
        fallbackActiveTokens.removeAll()
      }
      focusedField = nil // Dismiss keyboard
    }

    let typedHandler = typedOnSendMessageAction
    let fallbackHandler = onSendMessageAction

    startTurnTask {
      if let typedHandler {
        await typedHandler(submission)
      } else {
        await fallbackHandler(userMessage)
      }
    }
  }
}

// MARK: - Strongly-Typed onSendMessage Overloads ([MF-1])

extension ConversationView {
  /// Defines a strongly-typed action executed when the user sends a new message, eliminating `as? DefaultMessage` downcasting.
  public func onSendMessage(
    _ action: @escaping @MainActor (MessageType) async -> Void
  ) -> Self {
    var copy = self
    copy.typedOnSendMessageAction = { submission in
      await action(submission.message)
    }
    return copy
  }

  /// Defines a strongly-typed action receiving the full `MessageSubmission` context (message, attachments, capabilities, tokens, and model ID).
  public func onSendMessage(
    _ action: @escaping @MainActor (MessageSubmission<MessageType, AttachmentType>) async -> Void
  ) -> Self {
    var copy = self
    copy.typedOnSendMessageAction = action
    return copy
  }
}

// MARK: - Convenience Initializers

extension ConversationView where Content == MessageView {
  public init(
    messages: Binding<[MessageType]>,
    attachments: Binding<[AttachmentType]>,
    userPrompt: String? = ""
  ) {
    self.init(
      messages: messages,
      attachments: attachments,
      userPrompt: userPrompt,
      content: { message in
        MessageView(message)
      }
    )
  }
}

extension ConversationView where AttachmentType == EmptyAttachment {
  public init(messages: Binding<[MessageType]>, userPrompt: String? = "") where Content == MessageView {
    self.init(
      messages: messages,
      attachments: .constant([]),
      userPrompt: userPrompt,
      content: { message in
        MessageView(message)
      }
    )
  }

  public init(
    messages: Binding<[MessageType]>,
    userPrompt: String? = "",
    @ViewBuilder content: @escaping (MessageType) -> Content
  ) {
    self.init(
      messages: messages,
      attachments: .constant([]),
      userPrompt: userPrompt,
      content: content
    )
  }
}
