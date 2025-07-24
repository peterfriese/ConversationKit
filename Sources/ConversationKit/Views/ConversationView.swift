//
// SwiftUIView.swift
//
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
  @Entry var onSendMessageAction: (_ message: Message) -> Void = { message in
    // no-op
  }
  
}

public extension View {
  func onSendMessage(_ action: @escaping (_ message: Message) -> Void) -> some View {
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
/// object when they send it. In this closure, you can process the message,
/// such as by sending it to a backend or a local model, and then append any
/// response to your `messages` array to have it appear in the conversation.
///
/// ## Example
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
///                 // Process the user's message, for example, by sending
///                 // it to a remote service and getting a response.
///                 Task {
///                     let responseText = await getResponse(for: userMessage.content ?? "")
///                     let responseMessage = Message(content: responseText, participant: .other)
///                     await MainActor.run {
///                         messages.append(responseMessage)
///                     }
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
/// - Parameter messages: A binding to an array of `Message` instances representing the conversation.
public struct ConversationView: View {
  @Binding var messages: [Message]

  @State private var scrolledID: Message.ID?

  @State private var message: String = ""
  @FocusState private var focusedField: FocusedField?
  enum FocusedField {
    case message
  }

  @Environment(\.onSendMessageAction) private var onSendMessageAction

  public init(messages: Binding<[Message]>) {
    self._messages = messages
  }

  public var body: some View {
    ZStack(alignment: .bottom) {
      ScrollView {
        LazyVStack(spacing: 20) {
          ForEach(messages) { message in
            MessageView(message: message.content,
                        imageURL: message.imageURL,
                        participant: message.participant)
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

    onSendMessageAction(userMessage)
  }

}

#Preview {
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
      .onSendMessage { userMessage in
        let content = userMessage.content ?? "(nothing at all)"
        print("You said: \(content)")
        messages.append(Message(content: content.localizedUppercase, participant: .other))
      }
      .navigationTitle("Chat")
      .navigationBarTitleDisplayMode(.inline)
  }
}
