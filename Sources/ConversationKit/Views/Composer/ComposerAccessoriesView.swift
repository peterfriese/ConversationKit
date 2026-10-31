//
// ComposerAccessoriesView.swift
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

/// Floating autocomplete popup anchored above `MessageComposerView` for `/` slash commands and `@` mentions (`FR-4.4`, `AC-16`).
public struct ComposerSuggestionPopupView: View {
  public let suggestions: [ComposerTokenChip]
  public let onSelect: (ComposerTokenChip) -> Void

  public init(
    suggestions: [ComposerTokenChip],
    onSelect: @escaping (ComposerTokenChip) -> Void
  ) {
    self.suggestions = suggestions
    self.onSelect = onSelect
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      ForEach(suggestions) { item in
        Button {
          onSelect(item)
        } label: {
          HStack(spacing: 8) {
            Image(systemName: item.icon ?? defaultIcon(for: item.kind))
              .font(.caption.weight(.semibold))
              .foregroundStyle(Color.accentColor)
              .frame(width: 18)

            Text(formattedTrigger(for: item))
              .font(.system(.caption, design: .monospaced).weight(.semibold))
              .foregroundStyle(.primary)

            Text(item.title)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)

            Spacer(minLength: 0)
          }
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("composer_suggestion_item_\(item.id)")
      }
    }
    .padding(6)
    .background(Color.platformSecondaryBackground)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(
      RoundedRectangle(cornerRadius: 14)
        .stroke(Color.platformSeparator, lineWidth: 0.5)
    )
    .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("composer_suggestion_popup")
  }

  private func defaultIcon(for kind: ComposerTokenChip.Kind) -> String {
    switch kind {
    case .slashCommand:
      return "terminal"
    case .mention:
      return "at"
    }
  }

  private func formattedTrigger(for item: ComposerTokenChip) -> String {
    let prefix = item.kind == .slashCommand ? "/" : "@"
    if item.trigger.hasPrefix(prefix) {
      return item.trigger
    }
    return "\(prefix)\(item.trigger)"
  }
}

/// Horizontal strip of active `ComposerTokenChip` pills rendered inside `MessageComposerView` (`FR-4.4`, `AC-16`).
struct ComposerActiveTokensBar: View {
  let tokens: [ComposerTokenChip]
  let onRemove: (ComposerTokenChip) -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 6) {
        ForEach(tokens) { token in
          HStack(spacing: 4) {
            if let icon = token.icon, !icon.isEmpty {
              Image(systemName: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.accentColor)
            } else {
              Text(token.kind == .slashCommand ? "/" : "@")
                .font(.system(.caption2, design: .monospaced).weight(.bold))
                .foregroundStyle(Color.accentColor)
            }

            Text(token.title)
              .font(.caption.weight(.medium))
              .foregroundStyle(.primary)
              .lineLimit(1)

            Button {
              onRemove(token)
            } label: {
              Image(systemName: "xmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(token.title)")
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.accentColor.opacity(0.12))
          .clipShape(Capsule())
          .accessibilityIdentifier("composer_token_chip_\(token.id)")
        }
      }
      .padding(.horizontal, 12)
      .padding(.top, 8)
    }
    .accessibilityIdentifier("composer_active_tokens_bar")
  }
}

/// Bottom accessory row inside `MessageComposerView` hosting the model picker and capability toggle chips (`FR-4.2`, `FR-4.3`, `AC-14`, `AC-15`).
struct ComposerBottomAccessoryRow: View {
  let models: [ComposerModelOption]
  @Binding var selectedModelID: String?
  let capabilities: [ComposerCapability]
  @Binding var activeCapabilities: Set<ComposerCapability>

  private var selectedModel: ComposerModelOption? {
    if let selectedModelID, let match = models.first(where: { $0.id == selectedModelID }) {
      return match
    }
    return models.first
  }

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        if !models.isEmpty {
          Menu {
            ForEach(models) { model in
              Button {
                selectedModelID = model.id
              } label: {
                HStack {
                  if let icon = model.icon, !icon.isEmpty {
                    Image(systemName: icon)
                  }
                  Text(model.name)
                  if let subtitle = model.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                  }
                  if selectedModel?.id == model.id {
                    Image(systemName: "checkmark")
                  }
                }
              }
              .accessibilityIdentifier("composer_model_option_\(model.id)")
            }
          } label: {
            HStack(spacing: 4) {
              if let icon = selectedModel?.icon, !icon.isEmpty {
                Image(systemName: icon)
                  .font(.caption.weight(.semibold))
              } else {
                Image(systemName: "cpu")
                  .font(.caption.weight(.semibold))
              }

              Text(selectedModel?.name ?? "Model")
                .font(.caption.weight(.semibold))
                .lineLimit(1)

              Image(systemName: "chevron.up.chevron.down")
                .font(.caption2)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.platformTertiaryBackground)
            .clipShape(Capsule())
          }
          .menuStyle(.borderlessButton)
          .accessibilityIdentifier("composer_model_picker")
        }

        ForEach(capabilities) { capability in
          let isSelected = activeCapabilities.contains(capability)
          Button {
            if isSelected {
              activeCapabilities.remove(capability)
            } else {
              activeCapabilities.insert(capability)
            }
          } label: {
            HStack(spacing: 4) {
              Image(systemName: capability.icon)
                .font(.caption.weight(.semibold))

              Text(capability.title)
                .font(.caption.weight(isSelected ? .semibold : .medium))
                .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.platformTertiaryBackground)
            .clipShape(Capsule())
            .overlay(
              Capsule()
                .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 0.75)
            )
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("composer_capability_\(capability.id)")
          .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
      }
      .padding(.horizontal, 12)
      .padding(.bottom, 8)
    }
  }
}
