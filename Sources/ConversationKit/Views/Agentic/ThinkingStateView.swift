//
//  ThinkingStateView.swift
//  ConversationKit
//
//  Collapsed-by-default chain-of-thought reasoning view with phase-locked status icon,
//  leaf-scoped 10Hz tabular elapsed timer, and ThinkingStateStyle delegation (AC-10, AC-11, AC-16).
//

import Foundation
import SwiftUI

// MARK: - Accessibility Identifier Extensions

extension ConversationAccessibilityID {
  /// Accessibility identifier for the interactive header label of `ThinkingStateView`.
  public static let thinkingHeader = "thinking.header"

  /// Accessibility identifier for the expandable reasoning transcript of `ThinkingStateView`.
  public static let thinkingTranscript = "thinking.transcript"
}

// MARK: - ThinkingStateView

/// Displays an AI assistant's chain-of-thought reasoning trace (`F-7`, `AC-10`, `AC-11`, `AC-16`).
///
/// `ThinkingStateView` strictly defaults to collapsed (`ThinkingTrace.defaultExpanded == false`) so
/// multi-paragraph reasoning traces never push the response content off screen unless the user explicitly
/// taps the header to inspect the transcript.
///
/// To guarantee 120Hz ProMotion scrolling performance, the periodic `0.1s` timer used while
/// `trace.status` is `.thinking(startedAt:)` is isolated inside `ThinkingElapsedLabelView`—a leaf
/// `View`—so `TimelineView` ticks never re-evaluate the reasoning transcript or parent timeline row.
@MainActor
public struct ThinkingStateView: View {
  /// The reasoning trace model to render.
  public let trace: ThinkingTrace

  /// Optional external binding overriding internal expansion state.
  private var externalIsExpanded: Binding<Bool>?

  /// Internal expansion state, initialized strictly to `ThinkingTrace.defaultExpanded` (`false`).
  @State private var internalIsExpanded: Bool = ThinkingTrace.defaultExpanded

  /// Tracks whether the user has manually toggled the header during this view's lifetime.
  @State private var hasUserManuallyToggled: Bool = false

  @Environment(\.thinkingStateStyle) private var thinkingStateStyle
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// Creates a `ThinkingStateView` for the given `ThinkingTrace`.
  ///
  /// - Parameters:
  ///   - trace: The `ThinkingTrace` value model.
  ///   - isExpanded: Optional external binding for controlling expansion state. When `nil`,
  ///     `ThinkingStateView` manages its own `@State` initialized to `ThinkingTrace.defaultExpanded` (`false`).
  public init(
    trace: ThinkingTrace,
    isExpanded: Binding<Bool>? = nil
  ) {
    self.trace = trace
    self.externalIsExpanded = isExpanded
  }

  /// Effective expansion state (collapsed by default).
  private var isExpanded: Bool {
    externalIsExpanded?.wrappedValue ?? internalIsExpanded
  }

  public var body: some View {
    let configuration = ThinkingStateStyleConfiguration(
      status: trace.status,
      summary: trace.summary,
      transcript: trace.transcript,
      formattedElapsed: Self.staticFormattedElapsed(for: trace.status),
      isExpanded: isExpanded,
      toggleExpanded: toggleExpansion,
      headerLabel: AnyView(
        ThinkingHeaderLabelView(
          status: trace.status,
          summary: trace.summary
        )
        .accessibilityIdentifier(ConversationAccessibilityID.thinkingHeader)
      ),
      transcriptContent: AnyView(
        ThinkingTranscriptContentView(
          summary: trace.summary,
          transcript: trace.transcript
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(ConversationAccessibilityID.thinkingTranscript)
      ),
      headerIcon: AnyView(
        ThinkingStatusIconView(status: trace.status)
      )
    )

    thinkingStateStyle
      .makeBody(configuration: configuration)
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier(ConversationAccessibilityID.thinkingState(trace.id))
  }

  // MARK: Actions

  @MainActor
  private func toggleExpansion() {
    hasUserManuallyToggled = true
    PlatformHapticEvent.triggerHaptic(.selection)

    let animation: Animation = reduceMotion
      ? .easeOut(duration: 0.15)
      : .snappy(duration: 0.24)

    withAnimation(animation) {
      if let externalIsExpanded {
        externalIsExpanded.wrappedValue.toggle()
      } else {
        internalIsExpanded.toggle()
      }
    }
  }

  // MARK: Formatting Helpers

  /// Formats the static elapsed duration for `.completed` and `.cancelled` states.
  internal static func staticFormattedElapsed(for status: ThinkingTrace.Status) -> String {
    switch status {
    case .thinking:
      return ""
    case .completed(let duration):
      return "\(Int(max(0, duration).rounded()))s"
    case .cancelled(let duration):
      return "\(max(0, duration).formatted(.number.precision(.fractionLength(1))))s"
    }
  }

  /// Formats the complete status headline string for a given `ThinkingTrace.Status` and reference `Date`.
  public nonisolated static func formattedHeadline(
    for status: ThinkingTrace.Status,
    now: Date = .now
  ) -> String {
    switch status {
    case .thinking(let startedAt):
      let elapsed = max(0, now.timeIntervalSince(startedAt))
      let formatted = elapsed.formatted(.number.precision(.fractionLength(1)))
      return "Thinking · \(formatted)s"
    case .completed(let duration):
      let roundedSeconds = Int(max(0, duration).rounded())
      return "Thought for \(roundedSeconds)s"
    case .cancelled(let duration):
      let formatted = max(0, duration).formatted(.number.precision(.fractionLength(1)))
      return "Thinking stopped · \(formatted)s"
    }
  }
}

// MARK: - ThinkingHeaderLabelView

/// Combines the phase-locked status icon and the leaf-scoped elapsed label.
private struct ThinkingHeaderLabelView: View {
  let status: ThinkingTrace.Status
  let summary: String?

  var body: some View {
    HStack(alignment: .center, spacing: 6) {
      ThinkingStatusIconView(status: status)
      ThinkingElapsedLabelView(status: status, summary: summary)
    }
  }
}

// MARK: - ThinkingStatusIconView

/// Renders the phase-locked icon for `ThinkingStateView`:
/// - `.thinking`: breathing/pulsing `sparkles` mark
/// - `.completed`: `checkmark.circle.fill`
/// - `.cancelled`: `stop.circle`
private struct ThinkingStatusIconView: View {
  let status: ThinkingTrace.Status

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var symbolName: String {
    switch status {
    case .thinking:
      return "sparkles"
    case .completed:
      return "checkmark.circle.fill"
    case .cancelled:
      return "stop.circle"
    }
  }

  private var isThinking: Bool {
    if case .thinking = status {
      return true
    }
    return false
  }

  var body: some View {
    Image(systemName: symbolName)
      .font(.caption.weight(.semibold))
      .foregroundStyle(iconForegroundStyle)
      .contentTransition(.symbolEffect(.replace))
      .symbolEffect(
        .pulse.byLayer,
        options: .repeating,
        isActive: isThinking && !reduceMotion
      )
      .accessibilityHidden(true)
  }

  private var iconForegroundStyle: AnyShapeStyle {
    switch status {
    case .thinking:
      return AnyShapeStyle(.tint)
    case .completed:
      return AnyShapeStyle(.secondary)
    case .cancelled:
      return AnyShapeStyle(.secondary)
    }
  }
}

// MARK: - ThinkingElapsedLabelView (Leaf TimelineView Isolation)

/// Leaf-scoped view that isolates the `0.1s` `TimelineView` strictly to the monospaced timer text
/// while `status` is `.thinking(startedAt:)`, ensuring 120Hz ProMotion scrolling never re-evaluates
/// the transcript or parent hierarchy on timer ticks.
private struct ThinkingElapsedLabelView: View {
  let status: ThinkingTrace.Status
  let summary: String?

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    switch status {
    case .thinking(let startedAt):
      TimelineView(.periodic(from: startedAt, by: 0.1)) { context in
        let elapsed = max(0, context.date.timeIntervalSince(startedAt))
        let elapsedText = elapsed.formatted(.number.precision(.fractionLength(1)))
        let phase = sheenPhase(elapsed: elapsed)

        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text("Thinking")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(
              reduceMotion
                ? AnyShapeStyle(.primary)
                : AnyShapeStyle(sheenGradient(phase: phase))
            )

          Text("·")
            .font(.subheadline)
            .foregroundStyle(.tertiary)

          Text("\(elapsedText)s")
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)
            .contentTransition(.numericText(countsDown: false))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Thinking, \(elapsedText) seconds elapsed")
      }

    case .completed(let duration):
      let seconds = Int(max(0, duration).rounded())
      Text("Thought for \(seconds)s")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
        .monospacedDigit()
        .contentTransition(.numericText())
        .accessibilityLabel("Thought for \(seconds) seconds")

    case .cancelled(let duration):
      let formatted = max(0, duration).formatted(.number.precision(.fractionLength(1)))
      Text("Thinking stopped · \(formatted)s")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
        .monospacedDigit()
        .contentTransition(.numericText())
        .accessibilityLabel("Thinking stopped after \(formatted) seconds")
    }
  }

  /// Computes a normalized `0.0...1.0` sweep phase every `1.8s` for the active alpha sheen.
  private func sheenPhase(elapsed: TimeInterval) -> Double {
    let cycleDuration: TimeInterval = 1.8
    let remainder = elapsed.truncatingRemainder(dividingBy: cycleDuration)
    return remainder / cycleDuration
  }

  /// Subtle alpha sheen gradient sweeping across `"Thinking"` while streaming (`!reduceMotion`).
  private func sheenGradient(phase: Double) -> LinearGradient {
    let center = phase
    let leading = max(0.0, center - 0.25)
    let trailing = min(1.0, center + 0.25)

    return LinearGradient(
      stops: [
        .init(color: Color.primary.opacity(0.62), location: 0.0),
        .init(color: Color.primary.opacity(0.62), location: leading),
        .init(color: Color.primary, location: center),
        .init(color: Color.primary.opacity(0.62), location: trailing),
        .init(color: Color.primary.opacity(0.62), location: 1.0),
      ],
      startPoint: .leading,
      endPoint: .trailing
    )
  }
}

// MARK: - ThinkingTranscriptContentView

/// Renders the expanded reasoning summary and full transcript text.
private struct ThinkingTranscriptContentView: View {
  let summary: String?
  let transcript: String

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      if let summary, !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        Text(summary)
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.primary.opacity(0.85))
      }

      if !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        Text(transcript)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .textSelection(.enabled)
          .fixedSize(horizontal: false, vertical: true)
      } else if summary == nil || summary?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
        Text("Reasoning in progress…")
          .font(.subheadline)
          .foregroundStyle(.tertiary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
