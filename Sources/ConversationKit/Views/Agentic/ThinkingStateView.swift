//
// ThinkingStateView.swift
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
import MarkdownUI

/// Renders an expandable chain-of-thought reasoning trace with a leaf-scoped 0.1s elapsed timer (`FR-2.1`, `FR-2.2`, `AC-5`, `AC-6`).
public struct ThinkingStateView: View {
  public let thinking: ThinkingTrace

  @State private var isExpanded: Bool
  @State private var hasUserToggled: Bool = false

  public init(thinking: ThinkingTrace) {
    self.thinking = thinking
    switch thinking.status {
    case .thinking:
      self._isExpanded = State(initialValue: true)
    case .completed, .cancelled:
      self._isExpanded = State(initialValue: false)
    }
  }

  /// Deterministically formats the thinking header title for a given status (`AC-5`).
  public static func headerTitle(
    for status: ThinkingTrace.Status,
    now: Date = Date(),
    includeCancelledDuration: Bool = false
  ) -> String {
    switch status {
    case .thinking(let startedAt):
      let elapsed = max(0, now.timeIntervalSince(startedAt))
      return "Thinking · \(elapsed.formatted(.number.precision(.fractionLength(1))))s"
    case .completed(let duration):
      return "Thought for \(Int(duration.rounded()))s"
    case .cancelled(let duration):
      if includeCancelledDuration, let duration {
        return "Thinking stopped · \(duration.formatted(.number.precision(.fractionLength(1))))s"
      }
      return "Thinking stopped"
    }
  }

  private var hasTranscriptContent: Bool {
    let hasSummary = thinking.summary?.contains(where: { !$0.isWhitespace && !$0.isNewline }) ?? false
    let hasTranscript = thinking.transcript.contains(where: { !$0.isWhitespace && !$0.isNewline })
    return hasSummary || hasTranscript
  }

  public var body: some View {
    let hasContent = hasTranscriptContent

    VStack(alignment: .leading, spacing: 8) {
      Button {
        guard hasContent else { return }
        hasUserToggled = true
        withAnimation(.snappy(duration: 0.25)) {
          isExpanded.toggle()
        }
      } label: {
        HStack(spacing: 6) {
          Image(systemName: statusIconName)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(statusIconColor)

          switch thinking.status {
          case .thinking(let startedAt):
            ElapsedTimerText(startedAt: startedAt)
          case .completed(let duration):
            Text("Thought for \(Int(duration.rounded()))s")
              .font(.subheadline.weight(.medium))
              .monospacedDigit()
              .foregroundStyle(.secondary)
          case .cancelled:
            Text(Self.headerTitle(for: thinking.status, includeCancelledDuration: true))
              .font(.subheadline.weight(.medium))
              .monospacedDigit()
              .foregroundStyle(.secondary)
          }

          if hasContent {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
              .font(.caption2.weight(.semibold))
              .foregroundStyle(.secondary)
          }
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("thinking_header_button")

      if isExpanded && hasContent {
        HStack(alignment: .top, spacing: 10) {
          RoundedRectangle(cornerRadius: 1.5)
            .fill(Color.accentColor.opacity(0.4))
            .frame(width: 3)

          VStack(alignment: .leading, spacing: 6) {
            if let summary = thinking.summary, !summary.isEmpty {
              Text(summary)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }

            if !thinking.transcript.isEmpty {
              EquatableThinkingMarkdown(text: thinking.transcript)
                .equatable()
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }
        .padding(.leading, 4)
        .padding(.vertical, 2)
        .transition(.opacity.combined(with: .move(edge: .top)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("thinking_trace_content")
      }
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("thinking_state_view")
    .onChange(of: thinking.status) { _, newStatus in
      guard !hasUserToggled else { return }
      switch newStatus {
      case .thinking:
        withAnimation(.snappy(duration: 0.25)) {
          isExpanded = true
        }
      case .completed, .cancelled:
        withAnimation(.snappy(duration: 0.25)) {
          isExpanded = false
        }
      }
    }
  }

  private var statusIconName: String {
    switch thinking.status {
    case .thinking:
      return "brain"
    case .completed:
      return "sparkles"
    case .cancelled:
      return "stop.circle"
    }
  }

  private var statusIconColor: Color {
    switch thinking.status {
    case .thinking:
      return Color.accentColor
    case .completed, .cancelled:
      return Color.secondary
    }
  }
}

/// Private leaf view isolating the 10Hz `TimelineView` so timer ticks never re-evaluate
/// the parent `ThinkingStateView` or `Markdown` transcript (`[SF-1]`, `AC-5`).
private struct ElapsedTimerText: View {
  let startedAt: Date

  var body: some View {
    TimelineView(.periodic(from: startedAt, by: 0.1)) { context in
      let elapsed = max(0, context.date.timeIntervalSince(startedAt))
      Text("Thinking · \(elapsed, format: .number.precision(.fractionLength(1)))s")
        .font(.subheadline.weight(.medium))
        .monospacedDigit()
        .foregroundStyle(.secondary)
    }
  }
}

private struct EquatableThinkingMarkdown: View, Equatable {
  let text: String

  static func == (lhs: EquatableThinkingMarkdown, rhs: EquatableThinkingMarkdown) -> Bool {
    lhs.text == rhs.text
  }

  var body: some View {
    Markdown(text)
  }
}

#Preview("Active Thinking") {
  ThinkingStateView(
    thinking: ThinkingTrace(
      summary: "Analyzing scroll anchor invariants",
      transcript: "Checking `ConversationScrollID` stability and `.safeAreaInset` margins...",
      status: .thinking(startedAt: Date().addingTimeInterval(-3.2))
    )
  )
  .padding()
}

#Preview("Completed Thinking") {
  ThinkingStateView(
    thinking: ThinkingTrace(
      summary: "Analyzed scroll anchor invariants",
      transcript: "Verified that a single outer scroll ID preserves Push-and-Pin clamping.",
      status: .completed(duration: 4.2)
    )
  )
  .padding()
}
