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
  @Entry var onSendMessageAction: (_ message: any Message) async -> Void = { message in
    // no-op
  }
}

public extension View {
  func onSendMessage(_ action: @escaping (_ message: any Message) async -> Void) -> some View {
    environment(\.onSendMessageAction, action)
  }
}

public struct ConversationView<Content, MessageType: Message, AttachmentType: Attachment & View>: View where Content: View {
  @Binding var messages: [MessageType]
  @Binding var attachments: [AttachmentType]

  enum ConversationScrollID: Hashable {
    case message(MessageType.ID)
    case bottomMarker
  }

  @State private var scrolledID: ConversationScrollID?

  @State private var message: String = ""
  @FocusState private var focusedField: FocusedField?
  enum FocusedField {
    case message
  }

  @Environment(\.onSendMessageAction) private var onSendMessageAction
  @Environment(\.messageActions) private var messageActions
  @Environment(\.conversationDisclaimer) private var conversationDisclaimer
  @Environment(\.scrollToBottomButtonStyle) private var scrollToBottomButtonStyle
  
  private let content: (MessageType) -> Content
  
  public init(messages: Binding<[MessageType]>,
              attachments: Binding<[AttachmentType]>,
              userPrompt: String? = "",
              @ViewBuilder content: @escaping (MessageType) -> Content) {
    self._messages = messages
    self._attachments = attachments
    self.message = userPrompt ?? ""
    self.content = content
  }

  public var body: some View {
    ZStack(alignment: .bottom) {
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(spacing: 16) {
            ForEach(messages) { message in
              VStack(alignment: .leading, spacing: 8) {
                content(message)
                
                // Message Actions
                if message.participant == .other, let actions = messageActions {
                  actions(message)
                }
              }
              .padding(.horizontal)
              .id(ConversationScrollID.message(message.id))
            }
            
            // Disclaimer View
            if let lastMessage = messages.last, lastMessage.participant == .other, let disclaimer = conversationDisclaimer {
              disclaimer
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            Spacer()
              .frame(height: 100)
              .id(ConversationScrollID.bottomMarker)
          }
          .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollBounceBehavior(.always)
        .scrollDismissesKeyboard(.interactively)
        .scrollPosition(id: $scrolledID, anchor: .top)
        .onChange(of: messages) { oldValue, newValue in
          // Anchor to the latest user message
          if let lastMessage = newValue.last, lastMessage.participant == .user {
            withAnimation {
              scrolledID = .message(lastMessage.id)
            }
          }
        }
        .overlay(alignment: .bottomTrailing) {
          // Show FAB if not near bottom
          if shouldShowFAB {
            scrollToBottomButtonStyle.makeBody(configuration: ScrollToBottomButtonConfiguration {
              withAnimation {
                proxy.scrollTo(ConversationScrollID.bottomMarker, anchor: .bottom)
              }
            })
            .padding(.bottom, 80) // Adjust to sit above composer
            .padding(.trailing, 16)
          }
        }
      }

      MessageComposerView(message: $message, attachments: $attachments)
        .padding(.bottom, 10) // keep distance from keyboard
        .focused($focusedField, equals: .message)
        .onSubmitAction {
          submit()
        }
    }
  }
  
  private var shouldShowFAB: Bool {
    guard let scrolledID = scrolledID, case .message(let id) = scrolledID, !messages.isEmpty else { return false }
    // If the currently top-anchored message is older than the last 3 messages, we likely scrolled up.
    if let currentIndex = messages.firstIndex(where: { $0.id == id }) {
      return currentIndex < messages.count - 3
    }
    return false
  }

  @MainActor
  func submit() {
    let userMessage = MessageType(content: message, imageURL: nil, participant: .user)
    
    withAnimation {
      message = ""
      focusedField = nil // Dismiss keyboard
    }

    Task {
      await onSendMessageAction(userMessage)
    }
  }

}

extension ConversationView where Content == MessageView {
  public init(messages: Binding<[MessageType]>,
              attachments: Binding<[AttachmentType]>,
              userPrompt: String? = "") {
    self.init(messages: messages,
              attachments: attachments,
              userPrompt: userPrompt,
              content: { message in
      MessageView(message: message.content,
                  imageURL: message.imageURL,
                  participant: message.participant,
                  error: message.error)
    })
  }
}

extension ConversationView where AttachmentType == EmptyAttachment {
  public init(messages: Binding<[MessageType]>, userPrompt: String? = "") where Content == MessageView {
    self.init(messages: messages,
              attachments: .constant([]),
              userPrompt: userPrompt,
              content: { message in
      MessageView(message: message.content,
                  imageURL: message.imageURL,
                  participant: message.participant,
                  error: message.error)
    })
  }
  
  public init(messages: Binding<[MessageType]>,
              userPrompt: String? = "",
              @ViewBuilder content: @escaping (MessageType) -> Content) {
    self.init(messages: messages,
              attachments: .constant([]),
              userPrompt: userPrompt,
              content: content)
  }
}
