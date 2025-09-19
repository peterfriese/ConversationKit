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
import PhotosUI

@Observable
class FirebaseAILogicChatViewModel {
  var messages: [DefaultMessage] = []
  var attachments = [ImageAttachment]()
  var selectedItems = [PhotosPickerItem]()

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

  func sendMessage(_ message: any Message) async {
    if let defaultMessage = message as? DefaultMessage {
      messages.append(defaultMessage)
    }
    var responseText: String
    do {
      // Convert attachments (UIImage) into InlineDataPart which conforms to Part/PartsRepresentable.
      let imageParts: [InlineDataPart] = attachments.compactMap { attachment in
        // Prefer JPEG to reduce size; fall back to PNG if JPEG encoding fails.
        if let jpegData = attachment.image.jpegData(compressionQuality: 0.85) {
          return InlineDataPart(data: jpegData, mimeType: "image/jpeg")
        } else if let pngData = attachment.image.pngData() {
          return InlineDataPart(data: pngData, mimeType: "image/png")
        } else {
          return nil
        }
      }

      // Build a single message with images and text. String is PartsRepresentable via TextPart.
      // Use the variadic sendMessage overload by passing an array (which itself conforms to PartsRepresentable).
      let parts: [PartsRepresentable] = imageParts + [message.content ?? ""]
      withAnimation {
        attachments.removeAll()
      }
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
        .attachmentActions {
          Button("Photos", systemImage: "photo.on.rectangle.angled") {
            showingPhotoPicker = true
          }
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onSendMessage { message in
          await viewModel.sendMessage(message)
        }
        .photosPicker(
          isPresented: $showingPhotoPicker,
          selection: $viewModel.selectedItems,
          maxSelectionCount: 5,
          matching: .images
        )
        .onChange(of: viewModel.selectedItems) {
          Task {
            for item in viewModel.selectedItems {
              do {
                if let data = try await item.loadTransferable(type: Data.self) {
                  if let uiImage = UIImage(data: data) {
                    viewModel.attachments.append(
                      ImageAttachment(image: uiImage)
                    )
                  }
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
