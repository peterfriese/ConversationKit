//
//  UserMessageBubbleStyle.swift
//  ConversationKit
//
//  SwiftUI Style protocol and built-in non-glass bubble styles for user messages (F-3, AC-5, AC-10, AC-16).
//

import SwiftUI

// MARK: - UserMessageBubbleStyle Protocol

/// Customizes the right-aligned user prompt bubble in `MessageView` (`F-3`, `AC-5`, `AC-16`, `[MF-1]`).
///
/// - Important: Assistant (`.other`) messages never use this style and always render full-width on the
///   background canvas (`F-3`). All `UserMessageBubbleStyle` implementations must use opaque or tinted
///   semantic fills (`Color.platformUserBubbleFill`, `Color.platformSecondaryBackground`) and NEVER
///   apply Liquid Glass inside scrolling timeline cells (`AC-10`, `[MF-1]`).
///
/// ### Usage
/// ```swift
/// // Layer 1 (Troposphere): Default .tailedBubble user message style
/// ConversationView(messages: $messages)
///
/// // Layer 2 (Stratosphere): Switch to .roundedCard or .capsule bubble style
/// ConversationView(messages: $messages)
///   .userMessageBubbleStyle(.roundedCard)
/// ```
@MainActor
public protocol UserMessageBubbleStyle: DynamicProperty, Sendable {
  /// The view type representing the body of this user message bubble style.
  associatedtype Body: View

  /// Convenience alias for `UserMessageBubbleStyleConfiguration`.
  typealias Configuration = UserMessageBubbleStyleConfiguration

  /// Creates the view representing the styled user message bubble.
  @ViewBuilder
  @MainActor
  func makeBody(configuration: Configuration) -> Body
}

// MARK: - UserMessageBubbleStyleConfiguration

/// The subview slots and content flags passed to a `UserMessageBubbleStyle` implementation (`§3.3.3`).
@MainActor
public struct UserMessageBubbleStyleConfiguration {
  /// The primary text/markdown content view of the user's prompt.
  public let content: AnyView

  /// Optional view rendering attached photos (`1–4` collage grid with `+N` badge) and file chips.
  public let attachmentsContent: AnyView?

  /// Optional view rendering structured `/command` and `@mention` `ComposerToken` pills.
  public let tokensContent: AnyView?

  /// Indicates whether the user message has non-empty text content.
  public let hasText: Bool

  /// Indicates whether the user message has one or more attachments.
  public let hasAttachments: Bool

  /// Indicates whether the user message has one or more structured tokens.
  public let hasTokens: Bool

  /// Creates a `UserMessageBubbleStyleConfiguration` using `attachmentsContent` and `tokensContent`.
  public init(
    content: AnyView,
    attachmentsContent: AnyView? = nil,
    tokensContent: AnyView? = nil,
    hasText: Bool = true,
    hasAttachments: Bool? = nil,
    hasTokens: Bool? = nil
  ) {
    self.content = content
    self.attachmentsContent = attachmentsContent
    self.tokensContent = tokensContent
    self.hasText = hasText
    self.hasAttachments = hasAttachments ?? (attachmentsContent != nil)
    self.hasTokens = hasTokens ?? (tokensContent != nil)
  }
}

// MARK: - TailedBubbleUserMessageStyle (.tailedBubble / .standard / .automatic)

/// Default asymmetric right-aligned user message bubble style featuring `20pt` outer corners
/// and a `6pt` bottom-trailing corner (`UnevenRoundedRectangle`) filled with `Color.platformUserBubbleFill` (`AC-5`, `AC-10`, `AC-16`).
public struct TailedBubbleUserMessageStyle: UserMessageBubbleStyle, Sendable {
  /// Creates the default tailed user message bubble style.
  public nonisolated init() {}

  @MainActor
  public func makeBody(configuration: Configuration) -> some View {
    let bubbleShape = UnevenRoundedRectangle(
      topLeadingRadius: 20,
      bottomLeadingRadius: 20,
      bottomTrailingRadius: 6,
      topTrailingRadius: 20,
      style: .continuous
    )

    VStack(alignment: .trailing, spacing: 8) {
      if configuration.hasAttachments, let attachmentsContent = configuration.attachmentsContent {
        attachmentsContent
      }

      if configuration.hasText || configuration.hasTokens {
        VStack(alignment: .leading, spacing: 6) {
          if configuration.hasTokens, let tokensContent = configuration.tokensContent {
            tokensContent
          }

          if configuration.hasText {
            configuration.content
              .foregroundStyle(.primary)
          }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.platformUserBubbleFill, in: bubbleShape)
        .overlay {
          bubbleShape
            .strokeBorder(Color.accentColor.opacity(0.22), lineWidth: 0.5)
        }
      }
    }
  }
}

// MARK: - RoundedCardUserMessageStyle (.roundedCard)

/// Continuous `20pt` concentric rounded rectangle card style for structured user prompts (`AC-10`, `AC-16`).
public struct RoundedCardUserMessageStyle: UserMessageBubbleStyle, Sendable {
  /// Creates a rounded card user message bubble style.
  public nonisolated init() {}

  @MainActor
  public func makeBody(configuration: Configuration) -> some View {
    let cardShape = RoundedRectangle(cornerRadius: 20, style: .continuous)

    VStack(alignment: .leading, spacing: 8) {
      if configuration.hasAttachments, let attachmentsContent = configuration.attachmentsContent {
        attachmentsContent
      }

      if configuration.hasTokens, let tokensContent = configuration.tokensContent {
        tokensContent
      }

      if configuration.hasText {
        configuration.content
          .foregroundStyle(.primary)
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 11)
    .background(Color.platformSecondaryBackground, in: cardShape)
    .overlay {
      cardShape
        .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
    }
  }
}

// MARK: - CapsuleUserMessageStyle (.capsule)

/// Pill/capsule user message bubble style for single-line prompts, gracefully expanding for multi-line content (`AC-10`, `AC-16`).
public struct CapsuleUserMessageStyle: UserMessageBubbleStyle, Sendable {
  /// Creates a capsule user message bubble style.
  public nonisolated init() {}

  @MainActor
  public func makeBody(configuration: Configuration) -> some View {
    let bubbleShape = RoundedRectangle(cornerRadius: 24, style: .continuous)

    VStack(alignment: .trailing, spacing: 8) {
      if configuration.hasAttachments, let attachmentsContent = configuration.attachmentsContent {
        attachmentsContent
      }

      if configuration.hasText || configuration.hasTokens {
        VStack(alignment: .leading, spacing: 6) {
          if configuration.hasTokens, let tokensContent = configuration.tokensContent {
            tokensContent
          }

          if configuration.hasText {
            configuration.content
              .foregroundStyle(.primary)
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.platformUserBubbleFill, in: bubbleShape)
        .overlay {
          bubbleShape
            .strokeBorder(Color.accentColor.opacity(0.22), lineWidth: 0.5)
        }
      }
    }
  }
}

// MARK: - Static Style Presets

extension UserMessageBubbleStyle where Self == TailedBubbleUserMessageStyle {
  /// Default style: Asymmetric right-aligned bubble (`20pt` outer corners, `6pt` bottom-trailing corner).
  public nonisolated static var tailedBubble: TailedBubbleUserMessageStyle {
    TailedBubbleUserMessageStyle()
  }

  /// Alias for `.tailedBubble` preserving PRD parity (`[MF-1]`).
  public nonisolated static var standard: TailedBubbleUserMessageStyle {
    TailedBubbleUserMessageStyle()
  }

  /// Idiomatic SwiftUI alias for `.tailedBubble` (`[MF-1]`).
  public nonisolated static var automatic: TailedBubbleUserMessageStyle {
    TailedBubbleUserMessageStyle()
  }
}

extension UserMessageBubbleStyle where Self == RoundedCardUserMessageStyle {
  /// Continuous `20pt` concentric rounded rectangle card for structured prompt bubbles.
  public nonisolated static var roundedCard: RoundedCardUserMessageStyle {
    RoundedCardUserMessageStyle()
  }
}

extension UserMessageBubbleStyle where Self == CapsuleUserMessageStyle {
  /// Pill/capsule bubble for single-line prompts, gracefully expanding for multi-line text.
  public nonisolated static var capsule: CapsuleUserMessageStyle {
    CapsuleUserMessageStyle()
  }
}

// MARK: - Type-Erased AnyUserMessageBubbleStyle & Environment

/// A type-erased `UserMessageBubbleStyle` wrapper stored in `EnvironmentValues`.
@MainActor
public struct AnyUserMessageBubbleStyle: UserMessageBubbleStyle, Sendable {
  private let bodyBuilder: @MainActor @Sendable (UserMessageBubbleStyleConfiguration) -> AnyView

  /// Type-erases a concrete `UserMessageBubbleStyle`.
  public nonisolated init<S: UserMessageBubbleStyle & Sendable>(_ style: S) {
    self.bodyBuilder = { @MainActor configuration in
      AnyView(UserMessageBubbleStyleHost(style: style, configuration: configuration))
    }
  }

  @MainActor
  public func makeBody(configuration: Configuration) -> AnyView {
    bodyBuilder(configuration)
  }
}

private struct UserMessageBubbleStyleHost<S: UserMessageBubbleStyle>: View {
  let style: S
  let configuration: UserMessageBubbleStyleConfiguration

  var body: some View {
    style.makeBody(configuration: configuration)
  }
}

extension EnvironmentValues {
  /// The active `UserMessageBubbleStyle` in the environment (defaults to `.tailedBubble`).
  @Entry public var userMessageBubbleStyle: AnyUserMessageBubbleStyle = AnyUserMessageBubbleStyle(.tailedBubble)
}

extension View {
  /// Sets the style for right-aligned user message bubbles in `MessageView` within this view hierarchy (`AC-16`).
  public func userMessageBubbleStyle<S: UserMessageBubbleStyle & Sendable>(_ style: S) -> some View {
    environment(\.userMessageBubbleStyle, AnyUserMessageBubbleStyle(style))
  }
}
