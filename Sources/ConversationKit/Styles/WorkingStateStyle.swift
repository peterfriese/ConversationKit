//
//  WorkingStateStyle.swift
//  ConversationKit
//
//  SwiftUI Style protocol and built-in non-glass styles for WorkingStateView (AC-10).
//

import SwiftUI

// MARK: - WorkingStateStyle Protocol

/// Customizes the visual appearance of `WorkingStateView` before the first reasoning trace,
/// tool call, or Markdown token arrives (`AC-10`).
///
/// Because `WorkingStateView` renders inside scrolling timeline cells, all `WorkingStateStyle`
/// presets use semantic fills, borders, and typography—never Liquid Glass (`AC-10`).
///
/// ### Usage
/// ```swift
/// // Layer 1 (Troposphere): Default .inline style
/// ConversationView(messages: $messages)
///
/// // Layer 2 (Stratosphere): Switch to .pill or .minimal working state style
/// ConversationView(messages: $messages)
///   .workingStateStyle(.pill)
/// ```
@MainActor
public protocol WorkingStateStyle: DynamicProperty, Sendable {
  /// The view type representing the body of this working state style.
  associatedtype Body: View

  /// Convenience alias for `WorkingStateStyleConfiguration`.
  typealias Configuration = WorkingStateStyleConfiguration

  /// Creates the view representing the body of `WorkingStateView`.
  @ViewBuilder
  @MainActor
  func makeBody(configuration: Configuration) -> Body
}

// MARK: - WorkingStateStyleConfiguration

/// The state properties and pre-built subviews passed to `WorkingStateStyle`.
@MainActor
public struct WorkingStateStyleConfiguration {
  /// Display title for the working state indicator (e.g., `"Working…"`).
  public let title: String

  /// Pre-configured pulsing `sparkles` icon view.
  public let icon: AnyView

  /// Pre-configured `Text(title)` label view.
  public let label: AnyView

  /// Creates a `WorkingStateStyleConfiguration` with a title, pre-configured icon, and label view.
  public init(
    title: String = "Working…",
    icon: AnyView,
    label: AnyView
  ) {
    self.title = title
    self.icon = icon
    self.label = label
  }
}

// MARK: - InlineWorkingStateStyle (.inline / .default / .automatic)

/// Default inline working state style displaying a pulsing `sparkles` mark and secondary subheadline label (`AC-10`).
public struct InlineWorkingStateStyle: WorkingStateStyle, Sendable {
  /// Optional custom title overriding `configuration.title`.
  public let customTitle: String?

  /// Creates an inline working state style with an optional custom title override.
  public nonisolated init(title: String? = nil) {
    self.customTitle = title
  }

  @MainActor
  public func makeBody(configuration: Configuration) -> some View {
    let displayTitle = customTitle ?? configuration.title
    HStack(alignment: .center, spacing: 6) {
      configuration.icon
        .font(.subheadline.weight(.semibold))

      Text(displayTitle)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .accessibilityLabel(displayTitle == "Working…" ? "Assistant is working" : displayTitle)
    }
    .padding(.vertical, 4)
  }
}

// MARK: - PillWorkingStateStyle (.pill)

/// Compact accent-tinted capsule style for `WorkingStateView` matching `PillThinkingStateStyle` (`AC-10`).
///
/// Uses a semantic accent-tinted capsule fill over `Color.platformSecondaryBackground`
/// (never Liquid Glass in scrolling cells, `AC-10`).
public struct PillWorkingStateStyle: WorkingStateStyle, Sendable {
  /// Optional custom title overriding `configuration.title`.
  public let customTitle: String?

  /// Creates a pill working state style with an optional custom title override.
  public nonisolated init(title: String? = nil) {
    self.customTitle = title
  }

  @MainActor
  public func makeBody(configuration: Configuration) -> some View {
    let displayTitle = customTitle ?? configuration.title
    HStack(alignment: .center, spacing: 6) {
      configuration.icon
        .font(.footnote.weight(.semibold))

      Text(displayTitle)
        .font(.footnote.weight(.medium))
        .foregroundStyle(.primary)
        .accessibilityLabel(displayTitle == "Working…" ? "Assistant is working" : displayTitle)
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
  }
}

// MARK: - MinimalWorkingStateStyle (.minimal)

/// Ultra-lightweight inline caption style for `WorkingStateView` matching `MinimalThinkingStateStyle` (`AC-10`).
public struct MinimalWorkingStateStyle: WorkingStateStyle, Sendable {
  /// Optional custom title overriding `configuration.title`.
  public let customTitle: String?

  /// Creates a minimal inline working state style with an optional custom title override.
  public nonisolated init(title: String? = nil) {
    self.customTitle = title
  }

  @MainActor
  public func makeBody(configuration: Configuration) -> some View {
    let displayTitle = customTitle ?? configuration.title
    HStack(alignment: .center, spacing: 5) {
      configuration.icon
        .font(.caption.weight(.semibold))

      Text(displayTitle)
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityLabel(displayTitle == "Working…" ? "Assistant is working" : displayTitle)
    }
    .padding(.vertical, 2)
  }
}

// MARK: - Static Style Presets

extension WorkingStateStyle where Self == InlineWorkingStateStyle {
  /// Default inline working state style with pulsing `sparkles` icon and subheadline label.
  public nonisolated static var inline: InlineWorkingStateStyle {
    InlineWorkingStateStyle()
  }

  /// Inline working state style with a custom title override.
  public nonisolated static func inline(title: String) -> InlineWorkingStateStyle {
    InlineWorkingStateStyle(title: title)
  }

  /// Alias for `.inline`.
  public nonisolated static var `default`: InlineWorkingStateStyle {
    InlineWorkingStateStyle()
  }

  /// Idiomatic SwiftUI alias for `.inline`.
  public nonisolated static var automatic: InlineWorkingStateStyle {
    InlineWorkingStateStyle()
  }
}

extension WorkingStateStyle where Self == PillWorkingStateStyle {
  /// Compact accent-tinted capsule working state style.
  public nonisolated static var pill: PillWorkingStateStyle {
    PillWorkingStateStyle()
  }

  /// Compact accent-tinted capsule working state style with a custom title override.
  public nonisolated static func pill(title: String) -> PillWorkingStateStyle {
    PillWorkingStateStyle(title: title)
  }
}

extension WorkingStateStyle where Self == MinimalWorkingStateStyle {
  /// Ultra-lightweight inline caption working state style without background fill.
  public nonisolated static var minimal: MinimalWorkingStateStyle {
    MinimalWorkingStateStyle()
  }

  /// Ultra-lightweight inline caption working state style with a custom title override.
  public nonisolated static func minimal(title: String) -> MinimalWorkingStateStyle {
    MinimalWorkingStateStyle(title: title)
  }
}

// MARK: - Type-Erased AnyWorkingStateStyle & Environment

/// A type-erased `WorkingStateStyle` wrapper stored in `EnvironmentValues`.
@MainActor
public struct AnyWorkingStateStyle: WorkingStateStyle, Sendable {
  private let bodyBuilder: @MainActor @Sendable (WorkingStateStyleConfiguration) -> AnyView

  /// Type-erases a concrete `WorkingStateStyle`.
  public nonisolated init<S: WorkingStateStyle & Sendable>(_ style: S) {
    self.bodyBuilder = { @MainActor configuration in
      AnyView(WorkingStateStyleHost(style: style, configuration: configuration))
    }
  }

  @MainActor
  public func makeBody(configuration: Configuration) -> AnyView {
    bodyBuilder(configuration)
  }
}

private struct WorkingStateStyleHost<S: WorkingStateStyle>: View {
  let style: S
  let configuration: WorkingStateStyleConfiguration

  var body: some View {
    style.makeBody(configuration: configuration)
  }
}

extension EnvironmentValues {
  /// The active `WorkingStateStyle` in the environment (defaults to `.inline`).
  @Entry public var workingStateStyle: AnyWorkingStateStyle = AnyWorkingStateStyle(.inline)
}

extension View {
  /// Sets the style for `WorkingStateView` within this view hierarchy.
  public func workingStateStyle<S: WorkingStateStyle & Sendable>(_ style: S) -> some View {
    environment(\.workingStateStyle, AnyWorkingStateStyle(style))
  }
}
