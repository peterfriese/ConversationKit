//
// FirebaseAILogicChatWithMetadataView.swift
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
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct ChatMessage: Message {
  var id: String
  var content: String?
  var participant: Participant
  var createdAt: Date
  var attachments: [ConversationAttachment]
  var tokens: [ComposerToken]
  var selectedModelID: String?
  var messageError: MessageError?

  let usageMetadata: GenerateContentResponse.UsageMetadata?
  let finishReason: FinishReason?
  let citationMetadata: CitationMetadata?
  let groundingMetadata: GroundingMetadata?
  let promptFeedback: PromptFeedback?

  init(
    id: String = UUID().uuidString,
    content: String? = nil,
    participant: Participant,
    createdAt: Date = .now,
    attachments: [ConversationAttachment] = [],
    tokens: [ComposerToken] = [],
    selectedModelID: String? = nil,
    error: (any Error)? = nil,
    usageMetadata: GenerateContentResponse.UsageMetadata? = nil,
    finishReason: FinishReason? = nil,
    citationMetadata: CitationMetadata? = nil,
    groundingMetadata: GroundingMetadata? = nil,
    promptFeedback: PromptFeedback? = nil
  ) {
    self.id = id
    self.content = content
    self.participant = participant
    self.createdAt = createdAt
    self.attachments = attachments
    self.tokens = tokens
    self.selectedModelID = selectedModelID
    self.messageError = error.map { MessageError(error: $0) }
    self.usageMetadata = usageMetadata
    self.finishReason = finishReason
    self.citationMetadata = citationMetadata
    self.groundingMetadata = groundingMetadata
    self.promptFeedback = promptFeedback
  }

  static func makeUserMessage(
    id: String,
    content: String?,
    attachments: [ConversationAttachment],
    tokens: [ComposerToken],
    selectedModelID: String?
  ) -> ChatMessage {
    ChatMessage(
      id: id,
      content: content,
      participant: .user,
      createdAt: .now,
      attachments: attachments,
      tokens: tokens,
      selectedModelID: selectedModelID
    )
  }

  static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
    lhs.id == rhs.id
      && lhs.content == rhs.content
      && lhs.participant == rhs.participant
      && lhs.attachments == rhs.attachments
      && lhs.tokens == rhs.tokens
      && lhs.messageError == rhs.messageError
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(content)
    hasher.combine(participant)
    hasher.combine(attachments)
    hasher.combine(tokens)
    hasher.combine(messageError)
  }
}

@MainActor
@Observable
final class FirebaseAILogicChatWithMetadataViewModel {
  var messages: [ChatMessage] = []
  var attachments: [ConversationAttachment] = []
  var selectedItems: [PhotosPickerItem] = []

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

  func sendMessage(_ submission: ConversationSubmission<ChatMessage>) async {
    messages.append(submission.message)

    var responseText: String
    var usageMetadata: GenerateContentResponse.UsageMetadata?
    var finishReason: FinishReason?
    var citationMetadata: CitationMetadata?
    var groundingMetadata: GroundingMetadata?
    var promptFeedback: PromptFeedback?

    do {
      let imageParts: [InlineDataPart] = submission.attachments.compactMap { attachment in
        switch attachment.payload {
        case .image(let imageBox):
          #if canImport(UIKit)
          if let jpegData = imageBox.image.jpegData(compressionQuality: 0.85) {
            return InlineDataPart(data: jpegData, mimeType: "image/jpeg")
          }
          #endif
          if let pngData = imageBox.pngData() {
            return InlineDataPart(data: pngData, mimeType: "image/png")
          }
          return nil

        case .data(let data, let contentType, _):
          let mimeType = contentType.preferredMIMEType ?? "application/octet-stream"
          return InlineDataPart(data: data, mimeType: mimeType)

        case .file(let url):
          guard let data = try? Data(contentsOf: url) else { return nil }
          let mimeType = attachment.contentType.preferredMIMEType ?? "application/octet-stream"
          return InlineDataPart(data: data, mimeType: mimeType)
        }
      }

      let parts: [PartsRepresentable] = imageParts + [submission.text]
      let response = try await chat.sendMessage(parts)
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
  @State private var showingPhotoPicker = false

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
      let blockReason = promptFeedback.blockReason
    {
      Text("Prompt Blocked: \(blockReason.rawValue)")
        .font(.caption2)
        .foregroundStyle(.red)
      if let blockMsg = promptFeedback.blockReasonMessage {
        Text(blockMsg)
          .font(.caption2)
          .foregroundStyle(.red)
      }
    }
  }

  @ViewBuilder
  private func messageContent(for message: ChatMessage) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      MessageView(message: message)
      if message.participant == .other {
        VStack(alignment: .leading, spacing: 4) {
          tokenBar(for: message)
          metadataDebugView(for: message)
        }
      }
    }
  }

  var body: some View {
    NavigationStack {
      ConversationView(messages: $viewModel.messages, attachments: $viewModel.attachments) { message in
        messageContent(for: message)
      }
      .onSendMessage { submission in
        await viewModel.sendMessage(submission)
      }
      .attachmentActions {
        Button("Photos", systemImage: "photo.on.rectangle.angled") {
          showingPhotoPicker = true
        }
      }
      .navigationTitle("Firebase AI (Metadata)")
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
      .photosPicker(
        isPresented: $showingPhotoPicker,
        selection: $viewModel.selectedItems,
        maxSelectionCount: 5,
        matching: .images
      )
      .onChange(of: viewModel.selectedItems) {
        Task { @MainActor in
          for (index, item) in viewModel.selectedItems.enumerated() {
            do {
              if let data = try await item.loadTransferable(type: Data.self),
                let imageBox = PlatformImageBox(data: data)
              {
                viewModel.attachments.append(
                  ConversationAttachment(
                    imageBox: imageBox,
                    filename: "Photo-\(index + 1).jpg"
                  )
                )
              }
            } catch {
              print("Failed to load image attachment: \(error.localizedDescription)")
            }
          }
          viewModel.selectedItems.removeAll()
        }
      }
    }
  }
}

#Preview {
  FirebaseAILogicChatWithMetadataView()
}
