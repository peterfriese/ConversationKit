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
  @State private var messages: [DefaultMessage] = [
    DefaultMessage(content: "Hello! How can I help you today?", participant: .other)
  ]
  @State private var errorWrapper: ErrorWrapper?
  
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
          if let defaultMessage = message as? DefaultMessage {
            messages.append(defaultMessage)
          }
          var responseMessage: DefaultMessage
          do {
            let response = try await session.respond(to: message.content ?? "")
            let responseText = response.content
            responseMessage = DefaultMessage(content: responseText, participant: .other)
          } catch {
            let responseText = "An error has occurred. Try again later."
            responseMessage = DefaultMessage(content: responseText, participant: .other, error: error)
          }
          messages.append(responseMessage)
        }
        .onError { error in
          errorWrapper = ErrorWrapper(error: error)
        }
        .sheet(item: $errorWrapper) { wrapper in
          NavigationStack {
            VStack {
              Text(wrapper.error.localizedDescription)
                .padding()
              Spacer()
            }
            .navigationTitle("Error details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button("Dismiss", systemImage: "xmark") {
                  errorWrapper = nil
                }
              }
            }
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