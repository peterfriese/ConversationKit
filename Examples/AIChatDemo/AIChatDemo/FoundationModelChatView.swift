//
// FoundationModelChatView.swift
// AIChatDemo
//
// Created by Peter Friese on 07.07.25.
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

import ConversationKit
import FoundationModels
import SwiftUI

@available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *)
struct FoundationModelChatView: View {
  @State private var messages: [DefaultMessage] = [
    DefaultMessage(content: "Hello! How can I help you today?", participant: .other)
  ]

  private let session = LanguageModelSession()

  var body: some View {
    NavigationStack {
      ConversationView(messages: $messages)
        .onSendMessage { submission in
          messages.append(submission.message)

          let responseMessage: DefaultMessage
          do {
            let response = try await session.respond(to: submission.text)
            responseMessage = DefaultMessage(
              content: response.content,
              participant: .other
            )
          } catch {
            responseMessage = DefaultMessage(
              content: "An error has occurred. Try again later.",
              participant: .other,
              error: error
            )
          }
          messages.append(responseMessage)
        }
        .navigationTitle("On-Device Chat")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
  }
}

#Preview {
  if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
    FoundationModelChatView()
  } else {
    Text("The Apple Foundation Models framework requires iOS 26+.")
  }
}
