//
//  StreamingMarkdownView.swift
//  ConversationKit
//
//  Incremental block-committed Markdown renderer with adaptive 60Hz token cadence smoothing,
//  TextRenderer per-word ink fade + cap-height streaming cursor, copyable code block cards,
//  and strict http/https URL scheme allowlisting (AC-10, AC-17, AC-18, MUST-FIX-3, SHOULD-FIX-4).
//

import Foundation
import SwiftUI

// MARK: - Accessibility Identifier Extensions

extension ConversationAccessibilityID {
  /// Accessibility identifier for a fenced code block's Copy button (`message.codeBlock.copy.<id>`).
  public static func codeBlockCopyButton(_ id: String) -> String {
    "message.codeBlock.copy.\(id)"
  }
}

// MARK: - MarkdownBlock (`AC-17`, `SHOULD-FIX-4`)

/// Represents a discrete structural Markdown block parsed by `StreamingMarkdownView` (`§3.6.2`, `AC-17`).
///
/// Completed blocks (`isCommitted == true`) are rendered inside `CommittedMarkdownBlockView` (`Equatable`),
/// allowing SwiftUI to skip re-parsing and re-laying out settled paragraphs, headings, lists, tables,
/// and code blocks while new tokens stream into the single trailing `tail` block at 120Hz.
public struct MarkdownBlock: Identifiable, Equatable, Hashable, Sendable {

  /// A single item inside a `.list` `MarkdownBlock`.
  public struct ListItem: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public var text: String
    public var number: Int?
    public var isChecked: Bool?

    public init(
      id: String = UUID().uuidString,
      text: String,
      number: Int? = nil,
      isChecked: Bool? = nil
    ) {
      self.id = id
      self.text = text
      self.number = number
      self.isChecked = isChecked
    }
  }

  /// Structural category of a `MarkdownBlock`.
  public enum Kind: Equatable, Hashable, Sendable {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case codeBlock(language: String?, code: String, isClosed: Bool)
    case blockquote(text: String)
    case list(items: [ListItem], isOrdered: Bool)
    case table(headers: [String], rows: [[String]])
    case thematicBreak
  }

  /// Stable block identifier across streaming updates.
  public let id: String

  /// Zero-based sequential block index within the Markdown document.
  public let index: Int

  /// Structural kind and payload of the block.
  public let kind: Kind

  /// Indicates whether this block is structurally closed and committed (`true`) or actively streaming (`false`).
  public let isCommitted: Bool

  /// Creates a `MarkdownBlock`.
  public init(
    id: String? = nil,
    index: Int = 0,
    kind: Kind,
    isCommitted: Bool = true
  ) {
    self.index = index
    self.kind = kind
    self.isCommitted = isCommitted
    self.id = id ?? Self.makeStableID(index: index, kind: kind)
  }

  private static func makeStableID(index: Int, kind: Kind) -> String {
    let tag: String = switch kind {
    case .heading(let level, _):
      "h\(level)"
    case .paragraph:
      "p"
    case .codeBlock(let language, _, _):
      "code-\(language ?? "plain")"
    case .blockquote:
      "quote"
    case .list(_, let isOrdered):
      isOrdered ? "ol" : "ul"
    case .table:
      "table"
    case .thematicBreak:
      "hr"
    }
    return "md-block-\(index)-\(tag)"
  }

  // MARK: - Incremental Block Parser (`AC-17`, `SHOULD-FIX-4`)

  /// Incrementally parses a Markdown string into frozen `committed` blocks and an optional active `tail` block (`AC-17`).
  ///
  /// - Parameters:
  ///   - markdown: Raw Markdown input string.
  ///   - isStreaming: Whether the message is actively streaming tokens. When `false`, all blocks are returned in `committed` and `tail` is `nil`.
  /// - Returns: A tuple of `(committed: [MarkdownBlock], tail: MarkdownBlock?)`.
  public static func parse(
    _ markdown: String,
    isStreaming: Bool = false
  ) -> (committed: [MarkdownBlock], tail: MarkdownBlock?) {
    guard !markdown.isEmpty else {
      return (committed: [], tail: nil)
    }

    let normalized = markdown.utf8.contains(UInt8(ascii: "\r"))
      ? markdown.replacingOccurrences(of: "\r\n", with: "\n")
      : markdown
    let rawLines = normalized.components(separatedBy: "\n")

    var parsedKinds: [(kind: Kind, endedWithExplicitBoundary: Bool)] = []
    var lineIndex = 0
    let lineCount = rawLines.count

    while lineIndex < lineCount {
      let line = rawLines[lineIndex]
      let trimmed = line.trimmingCharacters(in: .whitespaces)

      // 1. Skip blank lines (and mark previous block as having a trailing blank-line boundary).
      // When `normalized` ends with a single `\n`, `components(separatedBy: "\n")` produces a
      // trailing `""` element at `lineCount - 1` which terminates the preceding line rather than
      // forming an empty blank line (`\n\n`).
      if trimmed.isEmpty {
        let isSingleTrailingNewlineArtifact = (lineIndex == lineCount - 1) && normalized.hasSuffix("\n")
        if !isSingleTrailingNewlineArtifact, !parsedKinds.isEmpty {
          parsedKinds[parsedKinds.count - 1].endedWithExplicitBoundary = true
        }
        lineIndex += 1
        continue
      }

      // 2. Fenced Code Block (``` or ~~~)
      if let fence = parseOpeningFence(trimmed) {
        lineIndex += 1
        var codeLines: [String] = []
        var isClosed = false

        while lineIndex < lineCount {
          let currentLine = rawLines[lineIndex]
          let currentTrimmed = currentLine.trimmingCharacters(in: .whitespaces)
          if isClosingFence(currentTrimmed, matching: fence.marker, minLength: fence.count) {
            isClosed = true
            lineIndex += 1
            break
          }
          codeLines.append(currentLine)
          lineIndex += 1
        }

        // A closed code block is committed as soon as its closing fence line is followed by at least one more line
        // (i.e. a newline after the closing fence) or when streaming has finished.
        let hasNewlineAfterClosingFence = isClosed && (lineIndex < lineCount || normalized.hasSuffix("\n"))
        parsedKinds.append((
          kind: .codeBlock(
            language: fence.language,
            code: codeLines.joined(separator: "\n"),
            isClosed: isClosed
          ),
          endedWithExplicitBoundary: hasNewlineAfterClosingFence
        ))
        continue
      }

      // 3. Thematic Break (---, ***, ___)
      if isThematicBreak(trimmed) {
        let hasTrailingNewline = (lineIndex + 1 < lineCount)
        parsedKinds.append((
          kind: .thematicBreak,
          endedWithExplicitBoundary: hasTrailingNewline
        ))
        lineIndex += 1
        continue
      }

      // 4. ATX Heading (# ... ######)
      if let heading = parseHeading(trimmed) {
        let hasTrailingNewline = (lineIndex + 1 < lineCount)
        parsedKinds.append((
          kind: .heading(level: heading.level, text: heading.text),
          endedWithExplicitBoundary: hasTrailingNewline && (lineIndex + 1 < lineCount && rawLines[lineIndex + 1].trimmingCharacters(in: .whitespaces).isEmpty)
        ))
        lineIndex += 1
        continue
      }

      // 5. GFM Pipe Table
      if lineIndex + 1 < lineCount,
        isTablePipeRow(trimmed),
        isTableDelimiterRow(rawLines[lineIndex + 1].trimmingCharacters(in: .whitespaces))
      {
        let headers = parseTableCells(from: trimmed)
        lineIndex += 2
        var rows: [[String]] = []
        while lineIndex < lineCount {
          let rowTrimmed = rawLines[lineIndex].trimmingCharacters(in: .whitespaces)
          guard !rowTrimmed.isEmpty, isTablePipeRow(rowTrimmed) else { break }
          rows.append(parseTableCells(from: rowTrimmed))
          lineIndex += 1
        }
        parsedKinds.append((
          kind: .table(headers: headers, rows: rows),
          endedWithExplicitBoundary: false
        ))
        continue
      }

      // 6. Blockquote (> ...)
      if trimmed.hasPrefix(">") {
        var quoteLines: [String] = []
        while lineIndex < lineCount {
          let currentTrimmed = rawLines[lineIndex].trimmingCharacters(in: .whitespaces)
          guard currentTrimmed.hasPrefix(">") else { break }
          var stripped = String(currentTrimmed.dropFirst())
          if stripped.hasPrefix(" ") {
            stripped.removeFirst()
          }
          quoteLines.append(stripped)
          lineIndex += 1
        }
        parsedKinds.append((
          kind: .blockquote(text: quoteLines.joined(separator: "\n")),
          endedWithExplicitBoundary: false
        ))
        continue
      }

      // 7. Unordered or Ordered List
      if let firstItem = parseListItem(trimmed, itemIndex: 0, blockIndex: parsedKinds.count) {
        let isOrdered = firstItem.isOrdered
        var items: [ListItem] = [firstItem.item]
        lineIndex += 1

        while lineIndex < lineCount {
          let currentTrimmed = rawLines[lineIndex].trimmingCharacters(in: .whitespaces)
          guard !currentTrimmed.isEmpty else { break }
          if let nextParsed = parseListItem(
            currentTrimmed,
            itemIndex: items.count,
            blockIndex: parsedKinds.count
          ), nextParsed.isOrdered == isOrdered {
            items.append(nextParsed.item)
            lineIndex += 1
          } else {
            break
          }
        }

        parsedKinds.append((
          kind: .list(items: items, isOrdered: isOrdered),
          endedWithExplicitBoundary: false
        ))
        continue
      }

      // 8. Paragraph (accumulates consecutive non-blank, non-structural lines)
      var paragraphLines: [String] = [line]
      lineIndex += 1
      while lineIndex < lineCount {
        let nextLine = rawLines[lineIndex]
        let nextTrimmed = nextLine.trimmingCharacters(in: .whitespaces)
        if nextTrimmed.isEmpty
          || parseOpeningFence(nextTrimmed) != nil
          || isThematicBreak(nextTrimmed)
          || parseHeading(nextTrimmed) != nil
          || nextTrimmed.hasPrefix(">")
          || parseListItem(nextTrimmed, itemIndex: 0, blockIndex: parsedKinds.count) != nil
          || (lineIndex + 1 < lineCount
            && isTablePipeRow(nextTrimmed)
            && isTableDelimiterRow(rawLines[lineIndex + 1].trimmingCharacters(in: .whitespaces)))
        {
          break
        }
        paragraphLines.append(nextLine)
        lineIndex += 1
      }

      parsedKinds.append((
        kind: .paragraph(text: paragraphLines.joined(separator: "\n")),
        endedWithExplicitBoundary: false
      ))
    }

    guard !parsedKinds.isEmpty else {
      return (committed: [], tail: nil)
    }

    if !isStreaming {
      let committed = parsedKinds.enumerated().map { idx, entry in
        MarkdownBlock(index: idx, kind: entry.kind, isCommitted: true)
      }
      return (committed: committed, tail: nil)
    }

    // While streaming, all blocks prior to the last block are committed.
    // The final block is committed only if it ended with an explicit commit boundary
    // (e.g., blank line `\n\n` or closed code fence followed by `\n`) AND is not an unclosed code block.
    let lastIndex = parsedKinds.count - 1
    let lastEntry = parsedKinds[lastIndex]
    let isLastCodeBlockUnclosed: Bool = {
      if case .codeBlock(_, _, let isClosed) = lastEntry.kind {
        return !isClosed
      }
      return false
    }()

    let shouldCommitLast = lastEntry.endedWithExplicitBoundary && !isLastCodeBlockUnclosed

    if shouldCommitLast {
      let committed = parsedKinds.enumerated().map { idx, entry in
        MarkdownBlock(index: idx, kind: entry.kind, isCommitted: true)
      }
      return (committed: committed, tail: nil)
    } else {
      let committed = parsedKinds.dropLast().enumerated().map { idx, entry in
        MarkdownBlock(index: idx, kind: entry.kind, isCommitted: true)
      }
      let tail = MarkdownBlock(
        index: lastIndex,
        kind: lastEntry.kind,
        isCommitted: false
      )
      return (committed: committed, tail: tail)
    }
  }

  // MARK: - Private Line Lexers

  private static func parseOpeningFence(
    _ trimmedLine: String
  ) -> (marker: Character, count: Int, language: String?)? {
    guard let first = trimmedLine.first, first == "`" || first == "~" else {
      return nil
    }
    var count = 0
    for ch in trimmedLine {
      if ch == first {
        count += 1
      } else {
        break
      }
    }
    guard count >= 3 else { return nil }
    let remainder = String(trimmedLine.dropFirst(count)).trimmingCharacters(in: .whitespaces)
    if first == "`" && remainder.contains("`") {
      return nil
    }
    let language = remainder.isEmpty ? nil : remainder.components(separatedBy: .whitespaces).first
    return (marker: first, count: count, language: language)
  }

  private static func isClosingFence(
    _ trimmedLine: String,
    matching marker: Character,
    minLength: Int
  ) -> Bool {
    guard trimmedLine.first == marker else { return false }
    var count = 0
    for ch in trimmedLine {
      if ch == marker {
        count += 1
      } else if ch.isWhitespace {
        continue
      } else {
        return false
      }
    }
    return count >= minLength
  }

  private static func isThematicBreak(_ trimmedLine: String) -> Bool {
    guard let first = trimmedLine.first, first == "-" || first == "*" || first == "_" else {
      return false
    }
    var markerCount = 0
    for ch in trimmedLine {
      if ch == first {
        markerCount += 1
      } else if ch == " " || ch == "\t" {
        continue
      } else {
        return false
      }
    }
    return markerCount >= 3
  }

  private static func parseHeading(_ trimmedLine: String) -> (level: Int, text: String)? {
    guard trimmedLine.hasPrefix("#") else { return nil }
    var level = 0
    for ch in trimmedLine {
      if ch == "#" {
        level += 1
      } else {
        break
      }
    }
    guard (1...6).contains(level) else { return nil }
    let afterHashes = trimmedLine.dropFirst(level)
    guard afterHashes.isEmpty || afterHashes.first == " " || afterHashes.first == "\t" else {
      return nil
    }
    let text = afterHashes.trimmingCharacters(in: .whitespaces)
    return (level: level, text: text)
  }

  private static func parseListItem(
    _ trimmedLine: String,
    itemIndex: Int,
    blockIndex: Int
  ) -> (item: ListItem, isOrdered: Bool)? {
    // Unordered list markers: "- ", "* ", "+ "
    if trimmedLine.count >= 2 {
      let prefix2 = trimmedLine.prefix(2)
      if prefix2 == "- " || prefix2 == "* " || prefix2 == "+ " {
        let rawBody = String(trimmedLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        let (cleanText, isChecked) = extractCheckbox(from: rawBody)
        return (
          item: ListItem(
            id: "list-\(blockIndex)-\(itemIndex)",
            text: cleanText,
            number: nil,
            isChecked: isChecked
          ),
          isOrdered: false
        )
      }
    }

    // Ordered list markers: "1. ", "2) "
    var digitCount = 0
    for ch in trimmedLine {
      if ch.isNumber {
        digitCount += 1
      } else {
        break
      }
    }
    guard digitCount > 0 && digitCount <= 9 else { return nil }
    let afterDigits = trimmedLine.dropFirst(digitCount)
    guard afterDigits.count >= 2 else { return nil }
    let delimiter = afterDigits.first
    let second = afterDigits.dropFirst().first
    guard (delimiter == "." || delimiter == ")") && (second == " " || second == "\t") else {
      return nil
    }
    let number = Int(trimmedLine.prefix(digitCount))
    let rawBody = String(afterDigits.dropFirst(2)).trimmingCharacters(in: .whitespaces)
    let (cleanText, isChecked) = extractCheckbox(from: rawBody)
    return (
      item: ListItem(
        id: "list-\(blockIndex)-\(itemIndex)",
        text: cleanText,
        number: number,
        isChecked: isChecked
      ),
      isOrdered: true
    )
  }

  private static func extractCheckbox(from text: String) -> (String, Bool?) {
    if text.hasPrefix("[ ] ") {
      return (String(text.dropFirst(4)), false)
    }
    if text.hasPrefix("[x] ") || text.hasPrefix("[X] ") {
      return (String(text.dropFirst(4)), true)
    }
    return (text, nil)
  }

  private static func isTablePipeRow(_ trimmedLine: String) -> Bool {
    trimmedLine.contains("|") && !trimmedLine.hasPrefix("```")
  }

  private static func isTableDelimiterRow(_ trimmedLine: String) -> Bool {
    guard trimmedLine.contains("|") && trimmedLine.contains("-") else { return false }
    let allowed = CharacterSet(charactersIn: "|-: \t")
    return trimmedLine.unicodeScalars.allSatisfy { allowed.contains($0) }
  }

  private static func parseTableCells(from rowLine: String) -> [String] {
    var stripped = rowLine.trimmingCharacters(in: .whitespaces)
    if stripped.hasPrefix("|") {
      stripped.removeFirst()
    }
    if stripped.hasSuffix("|") {
      stripped.removeLast()
    }
    return stripped
      .components(separatedBy: "|")
      .map { $0.trimmingCharacters(in: .whitespaces) }
  }
}

// MARK: - StreamingTailTextRenderer (`AC-17`, `SHOULD-FIX-4`)

/// Custom SwiftUI `TextRenderer` applied exclusively to the active trailing prose block (`tailBlock`)
/// during token streaming (`§3.6.3`, `AC-17`).
///
/// Renders newly revealed trailing glyph slices with a subtle ink opacity ramp (`0.22 -> 1.0`)
/// and draws an inline cap-height rounded capsule cursor immediately after the final glyph slice
/// when `showsCursor` is `true`.
///
/// - Important: Unclosed fenced `.codeBlock` blocks bypass `StreamingTailTextRenderer` (`SHOULD-FIX-4`)
///   so monospaced code streams at 120Hz without per-glyph fade overhead.
public struct StreamingTailTextRenderer: TextRenderer, Sendable {
  /// Progress (`0.0...1.0`) for fading in the trailing word/run of the active block.
  public var trailingRevealProgress: Double

  /// Whether to draw the inline cap-height streaming cursor after the final glyph run.
  public var showsCursor: Bool

  public var animatableData: Double {
    get { trailingRevealProgress }
    set { trailingRevealProgress = newValue }
  }

  public init(
    trailingRevealProgress: Double = 1.0,
    showsCursor: Bool = true
  ) {
    self.trailingRevealProgress = min(max(trailingRevealProgress, 0.0), 1.0)
    self.showsCursor = showsCursor
  }

  public func draw(layout: Text.Layout, in context: inout GraphicsContext) {
    let allLines = Array(layout)
    guard !allLines.isEmpty else { return }

    let lastLineIndex = allLines.count - 1
    var lastGlyphRect: CGRect?

    for (lineIdx, line) in allLines.enumerated() {
      let runs = Array(line)
      let lastRunIndex = runs.count - 1

      for (runIdx, run) in runs.enumerated() {
        let slices = Array(run)
        let sliceCount = slices.count
        let isLastRunOfLastLine = (lineIdx == lastLineIndex && runIdx == lastRunIndex)

        for (sliceIdx, slice) in slices.enumerated() {
          var sliceContext = context
          if isLastRunOfLastLine && sliceCount > 0 {
            let tailWindow = min(4, sliceCount)
            let distanceFromEnd = (sliceCount - 1) - sliceIdx
            if distanceFromEnd < tailWindow {
              let weight = Double(tailWindow - distanceFromEnd) / Double(tailWindow)
              let baseAlpha = 0.22 + (0.78 * trailingRevealProgress)
              let effectiveOpacity = 1.0 - (weight * (1.0 - baseAlpha))
              sliceContext.opacity = min(max(effectiveOpacity, 0.22), 1.0)
            }
          }
          sliceContext.draw(slice)
          if isLastRunOfLastLine && sliceIdx == sliceCount - 1 {
            lastGlyphRect = slice.typographicBounds.rect
          }
        }
      }
    }

    if showsCursor, let rect = lastGlyphRect, rect.height > 0 {
      let cursorHeight = max(12, rect.height * 0.78)
      let cursorY = rect.midY - (cursorHeight / 2.0)
      let cursorRect = CGRect(
        x: rect.maxX + 2.5,
        y: cursorY,
        width: 2.2,
        height: cursorHeight
      )
      let cursorPath = Path(roundedRect: cursorRect, cornerRadius: 1.1)
      context.fill(cursorPath, with: .style(.tint))
    }
  }
}

// MARK: - StreamingMarkdownView (`AC-17`, `MUST-FIX-3`, `SHOULD-FIX-4`)

/// High-performance incremental Markdown view for assistant responses (`AC-10`, `AC-17`, `AC-18`, `MUST-FIX-3`, `SHOULD-FIX-4`).
///
/// ### Architectural Guarantees
/// 1. **Block-Level Commit Boundary (`AC-17`):** Completed Markdown blocks are frozen and rendered inside
///    `CommittedMarkdownBlockView` (`Equatable`), so incoming streaming tokens only re-parse the single
///    active `tail` block.
/// 2. **Code Block Fast Path (`SHOULD-FIX-4`):** Unclosed fenced `.codeBlock` blocks bypass `StreamingTailTextRenderer`
///    and render directly inside the two-tone monospaced code card with a one-tap **Copy** button.
/// 3. **Strict URL Allowlist (`MUST-FIX-3`):** Installs an `OpenURLAction` guard that permits only
///    `url.isAllowedConversationURL` (`http` and `https` with non-empty host), discarding `javascript:`,
///    `file:`, `data:`, and custom schemes.
/// 4. **Zero Liquid Glass in Scrolling Cells (`AC-10`):** Uses semantic code-block and blockquote surfaces
///    without Liquid Glass modifiers.
@MainActor
public struct StreamingMarkdownView: View {
  /// Raw Markdown string to render.
  public let markdown: String

  /// Whether tokens are actively streaming into `markdown`.
  public var isStreaming: Bool

  @Environment(\.isStreamingCadenceEnabled) private var isStreamingCadenceEnabled
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var displayedCharacterCount: Int = 0
  @State private var tailRevealProgress: Double = 1.0

  /// Creates a `StreamingMarkdownView`.
  ///
  /// - Parameters:
  ///   - markdown: The Markdown string to parse and render.
  ///   - isStreaming: Indicates whether the message is actively streaming tokens (`false` by default).
  public init(
    markdown: String,
    isStreaming: Bool = false
  ) {
    self.markdown = markdown
    self.isStreaming = isStreaming
  }

  private var effectiveMarkdown: String {
    guard isStreaming, isStreamingCadenceEnabled, !reduceMotion else {
      return markdown
    }
    let totalCount = markdown.count
    if displayedCharacterCount <= 0 || displayedCharacterCount >= totalCount {
      return markdown
    }
    let endIndex = markdown.index(markdown.startIndex, offsetBy: displayedCharacterCount)
    return String(markdown[..<endIndex])
  }

  public var body: some View {
    let parsed = MarkdownBlock.parse(effectiveMarkdown, isStreaming: isStreaming)

    VStack(alignment: .leading, spacing: 12) {
      ForEach(parsed.committed) { block in
        CommittedMarkdownBlockView(block: block)
          .equatable()
      }

      if let tail = parsed.tail {
        TailMarkdownBlockView(
          block: tail,
          isStreaming: isStreaming,
          revealProgress: reduceMotion ? 1.0 : tailRevealProgress,
          reduceMotion: reduceMotion
        )
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .environment(
      \.openURL,
      OpenURLAction { url in
        url.isAllowedConversationURL ? .systemAction : .discarded
      }
    )
    .onAppear {
      displayedCharacterCount = markdown.count
    }
    .onChange(of: markdown) { oldValue, newValue in
      handleMarkdownUpdate(from: oldValue, to: newValue)
    }
    .onChange(of: isStreaming) { _, streaming in
      if !streaming {
        displayedCharacterCount = markdown.count
        tailRevealProgress = 1.0
      }
    }
    .task(id: markdown) {
      guard isStreaming, isStreamingCadenceEnabled, !reduceMotion else {
        displayedCharacterCount = markdown.count
        return
      }
      let target = markdown.count
      while !Task.isCancelled && displayedCharacterCount < target {
        displayedCharacterCount = Self.nextCadenceCharacterCount(
          currentDisplayedCount: displayedCharacterCount,
          targetCount: target
        )
        if displayedCharacterCount < target {
          try? await Task.sleep(for: .milliseconds(8))
        }
      }
    }
  }

  private func handleMarkdownUpdate(from oldValue: String, to newValue: String) {
    if !isStreaming || !isStreamingCadenceEnabled || reduceMotion {
      displayedCharacterCount = newValue.count
      tailRevealProgress = 1.0
      return
    }

    displayedCharacterCount = Self.characterCountOnChunkArrival(
      currentDisplayedCount: displayedCharacterCount,
      oldCount: oldValue.count,
      newCount: newValue.count,
      isStreaming: isStreaming,
      isStreamingCadenceEnabled: isStreamingCadenceEnabled,
      reduceMotion: reduceMotion
    )

    tailRevealProgress = 0.25
    withAnimation(.easeOut(duration: 0.14)) {
      tailRevealProgress = 1.0
    }
  }

  /// Computes the updated `displayedCharacterCount` immediately upon receiving a new Markdown chunk (`oldCount -> newCount`).
  /// Commits everything up to `oldCount` while streaming so the view never freezes on the initial chunk (`18` chars),
  /// allowing the `.task(id: markdown)` cadence loop to smoothly reveal the newly arrived range (`oldCount ..< newCount`).
  nonisolated internal static func characterCountOnChunkArrival(
    currentDisplayedCount: Int,
    oldCount: Int,
    newCount: Int,
    isStreaming: Bool,
    isStreamingCadenceEnabled: Bool = true,
    reduceMotion: Bool = false
  ) -> Int {
    guard isStreaming, isStreamingCadenceEnabled, !reduceMotion else {
      return newCount
    }
    if newCount < oldCount {
      return newCount
    } else {
      // Commit everything up to oldCount so we never fall behind incoming chunks,
      // and let the cadence task smoothly reveal the newly arrived characters (oldCount ..< newCount).
      return max(currentDisplayedCount, oldCount)
    }
  }

  /// Advances `currentDisplayedCount` by one cadence tick toward `targetCount`.
  nonisolated internal static func nextCadenceCharacterCount(
    currentDisplayedCount: Int,
    targetCount: Int
  ) -> Int {
    guard currentDisplayedCount < targetCount else {
      return targetCount
    }
    let remaining = targetCount - currentDisplayedCount
    let step = max(2, (remaining + 2) / 3)
    return min(targetCount, currentDisplayedCount + step)
  }
}

// MARK: - CommittedMarkdownBlockView (Equatable Memoized Subview)

/// Renders a committed `MarkdownBlock` and conforms to `Equatable` so SwiftUI skips
/// re-evaluating settled blocks during 120Hz token streaming (`AC-17`).
internal struct CommittedMarkdownBlockView: View, Equatable {
  let block: MarkdownBlock

  nonisolated static func == (lhs: CommittedMarkdownBlockView, rhs: CommittedMarkdownBlockView) -> Bool {
    lhs.block == rhs.block
  }

  var body: some View {
    MarkdownBlockContentView(
      block: block,
      isStreamingTail: false,
      revealProgress: 1.0,
      reduceMotion: true
    )
  }
}

// MARK: - TailMarkdownBlockView

private struct TailMarkdownBlockView: View {
  let block: MarkdownBlock
  let isStreaming: Bool
  let revealProgress: Double
  let reduceMotion: Bool

  var body: some View {
    MarkdownBlockContentView(
      block: block,
      isStreamingTail: isStreaming,
      revealProgress: revealProgress,
      reduceMotion: reduceMotion
    )
  }
}

// MARK: - MarkdownBlockContentView

private struct MarkdownBlockContentView: View {
  let block: MarkdownBlock
  let isStreamingTail: Bool
  let revealProgress: Double
  let reduceMotion: Bool

  var body: some View {
    switch block.kind {
    case .heading(let level, let text):
      headingView(level: level, text: text)

    case .paragraph(let text):
      proseTextView(text)

    case .codeBlock(let language, let code, _):
      // SHOULD-FIX-4: Bypass per-word TextRenderer fade on both committed and unclosed code blocks
      CodeBlockCardView(
        blockID: block.id,
        language: language,
        code: code
      )

    case .blockquote(let text):
      blockquoteView(text: text)

    case .list(let items, let isOrdered):
      listView(items: items, isOrdered: isOrdered)

    case .table(let headers, let rows):
      tableView(headers: headers, rows: rows)

    case .thematicBreak:
      Divider()
        .overlay(Color.platformSeparator.opacity(0.6))
        .padding(.vertical, 4)
    }
  }

  @ViewBuilder
  private func headingView(level: Int, text: String) -> some View {
    let font: Font = switch level {
    case 1:
      .title2.weight(.bold)
    case 2:
      .title3.weight(.semibold)
    case 3:
      .headline.weight(.semibold)
    default:
      .subheadline.weight(.semibold)
    }

    styledInlineText(text)
      .font(font)
      .foregroundStyle(.primary)
      .textSelection(.enabled)
      .fixedSize(horizontal: false, vertical: true)
      .padding(.top, level <= 2 ? 4 : 2)
  }

  @ViewBuilder
  private func proseTextView(_ rawText: String) -> some View {
    if isStreamingTail && !reduceMotion {
      styledInlineText(rawText)
        .font(.body)
        .foregroundStyle(.primary)
        .textRenderer(
          StreamingTailTextRenderer(
            trailingRevealProgress: revealProgress,
            showsCursor: true
          )
        )
        .fixedSize(horizontal: false, vertical: true)
    } else {
      styledInlineText(rawText)
        .font(.body)
        .foregroundStyle(.primary)
        .textSelection(.enabled)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  @ViewBuilder
  private func blockquoteView(text: String) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Capsule()
        .fill(Color.accentColor.opacity(0.65))
        .frame(width: 3)

      styledInlineText(text)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .textSelection(.enabled)
        .fixedSize(horizontal: false, vertical: true)
    }
    .fixedSize(horizontal: false, vertical: true)
    .padding(.vertical, 2)
    .padding(.leading, 2)
  }

  @ViewBuilder
  private func listView(items: [MarkdownBlock.ListItem], isOrdered: Bool) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(items.enumerated(), id: \.element.id) { idx, item in
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          if let isChecked = item.isChecked {
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
              .font(.subheadline)
              .foregroundStyle(isChecked ? Color.accentColor : Color.secondary)
          } else if isOrdered {
            Text("\(item.number ?? (idx + 1)).")
              .font(.body.monospacedDigit().weight(.medium))
              .foregroundStyle(.secondary)
              .frame(minWidth: 20, alignment: .trailing)
          } else {
            Text("•")
              .font(.body.weight(.bold))
              .foregroundStyle(.secondary)
              .frame(width: 12, alignment: .center)
          }

          let isLastItem = (idx == items.count - 1)
          if isStreamingTail && isLastItem && !reduceMotion {
            styledInlineText(item.text)
              .font(.body)
              .foregroundStyle(.primary)
              .textRenderer(
                StreamingTailTextRenderer(
                  trailingRevealProgress: revealProgress,
                  showsCursor: true
                )
              )
              .fixedSize(horizontal: false, vertical: true)
          } else {
            styledInlineText(item.text)
              .font(.body)
              .foregroundStyle(.primary)
              .textSelection(.enabled)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func tableView(headers: [String], rows: [[String]]) -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
        GridRow {
          ForEach(headers.enumerated(), id: \.offset) { _, header in
            styledInlineText(header)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.primary)
          }
        }

        Divider()
          .overlay(Color.platformSeparator.opacity(0.6))

        ForEach(rows.enumerated(), id: \.offset) { _, row in
          GridRow {
            ForEach(0..<headers.count, id: \.self) { colIndex in
              let cellText = colIndex < row.count ? row[colIndex] : ""
              styledInlineText(cellText)
                .font(.subheadline)
                .foregroundStyle(.primary)
            }
          }
        }
      }
      .padding(12)
    }
    .background(
      Color.platformSecondaryBackground,
      in: RoundedRectangle(cornerRadius: 12, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
    }
  }

  private func styledInlineText(_ raw: String) -> Text {
    let options = AttributedString.MarkdownParsingOptions(
      interpretedSyntax: .inlineOnlyPreservingWhitespace
    )
    if let attributed = try? AttributedString(markdown: raw, options: options) {
      return Text(attributed)
    }
    return Text(raw)
  }
}

// MARK: - CodeBlockCardView (`AC-17`, `SHOULD-FIX-4`)

/// Two-tone fenced code block card with monospaced language header and one-tap Copy button (`AC-17`).
private struct CodeBlockCardView: View {
  let blockID: String
  let language: String?
  let code: String

  @State private var didCopy: Bool = false

  private var displayLanguage: String {
    if let language, !language.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return language.lowercased()
    }
    return "code"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header bar
      HStack(alignment: .center, spacing: 8) {
        Text(displayLanguage)
          .font(.caption.monospaced().weight(.semibold))
          .foregroundStyle(.secondary)

        Spacer(minLength: 8)

        Button {
          PlatformPasteboard.copyText(code)
          PlatformHapticEvent.triggerHaptic(.copySuccess)
          didCopy = true
          Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            didCopy = false
          }
        } label: {
          HStack(spacing: 4) {
            Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
              .font(.caption2.weight(.semibold))
              .contentTransition(.symbolEffect(.replace))

            Text(didCopy ? "Copied" : "Copy")
              .font(.caption.weight(.medium))
          }
          .foregroundStyle(didCopy ? Color.green : Color.secondary)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(ConversationAccessibilityID.codeBlockCopyButton(blockID))
        .accessibilityLabel(didCopy ? "Copied code" : "Copy \(displayLanguage) code")
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 7)
      .background(Color.platformCodeBlockHeaderBackground)

      Divider()
        .overlay(Color.platformSeparator.opacity(0.45))

      // Monospaced code body (bypasses StreamingTailTextRenderer per SHOULD-FIX-4)
      ScrollView(.horizontal, showsIndicators: false) {
        Text(verbatim: code)
          .font(.callout.monospaced())
          .foregroundStyle(.primary)
          .textSelection(.enabled)
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .background(Color.platformCodeBlockBodyBackground)
    }
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
    }
  }
}

#Preview("StreamingMarkdownView") {
  ScrollView {
    StreamingMarkdownView(
      markdown: """
      # Incremental Block Streaming

      `StreamingMarkdownView` commits completed blocks so only the active tail block re-parses per token.

      - Zero UIKit/AppKit conditional import leakage
      - 120Hz ProMotion code block rendering
      - Safe [Apple Developer](https://developer.apple.com) link allowlisting

      ```swift
      struct ChatDemo: View {
        @State private var messages: [DefaultMessage] = []
        var body: some View {
          ConversationView(messages: $messages)
        }
      }
      ```
      """,
      isStreaming: false
    )
    .padding()
  }
}
