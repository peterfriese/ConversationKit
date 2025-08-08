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
class FirebaseAILogicChatWithMetadataViewModel {
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
      ModelContent(role: "model", parts: firstMessage.content ?? "")
    ]
    chat = model.startChat(history: history)
  }

  func extractMetadata(from response: GenerateContentResponse) -> [String: AnyHashable] {
    var metaData: [String: AnyHashable] = [:]
    // Add standard token metadata
    if let usage = response.usageMetadata {
      metaData["promptTokenCount"] = usage.promptTokenCount
      metaData["candidatesTokenCount"] = usage.candidatesTokenCount
      metaData["thoughtsTokenCount"] = usage.thoughtsTokenCount
      metaData["totalTokenCount"] = usage.totalTokenCount
      // Add per-modality token details if present (as a count)
      metaData["promptModalityCount"] = usage.promptTokensDetails.count
      metaData["candidatesModalityCount"] = usage.candidatesTokensDetails.count
    }
    // Add finish reason and citation count from candidate if present
    if let candidate = response.candidates.first {
      metaData["finishReason"] = candidate.finishReason?.rawValue ?? ""
      metaData["citationCount"] = candidate.citationMetadata?.citations.count ?? 0
      if let groundingMetadata = candidate.groundingMetadata {
        metaData["groundingChunkCount"] = groundingMetadata.groundingChunks.count
      }
    }
    // Optionally show if prompt feedback is blocked
    if let promptFeedback = response.promptFeedback, let blockReason = promptFeedback.blockReason {
      metaData["promptBlocked"] = true
      metaData["blockReason"] = blockReason.rawValue
      if let blockMsg = promptFeedback.blockReasonMessage {
        metaData["blockReasonMessage"] = blockMsg
      }
    }
    return metaData
  }

  func sendMessage(_ message: Message) async {
    if let content = message.content {
      var responseText: String
      var metaData: [String: AnyHashable] = [:]
      do {
        let response = try await chat.sendMessage(content)
        metaData = self.extractMetadata(from: response)
        responseText = response.text ?? ""
      } catch {
        responseText =
          "I'm sorry, I don't understand that. Please try again. \(error.localizedDescription)"
      }
      let response = Message(
        content: responseText,
        participant: .other,
        metadata: metaData
      )
      messages.append(response)
    }
  }
}

struct FirebaseAILogicChatWithMetadataView: View {
  @State private var viewModel = FirebaseAILogicChatWithMetadataViewModel()

  @ViewBuilder
  private func tokenBar(for message: Message) -> some View {
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
        Text("\(message.metadata["totalTokenCount"] as? Int ?? 0)")
          .font(.caption2.monospacedDigit())
          .foregroundStyle(.primary)
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
  private func metadataDebugView(for message: Message) -> some View {
    if !message.metadata.isEmpty {
      VStack(alignment: .leading, spacing: 2) {
        if let promptTokenCount = message.metadata["promptTokenCount"] {
          Text("Prompt tokens: \(promptTokenCount as? Int ?? 0)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        if let candidatesTokenCount = message.metadata["candidatesTokenCount"] {
          Text("Candidates tokens: \(candidatesTokenCount as? Int ?? 0)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        if let thoughtsTokenCount = message.metadata["thoughtsTokenCount"] {
          Text("Thoughts tokens: \(thoughtsTokenCount as? Int ?? 0)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        if let finishReason = message.metadata["finishReason"] as? String, !finishReason.isEmpty {
          Text("Finish reason: \(finishReason)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        if let citationCount = message.metadata["citationCount"] as? Int, citationCount > 0 {
          Text("Citations: \(citationCount)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        if let groundingChunkCount = message.metadata["groundingChunkCount"] as? Int, groundingChunkCount > 0 {
          Text("Grounding chunks: \(groundingChunkCount)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        if let promptBlocked = message.metadata["promptBlocked"] as? Bool, promptBlocked,
           let blockReason = message.metadata["blockReason"] as? String {
          Text("Prompt Blocked: \(blockReason)")
            .font(.caption2)
            .foregroundColor(.red)
          if let blockMsg = message.metadata["blockReasonMessage"] as? String {
            Text(blockMsg)
              .font(.caption2)
              .foregroundColor(.red)
          }
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(Color.secondary.opacity(0.08))
      )
    }
  }

  @ViewBuilder
  private func messageContent(for message: Message) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      MessageView(
        message: message.content ?? "",
        imageURL: message.imageURL ?? "",
        participant: message.participant,
        metadata: message.metadata
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
