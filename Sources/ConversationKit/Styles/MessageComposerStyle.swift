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
  /// Vertical-growing prompt text field.
  public let textField: AnyView

  /// Leading `+` menu trigger button for adding photos, files, or custom attachment actions.
  public let attachmentButton: AnyView?

  /// Horizontal scroll strip displaying pending `ConversationAttachment` cards with upload progress rings.
  public let attachmentsTray: AnyView?

  /// Horizontal scroll bar displaying active `/command` and `@mention` `ComposerToken` pills.
  public let tokensBar: AnyView?

  /// Integrated model selector menu pill (`ComposerModelOption`).
  public let modelSelector: AnyView?

  /// Toggleable capability chips bar (`Think`, `Search`, `Image`, etc.).
  public let capabilitiesBar: AnyView?

  /// Optional voice/dictation button.
  public let dictationButton: AnyView?

  /// Trailing primary action button (morphs between Send and cooperative Stop).
  public let submitButton: AnyView

  /// Focus-driven keyboard dismiss button (`keyboard.chevron.compact.down`) shown on iOS when `isFocused` is `true` (`F-11`, `AC-15`).
  public let dismissKeyboardButton: AnyView?

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
    capabilitiesBar: AnyView? = nil,
    dictationButton: AnyView? = nil,
    submitButton: AnyView,
    dismissKeyboardButton: AnyView? = nil,
    isFocused: Bool = false,
    isGenerating: Bool = false,
    canSubmit: Bool = false,
    hasAttachments: Bool? = nil,
    hasTokens: Bool? = nil,
    hasModels: Bool? = nil,
    hasCapabilities: Bool? = nil
  ) {
    self.textField = textField
    self.attachmentButton = attachmentButton
    self.attachmentsTray = attachmentsTray
    self.tokensBar = tokensBar
    self.modelSelector = modelSelector
    self.capabilitiesBar = capabilitiesBar
    self.dictationButton = dictationButton
    self.submitButton = submitButton
    self.dismissKeyboardButton = dismissKeyboardButton
    self.isFocused = isFocused
    self.isGenerating = isGenerating
    self.canSubmit = canSubmit
    self.hasAttachments = hasAttachments ?? (attachmentsTray != nil)
    self.hasTokens = hasTokens ?? (tokensBar != nil)
    self.hasModels = hasModels ?? (modelSelector != nil)
    self.hasCapabilities = hasCapabilities ?? (capabilitiesBar != nil)
  }
}

// MARK: - ClassicGlassMessageComposerStyle (.classicGlass / .automatic)

/// Default Liquid Glass composer style featuring a classic single-row rounded pill (`cornerRadius: 22`)
/// inside `GlassEffectContainer`, housing the leading `+` attachment button, growing prompt text field,
/// optional model selector, keyboard dismiss, and send/stop button in a bottom-aligned input row (~48pt empty height).
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
/// `attachmentButton`, `modelSelector`, `Spacer()`, `dismissKeyboardButton` (when focused), and `submitButton` (when `canSubmit || isGenerating`).
public struct CardGlassMessageComposerStyle: MessageComposerStyle, Sendable {
  /// Creates a two-row card Liquid Glass composer style.
  public nonisolated init() {}

  @MainActor
  public func makeBody(configuration: Configuration) -> some View {
    CardGlassComposerBody(configuration: configuration)
  }
}

// MARK: - ClassicGlassComposerBody

private struct ClassicGlassComposerBody: View {
  let configuration: MessageComposerStyleConfiguration

  @Namespace private var glassNamespace
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private let controlDiameter: CGFloat = 34
  private let pillCornerRadius: CGFloat = 22

  private var showsSubmitButton: Bool {
    configuration.canSubmit || configuration.isGenerating
  }

  private var hasTrailingControls: Bool {
    configuration.hasModels ||
    configuration.hasCapabilities ||
    configuration.dictationButton != nil ||
    configuration.isFocused ||
    showsSubmitButton
  }

  var body: some View {
    GlassEffectContainer(spacing: 8) {
      classicPill
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
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
        .padding(.top, (configuration.hasAttachments || configuration.hasTokens) ? 0 : 7)
        .padding(.bottom, 7)
        .padding(.horizontal, 7)
    }

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
        .glassEffectID("composer.classicPanel", in: glassNamespace)
    }
  }

  @ViewBuilder
  private var mainInputRow: some View {
    HStack(alignment: .bottom, spacing: 6) {
      if let attachmentButton = configuration.attachmentButton {
        attachmentButton
          .frame(width: controlDiameter, height: controlDiameter)
      }

      configuration.textField
        .frame(maxWidth: .infinity, minHeight: controlDiameter, alignment: .leading)
        .padding(.leading, configuration.attachmentButton == nil ? 8 : 2)
        .padding(.trailing, hasTrailingControls ? 2 : 8)

      if (configuration.hasModels || configuration.hasCapabilities), let modelSelector = configuration.modelSelector {
        modelSelector
          .frame(minHeight: controlDiameter)
          .fixedSize(horizontal: true, vertical: false)
          .layoutPriority(1)
      }

      HStack(alignment: .bottom, spacing: 6) {
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
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
      }
      .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: configuration.isFocused)
      .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: showsSubmitButton)
    }
  }
}

// MARK: - CardGlassComposerBody

private struct CardGlassComposerBody: View {
  let configuration: MessageComposerStyleConfiguration

  @Namespace private var glassNamespace
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private let controlDiameter: CGFloat = 34
  private let cardCornerRadius: CGFloat = 24

  private var showsSubmitButton: Bool {
    configuration.canSubmit || configuration.isGenerating
  }

  var body: some View {
    GlassEffectContainer(spacing: 10) {
      cardPanel
    }
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

      HStack(alignment: .center, spacing: 8) {
        if let attachmentButton = configuration.attachmentButton {
          attachmentButton
            .frame(width: controlDiameter, height: controlDiameter)
        }

        if (configuration.hasModels || configuration.hasCapabilities), let modelSelector = configuration.modelSelector {
          modelSelector
            .frame(minHeight: controlDiameter)
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(1)
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
              .transition(.scale(scale: 0.8).combined(with: .opacity))
          }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: configuration.isFocused)
        .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: showsSubmitButton)
      }
      .padding(.horizontal, 12)
      .padding(.bottom, 10)
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
        .glassEffectID("composer.cardPanel", in: glassNamespace)
    }
  }
}

// MARK: - CompactGlassMessageComposerStyle (.compactGlass)

/// Single-row compact capsule Liquid Glass composer style for secondary sheets, popovers, and inspectors (`AC-16`).
///
/// Houses all controls (`attachmentButton`, `textField`, `modelSelector`, `dismissKeyboardButton`,
/// and `submitButton`) inside a single unified Liquid Glass capsule.
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

  @Namespace private var glassNamespace
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private let controlDiameter: CGFloat = 32

  private var showsSubmitButton: Bool {
    configuration.canSubmit || configuration.isGenerating
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      if configuration.hasAttachments, let attachmentsTray = configuration.attachmentsTray {
        attachmentsTray
          .padding(.horizontal, 4)
      }

      if configuration.hasTokens, let tokensBar = configuration.tokensBar {
        tokensBar
          .padding(.horizontal, 4)
      }

      GlassEffectContainer(spacing: 8) {
        capsulePill
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
  }

  @ViewBuilder
  private var capsulePill: some View {
    let rowContent = HStack(alignment: .center, spacing: 8) {
      if let attachmentButton = configuration.attachmentButton {
        attachmentButton
          .frame(width: controlDiameter, height: controlDiameter)
      }

      configuration.textField
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)

      if (configuration.hasModels || configuration.hasCapabilities), let modelSelector = configuration.modelSelector {
        modelSelector
          .fixedSize(horizontal: true, vertical: false)
          .layoutPriority(1)
      }

      HStack(alignment: .center, spacing: 6) {
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
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
      }
      .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: configuration.isFocused)
      .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: showsSubmitButton)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)

    if reduceTransparency {
      rowContent
        .background(Color.platformSecondaryBackground, in: Capsule())
        .overlay {
          Capsule()
            .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
        }
    } else {
      rowContent
        .glassEffect(.regular.interactive(), in: .capsule)
        .glassEffectID("composer.compactCapsule", in: glassNamespace)
    }
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
}

extension View {
  /// Sets the style for `MessageComposerView` within this view hierarchy (`AC-16`).
  public func messageComposerStyle<S: MessageComposerStyle & Sendable>(_ style: S) -> some View {
    environment(\.messageComposerStyle, AnyMessageComposerStyle(style))
  }
}
