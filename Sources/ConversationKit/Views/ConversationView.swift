// 
// ConversationView.swift
//
// Created by Peter Friese on 20.02.24.
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
import MarkdownUI

extension EnvironmentValues {
  @Entry var onSendMessageAction: (_ message: Message) async -> Void = { message in
    // no-op
  }
  
}

public extension View {
  func onSendMessage(_ action: @escaping (_ message: Message) async -> Void) -> some View {
    environment(\.onSendMessageAction, action)
  }
}


/// A view that displays a conversation thread and provides a text input field for the user.
///
/// `ConversationView` takes a binding to an array of `Message` objects and
/// displays them in a scrollable view. It also provides a text input field at the
/// bottom for the user to compose and send new messages. When a new message is
/// submitted, it is automatically appended to the `messages` array.
///
/// ## Handling Sent Messages
///
/// To handle new messages sent by the user, use the `onSendMessage(_:)`
/// view modifier. This modifier's closure is called with the user's `Message`
/// object when they send it and supports async operations. In this closure, you can
/// process the message asynchronously, such as by sending it to a backend or a local
/// model, and then append any response to your `messages` array to have it appear
/// in the conversation.
///
/// ## Built-in Message Rendering
///
/// The simplest way to use `ConversationView` is with the default message renderer,
/// which uses the built-in `MessageView` to display messages:
///
/// ```swift
/// struct ChatScreen: View {
///     @State private var messages: [Message] = [
///         .init(content: "Hello!", participant: .other)
///     ]
///
///     var body: some View {
///         ConversationView(messages: $messages)
///             .onSendMessage { userMessage in
///                 // Process the user's message asynchronously
///                 let responseText = await getResponse(for: userMessage.content ?? "")
///                 let responseMessage = Message(content: responseText, participant: .other)
///                 await MainActor.run {
///                     messages.append(responseMessage)
///                 }
///             }
///     }
///
///     func getResponse(for text: String) async -> String {
///         // Simulate network request
///         try? await Task.sleep(for: .seconds(1))
///         return "You said: \(text)"
///     }
/// }
/// ```
///
/// ## Custom Message Rendering
///
/// For more control over message appearance, you can provide a custom content closure
/// that defines how each message should be rendered:
///
/// ```swift
/// struct CustomChatScreen: View {
///     @State private var messages: [Message] = [
///         .init(content: "Hello!", participant: .other)
///     ]
///
///     var body: some View {
///         ConversationView(messages: $messages) { message in
///             HStack {
///                 if message.participant == .user {
///                     Spacer()
///                 }
///                 
///                 VStack(alignment: .leading) {
///                     if let content = message.content {
///                         Text(content)
///                             .padding()
///                             .background(message.participant == .user ? Color.blue : Color.gray)
///                             .foregroundColor(.white)
///                             .cornerRadius(12)
///                     }
///                 }
///                 
///                 if message.participant == .other {
///                     Spacer()
///                 }
///             }
///         }
///         .onSendMessage { userMessage in
///             // Handle the sent message asynchronously
///             await processMessage(userMessage)
///         }
///     }
///     
///     func processMessage(_ message: Message) async {
///         // Perform async operations like API calls
///         let response = await chatService.getResponse(to: message.content ?? "")
///         await MainActor.run {
///             messages.append(Message(content: response, participant: .other))
///         }
///     }
/// }
/// ```
///
/// ## Error Handling
///
/// Since the `onSendMessage` action is async, you can handle errors naturally:
///
/// ```swift
/// .onSendMessage { userMessage in
///     do {
///         let response = try await chatService.sendMessage(userMessage.content ?? "")
///         await MainActor.run {
///             messages.append(Message(content: response, participant: .other))
///         }
///     } catch {
///         await MainActor.run {
///             messages.append(Message(content: "Error: \(error.localizedDescription)", participant: .other))
///         }
///     }
/// }
/// ```
///
/// ## Initializers
///
/// - `init(messages:)`: Creates a conversation view with built-in message rendering using `MessageView`
/// - `init(messages:content:)`: Creates a conversation view with custom message rendering using the provided content closure
///
/// - Parameter messages: A binding to an array of `Message` instances representing the conversation.
/// - Parameter content: A closure that takes a `Message` and returns a view for rendering that message.
public struct ConversationView<Content>: View where Content: View {
  @Binding var messages: [Message]

  @State private var scrolledID: Message.ID?

  @State private var message: String = ""
  @FocusState private var focusedField: FocusedField?
  enum FocusedField {
    case message
  }

  @Environment(\.onSendMessageAction) private var onSendMessageAction
  
  private let content: (Message) -> Content
  
  public init(messages: Binding<[Message]>) where Content == MessageView {
    self._messages = messages
    self.content = { message in
      MessageView(message: message.content,
                  imageURL: message.imageURL,
                  participant: message.participant)
    }
  }


  public init(messages: Binding<[Message]>, content: @escaping (Message) -> Content) {
    self._messages = messages
    self.content = content
  }

  public var body: some View {
    ZStack(alignment: .bottom) {
      ScrollView {
        LazyVStack(spacing: 20) {
          ForEach(messages) { message in
            content(message)
              .padding(.horizontal)
          }
          Spacer()
            .frame(height: 50)
        }
        .scrollTargetLayout()
      }
      .scrollTargetBehavior(.viewAligned)
      .scrollBounceBehavior(.always)
      .scrollDismissesKeyboard(.interactively)
      .scrollPosition(id: $scrolledID, anchor: .top)

      MessageComposerView(message: $message)
        .padding(.bottom, 10) // keep distance from keyboard
        .focused($focusedField, equals: .message)
        .onSubmitAction {
          submit()
        }
    }
    .onChange(of: messages) { oldValue, newValue in
      scrolledID = messages.last?.id
    }
  }

  @MainActor
  func submit() {
    let userMessage = Message(content: message, participant: .user)
    messages.append(userMessage)
    message = ""
    focusedField = .message

    Task {
      await onSendMessageAction(userMessage)
    }
  }

}

#Preview("Built-in chat bubbles") {
  @Previewable @State var messages: [Message] = [
    .init(content: "Hello, how are you?",
          imageURL: "https://picsum.photos/1080/1920",
          participant: .other),
    .init(content: "Well, I am fine, how are you?",
          imageURL: "https://picsum.photos/100/100",
          participant: .user),
    .init(content: "Not too bad. Not too bad after all.", 
          participant: .other),
    .init(imageURL: "https://picsum.photos/100/100",
          participant: .user),
    .init(content: "Laborum ea ad anim magna.", participant: .other),
    .init(content: "Esse aliquip laboris irure est voluptate aliquip non duis aute eu. Occaecat irure incididunt aute aute do sunt labore nisi esse nostrud amet labore enim mollit occaecat. Occaecat incididunt consectetur sint dolor deserunt exercitation mollit id culpa deserunt fugiat pariatur pariatur ullamco. Ex aliqua sit commodo enim qui commodo aliqua sint dolor laboris magna consequat adipisicing sunt.",
          imageURL: "https://picsum.photos/100/100",
          participant: .user)
  ]
  NavigationStack {
    ConversationView(messages: $messages)
      .attachmentActions {
        Button(action: {}) {
          Label("Photos", systemImage: "photo.on.rectangle.angled")
        }
        Button(action: {}) {
          Label("Camera", systemImage: "camera")
        }
      }
      .onSendMessage { userMessage in
        let content = userMessage.content ?? "(nothing at all)"
        print("You said: \(content)")
        // Simulate async response
        try? await Task.sleep(for: .seconds(0.5))
        await MainActor.run {
          messages.append(Message(content: content.localizedUppercase, participant: .other))
        }
      }
      .navigationTitle("Chat")
      .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview("Custom chat bubbles") {
  @Previewable @State var messages: [Message] = [
    .init(content: "Hello, how are you?",
          imageURL: "https://picsum.photos/1080/1920",
          participant: .other),
    .init(content: "Well, I am fine, how are you?",
          imageURL: "https://picsum.photos/100/100",
          participant: .user),
    .init(content: "Not too bad. Not too bad after all.",
          participant: .other),
    .init(imageURL: "https://picsum.photos/100/100",
          participant: .user),
    .init(content: "Laborum ea ad anim magna.", participant: .other),
    .init(content: "Esse aliquip laboris irure est voluptate aliquip non duis aute eu. Occaecat irure incididunt aute aute do sunt labore nisi esse nostrud amet labore enim mollit occaecat. Occaecat incididunt consectetur sint dolor deserunt exercitation mollit id culpa deserunt fugiat pariatur pariatur ullamco. Ex aliqua sit commodo enim qui commodo aliqua sint dolor laboris magna consequat adipisicing sunt.",
          imageURL: "https://picsum.photos/100/100",
          participant: .user)
  ]
  NavigationStack {
    ConversationView(messages: $messages) { message in
      VStack {
        if let imageURL = message.imageURL {
          if let url = URL(string: imageURL) {
            HStack {
              if message.participant == .user {
                Spacer()
              }
              AsyncImage(url: url) { phase in
                if let image = phase.image {
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 200, maxHeight: 400)
                } else if phase.error != nil {
                  Image(systemName: "icloud.slash")
                } else {
                  ProgressView()
                }
              }
              .frame(width: .infinity, height: .infinity, alignment: .center)
              .cornerRadius(8.0)
              if message.participant == .other {
                Spacer()
              }
            }
          }
        }
        if let messageContent = message.content {
          HStack {
            if message.participant == .user {
              Spacer()
            }
            Markdown(messageContent ?? "")
              .padding()
              .background {
                Color(uiColor: message.participant == .other
                      ? .secondarySystemBackground
                      : .systemGray4)
              }
              .roundedCorner(10, corners: .allCorners)
            if message.participant == .other {
              Spacer()
            }
          }
        }
      }
    }
    .onSendMessage { userMessage in
      let content = userMessage.content ?? "(nothing at all)"
      print("You said: \(content)")
      await MainActor.run {
        messages.append(Message(content: content.localizedUppercase, participant: .other))
      }
    }
    .navigationTitle("Chat")
    .navigationBarTitleDisplayMode(.inline)
  }
}
