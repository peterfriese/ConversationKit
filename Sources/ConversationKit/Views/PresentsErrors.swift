//
//  PresentsErrors.swift
//  ConversationKit
//
//  Created by Peter Friese on 12.08.25.
//

import SwiftUI

struct PresentsErrorsInSheetModifier<ErrorContent: View>: ViewModifier {
  @State private var error: Error?

  // This is the user-provided view for displaying the error
  let errorContent: (Error) -> ErrorContent

  // Helper binding for .sheet
  private var isErrorPresented: Binding<Bool> {
    Binding(
      get: { error != nil },
      set: { newValue in
        if !newValue {
          error = nil
        }
      }
    )
  }

  func body(content: Content) -> some View {
    content
      .environment(\.presentErrorAction, PresentErrorAction { error in
        self.error = error
      })
      .sheet(isPresented: isErrorPresented) {
        if let error {
          errorContent(error)
        }
      }
  }
}

public extension View {
  func presentsErrorsInSheet() -> some View {
    self.modifier(PresentsErrorsInSheetModifier { error in
      Text(error.localizedDescription)
    })
  }

  func presentsErrorsInSheet<ErrorContent: View>(
    @ViewBuilder content: @escaping (Error) -> ErrorContent
  ) -> some View {
    self.modifier(PresentsErrorsInSheetModifier(errorContent: content))
  }
}
