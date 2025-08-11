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

public enum Participant {
  case other
  case user
}

public struct Message: Identifiable {
  public let id: UUID = .init()
  public var content: String
  public let imageURL: String?
  public let participant: Participant
  public var pending = false
  public var metadata: [String: Any]

  public init(content: String = "", imageURL: String? = nil, participant: Participant, pending: Bool = false, metadata: [String: Any] = [:]) {
    self.content = content
    self.imageURL = imageURL
    self.participant = participant
    self.pending = pending
    self.metadata = metadata
  }
  
  public static func pending(participant: Participant) -> Message {
    Self(content: "", participant: participant, pending: true)
  }
}

extension Message: Equatable {
  public static func == (lhs: Message, rhs: Message) -> Bool {
    return lhs.id == rhs.id &&
           lhs.content == rhs.content &&
           lhs.imageURL == rhs.imageURL &&
           lhs.participant == rhs.participant &&
           lhs.pending == rhs.pending
    // Note: metadata is intentionally NOT compared
  }
}

extension Message: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(content)
    hasher.combine(imageURL)
    hasher.combine(participant)
    hasher.combine(pending)
    // Note: metadata is intentionally NOT included in hash
  }
}
