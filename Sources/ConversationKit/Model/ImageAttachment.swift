//
// ImageAttachment.swift
// ConversationKit
//
// Created by Peter Friese on 01.09.25.
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

public struct ImageAttachment: Attachment {
  public let id = UUID()
  public let image: UIImage

  public init(image: UIImage) {
    self.image = image
  }

  public static func == (lhs: ImageAttachment, rhs: ImageAttachment) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
