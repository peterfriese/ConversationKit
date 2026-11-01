//
//  ComposerPopupView.swift
//  ConversationKit
//
//  Floating Liquid Glass autocomplete popover for '/' slash commands and '@' resource
//  mentions with matched-substring highlighting (F-5, AC-8, AC-9).
//

import SwiftUI

// MARK: - ComposerPopupItem

/// A unified autocomplete entry displayed inside `ComposerPopupView` (`F-5`, `AC-8`).
public enum ComposerPopupItem: Identifiable, Hashable, Sendable {
  case command(SlashCommand)
  case mention(ResourceMention)

  public var id: String {
    switch self {
    case .command(let cmd):
      return "cmd-\(cmd.id)"
    case .mention(let mention):
      return "mention-\(mention.id)"
    }
  }

  /// Primary label matched against the active query (`"/trigger"` for commands, `title` for mentions).
  public var primaryText: String {
    switch self {
    case .command(let cmd):
      return cmd.formattedTrigger
    case .mention(let mention):
      return mention.title
    }
  }

  /// Optional secondary description (`title` or `description` for commands, `subtitle` for mentions).
  public var secondaryText: String? {
    switch self {
    case .command(let cmd):
      if let description = cmd.description, !description.isEmpty {
        return description
      }
      if cmd.title != cmd.trigger && !cmd.title.isEmpty {
        return cmd.title
      }
      return nil
    case .mention(let mention):
      if let subtitle = mention.subtitle, !subtitle.isEmpty {
        return subtitle
      }
      return mention.formattedHandle
    }
  }

  /// Optional trailing badge text (`category` for commands, `category` or `@handle` for mentions).
  public var trailingBadge: String? {
    switch self {
    case .command(let cmd):
      if let category = cmd.category, !category.isEmpty {
        return category
      }
      if cmd.title != cmd.trigger && !cmd.title.isEmpty {
        return cmd.title
      }
      return nil
    case .mention(let mention):
      if let category = mention.category, !category.isEmpty {
        return category
      }
      return mention.formattedHandle
    }
  }

  /// SF Symbol name displayed in the leading icon badge.
  public var symbolName: String {
    switch self {
    case .command(let cmd):
      return cmd.systemImage
    case .mention(let mention):
      return mention.symbolName
    }
  }
}

// MARK: - ComposerPopupView

/// Floating Liquid Glass autocomplete popover presented above `MessageComposerView` when a
/// word-boundary `/` command or `@` resource mention query is active (`F-5`, `AC-8`, `AC-9`).
///
/// Highlights matched query characters in `.semibold` primary ink and remaining characters in
/// secondary ink via `ComposerTextBuffer.highlightSegments(in:matching:)`, displays up to 6 rows
/// before scrolling internally, and shows an inline loading row while an async `ResourceMentionProvider`
/// is actively searching.
@MainActor
public struct ComposerPopupView: View {
  /// The active search query text (without the leading `/` or `@`).
  public let query: String

  /// The matching items to display in the autocomplete popover.
  public let items: [ComposerPopupItem]

  /// Indicates whether an asynchronous `ResourceMentionProvider` search is currently in flight.
  public let isLoading: Bool

  /// Callback invoked when a `SlashCommand` item is selected.
  public let onSelectCommand: (@MainActor (SlashCommand) -> Void)?

  /// Callback invoked when a `ResourceMention` item is selected.
  public let onSelectMention: (@MainActor (ResourceMention) -> Void)?

  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  private static let rowHeight: CGFloat = 46
  private static let maxVisibleRows: Int = 6
  private static let cornerRadius: CGFloat = 18

  /// Creates a `ComposerPopupView` with explicit `ComposerPopupItem` entries.
  public init(
    query: String,
    items: [ComposerPopupItem],
    isLoading: Bool = false,
    onSelectCommand: (@MainActor (SlashCommand) -> Void)? = nil,
    onSelectMention: (@MainActor (ResourceMention) -> Void)? = nil
  ) {
    self.query = ComposerTextBuffer.cleanText(query)
    self.items = items
    self.isLoading = isLoading
    self.onSelectCommand = onSelectCommand
    self.onSelectMention = onSelectMention
  }

  /// Creates a `ComposerPopupView` from matching `SlashCommand` and `ResourceMention` collections.
  public init(
    query: String,
    commands: [SlashCommand] = [],
    mentions: [ResourceMention] = [],
    isLoading: Bool = false,
    onSelectCommand: (@MainActor (SlashCommand) -> Void)? = nil,
    onSelectMention: (@MainActor (ResourceMention) -> Void)? = nil
  ) {
    self.query = ComposerTextBuffer.cleanText(query)
    self.items = commands.map(ComposerPopupItem.command) + mentions.map(ComposerPopupItem.mention)
    self.isLoading = isLoading
    self.onSelectCommand = onSelectCommand
    self.onSelectMention = onSelectMention
  }

  /// Convenience initializer for presenting `/` slash command matches.
  public init(
    query: String,
    commands: [SlashCommand],
    onSelect: @escaping @MainActor (SlashCommand) -> Void
  ) {
    self.init(
      query: query,
      commands: commands,
      mentions: [],
      isLoading: false,
      onSelectCommand: onSelect,
      onSelectMention: nil
    )
  }

  /// Convenience initializer for presenting `@` resource mention matches.
  public init(
    query: String,
    mentions: [ResourceMention],
    isLoading: Bool = false,
    onSelect: @escaping @MainActor (ResourceMention) -> Void
  ) {
    self.init(
      query: query,
      commands: [],
      mentions: mentions,
      isLoading: isLoading,
      onSelectCommand: nil,
      onSelectMention: onSelect
    )
  }

  public var body: some View {
    if !items.isEmpty || isLoading {
      popupSurface
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(ConversationAccessibilityID.composerPopup)
    }
  }

  // MARK: - Surface & Scrollable List

  @ViewBuilder
  private var popupSurface: some View {
    let content = VStack(alignment: .leading, spacing: 0) {
      if !items.isEmpty {
        ScrollView(.vertical, showsIndicators: items.count > Self.maxVisibleRows) {
          LazyVStack(alignment: .leading, spacing: 2) {
            ForEach(items) { item in
              popupRowButton(for: item)
            }
          }
          .padding(6)
        }
        .frame(maxHeight: scrollContainerMaxHeight)
      }

      if isLoading {
        if !items.isEmpty {
          Divider()
            .padding(.horizontal, 12)
        }
        loadingIndicatorRow
      }
    }

    if reduceTransparency {
      content
        .background(
          Color.platformSecondaryBackground,
          in: RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
        )
        .overlay {
          RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
            .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
        }
    } else {
      GlassEffectContainer(spacing: 8) {
        content
          .glassEffect(.regular, in: .rect(cornerRadius: Self.cornerRadius))
      }
    }
  }

  private var scrollContainerMaxHeight: CGFloat {
    let visibleCount = min(items.count, Self.maxVisibleRows)
    return CGFloat(visibleCount) * Self.rowHeight + 12
  }

  // MARK: - Row Rendering

  @ViewBuilder
  private func popupRowButton(for item: ComposerPopupItem) -> some View {
    Button {
      PlatformHapticEvent.triggerHaptic(.selection)
      switch item {
      case .command(let cmd):
        onSelectCommand?(cmd)
      case .mention(let mention):
        onSelectMention?(mention)
      }
    } label: {
      HStack(spacing: 10) {
        leadingIconBadge(for: item)

        VStack(alignment: .leading, spacing: 2) {
          highlightedText(for: item.primaryText, matching: query)
            .font(.subheadline)
            .lineLimit(1)

          if let secondaryText = item.secondaryText, !secondaryText.isEmpty {
            highlightedSecondaryText(for: secondaryText, matching: query)
              .font(.caption)
              .lineLimit(1)
          }
        }

        Spacer(minLength: 8)

        if let badge = item.trailingBadge, !badge.isEmpty {
          Text(badge)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
              Color.primary.opacity(0.07),
              in: Capsule()
            )
            .lineLimit(1)
        }
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 7)
      .frame(minHeight: Self.rowHeight - 4)
      .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(ConversationAccessibilityID.popupItem(rawItemIdentifier(for: item)))
    .accessibilityLabel(accessibilityLabel(for: item))
  }

  @ViewBuilder
  private func leadingIconBadge(for item: ComposerPopupItem) -> some View {
    let tint: Color = switch item {
    case .command:
      .accentColor
    case .mention:
      .indigo
    }

    Image(systemName: item.symbolName)
      .font(.system(size: 13, weight: .semibold))
      .foregroundStyle(tint)
      .frame(width: 28, height: 28)
      .background(
        tint.opacity(0.14),
        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
      )
  }

  @ViewBuilder
  private var loadingIndicatorRow: some View {
    HStack(spacing: 10) {
      ProgressView()
        .controlSize(.small)

      Text("Searching resources…")
        .font(.caption)
        .foregroundStyle(.secondary)

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Searching resources")
  }

  // MARK: - Substring Highlighting (`ComposerTextBuffer.highlightSegments(in:matching:)`)

  /// Renders matched query characters in `.semibold` primary ink and remaining characters in secondary ink.
  internal func highlightedText(for candidate: String, matching query: String) -> Text {
    let segments = ComposerTextBuffer.highlightSegments(in: candidate, matching: query)
    guard !segments.isEmpty else {
      return Text(candidate)
    }

    return segments.reduce(Text("")) { partial, segment in
      let styledSegment: Text = if segment.isMatched {
        Text(segment.text)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
      } else {
        Text(segment.text)
          .fontWeight(.regular)
          .foregroundStyle(.secondary)
      }
      return Text("\(partial)\(styledSegment)")
    }
  }

  internal func highlightedSecondaryText(for candidate: String, matching query: String) -> Text {
    let segments = ComposerTextBuffer.highlightSegments(in: candidate, matching: query)
    guard !segments.isEmpty else {
      return Text(candidate).foregroundStyle(.secondary)
    }

    return segments.reduce(Text("")) { partial, segment in
      let styledSegment: Text = if segment.isMatched {
        Text(segment.text)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
      } else {
        Text(segment.text)
          .fontWeight(.regular)
          .foregroundStyle(.secondary)
      }
      return Text("\(partial)\(styledSegment)")
    }
  }

  private func rawItemIdentifier(for item: ComposerPopupItem) -> String {
    switch item {
    case .command(let cmd):
      return cmd.id
    case .mention(let mention):
      return mention.id
    }
  }

  private func accessibilityLabel(for item: ComposerPopupItem) -> String {
    if let secondary = item.secondaryText, !secondary.isEmpty {
      return "\(item.primaryText), \(secondary)"
    }
    return item.primaryText
  }
}

#Preview("ComposerPopupView - Slash Commands") {
  VStack {
    Spacer()
    ComposerPopupView(
      query: "sum",
      commands: [
        SlashCommand(
          id: "summarize",
          trigger: "summarize",
          title: "Summarize thread",
          description: "Condense key decisions and action items",
          symbolName: "text.Format.size",
          category: "Workflow"
        ),
        SlashCommand(
          id: "review",
          trigger: "review",
          title: "Code review",
          description: "Audit Swift 6 concurrency and Liquid Glass rules",
          symbolName: "checkmark.shield",
          category: "Engineering"
        )
      ]
    ) { _ in }
  }
  .padding(.vertical)
}
