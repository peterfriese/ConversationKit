//
// AttachmentPreviewScrollView.swift
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

struct AttachmentPreviewScrollView<AttachmentType: Attachment & View>: View {
  @Binding var attachments: [AttachmentType]

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        ForEach(attachments) { attachment in
          AttachmentPreviewCard(attachment: attachment) {
            withAnimation {
              attachments.removeAll { $0.id == attachment.id }
            }
          }
        }
      }
      .padding(.horizontal, 8)
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State var attachments = [
      ImageAttachment(image: UIImage(systemName: "photo")!),
      ImageAttachment(image: UIImage(systemName: "camera")!),
      ImageAttachment(image: UIImage(systemName: "mic")!)
    ]

    var body: some View {
      AttachmentPreviewScrollView(attachments: $attachments)
    }
  }
  return PreviewWrapper()
}
