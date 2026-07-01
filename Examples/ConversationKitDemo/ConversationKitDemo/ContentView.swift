//
//  ContentView.swift
//  ConversationKitDemo
//
//  Created by Peter Friese on 19.02.24.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import ConversationKit
import PhotosUI
import SwiftUI

struct ContentView: View {
  @State
  var messages: [DefaultMessage] = [
    .init(content: "Hello! I'm your AI assistant. How can I help you today?", participant: .other),
    .init(content: "What are the key features of ConversationKit?", participant: .user),
    .init(content: "ConversationKit provides a robust set of UI components for building chat interfaces. Key features include Optimistic UI, 'Sticky Top' scrolling, and native cross-platform support.", participant: .other),
    .init(content: "How does the 'Sticky Top' scrolling work?", participant: .user),
    .init(content: "It anchors the scroll position to the top of the message being streamed, ensuring a stable reading experience as new tokens arrive.", participant: .other),
    .init(content: "Can you show me a formatted response with an image?", participant: .user),
    .init(
      content: "Sure! Here is an example of a **formatted message** with an image:\n\n### Key Benefits\n* **Native Performance**: Built entirely in SwiftUI.\n* **Customizable**: Use your own models and views.\n* **Cross-platform**: Works on iOS and macOS.",
      imageURL: "https://picsum.photos/400/300",
      participant: .other
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

  @MainActor
  func generateResponse(for message: any Message) async {
    let userText = message.content ?? ""
    
    let responses: [(text: String, imageURL: String?)] = [
      (
        text: "ConversationKit provides a **smooth** and **native** chat experience. It handles complex UI logic like message deduplication and scroll management so you can focus on your AI logic. The library is fully compatible with **SwiftUI** and supports both iOS and macOS.",
        imageURL: nil
      ),
      (
        text: "Sure! Here is an example of a **formatted message** with an image:\n\n### Key Benefits\n*   **Native Performance**: Built entirely in SwiftUI.\n*   **Customizable**: Use your own models and views.\n*   **Cross-platform**: Works on iOS and macOS.\n\n```swift\nConversationView(messages: $messages)\n```",
        imageURL: "https://picsum.photos/400/300"
      ),
      (
        text: "I can definitely help with that. Did you know that *Sticky Top* scrolling is one of the most requested features for chat apps? We've made it a first-class citizen in this library.",
        imageURL: nil
      ),
      (
        text: "That's a great question! Integrating AI can be complex, but your UI shouldn't be. That's why we built **ConversationKit**.",
        imageURL: nil
      )
    ]
    
    let selectedResponse: (text: String, imageURL: String?)
    if userText.localizedCaseInsensitiveContains("formatted") || userText.localizedCaseInsensitiveContains("image") {
      selectedResponse = responses[1]
    } else {
      selectedResponse = responses.randomElement() ?? responses[0]
    }

    var generatedText = ""
    var responseMessage = DefaultMessage(content: generatedText, imageURL: selectedResponse.imageURL, participant: .other)
    messages.append(responseMessage)

    let chunkSize = 5

    do {
      let text = selectedResponse.text
      for chunkStart in stride(from: 0, to: text.count, by: chunkSize) {
        let chunkEnd = min(chunkStart + chunkSize, text.count)
        let chunk = text[
          text.index(
            text.startIndex,
            offsetBy: chunkStart
          )..<text.index(text.startIndex, offsetBy: chunkEnd)
        ]

        generatedText.append(String(chunk))
        responseMessage.content = generatedText
        messages[messages.count - 1] = responseMessage

        let randomDelay = Double.random(in: 0.1...0.2)
        try await Task.sleep(nanoseconds: UInt64(randomDelay * 100_000_000))
        
        try Task.checkCancellation()
      }
    } catch {
      // Handle errors if needed
    }
  }

  @MainActor
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
