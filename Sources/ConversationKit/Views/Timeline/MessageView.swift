//
// MessageView.swift
// ConversationKit
//
// Created by Peter Friese on 04.07.25.
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

public struct MessageView: View, Equatable {
  @Environment(\.presentErrorAction) var presentErrorAction
  @Environment(\.onRetryMessageAction) private var onRetryMessageAction

  let message: String?
  let imageURL: String?
  let fullWidth: Bool = false
  let participant: Participant
  let error: Error?

  public let thinking: ThinkingTrace?
  public let toolCalls: [ToolCall]
  public let citations: [Citation]
  public let plan: AgentPlan?
  public let approvalRequest: ApprovalRequest?
  public let isStreaming: Bool
  public let rating: MessageRating?
  public let fullMessage: (any Message)?

  public init(
    message: String?,
    imageURL: String?,
    participant: Participant,
    error: Error? = nil,
    thinking: ThinkingTrace? = nil,
    toolCalls: [ToolCall] = [],
    citations: [Citation] = [],
    plan: AgentPlan? = nil,
    approvalRequest: ApprovalRequest? = nil,
    isStreaming: Bool = false,
    rating: MessageRating? = nil
  ) {
    self.message = message
    self.imageURL = imageURL
    self.participant = participant
    self.error = error
    self.thinking = thinking
    self.toolCalls = toolCalls
    self.citations = citations
    self.plan = plan
    self.approvalRequest = approvalRequest
    self.isStreaming = isStreaming
    self.rating = rating
    self.fullMessage = nil
  }

  public init<M: Message>(_ message: M) {
    self.message = message.content
    self.imageURL = message.imageURL
    self.participant = message.participant
    self.error = message.error
    self.thinking = message.thinking
    self.toolCalls = message.toolCalls
    self.citations = message.citations
    self.plan = message.plan
    self.approvalRequest = message.approvalRequest
    self.isStreaming = message.isStreaming
    self.rating = message.rating
    self.fullMessage = message
  }

  public init<M: Message>(message: M) {
    self.init(message)
  }

  public static func == (lhs: MessageView, rhs: MessageView) -> Bool {
    guard lhs.participant == rhs.participant,
          lhs.isStreaming == rhs.isStreaming,
          lhs.rating == rhs.rating,
          lhs.message?.utf8.count == rhs.message?.utf8.count,
          (lhs.error != nil) == (rhs.error != nil)
    else {
      return false
    }

    return lhs.imageURL == rhs.imageURL
      && lhs.thinking == rhs.thinking
      && lhs.toolCalls == rhs.toolCalls
      && lhs.citations == rhs.citations
      && lhs.plan == rhs.plan
      && lhs.approvalRequest == rhs.approvalRequest
      && lhs.message == rhs.message
      && lhs.error?.localizedDescription == rhs.error?.localizedDescription
  }

  private var resolvedMessageForCallback: any Message {
    if let fullMessage {
      return fullMessage
    }
    return DefaultMessage(
      content: message,
      imageURL: imageURL,
      participant: participant,
      error: error,
      thinking: thinking,
      toolCalls: toolCalls,
      citations: citations,
      plan: plan,
      approvalRequest: approvalRequest,
      isStreaming: isStreaming,
      rating: rating
    )
  }

  private var hasAgenticSubsurfaces: Bool {
    thinking != nil || !toolCalls.isEmpty || plan != nil || approvalRequest != nil || !citations.isEmpty
  }

  public var body: some View {
    HStack(alignment: .top) {
      if participant == .user {
        Spacer()
      } else {
        Image(systemName: "sparkles")
          .font(.title2)
          .foregroundStyle(Color.accentColor)
          .accessibilityHidden(true)
      }

      VStack(alignment: participant == .user ? .trailing : .leading, spacing: 8) {
        if let error {
          HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundStyle(.red)
              .accessibilityHidden(true)

            Text(error.localizedDescription.isEmpty ? "An error occurred." : error.localizedDescription)
              .font(.subheadline)

            Button("More information", systemImage: "info.circle") {
              presentErrorAction?(error)
            }
            .labelStyle(.iconOnly)

            if let onRetryMessageAction {
              Button {
                let target = resolvedMessageForCallback
                Task { @MainActor in
                  await onRetryMessageAction(target)
                }
              } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                  .font(.subheadline.weight(.medium))
              }
              .buttonStyle(.bordered)
              .controlSize(.small)
              .accessibilityIdentifier("message_retry_button")
            }
          }
          .padding()
          .background(Color.red.opacity(0.1))
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .accessibilityElement(children: .contain)
          .accessibilityIdentifier("message_error_banner")
        } else {
          // 1. Attached image
          if let imageURL, !imageURL.isEmpty, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
              if let image = phase.image {
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .frame(maxWidth: 260, maxHeight: 280)
                  .clipped()
                  .accessibilityLabel("Attached image")
              } else if phase.error != nil {
                Image(systemName: "icloud.slash")
                  .accessibilityLabel("Image failed to load")
              } else {
                ProgressView()
                  .frame(width: 80, height: 80)
              }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8.0))
            .accessibilityIdentifier("message_image")
          }

          // 2. Thinking trace (AI turn)
          if participant == .other, let thinking {
            ThinkingStateView(thinking: thinking)
          }

          // 3. Tool Call Group (AI turn)
          if participant == .other, !toolCalls.isEmpty {
            ToolCallsGroupView(toolCalls: toolCalls)
          }

          // 4. Agent Execution Plan (AI turn)
          if participant == .other, let plan {
            AgentPlanView(plan: plan)
          }

          // 5. HITL Approval Request (AI turn)
          if participant == .other, let approvalRequest {
            AgentApprovalView(request: approvalRequest)
          }

          // 6. Primary Markdown Content or Typing Indicator
          if let message, !message.isEmpty {
            EquatableMarkdownText(text: message)
              .equatable()
              .accessibilityIdentifier("message_text")
              .padding(participant == .user ? 16 : 0)
          } else if participant == .other && !hasAgenticSubsurfaces {
            TypingIndicator()
              .accessibilityIdentifier("typing_indicator")
          }

          // 7. Grounded Source Citations (AI turn)
          if participant == .other, !citations.isEmpty {
            SourceStackView(citations: citations)
          }
        }
      }
      .frame(maxWidth: fullWidth ? .infinity : nil, alignment: .leading)
      .modifier(UserBubbleStyleModifier(isUser: participant == .user))

      if participant == .other {
        Spacer()
      }
    }
    .listRowSeparator(.hidden)
  }
}

private struct UserBubbleStyleModifier: ViewModifier {
  let isUser: Bool

  func body(content: Content) -> some View {
    if isUser {
      content
        .background(Color.platformGray4)
        .clipShape(
          UnevenRoundedRectangle(
            topLeadingRadius: 20,
            bottomLeadingRadius: 20,
            bottomTrailingRadius: 8,
            topTrailingRadius: 20
          )
        )
    } else {
      content
    }
  }
}

private struct EquatableMarkdownText: View, Equatable {
  let text: String

  static func == (lhs: EquatableMarkdownText, rhs: EquatableMarkdownText) -> Bool {
    lhs.text.utf8.count == rhs.text.utf8.count && lhs.text == rhs.text
  }

  var body: some View {
    Markdown(text)
  }
}

struct TypingIndicator: View {
  @State private var offset: CGFloat = 0

  var body: some View {
    HStack(spacing: 4) {
      Circle()
        .fill(Color.secondary)
        .frame(width: 6, height: 6)
        .offset(y: offset)
        .animation(.easeInOut(duration: 0.5).repeatForever().delay(0.0), value: offset)
      Circle()
        .fill(Color.secondary)
        .frame(width: 6, height: 6)
        .offset(y: offset)
        .animation(.easeInOut(duration: 0.5).repeatForever().delay(0.2), value: offset)
      Circle()
        .fill(Color.secondary)
        .frame(width: 6, height: 6)
        .offset(y: offset)
        .animation(.easeInOut(duration: 0.5).repeatForever().delay(0.4), value: offset)
    }
    .padding(.vertical, 8)
    .onAppear {
      offset = -4
    }
  }
}
