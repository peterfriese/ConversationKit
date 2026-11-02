//
//  SourceStackView.swift
//  ConversationKit
//
//  Overlapping domain badge capsule pill and expandable numbered citation cards
//  with strict http/https URL scheme allowlisting (AC-10, AC-18, MUST-FIX-3).
//

import Foundation
import SwiftUI

// MARK: - SourceStackView

/// Renders an overlapping source badge pill (`"N sources"`) that expands on tap into numbered
/// citation cards with strict `http` / `https` URL allowlisting (`AC-10`, `AC-18`, `MUST-FIX-3`).
///
/// ### URL Security Allowlist (`MUST-FIX-3`)
/// - Citations with a valid `citation.sanitizedURL` (`http` or `https` scheme and non-empty host)
///   render as interactive cards that open via `@Environment(\.openURL)`.
/// - Citations with `nil` or disallowed schemes (`javascript:`, `file:`, `data:`, `vbscript:`, or
///   custom schemes) render as non-interactive static cards and never invoke `openURL`.
/// - Additionally, `SourceStackView` installs a defensive `OpenURLAction` filter verifying
///   `url.isAllowedConversationURL` before permitting system link navigation.
@MainActor
public struct SourceStackView: View {
  /// Ordered list of citations to display.
  public let citations: [Citation]

  /// Optional parent message identifier used for accessibility identification.
  public let messageID: String

  /// Optional external binding overriding internal expansion state.
  private var externalIsExpanded: Binding<Bool>?

  @State private var internalIsExpanded: Bool = false

  @Environment(\.openURL) private var openURL
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// Creates a `SourceStackView` with `citations` and an optional `isExpanded` binding.
  public init(
    citations: [Citation],
    isExpanded: Binding<Bool>? = nil
  ) {
    self.citations = citations
    self.messageID = ""
    self.externalIsExpanded = isExpanded
  }

  /// Creates a `SourceStackView` with `citations`, a parent `messageID`, and an optional `isExpanded` binding.
  public init(
    citations: [Citation],
    messageID: String,
    isExpanded: Binding<Bool>? = nil
  ) {
    self.citations = citations
    self.messageID = messageID
    self.externalIsExpanded = isExpanded
  }

  private var isExpanded: Bool {
    externalIsExpanded?.wrappedValue ?? internalIsExpanded
  }

  private var stackAccessibilityID: String {
    let resolvedID = messageID.isEmpty ? (citations.first?.id ?? "default") : messageID
    return ConversationAccessibilityID.sourceStack(resolvedID)
  }

  public var body: some View {
    if !citations.isEmpty {
      VStack(alignment: .leading, spacing: 8) {
        pillHeaderButton

        if isExpanded {
          VStack(alignment: .leading, spacing: 6) {
            ForEach(citations.enumerated(), id: \.element.id) { offset, citation in
              let displayIndex = citation.index ?? (offset + 1)
              CitationCardView(
                citation: citation,
                displayIndex: displayIndex,
                onOpenSafeURL: { safeURL in
                  guard safeURL.isAllowedConversationURL else { return }
                  PlatformHapticEvent.triggerHaptic(.selection)
                  openURL(safeURL)
                }
              )
              .accessibilityIdentifier(ConversationAccessibilityID.citationRow(citation.id))
            }
          }
          .transition(
            reduceMotion
              ? .opacity
              : .opacity.combined(with: .scale(scale: 0.98, anchor: .topLeading))
          )
        }
      }
      .environment(
        \.openURL,
        OpenURLAction { url in
          url.isAllowedConversationURL ? .systemAction : .discarded
        }
      )
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier(stackAccessibilityID)
    }
  }

  // MARK: Pill Header Button

  private var pillHeaderButton: some View {
    Button(action: toggleExpansion) {
      HStack(alignment: .center, spacing: 8) {
        overlappingDomainBadges

        Text(Self.sourcesCountLabel(for: citations.count))
          .font(.caption.weight(.semibold))
          .foregroundStyle(.primary)
          .monospacedDigit()

        Image(systemName: "chevron.right")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)
          .rotationEffect(.degrees(isExpanded ? 90 : 0))
          .animation(
            reduceMotion ? nil : .snappy(duration: 0.22),
            value: isExpanded
          )
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(Color.platformSecondaryBackground, in: Capsule())
      .overlay {
        Capsule()
          .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
      }
      .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel(Self.sourcesCountLabel(for: citations.count))
    .accessibilityHint(
      isExpanded
        ? Text("Double-tap to collapse source citations")
        : Text("Double-tap to expand source citations")
    )
  }

  // MARK: Overlapping Domain Initial Badges (Up to 3)

  private var overlappingDomainBadges: some View {
    let previewCitations = citations.prefix(3)
    return HStack(spacing: -6) {
      ForEach(previewCitations.enumerated(), id: \.element.id) { index, citation in
        DomainInitialBadge(
          domain: citation.domain,
          colorIndex: index
        )
        .zIndex(Double(previewCitations.count - index))
      }
    }
    .accessibilityHidden(true)
  }

  // MARK: Actions & Helpers

  @MainActor
  private func toggleExpansion() {
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

  /// Formats `"1 source"` or `"N sources"`.
  public nonisolated static func sourcesCountLabel(for count: Int) -> String {
    let clamped = max(0, count)
    return clamped == 1 ? "1 source" : "\(clamped) sources"
  }
}

// MARK: - DomainInitialBadge

private struct DomainInitialBadge: View {
  let domain: String
  let colorIndex: Int

  private static let palette: [Color] = [
    .blue,
    .indigo,
    .teal,
  ]

  private var initialLetter: String {
    let trimmed = domain.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let first = trimmed.first else { return "S" }
    return String(first).uppercased()
  }

  private var tintColor: Color {
    Self.palette[colorIndex % Self.palette.count]
  }

  var body: some View {
    ZStack {
      Circle()
        .fill(Color.platformTertiaryBackground)

      Circle()
        .fill(tintColor.opacity(0.18))

      Text(initialLetter)
        .font(.system(size: 10, weight: .bold, design: .rounded))
        .foregroundStyle(tintColor)
    }
    .frame(width: 20, height: 20)
    .overlay {
      Circle()
        .strokeBorder(Color.platformSecondaryBackground, lineWidth: 1.5)
    }
  }
}

// MARK: - CitationCardView

private struct CitationCardView: View {
  let citation: Citation
  let displayIndex: Int
  let onOpenSafeURL: @MainActor (URL) -> Void

  var body: some View {
    if let safeURL = citation.sanitizedURL {
      Button {
        onOpenSafeURL(safeURL)
      } label: {
        cardContent(isInteractive: true)
      }
      .buttonStyle(.plain)
      .accessibilityAddTraits(.isLink)
      .accessibilityLabel(accessibilitySummary(isInteractive: true))
    } else {
      cardContent(isInteractive: false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary(isInteractive: false))
    }
  }

  private func cardContent(isInteractive: Bool) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Text("[\(displayIndex)]")
        .font(.caption.monospaced().weight(.semibold))
        .foregroundStyle(isInteractive ? Color.accentColor : Color.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
          Color.platformTertiaryBackground,
          in: RoundedRectangle(cornerRadius: 6, style: .continuous)
        )

      VStack(alignment: .leading, spacing: 3) {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text(citation.title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)

          Spacer(minLength: 4)

          if isInteractive {
            Image(systemName: "arrow.up.right")
              .font(.caption2.weight(.semibold))
              .foregroundStyle(.tertiary)
              .accessibilityHidden(true)
          }
        }

        HStack(spacing: 4) {
          Image(systemName: isInteractive ? "globe" : "doc.text")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)

          Text(citation.domain)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        if let snippet = citation.snippet,
          !snippet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
          Text(snippet)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .padding(.top, 2)
        }
      }
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      Color.platformSecondaryBackground,
      in: RoundedRectangle(cornerRadius: 12, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
    }
    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  private func accessibilitySummary(isInteractive: Bool) -> String {
    var parts: [String] = ["Source \(displayIndex): \(citation.title), \(citation.domain)"]
    if let snippet = citation.snippet, !snippet.isEmpty {
      parts.append(snippet)
    }
    if !isInteractive {
      parts.append("Link unavailable")
    }
    return parts.joined(separator: ". ")
  }
}
