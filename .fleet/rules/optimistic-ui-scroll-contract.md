# Rule: Optimistic UI & "Push and Pin" Scroll Physics Contract

1. **Synchronous Optimistic Insertion**: When the user submits a message, `optimisticUserMessage` must be set synchronously in the same transaction as keyboard dismissal so `.scrollPosition` / `ScrollViewReader` can anchor the new user message with `anchor: .top`.
2. **ID-Preserving Deduplication**: `displayedMessages` deduplicates `optimisticUserMessage` against `messages` by comparing `Message.ID`. Any new message block (thinking, tool calls, citations, streaming chunks) must preserve stable `ConversationScrollID.message(message.id)` identity so expanding/collapsing disclosures never break the scroll anchor.
3. **Cooperative Cancellation**: While `onSendMessageAction` executes (`sendingTask != nil`), the composer's Send button must transform into a Stop button that invokes `sendingTask?.cancel()`.
