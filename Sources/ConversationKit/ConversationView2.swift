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

// https://www.avanderlee.com/swiftui/conditional-view-modifier/
extension View {
  /// Applies the given transform if the given condition evaluates to `true`.
  /// - Parameters:
  ///   - condition: The condition to evaluate.
  ///   - transform: The transform to apply to the source `View`.
  /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
  @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}

public enum Participant {
  case other
  case user
}

public struct Message: Identifiable, Hashable {
  public let id: UUID = .init()
  public var content: String
  public let participant: Participant

  public init(content: String, participant: Participant) {
    self.content = content
    self.participant = participant
  }
}

struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}

extension View {
  func roundedCorner(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

struct MessageView: View {
  let message: String
  let fullWidth: Bool = false
  let participant: Participant

  var body: some View {
    HStack(alignment: .top) {
      if participant == .user {
        Spacer()
      }
      else {
        Image(systemName: "person.circle.fill")
          .font(.title)
      }
      Text(message)
        .padding()
        .if(fullWidth) { view in
          view.frame(maxWidth: .infinity, alignment: .leading)
        }
        .background {
          Color(uiColor: participant == .other
                ? .secondarySystemBackground
                : .systemGray4)
        }
        .roundedCorner(8, corners: participant == .other ? .topLeft : .topRight)
        .roundedCorner(20, corners: participant == .other ? [.topRight, .bottomLeft, .bottomRight] : [.topLeft, .bottomLeft, .bottomRight])
      if participant == .other {
        Spacer()
      }
      else {
        Image(systemName: "cloud.circle.fill")
          .font(.title)
      }
    }
    .listRowSeparator(.hidden)
  }
}

struct ConversationViewSubmitHandler: EnvironmentKey {
  static let defaultValue: (_ message: Message) -> Void = {
    message in
    // no-op
  }
}

extension EnvironmentValues {
  public var onSendMessageAction: (_ message: Message) -> Void {
    get { self[ConversationViewSubmitHandler.self] }
    set { self[ConversationViewSubmitHandler.self] = newValue }
  }
}

public extension View {
  func onSendMessage(_ action: @escaping (_ message: Message) -> Void) -> some View {
    environment(\.onSendMessageAction, action)
  }
}


public struct ConversationView2: View {
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
            MessageView(message: message.content, participant: message.participant)
              .padding(.horizontal)
          }
          Spacer()
            .frame(height: 50)
        }
        .scrollTargetLayout()
      }
      .scrollTargetBehavior(.viewAligned)
      .scrollBounceBehavior(.always)
      .scrollDismissesKeyboard(.immediately)
      .scrollPosition(id: $scrolledID, anchor: .top)

      TextInputView(message: $message)
        .focused($focusedField, equals: .message)
        .onSubmit {
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
  NavigationStack {
    @State var messages: [Message] = [
      .init(content: "Hello, how are you?", participant: .other),
      .init(content: "Well, I am fine, how are you?", participant: .user),
      .init(content: "Not too bad. Not too bad after all.", participant: .other),
      .init(content: "Laboris officia aliqua eiusmod deserunt pariatur aliquip cillum proident excepteur qui pariatur consequat aute occaecat deserunt.", participant: .user),
      .init(content: "Laborum ea ad anim magna.", participant: .other),
      .init(content: "Esse aliquip laboris irure est voluptate aliquip non duis aute eu. Occaecat irure incididunt aute aute do sunt labore nisi esse nostrud amet labore enim mollit occaecat. Occaecat incididunt consectetur sint dolor deserunt exercitation mollit id culpa deserunt fugiat pariatur pariatur ullamco. Ex aliqua sit commodo enim qui commodo aliqua sint dolor laboris magna consequat adipisicing sunt.", participant: .user)
    ]
    ConversationView2(messages: $messages)
      .onSendMessage { userMessage in
        print("You said: \(userMessage.content)")
        messages.append(Message(content: userMessage.content.localizedUppercase, participant: .other))
      }
      .navigationTitle("Chat")
      .navigationBarTitleDisplayMode(.inline)
  }
}
