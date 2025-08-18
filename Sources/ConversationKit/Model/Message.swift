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

public protocol Message: Identifiable, Hashable {
  var content: String? { get set }
  var participant: Participant { get }
  var error: Error? { get }
  var imageURL: String? { get }

  init(content: String?, participant: Participant)
}

public extension Message {
  public var imageURL: String? { nil }
}

public struct DefaultMessage: Message {
  public let id: UUID = .init()
  public var content: String?
  public let participant: Participant
  public let error: (any Error)?
  public var imageURL: String? = nil
  
  public init(content: String? = nil, imageURL: String? = nil, participant: Participant, error: (any Error)? = nil) {
    self.content = content
    self.imageURL = imageURL
    self.participant = participant
    self.error = error
  }
  
  // Protocol-required initializer
  public init(content: String?, participant: Participant) {
    self.content = content
    self.participant = participant
    self.error = nil
  }
}

// Implement Equatable and Hashable for DefaultMessage (ignore error)
extension DefaultMessage {
  public static func == (lhs: DefaultMessage, rhs: DefaultMessage) -> Bool {
    lhs.id == rhs.id &&
    lhs.content == rhs.content &&
    lhs.imageURL == rhs.imageURL &&
    lhs.participant == rhs.participant
    // intentionally ignore `error`
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(content)
    hasher.combine(imageURL)
    hasher.combine(participant)
    // intentionally ignore `error`
  }
}
