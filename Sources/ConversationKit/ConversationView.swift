//
// ConversationView.swift
// ChatKitSample
//
// Created by Peter Friese on 19.02.24.
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

public struct ConversationView: View {
  @State var messages: [Message]
  @State var message: String = ""

  public init(messages: [Message]) {
    self.messages = messages
  }

  public var body: some View {
    ZStack(alignment: .bottom) {
      List(messages) { message in
        MessageView(message: message.content, participant: message.participant)
      }
      .scrollContentBackground(.hidden)
      .listStyle(.plain)

      HStack(alignment: .bottom) {
        TextField("Enter your message here", text: $message, axis: .vertical)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .overlay {
            RoundedRectangle(
              cornerRadius: 8,
              style: .continuous
            )
            .stroke(Color(UIColor.systemFill), lineWidth: 1)
          }

        Button(action: {
          messages.append(Message(content: message, participant: .user))
        }) {
          Image(systemName: "arrow.up.circle.fill")
            .font(.title)
            .tint(Color(uiColor: .label))
        }
      }
      .padding(.top, 8)
      .padding([.horizontal, .bottom], 16)
      .background(.thinMaterial)
    }
  }
}

#Preview {
  NavigationStack {
    var messages: [Message] = [
      .init(content: "Hello, how are you?", participant: .other),
      .init(content: "Well, I am fine, how are you?", participant: .user),
      .init(content: "Not too bad. Not too bad after all.", participant: .other),
      .init(content: "Laboris officia aliqua eiusmod deserunt pariatur aliquip cillum proident excepteur qui pariatur consequat aute occaecat deserunt.", participant: .user),
      .init(content: "Laborum ea ad anim magna.", participant: .other),
      .init(content: "Esse aliquip laboris irure est voluptate aliquip non duis aute eu. Occaecat irure incididunt aute aute do sunt labore nisi esse nostrud amet labore enim mollit occaecat. Occaecat incididunt consectetur sint dolor deserunt exercitation mollit id culpa deserunt fugiat pariatur pariatur ullamco. Ex aliqua sit commodo enim qui commodo aliqua sint dolor laboris magna consequat adipisicing sunt.", participant: .user)
    ]
    ConversationView(messages: messages)
      .navigationTitle("Chat")
      .navigationBarTitleDisplayMode(.inline)
  }
}
