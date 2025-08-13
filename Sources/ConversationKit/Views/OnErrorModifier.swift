//
//  OnErrorModifier.swift
//  ConversationKit
//
//  Created by Peter Friese on 12.08.25.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
