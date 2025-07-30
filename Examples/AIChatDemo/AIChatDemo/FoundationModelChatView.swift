//
// ContentView.swift
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

@available(iOS 26.0, macCatalyst 26.0, *)
struct FoundationModelChatView {
  @State private var messages: [Message] = [
    Message(content: "Hello! How can I help you today?", participant: .other)
  ]
  
  let session = LanguageModelSession()
}

@available(iOS 26.0, macCatalyst 26.0, *)
extension FoundationModelChatView: View {
  var body: some View {
    NavigationStack {
      ConversationView(messages: $messages)
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onSendMessage { message in
          if let content = message.content {
            var responseText: String
            do {
              let response = try await session.respond(to: content)
              responseText = response.content
            } catch {
              responseText =
                "I'm sorry, I don't understand that. Please try again. \(error.localizedDescription)"
            }
            let response = Message(content: responseText, participant: .other)
            messages.append(response)
          }
        }
    }
  }
}

#Preview {
  if #available(iOS 26.0, macCatalyst 26.0, *) {
    FoundationModelChatView()
  } else {
    Text("The Apple Foundation Models framework requires iOS 26+.")
  }
}
