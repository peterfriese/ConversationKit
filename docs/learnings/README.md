# 💡 ConversationKit Engineering Learnings Index

A curated collection of deep architectural discoveries, SwiftUI layout physics analyses, concurrency patterns, and performance breakthroughs from building `ConversationKit`.

## Articles

| Date | Title | Summary |
| :--- | :--- | :--- |
| 2026-11-02 | [Canonical Liquid Glass Composer Architecture, Native `.interactive()` Touch-Down Breathing, and `.overlay` Menu Isolation in ConversationKit v2](./2026-11-02-liquid-glass-composer-styles-and-breathing-physics.md) | Why native `.glassEffect(.regular.interactive())` inside static `GlassEffectContainer(spacing: 12)` and `HStack(spacing: 8)` beats dynamic focus-spacing hacks (`isFocused ? 3 : 8`), why placing a SwiftUI `Menu` inside an `.interactive()` glass subtree caused `UIContextMenuInteraction` to lift the entire vessel and how the refined `Sofia`-style `ComposerMenuSlotAnchorKey: PreferenceKey` + `.overlayPreferenceValue` pattern (alongside `PlatformPasteboard.hasAttachments`) solves it with zero duplicate `HStack`s and zero `Color.clear` dummy spacers, and how the 3-zone bookend sibling grammar (`Sofia` pattern) + explicit square frames (`in: .circle`) + gradient-free `.safeAreaBar(edge: .bottom)` achieve true iOS 26 / macOS 26 Liquid Glass fidelity. |
| 2026-11-01 | [Top-Floating Turn Runway, `.safeAreaBar` Scroll Geometry, Accessibility Traversal, and 120Hz Streaming Markdown in ConversationKit v2](./2026-11-01-top-floating-turn-runway-and-liquid-glass.md) | How `ConversationTurn` + `activeTurnMinHeight` achieves $\Delta Y = 0.0\text{pt}$ top-floating scroll physics without per-token `scrollTo` calls, why `geo.visibleRect.maxY` already reflects `.safeAreaBar(edge: .bottom)` insets, how `.accessibilityElement(children: .contain)` preserves horizontal `ScrollView` button traversal, and how scalar-level `\u{200B}` stripping + incremental Markdown block commits sustain `0.84ms/step` at 120Hz. |
