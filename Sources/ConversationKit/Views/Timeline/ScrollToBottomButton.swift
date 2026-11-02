//
//  ScrollToBottomButton.swift
//  ConversationKit
//
//  Floating Liquid Glass scroll-to-bottom button with >80pt / <24pt hysteresis state machine (F-10, AC-10, AC-14).
//

import Foundation
import SwiftUI

// MARK: - Accessibility Identifier Extensions

extension ConversationAccessibilityID {
  /// Alias for `scrollToBottomButton` (`"timeline.scrollToBottomButton"`).
  public static let timelineScrollToBottomButton = scrollToBottomButton
}

// MARK: - ScrollToBottomButton (`F-10`, `AC-10`, `AC-14`)

/// Floating Liquid Glass button overlaid above the message composer when the user scrolls away from
/// the bottom of the timeline or when a streaming response overflows below the viewport (`F-10`, `AC-10`, `AC-14`).
///
/// ### Hysteresis State Machine (`AC-14`)
/// `ScrollToBottomButton.shouldShow(currentState:distanceFromBottom:showThreshold:hideThreshold:)`
/// implements a deadband between `24pt` and `80pt` so small scroll fluctuations near the threshold
/// never cause rapid button flicker:
/// - Transitions `false -> true` only when `distanceFromBottom > 80pt`.
/// - Stays `true` while `distanceFromBottom >= 24pt`, transitioning `true -> false` only when `< 24pt`.
@MainActor
public struct ScrollToBottomButton: View {
  /// Indicates whether new or streaming content exists below the visible fold.
  public let hasUnreadBelowFold: Bool

  /// Callback invoked on `@MainActor` when the user taps the button.
  public let action: @MainActor () -> Void

  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  /// Creates a `ScrollToBottomButton`.
  ///
  /// - Parameters:
  ///   - hasUnreadBelowFold: When `true`, expands the button into a capsule with a subtle unread indicator dot.
  ///   - action: Closure invoked on tap to smoothly scroll to the bottom of the timeline.
  public init(
    hasUnreadBelowFold: Bool = false,
    action: @escaping @MainActor () -> Void
  ) {
    self.hasUnreadBelowFold = hasUnreadBelowFold
    self.action = action
  }

  /// Evaluates the hysteresis state machine for showing or hiding `ScrollToBottomButton` (`§3.4.3`, `AC-14`).
  ///
  /// - Parameters:
  ///   - currentState: Whether the scroll-to-bottom button is currently visible.
  ///   - distanceFromBottom: Current vertical distance in points from the bottom of the scroll content.
  ///   - showThreshold: Distance threshold above which the button appears (`80pt` by default).
  ///   - hideThreshold: Distance threshold below which the button hides (`24pt` by default).
  /// - Returns: The next visibility state (`Bool`).
  public nonisolated static func shouldShow(
    currentState: Bool,
    distanceFromBottom: CGFloat,
    showThreshold: CGFloat = 80,
    hideThreshold: CGFloat = 24
  ) -> Bool {
    if currentState {
      return distanceFromBottom >= hideThreshold
    } else {
      return distanceFromBottom > showThreshold
    }
  }

  public var body: some View {
    GlassEffectContainer(spacing: 8) {
      buttonContent
    }
  }

  @ViewBuilder
  private var buttonContent: some View {
    let baseButton = Button {
      PlatformHapticEvent.triggerHaptic(.selection)
      action()
    } label: {
      HStack(spacing: 6) {
        if hasUnreadBelowFold {
          Circle()
            .fill(Color.accentColor)
            .frame(width: 6, height: 6)
        }

        Image(systemName: "arrow.down")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.primary)
      }
      .padding(.horizontal, hasUnreadBelowFold ? 14 : 0)
      .frame(width: hasUnreadBelowFold ? nil : 40, height: 40)
      .fixedSize(horizontal: true, vertical: false)
      .contentShape(hasUnreadBelowFold ? AnyShape(Capsule()) : AnyShape(Circle()))
    }
    .buttonStyle(.plain)
    .fixedSize()
    .accessibilityIdentifier(ConversationAccessibilityID.timelineScrollToBottomButton)
    .accessibilityLabel(hasUnreadBelowFold ? "Scroll to latest message" : "Scroll to bottom")
    .accessibilityHint("Scrolls to the bottom of the conversation")

    if reduceTransparency {
      if hasUnreadBelowFold {
        baseButton
          .background(Color.platformSecondaryBackground, in: Capsule())
          .overlay {
            Capsule()
              .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
          }
          .fixedSize()
      } else {
        baseButton
          .background(Color.platformSecondaryBackground, in: Circle())
          .overlay {
            Circle()
              .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
          }
          .fixedSize()
      }
    } else {
      if hasUnreadBelowFold {
        baseButton
          .glassEffect(.regular.interactive(), in: .capsule)
          .fixedSize()
      } else {
        baseButton
          .glassEffect(.regular.interactive(), in: .circle)
          .fixedSize()
      }
    }
  }
}

#Preview("ScrollToBottomButton") {
  HStack(spacing: 20) {
    ScrollToBottomButton(hasUnreadBelowFold: false) {}
    ScrollToBottomButton(hasUnreadBelowFold: true) {}
  }
  .padding()
}
