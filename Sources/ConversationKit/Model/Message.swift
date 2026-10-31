//
// Message.swift
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

import Foundation

public enum Participant: String, Hashable, Sendable {
  case other
  case user
}

public protocol Message: Identifiable, Hashable {
  var content: String? { get set }
  var imageURL: String? { get }
  var participant: Participant { get }
  var error: Error? { get }

  // vNext Agentic Surface & Turn Lifecycle Properties
  var thinking: ThinkingTrace? { get }
  var toolCalls: [ToolCall] { get }
  var citations: [Citation] { get }
  var plan: AgentPlan? { get }
  var approvalRequest: ApprovalRequest? { get }
  var isStreaming: Bool { get }
  var rating: MessageRating? { get }

  init(content: String?, imageURL: String?, participant: Participant)
}

public extension Message {
  var thinking: ThinkingTrace? { nil }
  var toolCalls: [ToolCall] { [] }
  var citations: [Citation] { [] }
  var plan: AgentPlan? { nil }
  var approvalRequest: ApprovalRequest? { nil }
  var isStreaming: Bool { false }
  var rating: MessageRating? { nil }
}

public struct DefaultMessage: Message, Sendable {
  public let id: UUID
  public var content: String?
  public var imageURL: String?
  public var participant: Participant
  public var error: (any Error)?
  public var thinking: ThinkingTrace?
  public var toolCalls: [ToolCall]
  public var citations: [Citation]
  public var plan: AgentPlan?
  public var approvalRequest: ApprovalRequest?
  public var isStreaming: Bool
  public var rating: MessageRating?

  public init(
    id: UUID = UUID(),
    content: String? = nil,
    imageURL: String? = nil,
    participant: Participant,
    error: (any Error)? = nil,
    thinking: ThinkingTrace? = nil,
    toolCalls: [ToolCall] = [],
    citations: [Citation] = [],
    plan: AgentPlan? = nil,
    approvalRequest: ApprovalRequest? = nil,
    isStreaming: Bool = false,
    rating: MessageRating? = nil
  ) {
    self.id = id
    self.content = content
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
  }

  // Protocol-required initializer
  public init(content: String?, imageURL: String?, participant: Participant) {
    self.id = UUID()
    self.content = content
    self.imageURL = imageURL
    self.participant = participant
    self.error = nil
    self.thinking = nil
    self.toolCalls = []
    self.citations = []
    self.plan = nil
    self.approvalRequest = nil
    self.isStreaming = false
    self.rating = nil
  }
}

extension DefaultMessage {
  public static func == (lhs: DefaultMessage, rhs: DefaultMessage) -> Bool {
    lhs.id == rhs.id &&
    lhs.isStreaming == rhs.isStreaming &&
    lhs.participant == rhs.participant &&
    lhs.rating == rhs.rating &&
    lhs.content?.utf8.count == rhs.content?.utf8.count &&
    (lhs.error != nil) == (rhs.error != nil) &&
    lhs.content == rhs.content &&
    lhs.imageURL == rhs.imageURL &&
    lhs.thinking == rhs.thinking &&
    lhs.toolCalls == rhs.toolCalls &&
    lhs.citations == rhs.citations &&
    lhs.plan == rhs.plan &&
    lhs.approvalRequest == rhs.approvalRequest &&
    lhs.error?.localizedDescription == rhs.error?.localizedDescription
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(content)
    hasher.combine(imageURL)
    hasher.combine(participant)
    hasher.combine(error != nil)
    hasher.combine(error?.localizedDescription)
    hasher.combine(thinking)
    hasher.combine(toolCalls)
    hasher.combine(citations)
    hasher.combine(plan)
    hasher.combine(approvalRequest)
    hasher.combine(isStreaming)
    hasher.combine(rating)
  }
}
