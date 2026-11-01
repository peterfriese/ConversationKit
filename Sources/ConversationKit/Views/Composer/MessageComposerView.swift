//
//  MessageComposerView.swift
//  ConversationKit
//
//  Liquid Glass message composer with \u{200B} sentinel two-stage backspace token removal,
//  '/' command & '@' mention autocomplete with async generation guard, universal attachment
//  pickers, upload submission gating, and focus-driven keyboard dismissal (F-4, F-5, F-6, F-9, F-11).
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// Primary message input composer view for `ConversationKit`, delegating visual chrome layout to
/// `@Environment(\.messageComposerStyle)` (`MessageComposerStyle`, `AC-16`).
///
/// `MessageComposerView` orchestrates:
/// 1. **Zero-Width Sentinel (`\u{200B}`) & Two-Stage Backspace (`AC-9`, `[MF-5]`):** Maintains a leading
///    `\u{200B}` character via `ComposerTextBuffer` whenever structured `ComposerToken` pills exist so
///    iOS software keyboards reliably emit backspace events on an empty visible draft.
/// 2. **Slash Commands (`/`) & Resource Mentions (`@`) (`F-5`, `AC-8`, `SHOULD-FIX-1`):** Presents
///    `ComposerPopupView` above the composer on word-boundary triggers, guarding async `@mention`
///    provider searches with cooperative task cancellation and a monotonic `queryGenerationID: UInt64`.
/// 3. **Built-In Multimodal Attachment Pickers (`F-4`, `AC-6`, `AC-7`):** Integrates `PhotosPicker`,
///    `.fileImporter`, pasteboard attachment reading (`PlatformPasteboard.readAttachments()`),
///    drag-and-drop (`.dropDestination`), and determinate upload progress rings (`AttachmentTrayView`).
/// 4. **Strict Submission Gating & Return-Key Safety (`AC-7`, `[MF-5]`):** Requires at least one
///    non-empty input (`cleanText`, `attachments`, or `tokens`) and `attachments.allSatisfy(\.isReadyForSubmission)`,
///    ensuring Return key presses never cancel an active streaming response.
/// 5. **Focus-Driven Keyboard Dismiss Button (`F-11`, `AC-15`):** Populates `configuration.dismissKeyboardButton`
///    (`keyboard.chevron.compact.down`) whenever the composer text field is focused.
@MainActor
public struct MessageComposerView: View {
  // MARK: - Bindings & Configuration

  @Binding private var text: String
  private var externalAttachments: Binding<[ConversationAttachment]>?
  private var externalTokens: Binding<[ComposerToken]>?
  private var externalFocusState: FocusState<Bool>.Binding?
  private var externalFocusBinding: Binding<Bool>?

  private let isGenerating: Bool
  private let placeholder: String
  private let showsPopupInline: Bool
  private let onSubmitAction: @MainActor () -> Void
  private let onStopAction: @MainActor () -> Void
  private let onDictationAction: (@MainActor () -> Void)?

  // MARK: - Environment

  @Environment(\.messageComposerStyle) private var composerStyle
  @Environment(\.slashCommands) private var slashCommands
  @Environment(\.resourceMentions) private var resourceMentions
  @Environment(\.resourceMentionProvider) private var resourceMentionProvider
  @Environment(\.composerModels) private var composerModels
  @Environment(\.selectedComposerModelBox) private var selectedComposerModelBox
  @Environment(\.composerCapabilities) private var composerCapabilities
  @Environment(\.activeComposerCapabilitiesBox) private var activeComposerCapabilitiesBox
  @Environment(\.composerTokensBox) private var environmentTokensBox
  @Environment(\.attachmentActions) private var customAttachmentActions
  @Environment(\.attachmentsDisabled) private var attachmentsDisabled
  @Environment(\.onAttachmentUpload) private var onAttachmentUpload
  @Environment(\.onAttachmentRetry) private var onAttachmentRetry
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  // MARK: - Internal State

  @FocusState private var internalFocusState: Bool
  @State private var internalAttachments: [ConversationAttachment] = []
  @State private var internalTokens: [ComposerToken] = []
  @State private var internalSelectedModel: ComposerModelOption?
  @State private var internalActiveCapabilities: Set<ComposerCapability> = []

  @State private var textBuffer = ComposerTextBuffer()
  @State private var pulsedTokenID: String?

  // Autocomplete & Async Mention Provider State (`SHOULD-FIX-1`)
  @State private var asyncMentionResults: [ResourceMention] = []
  @State private var isSearchingMentions: Bool = false
  @State private var queryGenerationID: UInt64 = 0
  @State private var mentionSearchTask: Task<Void, Never>?

  // Built-in Pickers State (`F-4`)
  @State private var isShowingPhotosPicker: Bool = false
  @State private var selectedPhotoItems: [PhotosPickerItem] = []
  @State private var isShowingFileImporter: Bool = false
  @State private var uploadTasks: [String: Task<Void, Never>] = [:]

  // MARK: - Initializers

  /// Creates a `MessageComposerView` with full bindings and lifecycle callbacks.
  ///
  /// - Parameters:
  ///   - text: Two-way binding to the clean prompt text (`\u{200B}` sentinel is automatically stripped).
  ///   - attachments: Optional binding to pending `[ConversationAttachment]` items (falls back to internal state).
  ///   - tokens: Optional binding to committed `[ComposerToken]` pills (falls back to environment or internal state).
  ///   - isFocused: Optional `FocusState<Bool>.Binding` for external focus coordination.
  ///   - isGenerating: Whether an assistant response is actively streaming (`true` turns Send into Stop).
  ///   - placeholder: Placeholder string displayed when the prompt is empty.
  ///   - showsPopupInline: Whether `ComposerPopupView` renders automatically above the composer when `/` or `@` is active.
  ///   - onDictation: Optional callback enabling the voice/dictation button.
  ///   - onSubmit: Callback invoked when the user taps Send or presses Return while `canSubmit` is `true`.
  ///   - onStop: Callback invoked when the user taps Stop while `isGenerating` is `true`.
  public init(
    text: Binding<String>,
    attachments: Binding<[ConversationAttachment]>? = nil,
    tokens: Binding<[ComposerToken]>? = nil,
    isFocused: FocusState<Bool>.Binding? = nil,
    isGenerating: Bool = false,
    placeholder: String = "Message…",
    showsPopupInline: Bool = true,
    onDictation: (@MainActor () -> Void)? = nil,
    onSubmit: @escaping @MainActor () -> Void = {},
    onStop: @escaping @MainActor () -> Void = {}
  ) {
    self._text = text
    self.externalAttachments = attachments
    self.externalTokens = tokens
    self.externalFocusState = isFocused
    self.externalFocusBinding = nil
    self.isGenerating = isGenerating
    self.placeholder = placeholder
    self.showsPopupInline = showsPopupInline
    self.onDictationAction = onDictation
    self.onSubmitAction = onSubmit
    self.onStopAction = onStop
  }

  /// Convenience initializer accepting `onSend:` parameter label.
  public init(
    text: Binding<String>,
    attachments: Binding<[ConversationAttachment]>? = nil,
    tokens: Binding<[ComposerToken]>? = nil,
    isFocused: FocusState<Bool>.Binding? = nil,
    isGenerating: Bool = false,
    placeholder: String = "Message…",
    showsPopupInline: Bool = true,
    onSend: @escaping @MainActor () -> Void,
    onStop: @escaping @MainActor () -> Void = {}
  ) {
    self.init(
      text: text,
      attachments: attachments,
      tokens: tokens,
      isFocused: isFocused,
      isGenerating: isGenerating,
      placeholder: placeholder,
      showsPopupInline: showsPopupInline,
      onDictation: nil,
      onSubmit: onSend,
      onStop: onStop
    )
  }

  /// Convenience initializer accepting `message:` parameter label.
  public init(
    message: Binding<String>,
    attachments: Binding<[ConversationAttachment]>? = nil,
    tokens: Binding<[ComposerToken]>? = nil,
    isFocused: FocusState<Bool>.Binding? = nil,
    isGenerating: Bool = false,
    placeholder: String = "Message…",
    showsPopupInline: Bool = true,
    onSubmit: @escaping @MainActor () -> Void = {},
    onStop: @escaping @MainActor () -> Void = {}
  ) {
    self.init(
      text: message,
      attachments: attachments,
      tokens: tokens,
      isFocused: isFocused,
      isGenerating: isGenerating,
      placeholder: placeholder,
      showsPopupInline: showsPopupInline,
      onDictation: nil,
      onSubmit: onSubmit,
      onStop: onStop
    )
  }

  /// Convenience initializer accepting a standard `Binding<Bool>` for `isFocused`.
  public init(
    text: Binding<String>,
    attachments: Binding<[ConversationAttachment]>? = nil,
    tokens: Binding<[ComposerToken]>? = nil,
    isFocused: Binding<Bool>,
    isGenerating: Bool = false,
    placeholder: String = "Message…",
    showsPopupInline: Bool = true,
    onSubmit: @escaping @MainActor () -> Void = {},
    onStop: @escaping @MainActor () -> Void = {}
  ) {
    self._text = text
    self.externalAttachments = attachments
    self.externalTokens = tokens
    self.externalFocusState = nil
    self.externalFocusBinding = isFocused
    self.isGenerating = isGenerating
    self.placeholder = placeholder
    self.showsPopupInline = showsPopupInline
    self.onDictationAction = nil
    self.onSubmitAction = onSubmit
    self.onStopAction = onStop
  }

  // MARK: - Effective Bindings & Derived State

  private var attachmentsBinding: Binding<[ConversationAttachment]> {
    externalAttachments ?? $internalAttachments
  }

  private var tokensBinding: Binding<[ComposerToken]> {
    if let externalTokens {
      return externalTokens
    }
    if let environmentTokensBox {
      return environmentTokensBox.binding
    }
    return $internalTokens
  }

  private var selectedModelBinding: Binding<ComposerModelOption?> {
    if let selectedComposerModelBox {
      return selectedComposerModelBox.binding
    }
    return $internalSelectedModel
  }

  private var activeCapabilitiesBinding: Binding<Set<ComposerCapability>> {
    if let activeComposerCapabilitiesBox {
      return activeComposerCapabilitiesBox.binding
    }
    return $internalActiveCapabilities
  }

  private var effectiveIsFocused: Bool {
    if let externalFocusState {
      return externalFocusState.wrappedValue
    }
    if let externalFocusBinding {
      return externalFocusBinding.wrappedValue || internalFocusState
    }
    return internalFocusState
  }

  /// Clean user-visible text with all `\u{200B}` sentinel characters globally stripped (`[MF-5]`).
  public var cleanText: String {
    ComposerTextBuffer.cleanText(text).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Submission gate (`AC-7`, `[MF-5]`): requires non-empty content/attachments/tokens AND all attachments `.ready`.
  public var canSubmit: Bool {
    let currentAttachments = attachmentsBinding.wrappedValue
    let currentTokens = tokensBinding.wrappedValue
    let hasContent = !cleanText.isEmpty || !currentAttachments.isEmpty || !currentTokens.isEmpty
    let allAttachmentsReady = currentAttachments.allSatisfy(\.isReadyForSubmission)
    return hasContent && allAttachmentsReady
  }

  // MARK: - Body

  public var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      if showsPopupInline, let trigger = activeTriggerMatch {
        popupView(for: trigger)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }

      composerStyle.makeBody(configuration: styleConfiguration)
    }
    .photosPicker(
      isPresented: $isShowingPhotosPicker,
      selection: $selectedPhotoItems,
      maxSelectionCount: 10,
      matching: .images
    )
    .fileImporter(
      isPresented: $isShowingFileImporter,
      allowedContentTypes: [.item, .pdf, .image, .text, .data],
      allowsMultipleSelection: true
    ) { result in
      handleFileImportResult(result)
    }
    .dropDestination(for: URL.self) { urls, _ in
      guard !attachmentsDisabled else { return false }
      return handleDroppedURLs(urls)
    }
    .dropDestination(for: Data.self) { dataItems, _ in
      guard !attachmentsDisabled else { return false }
      return handleDroppedData(dataItems)
    }
    .onAppear {
      synchronizeBufferFromExternalState()
    }
    .onChange(of: text) { _, newValue in
      let cleaned = ComposerTextBuffer.cleanText(newValue)
      if cleaned != newValue {
        text = cleaned
      }
      if cleaned != textBuffer.cleanText {
        textBuffer.setText(cleaned, hasTokens: !tokensBinding.wrappedValue.isEmpty)
      }
      handleTriggerQueryUpdate()
    }
    .onChange(of: tokensBinding.wrappedValue) { _, newTokens in
      textBuffer.syncTokens(newTokens)
    }
    .onChange(of: selectedPhotoItems) { _, newItems in
      guard !newItems.isEmpty else { return }
      processSelectedPhotoItems(newItems)
    }
    .onChange(of: internalFocusState) { _, focused in
      if externalFocusBinding?.wrappedValue != focused {
        externalFocusBinding?.wrappedValue = focused
      }
    }
    .onChange(of: externalFocusBinding?.wrappedValue) { _, newFocused in
      if let newFocused, internalFocusState != newFocused {
        internalFocusState = newFocused
      }
    }
    .onDisappear {
      mentionSearchTask?.cancel()
    }
  }

  // MARK: - StyleConfiguration Builder

  private var styleConfiguration: MessageComposerStyleConfiguration {
    let currentAttachments = attachmentsBinding.wrappedValue
    let currentTokens = tokensBinding.wrappedValue
    let hasModels = !composerModels.isEmpty
    let hasCapabilities = !composerCapabilities.isEmpty

    return MessageComposerStyleConfiguration(
      textField: AnyView(promptTextField),
      attachmentButton: attachmentsDisabled ? nil : AnyView(attachmentMenu(isBorderless: false)),
      attachmentsTray: currentAttachments.isEmpty ? nil : AnyView(attachmentsTraySubview),
      tokensBar: currentTokens.isEmpty ? nil : AnyView(tokensBarSubview),
      modelSelector: (hasModels || hasCapabilities) ? AnyView(modelSelectorSubview(isCompact: false)) : nil,
      capabilitiesBar: nil,
      dictationButton: onDictationAction.map { action in
        AnyView(dictationButtonSubview(action: action))
      },
      submitButton: AnyView(submitButtonSubview),
      dismissKeyboardButton: effectiveIsFocused ? AnyView(dismissKeyboardButtonSubview) : nil,
      isFocused: effectiveIsFocused,
      isGenerating: isGenerating,
      canSubmit: canSubmit,
      hasAttachments: !currentAttachments.isEmpty,
      hasTokens: !currentTokens.isEmpty,
      hasModels: hasModels,
      hasCapabilities: hasCapabilities,
      compactModelSelector: (hasModels || hasCapabilities) ? AnyView(modelSelectorSubview(isCompact: true)) : nil,
      borderlessAttachmentButton: attachmentsDisabled ? nil : AnyView(attachmentMenu(isBorderless: true))
    )
  }

  // MARK: - Subviews

  @ViewBuilder
  private var promptTextField: some View {
    let isVisuallyEmpty = ComposerTextBuffer.cleanText(text).isEmpty

    TextField("", text: textFieldRawBinding, axis: .vertical)
      .lineLimit(1...8)
      .textFieldStyle(.plain)
      .modifier(
        ComposerFocusBridgeModifier(
          externalFocus: externalFocusState,
          internalFocus: $internalFocusState
        )
      )
      .onSubmit(of: .text) {
        handleReturnKeySubmit()
      }
      .overlay(alignment: .leading) {
        if isVisuallyEmpty {
          Text(placeholder)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
      }
      .accessibilityIdentifier(ConversationAccessibilityID.composerTextField)
      .accessibilityLabel(placeholder)
      .accessibilityValue(ComposerTextBuffer.cleanText(text))
  }

  @ViewBuilder
  private func attachmentMenu(isBorderless: Bool) -> some View {
    Menu {
      Button("Photos", systemImage: "photo.on.rectangle.angled") {
        PlatformHapticEvent.triggerHaptic(.selection)
        isShowingPhotosPicker = true
      }

      Button("Files", systemImage: "doc.badge.plus") {
        PlatformHapticEvent.triggerHaptic(.selection)
        isShowingFileImporter = true
      }

      if !PlatformPasteboard.readAttachments().isEmpty {
        Button("Paste from Clipboard", systemImage: "doc.on.clipboard") {
          PlatformHapticEvent.triggerHaptic(.selection)
          pasteAttachmentsFromClipboard()
        }
      }

      if let customAttachmentActions {
        Divider()
        customAttachmentActions()
      }
    } label: {
      if isBorderless {
        Image(systemName: "plus")
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.primary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .contentShape(Circle())
      } else {
        Image(systemName: "plus")
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(.primary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color.primary.opacity(0.06), in: Circle())
          .overlay {
            Circle()
              .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
          }
          .contentShape(Circle())
      }
    }
    .frame(width: isBorderless ? 34 : 44, height: isBorderless ? 34 : 44)
    .menuStyle(.button)
    .buttonStyle(.plain)
    .accessibilityIdentifier(ConversationAccessibilityID.composerAttachmentButton)
    .accessibilityLabel("Add attachment")
    .accessibilityHint("Opens menu to attach photos, files, or clipboard items")
  }

  @ViewBuilder
  private var attachmentsTraySubview: some View {
    AttachmentTrayView(
      attachments: attachmentsBinding,
      onRetry: { failedAttachment in
        handleAttachmentRetry(failedAttachment)
      },
      onRemove: { removedAttachment in
        removeAttachment(removedAttachment)
      }
    )
  }

  @ViewBuilder
  private var tokensBarSubview: some View {
    ComposerTokensBar(
      tokens: tokensBinding.wrappedValue,
      highlightedTokenID: textBuffer.highlightedTokenID,
      pulsedTokenID: pulsedTokenID
    ) { tokenToRemove in
      removeToken(tokenToRemove)
    }
  }

  @ViewBuilder
  private func modelSelectorSubview(isCompact: Bool) -> some View {
    ComposerModelSelectorMenu(
      models: composerModels,
      selectedModel: selectedModelBinding,
      capabilities: composerCapabilities,
      activeCapabilities: activeCapabilitiesBinding,
      isCompact: isCompact
    )
  }

  @ViewBuilder
  private var capabilitiesBarSubview: some View {
    ComposerCapabilitiesBar(
      capabilities: composerCapabilities,
      activeCapabilities: activeCapabilitiesBinding
    )
  }

  @ViewBuilder
  private func dictationButtonSubview(action: @escaping @MainActor () -> Void) -> some View {
    Button {
      PlatformHapticEvent.triggerHaptic(.selection)
      action()
    } label: {
      Image(systemName: "waveform")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.secondary)
        .frame(width: 30, height: 30)
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(ConversationAccessibilityID.composerDictationButton)
    .accessibilityLabel("Dictate message")
  }

  @ViewBuilder
  private var submitButtonSubview: some View {
    Button {
      handlePrimaryAction()
    } label: {
      Image(systemName: isGenerating ? "stop.fill" : "arrow.up")
        .font(isGenerating ? .system(size: 12, weight: .black) : .system(size: 15, weight: .semibold))
        .foregroundStyle(Color.white)
        .frame(width: 34, height: 34)
        .background(Color.accentColor, in: Circle())
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .disabled(!isGenerating && !canSubmit)
    .accessibilityLabel(isGenerating ? "Stop generating" : "Send message")
    .accessibilityIdentifier(ConversationAccessibilityID.composerSubmitButton)
    .accessibilityHint(
      isGenerating
        ? "Stops the active assistant response"
        : (canSubmit ? "Sends your message" : "Enter a message or wait for uploads to finish")
    )
  }

  @ViewBuilder
  private var dismissKeyboardButtonSubview: some View {
    Button {
      dismissKeyboard()
    } label: {
      Image(systemName: "keyboard.chevron.compact.down")
        .font(.system(size: 17, weight: .regular))
        .foregroundStyle(.secondary)
        .frame(width: 34, height: 34)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Dismiss keyboard")
    .accessibilityIdentifier(ConversationAccessibilityID.composerDismissKeyboardButton)
  }

  // MARK: - `\u{200B}` Sentinel & Two-Stage Backspace Binding (`AC-9`, `[MF-5]`)

  private var textFieldRawBinding: Binding<String> {
    Binding(
      get: {
        let hasTokens = !tokensBinding.wrappedValue.isEmpty
        return ComposerTextBuffer.bindingText(for: text, hasTokens: hasTokens)
      },
      set: { newRawValue in
        var currentTokens = tokensBinding.wrappedValue
        textBuffer.syncTokens(currentTokens)
        let action = textBuffer.applyEdit(newRawValue, tokens: &currentTokens)

        switch action {
        case .none:
          let cleaned = textBuffer.cleanText
          if text != cleaned {
            text = cleaned
          }
          handleTriggerQueryUpdate()

        case .highlightToken:
          PlatformHapticEvent.triggerHaptic(.selection)
          if !text.isEmpty {
            text = ""
          }

        case .removeToken:
          PlatformHapticEvent.triggerHaptic(.tokenRemoved)
          tokensBinding.wrappedValue = currentTokens
          if !text.isEmpty {
            text = ""
          }
        }
      }
    )
  }

  private func synchronizeBufferFromExternalState() {
    let cleaned = ComposerTextBuffer.cleanText(text)
    if cleaned != text {
      text = cleaned
    }
    textBuffer.setText(cleaned, hasTokens: !tokensBinding.wrappedValue.isEmpty)
    handleTriggerQueryUpdate()
  }

  private func removeToken(_ token: ComposerToken) {
    var updated = tokensBinding.wrappedValue
    updated.removeAll { $0.id == token.id }
    tokensBinding.wrappedValue = updated
    textBuffer.syncTokens(updated)
  }

  // MARK: - `/` Slash Command & `@` Mention Autocomplete (`F-5`, `AC-8`, `AC-9`, `SHOULD-FIX-1`)

  private var activeTriggerMatch: ComposerTextBuffer.TriggerMatch? {
    ComposerTextBuffer.detectTrigger(in: text)
  }

  private func matchingCommands(for query: String) -> [SlashCommand] {
    guard !slashCommands.isEmpty else { return [] }
    let trimmed = ComposerTextBuffer.cleanText(query).trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return slashCommands }
    return slashCommands.filter { cmd in
      ComposerTextBuffer.matchedRange(of: trimmed, in: cmd.trigger) != nil
        || ComposerTextBuffer.matchedRange(of: trimmed, in: cmd.title) != nil
        || (cmd.description.flatMap { ComposerTextBuffer.matchedRange(of: trimmed, in: $0) } != nil)
    }
  }

  private func matchingMentions(for query: String) -> [ResourceMention] {
    let trimmed = ComposerTextBuffer.cleanText(query).trimmingCharacters(in: .whitespacesAndNewlines)
    let staticMatches: [ResourceMention]
    if trimmed.isEmpty {
      staticMatches = resourceMentions
    } else {
      staticMatches = resourceMentions.filter { mention in
        ComposerTextBuffer.matchedRange(of: trimmed, in: mention.queryHandle) != nil
          || ComposerTextBuffer.matchedRange(of: trimmed, in: mention.title) != nil
          || (mention.subtitle.flatMap { ComposerTextBuffer.matchedRange(of: trimmed, in: $0) } != nil)
      }
    }

    var combined: [ResourceMention] = []
    var seenIDs = Set<String>()
    for item in staticMatches + asyncMentionResults {
      if seenIDs.insert(item.id).inserted {
        combined.append(item)
      }
    }
    return combined
  }

  @ViewBuilder
  private func popupView(for trigger: ComposerTextBuffer.TriggerMatch) -> some View {
    switch trigger {
    case .slashCommand(let query, _):
      let matches = matchingCommands(for: query)
      if !matches.isEmpty {
        ComposerPopupView(
          query: query,
          commands: matches
        ) { selectedCommand in
          selectSlashCommand(selectedCommand)
        }
      }

    case .resourceMention(let query, _):
      let matches = matchingMentions(for: query)
      if !matches.isEmpty || isSearchingMentions {
        ComposerPopupView(
          query: query,
          mentions: matches,
          isLoading: isSearchingMentions
        ) { selectedMention in
          selectResourceMention(selectedMention)
        }
      }
    }
  }

  private func handleTriggerQueryUpdate() {
    guard let trigger = activeTriggerMatch else {
      mentionSearchTask?.cancel()
      isSearchingMentions = false
      asyncMentionResults = []
      return
    }

    switch trigger {
    case .slashCommand:
      mentionSearchTask?.cancel()
      isSearchingMentions = false
      asyncMentionResults = []

    case .resourceMention(let query, _):
      guard let provider = resourceMentionProvider else {
        mentionSearchTask?.cancel()
        isSearchingMentions = false
        asyncMentionResults = []
        return
      }

      // Cancel in-flight task and advance monotonic generation guard (`SHOULD-FIX-1`)
      mentionSearchTask?.cancel()
      queryGenerationID &+= 1
      let expectedGeneration = queryGenerationID
      let cleanQuery = ComposerTextBuffer.cleanText(query)
      isSearchingMentions = true

      mentionSearchTask = Task { @MainActor in
        do {
          if !cleanQuery.isEmpty {
            try await Task.sleep(for: .milliseconds(90))
          }
          try Task.checkCancellation()
          let results = try await provider(cleanQuery)
          try Task.checkCancellation()
          guard expectedGeneration == queryGenerationID else { return }
          asyncMentionResults = results
          isSearchingMentions = false
        } catch {
          guard expectedGeneration == queryGenerationID else { return }
          isSearchingMentions = false
        }
      }
    }
  }

  private func selectSlashCommand(_ command: SlashCommand) {
    var currentTokens = tokensBinding.wrappedValue
    // Replace existing slash command token or append at the front
    let commandToken = ComposerToken.command(command)
    if let existingIndex = currentTokens.firstIndex(where: { $0.command != nil }) {
      currentTokens[existingIndex] = commandToken
    } else {
      currentTokens.insert(commandToken, at: 0)
    }

    textBuffer.setText(text, hasTokens: true)
    textBuffer.consumeActiveTrigger(hasTokens: true)
    tokensBinding.wrappedValue = currentTokens
    text = textBuffer.cleanText
    PlatformHapticEvent.triggerHaptic(.tokenInserted)
  }

  private func selectResourceMention(_ mention: ResourceMention) {
    var currentTokens = tokensBinding.wrappedValue
    textBuffer.setText(text, hasTokens: true)
    textBuffer.consumeActiveTrigger(hasTokens: true)
    text = textBuffer.cleanText

    // Duplicate mention guard (`AC-9`): pulse existing token instead of inserting a duplicate
    if let existing = currentTokens.first(where: {
      $0.mention?.id == mention.id || $0.id == "mention-\(mention.id)"
    }) {
      PlatformHapticEvent.triggerHaptic(.warning)
      pulsedTokenID = existing.id
      let targetID = existing.id
      Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(550))
        if pulsedTokenID == targetID {
          pulsedTokenID = nil
        }
      }
      return
    }

    let mentionToken = ComposerToken.mention(mention)
    currentTokens.append(mentionToken)
    tokensBinding.wrappedValue = currentTokens
    textBuffer.syncTokens(currentTokens)
    PlatformHapticEvent.triggerHaptic(.tokenInserted)
  }

  // MARK: - Submission & Focus Handling

  private func handlePrimaryAction() {
    if isGenerating {
      PlatformHapticEvent.triggerHaptic(.selection)
      onStopAction()
    } else if canSubmit {
      triggerSubmit()
    }
  }

  private func dismissKeyboard() {
    PlatformHapticEvent.triggerHaptic(.selection)
    setFocus(false)
  }

  private func handleReturnKeySubmit() {
    // Return key MUST ONLY submit when not generating and canSubmit is true (`[MF-5]`)
    guard !isGenerating, canSubmit else { return }
    triggerSubmit()
  }

  private func triggerSubmit() {
    guard !isGenerating, canSubmit else { return }
    text = ComposerTextBuffer.cleanText(text)
    textBuffer.highlightedTokenID = nil
    setFocus(false)
    PlatformHapticEvent.triggerHaptic(.send)
    onSubmitAction()
  }

  private func setFocus(_ focused: Bool) {
    if let externalFocusState {
      externalFocusState.wrappedValue = focused
    } else {
      internalFocusState = focused
    }
    externalFocusBinding?.wrappedValue = focused
  }

  // MARK: - Attachment Ingestion & Upload Coordination (`F-4`, `AC-6`, `AC-7`)

  private func processSelectedPhotoItems(_ items: [PhotosPickerItem]) {
    selectedPhotoItems.removeAll()
    Task { @MainActor in
      for (index, item) in items.enumerated() {
        guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
        let contentType = item.supportedContentTypes.first ?? .png
        let ext = contentType.preferredFilenameExtension ?? "png"
        let filename = "Photo-\(index + 1).\(ext)"

        let attachment: ConversationAttachment
        if let imageBox = PlatformImageBox(data: data) {
          attachment = ConversationAttachment(
            imageBox: imageBox,
            filename: filename
          )
        } else {
          attachment = ConversationAttachment(
            data: data,
            contentType: contentType,
            filename: filename
          )
        }
        appendAndUploadAttachment(attachment)
      }
    }
  }

  private func handleFileImportResult(_ result: Result<[URL], any Error>) {
    guard case .success(let urls) = result else { return }
    _ = handleDroppedURLs(urls)
  }

  private func handleDroppedURLs(_ urls: [URL]) -> Bool {
    var addedAny = false
    for url in urls {
      let didStart = url.startAccessingSecurityScopedResource()
      defer {
        if didStart {
          url.stopAccessingSecurityScopedResource()
        }
      }
      let attachment = ConversationAttachment(fileURL: url)
      appendAndUploadAttachment(attachment)
      addedAny = true
    }
    if addedAny {
      PlatformHapticEvent.triggerHaptic(.selection)
    }
    return addedAny
  }

  private func handleDroppedData(_ dataItems: [Data]) -> Bool {
    var addedAny = false
    for (index, data) in dataItems.enumerated() {
      let attachment: ConversationAttachment
      if let imageBox = PlatformImageBox(data: data) {
        attachment = ConversationAttachment(
          imageBox: imageBox,
          filename: "Dropped-Image-\(index + 1).png"
        )
      } else {
        attachment = ConversationAttachment(
          data: data,
          contentType: .data,
          filename: "Dropped-File-\(index + 1).bin"
        )
      }
      appendAndUploadAttachment(attachment)
      addedAny = true
    }
    if addedAny {
      PlatformHapticEvent.triggerHaptic(.selection)
    }
    return addedAny
  }

  private func pasteAttachmentsFromClipboard() {
    let pasted = PlatformPasteboard.readAttachments()
    for item in pasted {
      let attachment: ConversationAttachment
      if item.contentType.conforms(to: .image), let imageBox = PlatformImageBox(data: item.data) {
        attachment = ConversationAttachment(
          imageBox: imageBox,
          filename: item.filename
        )
      } else {
        attachment = ConversationAttachment(
          data: item.data,
          contentType: item.contentType,
          filename: item.filename
        )
      }
      appendAndUploadAttachment(attachment)
    }
  }

  private func appendAndUploadAttachment(_ attachment: ConversationAttachment) {
    var current = attachmentsBinding.wrappedValue
    var mutableAttachment = attachment
    if onAttachmentUpload != nil {
      mutableAttachment.uploadState = .uploading(progress: 0.0)
    }
    current.append(mutableAttachment)
    attachmentsBinding.wrappedValue = current

    if onAttachmentUpload != nil {
      startUploadTask(for: mutableAttachment)
    }
  }

  private func removeAttachment(_ attachment: ConversationAttachment) {
    uploadTasks[attachment.id]?.cancel()
    uploadTasks[attachment.id] = nil
    if reduceMotion {
      attachmentsBinding.wrappedValue.removeAll { $0.id == attachment.id }
    } else {
      withAnimation(.snappy(duration: 0.22)) {
        attachmentsBinding.wrappedValue.removeAll { $0.id == attachment.id }
      }
    }
  }

  private func handleAttachmentRetry(_ attachment: ConversationAttachment) {
    if let onAttachmentRetry {
      Task { @MainActor in
        await onAttachmentRetry(attachment)
      }
    } else if onAttachmentUpload != nil {
      startUploadTask(for: attachment)
    } else if let idx = attachmentsBinding.wrappedValue.firstIndex(where: { $0.id == attachment.id }) {
      attachmentsBinding.wrappedValue[idx].uploadState = .ready
    }
  }

  private func startUploadTask(for attachment: ConversationAttachment) {
    guard let onAttachmentUpload else { return }
    uploadTasks[attachment.id]?.cancel()

    if let idx = attachmentsBinding.wrappedValue.firstIndex(where: { $0.id == attachment.id }) {
      attachmentsBinding.wrappedValue[idx].uploadState = .uploading(progress: 0.0)
    }

    let attachmentID = attachment.id
    uploadTasks[attachmentID] = Task { @MainActor in
      do {
        let completed = try await onAttachmentUpload(attachment) { progress in
          let clamped = min(max(progress, 0.0), 1.0)
          if let index = attachmentsBinding.wrappedValue.firstIndex(where: { $0.id == attachmentID }) {
            attachmentsBinding.wrappedValue[index].uploadState = .uploading(progress: clamped)
          }
        }
        try Task.checkCancellation()
        if let index = attachmentsBinding.wrappedValue.firstIndex(where: { $0.id == attachmentID }) {
          var finalized = completed
          finalized.uploadState = .ready
          attachmentsBinding.wrappedValue[index] = finalized
        }
        uploadTasks[attachmentID] = nil
      } catch is CancellationError {
        uploadTasks[attachmentID] = nil
      } catch {
        if let index = attachmentsBinding.wrappedValue.firstIndex(where: { $0.id == attachmentID }) {
          attachmentsBinding.wrappedValue[index].uploadState = .failed(
            error: error.localizedDescription
          )
        }
        PlatformHapticEvent.triggerHaptic(.error)
        uploadTasks[attachmentID] = nil
      }
    }
  }
}

// MARK: - ComposerFocusBridgeModifier

private struct ComposerFocusBridgeModifier: ViewModifier {
  let externalFocus: FocusState<Bool>.Binding?
  let internalFocus: FocusState<Bool>.Binding

  func body(content: Content) -> some View {
    if let externalFocus {
      content.focused(externalFocus)
    } else {
      content.focused(internalFocus)
    }
  }
}

#Preview("MessageComposerView - Classic Glass") {
  @Previewable @State var text = ""
  @Previewable @State var attachments: [ConversationAttachment] = []
  @Previewable @State var tokens: [ComposerToken] = [
    .command(SlashCommand(trigger: "review", title: "Review"))
  ]
  @Previewable @State var selectedModel: ComposerModelOption? = ComposerModelOption(
    id: "sonnet-4-6",
    name: "Claude Sonnet 4.6",
    badge: "Pro",
    symbolName: "sparkles"
  )
  @Previewable @State var activeCapabilities: Set<ComposerCapability> = [.think]

  VStack {
    Spacer()
    MessageComposerView(
      text: $text,
      attachments: $attachments,
      tokens: $tokens
    )
    .composerModels([selectedModel!], selection: $selectedModel)
    .composerCapabilities([.think, .search, .image], active: $activeCapabilities)
  }
}
