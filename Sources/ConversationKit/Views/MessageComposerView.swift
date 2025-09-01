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
  @Entry var attachmentActions: AnyView = AnyView(EmptyView())
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

public struct MessageComposerView<AttachmentType: Attachment>: View {
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
    if #available(iOS 26.0, *) {
      GlassEffectContainer {
        HStack(alignment: .bottom) {
          if !disableAttachments {
            Menu {
              attachmentActions
            } label: {
              Image(systemName: "plus")
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .buttonBorderShape(.circle)
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

            HStack(alignment: .bottom) {
              TextField("Enter a message", text: $message, axis: .vertical)
                .frame(minHeight: 32)
                .padding(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 0))
                .onSubmit(of: .text) { onSubmitAction() }

              Button(action: { onSubmitAction() }) {
                Image(systemName: "arrow.up")
              }
              .buttonStyle(.borderedProminent)
              .padding(EdgeInsets(top: 7, leading: 0, bottom: 7, trailing: 7))
            }
          }
          .clipShape(.rect(cornerRadius: 20.0))
          .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20.0))
          .offset(x: -5.0, y: 0.0)
        }
      }
      .padding([.horizontal, .bottom], 8)
    } else {
      // provide compatible attachment actions and glass effect for iOS 18 and below
      HStack(alignment: .bottom) {
        if !disableAttachments {
          Menu {
            attachmentActions
          } label: {
            Image(systemName: "plus")
              .foregroundColor(.primary)
          }
          .controlSize(.large)
          .frame(width: 44, height: 44)
          .background(.regularMaterial)
          .clipShape(Circle())
          .overlay(
            Circle()
              .stroke(Color(.separator), lineWidth: 0.5)
          )
          .padding(.trailing, 8)
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

          HStack(alignment: .bottom) {
            TextField("Enter a message", text: $message, axis: .vertical)
              .frame(minHeight: 32)
              .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 0))
              .onSubmit(of: .text) { onSubmitAction() }

            Button(action: { onSubmitAction() }) {
              Image(systemName: "arrow.up")
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .controlSize(.regular)
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 7))
          }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
          RoundedRectangle(cornerRadius: 22)
            .stroke(Color(.separator), lineWidth: 0.5)
        )
      }
      .padding(.top, 8)
      .padding([.horizontal, .bottom], 16)
    }
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
    ImageAttachment(image: Image(systemName: "photo")),
    ImageAttachment(image: Image(systemName: "camera")),
    ImageAttachment(image: Image(systemName: "mic"))
  ]

  MessageComposerView(message: $message, attachments: $attachments)
    .padding()
}
