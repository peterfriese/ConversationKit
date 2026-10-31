# Stratos Progressive Disclosure & SwiftUI Style Protocols

1. Design all public APIs Call-Site First following the 4-layer Stratos Progressive Disclosure model (Troposphere drop-in defaults -> Stratosphere view modifiers -> Mesosphere composable subviews -> Thermosphere custom Style & protocol conformances).
2. Implement SwiftUI's native `Style` + `StyleConfiguration` pattern (`MessageComposerStyle`, `ThinkingStateStyle`, `UserMessageBubbleStyle`) so layout and visual styling are decoupled from state and behavior.
3. Provide strongly-typed `.onSendMessage` overloads so developers never need to downcast `any Message`.
