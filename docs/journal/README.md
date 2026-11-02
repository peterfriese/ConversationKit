# 📓 Engineering Journal Index

Chronological log of daily engineering milestones, architectural decisions, and verification evidence for `ConversationKit`.

| Date | Milestone | Summary |
| :--- | :--- | :--- |
| [2026-11-02](./2026-11-02.md) | Canonical 3-Zone Liquid Glass Composer, Refactoring Steps 1–3 (`F-01`, `F-05`–`F-07`, `F-09`), Multi-Turn Top-Anchor Runway Fix & `v2.0.0-alpha.4` | Established the canonical `Sofia` 3-zone bookend composer, replaced twin hit-target passes with `ComposerMenuSlotAnchorKey` (`F-01`) and lightweight pasteboard checks (`F-09`), removed single-child `GlassEffectContainer` wrappers (`F-05`), fixed the `+84pt` Turn-2 top-anchor slide-down (`ScrollGeometry.containerSize.height` double-inset subtraction + blockquote `.fixedSize`) and timeline layout (`F-06`/`F-07`), added varied demo replies with contextual follow-up chips, and verified `v2.0.0-alpha.4` via `swift test` (39/39), `flowdeck test` (6/6), and deployment to `Peter iPhone 17 Pro`. |
| [2026-11-01](./2026-11-01.md) | ConversationKit v2 Clean-Slate Rewrite (`v2` branch) | Completed the clean-slate rewrite of ConversationKit v2 targeting iOS 26+ and macOS 26+ with Swift 6.2 strict concurrency and zero external dependencies, verified via `swift test` (23/23 passing in 0.084s) and FlowDeck (`flowdeck`) iPhone 17 Pro UI tests (4/4 passing with $\Delta Y = 0.0\text{pt}$ top-bubble scroll stability). |
