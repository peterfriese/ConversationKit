//
//  ThinkingStateStyle.swift
//  ConversationKit
//
//  SwiftUI Style protocol and built-in non-glass styles for ThinkingStateView (AC-10, AC-11, AC-16).
//

import SwiftUI

// MARK: - ThinkingStateStyle Protocol

/// Customizes the visual appearance of `ThinkingStateView` (`F-7`, `AC-11`, `AC-16`, `[MF-1]`).
///
/// Because `ThinkingStateView` renders inside scrolling timeline cells, all `ThinkingStateStyle`
/// presets use semantic fills, borders, and typography—never Liquid Glass (`AC-10`).
///
/// ### Usage
/// ```swift
/// // Layer 1 (Troposphere): Default .collapsibleHeader style (collapsed by default)
/// ConversationView(messages: $messages)
///
/// // Layer 2 (Stratosphere): Switch to .pill or .minimal thinking style
/// ConversationView(messages: $messages)
///   .thinkingStateStyle(.pill)
/// ```
@MainActor
public protocol ThinkingStateStyle: DynamicProperty, Sendable {
  /// The view type representing the body of this thinking state style.
  associatedtype Body: View

  /// Convenience alias for `ThinkingStateStyleConfiguration`.
  typealias Configuration = ThinkingStateStyleConfiguration

  /// Creates the view representing the body of `ThinkingStateView`.
  @ViewBuilder
  @MainActor
  func makeBody(configuration: Configuration) -> Body
}

// MARK: - ThinkingStateStyleConfiguration

/// The state properties, toggle callback, and pre-built subviews passed to `ThinkingStateStyle` (`§3.3.2`).
@MainActor
public struct ThinkingStateStyleConfiguration {
  /// Current lifecycle status of the reasoning trace (`.thinking`, `.completed`, or `.cancelled`).
  public let status: ThinkingTrace.Status

  /// Optional concise headline summary for the reasoning block.
  public let summary: String?

  /// Full reasoning transcript text.
  public let transcript: String

  /// Formatted elapsed time label (e.g., `"3.2s"` or `"4s"`).
  public let formattedElapsed: String

  /// Indicates whether the reasoning transcript container is currently expanded (`false` by default, `AC-11`).
  public let isExpanded: Bool

  /// Action closure invoked on `@MainActor` to toggle the expanded/collapsed state.
  public let toggleExpanded: @MainActor () -> Void

  /// Pre-configured header label view combining the phase-locked breathing mark, status title, and tabular timer.
  public let headerLabel: AnyView

  /// Pre-configured expandable transcript content view.
  public let transcriptContent: AnyView

  /// Pre-configured leading status icon view.
  public let headerIcon: AnyView

  /// Non-optional display title derived from `summary` or `status` (preserving ADR §3.3.2 parity).
  public var title: String {
    if let summary, !summary.isEmpty {
      return summary
    }
    switch status {
    case .thinking:
      return "Thinking"
    case .completed(let duration):
      return "Thought for \(Self.formatDuration(duration))"
    case .cancelled(let duration):
      return "Thinking stopped · \(Self.formatDuration(duration))"
    }
  }

  /// Alias for `transcriptContent` preserving terminology parity with `traceContent` (`§3.3.2`).
  public var traceContent: AnyView {
    transcriptContent
  }

  /// Creates a `ThinkingStateStyleConfiguration` with `summary`, `transcript`, `headerLabel`, and `transcriptContent`.
  public init(
    status: ThinkingTrace.Status,
    summary: String? = nil,
    transcript: String = "",
    formattedElapsed: String? = nil,
    isExpanded: Bool = ThinkingTrace.defaultExpanded,
    toggleExpanded: @escaping @MainActor () -> Void,
    headerLabel: AnyView,
    transcriptContent: AnyView,
    headerIcon: AnyView? = nil
  ) {
    self.status = status
    self.summary = summary
    self.transcript = transcript
    self.formattedElapsed = formattedElapsed ?? Self.defaultFormattedElapsed(for: status)
    self.isExpanded = isExpanded
    self.toggleExpanded = toggleExpanded
    self.headerLabel = headerLabel
    self.transcriptContent = transcriptContent
    self.headerIcon = headerIcon ?? AnyView(
      Image(systemName: "brain")
        .imageScale(.small)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)
    )
  }

  /// Convenience initializer matching `title`, `formattedElapsed`, `headerIcon`, and `traceContent` (`§3.3.2`).
  public init(
    status: ThinkingTrace.Status,
    title: String,
    formattedElapsed: String,
    isExpanded: Bool = ThinkingTrace.defaultExpanded,
    toggleExpanded: @escaping @MainActor () -> Void,
    headerIcon: AnyView,
    traceContent: AnyView,
    transcript: String = ""
  ) {
    self.status = status
    self.summary = title
    self.transcript = transcript
    self.formattedElapsed = formattedElapsed
    self.isExpanded = isExpanded
    self.toggleExpanded = toggleExpanded
    self.headerIcon = headerIcon
    self.transcriptContent = traceContent
    self.headerLabel = AnyView(
      ThinkingCustomHeaderLabelView(
        headerIcon: headerIcon,
        title: title,
        formattedElapsed: formattedElapsed
      )
    )
  }

  private static func defaultFormattedElapsed(for status: ThinkingTrace.Status) -> String {
    switch status {
    case .thinking:
      return ""
    case .completed(let duration), .cancelled(let duration):
      return formatDuration(duration)
    }
  }

  private static func formatDuration(_ duration: TimeInterval) -> String {
    let clamped = max(0, duration)
    if clamped < 10 {
      return String(format: "%.1fs", clamped)
    }
    return "\(Int(clamped.rounded()))s"
  }
}

private struct ThinkingCustomHeaderLabelView: View {
  let headerIcon: AnyView
  let title: String
  let formattedElapsed: String

  @Environment(\.thinkingHeaderShowsInlineIcon) private var showsInlineIcon

  var body: some View {
    HStack(spacing: 6) {
      if showsInlineIcon {
        headerIcon
      }
      Text(title)
        .fontWeight(.medium)
      if !formattedElapsed.isEmpty {
        Text("·")
          .foregroundStyle(.tertiary)
        Text(formattedElapsed)
          .monospacedDigit()
          .foregroundStyle(.secondary)
      }
    }
  }
}

// MARK: - CollapsibleHeaderThinkingStateStyle (.collapsibleHeader / .default / .automatic)

/// Default thinking state style featuring a structured rounded card container, a leading badged status icon,
/// an inline collapsed summary preview, a rotating trailing chevron, and a hairline-separated expandable
/// reasoning trace container (`F-7`, `AC-10`, `AC-11`, `AC-16`).
public struct CollapsibleHeaderThinkingStateStyle: ThinkingStateStyle, Sendable {
  /// Creates the default collapsible header thinking state style.
  public nonisolated init() {}

  @MainActor
  public func makeBody(configuration: Configuration) -> some View {
    CollapsibleHeaderThinkingBody(configuration: configuration)
  }
}

private struct CollapsibleHeaderThinkingBody: View {
  let configuration: ThinkingStateStyleConfiguration

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var isThinking: Bool {
    if case .thinking = configuration.status {
      return true
    }
    return false
  }

  private var trimmedSummary: String? {
    guard let raw = configuration.summary?.trimmingCharacters(in: .whitespacesAndNewlines),
      !raw.isEmpty
    else {
      return nil
    }
    return raw
  }

  var body: some View {
    let cardShape = RoundedRectangle(cornerRadius: 12, style: .continuous)

    VStack(alignment: .leading, spacing: 0) {
      Button(action: configuration.toggleExpanded) {
        HStack(alignment: .center, spacing: 8) {
          ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
              .fill(
                isThinking
                  ? Color.accentColor.opacity(0.12)
                  : Color.platformSeparator.opacity(0.25)
              )
              .frame(width: 22, height: 22)

            configuration.headerIcon
              .font(.subheadline)
          }

          configuration.headerLabel
            .environment(\.thinkingHeaderShowsInlineIcon, false)
            .font(.subheadline)
            .layoutPriority(1)

          if !configuration.isExpanded, let summary = trimmedSummary {
            Text("· \(summary)")
              .font(.footnote)
              .foregroundStyle(.tertiary)
              .lineLimit(1)
              .truncationMode(.tail)
          }

          Spacer(minLength: 8)

          Image(systemName: "chevron.right")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
            .animation(
              reduceMotion ? nil : .snappy(duration: 0.22),
              value: configuration.isExpanded
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier(ConversationAccessibilityID.thinkingHeader)
      .accessibilityAddTraits(.isButton)
      .accessibilityHint(
        configuration.isExpanded
          ? Text("Double-tap to collapse reasoning trace")
          : Text("Double-tap to expand reasoning trace")
      )

      if configuration.isExpanded {
        VStack(alignment: .leading, spacing: 0) {
          Divider()
            .opacity(0.5)

          HStack(alignment: .top, spacing: 10) {
            Capsule()
              .fill(Color.accentColor.opacity(0.45))
              .frame(width: 2)

            configuration.transcriptContent
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 10)
        }
        .transition(
          reduceMotion
            ? .opacity
            : .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
        )
      }
    }
    .background(Color.platformSecondaryBackground.opacity(0.65), in: cardShape)
    .clipShape(cardShape)
    .overlay {
      cardShape
        .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
    }
  }
}

// MARK: - PillThinkingStateStyle (.pill)

/// Compact tinted pill header style for `ThinkingStateView` that expands the reasoning trace beneath it on tap (`AC-16`).
///
/// Uses a semantic accent-tinted capsule fill over `Color.platformSecondaryBackground`
/// (never Liquid Glass in scrolling cells, `AC-10`).
public struct PillThinkingStateStyle: ThinkingStateStyle, Sendable {
  /// Creates a pill thinking state style.
  public nonisolated init() {}

  @MainActor
  public func makeBody(configuration: Configuration) -> some View {
    PillThinkingBody(configuration: configuration)
  }
}

private struct PillThinkingBody: View {
  let configuration: ThinkingStateStyleConfiguration

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    let calloutShape = RoundedRectangle(cornerRadius: 14, style: .continuous)

    VStack(alignment: .leading, spacing: 8) {
      Button(action: configuration.toggleExpanded) {
        HStack(alignment: .center, spacing: 6) {
          configuration.headerLabel
            .font(.footnote.weight(.medium))

          Image(systemName: "chevron.right")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
            .animation(
              reduceMotion ? nil : .snappy(duration: 0.22),
              value: configuration.isExpanded
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
          Capsule()
            .fill(Color.platformSecondaryBackground.opacity(0.85))
            .overlay {
              Capsule()
                .fill(Color.accentColor.opacity(0.10))
            }
        }
        .overlay {
          Capsule()
            .strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 0.75)
        }
        .contentShape(Capsule())
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier(ConversationAccessibilityID.thinkingHeader)
      .accessibilityAddTraits(.isButton)
      .accessibilityHint(
        configuration.isExpanded
          ? Text("Double-tap to collapse reasoning trace")
          : Text("Double-tap to expand reasoning trace")
      )

      if configuration.isExpanded {
        configuration.transcriptContent
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(
            Color.platformSecondaryBackground.opacity(0.65),
            in: calloutShape
          )
          .clipShape(calloutShape)
          .overlay {
            calloutShape
              .strokeBorder(Color.platformSeparator.opacity(0.35), lineWidth: 0.5)
          }
          .transition(
            reduceMotion
              ? .opacity
              : .opacity.combined(with: .scale(scale: 0.98, anchor: .topLeading))
          )
      }
    }
  }
}

// MARK: - MinimalThinkingStateStyle (.minimal)

/// Ultra-lightweight inline caption style for `ThinkingStateView` without background fill (`AC-16`).
public struct MinimalThinkingStateStyle: ThinkingStateStyle, Sendable {
  /// Creates a minimal inline thinking state style.
  public nonisolated init() {}

  @MainActor
  public func makeBody(configuration: Configuration) -> some View {
    MinimalThinkingBody(configuration: configuration)
  }
}

private struct MinimalThinkingBody: View {
  let configuration: ThinkingStateStyleConfiguration

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Button(action: configuration.toggleExpanded) {
        HStack(alignment: .center, spacing: 4) {
          configuration.headerLabel
            .font(.caption)
            .foregroundStyle(.secondary)

          Image(systemName: "chevron.right")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.tertiary)
            .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
            .animation(
              reduceMotion ? nil : .snappy(duration: 0.18),
              value: configuration.isExpanded
            )
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier(ConversationAccessibilityID.thinkingHeader)
      .accessibilityAddTraits(.isButton)
      .accessibilityHint(
        configuration.isExpanded
          ? Text("Double-tap to collapse reasoning trace")
          : Text("Double-tap to expand reasoning trace")
      )

      if configuration.isExpanded {
        HStack(alignment: .top, spacing: 8) {
          Capsule()
            .fill(Color.platformSeparator.opacity(0.5))
            .frame(width: 1.5)

          configuration.transcriptContent
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 4)
        .padding(.vertical, 2)
        .clipped()
        .transition(.opacity)
      }
    }
    .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: configuration.isExpanded)
  }
}

// MARK: - Static Style Presets

extension ThinkingStateStyle where Self == CollapsibleHeaderThinkingStateStyle {
  /// Default style: Phase-locked breathing mark, alpha sheen sweep while active, monospaced timer,
  /// and left-bordered expandable trace container.
  public nonisolated static var collapsibleHeader: CollapsibleHeaderThinkingStateStyle {
    CollapsibleHeaderThinkingStateStyle()
  }

  /// Alias for `.collapsibleHeader` preserving PRD parity (`[MF-1]`).
  public nonisolated static var `default`: CollapsibleHeaderThinkingStateStyle {
    CollapsibleHeaderThinkingStateStyle()
  }

  /// Idiomatic SwiftUI alias for `.collapsibleHeader` (`[MF-1]`).
  public nonisolated static var automatic: CollapsibleHeaderThinkingStateStyle {
    CollapsibleHeaderThinkingStateStyle()
  }
}

extension ThinkingStateStyle where Self == PillThinkingStateStyle {
  /// Compact tinted pill header that expands the reasoning trace beneath it on tap.
  public nonisolated static var pill: PillThinkingStateStyle {
    PillThinkingStateStyle()
  }
}

extension ThinkingStateStyle where Self == MinimalThinkingStateStyle {
  /// Ultra-lightweight inline caption header without background fill.
  public nonisolated static var minimal: MinimalThinkingStateStyle {
    MinimalThinkingStateStyle()
  }
}

// MARK: - Type-Erased AnyThinkingStateStyle & Environment

/// A type-erased `ThinkingStateStyle` wrapper stored in `EnvironmentValues`.
@MainActor
public struct AnyThinkingStateStyle: ThinkingStateStyle, Sendable {
  private let bodyBuilder: @MainActor @Sendable (ThinkingStateStyleConfiguration) -> AnyView

  /// Type-erases a concrete `ThinkingStateStyle`.
  public nonisolated init<S: ThinkingStateStyle & Sendable>(_ style: S) {
    self.bodyBuilder = { @MainActor configuration in
      AnyView(ThinkingStateStyleHost(style: style, configuration: configuration))
    }
  }

  @MainActor
  public func makeBody(configuration: Configuration) -> AnyView {
    bodyBuilder(configuration)
  }
}

private struct ThinkingStateStyleHost<S: ThinkingStateStyle>: View {
  let style: S
  let configuration: ThinkingStateStyleConfiguration

  var body: some View {
    style.makeBody(configuration: configuration)
  }
}

extension EnvironmentValues {
  /// The active `ThinkingStateStyle` in the environment (defaults to `.collapsibleHeader`).
  @Entry public var thinkingStateStyle: AnyThinkingStateStyle = AnyThinkingStateStyle(.collapsibleHeader)
}

extension View {
  /// Sets the style for `ThinkingStateView` within this view hierarchy (`AC-16`).
  public func thinkingStateStyle<S: ThinkingStateStyle & Sendable>(_ style: S) -> some View {
    environment(\.thinkingStateStyle, AnyThinkingStateStyle(style))
  }
}
