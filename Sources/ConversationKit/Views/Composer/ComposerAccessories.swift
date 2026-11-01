//
//  ComposerAccessories.swift
//  ConversationKit
//
//  Composer accessory views: ComposerTokensBar, ComposerModelSelectorMenu,
//  ComposerCapabilitiesBar, and composer accessibility identifier extensions (F-5, F-9, AC-9, AC-13).
//

import SwiftUI

// MARK: - Composer Accessibility Identifier Aliases & Extensions

extension ConversationAccessibilityID {
  /// Alias for `suggestionChipsBar` (`"composer.suggestionChipsBar"`).
  public static let composerSuggestionChipsBar = suggestionChipsBar

  /// Alias for `attachmentTray` (`"composer.attachmentTray"`).
  public static let composerAttachmentTray = attachmentTray

  /// Alias for `popupView` (`"composer.popupView"`).
  public static let composerPopup = popupView

  /// Alias for `tokensBar` (`"composer.tokensBar"`).
  public static let composerTokensBar = tokensBar

  /// Alias for `modelSelector` (`"composer.modelSelector"`).
  public static let composerModelSelector = modelSelector

  /// Alias for `capabilitiesBar` (`"composer.capabilitiesBar"`).
  public static let composerCapabilitiesBar = capabilitiesBar

  /// Alias for `attachmentButton` (`"composer.attachmentButton"`).
  public static let composerAttachmentButton = attachmentButton

  /// Alias for `textField` (`"composer.textField"`).
  public static let composerTextField = textField

  /// Alias for `dictationButton` (`"composer.dictationButton"`).
  public static let composerDictationButton = dictationButton

  /// Alias for `submitButton` (`"composer.submitButton"`).
  public static let composerSubmitButton = submitButton

  /// Alias for `dismissKeyboardButton` (`"composer.dismissKeyboardButton"`).
  public static let composerDismissKeyboardButton = dismissKeyboardButton

  /// Accessibility identifier for an attachment tile (`composer.attachment.<id>`).
  public static func attachmentTile(_ id: String) -> String {
    attachmentCard(id)
  }

  /// Accessibility identifier for an attachment upload progress ring (`composer.attachment.progress.<id>`).
  public static func attachmentUploadProgress(_ id: String) -> String {
    "composer.attachment.progress.\(id)"
  }

  /// Accessibility identifier for a failed attachment's Retry button (`composer.attachment.retry.<id>`).
  public static func attachmentRetryButton(_ id: String) -> String {
    "composer.attachment.retry.\(id)"
  }

  /// Accessibility identifier for an attachment's Remove button (`composer.attachment.remove.<id>`).
  public static func attachmentRemoveButton(_ id: String) -> String {
    "composer.attachment.remove.\(id)"
  }

  /// Alias for `tokenChip(_:)` (`composer.token.<id>`).
  public static func composerTokenChip(_ id: String) -> String {
    tokenChip(id)
  }

  /// Accessibility identifier for a token's remove button (`composer.token.remove.<id>`).
  public static func composerTokenRemoveButton(_ id: String) -> String {
    "composer.token.remove.\(id)"
  }

  /// Alias for `capabilityChip(_:)` (`composer.capability.<id>`).
  public static func composerCapabilityChip(_ id: String) -> String {
    capabilityChip(id)
  }
}

// MARK: - ComposerTokensBar (`F-5`, `AC-8`, `AC-9`)

/// Horizontal scrollable bar of committed `ComposerToken` pills (`/command` and `@mention`)
/// rendered inside `MessageComposerView` (`F-5`, `AC-8`, `AC-9`).
///
/// Highlights any token whose `id == highlightedTokenID` (first stage of double-backspace removal)
/// in destructive/accent tint, pulses any duplicate-selected token (`pulsedTokenID`), and allows
/// one-tap removal via the trailing `xmark` button.
@MainActor
public struct ComposerTokensBar: View {
  /// The committed `/command` and `@mention` tokens currently attached to the draft.
  public let tokens: [ComposerToken]

  /// Identifier of the trailing token highlighted on the first backspace press when input is empty (`AC-9`).
  public let highlightedTokenID: String?

  /// Identifier of a token that should pulse when the user selects an already-attached `@mention` (`AC-9`).
  public let pulsedTokenID: String?

  /// Callback invoked when the user removes a token pill.
  public let onRemove: @MainActor (ComposerToken) -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// Creates a `ComposerTokensBar` from an array of `ComposerToken` pills.
  public init(
    tokens: [ComposerToken],
    highlightedTokenID: String? = nil,
    pulsedTokenID: String? = nil,
    onRemove: @escaping @MainActor (ComposerToken) -> Void
  ) {
    self.tokens = tokens
    self.highlightedTokenID = highlightedTokenID
    self.pulsedTokenID = pulsedTokenID
    self.onRemove = onRemove
  }

  /// Convenience initializer binding directly to `[ComposerToken]`.
  public init(
    tokens: Binding<[ComposerToken]>,
    highlightedTokenID: String? = nil,
    pulsedTokenID: String? = nil,
    onRemove: (@MainActor (ComposerToken) -> Void)? = nil
  ) {
    self.tokens = tokens.wrappedValue
    self.highlightedTokenID = highlightedTokenID
    self.pulsedTokenID = pulsedTokenID
    self.onRemove = { token in
      if let onRemove {
        onRemove(token)
      } else {
        tokens.wrappedValue.removeAll { $0.id == token.id }
      }
    }
  }

  public var body: some View {
    if !tokens.isEmpty {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 6) {
          ForEach(tokens) { token in
            tokenChipView(for: token)
          }
        }
        .padding(.vertical, 2)
      }
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier(ConversationAccessibilityID.composerTokensBar)
    }
  }

  @ViewBuilder
  private func tokenChipView(for token: ComposerToken) -> some View {
    let isHighlighted = (token.id == highlightedTokenID)
    let isPulsed = (token.id == pulsedTokenID)
    let tintColor = chipTintColor(for: token, isHighlighted: isHighlighted)

    HStack(spacing: 5) {
      Image(systemName: token.symbolName)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(tintColor)

      Text(token.displayText)
        .font(.caption.weight(.semibold))
        .foregroundStyle(isHighlighted ? Color.red : Color.primary)
        .lineLimit(1)

      Button {
        PlatformHapticEvent.triggerHaptic(.tokenRemoved)
        onRemove(token)
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 9, weight: .bold))
          .foregroundStyle(isHighlighted ? Color.red : Color.secondary)
          .frame(width: 16, height: 16)
          .background(
            (isHighlighted ? Color.red : Color.primary).opacity(0.10),
            in: Circle()
          )
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier(ConversationAccessibilityID.composerTokenRemoveButton(token.id))
      .accessibilityLabel("Remove \(token.displayText)")
    }
    .padding(.leading, 8)
    .padding(.trailing, 5)
    .padding(.vertical, 4)
    .background(
      tintColor.opacity(isHighlighted ? 0.22 : (isPulsed ? 0.26 : 0.12)),
      in: Capsule()
    )
    .overlay {
      Capsule()
        .strokeBorder(
          tintColor.opacity(isHighlighted ? 0.90 : (isPulsed ? 0.85 : 0.30)),
          lineWidth: (isHighlighted || isPulsed) ? 1.25 : 0.5
        )
    }
    .scaleEffect(reduceMotion ? 1.0 : (isPulsed ? 1.06 : 1.0))
    .animation(
      reduceMotion ? nil : .spring(duration: 0.24, bounce: 0.35),
      value: isHighlighted
    )
    .animation(
      reduceMotion ? nil : .spring(duration: 0.26, bounce: 0.45),
      value: isPulsed
    )
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier(ConversationAccessibilityID.composerTokenChip(token.id))
    .accessibilityLabel(token.displayText)
    .accessibilityValue(isHighlighted ? "Selected for deletion" : "")
    .accessibilityAction(named: "Remove") {
      PlatformHapticEvent.triggerHaptic(.tokenRemoved)
      onRemove(token)
    }
  }

  private func chipTintColor(for token: ComposerToken, isHighlighted: Bool) -> Color {
    if isHighlighted {
      return .red
    }
    switch token.kind {
    case .command:
      return .accentColor
    case .mention:
      return .indigo
    }
  }
}

// MARK: - ComposerModelSelectorMenu (`F-9`, `AC-13`)

/// Integrated native `Menu` pill inside `MessageComposerView` displaying the active
/// `ComposerModelOption` (symbol, name, optional capability badge) and checkmark menu items
/// for switching models and toggling capabilities (`F-9`, `AC-13`).
@MainActor
public struct ComposerModelSelectorMenu: View {
  /// Available model options to display in the menu.
  public let models: [ComposerModelOption]

  /// Two-way binding to the currently selected `ComposerModelOption?`.
  @Binding public var selectedModel: ComposerModelOption?

  /// Capability options available to toggle inside the menu.
  public let capabilities: [ComposerCapability]

  /// Two-way binding to the set of currently active capabilities.
  public var activeCapabilities: Binding<Set<ComposerCapability>>?

  /// Whether to render only a compact circular icon button (`34×34pt`) without model name text.
  public let isCompact: Bool

  /// Optional callback invoked when the user picks a model.
  public let onSelect: (@MainActor (ComposerModelOption) -> Void)?

  /// Optional callback invoked when a capability is toggled.
  public let onToggleCapability: (@MainActor (ComposerCapability, Bool) -> Void)?

  /// Creates a `ComposerModelSelectorMenu`.
  public init(
    models: [ComposerModelOption],
    selectedModel: Binding<ComposerModelOption?>,
    capabilities: [ComposerCapability] = [],
    activeCapabilities: Binding<Set<ComposerCapability>>? = nil,
    isCompact: Bool = false,
    onSelect: (@MainActor (ComposerModelOption) -> Void)? = nil,
    onToggleCapability: (@MainActor (ComposerCapability, Bool) -> Void)? = nil
  ) {
    self.models = models
    self._selectedModel = selectedModel
    self.capabilities = capabilities
    self.activeCapabilities = activeCapabilities
    self.isCompact = isCompact
    self.onSelect = onSelect
    self.onToggleCapability = onToggleCapability
  }

  /// Convenience initializer preserving parameter signature without `isCompact`.
  public init(
    models: [ComposerModelOption],
    selectedModel: Binding<ComposerModelOption?>,
    capabilities: [ComposerCapability] = [],
    activeCapabilities: Binding<Set<ComposerCapability>>? = nil,
    onSelect: (@MainActor (ComposerModelOption) -> Void)? = nil,
    onToggleCapability: (@MainActor (ComposerCapability, Bool) -> Void)? = nil
  ) {
    self.init(
      models: models,
      selectedModel: selectedModel,
      capabilities: capabilities,
      activeCapabilities: activeCapabilities,
      isCompact: false,
      onSelect: onSelect,
      onToggleCapability: onToggleCapability
    )
  }

  private var activeModel: ComposerModelOption? {
    selectedModel ?? models.first
  }

  private var activeCapabilitiesList: [ComposerCapability] {
    capabilities.filter { activeCapabilities?.wrappedValue.contains($0) == true }
  }

  private var accessibilityDescription: String {
    let modelName = activeModel?.name ?? "Model"
    if activeCapabilitiesList.isEmpty {
      return modelName
    } else {
      let capTitles = activeCapabilitiesList.map(\.title).joined(separator: ", ")
      return "\(modelName), active capabilities: \(capTitles)"
    }
  }

  private var shouldGroupByCategory: Bool {
    models.count > 5 || models.contains(where: { $0.category != nil })
  }

  private struct ModelCategoryGroup: Identifiable {
    var id: String { category }
    let category: String
    let models: [ComposerModelOption]
  }

  private var categorizedModelGroups: [ModelCategoryGroup] {
    var groups: [String: [ComposerModelOption]] = [:]
    var order: [String] = []
    for model in models {
      guard let category = model.category, !category.isEmpty else { continue }
      if groups[category] == nil {
        order.append(category)
        groups[category] = []
      }
      groups[category]?.append(model)
    }
    return order.compactMap { category in
      guard let list = groups[category], !list.isEmpty else { return nil }
      return ModelCategoryGroup(category: category, models: list)
    }
  }

  private var uncategorizedModels: [ComposerModelOption] {
    models.filter { $0.category == nil || $0.category?.isEmpty == true }
  }

  private var modelSelectionBinding: Binding<ComposerModelOption?> {
    Binding(
      get: { selectedModel ?? models.first },
      set: { option in
        PlatformHapticEvent.triggerHaptic(.selection)
        selectedModel = option
        if let option {
          onSelect?(option)
        }
      }
    )
  }

  private func capabilityBinding(for cap: ComposerCapability) -> Binding<Bool> {
    Binding<Bool>(
      get: {
        activeCapabilities?.wrappedValue.contains(cap) == true
      },
      set: { isEnabled in
        PlatformHapticEvent.triggerHaptic(.selection)
        if isEnabled {
          activeCapabilities?.wrappedValue.insert(cap)
        } else {
          activeCapabilities?.wrappedValue.remove(cap)
        }
        onToggleCapability?(cap, isEnabled)
      }
    )
  }

  public var body: some View {
    if !models.isEmpty || !capabilities.isEmpty {
      Menu {
        menuContent
      } label: {
        if isCompact {
          menuIconOnlyLabel
        } else {
          menuPillLabel
        }
      }
      .menuIndicator(.hidden)
      .accessibilityIdentifier(ConversationAccessibilityID.composerModelSelector)
      .accessibilityLabel("AI Model")
      .accessibilityValue(accessibilityDescription)
      .accessibilityHint("Double-tap to switch the active AI model or toggle capabilities")
    }
  }

  @ViewBuilder
  private var menuContent: some View {
    if !models.isEmpty {
      if shouldGroupByCategory {
        if !uncategorizedModels.isEmpty {
          Picker("Model", selection: modelSelectionBinding) {
            ForEach(uncategorizedModels) { option in
              Label(option.menuItemTitle, systemImage: option.systemImage)
                .tag(Optional(option))
            }
          }
          .pickerStyle(.inline)
        }

        ForEach(categorizedModelGroups) { group in
          Menu(group.category) {
            Picker(group.category, selection: modelSelectionBinding) {
              ForEach(group.models) { option in
                Label(option.menuItemTitle, systemImage: option.systemImage)
                  .tag(Optional(option))
              }
            }
            .pickerStyle(.inline)
          }
        }
      } else {
        Picker("Model", selection: modelSelectionBinding) {
          ForEach(models) { option in
            Label(option.menuItemTitle, systemImage: option.systemImage)
              .tag(Optional(option))
          }
        }
        .pickerStyle(.inline)
      }
    }

    if !capabilities.isEmpty {
      Section("Capabilities") {
        ForEach(capabilities) { cap in
          Toggle(isOn: capabilityBinding(for: cap)) {
            Label(cap.title, systemImage: cap.symbolName)
          }
          .accessibilityIdentifier(ConversationAccessibilityID.composerCapabilityChip(cap.id))
        }
      }
    }
  }

  @ViewBuilder
  private var menuIconOnlyLabel: some View {
    let current = activeModel
    ZStack(alignment: .topTrailing) {
      Image(systemName: current?.symbolName ?? "sparkles")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.primary)

      if !activeCapabilitiesList.isEmpty {
        Circle()
          .fill(Color.accentColor)
          .frame(width: 6, height: 6)
          .padding(.top, 2)
          .padding(.trailing, 2)
      }
    }
    .frame(width: 32, height: 32)
    .background(Color.primary.opacity(0.06), in: Circle())
    .overlay {
      Circle()
        .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
    }
    .contentShape(Circle())
    .fixedSize(horizontal: true, vertical: false)
    .layoutPriority(1)
  }

  @ViewBuilder
  private var menuPillLabel: some View {
    let current = activeModel
    HStack(spacing: 6) {
      Image(systemName: current?.symbolName ?? "sparkles")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.secondary)
        .frame(width: 24, height: 24)
        .background(Color.primary.opacity(0.08), in: Circle())

      Text(current?.name ?? "Model")
        .font(.subheadline.weight(.regular))
        .foregroundStyle(.primary)
        .lineLimit(1)

      if !activeCapabilitiesList.isEmpty {
        HStack(spacing: 3) {
          ForEach(activeCapabilitiesList) { cap in
            Image(systemName: cap.symbolName)
              .font(.system(size: 10, weight: .semibold))
              .foregroundStyle(Color.accentColor)
          }
        }
        .animation(.snappy(duration: 0.2), value: activeCapabilitiesList)
      }

      Image(systemName: "chevron.up.chevron.down")
        .font(.system(size: 9, weight: .semibold))
        .foregroundStyle(.secondary)
    }
    .padding(.leading, 5)
    .padding(.trailing, 10)
    .frame(height: 32)
    .background(Color.primary.opacity(0.06), in: Capsule())
    .overlay {
      Capsule()
        .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
    }
    .contentShape(Capsule())
    .fixedSize(horizontal: true, vertical: false)
    .layoutPriority(1)
  }
}

extension ComposerModelOption {
  fileprivate var menuItemTitle: String {
    if let badge, !badge.isEmpty {
      return "\(name) (\(badge))"
    }
    return name
  }
}

// MARK: - ComposerCapabilitiesBar (`F-9`, `AC-13`)

/// Horizontal strip of toggleable `ComposerCapability` capsule chips (`Think`, `Search`,
/// `Image`, or custom capabilities) rendered inside `MessageComposerView` (`F-9`, `AC-13`).
@MainActor
public struct ComposerCapabilitiesBar: View {
  /// Ordered capability options available to toggle.
  public let capabilities: [ComposerCapability]

  /// Two-way binding to the set of currently active capabilities.
  @Binding public var activeCapabilities: Set<ComposerCapability>

  /// Optional callback invoked when a capability is toggled.
  public let onToggle: (@MainActor (ComposerCapability, Bool) -> Void)?

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// Creates a `ComposerCapabilitiesBar`.
  public init(
    capabilities: [ComposerCapability],
    activeCapabilities: Binding<Set<ComposerCapability>>,
    onToggle: (@MainActor (ComposerCapability, Bool) -> Void)? = nil
  ) {
    self.capabilities = capabilities
    self._activeCapabilities = activeCapabilities
    self.onToggle = onToggle
  }

  public var body: some View {
    if !capabilities.isEmpty {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 6) {
          ForEach(capabilities) { capability in
            capabilityChipButton(for: capability)
          }
        }
        .padding(.vertical, 1)
      }
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier(ConversationAccessibilityID.composerCapabilitiesBar)
    }
  }

  @ViewBuilder
  private func capabilityChipButton(for capability: ComposerCapability) -> some View {
    let isSelected = activeCapabilities.contains(capability)

    Button {
      PlatformHapticEvent.triggerHaptic(.selection)
      let nextState = !isSelected
      if reduceMotion {
        updateCapability(capability, isActive: nextState)
      } else {
        withAnimation(.snappy(duration: 0.2)) {
          updateCapability(capability, isActive: nextState)
        }
      }
      onToggle?(capability, nextState)
    } label: {
      HStack(spacing: 4) {
        Image(systemName: capability.symbolName)
          .font(.system(size: 11, weight: .semibold))

        Text(capability.title)
          .font(.caption.weight(.medium))
          .lineLimit(1)
      }
      .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
      .padding(.horizontal, 9)
      .padding(.vertical, 5)
      .background(
        isSelected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.06),
        in: Capsule()
      )
      .overlay {
        Capsule()
          .strokeBorder(
            isSelected
              ? Color.accentColor.opacity(0.55)
              : Color.platformSeparator.opacity(0.35),
            lineWidth: isSelected ? 1.0 : 0.5
          )
      }
      .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(ConversationAccessibilityID.composerCapabilityChip(capability.id))
    .accessibilityLabel(capability.title)
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
  }

  private func updateCapability(_ capability: ComposerCapability, isActive: Bool) {
    if isActive {
      activeCapabilities.insert(capability)
    } else {
      activeCapabilities.remove(capability)
    }
  }
}

#Preview("ComposerAccessories") {
  @Previewable @State var tokens: [ComposerToken] = [
    .command(SlashCommand(trigger: "summarize", title: "Summarize")),
    .mention(ResourceMention(queryHandle: "PRD-0001", title: "PRD-0001.md"))
  ]
  @Previewable @State var selectedModel: ComposerModelOption? = ComposerModelOption(
    id: "sonnet",
    name: "Sonnet 4.6",
    subtitle: "Balanced speed & intelligence",
    badge: "Pro",
    symbolName: "sparkles"
  )
  @Previewable @State var activeCapabilities: Set<ComposerCapability> = [.think, .search]

  VStack(alignment: .leading, spacing: 12) {
    ComposerTokensBar(
      tokens: $tokens,
      highlightedTokenID: tokens.last?.id
    )

    HStack {
      Spacer()
      ComposerModelSelectorMenu(
        models: [
          ComposerModelOption(
            id: "sonnet",
            name: "Sonnet 4.6",
            subtitle: "Balanced speed & intelligence",
            badge: "Pro",
            symbolName: "sparkles",
            category: "Anthropic"
          ),
          ComposerModelOption(
            id: "opus",
            name: "Opus 4.6",
            subtitle: "Deep architectural reasoning",
            badge: "Max",
            symbolName: "brain",
            category: "Anthropic"
          ),
          ComposerModelOption(
            id: "gpt-4o",
            name: "GPT-4o",
            subtitle: "Omni multimodal intelligence",
            badge: "Fast",
            symbolName: "sparkles",
            category: "OpenAI"
          )
        ],
        selectedModel: $selectedModel,
        capabilities: [.think, .search, .image],
        activeCapabilities: $activeCapabilities
      )
    }
  }
  .padding()
}
