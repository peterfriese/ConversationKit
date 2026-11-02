//
//  ComposerModels.swift
//  ConversationKit
//
//  Structured prompting models, model/capability selectors, suggestion chips, and
//  the zero-width sentinel ComposerTextBuffer state machine.
//

import Foundation

// MARK: - ComposerModelOption

/// Represents an AI model choice displayed in the composer's integrated Model Selector menu (`F-9`).
///
/// ### Usage
/// ```swift
/// let sonnet = ComposerModelOption(
///   id: "claude-sonnet-4-6",
///   name: "Claude Sonnet 4.6",
///   subtitle: "Fast & balanced reasoning",
///   badge: "Default",
///   symbolName: "sparkles"
/// )
/// ```
public struct ComposerModelOption: Identifiable, Hashable, Sendable, Codable {
  /// Unique model identifier (e.g., `"claude-sonnet-4-6"`).
  public let id: String
  /// Display name of the model.
  public var name: String
  /// Optional secondary description shown in the picker menu.
  public var subtitle: String?
  /// Optional short badge label (e.g., `"Pro"`, `"Fast"`).
  public var badge: String?
  /// Optional SF Symbol name displayed alongside the model name.
  public var symbolName: String?
  /// Optional grouping category for submenus in the model selector (e.g., `"Anthropic"`, `"OpenAI"`).
  public let category: String?

  /// Non-optional SF Symbol name (defaults to `"sparkles"` when `symbolName` is `nil`).
  public var systemImage: String {
    get { symbolName ?? "sparkles" }
    set { symbolName = newValue }
  }

  /// Creates a `ComposerModelOption` using `name` and optional `symbolName`.
  public init(
    id: String,
    name: String,
    subtitle: String? = nil,
    badge: String? = nil,
    symbolName: String? = "sparkles",
    category: String? = nil
  ) {
    self.id = id
    self.name = name
    self.subtitle = subtitle
    self.badge = badge
    self.symbolName = symbolName
    self.category = category
  }
}

// MARK: - ComposerCapability

/// Represents a toggleable capability pill inside the composer (e.g., `.think`, `.search`, `.image`).
///
/// ### Usage
/// ```swift
/// let capabilities: [ComposerCapability] = [
///   .think,
///   .search,
///   .image,
///   .custom(id: "code-interpreter", title: "Code", symbolName: "terminal")
/// ]
/// ```
public enum ComposerCapability: Identifiable, Hashable, Sendable, Codable {
  /// Extended chain-of-thought reasoning toggle (`"Think"`).
  case think
  /// Web search grounding toggle (`"Search"`).
  case search
  /// Image generation toggle (`"Image"`).
  case image
  /// Custom domain-specific capability toggle.
  case custom(id: String, title: String, symbolName: String)

  /// Stable capability identifier.
  public var id: String {
    switch self {
    case .think:
      return "think"
    case .search:
      return "search"
    case .image:
      return "image"
    case .custom(let id, _, _):
      return id
    }
  }

  /// Localized or display title shown in the capability pill.
  public var title: String {
    switch self {
    case .think:
      return "Think"
    case .search:
      return "Search"
    case .image:
      return "Image"
    case .custom(_, let title, _):
      return title
    }
  }

  /// SF Symbol name representing the capability.
  public var symbolName: String {
    switch self {
    case .think:
      return "brain"
    case .search:
      return "globe"
    case .image:
      return "photo.badge.plus"
    case .custom(_, _, let symbolName):
      return symbolName
    }
  }
}

// MARK: - SlashCommand

/// Defines a `/` slash command entry displayed in `ComposerPopupView` (`F-5`).
///
/// `SlashCommand` automatically normalizes `trigger` by stripping any leading `/` characters
/// and trimming surrounding whitespace so `"summarize"` and `"/summarize"` behave identically.
public struct SlashCommand: Identifiable, Hashable, Sendable, Codable {
  /// Stable unique identifier.
  public let id: String

  /// Normalized command trigger without a leading `/` (e.g., `"summarize"`).
  public var trigger: String {
    didSet {
      let normalized = Self.normalizeTrigger(trigger)
      if trigger != normalized {
        trigger = normalized
      }
    }
  }

  /// Human-readable command title.
  public var title: String

  /// Optional explanation of what the command does.
  public var description: String?

  /// Optional SF Symbol name displayed in the autocomplete row and token chip.
  public var symbolName: String?

  /// Optional grouping category in the autocomplete popup.
  public var category: String?

  /// Trigger prefixed with `"/"` (e.g., `"/summarize"`).
  public var formattedTrigger: String {
    "/\(trigger)"
  }

  /// Non-optional SF Symbol name (defaults to `"command"`).
  public var systemImage: String {
    get { symbolName ?? "command" }
    set { symbolName = newValue }
  }

  /// Creates a `SlashCommand` with automatic leading-`/` normalization.
  public init(
    id: String? = nil,
    trigger: String,
    title: String? = nil,
    description: String? = nil,
    symbolName: String? = "command",
    category: String? = nil
  ) {
    let normalized = Self.normalizeTrigger(trigger)
    self.id = id ?? (normalized.isEmpty ? UUID().uuidString : normalized)
    self.trigger = normalized
    self.title = title ?? normalized
    self.description = description
    self.symbolName = symbolName
    self.category = category
  }

  /// Strips leading `/` characters and surrounding whitespace from a raw trigger string.
  public static func normalizeTrigger(_ rawTrigger: String) -> String {
    var trimmed = rawTrigger.trimmingCharacters(in: .whitespacesAndNewlines)
    while trimmed.hasPrefix("/") {
      trimmed.removeFirst()
    }
    return trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

// MARK: - ResourceMention

/// Defines an `@` resource mention entry displayed in `ComposerPopupView` (`F-5`).
///
/// `ResourceMention` automatically normalizes `queryHandle` by stripping any leading `@` characters.
public struct ResourceMention: Identifiable, Hashable, Sendable, Codable {

  /// Semantic category of a mentioned resource.
  public enum Kind: Sendable, Hashable, Codable {
    case file
    case document
    case person
    case agent
    case web
    case custom(String)

    /// Default SF Symbol name for this resource kind.
    public var defaultSymbolName: String {
      switch self {
      case .file:
        return "doc"
      case .document:
        return "doc.text"
      case .person:
        return "person"
      case .agent:
        return "cpu"
      case .web:
        return "globe"
      case .custom:
        return "at"
      }
    }

    /// Display label for this resource kind.
    public var displayName: String {
      switch self {
      case .file:
        return "File"
      case .document:
        return "Document"
      case .person:
        return "Person"
      case .agent:
        return "Agent"
      case .web:
        return "Web"
      case .custom(let label):
        return label
      }
    }
  }

  /// Stable unique identifier.
  public let id: String

  /// Normalized query handle without a leading `@` (e.g., `"PRD-0001"`).
  public var queryHandle: String {
    didSet {
      let normalized = Self.normalizeHandle(queryHandle)
      if queryHandle != normalized {
        queryHandle = normalized
      }
    }
  }

  /// Human-readable display title.
  public var title: String

  /// Optional secondary subtitle (e.g., file path or role).
  public var subtitle: String?

  /// SF Symbol name representing this resource.
  public var symbolName: String

  /// Semantic category of this resource.
  public var kind: Kind

  /// Optional category string derived from `kind`.
  public var category: String? {
    kind.displayName
  }

  /// Formatted handle prefixed with `"@"` (e.g., `"@PRD-0001"`).
  public var formattedHandle: String {
    "@\(queryHandle)"
  }

  /// Creates a `ResourceMention` with automatic leading-`@` normalization.
  public init(
    id: String? = nil,
    queryHandle: String,
    title: String? = nil,
    subtitle: String? = nil,
    symbolName: String? = nil,
    kind: Kind = .document
  ) {
    let normalized = Self.normalizeHandle(queryHandle)
    self.id = id ?? (normalized.isEmpty ? UUID().uuidString : normalized)
    self.queryHandle = normalized
    self.title = title ?? normalized
    self.subtitle = subtitle
    self.kind = kind
    self.symbolName = symbolName ?? kind.defaultSymbolName
  }

  /// Strips leading `@` characters and surrounding whitespace from a raw handle string.
  public static func normalizeHandle(_ rawHandle: String) -> String {
    var trimmed = rawHandle.trimmingCharacters(in: .whitespacesAndNewlines)
    while trimmed.hasPrefix("@") {
      trimmed.removeFirst()
    }
    return trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

/// Asynchronous search provider closure for dynamic `@mention` resolution with cooperative cancellation.
public typealias ResourceMentionProvider = @Sendable (String) async throws -> [ResourceMention]

// MARK: - ComposerToken

/// A structured token pill inserted into `MessageComposerView` when a `/` command or `@` mention is chosen (`F-5`).
public struct ComposerToken: Identifiable, Hashable, Sendable, Codable {

  /// Discriminates between slash command tokens and resource mention tokens.
  public enum Kind: Sendable, Hashable, Codable {
    case command(SlashCommand)
    case mention(ResourceMention)
  }

  /// Stable unique identifier for the token instance.
  public let id: String

  /// Underlying command or mention payload.
  public var kind: Kind

  /// Formatted label displayed inside the token pill (e.g., `"/summarize"` or `"@PRD-0001"`).
  public var displayText: String

  /// SF Symbol name displayed inside the token pill.
  public var symbolName: String

  /// Extracts the underlying `SlashCommand` when `kind` is `.command`, otherwise `nil`.
  public var command: SlashCommand? {
    if case .command(let cmd) = kind {
      return cmd
    }
    return nil
  }

  /// Extracts the underlying `ResourceMention` when `kind` is `.mention`, otherwise `nil`.
  public var mention: ResourceMention? {
    if case .mention(let item) = kind {
      return item
    }
    return nil
  }

  /// Creates a `ComposerToken` from a `Kind` and optional display overrides.
  public init(
    id: String? = nil,
    kind: Kind,
    displayText: String? = nil,
    symbolName: String? = nil
  ) {
    switch kind {
    case .command(let cmd):
      self.id = id ?? "cmd-\(cmd.id)"
      self.kind = kind
      self.displayText = displayText ?? "/\(cmd.trigger)"
      self.symbolName = symbolName ?? cmd.symbolName ?? "command"
    case .mention(let mention):
      self.id = id ?? "mention-\(mention.id)"
      self.kind = kind
      self.displayText = displayText ?? "@\(mention.title)"
      self.symbolName = symbolName ?? mention.symbolName
    }
  }

  /// Creates a `ComposerToken` wrapping a `SlashCommand`.
  public static func command(
    id: String? = nil,
    _ command: SlashCommand
  ) -> ComposerToken {
    ComposerToken(id: id, kind: .command(command))
  }

  /// Creates a `ComposerToken` wrapping a `ResourceMention`.
  public static func mention(
    id: String? = nil,
    _ mention: ResourceMention
  ) -> ComposerToken {
    ComposerToken(id: id, kind: .mention(mention))
  }
}

// MARK: - PromptHandoffBehavior & PromptSuggestion

/// Determines how tapping a first-turn `PromptSuggestion` chip interacts with the composer (`F-8`).
public enum PromptHandoffBehavior: String, Sendable, Hashable, Codable, CaseIterable {
  /// Immediately constructs and submits the user message in a single tap.
  case immediateSend
  /// Populates the composer text field and focuses `@FocusState` for user editing.
  case populateComposer
}

/// A first-turn suggestion chip rendered in `SuggestionChipsBar` above the composer (`F-8`).
public struct PromptSuggestion: Identifiable, Hashable, Sendable, Codable {
  /// Stable unique identifier.
  public let id: String
  /// Short label displayed inside the suggestion capsule.
  public var title: String
  /// Full prompt text submitted or populated when the chip is tapped.
  public var prompt: String
  /// Optional SF Symbol name displayed at the leading edge of the chip.
  public var symbolName: String?
  /// Optional category or subtitle label.
  public var category: String?
  /// Optional handoff behavior override (defaults to `.immediateSend` if not overridden by environment).
  public var behavior: PromptHandoffBehavior

  /// Creates a `PromptSuggestion` chip.
  public init(
    id: String = UUID().uuidString,
    title: String,
    prompt: String? = nil,
    symbolName: String? = nil,
    category: String? = nil,
    behavior: PromptHandoffBehavior = .immediateSend
  ) {
    self.id = id
    self.title = title
    self.prompt = prompt ?? title
    self.symbolName = symbolName
    self.category = category
    self.behavior = behavior
  }
}

// MARK: - ComposerTextBuffer (`[MF-5]`)

/// Pure value-type state machine managing the `\u{200B}` zero-width space sentinel (`[MF-5]`),
/// two-stage backspace token highlight-then-remove (`AC-9`), active `/` command and `@` mention
/// word-boundary trigger detection (`AC-8`), and matched-substring range calculation for popup highlighting.
///
/// ### Why the `\u{200B}` Sentinel Exists
/// Standard iOS software keyboards do not emit a text-change event when the user taps Backspace inside
/// an already-empty `TextField`. Whenever `!tokens.isEmpty`, `ComposerTextBuffer` maintains a leading
/// `\u{200B}` sentinel in `rawText` so that pressing Backspace on a visually empty draft transitions
/// `rawText` from `"\u{200B}"` to `""`.
/// - **First Backspace on empty `cleanText`:** Restores `"\u{200B}"` and highlights the trailing token (`highlightedTokenID`).
/// - **Second Consecutive Backspace:** Pops the highlighted trailing token from `tokens` and clears `highlightedTokenID`.
/// - **Global Sentinel Stripping (`[MF-5]`):** `cleanText` strips **all** occurrences of `\u{200B}` anywhere in the string,
///   protecting against mid-string cursor movement or pasted text.
public struct ComposerTextBuffer: Sendable, Hashable {

  /// The invisible zero-width space string (`"\u{200B}"`) used as a backspace-detection sentinel.
  public static let sentinel: String = "\u{200B}"

  /// Identifies whether an active autocomplete trigger is a `/` command or `@` mention.
  public enum TriggerKind: String, Sendable, Hashable, Codable {
    case slashCommand
    case resourceMention
  }

  /// Represents an active word-boundary `/` command or `@` mention query inside `cleanText`.
  public enum TriggerMatch: Sendable, Equatable {
    /// An active `/command` trigger with its query string (without `/`) and its full range in `cleanText` (including `/`).
    case slashCommand(query: String, range: Range<String.Index>)
    /// An active `@mention` trigger with its query string (without `@`) and its full range in `cleanText` (including `@`).
    case resourceMention(query: String, range: Range<String.Index>)

    /// The search query text after the leading `/` or `@`.
    public var query: String {
      switch self {
      case .slashCommand(let query, _), .resourceMention(let query, _):
        return query
      }
    }

    /// The range of the entire trigger token (including `/` or `@`) within `cleanText`.
    public var range: Range<String.Index> {
      switch self {
      case .slashCommand(_, let range), .resourceMention(_, let range):
        return range
      }
    }

    /// The semantic kind of this trigger match.
    public var kind: TriggerKind {
      switch self {
      case .slashCommand:
        return .slashCommand
      case .resourceMention:
        return .resourceMention
      }
    }
  }

  /// Outcome of processing a text edit or backspace event against structured `ComposerToken` pills.
  public enum BackspaceAction: Sendable, Hashable {
    /// Normal text edit; no token highlight or removal occurred.
    case none
    /// First backspace on visually empty input: the trailing token with this ID was highlighted.
    case highlightToken(String)
    /// Second consecutive backspace: the highlighted token with this ID was removed.
    case removeToken(String)
  }

  /// A segment of candidate text used by `ComposerPopupView` to highlight matched query substrings.
  public struct HighlightSegment: Sendable, Hashable {
    public let text: String
    public let isMatched: Bool

    public init(text: String, isMatched: Bool) {
      self.text = text
      self.isMatched = isMatched
    }
  }

  // MARK: - Stored State

  /// The raw string bound to the underlying `TextField` (includes the leading `\u{200B}` sentinel when `hasTokens` is `true`).
  public private(set) var rawText: String

  /// The identifier of the trailing `ComposerToken` currently highlighted for deletion on the next backspace, if any.
  public var highlightedTokenID: String?

  /// Whether structured tokens are currently present in the composer.
  public private(set) var hasTokens: Bool

  // MARK: - Computed Properties

  /// The user-visible draft text with **all** occurrences of `\u{200B}` globally stripped (`[MF-5]`).
  public var cleanText: String {
    Self.cleanText(rawText)
  }

  /// Returns `true` when `cleanText` contains no visible characters after trimming whitespace and newlines.
  public var isVisuallyEmpty: Bool {
    cleanText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  /// Detects an active word-boundary `/` slash command or `@` resource mention trigger in `cleanText`.
  public var activeTrigger: TriggerMatch? {
    Self.detectTrigger(in: cleanText)
  }

  // MARK: - Initializer

  /// Creates a `ComposerTextBuffer` with optional initial text and token presence state.
  public init(
    text: String = "",
    hasTokens: Bool = false,
    highlightedTokenID: String? = nil
  ) {
    let cleaned = Self.cleanText(text)
    self.hasTokens = hasTokens
    self.highlightedTokenID = hasTokens ? highlightedTokenID : nil
    self.rawText = Self.bindingText(for: cleaned, hasTokens: hasTokens)
  }

  // MARK: - Sentinel & Clean Text Helpers (`[MF-5]`)

  /// Strips all occurrences of `\u{200B}` from `text` globally at the Unicode scalar level (`[MF-5]`).
  @inlinable
  public static func cleanText(_ text: String) -> String {
    guard text.unicodeScalars.contains("\u{200B}") else { return text }
    var scalars = String.UnicodeScalarView()
    scalars.reserveCapacity(text.unicodeScalars.count)
    for scalar in text.unicodeScalars where scalar != "\u{200B}" {
      scalars.append(scalar)
    }
    return String(scalars)
  }

  /// Produces the `TextField`-bound representation for a clean string, prefixing `\u{200B}` if `hasTokens` is `true`.
  public static func bindingText(for cleanText: String, hasTokens: Bool) -> String {
    let cleaned = Self.cleanText(cleanText)
    return hasTokens ? (Self.sentinel + cleaned) : cleaned
  }

  /// Synchronizes the buffer's `hasTokens` state when tokens are externally added or removed.
  public mutating func syncTokens(_ tokens: [ComposerToken]) {
    let cleaned = cleanText
    hasTokens = !tokens.isEmpty
    if let highlightedTokenID, !tokens.contains(where: { $0.id == highlightedTokenID }) {
      self.highlightedTokenID = nil
    }
    rawText = Self.bindingText(for: cleaned, hasTokens: hasTokens)
  }

  /// Replaces the user-visible text and updates `rawText` while preserving the sentinel invariant.
  public mutating func setText(_ newText: String, hasTokens: Bool? = nil) {
    if let hasTokens {
      self.hasTokens = hasTokens
    }
    let cleaned = Self.cleanText(newText)
    if !cleaned.isEmpty {
      highlightedTokenID = nil
    }
    if !self.hasTokens {
      highlightedTokenID = nil
    }
    rawText = Self.bindingText(for: cleaned, hasTokens: self.hasTokens)
  }

  // MARK: - Two-Stage Backspace State Machine (`AC-9`, `[MF-5]`)

  /// Processes a raw text change emitted by `TextField` and mutates `tokens` on second consecutive backspace when empty.
  ///
  /// - Parameters:
  ///   - newRawText: The new string value received from the `TextField` binding.
  ///   - tokens: The active array of `ComposerToken` pills, mutated in place if the second backspace removes the last token.
  /// - Returns: The `BackspaceAction` that occurred (`.none`, `.highlightToken`, or `.removeToken`).
  @discardableResult
  public mutating func applyEdit(
    _ newRawText: String,
    tokens: inout [ComposerToken]
  ) -> BackspaceAction {
    let previousCleaned = cleanText
    let newCleaned = Self.cleanText(newRawText)
    let hadSentinel = rawText.unicodeScalars.contains("\u{200B}")
    let hasSentinelNow = newRawText.unicodeScalars.contains("\u{200B}")

    // Detect sentinel deletion when clean text was already empty and tokens exist
    if !tokens.isEmpty && previousCleaned.isEmpty && newCleaned.isEmpty && hadSentinel && !hasSentinelNow {
      return performBackspaceOnEmpty(tokens: &tokens)
    }

    // Normal character typing, pasting, or deleting visible characters
    hasTokens = !tokens.isEmpty
    if newCleaned != previousCleaned || !newCleaned.isEmpty {
      highlightedTokenID = nil
    }
    rawText = Self.bindingText(for: newCleaned, hasTokens: hasTokens)
    return .none
  }

  /// Explicitly performs a single backspace step when the visible text buffer is empty.
  ///
  /// - Stage 1: If the trailing token is not yet highlighted, sets `highlightedTokenID = tokens.last?.id` and keeps the token.
  /// - Stage 2: If `highlightedTokenID == tokens.last?.id`, removes the trailing token and clears `highlightedTokenID`.
  @discardableResult
  public mutating func performBackspaceOnEmpty(
    tokens: inout [ComposerToken]
  ) -> BackspaceAction {
    guard cleanText.isEmpty, let lastToken = tokens.last else {
      hasTokens = !tokens.isEmpty
      rawText = Self.bindingText(for: cleanText, hasTokens: hasTokens)
      return .none
    }

    if highlightedTokenID == lastToken.id {
      let removed = tokens.removeLast()
      highlightedTokenID = nil
      hasTokens = !tokens.isEmpty
      rawText = Self.bindingText(for: "", hasTokens: hasTokens)
      return .removeToken(removed.id)
    } else {
      highlightedTokenID = lastToken.id
      hasTokens = true
      rawText = Self.bindingText(for: "", hasTokens: true)
      return .highlightToken(lastToken.id)
    }
  }

  // MARK: - Word-Boundary Trigger Detection (`AC-8`)

  /// Detects an active `/` slash command or `@` resource mention trigger at a word boundary in `text`.
  ///
  /// A trigger is valid only when `/` or `@` appears at the start of the string or immediately after
  /// whitespace/newline, and the query between the trigger character and `cursorIndex` contains no whitespace.
  /// Mid-word occurrences (such as `"user@example.com"` or `"path/to/file"`) are ignored.
  ///
  /// - Parameters:
  ///   - text: Input string (any `\u{200B}` characters are stripped before inspection).
  ///   - cursorIndex: Optional cursor position within `cleanText` (defaults to `cleanText.endIndex`).
  /// - Returns: A `TriggerMatch` (`.slashCommand` or `.resourceMention`), or `nil` if no valid trigger is active.
  public static func detectTrigger(
    in text: String,
    cursorIndex: String.Index? = nil
  ) -> TriggerMatch? {
    let cleaned = Self.cleanText(text)
    guard !cleaned.isEmpty else { return nil }

    let effectiveEnd = Self.resolveCleanCursorIndex(cursorIndex, in: text, cleaned: cleaned)
    guard effectiveEnd > cleaned.startIndex else { return nil }

    // Scan backward from effectiveEnd to the beginning of the current whitespace-delimited word
    var wordStart = effectiveEnd
    while wordStart > cleaned.startIndex {
      let previousIndex = cleaned.index(before: wordStart)
      let ch = cleaned[previousIndex]
      if ch.isWhitespace || ch.isNewline {
        break
      }
      wordStart = previousIndex
    }

    guard wordStart < effectiveEnd else { return nil }

    // Word boundary check: wordStart is either startIndex or preceded by whitespace/newline
    let triggerChar = cleaned[wordStart]
    let queryStart = cleaned.index(after: wordStart)
    let query = String(cleaned[queryStart..<effectiveEnd])

    switch triggerChar {
    case "/":
      // Reject paths or double-slashes like "//comment" or "/usr/local"
      guard !query.contains("/") else { return nil }
      return .slashCommand(query: query, range: wordStart..<effectiveEnd)

    case "@":
      // Reject multiple '@' symbols in the same token
      guard !query.contains("@") else { return nil }
      return .resourceMention(query: query, range: wordStart..<effectiveEnd)

    default:
      return nil
    }
  }

  /// Safely maps an optional `cursorIndex` (from either `rawText` or `cleaned`) to a valid
  /// `Character`-aligned `String.Index` within `cleaned`.
  private static func resolveCleanCursorIndex(
    _ cursorIndex: String.Index?,
    in rawText: String,
    cleaned: String
  ) -> String.Index {
    guard let cursorIndex else { return cleaned.endIndex }
    if cursorIndex <= rawText.startIndex {
      return cleaned.startIndex
    }
    if !rawText.unicodeScalars.contains("\u{200B}") {
      if cursorIndex >= cleaned.endIndex {
        return cleaned.endIndex
      }
      var aligned = cleaned.startIndex
      for idx in cleaned.indices {
        if idx <= cursorIndex {
          aligned = idx
        } else {
          break
        }
      }
      let nextIdx = cleaned.index(after: aligned)
      if nextIdx <= cursorIndex {
        return nextIdx
      }
      return aligned
    }

    if cursorIndex >= rawText.endIndex {
      return cleaned.endIndex
    }
    var safeRawEnd = rawText.startIndex
    for idx in rawText.unicodeScalars.indices {
      if idx <= cursorIndex {
        safeRawEnd = idx
      } else {
        break
      }
    }
    let nextScalarIdx = rawText.unicodeScalars.index(after: safeRawEnd)
    if nextScalarIdx <= cursorIndex {
      safeRawEnd = nextScalarIdx
    }
    let cleanPrefix = Self.cleanText(String(rawText[..<safeRawEnd]))
    return cleaned.index(
      cleaned.startIndex,
      offsetBy: cleanPrefix.count,
      limitedBy: cleaned.endIndex
    ) ?? cleaned.endIndex
  }

  /// Removes the currently active `/command` or `@mention` trigger range from `cleanText`
  /// (typically called when the user selects an autocomplete item to insert a `ComposerToken`).
  public mutating func consumeActiveTrigger(hasTokens: Bool = true) {
    let currentClean = cleanText
    guard let match = Self.detectTrigger(in: currentClean) else {
      self.hasTokens = hasTokens
      self.rawText = Self.bindingText(for: currentClean, hasTokens: hasTokens)
      return
    }
    var updated = currentClean
    updated.removeSubrange(match.range)
    // Trim a single leftover trailing space if the trigger was at the start and followed by space
    if updated.first == " " && match.range.lowerBound == currentClean.startIndex {
      updated.removeFirst()
    }
    self.hasTokens = hasTokens
    self.highlightedTokenID = nil
    self.rawText = Self.bindingText(for: updated, hasTokens: hasTokens)
  }

  // MARK: - Popup Substring Highlighting (`AC-8`)

  /// Computes the case- and diacritic-insensitive range of `query` inside `candidate` for autocomplete popup highlighting.
  ///
  /// - Parameters:
  ///   - query: The active search query typed after `/` or `@`.
  ///   - candidate: The candidate command trigger, title, or mention handle.
  /// - Returns: The matched `Range<String.Index>` inside `candidate`, or `nil` if `query` is empty or does not match.
  public static func matchedRange(
    of query: String,
    in candidate: String
  ) -> Range<String.Index>? {
    let trimmedQuery = Self.cleanText(query).trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedQuery.isEmpty, !candidate.isEmpty else { return nil }
    return candidate.range(
      of: trimmedQuery,
      options: [.caseInsensitive, .diacriticInsensitive]
    )
  }

  /// Splits `candidate` into ordered `HighlightSegment` runs so `ComposerPopupView` can render
  /// matched query characters in `.semibold` primary tint.
  public static func highlightSegments(
    in candidate: String,
    matching query: String
  ) -> [HighlightSegment] {
    guard !candidate.isEmpty else { return [] }
    guard let range = matchedRange(of: query, in: candidate) else {
      return [HighlightSegment(text: candidate, isMatched: false)]
    }

    var segments: [HighlightSegment] = []
    if range.lowerBound > candidate.startIndex {
      segments.append(
        HighlightSegment(
          text: String(candidate[candidate.startIndex..<range.lowerBound]),
          isMatched: false
        )
      )
    }
    segments.append(
      HighlightSegment(
        text: String(candidate[range]),
        isMatched: true
      )
    )
    if range.upperBound < candidate.endIndex {
      segments.append(
        HighlightSegment(
          text: String(candidate[range.upperBound..<candidate.endIndex]),
          isMatched: false
        )
      )
    }
    return segments
  }
}
