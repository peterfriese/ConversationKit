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
  /// Defines the action to be executed when the user sends a new message.
  ///
  /// This action is executed asynchronously in a background task managed by `ConversationView`.
  /// While this task runs, the composer's "Send" button becomes a "Stop" button.
  ///
  /// - Important: `ConversationView` utilizes an Optimistic UI state to ensure flawless layout
  ///   anchor physics when the keyboard dismisses. It instantly displays the user's message locally.
  ///   When this action fires, you **must** append the provided `message` instance to your array to
  ///   permanently store it. The exact `id` of the `message` parameter must be preserved; if you copy
  ///   the content into a different model with a new UUID, the internal deduplication will fail and
  ///   the message will briefly appear twice.
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
  
  // Custom scroll tracking
  @State private var isAutoScrollingTop: Bool = false
  @State private var autoScrollTargetID: MessageType.ID?
  @State private var isAtBottom: Bool = false
  
  /// The task currently executing the `onSendMessage` action. Used to show the Stop button.
  @State private var sendingTask: Task<Void, Never>?
  
  /// A temporary copy of the user's message used to instantly update the UI.
  /// SwiftUI's `.scrollPosition` requires the layout to update synchronously with keyboard dismissal
  /// for perfect "Sticky Top" physics. However, the SDK does not own the `messages` array, meaning
  /// we must wait for the developer to append the message via the async `onSendMessage` action, which delays layout.
  /// To fix this, we hold the message here optimistically to trick the layout engine into correct physics,
  /// then seamlessly swap it out once the developer's data catches up.
  @State private var optimisticUserMessage: MessageType?
  
  /// A dynamically computed list combining the developer's source of truth with our optimistic state.
  private var displayedMessages: [MessageType] {
    if let opt = optimisticUserMessage {
      // O(1) fast path: The developer almost certainly appended the message to the end of the array.
      if let last = messages.last, last.id == opt.id {
        return messages
      }
      // O(N) fallback path just in case the array is sorted differently.
      if !messages.contains(where: { $0.id == opt.id }) {
        return messages + [opt]
      }
    }
    return messages
  }

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
            ForEach(displayedMessages) { message in
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
            if let lastMessage = displayedMessages.last, lastMessage.participant == .other, let disclaimer = conversationDisclaimer {
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
        .simultaneousGesture(
          DragGesture().onChanged { _ in
            // Stop sticky top anchoring if the user touches/scrolls the view
            isAutoScrollingTop = false
            autoScrollTargetID = nil
          }
        )
        .onChange(of: displayedMessages) { oldValue, newValue in
          // 1. Detect if a brand new message was submitted by the user
          let wasUserMessageAdded = oldValue.count < newValue.count && newValue.last?.participant == .user
          
          if wasUserMessageAdded, let lastMessage = newValue.last {
            // Anchor to the new user message, trigger auto-scrolling state
            isAutoScrollingTop = true
            autoScrollTargetID = lastMessage.id
            withAnimation {
              proxy.scrollTo(ConversationScrollID.message(lastMessage.id), anchor: .top)
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
    if displayedMessages.isEmpty { return false }
    if isAutoScrollingTop { return false }
    return !isAtBottom
  }

  @MainActor
  func submit() {
    let userMessage = MessageType(content: message, imageURL: nil, participant: .user)
    
    // Set the optimistic message synchronously so it immediately appears in the layout
    // for perfect "Sticky Top" scrolling physics when the keyboard dismisses.
    // It will be seamlessly replaced by the developer's actual message update since
    // `displayedMessages` deduplicates by ID.
    optimisticUserMessage = userMessage
    
    withAnimation {
      message = ""
      focusedField = nil // Dismiss keyboard
    }

    // Wrap the developer's closure execution in a background task. 
    // We mark it @MainActor so it yields execution immediately to allow the layout 
    // physics animation above to finish, but keeps any state updates they perform safely 
    // bound to the main thread by default to prevent deadlocks.
    sendingTask = Task { @MainActor in
      defer { 
        self.sendingTask = nil 
        self.optimisticUserMessage = nil
      }
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
