//
//  MessageComposerStyle.swift
//  ConversationKit
//
//  SwiftUI Style protocol and built-in Liquid Glass styles for MessageComposerView (iOS 26+ / macOS 26+).
//

import SwiftUI

// MARK: - MessageComposerStyle Protocol

/// Defines the visual layout and iOS 26+ / macOS 26+ Liquid Glass arrangement of `MessageComposerView` (`AC-16`).
///
/// ### Usage
/// ```swift
/// // Layer 1 (Troposphere): Default .classicGlass composer style
/// ConversationView(messages: $messages)
///
/// // Layer 2 (Stratosphere): Built-in two-row AI assistant card or compact capsule style
/// ConversationView(messages: $messages)
///   .messageComposerStyle(.cardGlass)
///
/// // Layer 4 (Thermosphere): Custom MessageComposerStyle implementation
/// struct CustomComposerStyle: MessageComposerStyle {
///   func makeBody(configuration: Configuration) -> some View {
///     HStack {
///       configuration.textField
///       configuration.submitButton
///     }
///   }
/// }
/// ```
@MainActor
public protocol MessageComposerStyle: DynamicProperty, Sendable {
  /// The view type representing the body of this composer style.
  associatedtype Body: View

  /// Convenience alias for `MessageComposerStyleConfiguration`.
  typealias Configuration = MessageComposerStyleConfiguration

  /// Creates the view representing the body of `MessageComposerView`.
  @ViewBuilder
  @MainActor
  func makeBody(configuration: Configuration) -> Body
}

// MARK: - MessageComposerStyleConfiguration

/// The subview slots and state properties passed to a `MessageComposerStyle` implementation (`§3.3.1`).
@MainActor
public struct MessageComposerStyleConfiguration {
  private let textFieldBuilder: () -> AnyView
  private let attachmentButtonBuilder: (() -> AnyView)?
  private let borderlessAttachmentButtonBuilder: (() -> AnyView)?
  private let attachmentsTrayBuilder: (() -> AnyView)?
  private let tokensBarBuilder: (() -> AnyView)?
  private let modelSelectorBuilder: (() -> AnyView)?
  private let compactModelSelectorBuilder: (() -> AnyView)?
  private let dictationButtonBuilder: (() -> AnyView)?
  private let submitButtonBuilder: () -> AnyView
  private let dismissKeyboardButtonBuilder: (() -> AnyView)?

  /// Vertical-growing prompt text field.
  public var textField: AnyView {
    textFieldBuilder()
  }

  /// Leading `+` menu trigger button for adding photos, files, or custom attachment actions (bordered or detached).
  public var attachmentButton: AnyView? {
    attachmentButtonBuilder?()
  }

  /// Leading borderless `+` menu trigger icon without circular background or border overlay.
  public var borderlessAttachmentButton: AnyView? {
    borderlessAttachmentButtonBuilder?()
  }

  /// Horizontal scroll strip displaying pending `ConversationAttachment` cards with upload progress rings.
  public var attachmentsTray: AnyView? {
    attachmentsTrayBuilder?()
  }

  /// Horizontal scroll bar displaying active `/command` and `@mention` `ComposerToken` pills.
  public var tokensBar: AnyView? {
    tokensBarBuilder?()
  }

  /// Integrated model selector menu pill (`ComposerModelOption`) displaying model name and badge.
  public var modelSelector: AnyView? {
    modelSelectorBuilder?()
  }

  /// Compact circular icon-only model selector button (`ComposerModelOption`) without text label.
  public var compactModelSelector: AnyView? {
    compactModelSelectorBuilder?()
  }

  /// Optional voice/dictation button.
  public var dictationButton: AnyView? {
    dictationButtonBuilder?()
  }

  /// Trailing primary action button (morphs between Send and cooperative Stop).
  public var submitButton: AnyView {
    submitButtonBuilder()
  }

  /// Focus-driven keyboard dismiss button (`keyboard.chevron.compact.down`) shown on iOS when `isFocused` is `true` (`F-11`, `AC-15`).
  public var dismissKeyboardButton: AnyView? {
    dismissKeyboardButtonBuilder?()
  }

  /// Indicates whether the composer's text input field currently has keyboard focus (`@FocusState`).
  public let isFocused: Bool

  /// Indicates whether an assistant response is actively streaming (`true` transforms Send into Stop).
  public let isGenerating: Bool

  /// Indicates whether the current draft and attachments satisfy the submission gate (`[MF-5]`).
  public let canSubmit: Bool

  /// Indicates whether one or more pending attachments are present in the composer.
  public let hasAttachments: Bool

  /// Indicates whether one or more structured `/command` or `@mention` tokens are attached.
  public let hasTokens: Bool

  /// Indicates whether model options are configured for the integrated model selector.
  public let hasModels: Bool

  /// Indicates whether capability toggles are configured for the composer.
  public let hasCapabilities: Bool

  /// Creates a `MessageComposerStyleConfiguration`.
  public init(
    textField: AnyView,
    attachmentButton: AnyView? = nil,
    attachmentsTray: AnyView? = nil,
    tokensBar: AnyView? = nil,
    modelSelector: AnyView? = nil,
    dictationButton: AnyView? = nil,
    submitButton: AnyView,
    dismissKeyboardButton: AnyView? = nil,
    isFocused: Bool = false,
    isGenerating: Bool = false,
    canSubmit: Bool = false,
    hasAttachments: Bool? = nil,
    hasTokens: Bool? = nil,
    hasModels: Bool? = nil,
    hasCapabilities: Bool = false,
    compactModelSelector: AnyView? = nil,
    borderlessAttachmentButton: AnyView? = nil
  ) {
    self.textFieldBuilder = { textField }
    self.attachmentButtonBuilder = attachmentButton.map { view in { view } }
    self.borderlessAttachmentButtonBuilder = borderlessAttachmentButton.map { view in { view } }
    self.attachmentsTrayBuilder = attachmentsTray.map { view in { view } }
    self.tokensBarBuilder = tokensBar.map { view in { view } }
    self.modelSelectorBuilder = modelSelector.map { view in { view } }
    self.compactModelSelectorBuilder = compactModelSelector.map { view in { view } }
    self.dictationButtonBuilder = dictationButton.map { view in { view } }
    self.submitButtonBuilder = { submitButton }
    self.dismissKeyboardButtonBuilder = dismissKeyboardButton.map { view in { view } }
    self.isFocused = isFocused
    self.isGenerating = isGenerating
    self.canSubmit = canSubmit
    self.hasAttachments = hasAttachments ?? (attachmentsTray != nil)
    self.hasTokens = hasTokens ?? (tokensBar != nil)
    self.hasModels = hasModels ?? (modelSelector != nil || compactModelSelector != nil)
    self.hasCapabilities = hasCapabilities
  }

  /// Creates a `MessageComposerStyleConfiguration` with lazy subview builders so unused style slots are never constructed (`F-03`).
  internal init(
    lazyTextField: @escaping () -> AnyView,
    attachmentButton: (() -> AnyView)? = nil,
    borderlessAttachmentButton: (() -> AnyView)? = nil,
    attachmentsTray: (() -> AnyView)? = nil,
    tokensBar: (() -> AnyView)? = nil,
    modelSelector: (() -> AnyView)? = nil,
    compactModelSelector: (() -> AnyView)? = nil,
    dictationButton: (() -> AnyView)? = nil,
    submitButton: @escaping () -> AnyView,
    dismissKeyboardButton: (() -> AnyView)? = nil,
    isFocused: Bool = false,
    isGenerating: Bool = false,
    canSubmit: Bool = false,
    hasAttachments: Bool? = nil,
    hasTokens: Bool? = nil,
    hasModels: Bool? = nil,
    hasCapabilities: Bool = false
  ) {
    self.textFieldBuilder = lazyTextField
    self.attachmentButtonBuilder = attachmentButton
    self.borderlessAttachmentButtonBuilder = borderlessAttachmentButton
    self.attachmentsTrayBuilder = attachmentsTray
    self.tokensBarBuilder = tokensBar
    self.modelSelectorBuilder = modelSelector
    self.compactModelSelectorBuilder = compactModelSelector
    self.dictationButtonBuilder = dictationButton
    self.submitButtonBuilder = submitButton
    self.dismissKeyboardButtonBuilder = dismissKeyboardButton
    self.isFocused = isFocused
    self.isGenerating = isGenerating
    self.canSubmit = canSubmit
    self.hasAttachments = hasAttachments ?? (attachmentsTray != nil)
    self.hasTokens = hasTokens ?? (tokensBar != nil)
    self.hasModels = hasModels ?? (modelSelector != nil || compactModelSelector != nil)
    self.hasCapabilities = hasCapabilities
  }
}

// MARK: - ClassicGlassMessageComposerStyle (.classicGlass / .automatic)

/// Default Liquid Glass composer style featuring a canonical 3-zone bookend sibling architecture (`Sofia` pattern):
/// - **Outside Left (`44×44pt` Liquid Glass Circle Sibling):** Leading `+` attachment menu button (`.glassEffect(.regular.interactive(), in: .circle)`).
/// - **Inside the Interactive Text Vessel (`44pt` minHeight, `cornerRadius: 22`):** `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))` housing `textField` and borderless `32×32pt` inner trailing accessories (`compactModelSelector`, `dictationButton`, and focus-driven `dismissKeyboardButton`).
/// - **Outside Right (`44×44pt` Prominent Tinted Liquid Glass Circle Sibling):** Trailing `submitButton` (`Send` / `Stop`) when `canSubmit || isGenerating` is `true` inside `GlassEffectContainer(spacing: 6)` with static `HStack(alignment: .bottom, spacing: 8)`.
public struct ClassicGlassMessageComposerStyle: MessageComposerStyle, Sendable {
  /// Creates the default classic Liquid Glass composer style.
  public nonisolated init() {}

  @MainActor
  public func makeBody(configuration: Configuration) -> some View {
    ClassicGlassComposerBody(configuration: configuration)
  }
}

// MARK: - CardGlassMessageComposerStyle (.cardGlass)

/// Two-row modern AI assistant card composer style inside `GlassEffectContainer` (`AC-16`).
///
/// Renders a unified 2-row Liquid Glass card (`cornerRadius: 24`, ~84pt empty height) with `attachmentsTray`,
/// `tokensBar`, and full-width `textField` in the top section, and a dedicated bottom toolbar row housing
/// bordered `attachmentButton` (`32×32pt`), full `modelSelector` pill (`32pt` height), `Spacer()`, `dismissKeyboardButton` (when focused), and `submitButton` (when `canSubmit || isGenerating`, `32×32pt`).
public struct CardGlassMessageComposerStyle: MessageComposerStyle, Sendable {
  /// Creates a two-row card Liquid Glass composer style.
  public nonisolated init() {}

  @MainActor
  public func makeBody(configuration: Configuration) -> some View {
    CardGlassComposerBody(configuration: configuration)
  }
}

// MARK: - AnchorPreference Menu Isolation (`Sofia` Pattern / `F-01`)

private enum ComposerMenuSlotID: Hashable, Sendable {
  case attachmentMenu
  case modelSelectorMenu
}

private struct ComposerMenuSlotAnchorKey: PreferenceKey {
  static let defaultValue: [ComposerMenuSlotID: Anchor<CGRect>] = [:]

  static func reduce(
    value: inout [ComposerMenuSlotID: Anchor<CGRect>],
    nextValue: () -> [ComposerMenuSlotID: Anchor<CGRect>]
  ) {
    value.merge(nextValue(), uniquingKeysWith: { _, new in new })
  }
}

@MainActor
@ViewBuilder
private func composerMenuHitTargetsOverlay(
  anchors: [ComposerMenuSlotID: Anchor<CGRect>],
  attachmentMenu: AnyView? = nil,
  modelSelectorMenu: AnyView? = nil
) -> some View {
  if !anchors.isEmpty {
    GeometryReader { proxy in
      if let anchor = anchors[.attachmentMenu], let attachmentMenu {
        let rect = proxy[anchor]
        attachmentMenu
          .environment(\.isComposerMenuHitTargetOverlay, true)
          .frame(width: rect.width, height: rect.height)
          .position(x: rect.midX, y: rect.midY)
      }

      if let anchor = anchors[.modelSelectorMenu], let modelSelectorMenu {
        let rect = proxy[anchor]
        modelSelectorMenu
          .environment(\.isComposerMenuHitTargetOverlay, true)
          .frame(width: rect.width, height: rect.height)
          .position(x: rect.midX, y: rect.midY)
      }
    }
  }
}

// MARK: - ClassicGlassComposerBody

private struct ClassicGlassComposerBody: View {
  let configuration: MessageComposerStyleConfiguration

  @Namespace private var glassNamespace
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private let plusDiameter: CGFloat = 44
  private let buttonDiameter: CGFloat = 32
  private let pillCornerRadius: CGFloat = 22

  private var showsSubmitButton: Bool {
    configuration.canSubmit || configuration.isGenerating
  }

  var body: some View {
    GlassEffectContainer(spacing: 6) {
      HStack(alignment: .bottom, spacing: 8) {
        // Outside Left: 44×44pt Liquid Glass Circle Sibling (+ Attachment Menu)
        if let plusButton = configuration.attachmentButton {
          detachedPlusButton(plusButton)
        }

        // Inside the Interactive Text Vessel: TextField + Inner Trailing 32×32pt Accessories (Model + Dictation + DismissKeyboard)
        classicPill

        // Outside Right: 44×44pt Prominent Tinted Liquid Glass Circle Sibling (Send / Stop)
        if showsSubmitButton {
          detachedSubmitButton(configuration.submitButton)
        }
      }
      .animation(reduceMotion ? nil : .snappy(duration: 0.18), value: showsSubmitButton)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
  }

  @ViewBuilder
  private func detachedPlusButton(_ button: AnyView) -> some View {
    if reduceTransparency {
      button
        .frame(width: plusDiameter, height: plusDiameter)
        .background(Color.platformSecondaryBackground, in: Circle())
        .overlay {
          Circle()
            .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
        }
    } else {
      button
        .frame(width: plusDiameter, height: plusDiameter)
        .glassEffect(.regular.interactive(), in: .circle)
        .glassEffectID("classic.leadingPlus", in: glassNamespace)
    }
  }

  @ViewBuilder
  private func detachedSubmitButton(_ button: AnyView) -> some View {
    if reduceTransparency {
      button
        .frame(width: plusDiameter, height: plusDiameter)
        .background(Color.accentColor, in: Circle())
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    } else {
      button
        .frame(width: plusDiameter, height: plusDiameter)
        .glassEffect(.regular.tint(.accentColor).interactive(), in: .circle)
        .glassEffectTransition(.materialize)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }
  }

  @ViewBuilder
  private var classicPill: some View {
    let panelContent = VStack(alignment: .leading, spacing: 6) {
      if configuration.hasAttachments, let attachmentsTray = configuration.attachmentsTray {
        attachmentsTray
          .padding(.horizontal, 10)
          .padding(.top, 8)
      }

      if configuration.hasTokens, let tokensBar = configuration.tokensBar {
        tokensBar
          .padding(.horizontal, 10)
          .padding(.top, configuration.hasAttachments ? 2 : 8)
      }

      mainInputRow
    }
    .frame(minHeight: plusDiameter)

    if reduceTransparency {
      panelContent
        .background(
          Color.platformSecondaryBackground,
          in: RoundedRectangle(cornerRadius: pillCornerRadius, style: .continuous)
        )
        .overlay {
          RoundedRectangle(cornerRadius: pillCornerRadius, style: .continuous)
            .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
        }
    } else {
      panelContent
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: pillCornerRadius))
        .glassEffectID("classic.textPill", in: glassNamespace)
        .overlayPreferenceValue(ComposerMenuSlotAnchorKey.self) { anchors in
          composerMenuHitTargetsOverlay(
            anchors: anchors,
            modelSelectorMenu: (configuration.hasModels || configuration.hasCapabilities)
              ? (configuration.compactModelSelector ?? configuration.modelSelector)
              : nil
          )
        }
    }
  }

  private var hasInnerTrailingAccessories: Bool {
    ((configuration.hasModels || configuration.hasCapabilities)
      && (configuration.compactModelSelector ?? configuration.modelSelector) != nil)
      || configuration.dictationButton != nil
      || (configuration.isFocused && configuration.dismissKeyboardButton != nil)
  }

  @ViewBuilder
  private var mainInputRow: some View {
    HStack(alignment: .bottom, spacing: 0) {
      configuration.textField
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 14)
        .padding(.trailing, hasInnerTrailingAccessories ? 4 : 14)
        .padding(.vertical, 10)

      if hasInnerTrailingAccessories {
        innerTrailingAccessories
          .padding(.trailing, 6)
          .padding(.bottom, 6)
      }
    }
  }

  @ViewBuilder
  private var innerTrailingAccessories: some View {
    HStack(alignment: .bottom, spacing: 4) {
      if (configuration.hasModels || configuration.hasCapabilities),
         let modelSelector = configuration.compactModelSelector ?? configuration.modelSelector {
        if reduceTransparency {
          modelSelector
            .frame(width: buttonDiameter, height: buttonDiameter)
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(1)
        } else {
          modelSelector
            .environment(\.isComposerMenuVisualOnly, true)
            .frame(width: buttonDiameter, height: buttonDiameter)
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .anchorPreference(key: ComposerMenuSlotAnchorKey.self, value: .bounds) {
              [.modelSelectorMenu: $0]
            }
        }
      }

      if let dictationButton = configuration.dictationButton {
        dictationButton
          .frame(width: buttonDiameter, height: buttonDiameter)
      }

      if configuration.isFocused, let dismissKeyboardButton = configuration.dismissKeyboardButton {
        dismissKeyboardButton
          .frame(width: buttonDiameter, height: buttonDiameter)
          .transition(.scale(scale: 0.8).combined(with: .opacity))
      }
    }
    .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: configuration.isFocused)
  }
}

// MARK: - CardGlassComposerBody

private struct CardGlassComposerBody: View {
  let configuration: MessageComposerStyleConfiguration

  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private let controlDiameter: CGFloat = 32
  private let cardCornerRadius: CGFloat = 24

  private var showsSubmitButton: Bool {
    configuration.canSubmit || configuration.isGenerating
  }

  var body: some View {
    cardPanel
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
  }

  @ViewBuilder
  private var cardPanel: some View {
    let panelContent = VStack(alignment: .leading, spacing: 0) {
      if configuration.hasAttachments, let attachmentsTray = configuration.attachmentsTray {
        attachmentsTray
          .padding(.horizontal, 12)
          .padding(.top, 12)
      }

      if configuration.hasTokens, let tokensBar = configuration.tokensBar {
        tokensBar
          .padding(.horizontal, 12)
          .padding(.top, configuration.hasAttachments ? 6 : 12)
      }

      configuration.textField
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)

      bottomToolbarRow
    }

    if reduceTransparency {
      panelContent
        .background(
          Color.platformSecondaryBackground,
          in: RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
        )
        .overlay {
          RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
            .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
        }
    } else {
      panelContent
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cardCornerRadius))
        .overlayPreferenceValue(ComposerMenuSlotAnchorKey.self) { anchors in
          composerMenuHitTargetsOverlay(
            anchors: anchors,
            attachmentMenu: configuration.borderlessAttachmentButton ?? configuration.attachmentButton,
            modelSelectorMenu: (configuration.hasModels || configuration.hasCapabilities)
              ? configuration.modelSelector
              : nil
          )
        }
    }
  }

  @ViewBuilder
  private var bottomToolbarRow: some View {
    HStack(alignment: .center, spacing: 8) {
      if let attachmentButton = configuration.borderlessAttachmentButton ?? configuration.attachmentButton {
        if reduceTransparency {
          attachmentButton
            .frame(width: controlDiameter, height: controlDiameter)
            .background(Color.primary.opacity(0.07), in: Circle())
        } else {
          attachmentButton
            .environment(\.isComposerMenuVisualOnly, true)
            .frame(width: controlDiameter, height: controlDiameter)
            .background(Color.primary.opacity(0.07), in: Circle())
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .anchorPreference(key: ComposerMenuSlotAnchorKey.self, value: .bounds) {
              [.attachmentMenu: $0]
            }
        }
      }

      if (configuration.hasModels || configuration.hasCapabilities), let modelSelector = configuration.modelSelector {
        if reduceTransparency {
          modelSelector
            .frame(height: controlDiameter)
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(1)
        } else {
          modelSelector
            .environment(\.isComposerMenuVisualOnly, true)
            .frame(height: controlDiameter)
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .anchorPreference(key: ComposerMenuSlotAnchorKey.self, value: .bounds) {
              [.modelSelectorMenu: $0]
            }
        }
      }

      Spacer(minLength: 8)

      HStack(alignment: .center, spacing: 8) {
        if let dictationButton = configuration.dictationButton {
          dictationButton
            .frame(width: controlDiameter, height: controlDiameter)
        }

        if configuration.isFocused, let dismissKeyboardButton = configuration.dismissKeyboardButton {
          dismissKeyboardButton
            .frame(width: controlDiameter, height: controlDiameter)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }

        if showsSubmitButton {
          configuration.submitButton
            .frame(width: controlDiameter, height: controlDiameter)
            .background(Color.accentColor, in: Circle())
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
      }
      .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: configuration.isFocused)
      .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: showsSubmitButton)
    }
    .padding(.horizontal, 12)
    .padding(.bottom, 10)
  }
}

// MARK: - CompactGlassMessageComposerStyle (.compactGlass)

/// Single-row compact capsule Liquid Glass composer style (`cornerRadius: 22`) for secondary sheets, popovers, and inspectors (`AC-16`).
///
/// Houses `attachmentsTray`, `tokensBar`, a borderless `+` button (`borderlessAttachmentButton`), growing prompt `textField`,
/// compact round model icon button (`compactModelSelector`: `32×32pt`), `dismissKeyboardButton` (when focused), and `submitButton`
/// inside a unified interactive Liquid Glass capsule (`44pt` minHeight, `cornerRadius: 22`) with bottom baseline alignment.
public struct CompactGlassMessageComposerStyle: MessageComposerStyle, Sendable {
  /// Creates a compact single-row capsule Liquid Glass composer style.
  public nonisolated init() {}

  @MainActor
  public func makeBody(configuration: Configuration) -> some View {
    CompactGlassComposerBody(configuration: configuration)
  }
}

private struct CompactGlassComposerBody: View {
  let configuration: MessageComposerStyleConfiguration

  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private let capsuleMinHeight: CGFloat = 44
  private let controlDiameter: CGFloat = 32
  private let pillCornerRadius: CGFloat = 22

  private var showsSubmitButton: Bool {
    configuration.canSubmit || configuration.isGenerating
  }

  private var hasLeadingAttachment: Bool {
    (configuration.borderlessAttachmentButton ?? configuration.attachmentButton) != nil
  }

  private var hasTrailingControls: Bool {
    ((configuration.hasModels || configuration.hasCapabilities)
      && (configuration.compactModelSelector ?? configuration.modelSelector) != nil)
      || configuration.dictationButton != nil
      || (configuration.isFocused && configuration.dismissKeyboardButton != nil)
      || showsSubmitButton
  }

  var body: some View {
    capsulePill
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
  }

  @ViewBuilder
  private var capsulePill: some View {
    let panelContent = VStack(alignment: .leading, spacing: 6) {
      if configuration.hasAttachments, let attachmentsTray = configuration.attachmentsTray {
        attachmentsTray
          .padding(.horizontal, 10)
          .padding(.top, 8)
      }

      if configuration.hasTokens, let tokensBar = configuration.tokensBar {
        tokensBar
          .padding(.horizontal, 10)
          .padding(.top, configuration.hasAttachments ? 2 : 8)
      }

      mainInputRow
    }
    .frame(minHeight: capsuleMinHeight)

    if reduceTransparency {
      panelContent
        .background(
          Color.platformSecondaryBackground,
          in: RoundedRectangle(cornerRadius: pillCornerRadius, style: .continuous)
        )
        .overlay {
          RoundedRectangle(cornerRadius: pillCornerRadius, style: .continuous)
            .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
        }
    } else {
      panelContent
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: pillCornerRadius))
        .overlayPreferenceValue(ComposerMenuSlotAnchorKey.self) { anchors in
          composerMenuHitTargetsOverlay(
            anchors: anchors,
            attachmentMenu: configuration.borderlessAttachmentButton ?? configuration.attachmentButton,
            modelSelectorMenu: (configuration.hasModels || configuration.hasCapabilities)
              ? (configuration.compactModelSelector ?? configuration.modelSelector)
              : nil
          )
        }
    }
  }

  @ViewBuilder
  private var mainInputRow: some View {
    HStack(alignment: .bottom, spacing: 0) {
      if let attachmentButton = configuration.borderlessAttachmentButton ?? configuration.attachmentButton {
        if reduceTransparency {
          attachmentButton
            .frame(width: controlDiameter, height: controlDiameter)
            .padding(.leading, 6)
            .padding(.bottom, 6)
        } else {
          attachmentButton
            .environment(\.isComposerMenuVisualOnly, true)
            .frame(width: controlDiameter, height: controlDiameter)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .anchorPreference(key: ComposerMenuSlotAnchorKey.self, value: .bounds) {
              [.attachmentMenu: $0]
            }
            .padding(.leading, 6)
            .padding(.bottom, 6)
        }
      }

      configuration.textField
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, hasLeadingAttachment ? 6 : 14)
        .padding(.trailing, hasTrailingControls ? 4 : 14)
        .padding(.vertical, 10)

      if hasTrailingControls {
        trailingControls
          .padding(.trailing, 6)
          .padding(.bottom, 6)
      }
    }
  }

  @ViewBuilder
  private var trailingControls: some View {
    HStack(alignment: .bottom, spacing: 4) {
      if (configuration.hasModels || configuration.hasCapabilities),
         let modelSelector = configuration.compactModelSelector ?? configuration.modelSelector {
        if reduceTransparency {
          modelSelector
            .frame(width: controlDiameter, height: controlDiameter)
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(1)
        } else {
          modelSelector
            .environment(\.isComposerMenuVisualOnly, true)
            .frame(width: controlDiameter, height: controlDiameter)
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .anchorPreference(key: ComposerMenuSlotAnchorKey.self, value: .bounds) {
              [.modelSelectorMenu: $0]
            }
        }
      }

      if let dictationButton = configuration.dictationButton {
        dictationButton
          .frame(width: controlDiameter, height: controlDiameter)
      }

      if configuration.isFocused, let dismissKeyboardButton = configuration.dismissKeyboardButton {
        dismissKeyboardButton
          .frame(width: controlDiameter, height: controlDiameter)
          .transition(.scale(scale: 0.8).combined(with: .opacity))
      }

      if showsSubmitButton {
        configuration.submitButton
          .frame(width: controlDiameter, height: controlDiameter)
          .background(Color.accentColor, in: Circle())
          .transition(.scale(scale: 0.8).combined(with: .opacity))
      }
    }
    .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: configuration.isFocused)
    .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: showsSubmitButton)
  }
}

// MARK: - Static Style Presets

extension MessageComposerStyle where Self == ClassicGlassMessageComposerStyle {
  /// Default style: Classic single-row rounded pill (`cornerRadius: 22`, ~48pt empty height)
  /// housing attachment button, growing text field, model selector, keyboard dismiss, and send/stop.
  public nonisolated static var classicGlass: ClassicGlassMessageComposerStyle {
    ClassicGlassMessageComposerStyle()
  }

  /// Idiomatic SwiftUI alias for `.classicGlass`.
  public nonisolated static var automatic: ClassicGlassMessageComposerStyle {
    ClassicGlassMessageComposerStyle()
  }
}

extension MessageComposerStyle where Self == CardGlassMessageComposerStyle {
  /// Two-row unified Liquid Glass AI assistant card (`cornerRadius: 24`, ~84pt empty height) with top input area and bottom accessory toolbar.
  public nonisolated static var cardGlass: CardGlassMessageComposerStyle {
    CardGlassMessageComposerStyle()
  }
}

extension MessageComposerStyle where Self == CompactGlassMessageComposerStyle {
  /// Single-row compact capsule composer for secondary sheets, popovers, and inspectors.
  public nonisolated static var compactGlass: CompactGlassMessageComposerStyle {
    CompactGlassMessageComposerStyle()
  }
}

// MARK: - Type-Erased AnyMessageComposerStyle & Environment

/// A type-erased `MessageComposerStyle` wrapper stored in `EnvironmentValues`.
@MainActor
public struct AnyMessageComposerStyle: MessageComposerStyle, Sendable {
  private let bodyBuilder: @MainActor @Sendable (MessageComposerStyleConfiguration) -> AnyView

  /// Type-erases a concrete `MessageComposerStyle`.
  public nonisolated init<S: MessageComposerStyle & Sendable>(_ style: S) {
    self.bodyBuilder = { @MainActor configuration in
      AnyView(MessageComposerStyleHost(style: style, configuration: configuration))
    }
  }

  @MainActor
  public func makeBody(configuration: Configuration) -> AnyView {
    bodyBuilder(configuration)
  }
}

private struct MessageComposerStyleHost<S: MessageComposerStyle>: View {
  let style: S
  let configuration: MessageComposerStyleConfiguration

  var body: some View {
    style.makeBody(configuration: configuration)
  }
}

extension EnvironmentValues {
  /// The active `MessageComposerStyle` in the environment (defaults to `.classicGlass`).
  @Entry public var messageComposerStyle: AnyMessageComposerStyle = AnyMessageComposerStyle(.classicGlass)

  /// Internal flag indicating that a composer `Menu` slot is rendered inside `.glassEffect` for visual breathing only.
  @Entry internal var isComposerMenuVisualOnly: Bool = false

  /// Internal flag indicating that a composer `Menu` slot is rendered in an post-glass overlay as an invisible hit target.
  @Entry internal var isComposerMenuHitTargetOverlay: Bool = false
}

extension View {
  /// Sets the style for `MessageComposerView` within this view hierarchy (`AC-16`).
  public func messageComposerStyle<S: MessageComposerStyle & Sendable>(_ style: S) -> some View {
    environment(\.messageComposerStyle, AnyMessageComposerStyle(style))
  }
}
