//
//  MessageComposerView.swift
//  ConversationKit
//
//  Created by Peter Friese on 03.07.25.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI

public struct OnSubmitAction {
  private let handler: @MainActor () -> Void

  public init(handler: @escaping @MainActor () -> Void = {}) {
    self.handler = handler
  }

  @MainActor
  public func callAsFunction() {
    handler()
  }
}

public struct OnStopAction {
  private let handler: @MainActor () -> Void

  public init(handler: @escaping @MainActor () -> Void = {}) {
    self.handler = handler
  }

  @MainActor
  public func callAsFunction() {
    handler()
  }
}

extension EnvironmentValues {
  @Entry var onSubmitAction: OnSubmitAction = OnSubmitAction()
  @Entry var onStopAction: OnStopAction = OnStopAction()
  @Entry var isGenerating: Bool = false
  @Entry var disableAttachments: Bool = false
  @Entry var attachmentActions: AnyView? = nil
}

public extension View {
  /// Defines the closure executed when the user taps the send button (or hits return).
  @MainActor
  func onSubmitAction(_ action: @escaping @MainActor () -> Void) -> some View {
    environment(\.onSubmitAction, OnSubmitAction(handler: action))
  }

  /// Defines the closure executed when the user taps the stop button during active generation.
  /// Used to cooperatively cancel the background task running the submit action.
  @MainActor
  func onStopAction(_ action: @escaping @MainActor () -> Void) -> some View {
    environment(\.onStopAction, OnStopAction(handler: action))
  }

  /// Injects the current background execution state to toggle the Send button into a Stop button.
  func isGenerating(_ isGenerating: Bool) -> some View {
    environment(\.isGenerating, isGenerating)
  }

  /// Disables the attachment (+) button inside the `MessageComposerView`.
  func disableAttachments(_ disable: Bool = true) -> some View {
    environment(\.disableAttachments, disable)
  }

  /// Defines a custom set of buttons to be displayed when the attachment (+) button is tapped.
  func attachmentActions<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    environment(\.attachmentActions, AnyView(content()))
  }
}

private enum ComposerMetrics {
  #if os(iOS)
  static let buttonSize: CGFloat = 44
  #else
  static let buttonSize: CGFloat = 32
  #endif
  static let triggerTrimSet = CharacterSet(charactersIn: "/@")
}

public struct MessageComposerView<AttachmentType: Attachment & View>: View {
  @Environment(\.onSubmitAction) private var onSubmitAction
  @Environment(\.onStopAction) private var onStopAction
  @Environment(\.isGenerating) private var isGenerating
  @Environment(\.disableAttachments) private var disableAttachments
  @Environment(\.attachmentActions) private var attachmentActions
  @Environment(\.composerModels) private var composerModels
  @Environment(\.selectedComposerModelID) private var selectedComposerModelID
  @Environment(\.availableComposerCapabilities) private var availableComposerCapabilities
  @Environment(\.activeComposerCapabilities) private var activeComposerCapabilities
  @Environment(\.slashCommands) private var slashCommands
  @Environment(\.mentionSuggestions) private var mentionSuggestions
  @Environment(\.activeComposerTokens) private var activeComposerTokens

  @Binding var message: String
  @Binding var attachments: [AttachmentType]

  @State private var fallbackSelectedModelID: String?
  @State private var fallbackActiveCapabilities: Set<ComposerCapability> = []
  @State private var fallbackActiveTokens: [ComposerTokenChip] = []

  public init(message: Binding<String>, attachments: Binding<[AttachmentType]>) {
    self._message = message
    self._attachments = attachments
  }

  /// Detects `/` or `@` trigger prefixes at the current word boundary and filters `slashCommands` or `mentions` case-insensitively (`AC-16`).
  public static func matchingSuggestions(
    for text: String,
    slashCommands: [ComposerTokenChip],
    mentions: [ComposerTokenChip]
  ) -> (triggerQuery: String, suggestions: [ComposerTokenChip])? {
    guard !text.isEmpty,
          let lastChar = text.last,
          !lastChar.isWhitespace,
          !lastChar.isNewline
    else {
      return nil
    }

    let wordStart = text.lastIndex(where: { $0.isWhitespace || $0.isNewline })
      .map { text.index(after: $0) } ?? text.startIndex
    let lastWord = String(text[wordStart..<text.endIndex])
    guard !lastWord.isEmpty else { return nil }

    if lastWord.hasPrefix("/") {
      guard !slashCommands.isEmpty else { return nil }
      let rawQuery = String(lastWord.dropFirst())
      guard !rawQuery.hasPrefix("/"), !rawQuery.contains("/") else { return nil }
      let filtered = slashCommands.filter { item in
        guard !rawQuery.isEmpty else { return true }
        let cleanTrigger = item.trigger.trimmingCharacters(in: ComposerMetrics.triggerTrimSet)
        let cleanValue = item.value.trimmingCharacters(in: ComposerMetrics.triggerTrimSet)
        return cleanTrigger.localizedCaseInsensitiveContains(rawQuery)
          || item.title.localizedCaseInsensitiveContains(rawQuery)
          || cleanValue.localizedCaseInsensitiveContains(rawQuery)
      }
      guard !filtered.isEmpty else { return nil }
      return (triggerQuery: lastWord, suggestions: filtered)
    } else if lastWord.hasPrefix("@") {
      guard !mentions.isEmpty else { return nil }
      let rawQuery = String(lastWord.dropFirst())
      guard !rawQuery.hasPrefix("@") else { return nil }
      let filtered = mentions.filter { item in
        guard !rawQuery.isEmpty else { return true }
        let cleanTrigger = item.trigger.trimmingCharacters(in: ComposerMetrics.triggerTrimSet)
        let cleanValue = item.value.trimmingCharacters(in: ComposerMetrics.triggerTrimSet)
        return cleanTrigger.localizedCaseInsensitiveContains(rawQuery)
          || item.title.localizedCaseInsensitiveContains(rawQuery)
          || cleanValue.localizedCaseInsensitiveContains(rawQuery)
      }
      guard !filtered.isEmpty else { return nil }
      return (triggerQuery: lastWord, suggestions: filtered)
    }

    return nil
  }

  /// Inserts `suggestion` into `tokens` (if not already present) and strips the trailing `triggerQuery` from `text` (`AC-16`).
  public static func applySuggestion(
    _ suggestion: ComposerTokenChip,
    to text: inout String,
    triggerQuery: String,
    tokens: inout [ComposerTokenChip]
  ) {
    if !tokens.contains(where: { $0.id == suggestion.id }) {
      tokens.append(suggestion)
    }
    if let range = text.range(of: triggerQuery, options: .backwards) {
      text.removeSubrange(range)
      while let last = text.last, last == " " || last == "\t" {
        text.removeLast()
      }
      if !text.contains(where: { !$0.isWhitespace && !$0.isNewline }) {
        text = ""
      }
    }
  }

  private var effectiveSelectedModelIDBinding: Binding<String?> {
    selectedComposerModelID ?? $fallbackSelectedModelID
  }

  private var effectiveCapabilitiesBinding: Binding<Set<ComposerCapability>> {
    activeComposerCapabilities ?? $fallbackActiveCapabilities
  }

  private var effectiveTokensBinding: Binding<[ComposerTokenChip]> {
    activeComposerTokens ?? $fallbackActiveTokens
  }

  private var hasBottomAccessories: Bool {
    !composerModels.isEmpty || !availableComposerCapabilities.isEmpty
  }

  private var activeSuggestionMatch: (triggerQuery: String, suggestions: [ComposerTokenChip])? {
    Self.matchingSuggestions(
      for: message,
      slashCommands: slashCommands,
      mentions: mentionSuggestions
    )
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let match = activeSuggestionMatch {
        ComposerSuggestionPopupView(suggestions: match.suggestions) { chosen in
          var updatedText = message
          var updatedTokens = effectiveTokensBinding.wrappedValue
          Self.applySuggestion(
            chosen,
            to: &updatedText,
            triggerQuery: match.triggerQuery,
            tokens: &updatedTokens
          )
          message = updatedText
          effectiveTokensBinding.wrappedValue = updatedTokens
        }
      }

      HStack(alignment: .bottom) {
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
          .accessibilityIdentifier("attachment_button")
          .accessibilityLabel("Add attachment")
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

        VStack(alignment: .leading, spacing: 0) {
          if !attachments.isEmpty {
            VStack {
              AttachmentPreviewScrollView(attachments: $attachments)
                .padding(.top, 8)
              Divider()
                .padding(.horizontal, 8)
            }
            .padding(.bottom, -8)
          }

          if !effectiveTokensBinding.wrappedValue.isEmpty {
            ComposerActiveTokensBar(tokens: effectiveTokensBinding.wrappedValue) { removed in
              effectiveTokensBinding.wrappedValue.removeAll { $0.id == removed.id }
            }
          }

          HStack(alignment: .bottom) {
            let hasContent = message.contains(where: { !$0.isWhitespace && !$0.isNewline })
              || !attachments.isEmpty
              || !effectiveTokensBinding.wrappedValue.isEmpty
            let hasIncompleteOrFailedAttachment = attachments.contains { attachment in
              if attachment.uploadError != nil {
                return true
              }
              if let progress = attachment.uploadProgress {
                return progress < 1.0
              }
              return false
            }
            let canSubmit = hasContent && !hasIncompleteOrFailedAttachment

            TextField("Enter a message", text: $message, axis: .vertical)
              #if os(iOS)
              .frame(minHeight: 32)
              .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 0))
              #else
              .textFieldStyle(.plain)
              // Asymmetrical padding to push the text UP optically, offsetting AppKit's intrinsic baseline spacing
              .padding(EdgeInsets(top: 7, leading: 12, bottom: 9, trailing: 0))
              #endif
              .accessibilityIdentifier("message_input_field")
              .onSubmit(of: .text) {
                if !isGenerating && canSubmit {
                  onSubmitAction()
                }
              }

            Button(action: {
              if isGenerating {
                onStopAction()
              } else if canSubmit {
                onSubmitAction()
              }
            }) {
              Image(systemName: isGenerating ? "stop.fill" : "arrow.up")
                #if os(macOS)
                .font(isGenerating ? .system(size: 11, weight: .black) : .subheadline.weight(.bold))
                #else
                .font(isGenerating ? .system(size: 14, weight: .black) : .body.weight(.semibold))
                #endif
            }
            .accessibilityIdentifier("composer_primary_button")
            .accessibilityLabel(isGenerating ? Text("Stop generating") : Text("Send message"))
            .disabled(!isGenerating && !canSubmit)
            #if os(iOS)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .controlSize(.regular)
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 7))
            #else
            .buttonStyle(.plain)
            .foregroundStyle((isGenerating || canSubmit) ? .white : Color.secondary)
            // Specifically control the frame to match the + button
            .frame(width: ComposerMetrics.buttonSize, height: ComposerMetrics.buttonSize)
            .background((isGenerating || canSubmit) ? Color.accentColor : Color.secondary.opacity(0.2))
            .clipShape(Circle())
            .padding(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 2))
            #endif
          }

          if hasBottomAccessories {
            ComposerBottomAccessoryRow(
              models: composerModels,
              selectedModelID: effectiveSelectedModelIDBinding,
              capabilities: availableComposerCapabilities,
              activeCapabilities: effectiveCapabilitiesBinding
            )
          }
        }
        .modifier(ComposerInputBackgroundModifier())
      }
      .modifier(ComposerGlassEffectModifier())
    }
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
  @Previewable @State var message = "How does the sticky top scroll work?"
  @Previewable @State var attachments = [
    ImageAttachment(image: PlatformImage.systemSymbol("photo")!),
    ImageAttachment(image: PlatformImage.systemSymbol("camera")!),
    ImageAttachment(image: PlatformImage.systemSymbol("mic")!)
  ]

  MessageComposerView(message: $message, attachments: $attachments)
    .attachmentActions {
      Button(action: {}) {
        Label("Photos", systemImage: "photo.on.rectangle.angled")
      }
    }
    .padding()
}

#Preview("Without Attachments") {
  @Previewable @State var message = "Tell me more about ConversationKit."

  MessageComposerView(message: $message)
}
