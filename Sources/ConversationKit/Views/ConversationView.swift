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
  
  // Custom scroll tracking
  @State private var isAutoScrollingTop: Bool = false
  @State private var autoScrollTargetID: MessageType.ID?
  @State private var isAtBottom: Bool = false
  
  @State private var sendingTask: Task<Void, Never>?

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
              .onAppear {
                isAtBottom = true
              }
              .onDisappear {
                isAtBottom = false
              }
          }
          .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollBounceBehavior(.always)
        .scrollDismissesKeyboard(.interactively)
        .scrollPosition(id: $scrolledID, anchor: .top)
        .simultaneousGesture(
          DragGesture().onChanged { _ in
            // Stop sticky top anchoring if the user touches/scrolls the view
            isAutoScrollingTop = false
            autoScrollTargetID = nil
          }
        )
        .onChange(of: messages) { oldValue, newValue in
          // 1. Detect if a brand new message was submitted by the user
          let wasUserMessageAdded = oldValue.count < newValue.count && newValue.last?.participant == .user
          
          if wasUserMessageAdded, let lastMessage = newValue.last {
            // Anchor to the new user message, trigger auto-scrolling state
            isAutoScrollingTop = true
            autoScrollTargetID = lastMessage.id
            withAnimation {
              scrolledID = .message(lastMessage.id)
            }
          } 
          // 2. If we are currently anchored, and new tokens are arriving (list mutated but user didn't scroll away)
          else if isAutoScrollingTop, let targetID = autoScrollTargetID {
            // Force the proxy to clamp to the top of the anchor without animation (seamless "riding" of the expanding content)
            proxy.scrollTo(ConversationScrollID.message(targetID), anchor: .top)
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
            .transition(.opacity.combined(with: .scale(scale: 0.8)))
          }
        }
        .animation(.easeInOut(duration: 0.2), value: shouldShowFAB)
      }

      MessageComposerView(message: $message, attachments: $attachments)
        .padding(.bottom, 10) // keep distance from keyboard
        .focused($focusedField, equals: .message)
        .isGenerating(sendingTask != nil)
        .onStopAction {
          sendingTask?.cancel()
        }
        .onSubmitAction {
          submit()
        }
    }
  }
  
  private var shouldShowFAB: Bool {
    if messages.isEmpty { return false }
    if isAutoScrollingTop { return false }
    return !isAtBottom
  }

  @MainActor
  func submit() {
    let userMessage = MessageType(content: message, imageURL: nil, participant: .user)
    
    withAnimation {
      message = ""
      focusedField = nil // Dismiss keyboard
    }

    sendingTask = Task { @MainActor in
      defer { self.sendingTask = nil }
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
