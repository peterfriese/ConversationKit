//
// MessageComposerView.swift
// ConversationKit
//
// Created by Peter Friese on 03.07.25.
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

extension EnvironmentValues {
  @Entry var onSubmitAction: () -> Void = {}
  @Entry var disableAttachments: Bool = false
  @Entry var attachmentActions: AnyView? = nil
}

extension View {
  public func onSubmitAction(_ action: @escaping () -> Void) -> some View {
    environment(\.onSubmitAction, action)
  }
  
  public func disableAttachments(_ disable: Bool = true) -> some View {
    environment(\.disableAttachments, disable)
  }
  
  public func attachmentActions<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    environment(\.attachmentActions, AnyView(content()))
  }
}

private enum ComposerMetrics {
  #if os(iOS)
  static let buttonSize: CGFloat = 44
  #else
  static let buttonSize: CGFloat = 32
  #endif
}

public struct MessageComposerView<AttachmentType: Attachment & View>: View {
  @Environment(\.onSubmitAction) private var onSubmitAction
  @Environment(\.disableAttachments) private var disableAttachments
  @Environment(\.attachmentActions) private var attachmentActions

  @Binding var message: String
  @Binding var attachments: [AttachmentType]

  public init(message: Binding<String>, attachments: Binding<[AttachmentType]>) {
    self._message = message
    self._attachments = attachments
  }

  public var body: some View {
    HStack(alignment: .bottom) {
      
      // Plus button sits OUTSIDE the text pill on both iOS and macOS now
      if !disableAttachments, let attachmentActions {
        Menu {
          attachmentActions
        } label: {
          Image(systemName: "plus")
            #if os(iOS)
            .foregroundStyle(.primary)
            #else
            .foregroundStyle(.secondary)
            .font(.callout.weight(.medium))
            #endif
        }
        .menuStyle(.borderlessButton)
        #if os(iOS)
        .controlSize(.large)
        .frame(width: ComposerMetrics.buttonSize, height: ComposerMetrics.buttonSize)
        .background(.regularMaterial)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.platformSeparator, lineWidth: 0.5))
        .padding(.trailing, 8)
        #else
        .menuIndicator(.hidden)
        .frame(width: ComposerMetrics.buttonSize, height: ComposerMetrics.buttonSize)
        .background(Color.platformSecondaryBackground)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.platformSeparator, lineWidth: 0.5))
        .padding(.trailing, 6)
        .padding(.bottom, 2) // Reset to standard bottom padding to align with the text field baseline
        #endif
      }

      VStack {
        if !attachments.isEmpty {
          VStack {
            AttachmentPreviewScrollView(attachments: $attachments)
              .padding(.top, 8)
            Divider()
              .padding(.horizontal, 8)
          }
          .padding(.bottom, -8)
        }

        HStack(alignment: .center) {
          TextField("Enter a message", text: $message, axis: .vertical)
            #if os(iOS)
            .frame(minHeight: 32)
            .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 0))
            #else
            .textFieldStyle(.plain)
            // Asymmetrical padding to push the text UP optically, offsetting AppKit's intrinsic baseline spacing
            .padding(EdgeInsets(top: 7, leading: 12, bottom: 9, trailing: 0))
            #endif
            .onSubmit(of: .text) { onSubmitAction() }

          Button(action: { onSubmitAction() }) {
            Image(systemName: "arrow.up")
              #if os(macOS)
              .font(.subheadline.weight(.bold))
              #endif
          }
          #if os(iOS)
          .buttonStyle(.borderedProminent)
          .buttonBorderShape(.circle)
          .controlSize(.regular)
          .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 7))
          #else
          .buttonStyle(.plain)
          .foregroundStyle(.white)
          // Specifically control the frame to match the + button
          .frame(width: ComposerMetrics.buttonSize, height: ComposerMetrics.buttonSize)
          .background(Color.accentColor)
          .clipShape(Circle())
          .padding(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 2))
          #endif
        }
      }
      .modifier(ComposerInputBackgroundModifier())
    }
    .modifier(ComposerGlassEffectModifier())
    #if os(iOS)
    .padding(.top, 8)
    .padding([.horizontal, .bottom], 16)
    #else
    .padding()
    #endif
  }
}

// MARK: - Progressive Disclosure Modifiers

/// Applies the platform-appropriate background to the text input/attachment area
private struct ComposerInputBackgroundModifier: ViewModifier {
  func body(content: Content) -> some View {
    #if os(iOS)
    content
      .background(.regularMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 22))
      .overlay(
        RoundedRectangle(cornerRadius: 22)
          .stroke(Color.platformSeparator, lineWidth: 0.5)
      )
    #else
    content
      .background(Color.platformSecondaryBackground)
      .clipShape(RoundedRectangle(cornerRadius: 18))
      .overlay(
        RoundedRectangle(cornerRadius: 18)
          .stroke(Color.platformSeparator, lineWidth: 0.5)
      )
    #endif
  }
}

/// Progressively discloses the iOS 26+ GlassEffectContainer only where appropriate
private struct ComposerGlassEffectModifier: ViewModifier {
  func body(content: Content) -> some View {
    #if os(iOS)
    #if compiler(>=6.2)
    if #available(iOS 26.0, *) {
      GlassEffectContainer {
        content
      }
    } else {
      content
    }
    #else
    content
    #endif
    #else
    content
    #endif
  }
}

extension MessageComposerView where AttachmentType == EmptyAttachment {
  public init(message: Binding<String>) {
    self._message = message
    self._attachments = .constant([])
  }
}

#Preview("With Attachments") {
  @Previewable @State var message = "Hello, world!"
  @Previewable @State var attachments = [
    ImageAttachment(image: PlatformImage.systemSymbol("photo")!),
    ImageAttachment(image: PlatformImage.systemSymbol("camera")!),
    ImageAttachment(image: PlatformImage.systemSymbol("mic")!)
  ]

  MessageComposerView(message: $message, attachments: $attachments)
    .attachmentActions {
        Button(action: { }) {
            Label("Photos", systemImage: "photo.on.rectangle.angled")
        }
    }
    .padding()
}

#Preview("Without Attachments") {
    @Previewable @State var message = "Hello, world!"

    MessageComposerView(message: $message)

}
