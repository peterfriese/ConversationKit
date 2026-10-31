# Top-Floating Turn Scroll Physics & Non-Pushing AI Responses

1. When the user sends a message, the new user message immediately floats to the top of the screen (`anchor: .top`) via optimistic UI state in the same render transaction as keyboard dismissal.
2. The AI's response renders directly on the background below the user's message bubble.
3. If the AI's response grows longer than the screen height, it flows downward off the bottom edge and MUST NOT push the user's message up off the top of the screen.
4. Track scroll geometry via `.onScrollGeometryChange` with hysteresis (>80pt to show, <24pt to hide) to display the floating Liquid Glass scroll-to-bottom button whenever the user is not at the bottom of the chat.
