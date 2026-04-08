//
// ConversationEnvironment.swift
// ConversationKit
//
// Created by Peter Friese on 08.04.26.
//

import SwiftUI

// MARK: - Message Actions

public extension EnvironmentValues {
  @Entry var messageActions: ((any Message) -> AnyView)?
}

public extension View {
  /// Defines a custom view to be displayed below AI messages (e.g. thumbs up/down, copy, regenerate).
  /// - Parameter actions: A closure that takes a `Message` and returns a View.
  func messageActions<V: View>(@ViewBuilder actions: @escaping (any Message) -> V) -> some View {
    environment(\.messageActions, { message in AnyView(actions(message)) })
  }
}

// MARK: - Conversation Disclaimer

public extension EnvironmentValues {
  @Entry var conversationDisclaimer: AnyView?
}

public extension View {
  /// Defines a custom disclaimer view to be displayed at the bottom of the conversation thread,
  /// but only if the most recent message is from the AI (`.other`).
  func conversationDisclaimer<V: View>(@ViewBuilder disclaimer: @escaping () -> V) -> some View {
    environment(\.conversationDisclaimer, AnyView(disclaimer()))
  }
}

// MARK: - Scroll To Bottom Button Style

public struct ScrollToBottomButtonConfiguration {
  public let action: () -> Void
}

public protocol ScrollToBottomButtonStyle {
  associatedtype Body: View
  @ViewBuilder func makeBody(configuration: ScrollToBottomButtonConfiguration) -> Body
}

public struct DefaultScrollToBottomButtonStyle: ScrollToBottomButtonStyle {
  public func makeBody(configuration: ScrollToBottomButtonConfiguration) -> some View {
    Button(action: configuration.action) {
      Image(systemName: "chevron.down.circle.fill")
        .resizable()
        .frame(width: 32, height: 32)
        .foregroundColor(.secondary)
        .background(Circle().fill(Color.platformSecondaryBackground))
        .shadow(radius: 4, y: 2)
    }
    .padding()
  }
}

public extension EnvironmentValues {
  @Entry var scrollToBottomButtonStyle: AnyScrollToBottomButtonStyle = AnyScrollToBottomButtonStyle(DefaultScrollToBottomButtonStyle())
}

public struct AnyScrollToBottomButtonStyle: ScrollToBottomButtonStyle {
  private let _makeBody: (ScrollToBottomButtonConfiguration) -> AnyView
  
  public init<S: ScrollToBottomButtonStyle>(_ style: S) {
    self._makeBody = { configuration in AnyView(style.makeBody(configuration: configuration)) }
  }
  
  public func makeBody(configuration: ScrollToBottomButtonConfiguration) -> some View {
    _makeBody(configuration)
  }
}

public extension View {
  /// Sets the style for the scroll-to-bottom Floating Action Button (FAB).
  func scrollToBottomButtonStyle<S: ScrollToBottomButtonStyle>(_ style: S) -> some View {
    environment(\.scrollToBottomButtonStyle, AnyScrollToBottomButtonStyle(style))
  }
}
