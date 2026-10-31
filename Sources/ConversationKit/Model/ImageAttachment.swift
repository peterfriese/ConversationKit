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

public struct ImageAttachment: Attachment, @unchecked Sendable {
  public let id: UUID
  public let image: PlatformImage
  public var uploadProgress: Double?
  public var uploadError: (any Error)?

  public init(
    id: UUID = UUID(),
    image: PlatformImage,
    uploadProgress: Double? = nil,
    uploadError: (any Error)? = nil
  ) {
    self.id = id
    self.image = image
    self.uploadProgress = uploadProgress
    self.uploadError = uploadError
  }

  public static func == (lhs: ImageAttachment, rhs: ImageAttachment) -> Bool {
    lhs.id == rhs.id &&
    lhs.uploadProgress == rhs.uploadProgress &&
    (lhs.uploadError != nil) == (rhs.uploadError != nil) &&
    lhs.uploadError?.localizedDescription == rhs.uploadError?.localizedDescription
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(uploadProgress)
    hasher.combine(uploadError != nil)
    hasher.combine(uploadError?.localizedDescription)
  }
}

extension ImageAttachment: View {
  public var body: some View {
    Image(platformImage: image)
      .resizable()
      .aspectRatio(contentMode: .fill)
      .frame(width: 100, height: 100)
      .modifier(ConcentricClipShapeModifier())
      .accessibilityLabel("Photo attachment")
  }
}
