//
//  WorkingStateView.swift
//  ConversationKit
//
//  Pre-first-token working indicator view styled via WorkingStateStyle.
//

import SwiftUI

/// Displays the pre-first-token working indicator when an assistant message has started streaming
/// (`content == nil` or `""`) before the first reasoning trace, tool call, or Markdown token arrives.
///
/// Styled via `WorkingStateStyle` (`.inline`, `.pill`, `.minimal`, or a custom `WorkingStateStyle`).
@MainActor
public struct WorkingStateView: View {
  /// Optional explicit title override. When `nil`, falls back to `@Environment(\.workingStateTitle)` (`"Working…"`).
  public let title: String?

  /// Optional message identifier used to scope the accessibility identifier (`message.working.<id>`).
  public let messageID: String?

  @Environment(\.workingStateStyle) private var workingStateStyle
  @Environment(\.workingStateTitle) private var environmentTitle
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// Creates a `WorkingStateView`.
  ///
  /// - Parameters:
  ///   - title: Optional explicit label text override. When `nil`, uses `@Environment(\.workingStateTitle)` (`"Working…"`).
  ///   - messageID: Optional parent message ID for accessibility identification.
  public init(
    title: String? = nil,
    messageID: String? = nil
  ) {
    self.title = title
    self.messageID = messageID
  }

  private var resolvedTitle: String {
    title ?? environmentTitle
  }

  public var body: some View {
    let currentTitle = resolvedTitle
    let configuration = WorkingStateStyleConfiguration(
      title: currentTitle,
      icon: AnyView(
        Image(systemName: "sparkles")
          .foregroundStyle(.tint)
          .symbolEffect(
            .pulse.byLayer,
            options: .repeating,
            isActive: !reduceMotion
          )
      ),
      label: AnyView(
        Text(currentTitle)
          .accessibilityLabel(currentTitle == "Working…" ? "Assistant is working" : currentTitle)
      )
    )

    workingStateStyle
      .makeBody(configuration: configuration)
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier(
        messageID.map(ConversationAccessibilityID.workingState) ?? ConversationAccessibilityID.workingState
      )
  }
}
