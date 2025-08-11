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
import FirebaseAI
import SwiftUI

@Observable
class FirebaseAILogicChatViewModel {
  var messages: [Message] = []

  private let model: GenerativeModel
  private let chat: Chat

  init() {
    let firstMessage = Message(
      content: "Hello! How can I help you today?",
      participant: .other
    )
    self.messages = [firstMessage]

    model =
      FirebaseAI
      .firebaseAI(backend: .googleAI())
      .generativeModel(modelName: "gemini-2.5-flash")

    let history = [
      ModelContent(role: "model", parts: firstMessage.content)
    ]
    chat = model.startChat(history: history)
  }

  func sendMessage(_ message: Message) async {
    var responseText: String
    do {
      let response = try await chat.sendMessage(message.content)
      responseText = response.text ?? ""
    } catch {
      responseText =
      "I'm sorry, I don't understand that. Please try again. \(error.localizedDescription)"
    }
    let response = Message(
      content: responseText,
      participant: .other
    )
    messages.append(response)
  }
}

struct FirebaseAILogicChatView: View {
  @State private var viewModel = FirebaseAILogicChatViewModel()

  @ViewBuilder
  private func messageContent(for message: Message) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      MessageView(
        message: message.content ?? "",
        imageURL: message.imageURL ?? "",
        participant: message.participant,
        metadata: message.metadata
      )
    }
  }

  var body: some View {
    NavigationStack {
      ConversationView(messages: $viewModel.messages) { message in
        messageContent(for: message)
      }
      .attachmentActions {
        Button(action: {}) {
          Label("Photos", systemImage: "photo.on.rectangle.angled")
        }
        Button(action: {}) {
          Label("Camera", systemImage: "camera")
        }
      }
      .navigationTitle("Chat")
      .navigationBarTitleDisplayMode(.inline)
      .onSendMessage { message in
        await viewModel.sendMessage(message)
      }
    }
  }
}

#Preview {
  FirebaseAILogicChatView()
}
