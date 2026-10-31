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

public struct AttachmentPreviewCard<AttachmentType: Attachment & View>: View {
  var attachment: AttachmentType
  var onDelete: () -> Void

  public init(attachment: AttachmentType, onDelete: @escaping () -> Void) {
    self.attachment = attachment
    self.onDelete = onDelete
  }

  public var body: some View {
    ZStack(alignment: .topTrailing) {
      ZStack {
        attachment

        if let progress = attachment.uploadProgress, (0.0..<1.0).contains(progress) {
          ZStack {
            Color.black.opacity(0.45)

            CircularUploadProgressRing(progress: progress)
              .frame(width: 24, height: 24)
              .accessibilityIdentifier("attachment_upload_progress")
              .accessibilityLabel("Upload progress")
              .accessibilityValue("\(Int((progress * 100).rounded())) percent")
          }
        }
      }

      Button(action: onDelete) {
        Image(systemName: "xmark.circle.fill")
          .foregroundStyle(.white)
          .background(Circle().fill(Color.black.opacity(0.6)))
      }
      .accessibilityLabel("Remove attachment")
      .padding(4)
    }
  }
}

private struct CircularUploadProgressRing: View {
  let progress: Double

  var body: some View {
    ZStack {
      Circle()
        .stroke(Color.white.opacity(0.35), lineWidth: 2.5)

      Circle()
        .trim(from: 0, to: min(max(progress, 0.0), 1.0))
        .stroke(
          Color.white,
          style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .animation(.smooth(duration: 0.2), value: progress)
    }
  }
}

public struct ConcentricClipShapeModifier: ViewModifier {
  public func body(content: Content) -> some View {
#if compiler(>=6.2)
    if #available(iOS 26.0, macOS 26.0, *) {
      content
        .clipShape(.rect(corners: Edge.Corner.Style.concentric(minimum: 12), isUniform: false))
    } else {
      clipShapeLegacy(content: content)
    }
#else
    clipShapeLegacy(content: content)
#endif // compiler(>=6.2)
  }

  private func clipShapeLegacy(content: Content) -> some View {
    content
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.platformSeparator, lineWidth: 0.5)
      )
  }
}

#Preview {
  AttachmentPreviewCard(attachment: ImageAttachment(image: PlatformImage.systemSymbol("photo")!)) {
    print("Delete action tapped")
  }
}
