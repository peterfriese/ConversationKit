//
// FirebaseAILogicChatView.swift
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
import SwiftUI
import FirebaseAI

struct FirebaseAILogicChatView: View {
  @State private var messages: [Message] = [
    Message(content: "Hello! How can I help you today?", participant: .other)
  ]
  
  let model = {
    let ai = FirebaseAI.firebaseAI(backend: .googleAI())
    let model = ai.generativeModel(modelName: "gemini-2.5-flash")
    return model
  }()
  
  var body: some View {
    NavigationStack {
      ConversationView(messages: $messages)
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onSendMessage { message in
          Task {
            if let content = message.content {
              var responseText: String
              do {
                let response = try await model.generateContent(content)
                responseText = response.text ?? ""
              }
              catch {
                responseText = "I'm sorry, I don't understand that. Please try again. \(error.localizedDescription)"
              }
              let response = Message(content: responseText, participant: .other)
              messages.append(response)
            }
          }
        }
    }
  }
}

#Preview {
  FirebaseAILogicChatView()
}
