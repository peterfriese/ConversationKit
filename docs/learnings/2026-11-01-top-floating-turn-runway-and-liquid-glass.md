# 💡 Learnings: Top-Floating Turn Runway, `.safeAreaBar` Scroll Geometry, Accessibility Traversal, and 120Hz Streaming Markdown in ConversationKit v2

**Author**: Learnings Agent & ConversationKit v2 Engineering Team  
**Date**: 2026-11-01  
**Tags**: `SwiftUI`, `LiquidGlass`, `ScrollGeometry`, `Accessibility`, `Markdown`, `Unicode`, `iOS26`, `macOS26`  

---

## Summary

While re-architecting `ConversationKit` v2 for iOS 26+ and macOS 26+ (Tahoe) with native Liquid Glass chrome, we uncovered and solved four subtle SwiftUI layout, accessibility, and text-processing challenges. Grouping messages into `ConversationTurn` units with an unoccluded viewport runway (`activeTurnMinHeight`) allowed `proxy.scrollTo(newTurnID, anchor: .top)` to float a new user message to the top on frame 0 with zero per-token `scrollTo` calls during AI streaming ($\Delta Y = 0.0\text{pt}$). Along the way, we proved why `ScrollGeometry.visibleRect.maxY` already accounts for `.safeAreaBar(edge: .bottom)` insets, resolved a critical horizontal `ScrollView` accessibility flattening bug, and engineered a scalar-level `\u{200B}` sentinel and block-committed Markdown parser sustaining `0.84ms/step` across 220-block streams.

---

## The Problem / Challenge (`## The Problem or Puzzle`)

### 1. Content Clamping vs. Top-Floating Turn Physics
In a naive vertical `ScrollView` + `LazyVStack`, calling `proxy.scrollTo(userMessageID, anchor: .top)` when the user sends a message fails to place the message at the top of the screen because `ScrollView` clamps its maximum scroll offset to `contentSize.height - visibleRect.height`. If there is no scrollable content below the newly submitted user message yet, the message rests near the bottom above the composer. Worse, calling `scrollTo` on every streaming AI token causes continuous layout invalidation and micro-jitter, and if the software keyboard is open when the user taps **Send**, `geo.visibleRect.height` is transiently compressed by the keyboard height (~336pt).

### 2. Double-Counting `.safeAreaBar(edge: .bottom)` Insets in `ScrollToBottomButton`
`ConversationView` hosts its Liquid Glass composer inside `.safeAreaBar(edge: .bottom)` and overlays a floating `ScrollToBottomButton` controlled by a hysteresis state machine (`> 80pt` to show, `< 24pt` to hide). An initial temptation when computing `distanceFromBottom` inside `.onScrollGeometryChange` is to subtract `geo.contentInsets.bottom` from `geo.contentSize.height - geo.visibleRect.maxY`—which breaks the hysteresis deadband by under-reporting or zeroing out the true scroll distance.

### 3. Horizontal `ScrollView` Accessibility Flattening in VoiceOver & FlowDeck
Horizontal scrolling bars (`SuggestionChipsBar`, `ComposerTokensBar`, `ComposerCapabilitiesBar`) wrap interactive `Button` pills inside a `ScrollView(.horizontal)`. Attaching `.accessibilityLabel(...)` directly to the outer `ScrollView` after `.accessibilityIdentifier(...)` caused iOS accessibility automation (`FlowDeck` / VoiceOver) to treat the entire `ScrollView` as a single leaf element, hiding all child chip buttons (`composer.suggestion.<id>`, `composer.token.remove.<id>`) from the accessibility tree.

### 4. Grapheme Cluster Leaks with `\u{200B}` & $O(N^2)$ Streaming Markdown Re-Parsing
To detect Backspace inside an already-empty SwiftUI `TextField` (for two-stage highlight-then-delete of structured `/command` and `@mention` pills), `ComposerTextBuffer` injects a leading zero-width space sentinel (`\u{200B}`). However, filtering at the Swift `Character` (extended grapheme cluster) level fails when a user pastes or types combining diacritical marks (e.g., `\u{0301}`) or ZWJ emoji sequences adjacent to `\u{200B}`, because Swift merges `\u{200B}` + `\u{0301}` into a single composite `Character` that is no longer equal to `Character("\u{200B}")`. Simultaneously, re-parsing an entire growing Markdown document with `AttributedString(markdown:)` on every token causes $O(N^2)$ CPU spikes that blow past the `8.33ms` 120Hz ProMotion frame budget.

---

## Root Cause & Discovery (`## The Discovery`)

### 1. Why `activeTurnMinHeight` Unlocks Zero-Jitter Streaming ($\Delta Y = 0.0\text{pt}$)
- **Turn-Scoped Runway:** By partitioning `displayedMessages` into `ConversationTurn<MessageType>` (`userMessage` + `assistantMessages`) and applying `.frame(minHeight: activeTurnMinHeight, alignment: .top)` **exclusively** to the active (last) turn container, the scroll content immediately possesses enough bottom runway on frame 0 for `proxy.scrollTo(newTurnID, anchor: .top)` to position the user's bubble at the top of the viewport.
- **Unoccluded Height Locking:** While the software keyboard is dismissed on submission, `geo.visibleRect.height` transitions from its keyboard-compressed value back to the full unoccluded viewport height. By tracking `lockedUnoccludedHeight = max(lockedUnoccludedHeight, geo.visibleRect.height)` and clamping `activeTurnMinHeight = max(lockedUnoccludedHeight, 480)`, the active turn runway never shrinks during keyboard dismissal.
- **Zero Per-Token `scrollTo` Calls:** Because the user's prompt is already pinned at the top of the active turn container (`alignment: .top`), streaming tokens simply fill the pre-allocated vertical space downward and then naturally overflow below the fold—requiring **zero** `scrollTo` invocations during token streaming and guaranteeing $\Delta Y = 0.0\text{pt}$ on the user bubble even when the AI response exceeds `150%` of the viewport height.

### 2. Why `geo.visibleRect.maxY` Already Accounts for `.safeAreaBar(edge: .bottom)`
In SwiftUI's `ScrollGeometry` coordinate space:
- `geo.visibleRect` represents the currently visible portion of the scroll content rect inside the safe-area-inset viewport.
- When `.safeAreaBar(edge: .bottom)` insets the bottom of the `ScrollView`, SwiftUI reduces `geo.visibleRect.height` (and therefore `geo.visibleRect.maxY`) by the exact height of the bottom bar.
- When scrolled all the way to the bottom anchor, `geo.visibleRect.maxY == geo.contentSize.height`, making `geo.contentSize.height - geo.visibleRect.maxY == 0`. Subtracting `geo.contentInsets.bottom` again double-counts the safe area bar inset.

### 3. Why `.accessibilityElement(children: .contain)` Must Precede `.accessibilityIdentifier(...)`
SwiftUI modifiers wrap views from the inside out. On a `ScrollView`, applying `.accessibilityElement(children: .contain)` first establishes an accessibility container node that preserves child traversal, and applying `.accessibilityIdentifier(...)` immediately afterward stamps the container identifier onto that node. Adding `.accessibilityLabel(...)` onto the container without `.contain` promotes the container into a synthesized single accessibility element, masking its descendant buttons from `FlowDeck` and VoiceOver.

### 4. Why Unicode Scalar Filtering and Block-Level Commit Boundaries Are Essential
- **Scalar-Level Sentinel Stripping:** In Unicode, `U+200B` (`ZERO WIDTH SPACE`) is a single scalar (`Unicode.Scalar`), whereas Swift's `Character` models an extended grapheme cluster (UAX #29). Filtering `text.unicodeScalars` where `scalar != "\u{200B}"` strips every sentinel scalar even when fused with combining marks (`\u{200B}\u{0301}`) or pasted mid-string.
- **Block-Level Markdown Commits:** During LLM streaming, all completed paragraphs, headings, lists, blockquotes, tables, and closed fenced code blocks above the final active block are immutable. Splitting `MarkdownBlock.parse(_:isStreaming:)` into `(committed: [MarkdownBlock], tail: MarkdownBlock?)` and wrapping each committed block in `CommittedMarkdownBlockView` (`Equatable`) means SwiftUI skips diffing and `AttributedString` parsing for all settled blocks, only re-evaluating the single `tail` block. Furthermore, unclosed `.codeBlock` blocks bypass `StreamingTailTextRenderer`'s per-slice glyph opacity ramp, sustaining `0.84ms/step` across a 220-block stream (`< 8.33ms` 120Hz budget).

---

## The Idiomatic Solution & Code Examples (`## Solution & Architecture Pattern`)

### 1. Top-Floating Turn Runway & Single-Shot Submission Scroll

```swift
// ❌ BEFORE: Flat message list + per-token scrollTo(.bottom)
// Causes content clamping on frame 0 and continuous scroll jitter during streaming.
LazyVStack {
  ForEach(messages) { message in
    MessageView(message: message)
      .id(message.id)
  }
}
.onChange(of: messages.last?.content) {
  proxy.scrollTo(messages.last?.id, anchor: .bottom) // Jitters on every token!
}

// ✅ AFTER: Turn-scoped unoccluded runway + single-shot top scroll (ConversationView.swift)
private var activeTurnMinHeight: CGFloat {
  max(lockedUnoccludedHeight, 480)
}

@ViewBuilder
private func turnContainerView(
  for turn: ConversationTurn<MessageType>,
  isLastTurn: Bool
) -> some View {
  let turnStack = VStack(alignment: .leading, spacing: 16) {
    if let userMessage = turn.userMessage {
      content(userMessage)
    }
    ForEach(turn.assistantMessages) { assistantMessage in
      content(assistantMessage)
    }
  }
  .frame(maxWidth: .infinity, alignment: .topLeading)

  if isLastTurn {
    turnStack
      .frame(minHeight: activeTurnMinHeight, alignment: .top)
  } else {
    turnStack
  }
}

// Inside submitTurn(...): called ONCE on user submission, NEVER during token streaming
withAnimation(
  reduceMotion
    ? .easeOut(duration: 0.15)
    : .spring(duration: 0.38, bounce: 0.0)
) {
  proxy.scrollTo(newTurnID, anchor: .top)
}
```

### 2. Accurate `ScrollGeometry` Distance Calculation with `.safeAreaBar(edge: .bottom)`

```swift
// ❌ BEFORE: Double-counting .safeAreaBar bottom insets
let wrongDistance = geo.contentSize.height - geo.visibleRect.maxY - geo.contentInsets.bottom

// ✅ AFTER: geo.visibleRect.maxY already reflects the unoccluded safe-area viewport (ConversationView.swift)
.onScrollGeometryChange(for: ScrollGeometrySnapshot.self) { geo in
  let unoccludedCandidate = max(0, geo.visibleRect.height)
  let distanceFromBottom = max(0, geo.contentSize.height - geo.visibleRect.maxY)
  return ScrollGeometrySnapshot(
    unoccludedCandidateHeight: unoccludedCandidate,
    distanceFromBottom: distanceFromBottom
  )
} action: { _, snapshot in
  if snapshot.unoccludedCandidateHeight > lockedUnoccludedHeight {
    lockedUnoccludedHeight = snapshot.unoccludedCandidateHeight
  }

  let nextShowState = ScrollToBottomButton.shouldShow(
    currentState: isScrolledAwayFromBottom,
    distanceFromBottom: snapshot.distanceFromBottom // >80pt show, <24pt hide
  )
  if nextShowState != isScrolledAwayFromBottom {
    withAnimation(reduceMotion ? nil : .snappy(duration: 0.22)) {
      isScrolledAwayFromBottom = nextShowState
    }
  }
}
```

### 3. Preserving Child Accessibility Traversal in Horizontal `ScrollView` Bars

```swift
// ❌ BEFORE: Overriding container accessibility label flattens child buttons
ScrollView(.horizontal, showsIndicators: false) {
  HStack {
    ForEach(suggestions) { suggestion in
      chipButton(for: suggestion)
    }
  }
}
.accessibilityIdentifier("composer.suggestionChipsBar")
.accessibilityLabel("Prompt suggestions") // Collapses children into one leaf element!

// ✅ AFTER: .accessibilityElement(children: .contain) before .accessibilityIdentifier (SuggestionChipsBar.swift)
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
```

### 4. Unicode Scalar `\u{200B}` Stripping & Incremental Markdown Block Commits

```swift
// ❌ BEFORE: Character-level filtering leaks \u{200B} when combined with \u{0301} or ZWJ sequences
public static func brokenCleanText(_ text: String) -> String {
  String(text.filter { $0 != "\u{200B}" })
}

// ✅ AFTER: UnicodeScalarView filtering strips \u{200B} inside any grapheme cluster (ComposerModels.swift)
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
```

```swift
// ✅ Incremental Committed + Tail Markdown Rendering (StreamingMarkdownView.swift)
public var body: some View {
  let parsed = MarkdownBlock.parse(effectiveMarkdown, isStreaming: isStreaming)

  VStack(alignment: .leading, spacing: 12) {
    ForEach(parsed.committed) { block in
      CommittedMarkdownBlockView(block: block)
        .equatable() // Skips re-parsing & layout for all settled blocks
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
}
```

---

## Key Takeaways (`## Takeaways for the Team`)

- **Reserve Turn Runway, Never Spam `scrollTo` During Streaming:** Group conversation timelines into `ConversationTurn` units and apply `.frame(minHeight: max(lockedUnoccludedHeight, 480), alignment: .top)` only to the active turn. A single `proxy.scrollTo(newTurnID, anchor: .top)` on user submission floats the user bubble to the top on frame 0 and keeps $\Delta Y = 0.0\text{pt}$ throughout streaming without per-token scroll calls.
- **Lock Unoccluded Viewport Height Across Keyboard Transitions:** Monotonically capture the maximum `geo.visibleRect.height` in `.onScrollGeometryChange` so submitting a prompt while the software keyboard is open never shrinks the active turn's minimum runway height.
- **Trust `geo.visibleRect.maxY` with `.safeAreaBar(edge: .bottom)`:** `geo.contentSize.height - geo.visibleRect.maxY` already accounts for safe area bars; never subtract `geo.contentInsets.bottom` a second time when driving scroll-to-bottom hysteresis (`> 80pt` show, `< 24pt` hide).
- **Order Accessibility Modifiers Deliberately on `ScrollView`:** Always place `.accessibilityElement(children: .contain)` immediately before `.accessibilityIdentifier(...)` and omit container-level `.accessibilityLabel(...)` on horizontal chip/token scroll views so VoiceOver and UI automation can inspect and tap individual child buttons.
- **Manipulate Invisible Sentinels at the `UnicodeScalarView` Layer:** When using `\u{200B}` to detect Backspace on an empty `TextField`, strip sentinels via `text.unicodeScalars` rather than `Character` iteration so combining marks (`\u{0301}`) and ZWJ emoji clusters cannot trap the sentinel.
- **Freeze Completed Markdown Blocks Behind `Equatable` Views:** Partition streaming Markdown into `committed` blocks (`CommittedMarkdownBlockView: Equatable`) and a single `tail` block, and bypass `TextRenderer` glyph fades on unclosed fenced `.codeBlock` blocks to stay well under the `8.33ms` 120Hz ProMotion frame budget (`0.84ms/step` at 220 blocks).
