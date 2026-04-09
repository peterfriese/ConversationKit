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

