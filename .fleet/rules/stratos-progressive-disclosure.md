# Rule: Stratos Progressive Disclosure (vNext API Evolution)

1. **Four-Layer API Scaling**:
   - **Troposphere (1-Line Default)**: `ConversationView(messages: $messages)` must always work out-of-the-box with sensible defaults.
   - **Stratosphere (Modifier Configuration)**: Expose view-level customizations (e.g., `.conversationStarters(...)`, `.thinkingStyle(...)`, `.toolCallPresentation(...)`, `.composerModes(...)`, `.messageActions(...)`, `.conversationDisclaimer(...)`) via `@Entry` on `EnvironmentValues` and public `View` modifiers.
   - **Mesosphere (Slot / ViewBuilder Injection)**: Allow custom SwiftUI `@ViewBuilder` closures for specific sub-surfaces (welcome header, thinking state, tool call rows, message bubbles, composer accessory bars).
   - **Thermosphere (Protocol & State Control)**: Expose full protocol conformance (`Message`, `Attachment`) with default protocol extensions so simple adopters only implement core fields while advanced agentic apps opt into `thinking`, `toolCalls`, `citations`, `plan`, and `approvalRequest`.
2. **No Boolean Traps**: Never add multiple boolean parameters to `ConversationView.init`. Use semantic enums, option sets, or dedicated view modifiers.
