//
// AttachmentPreviewCard.swift
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

public struct AttachmentPreviewCard<AttachmentType: Attachment>: View {
  var attachment: AttachmentType
  var onDelete: () -> Void
  
  public init(attachment: AttachmentType, onDelete: @escaping () -> Void) {
    self.attachment = attachment
    self.onDelete = onDelete
  }
  
  public var body: some View {
    ZStack(alignment: .topTrailing) {
      AnyView(attachment.previewView())
      
      Button(action: onDelete) {
        Image(systemName: "xmark.circle.fill")
          .foregroundColor(.white)
          .background(Circle().fill(Color.black.opacity(0.6)))
      }
      .padding(4)
    }
  }
}

public struct ConcentricClipShapeModifier: ViewModifier {
  public func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content
        .clipShape(.rect(corners: .concentric(minimum: 12), isUniform: false))
    } else {
      content
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
  }
}

#Preview {
  AttachmentPreviewCard(attachment: ImageAttachment(image: UIImage(systemName: "photo")!)) {
    print("Delete action tapped")
  }
}
