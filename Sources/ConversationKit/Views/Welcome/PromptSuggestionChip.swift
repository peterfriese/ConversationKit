//
// PromptSuggestionChip.swift
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

/// A compact pill chip representing a starter prompt suggestion (`FR-1.2`).
public struct PromptSuggestionChip: View {
  public let suggestion: PromptSuggestion
  public let action: () -> Void

  public init(suggestion: PromptSuggestion, action: @escaping () -> Void) {
    self.suggestion = suggestion
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if let icon = suggestion.icon, !icon.isEmpty {
          Image(systemName: icon)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.accentColor)
        }

        Text(suggestion.title)
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.primary)
          .lineLimit(1)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 8)
      .background(Color.platformSecondaryBackground)
      .clipShape(Capsule())
      .overlay(
        Capsule()
          .stroke(Color.platformSeparator, lineWidth: 0.5)
      )
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("prompt_suggestion_chip_\(suggestion.id)")
  }
}

#Preview {
  HStack {
    PromptSuggestionChip(
      suggestion: PromptSuggestion(
        id: "summarize",
        title: "Summarize an article",
        icon: "doc.text.magnifyingglass",
        category: "Productivity"
      )
    ) {}
    PromptSuggestionChip(
      suggestion: PromptSuggestion(
        id: "debug",
        title: "Debug a Swift concurrency warning",
        icon: "ladybug",
        category: "Code"
      )
    ) {}
  }
  .padding()
}
