//
//  MessageActionBarView.swift
//  ConversationKit
//
//  Assistant message action bar with Copy (1.5s checkmark state), Regenerate,
//  Thumbs Up / Down feedback toggles, and native ShareLink (AC-10, AC-18).
//

import Foundation
import SwiftUI

// MARK: - Accessibility Identifier Extensions

extension ConversationAccessibilityID {
  /// Accessibility identifier for a message's Copy action button (`message.action.copy.<id>`).
  public static func messageCopyButton(_ id: String) -> String {
    "message.action.copy.\(id)"
  }

  /// Accessibility identifier for a message's Regenerate action button (`message.action.regenerate.<id>`).
  public static func messageRegenerateButton(_ id: String) -> String {
    "message.action.regenerate.\(id)"
  }

  /// Accessibility identifier for a message's Thumbs Up feedback button (`message.action.thumbsUp.<id>`).
  public static func messageThumbsUpButton(_ id: String) -> String {
    "message.action.thumbsUp.\(id)"
  }

  /// Accessibility identifier for a message's Thumbs Down feedback button (`message.action.thumbsDown.\(id)`).
  public static func messageThumbsDownButton(_ id: String) -> String {
    "message.action.thumbsDown.\(id)"
  }

  /// Accessibility identifier for a message's Share button (`message.action.share.<id>`).
  public static func messageShareButton(_ id: String) -> String {
    "message.action.share.\(id)"
  }
}

// MARK: - MessageActionBarView (`AC-18`)

/// Renders the interactive action bar below a completed assistant response (`AC-10`, `AC-18`).
///
/// Provides one-tap **Copy** (with a 1.5-second checkmark confirmation), **Regenerate**
/// (`@Environment(\.onRegenerateMessage)`), **Thumbs Up / Down** rating toggles
/// (`@Environment(\.onMessageFeedback)`), and native **Share** (`ShareLink(item: content)`).
///
/// - Important: Because `MessageActionBarView` lives inside scrolling timeline cells, it uses lightweight
///   semantic button styling and never applies Liquid Glass (`AC-10`).
@MainActor
public struct MessageActionBarView: View {
  /// Identifier of the assistant message associated with this action bar.
  public let messageID: String

  /// Plain or Markdown text content of the message for copying and sharing.
  public let content: String

  /// Optional external feedback rating on the message (`.thumbsUp` or `.thumbsDown`).
  public let feedback: MessageFeedback?

  @Environment(\.onRegenerateMessage) private var onRegenerateMessage
  @Environment(\.onMessageFeedback) private var onMessageFeedback

  @State private var didCopy: Bool = false
  @State private var localFeedback: MessageFeedback?

  /// Creates a `MessageActionBarView`.
  ///
  /// - Parameters:
  ///   - messageID: Unique identifier of the parent assistant message.
  ///   - content: Text content copied by Copy or shared by `ShareLink`.
  ///   - feedback: Optional current `MessageFeedback` state (`.thumbsUp` or `.thumbsDown`).
  public init(
    messageID: String,
    content: String,
    feedback: MessageFeedback? = nil
  ) {
    self.messageID = messageID
    self.content = content
    self.feedback = feedback
    self._localFeedback = State(initialValue: feedback)
  }

  private var effectiveFeedback: MessageFeedback? {
    localFeedback ?? feedback
  }

  public var body: some View {
    HStack(alignment: .center, spacing: 14) {
      copyButton
      regenerateButton
      thumbsUpButton
      thumbsDownButton
      shareButton

      Spacer(minLength: 0)
    }
    .padding(.top, 2)
    .onChange(of: feedback) { _, newValue in
      localFeedback = newValue
    }
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(ConversationAccessibilityID.messageActionBar(messageID))
  }

  // MARK: - Action Buttons

  private var copyButton: some View {
    Button {
      PlatformPasteboard.copyText(content)
      PlatformHapticEvent.triggerHaptic(.copySuccess)
      didCopy = true
      Task { @MainActor in
        try? await Task.sleep(for: .seconds(1.5))
        didCopy = false
      }
    } label: {
      Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(didCopy ? Color.green : Color.secondary)
        .frame(width: 28, height: 28)
        .contentShape(Rectangle())
        .contentTransition(.symbolEffect(.replace))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(ConversationAccessibilityID.messageCopyButton(messageID))
    .accessibilityLabel(didCopy ? "Copied" : "Copy message")
  }

  private var regenerateButton: some View {
    Button {
      PlatformHapticEvent.triggerHaptic(.selection)
      if let onRegenerateMessage {
        Task { @MainActor in
          await onRegenerateMessage(messageID)
        }
      }
    } label: {
      Image(systemName: "arrow.clockwise")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.secondary)
        .frame(width: 28, height: 28)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(ConversationAccessibilityID.messageRegenerateButton(messageID))
    .accessibilityLabel("Regenerate response")
  }

  private var thumbsUpButton: some View {
    let isSelected = (effectiveFeedback == .thumbsUp)
    return Button {
      toggleFeedback(.thumbsUp)
    } label: {
      Image(systemName: isSelected ? "hand.thumbsup.fill" : "hand.thumbsup")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
        .frame(width: 28, height: 28)
        .contentShape(Rectangle())
        .contentTransition(.symbolEffect(.replace))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(ConversationAccessibilityID.messageThumbsUpButton(messageID))
    .accessibilityLabel("Helpful response")
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
  }

  private var thumbsDownButton: some View {
    let isSelected = (effectiveFeedback == .thumbsDown)
    return Button {
      toggleFeedback(.thumbsDown)
    } label: {
      Image(systemName: isSelected ? "hand.thumbsdown.fill" : "hand.thumbsdown")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(isSelected ? Color.orange : Color.secondary)
        .frame(width: 28, height: 28)
        .contentShape(Rectangle())
        .contentTransition(.symbolEffect(.replace))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(ConversationAccessibilityID.messageThumbsDownButton(messageID))
    .accessibilityLabel("Unhelpful response")
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
  }

  private var shareButton: some View {
    ShareLink(item: content) {
      Image(systemName: "square.and.arrow.up")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.secondary)
        .frame(width: 28, height: 28)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(ConversationAccessibilityID.messageShareButton(messageID))
    .accessibilityLabel("Share message")
  }

  // MARK: - Helpers

  private func toggleFeedback(_ target: MessageFeedback) {
    PlatformHapticEvent.triggerHaptic(.selection)
    let updated: MessageFeedback? = (effectiveFeedback == target) ? nil : target
    localFeedback = updated
    onMessageFeedback?(messageID, updated)
  }
}

#Preview("MessageActionBarView") {
  VStack(alignment: .leading, spacing: 16) {
    MessageActionBarView(
      messageID: "msg-1",
      content: "Here is a concise summary of the architecture.",
      feedback: nil
    )

    MessageActionBarView(
      messageID: "msg-2",
      content: "Selected thumbs up state.",
      feedback: .thumbsUp
    )
  }
  .padding()
}
