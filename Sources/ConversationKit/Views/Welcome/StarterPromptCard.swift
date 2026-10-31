//
// StarterPromptCard.swift
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

/// A categorized card presenting a starter prompt in `ConversationWelcomeView` (`FR-1.3`).
public struct StarterPromptCard: View {
  public let suggestion: PromptSuggestion
  public let action: () -> Void

  public init(suggestion: PromptSuggestion, action: @escaping () -> Void) {
    self.suggestion = suggestion
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 6) {
          if let icon = suggestion.icon, !icon.isEmpty {
            Image(systemName: icon)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(Color.accentColor)
          }

          if let category = suggestion.category, !category.isEmpty {
            Text(category)
              .font(.caption.weight(.semibold))
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }

          Spacer(minLength: 0)
        }

        Text(suggestion.title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
          .multilineTextAlignment(.leading)
          .lineLimit(2)

        if let subtitle = suggestion.subtitle, !subtitle.isEmpty {
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(14)
      .background(Color.platformSecondaryBackground)
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(Color.platformSeparator, lineWidth: 0.5)
      )
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("starter_prompt_card_\(suggestion.id)")
  }
}

#Preview {
  StarterPromptCard(
    suggestion: PromptSuggestion(
      id: "architecture",
      title: "Review my SwiftUI architecture",
      subtitle: "Evaluate state management and scroll performance",
      icon: "building.columns",
      category: "Architecture"
    )
  ) {}
  .padding()
}
