# Rule: SwiftPieces-Grade Agentic UI & Micro-Interaction Physics

1. **Auto-Expand / Auto-Fold Lifecycle**:
   - `ThinkingStateView` and `ToolCallsGroupView` must open automatically while active (`.thinking` / `.running`) and fold smoothly into compact summary rows (e.g., `"Thought for 3.2s"`, `"Used 4 tools · 3.2s"`) once completed.
2. **Live Monospaced Timers**:
   - Elapsed durations for thinking states, tool execution, and long-running agent runs must use `TimelineView` paired with `.monospacedDigit()` to prevent horizontal layout jitter.
3. **Welcome & Prompt Chips Handoff**:
   - Starter chips and welcome cards must appear when `displayedMessages.isEmpty` and support smooth spring transitions when populating the composer or submitting immediately.
4. **Accessibility & Simulator Verification**:
   - Preserve and extend stable `.accessibilityIdentifier(...)` tags on all interactive controls so `ConversationKitDemoUITests`, FlowDeck, and RocketSim can inspect and automate every pattern state.
