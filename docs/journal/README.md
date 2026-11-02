# 📓 Engineering Journal Index

Chronological log of daily engineering milestones, architectural decisions, and verification evidence for `ConversationKit`.

| Date | Milestone | Summary |
| :--- | :--- | :--- |
| [2026-11-02](./2026-11-02.md) | Liquid Glass Composer Refinement & Scroll Physics Stability | Refined three distinct composer styles (Classic, Card, Compact), implemented pure SwiftUI focus-breathing liquid melting (`spacing: isFocused ? 3 : 8`), eliminated the disappearing pill bug with anchored popovers, and stabilized second-turn scroll push and token streaming cadence, verified via FlowDeck on iPhone 17 Pro and 36/36 passing Swift tests. |
| [2026-11-01](./2026-11-01.md) | ConversationKit v2 Clean-Slate Rewrite (`v2` branch) | Completed the clean-slate rewrite of ConversationKit v2 targeting iOS 26+ and macOS 26+ with Swift 6.2 strict concurrency and zero external dependencies, verified via `swift test` (23/23 passing in 0.084s) and FlowDeck (`flowdeck`) iPhone 17 Pro UI tests (4/4 passing with $\Delta Y = 0.0\text{pt}$ top-bubble scroll stability). |
