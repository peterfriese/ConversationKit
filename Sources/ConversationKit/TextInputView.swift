//
// TextInputView.swift
// HandfulOfTypes
//
// Created by Peter Friese on 16.12.23.
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

struct TextInputViewSubmitHandler: EnvironmentKey {
  static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
  public var onSubmitAction: () -> Void {
    get { self[TextInputViewSubmitHandler.self] }
    set {
      let oldValue = self[TextInputViewSubmitHandler.self]
      self[TextInputViewSubmitHandler.self] = {
        oldValue()
        newValue()
      }
    }
  }
}

public extension View {
  func onSubmit(_ action: @escaping () -> Void) -> some View {
    environment(\.onSubmitAction, action)
  }
}

struct TextInputView: View {
  @Environment(\.onSubmitAction) private var onSubmitAction
  @Binding var message: String

  var body: some View {
    HStack {
      // When using the `axis` parameter, the [Enter] key doesn't submit the field
      TextField("Enter a message", text: $message, axis: .vertical)
        .textFieldStyle(.automatic)
//        .fontDesign(.monospaced)
//        .tint(.crtGreen)
        .onSubmit(of: .text) { onSubmitAction() }
      Button(action: { onSubmitAction() }) {
        Image(systemName: "arrow.up.circle.fill")
//          .tint(.crtGreen)
          .font(.title)
      }
    }
//    .padding(.vertical, 4)
//    .padding(.horizontal, 4)
    .padding(.top, 8)
    .padding([.horizontal, .bottom], 16)
    .background(.thinMaterial)

//    .background(
//      Rectangle()
//        .foregroundStyle(Color(uiColor: .systemBackground))
//        .edgesIgnoringSafeArea(.bottom)
//    )
  }
}

#Preview {
  @State var input = ""
  return TextInputView(message: $input)
}
