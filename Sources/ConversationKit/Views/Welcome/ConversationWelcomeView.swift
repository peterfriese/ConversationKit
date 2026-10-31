//
// ConversationWelcomeView.swift
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

public typealias WelcomeView = ConversationWelcomeView

/// Empty-state welcome surface displaying a time-of-day greeting, horizontal snapping
/// `PromptSuggestionChip` rail, categorized `StarterPromptCard` grid, and shuffle control (`FR-1.1` – `FR-1.4`).
public struct ConversationWelcomeView: View {
  public let configuration: WelcomeConfiguration
  public let onSelectSuggestion: (PromptSuggestion) -> Void

  @State private var displayedSlice: [PromptSuggestion]
  @State private var shuffleCount: Int = 0

  public init(
    configuration: WelcomeConfiguration,
    onSelectSuggestion: @escaping (PromptSuggestion) -> Void
  ) {
    self.configuration = configuration
    self.onSelectSuggestion = onSelectSuggestion
    let initialCount = max(0, min(configuration.visibleCount, configuration.suggestions.count))
    self._displayedSlice = State(initialValue: Array(configuration.suggestions.prefix(initialCount)))
  }

  /// Deterministically computes a new shuffled slice of `PromptSuggestion` items from `pool` (`AC-3`).
  ///
  /// When `pool.count > count`, prefers items whose IDs are not currently in `currentIDs` so the
  /// visible slice always changes on shuffle without mutating the source `pool`.
  public static func shuffledSlice(
    from pool: [PromptSuggestion],
    count: Int,
    currentIDs: Set<String>
  ) -> [PromptSuggestion] {
    let targetCount = max(0, min(count, pool.count))
    guard targetCount > 0 else { return [] }
    guard pool.count > targetCount else {
      return pool.shuffled()
    }

    let unseen = pool.filter { !currentIDs.contains($0.id) }.shuffled()
    let seen = pool.filter { currentIDs.contains($0.id) }.shuffled()
    let combined = unseen + seen
    return Array(combined.prefix(targetCount))
  }

  private var canShuffle: Bool {
    configuration.allowsShuffle && configuration.suggestions.count > configuration.visibleCount
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(alignment: .leading, spacing: 6) {
        Text(configuration.resolvedGreeting())
          .font(.title.weight(.bold))
          .foregroundStyle(.primary)
          .accessibilityIdentifier("welcome_greeting")

        if let subtitle = configuration.subtitle, !subtitle.isEmpty {
          Text(subtitle)
            .font(.body)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("welcome_subtitle")
        }
      }
      .padding(.horizontal)

      if !configuration.suggestions.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 10) {
            ForEach(configuration.suggestions) { suggestion in
              PromptSuggestionChip(suggestion: suggestion) {
                onSelectSuggestion(suggestion)
              }
            }
          }
          .padding(.horizontal)
          .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .accessibilityIdentifier("welcome_chip_rail")

        VStack(alignment: .leading, spacing: 12) {
          if canShuffle {
            HStack {
              Text("Suggested prompts")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

              Spacer()

              Button {
                let currentIDs = Set(displayedSlice.map(\.id))
                withAnimation(.snappy(duration: 0.25)) {
                  displayedSlice = Self.shuffledSlice(
                    from: configuration.suggestions,
                    count: configuration.visibleCount,
                    currentIDs: currentIDs
                  )
                  shuffleCount += 1
                }
              } label: {
                Label("Shuffle", systemImage: "arrow.triangle.2.circlepath")
                  .font(.caption.weight(.medium))
              }
              .buttonStyle(.borderless)
              .foregroundStyle(.secondary)
              .sensoryFeedback(.selection, trigger: shuffleCount)
              .accessibilityIdentifier("welcome_shuffle_button")
            }
          }

          LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 220), spacing: 12)],
            spacing: 12
          ) {
            ForEach(displayedSlice) { suggestion in
              StarterPromptCard(suggestion: suggestion) {
                onSelectSuggestion(suggestion)
              }
            }
          }
        }
        .padding(.horizontal)
      }
    }
    .padding(.vertical, 24)
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("welcome_view")
    .onChange(of: configuration.suggestions) { _, newSuggestions in
      let count = max(0, min(configuration.visibleCount, newSuggestions.count))
      displayedSlice = Array(newSuggestions.prefix(count))
    }
  }
}

#Preview {
  ConversationWelcomeView(
    configuration: WelcomeConfiguration(
      userName: "Peter",
      subtitle: "How can I help you build today?",
      suggestions: [
        PromptSuggestion(
          id: "1",
          title: "Explain Push & Pin Scroll Physics",
          subtitle: "How ConversationView anchors user messages to the top",
          icon: "arrow.up.and.down.text.horizontal",
          category: "Architecture"
        ),
        PromptSuggestion(
          id: "2",
          title: "Add a custom tool call",
          subtitle: "Model multi-step agentic tool execution",
          icon: "wrench.and.screwdriver",
          category: "Agentic"
        ),
        PromptSuggestion(
          id: "3",
          title: "Configure Liquid Glass",
          subtitle: "Progressive adoption on iOS 26 and macOS 26",
          icon: "sparkles",
          category: "Design"
        ),
        PromptSuggestion(
          id: "4",
          title: "Write Swift Testing suites",
          subtitle: "Verify state transitions with @Test and #expect",
          icon: "checkmark.seal",
          category: "Testing"
        ),
        PromptSuggestion(
          id: "5",
          title: "Audit strict concurrency",
          subtitle: "Ensure Sendable and @MainActor isolation",
          icon: "lock.shield",
          category: "Swift 6"
        )
      ],
      visibleCount: 4,
      allowsShuffle: true
    )
  ) { _ in }
}
