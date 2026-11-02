# 💡 ConversationKit Engineering Learnings Index

A curated collection of deep architectural discoveries, SwiftUI layout physics analyses, concurrency patterns, and performance breakthroughs from building `ConversationKit`.

## Articles

| Date | Title | Summary |
| :--- | :--- | :--- |
| 2026-11-02 | [Liquid Glass Composer Styles, Focus Breathing Physics, and Popover Anchoring in ConversationKit v2](./2026-11-02-liquid-glass-composer-styles-and-breathing-physics.md) | How the three distinct composer styles (`Card Glass`, `Classic Glass`, `Compact Glass`) avoid the "permanent dog-bone" anti-pattern via pure SwiftUI focus breathing (`spacing: isFocused ? 3 : 8`), why UIKit `Menu` snapshotting vanishes Liquid Glass pills and how `.popover` + `.presentationCompactAdaptation(.popover)` stabilizes them, and how bottom-baseline alignment + continuous curvature insets prevent multiline button drift and corner clipping. |
| 2026-11-01 | [Top-Floating Turn Runway, `.safeAreaBar` Scroll Geometry, Accessibility Traversal, and 120Hz Streaming Markdown in ConversationKit v2](./2026-11-01-top-floating-turn-runway-and-liquid-glass.md) | How `ConversationTurn` + `activeTurnMinHeight` achieves $\Delta Y = 0.0\text{pt}$ top-floating scroll physics without per-token `scrollTo` calls, why `geo.visibleRect.maxY` already reflects `.safeAreaBar(edge: .bottom)` insets, how `.accessibilityElement(children: .contain)` preserves horizontal `ScrollView` button traversal, and how scalar-level `\u{200B}` stripping + incremental Markdown block commits sustain `0.84ms/step` at 120Hz. |
