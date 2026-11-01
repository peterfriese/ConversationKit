//
//  ConversationView.swift
//  ConversationKit
//
//  Primary conversational AI timeline & composer host with Top-Floating Turn Layout,
//  Unoccluded Active Turn Viewport Runway, Zero-Jitter Streaming Physics, Optimistic UI
//  deduplication, and .safeAreaBar(edge: .bottom) Liquid Glass chrome (F-1–F-11, AC-3–AC-20, [MF-2], [MF-3]).
//

import Foundation
import SwiftUI

// MARK: - ScrollGeometrySnapshot

/// Lightweight value snapshot extracted inside `.onScrollGeometryChange` so scroll state updates
/// only fire when geometry metrics meaningfully change.
private struct ScrollGeometrySnapshot: Equatable, Sendable {
  let unoccludedCandidateHeight: CGFloat
  let distanceFromBottom: CGFloat
}

// MARK: - ConversationView (`F-1`–`F-11`, `AC-3`–`AC-20`, `[MF-2]`, `[MF-3]`)

/// The primary entry point for `ConversationKit` v2, combining a turn-grouped scrollable timeline
/// with a `.safeAreaBar(edge: .bottom)` Liquid Glass message composer (`[MF-2]`, `[MF-3]`).
///
/// ### Top-Floating Turn Physics & Zero-Jitter Streaming (`F-1`, `F-2`, `AC-3`, `AC-4`, `[MF-3]`)
/// 1. **Optimistic Turn Grouping:** Merges `messages` with `optimisticUserMessage` (deduplicated in $O(1)$ by `id`)
///    and partitions them into `ConversationTurn.group(displayedMessages)`.
/// 2. **Unoccluded Active Turn Viewport Runway (`[MF-3]`):** The active (last) turn reserves
///    `.frame(minHeight: activeTurnMinHeight, alignment: .top)` where `activeTurnMinHeight` is locked to
///    `max(lockedUnoccludedHeight, 320)`. Even if the user taps Send while the software keyboard is open,
///    `activeTurnMinHeight` locks to the visible runway excluding top and bottom safe area insets and never shrinks during
///    keyboard dismissal.
/// 3. **Single-Shot Top Scroll on Submission (`AC-3`, `AC-4`):** `proxy.scrollTo(newTurnID, anchor: .top)`
///    is invoked **only once** when a user submits a turn—never during AI token streaming—guaranteeing
///    $\Delta Y = 0\text{pt}$ on the user's message bubble even as the AI response overflows past `150%` of
///    the viewport height.
///
/// ### Usage
/// ```swift
/// // Layer 1 (Troposphere): Zero-config default MessageView + internal attachments state
/// ConversationView(messages: $messages)
///   .onSendMessage { submission in
///     messages.append(submission.message)
///     await streamResponse(for: submission)
///   }
///
/// // Layer 2 (Stratosphere): External attachments, suggestion chips, models & styles
/// ConversationView(messages: $messages, attachments: $attachments)
///   .suggestionChips(suggestions)
///   .composerModels(models, selection: $selectedModel)
///   .messageComposerStyle(.cardGlass)
///   .thinkingStateStyle(.collapsibleHeader)
///   .userMessageBubbleStyle(.tailedBubble)
/// ```
@MainActor
public struct ConversationView<MessageType: Message, Content: View>: View {
  // MARK: - Bindings & Stored Properties

  @Binding private var messages: [MessageType]
  private var externalAttachments: Binding<[ConversationAttachment]>?
  private let initialUserPrompt: String
  private let content: (MessageType) -> Content
  private var onSendSubmissionAction: (@MainActor (ConversationSubmission<MessageType>) async -> Void)?

  // MARK: - Environment

  @Environment(\.suggestionChips) private var suggestionChips
  @Environment(\.suggestionChipHandoffBehavior) private var suggestionChipHandoff
  @Environment(\.composerModels) private var composerModels
  @Environment(\.selectedComposerModelBox) private var selectedComposerModelBox
  @Environment(\.activeComposerCapabilitiesBox) private var activeComposerCapabilitiesBox
  @Environment(\.composerTokensBox) private var environmentTokensBox
  @Environment(\.conversationDisclaimer) private var conversationDisclaimer
  @Environment(\.emptyConversationView) private var emptyConversationView
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  // MARK: - Internal State

  @State private var internalAttachments: [ConversationAttachment] = []
  @State private var internalTokens: [ComposerToken] = []
  @State private var draftText: String
  @State private var hasSeededInitialPrompt: Bool = false
  @FocusState private var isComposerFocused: Bool

  // Optimistic UI & Turn Coordinator State (`[MF-3]`)
  @State private var optimisticUserMessage: MessageType?
  @State private var hasSentFirstMessage: Bool = false
  @State private var activeTurnToken: UUID?
  @State private var sendingTask: Task<Void, Never>?
  @State private var pendingScrollTargetTurnID: String?
  @State private var keyboardFocusTask: Task<Void, Never>?

  // Scroll & Unoccluded Viewport Runway State (`[MF-3]`, `AC-14`)
  @State private var lockedUnoccludedHeight: CGFloat = 0
  @State private var currentVisibleHeight: CGFloat = 0
  @State private var isScrolledAwayFromBottom: Bool = false

  private static var bottomAnchorID: String { "timeline.bottomAnchor" }

  // MARK: - Initializers

  /// Creates a `ConversationView` with custom row `content`.
  ///
  /// - Parameters:
  ///   - messages: Two-way binding to the conversation's ordered `[MessageType]` array.
  ///   - attachments: Optional two-way binding to pending `[ConversationAttachment]` items. When `nil`,
  ///     `ConversationView` manages an internal `@State` attachment array automatically (`[MF-2]`).
  ///   - userPrompt: Optional initial draft text seeded into the composer on first appearance.
  ///   - content: View builder rendering each `MessageType` in the timeline.
  public init(
    messages: Binding<[MessageType]>,
    attachments: Binding<[ConversationAttachment]>? = nil,
    userPrompt: String = "",
    @ViewBuilder content: @escaping (MessageType) -> Content
  ) {
    self._messages = messages
    self.externalAttachments = attachments
    self.initialUserPrompt = userPrompt
    self.content = content
    self.onSendSubmissionAction = nil
    self._draftText = State(initialValue: ComposerTextBuffer.cleanText(userPrompt))
  }

  /// Creates a `ConversationView` using the default `MessageView<MessageType>` renderer (`[MF-2]`).
  ///
  /// - Parameters:
  ///   - messages: Two-way binding to the conversation's ordered `[MessageType]` array.
  ///   - attachments: Optional two-way binding to pending `[ConversationAttachment]` items.
  ///   - userPrompt: Optional initial draft text seeded into the composer on first appearance.
  public init(
    messages: Binding<[MessageType]>,
    attachments: Binding<[ConversationAttachment]>? = nil,
    userPrompt: String = ""
  ) where Content == MessageView<MessageType> {
    self.init(
      messages: messages,
      attachments: attachments,
      userPrompt: userPrompt
    ) { message in
      MessageView(message: message)
    }
  }

  // MARK: - Strongly-Typed `.onSendMessage` Modifiers (`AC-19`, `[MF-2]`)

  /// Registers an async submission handler receiving the newly created `MessageType` directly (`AC-19`).
  public func onSendMessage(
    _ action: @escaping @MainActor (MessageType) async -> Void
  ) -> Self {
    var copy = self
    copy.onSendSubmissionAction = { submission in
      await action(submission.message)
    }
    return copy
  }

  /// Registers an async submission handler receiving the full `ConversationSubmission<MessageType>` (`AC-19`, `[MF-2]`).
  public func onSendMessage(
    _ action: @escaping @MainActor (ConversationSubmission<MessageType>) async -> Void
  ) -> Self {
    var copy = self
    copy.onSendSubmissionAction = action
    return copy
  }

  // MARK: - Derived Timeline & Composer State

  private var attachmentsBinding: Binding<[ConversationAttachment]> {
    externalAttachments ?? $internalAttachments
  }

  private var tokensBinding: Binding<[ComposerToken]> {
    if let environmentTokensBox {
      return environmentTokensBox.binding
    }
    return $internalTokens
  }

  private var activeSelectedModel: ComposerModelOption? {
    selectedComposerModelBox?.wrappedValue ?? composerModels.first
  }

  private var activeCapabilities: Set<ComposerCapability> {
    activeComposerCapabilitiesBox?.wrappedValue ?? []
  }

  /// Combines `messages` with `optimisticUserMessage` deduplicated by `id` in $O(1)$.
  private var displayedMessages: [MessageType] {
    guard let optimistic = optimisticUserMessage else {
      return messages
    }
    var seenIDs = Set<String>(minimumCapacity: messages.count + 1)
    var combined: [MessageType] = []
    combined.reserveCapacity(messages.count + 1)

    for msg in messages {
      if seenIDs.insert(msg.id).inserted {
        combined.append(msg)
      }
    }
    if !seenIDs.contains(optimistic.id) {
      combined.append(optimistic)
    }
    return combined
  }

  /// Deterministically groups `displayedMessages` into ordered `ConversationTurn<MessageType>` units.
  private var turns: [ConversationTurn<MessageType>] {
    ConversationTurn.group(displayedMessages)
  }

  /// Indicates whether a turn submission task is active or any message is streaming.
  private var isGenerating: Bool {
    activeTurnToken != nil || displayedMessages.contains(where: \.isStreaming)
  }

  /// Unoccluded active turn minimum height (`max(lockedUnoccludedHeight, 320)`, `[MF-3]`).
  /// `lockedUnoccludedHeight` measures the visible runway between top navigation and bottom safeAreaBar insets,
  /// ensuring that empty/short top-anchored turns fit inside the scroll runway without premature overflow.
  private var activeTurnMinHeight: CGFloat {
    max(lockedUnoccludedHeight, 320)
  }

  /// First-turn suggestion chips are visible only when configured, before the first message is sent, and while the draft is pristine (`F-8`, `AC-12`, `IVE-03`).
  private var shouldShowSuggestionChips: Bool {
    let isDraftPristine = ComposerTextBuffer.cleanText(draftText)
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .isEmpty
      && tokensBinding.wrappedValue.isEmpty
      && attachmentsBinding.wrappedValue.isEmpty
    return !suggestionChips.isEmpty
      && !hasSentFirstMessage
      && displayedMessages.isEmpty
      && isDraftPristine
  }

  // MARK: - Body

  public var body: some View {
    ScrollViewReader { proxy in
      ZStack(alignment: .bottomTrailing) {
        timelineScrollView(proxy: proxy)

        if isScrolledAwayFromBottom && !displayedMessages.isEmpty {
          ScrollToBottomButton(hasUnreadBelowFold: isGenerating) {
            scrollToBottom(proxy: proxy)
          }
          .padding(.trailing, 16)
          .padding(.bottom, 12)
          .transition(
            reduceMotion
              ? .opacity
              : .scale(scale: 0.85, anchor: .bottom).combined(with: .opacity)
          )
        }
      }
      .safeAreaBar(edge: .bottom, spacing: 0) {
        bottomChromeBar(proxy: proxy)
      }
    }
    .onAppear {
      if !hasSeededInitialPrompt {
        hasSeededInitialPrompt = true
        let cleaned = ComposerTextBuffer.cleanText(initialUserPrompt)
        if !cleaned.isEmpty && draftText.isEmpty {
          draftText = cleaned
        }
      }
      if !messages.isEmpty {
        hasSentFirstMessage = true
      }
    }
    .onChange(of: messages) { _, newMessages in
      if let optimistic = optimisticUserMessage,
        newMessages.contains(where: { $0.id == optimistic.id })
      {
        optimisticUserMessage = nil
      }
      if !newMessages.isEmpty && !hasSentFirstMessage {
        hasSentFirstMessage = true
      }
    }
    .onDisappear {
      sendingTask?.cancel()
      keyboardFocusTask?.cancel()
    }
  }

  // MARK: - Timeline ScrollView (`F-1`, `F-2`, `AC-3`, `AC-4`, `[MF-3]`)

  @ViewBuilder
  private func timelineScrollView(proxy: ScrollViewProxy) -> some View {
    let currentTurns = turns
    let lastTurnID = currentTurns.last?.id

    ScrollView(.vertical) {
      if currentTurns.isEmpty {
        emptyStateContainer
          .transition(.opacity)
      } else {
        LazyVStack(alignment: .leading, spacing: 24) {
          ForEach(currentTurns) { turn in
            let isLastTurn = (turn.id == lastTurnID)
            turnContainerView(for: turn, isLastTurn: isLastTurn)
              .id(turn.id)
              .transition(
                reduceMotion
                  ? .opacity
                  : .asymmetric(
                      insertion: .move(edge: .bottom).combined(with: .opacity),
                      removal: .opacity
                    )
              )
              .accessibilityIdentifier(ConversationAccessibilityID.turnContainer(turn.id))
          }

          Color.clear
            .frame(height: 1)
            .id(Self.bottomAnchorID)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .transition(
          reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .opacity
              )
        )
      }
    }
    .scrollDismissesKeyboard(.interactively)
    .scrollEdgeEffectStyle(.soft, for: .bottom)
    .accessibilityIdentifier(ConversationAccessibilityID.timelineScrollView)
    .onChange(of: turns.last?.id) { _, newLastID in
      if let targetTurnID = pendingScrollTargetTurnID, targetTurnID == newLastID {
        pendingScrollTargetTurnID = nil
        withAnimation(
          reduceMotion
            ? .easeOut(duration: 0.15)
            : .spring(duration: 0.42, bounce: 0.05)
        ) {
          proxy.scrollTo(targetTurnID, anchor: .top)
        }
      }
    }
    .onChange(of: pendingScrollTargetTurnID) { _, newTargetID in
      if let newTargetID, turns.last?.id == newTargetID {
        pendingScrollTargetTurnID = nil
        withAnimation(
          reduceMotion
            ? .easeOut(duration: 0.15)
            : .spring(duration: 0.42, bounce: 0.05)
        ) {
          proxy.scrollTo(newTargetID, anchor: .top)
        }
      }
    }
    .onChange(of: isComposerFocused) { _, isFocused in
      if isFocused && !displayedMessages.isEmpty {
        keyboardFocusTask?.cancel()
        keyboardFocusTask = Task { @MainActor in
          // Brief delay to allow software keyboard safe-area adjustments to begin
          try? await Task.sleep(for: .milliseconds(60))
          guard !Task.isCancelled, isComposerFocused else { return }
          withAnimation(
            reduceMotion
              ? .easeOut(duration: 0.15)
              : .spring(duration: 0.34, bounce: 0.0)
          ) {
            proxy.scrollTo(Self.bottomAnchorID, anchor: .bottom)
            isScrolledAwayFromBottom = false
          }
        }
      }
    }
    .onScrollGeometryChange(for: ScrollGeometrySnapshot.self) { geo in
      // Available scroll viewport height excluding top navigation and bottom safeAreaBar insets
      let availableRunway = max(
        0,
        geo.containerSize.height - geo.contentInsets.top - geo.contentInsets.bottom
      )
      // Distance from the bottom of the content to the bottom of the visible scroll area
      let distanceFromBottom = max(
        0,
        geo.contentSize.height - geo.visibleRect.maxY
      )
      return ScrollGeometrySnapshot(
        unoccludedCandidateHeight: availableRunway,
        distanceFromBottom: distanceFromBottom
      )
    } action: { _, snapshot in
      currentVisibleHeight = snapshot.unoccludedCandidateHeight

      // [MF-3]: Lock unoccluded viewport height so transient keyboard dismissal insets never shrink activeTurnMinHeight
      if snapshot.unoccludedCandidateHeight > lockedUnoccludedHeight {
        lockedUnoccludedHeight = snapshot.unoccludedCandidateHeight
      }

      // [AC-14]: Hysteresis state machine (>80pt show, <24pt hide)
      let nextShowState = ScrollToBottomButton.shouldShow(
        currentState: isScrolledAwayFromBottom,
        distanceFromBottom: snapshot.distanceFromBottom
      )
      if nextShowState != isScrolledAwayFromBottom {
        if reduceMotion {
          isScrolledAwayFromBottom = nextShowState
        } else {
          withAnimation(.snappy(duration: 0.22)) {
            isScrolledAwayFromBottom = nextShowState
          }
        }
      }
    }
  }

  @ViewBuilder
  private func turnContainerView(
    for turn: ConversationTurn<MessageType>,
    isLastTurn: Bool
  ) -> some View {
    let turnStack = VStack(alignment: .leading, spacing: 16) {
      if let userMessage = turn.userMessage {
        content(userMessage)
      }

      ForEach(turn.assistantMessages) { assistantMessage in
        content(assistantMessage)
      }
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)

    if isLastTurn {
      turnStack
        .frame(minHeight: activeTurnMinHeight, alignment: .top)
    } else {
      turnStack
    }
  }

  @ViewBuilder
  private var emptyStateContainer: some View {
    if let emptyConversationView {
      emptyConversationView()
        .frame(maxWidth: .infinity, minHeight: max(currentVisibleHeight - 32, 160), alignment: .center)
        .padding(.horizontal, 24)
        .opacity(isComposerFocused ? 0 : 1)
        .animation(
          reduceMotion ? nil : .snappy(duration: 0.22),
          value: isComposerFocused
        )
        .accessibilityIdentifier(ConversationAccessibilityID.emptyConversationView)
    } else {
      Color.clear
        .frame(maxWidth: .infinity, minHeight: 1)
    }
  }

  // MARK: - Bottom `.safeAreaBar` Chrome (`F-6`, `F-8`, `F-11`)

  @ViewBuilder
  private func bottomChromeBar(proxy: ScrollViewProxy) -> some View {
    VStack(spacing: 4) {
      if shouldShowSuggestionChips {
        SuggestionChipsBar(suggestions: suggestionChips) { selectedSuggestion in
          handleSuggestionChipSelection(selectedSuggestion, proxy: proxy)
        }
        .transition(
          reduceMotion
            ? .opacity
            : .move(edge: .bottom).combined(with: .opacity)
        )
      }

      MessageComposerView(
        text: $draftText,
        attachments: attachmentsBinding,
        tokens: tokensBinding,
        isFocused: $isComposerFocused,
        isGenerating: isGenerating,
        onSubmit: {
          submitCurrentDraft(proxy: proxy)
        },
        onStop: {
          stopActiveGeneration()
        }
      )

      if let conversationDisclaimer {
        conversationDisclaimer()
          .padding(.horizontal, 16)
          .padding(.bottom, 4)
          .accessibilityIdentifier(ConversationAccessibilityID.disclaimerView)
      }
    }
    .background(alignment: .bottom) {
      LinearGradient(
        stops: [
          .init(color: Color.platformBackground.opacity(0.0), location: 0.0),
          .init(color: Color.platformBackground.opacity(0.88), location: 0.28),
          .init(color: Color.platformBackground, location: 0.55),
          .init(color: Color.platformBackground, location: 1.0)
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea(edges: .bottom)
      .allowsHitTesting(false)
    }
  }

  // MARK: - Turn Submission, Suggestion Handoff & Cooperative Stop (`F-1`, `F-8`, `AC-3`, `AC-4`, `AC-12`, `AC-19`)

  private func handleSuggestionChipSelection(
    _ suggestion: PromptSuggestion,
    proxy: ScrollViewProxy
  ) {
    let effectiveBehavior = suggestionChipHandoff ?? suggestion.behavior
    switch effectiveBehavior {
    case .immediateSend:
      let cleanPrompt = ComposerTextBuffer.cleanText(suggestion.prompt)
        .trimmingCharacters(in: .whitespacesAndNewlines)
      guard !cleanPrompt.isEmpty else { return }
      submitTurn(
        cleanText: cleanPrompt,
        attachments: attachmentsBinding.wrappedValue,
        tokens: tokensBinding.wrappedValue,
        proxy: proxy
      )

    case .populateComposer:
      draftText = ComposerTextBuffer.cleanText(suggestion.prompt)
      isComposerFocused = true
    }
  }

  private func submitCurrentDraft(proxy: ScrollViewProxy) {
    let cleanDraft = ComposerTextBuffer.cleanText(draftText)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let currentAttachments = attachmentsBinding.wrappedValue
    let currentTokens = tokensBinding.wrappedValue

    guard !cleanDraft.isEmpty || !currentAttachments.isEmpty || !currentTokens.isEmpty else {
      return
    }
    guard currentAttachments.allSatisfy(\.isReadyForSubmission) else {
      return
    }

    submitTurn(
      cleanText: cleanDraft,
      attachments: currentAttachments,
      tokens: currentTokens,
      proxy: proxy
    )
  }

  private func submitTurn(
    cleanText: String,
    attachments: [ConversationAttachment],
    tokens: [ComposerToken],
    proxy: ScrollViewProxy
  ) {
    // 1. Construct strongly-typed user message with a stable ID for Optimistic UI deduplication
    let newTurnID = UUID().uuidString
    let selectedModel = activeSelectedModel
    let capabilities = activeCapabilities

    let userMessage = MessageType.makeUserMessage(
      id: newTurnID,
      content: cleanText,
      attachments: attachments,
      tokens: tokens,
      selectedModelID: selectedModel?.id
    )

    let submission = ConversationSubmission(
      id: newTurnID,
      message: userMessage,
      text: cleanText,
      attachments: attachments,
      tokens: tokens,
      selectedModel: selectedModel,
      activeCapabilities: capabilities
    )

    // 2. Synchronous @MainActor transaction: set optimistic message, dismiss suggestion chips, clear draft & focus
    isComposerFocused = false
    keyboardFocusTask?.cancel()
    keyboardFocusTask = nil
    draftText = ""
    tokensBinding.wrappedValue.removeAll()
    attachmentsBinding.wrappedValue.removeAll()
    pendingScrollTargetTurnID = newTurnID

    if !hasSentFirstMessage {
      if reduceMotion {
        hasSentFirstMessage = true
      } else {
        withAnimation(.snappy(duration: 0.28)) {
          hasSentFirstMessage = true
        }
      }
    }

    withAnimation(
      reduceMotion
        ? .easeOut(duration: 0.15)
        : .spring(duration: 0.42, bounce: 0.05)
    ) {
      optimisticUserMessage = userMessage
    }

    // 3. Token-guarded async turn execution
    sendingTask?.cancel()
    let turnToken = UUID()
    activeTurnToken = turnToken

    sendingTask = Task { @MainActor in
      defer {
        if activeTurnToken == turnToken {
          activeTurnToken = nil
          sendingTask = nil
          if let optimistic = optimisticUserMessage,
            messages.contains(where: { $0.id == optimistic.id })
          {
            optimisticUserMessage = nil
          }
        }
      }

      if let onSendSubmissionAction {
        await onSendSubmissionAction(submission)
      } else {
        // Fallback when no onSendMessage modifier is attached: append userMessage directly
        if !messages.contains(where: { $0.id == userMessage.id }) {
          messages.append(userMessage)
        }
        optimisticUserMessage = nil
      }
    }
  }

  private func stopActiveGeneration() {
    sendingTask?.cancel()
    sendingTask = nil
    activeTurnToken = nil
  }

  private func scrollToBottom(proxy: ScrollViewProxy) {
    let targetID = Self.bottomAnchorID
    withAnimation(
      reduceMotion
        ? .easeOut(duration: 0.15)
        : .spring(duration: 0.34, bounce: 0.0)
    ) {
      proxy.scrollTo(targetID, anchor: .bottom)
      isScrolledAwayFromBottom = false
    }
  }
}

#Preview("ConversationView - Top-Floating Turn Engine") {
  @Previewable @State var messages: [DefaultMessage] = [
    DefaultMessage(
      id: "turn-1-user",
      content: "Explain how ConversationKit v2 prevents per-token scroll jitter.",
      participant: .user
    ),
    DefaultMessage(
      id: "turn-1-ai",
      content: """
      `ConversationView` groups messages into `ConversationTurn` units and locks `activeTurnMinHeight` to the unoccluded viewport height.

      When you tap **Send**, `proxy.scrollTo(newTurnID, anchor: .top)` executes once, and streaming tokens flow downward with **zero** `scrollTo` calls.
      """,
      participant: .other,
      thinkingTrace: ThinkingTrace(
        status: .completed(duration: 2.1),
        summary: "Evaluated unoccluded viewport runway math",
        transcript: "Confirmed Delta Y = 0pt across keyboard dismissal and >150% overflow."
      )
    )
  ]

  NavigationStack {
    ConversationView(messages: $messages)
      .onSendMessage { submission in
        messages.append(submission.message)
        let aiID = UUID().uuidString
        messages.append(
          DefaultMessage(
            id: aiID,
            content: "Received: \(submission.text)",
            participant: .other
          )
        )
      }
      .navigationTitle("ConversationKit v2")
  }
}
