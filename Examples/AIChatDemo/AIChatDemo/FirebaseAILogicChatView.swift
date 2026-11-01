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
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
final class FirebaseAILogicChatViewModel {
  var messages: [DefaultMessage] = []
  var attachments: [ConversationAttachment] = []
  var selectedItems: [PhotosPickerItem] = []

  private let model: GenerativeModel
  private let chat: Chat

  init() {
    let firstMessage = DefaultMessage(
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

  func sendMessage(_ submission: ConversationSubmission<DefaultMessage>) async {
    messages.append(submission.message)

    let responseText: String
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
    } catch {
      responseText =
        "I'm sorry, I don't understand that. Please try again. \(error.localizedDescription)"
    }

    let response = DefaultMessage(content: responseText, participant: .other)
    messages.append(response)
  }
}

struct FirebaseAILogicChatView: View {
  @State private var viewModel = FirebaseAILogicChatViewModel()
  @State private var showingPhotoPicker = false

  var body: some View {
    NavigationStack {
      ConversationView(messages: $viewModel.messages, attachments: $viewModel.attachments)
        .onSendMessage { submission in
          await viewModel.sendMessage(submission)
        }
        .attachmentActions {
          Button("Photos", systemImage: "photo.on.rectangle.angled") {
            showingPhotoPicker = true
          }
        }
        .navigationTitle("Firebase AI Chat")
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
  FirebaseAILogicChatView()
}
