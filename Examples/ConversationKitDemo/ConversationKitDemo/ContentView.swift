//
// ContentView.swift
// ConversationKitDemo
//
// Created by Peter Friese on 19.02.24.
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

import SwiftUI
import ConversationKit

struct ContentView: View {
  @State
  var messages: [DefaultMessage] = [
    .init(content: "Hello, how are you?", participant: .other),
    .init(content: "Well, I am fine, how are you?", participant: .user),
    .init(content: "Not too bad. Not too bad after all.", participant: .other),
    .init(content: "Laboris officia aliqua eiusmod deserunt pariatur aliquip cillum proident excepteur qui pariatur consequat aute occaecat deserunt.", participant: .user),
    .init(content: "Laborum ea ad anim magna.", participant: .other),
    .init(content: "Esse aliquip laboris irure est voluptate aliquip non duis aute eu. Occaecat irure incididunt aute aute do sunt labore nisi esse nostrud amet labore enim mollit occaecat. Occaecat incididunt consectetur sint dolor deserunt exercitation mollit id culpa deserunt fugiat pariatur pariatur ullamco. Ex aliqua sit commodo enim qui commodo aliqua sint dolor laboris magna consequat adipisicing sunt.",
          imageURL: "https://picsum.photos/100/100",
          participant: .user)
    
  ]

  var body: some View {
    NavigationStack {
      ConversationView(messages: $messages)
        .onSendMessage { userMessage in
          if let defaultMessage = userMessage as? DefaultMessage {
            messages.append(defaultMessage)
          }
          Task {
            print("You said: \(userMessage.content ?? "nothing")")
            await generateResponse(for: userMessage)
          }
        }
        .attachmentActions {
          Button("Image", systemImage: "photo.on.rectangle.angled") {
          }
          Button("Camera", systemImage: "camera") {
          }
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
  }

  func generateResponse(for message: any Message) async {
    let text = "Culpa *amet* irure aliquip qui deserunt ullamco tempor do irure anim amet do incididunt. Tempor et dolor qui. Aliqua **anim** aliqua elit in. Veniam veniam magna aliquip. Anim eu et excepteur voluptate labore reprehenderit exercitation voluptate fugiat dolor reprehenderit tempor esse et amet."

    var generatedText = ""
    var message = DefaultMessage(content: generatedText, participant: .other)
    messages.append(message) // Assuming you have an array 'messages' defined

    let chunkSize = 3 // Size of each chunk

    do {
      for chunkStart in stride(from: 0, to: text.count, by: chunkSize) {
        let chunkEnd = min(chunkStart + chunkSize, text.count)
        let chunk = text[text.index(text.startIndex, offsetBy: chunkStart)..<text.index(text.startIndex, offsetBy: chunkEnd)]

        generatedText.append(String(chunk))
        message.content = generatedText
        messages[messages.count - 1] = message // Update the last message

        let randomDelay = Double.random(in: 0.2...0.4) // Adjust delay for chunks
        try await Task.sleep(nanoseconds: UInt64(randomDelay * 100_000_000))
      }
    } catch {
      // Handle errors if needed
    }
  }

}

#Preview {
  ContentView()
}
