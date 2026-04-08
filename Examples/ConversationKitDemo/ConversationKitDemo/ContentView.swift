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

import ConversationKit
import PhotosUI
import SwiftUI

struct ContentView: View {
  @State
  var messages: [DefaultMessage] = [
    .init(content: "Hello, how are you?", participant: .other),
    .init(content: "Well, I am fine, how are you?", participant: .user),
    .init(content: "Not too bad. Not too bad after all.", participant: .other),
    .init(
      content:
        "Laboris officia aliqua eiusmod deserunt pariatur aliquip cillum proident excepteur qui pariatur consequat aute occaecat deserunt.",
      participant: .user
    ),
    .init(content: "Laborum ea ad anim magna.", participant: .other),
    .init(
      content:
        "Esse aliquip laboris irure est voluptate aliquip non duis aute eu. Occaecat irure incididunt aute aute do sunt labore nisi esse nostrud amet labore enim mollit occaecat. Occaecat incididunt consectetur sint dolor deserunt exercitation mollit id culpa deserunt fugiat pariatur pariatur ullamco. Ex aliqua sit commodo enim qui commodo aliqua sint dolor laboris magna consequat adipisicing sunt.",
      imageURL: "https://picsum.photos/100/100",
      participant: .user
    ),

  ]

  @State var attachments = [ImageAttachment]()
  @State private var selectedItems = [PhotosPickerItem]()
  @State private var showingPhotoPicker = false

  var body: some View {
    NavigationStack {
      ConversationView(messages: $messages, attachments: $attachments)
        .onSendMessage { userMessage in
          if let defaultMessage = userMessage as? DefaultMessage {
            messages.append(defaultMessage)
          }
          withAnimation {
            self.attachments.removeAll()
          }
          
          let content = userMessage.content ?? ""
          print("You said: \(content)")
          if content.localizedCaseInsensitiveContains("long") {
            await generateLongResponse()
          } else {
            await generateResponse(for: userMessage)
          }
        }
        .attachmentActions {
          Button("Photos", systemImage: "photo.on.rectangle.angled") {
            showingPhotoPicker = true
          }
        }
        .navigationTitle("Chat")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .photosPicker(
          isPresented: $showingPhotoPicker,
          selection: $selectedItems,
          maxSelectionCount: 5,
          matching: .images
        )
        .onChange(of: selectedItems) {
          Task {
            for item in selectedItems {
              do {
                if let data = try await item.loadTransferable(type: Data.self) {
                  if let platformImage = PlatformImage(data: data) {
                    attachments.append(
                      ImageAttachment(image: platformImage)
                    )
                  }
                }
              } catch {
                print("Failed to load image attachment: \(error.localizedDescription)")
              }
            }
            selectedItems.removeAll()
          }
        }
    }
  }

  func generateResponse(for message: any Message) async {
    let text =
      "Culpa *amet* irure aliquip qui deserunt ullamco tempor do irure anim amet do incididunt. Tempor et dolor qui. Aliqua **anim** aliqua elit in. Veniam veniam magna aliquip. Anim eu et excepteur voluptate labore reprehenderit exercitation voluptate fugiat dolor reprehenderit tempor esse et amet."

    var generatedText = ""
    var message = DefaultMessage(content: generatedText, participant: .other)
    messages.append(message)  // Assuming you have an array 'messages' defined

    let chunkSize = 3  // Size of each chunk

    do {
      for chunkStart in stride(from: 0, to: text.count, by: chunkSize) {
        let chunkEnd = min(chunkStart + chunkSize, text.count)
        let chunk = text[
          text.index(
            text.startIndex,
            offsetBy: chunkStart
          )..<text.index(text.startIndex, offsetBy: chunkEnd)
        ]

        generatedText.append(String(chunk))
        message.content = generatedText
        messages[messages.count - 1] = message  // Update the last message

        let randomDelay = Double.random(in: 0.2...0.4)  // Adjust delay for chunks
        try await Task.sleep(nanoseconds: UInt64(randomDelay * 100_000_000))
        
        try Task.checkCancellation()
      }
    } catch {
      // Handle errors if needed
    }
  }

  func generateLongResponse() async {
    let paragraphs = [
      "Here is a very long story just for you.",
      "Once upon a time in a digital realm far, far away, there lived a small bit of data named Byte. Byte was curious and always wanted to travel across the vast networks of the internet.",
      "One day, Byte found a packet header that was perfectly sized and hopped aboard. The journey was perilous, traversing through numerous routers, switches, and firewalls.",
      "At one point, Byte encountered a massive traffic jam at a transatlantic cable node. Packets were dropping left and right. It was a chaotic scene, but Byte managed to reroute through a satellite link.",
      "Floating through space, Byte saw the earth below—a beautiful blue marble interconnected by invisible threads of communication.",
      "Eventually, Byte landed safely in a cozy little server rack in Iceland, surrounded by humming cooling fans and the gentle blinking of LED lights.",
      "But the adventure didn't stop there. Byte was soon requested by a client application on a mobile device.",
      "Zipping back through fiber optic cables at the speed of light, Byte finally arrived on the screen of a user, bringing a tiny pixel to life to form part of a beautiful image.",
      "And so, Byte's journey came to an end, having successfully delivered the payload. It was a fulfilling existence, being part of the grand tapestry of human connection and information exchange.",
      "The end. I hope you enjoyed this incredibly long and detailed story about a single byte of data traversing the global internet infrastructure."
    ]

    var generatedText = ""
    var message = DefaultMessage(content: nil, participant: .other) // Start with loading state
    messages.append(message)
    
    // Simulate loading delay
    try? await Task.sleep(for: .seconds(1))

    let chunkSize = 5

    for paragraph in paragraphs {
      let textToStream = (generatedText.isEmpty ? "" : "\n\n") + paragraph
      for chunkStart in stride(from: 0, to: textToStream.count, by: chunkSize) {
        let chunkEnd = min(chunkStart + chunkSize, textToStream.count)
        let chunk = textToStream[
          textToStream.index(textToStream.startIndex, offsetBy: chunkStart)..<textToStream.index(textToStream.startIndex, offsetBy: chunkEnd)
        ]

        generatedText.append(String(chunk))
        message.content = generatedText
        messages[messages.count - 1] = message

        let randomDelay = Double.random(in: 0.05...0.1)
        try? await Task.sleep(for: .seconds(randomDelay))
        
        // This is strictly required for the new "Stop" button feature to work cooperatively
        do {
          try Task.checkCancellation()
        } catch {
          return // Stop streaming if cancelled
        }
      }
    }
  }

}

#Preview {
  ContentView()
}
