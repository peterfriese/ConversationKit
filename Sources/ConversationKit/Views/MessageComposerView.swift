//
// MessageComposerView.swift
// ConversationKit
//
// Created by Peter Friese on 03.07.25.
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

extension EnvironmentValues {
  @Entry var onSubmitAction: () -> Void = {}
  @Entry var disableAttachments: Bool = false
  @Entry var attachmentActions: AnyView = AnyView(EmptyView())
}

extension View {
  public func onSubmitAction(_ action: @escaping () -> Void) -> some View {
    environment(\.onSubmitAction, action)
  }
  
  public func disableAttachments(_ disable: Bool = true) -> some View {
    environment(\.disableAttachments, disable)
  }
  
  public func attachmentActions<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    environment(\.attachmentActions, AnyView(content()))
  }
}

struct MessageComposerView: View {
  @Environment(\.onSubmitAction) private var onSubmitAction
  @Environment(\.disableAttachments) private var disableAttachments
  @Environment(\.attachmentActions) private var attachmentActions
  
  @Binding var message: String
  
  var body: some View {
    if #available(iOS 26.0, *) {
      GlassEffectContainer {
        HStack(alignment: .bottom) {
          if !disableAttachments {
            Menu {
              attachmentActions
            } label: {
              Image(systemName: "plus")
            }
            .controlSize(.large)
            .buttonBorderShape(.circle)
            .glassEffect(.regular.interactive(), in: .circle)
          }
          
          HStack(alignment: .bottom) {
            TextField("Enter a message", text: $message, axis: .vertical)
              .frame(minHeight: 32)
              .padding(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 0))
              .onSubmit(of: .text) { onSubmitAction() }
            
            Button(action: { onSubmitAction() }) {
              Image(systemName: "arrow.up")
            }
            .buttonStyle(.borderedProminent)
            .padding(EdgeInsets(top: 7, leading: 0, bottom: 7, trailing: 7))
          }
          .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20.0))
          .offset(x: -5.0, y: 0.0)
        }
      }
      .padding(.horizontal, 8)
      .padding(.bottom, 8)
    } else {
      HStack {
        TextField("Enter a message", text: $message, axis: .vertical)
          .textFieldStyle(.automatic)
          .onSubmit(of: .text) { onSubmitAction() }
        Button(action: { onSubmitAction() }) {
          Image(systemName: "arrow.up.circle.fill")
            .font(.title)
        }
      }
      .padding(.top, 8)
      .padding([.horizontal, .bottom], 16)
      .background(.thinMaterial)
    }
  }
}

#Preview("Short message") {
  @Previewable @State var message = "Why, hello!"
  @Previewable @State var foo = false

  NavigationStack {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 10) {
          HStack {
            Text("Hello there!")
              .padding(10)
              .background(Color.blue.opacity(0.8))
              .cornerRadius(10)
              .foregroundColor(.white)
            Spacer()
          }

          Spacer()
        }
        .padding(.horizontal, 8)
      }

      MessageComposerView(message: $message)
        .padding(.bottom, 8)
        .padding(.horizontal, 8)
        .disableAttachments()
        // Example of providing custom attachment actions
        .attachmentActions {
            Button(action: {
              print("You tapped the custom action 1!")
              foo.toggle()
            }) {
              Label("Custom Action 1", systemImage: foo ? "star" : "star.slash")
            }
            Button(action: {
              print("You tapped the custom action 2!")
            }) {
                Label("Custom Action 2", systemImage: "heart")
            }
        }
    }
    .navigationTitle("Chat")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview("Long message") {
  @Previewable @State var message =
    """
      Chatting has become a staple of modern communication. It’s quick, easy, and often more convenient than a phone call. People can share thoughts, jokes, and updates in real-time, no matter the distance.
    """

  NavigationStack {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 10) {
          HStack {
            Text("Hello there!")
              .padding(10)
              .background(Color.blue.opacity(0.8))
              .cornerRadius(10)
              .foregroundColor(.white)
            Spacer()
          }

          Spacer()
        }
        .padding(.horizontal, 8)
      }

      MessageComposerView(message: $message)
        .padding(.bottom, 8)
        .padding(.horizontal, 8)
    }
    .navigationTitle("Chat")
    .navigationBarTitleDisplayMode(.inline)
  }
}

