//
//  SuggestionChipsBar.swift
//  ConversationKit
//
//  First-turn horizontally snapping Liquid Glass suggestion chips bar (F-8, AC-12).
//

import SwiftUI

/// Renders a horizontal view-aligned snapping bar of `PromptSuggestion` pills in Liquid Glass
/// directly above the message composer before the first user message is sent (`F-8`, `AC-12`).
///
/// Each suggestion pill is wrapped inside a shared `GlassEffectContainer(spacing: 12)` and styled
/// with `.glassEffect(.regular.interactive(), in: .capsule)` (automatically falling back to an
/// opaque `Color.platformSecondaryBackground` capsule when `accessibilityReduceTransparency` is enabled).
///
/// ### Usage
/// ```swift
/// SuggestionChipsBar(suggestions: suggestions) { suggestion in
///   handleSuggestion(suggestion)
/// }
/// ```
@MainActor
public struct SuggestionChipsBar: View {
  /// The ordered prompt suggestions displayed in the horizontal snapping bar.
  public let suggestions: [PromptSuggestion]

  /// Callback invoked on `@MainActor` when the user taps a suggestion chip.
  public let onSelect: @MainActor (PromptSuggestion) -> Void

  @Namespace private var glassNamespace
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  /// Alias for `suggestions` preserving terminology parity with `chips`.
  public var chips: [PromptSuggestion] {
    suggestions
  }

  /// Creates a `SuggestionChipsBar` from an array of `PromptSuggestion` items.
  ///
  /// - Parameters:
  ///   - suggestions: The ordered array of `PromptSuggestion` chips to display.
  ///   - onSelect: Closure invoked when a chip is tapped.
  public init(
    suggestions: [PromptSuggestion],
    onSelect: @escaping @MainActor (PromptSuggestion) -> Void
  ) {
    self.suggestions = suggestions
    self.onSelect = onSelect
  }

  /// Convenience initializer accepting an unlabeled array of `PromptSuggestion` items.
  public init(
    _ suggestions: [PromptSuggestion],
    onSelect: @escaping @MainActor (PromptSuggestion) -> Void
  ) {
    self.suggestions = suggestions
    self.onSelect = onSelect
  }

  /// Convenience initializer accepting `chips:` parameter label.
  public init(
    chips: [PromptSuggestion],
    onSelect: @escaping @MainActor (PromptSuggestion) -> Void
  ) {
    self.suggestions = chips
    self.onSelect = onSelect
  }

  public var body: some View {
    if !suggestions.isEmpty {
      ScrollView(.horizontal, showsIndicators: false) {
        GlassEffectContainer(spacing: 12) {
          HStack(spacing: 10) {
            ForEach(suggestions) { suggestion in
              chipButton(for: suggestion)
            }
          }
          .scrollTargetLayout()
        }
      }
      .scrollTargetBehavior(.viewAligned)
      .contentMargins(.horizontal, 12, for: .scrollContent)
      .padding(.vertical, 4)
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier(ConversationAccessibilityID.composerSuggestionChipsBar)
    }
  }

  @ViewBuilder
  private func chipButton(for suggestion: PromptSuggestion) -> some View {
    Button {
      PlatformHapticEvent.triggerHaptic(.selection)
      onSelect(suggestion)
    } label: {
      chipLabel(for: suggestion)
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(ConversationAccessibilityID.suggestionChip(suggestion.id))
    .accessibilityLabel(accessibilityLabel(for: suggestion))
    .accessibilityHint(
      suggestion.behavior == .immediateSend
        ? "Double-tap to send this prompt immediately"
        : "Double-tap to insert this prompt into the message composer"
    )
  }

  @ViewBuilder
  private func chipLabel(for suggestion: PromptSuggestion) -> some View {
    let content = HStack(spacing: 8) {
      if let symbolName = suggestion.symbolName, !symbolName.isEmpty {
        Image(systemName: symbolName)
          .font(.caption.weight(.semibold))
          .foregroundStyle(Color.accentColor)
          .frame(width: 22, height: 22)
          .background(Color.accentColor.opacity(0.15), in: Circle())
      }

      Text(suggestion.title)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.primary)
        .lineLimit(1)
    }
    .padding(.leading, 8)
    .padding(.trailing, 14)
    .padding(.vertical, 8)
    .contentShape(Capsule())

    if reduceTransparency {
      content
        .background(Color.platformSecondaryBackground, in: Capsule())
        .overlay {
          Capsule()
            .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
        }
    } else {
      content
        .glassEffect(.regular.interactive(), in: .capsule)
        .glassEffectID("suggestion.\(suggestion.id)", in: glassNamespace)
    }
  }

  private func accessibilityLabel(for suggestion: PromptSuggestion) -> String {
    if let category = suggestion.category, !category.isEmpty {
      return "\(suggestion.title), \(category)"
    }
    return suggestion.title
  }
}

#Preview("SuggestionChipsBar") {
  VStack {
    Spacer()
    SuggestionChipsBar(
      suggestions: [
        PromptSuggestion(
          id: "arch",
          title: "Review architecture",
          prompt: "Review the v2 Liquid Glass architecture",
          symbolName: "building.columns",
          category: "Architecture"
        ),
        PromptSuggestion(
          id: "perf",
          title: "Audit scroll physics",
          prompt: "Verify zero-jitter top-floating turn runway",
          symbolName: "gauge.with.dots.needle.67percent",
          category: "Performance",
          behavior: .populateComposer
        ),
        PromptSuggestion(
          id: "tests",
          title: "Generate unit tests",
          prompt: "Write Swift Testing suites for ComposerTextBuffer",
          symbolName: "checkmark.shield"
        )
      ]
    ) { _ in }
  }
  .padding(.vertical)
}
