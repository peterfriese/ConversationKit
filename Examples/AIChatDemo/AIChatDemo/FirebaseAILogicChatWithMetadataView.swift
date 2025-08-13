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

struct ChatMessage: Message {
  var id: UUID = .init()
  
  var content: String?
  var imageURL: String?
  var participant: Participant
  var error: (any Error)?
  
  let usageMetadata: GenerateContentResponse.UsageMetadata?
  let finishReason: FinishReason?
  let citationMetadata: CitationMetadata?
  let groundingMetadata: GroundingMetadata?
  let promptFeedback: PromptFeedback?

  init(content: String? = nil,
       imageURL: String? = nil,
       participant: Participant,
       error: (any Error)? = nil,
       usageMetadata: GenerateContentResponse.UsageMetadata? = nil,
       finishReason: FinishReason? = nil,
       citationMetadata: CitationMetadata? = nil,
       groundingMetadata: GroundingMetadata? = nil,
       promptFeedback: PromptFeedback? = nil) {
    self.content = content
    self.imageURL = imageURL
    self.participant = participant
    self.usageMetadata = usageMetadata
    self.finishReason = finishReason
    self.citationMetadata = citationMetadata
    self.groundingMetadata = groundingMetadata
    self.promptFeedback = promptFeedback
  }

  init(content: String?, imageURL: String?, participant: Participant) {
    self.init(content: content,
              imageURL: imageURL,
              participant: participant,
              error: nil,
              usageMetadata: nil,
              finishReason: nil,
              citationMetadata: nil,
              groundingMetadata: nil,
              promptFeedback: nil)
  }
}

extension ChatMessage: Equatable {
  public static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
    lhs.id == rhs.id
  }
}

extension ChatMessage: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}


@Observable
class FirebaseAILogicChatWithMetadataViewModel {
  var messages: [ChatMessage] = []

  private let model: GenerativeModel
  private let chat: Chat

  init() {
    let firstMessage = ChatMessage(
      content: "Hello! How can I help you today?",
      participant: .other
    )
    self.messages = [firstMessage]

    model =
      FirebaseAI
      .firebaseAI(backend: .googleAI())
      .generativeModel(modelName: "gemini-2.5-flash")

    let history = [
      ModelContent(role: "model", parts: firstMessage.content ?? "")
    ]
    chat = model.startChat(history: history)
  }

  func sendMessage(_ message: any Message) async {
    if let chatMessage = message as? ChatMessage {
      messages.append(chatMessage)
    }
    var responseText: String
    var usageMetadata: GenerateContentResponse.UsageMetadata?
    var finishReason: FinishReason?
    var citationMetadata: CitationMetadata?
    var groundingMetadata: GroundingMetadata?
    var promptFeedback: PromptFeedback?

    do {
      let response = try await chat.sendMessage(message.content ?? "")
      responseText = response.text ?? ""
      usageMetadata = response.usageMetadata
      
      if let candidate = response.candidates.first {
        finishReason = candidate.finishReason
        citationMetadata = candidate.citationMetadata
        groundingMetadata = candidate.groundingMetadata
      }
      promptFeedback = response.promptFeedback
    } catch {
      responseText =
      "I'm sorry, I don't understand that. Please try again. \(error.localizedDescription)"
    }
    let response = ChatMessage(
      content: responseText,
      participant: .other,
      usageMetadata: usageMetadata,
      finishReason: finishReason,
      citationMetadata: citationMetadata,
      groundingMetadata: groundingMetadata,
      promptFeedback: promptFeedback
    )
    messages.append(response)
  }
}

struct FirebaseAILogicChatWithMetadataView: View {
  @State private var viewModel = FirebaseAILogicChatWithMetadataViewModel()

  @ViewBuilder
  private func tokenBar(for message: ChatMessage) -> some View {
    HStack {
      if message.participant == .user {
        Spacer()
      }
      HStack(spacing: 6) {
        Image(systemName: "number")
          .font(.caption2)
          .foregroundStyle(.secondary)
        Text("Total tokens: ")
          .font(.caption2)
          .foregroundStyle(.secondary)
        if let usageMetadata = message.usageMetadata {
          Text("\(usageMetadata.totalTokenCount)")
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.primary)
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 4)
      .background(
        Capsule()
          .fill(Color.accentColor.opacity(0.08))
      )
      .overlay(
        Capsule()
          .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
      )
      if message.participant == .other {
        Spacer()
      }
    }
    .padding(.top, 2)
  }

  @ViewBuilder
  private func metadataDebugView(for message: ChatMessage) -> some View {
    if let usageMetadata = message.usageMetadata {
      VStack(alignment: .leading, spacing: 2) {
        Text("Prompt tokens: \(usageMetadata.promptTokenCount)")
          .font(.caption2)
          .foregroundStyle(.secondary)
        Text("Candidates tokens: \(usageMetadata.candidatesTokenCount)")
          .font(.caption2)
          .foregroundStyle(.secondary)
        Text("Thoughts tokens: \(usageMetadata.thoughtsTokenCount)")
          .font(.caption2)
          .foregroundStyle(.secondary)
        Text("Total tokens: \(usageMetadata.totalTokenCount)")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }

    if let finishReason = message.finishReason {
      Text("Finish reason: \(finishReason.rawValue)")
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    if let citationMetadata = message.citationMetadata {
      let citationCount = citationMetadata.citations.count
      if citationCount > 0 {
        Text("Citations: \(citationCount)")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }

    if let groundingMetadata = message.groundingMetadata {
      let groundingChunkCount = groundingMetadata.groundingChunks.count
      if groundingChunkCount > 0 {
        Text("Grounding chunks: \(groundingChunkCount)")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }

    if let promptFeedback = message.promptFeedback,
       let blockReason = promptFeedback.blockReason {
      Text("Prompt Blocked: \(blockReason.rawValue)")
        .font(.caption2)
        .foregroundColor(.red)
      if let blockMsg = promptFeedback.blockReasonMessage {
        Text(blockMsg)
          .font(.caption2)
          .foregroundColor(.red)
      }
    }
  }

  @ViewBuilder
  private func messageContent(for message: ChatMessage) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      MessageView(
        message: message.content,
        imageURL: message.imageURL ?? "",
        participant: message.participant
      )
      VStack(alignment: .leading, spacing: 4) {
        tokenBar(for: message)
        metadataDebugView(for: message)
      }
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
  FirebaseAILogicChatWithMetadataView()
}

