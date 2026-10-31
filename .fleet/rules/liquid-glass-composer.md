# Native iOS 26+ Liquid Glass & Composer Chrome

1. Target iOS 26+ and macOS 26+ natively using `GlassEffectContainer`, `.glassEffect(.regular.interactive(), in: ...)`, `.buttonStyle(.glass)` / `.buttonStyle(.glassProminent)`, `.buttonBorderShape(...)`, and `.safeAreaBar(edge: .bottom)`.
2. Never apply Liquid Glass inside scrolling `ScrollView` timeline cells; apply Liquid Glass exclusively to floating/pinned chrome (composer, first-turn suggestion chips, `/` and `@` autocomplete popup, and floating scroll-to-bottom button).
3. When the composer text field has focus (`@FocusState`), display a circular Liquid Glass keyboard-dismiss button (`keyboard.chevron.compact.down`) at the trailing edge of the input row inside the `GlassEffectContainer`.
4. Show suggestion chips on top of the input box only before the first user message is sent; once the first message is sent, animate them out cleanly.
