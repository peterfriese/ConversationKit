//
//  OnErrorModifier.swift
//  ConversationKit
//
//  Created by Peter Friese on 12.08.25.
//

import SwiftUI

private struct OnErrorModifier: ViewModifier {
  let action: (Error) -> Void
  
  func body(content: Content) -> some View {
    content
      .environment(\.presentErrorAction, PresentErrorAction(handler: action))
  }
}

public extension View {
  /// Registers a callback to be performed when an error is presented.
  ///
  /// Use this modifier to catch errors that are passed up from `ConversationKit` views,
  /// such as when a user taps the information button on a message that contains an error.
  ///
  /// In your action closure, you can then update your view's state to present the error
  /// using a standard SwiftUI presentation modifier, like `.sheet(item:)` or `.alert(item:)`.
  ///
  /// - Parameter action: A closure that takes the `Error` as its sole parameter.
  func onError(perform action: @escaping (Error) -> Void) -> some View {
    self.modifier(OnErrorModifier(action: action))
  }
}
