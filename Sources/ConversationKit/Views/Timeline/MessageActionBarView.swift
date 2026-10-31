//
// MessageActionBarView.swift
// ConversationKit
//
// Created by Peter Friese on 31.10.26.
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

/// Turnkey action bar displayed below completed assistant messages (`FR-2.4` / `AC-7`).
///
/// Renders Copy, Regenerate (when `onRegenerateMessageAction` is provided),
/// Thumbs Up / Thumbs Down rating buttons (when `onRateMessageAction` is provided),
/// and a native `ShareLink` when the message contains non-empty text.
public struct MessageActionBarView: View {
  @Environment(\.onRegenerateMessageAction) private var onRegenerateMessageAction
  @Environment(\.onRateMessageAction) private var onRateMessageAction

  private let message: any Message
  private let onRegenerateOverride: (@MainActor (any Message) -> Void)?

  @State private var copyTrigger: UUID?
  @State private var showCopiedCheckmark: Bool = false
  @State private var overriddenRating: MessageRating??

  public init(
    message: any Message,
    onRegenerate: (@MainActor (any Message) -> Void)? = nil
  ) {
    self.message = message
    self.onRegenerateOverride = onRegenerate
  }

  public init(content: String?, rating: MessageRating? = nil) {
    self.message = DefaultMessage(
      content: content,
      participant: .other,
      rating: rating
    )
    self.onRegenerateOverride = nil
  }

  private var effectiveRating: MessageRating? {
    if let overriddenRating {
      return overriddenRating
    }
    return message.rating
  }

  private var shareableText: String? {
    guard let content = message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
          !content.isEmpty
    else {
      return nil
    }
    return content
  }

  public var body: some View {
    HStack(spacing: 12) {
      Button {
        PlatformPasteboard.copy(message.content ?? "")
        showCopiedCheckmark = true
        copyTrigger = UUID()
      } label: {
        Image(systemName: showCopiedCheckmark ? "checkmark" : "doc.on.doc")
          .contentTransition(.symbolEffect(.replace))
      }
      .buttonStyle(.borderless)
      .foregroundStyle(showCopiedCheckmark ? Color.accentColor : Color.secondary)
      .accessibilityIdentifier("message_copy_button")
      .accessibilityLabel(showCopiedCheckmark ? Text("Copied") : Text("Copy message"))
      .task(id: copyTrigger) {
        guard copyTrigger != nil else { return }
        try? await Task.sleep(for: .milliseconds(1500))
        guard !Task.isCancelled else { return }
        showCopiedCheckmark = false
      }

      if onRegenerateOverride != nil || onRegenerateMessageAction != nil {
        Button {
          if let onRegenerateOverride {
            onRegenerateOverride(message)
          } else if let onRegenerateMessageAction {
            Task { @MainActor in
              await onRegenerateMessageAction(message)
            }
          }
        } label: {
          Image(systemName: "arrow.clockwise")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("message_regenerate_button")
        .accessibilityLabel(Text("Regenerate response"))
      }

      if let onRateMessageAction {
        Button {
          let nextRating: MessageRating? = (effectiveRating == .up) ? nil : .up
          overriddenRating = .some(nextRating)
          onRateMessageAction(message, nextRating)
        } label: {
          Image(systemName: effectiveRating == .up ? "hand.thumbsup.fill" : "hand.thumbsup")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(effectiveRating == .up ? Color.accentColor : Color.secondary)
        .accessibilityIdentifier("message_rate_up_button")
        .accessibilityLabel(Text("Helpful"))
        .accessibilityAddTraits(effectiveRating == .up ? .isSelected : [])

        Button {
          let nextRating: MessageRating? = (effectiveRating == .down) ? nil : .down
          overriddenRating = .some(nextRating)
          onRateMessageAction(message, nextRating)
        } label: {
          Image(systemName: effectiveRating == .down ? "hand.thumbsdown.fill" : "hand.thumbsdown")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(effectiveRating == .down ? Color.accentColor : Color.secondary)
        .accessibilityIdentifier("message_rate_down_button")
        .accessibilityLabel(Text("Not helpful"))
        .accessibilityAddTraits(effectiveRating == .down ? .isSelected : [])
      }

      if let shareableText {
        ShareLink(item: shareableText) {
          Image(systemName: "square.and.arrow.up")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("message_share_button")
        .accessibilityLabel(Text("Share message"))
      }
    }
    .font(.subheadline)
    .padding(.top, 2)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("message_action_bar")
    .onChange(of: message.rating) { _, newValue in
      overriddenRating = nil
    }
  }
}

#Preview {
  MessageActionBarView(
    message: DefaultMessage(
      content: "Here is a sample assistant reply.",
      participant: .other
    )
  )
  .onRegenerateMessage { _ in }
  .onRateMessage { _, _ in }
  .padding()
}
