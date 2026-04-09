# ConversationKit: ConversationView Rewrite PRD & Architecture

## 1. Introduction
This document outlines the Product Requirements and Technical Architecture for rewriting `ConversationKit`'s `ConversationView`. The objective is to closely mimic the scrolling, layout, and interaction paradigms of the Google Gemini iOS application while strictly preserving the existing public API.

## 2. Product Requirements Document (PRD)

### 2.1 Goals
*   **Gemini-like UX:** Implement a smooth, streaming-friendly chat interface with specific scrolling behaviors ("Sticky Top").
*   **Distinct Styling:** Provide strong default visual styles differentiating user inputs from AI responses, matching modern conversational UI standards.
*   **Progressive Disclosure:** Expose flexible, SwiftUI-canonical extension points for developers to inject custom views (actions, disclaimers) without cluttering the base API.
*   **Zero API Breakage:** The core `ConversationView` initializers and environment modifiers (like `.onSendMessage`) must remain unchanged.

### 2.2 User Experience (UX) & Interactions

**2.2.1 Visual Layout & Styling**
*   **User Messages:** 
    *   Right-aligned.
    *   Contained within a background bubble.
    *   **Shape:** Rounded corners on all sides, with one corner (typically bottom-right) being *slightly less rounded* (a "tail" effect) to indicate the speaker.
*   **AI (Other) Messages:** 
    *   Left-aligned.
    *   No background bubble.
    *   Utilizes full markdown rendering natively.
*   **Custom Styling:** If a developer provides a custom `content` ViewBuilder closure to `ConversationView`, the default styling is bypassed entirely.
*   **Loading State:** If an AI message (`participant == .other`) is added to the model with `content == nil` (or empty), the UI must render a loading indicator (e.g., ProgressView/sparkle) at that message's location.

**2.2.2 Scrolling Behavior (The "Push and Pin" Paradigm)**
*   **Send Action:** 
    1.  Keyboard immediately dismisses.
    2.  `ScrollView` targets the *newly sent user message* with an `anchor: .top`. However, due to native SwiftUI content-clamping, if the chat is short, the message rests naturally at the bottom above the composer rather than artificially snapping to the absolute top of the screen.
*   **Streaming Content:** As the AI response streams in, it expands downward. The growing content naturally *pushes* the user's anchored message upwards.
*   **The Pin:** The exact moment the total height of the content exceeds the screen's height, SwiftUI's layout engine can finally satisfy the `anchor: .top` constraint. The user's message seamlessly pins to the top navigation bar, and the remaining AI response continues to grow out the bottom out of view.
*   **Manual Override:** Any manual scrolling gesture by the user instantly breaks the top anchor, allowing free, user-directed scrolling.
*   **Subsequent Turns:** The next user message resets the behavior, anchoring the new message with `.top`.

**2.2.3 Auxiliary Views (Progressive Disclosure)**
*   **Message Actions:** AI messages must support an optional action bar beneath the text (e.g., Thumbs Up/Down, Regenerate, Copy).
*   **Disclaimer Text:** A customizable disclaimer must appear **only** beneath the most recent AI message in the thread.

**2.2.4 Message Composer Experience**
*   **Empty State:** The "Send" button is visually disabled if the message input is empty. It relies strictly on native platform disabled styling (e.g., `.borderedProminent` on iOS) to ensure high-contrast readability without artificial opacity stacking.
*   **Generation State (Send/Stop):** When a user sends a message, the `ConversationView` must track the execution of the `onSendMessageAction` closure. While this closure is executing, the composer's "Send" button must transform into a "Stop" button (`stop.fill`). The stop icon utilizes specific, reduced font sizing to maintain visual mass balance against the default send arrow.
*   **Cancellation:** Tapping the Stop button calls `cancel()` on the executing `Task`. This implements a "Zero API Breakage" stop mechanism by relying entirely on standard Swift Cooperative Cancellation. Developers using the SDK must ensure their networking/streaming code checks `Task.isCancelled` to make the stop button effective.

---

## 3. Architecture & Design Document

### 3.1 Core Architecture Changes

The internal `body` of `ConversationView` will be restructured to support precise programmatic scrolling and state tracking.

**Components:**
1.  **`ScrollView` + `ScrollViewReader`:** Essential for programmatic anchoring.
2.  **Scroll State Tracking:** We must track whether the user is actively dragging. This prevents the view from snapping back to an anchor when the `messages` array updates during an active manual scroll. 
    *   *Implementation detail:* Depending on minimum iOS version targets, this involves `onScrollPhaseChange` (iOS 18+) or preference keys/geometry readers tracking scroll offset changes.
3.  **`MessageView` (Default Renderer):** Will be updated to handle the `UnevenRoundedRectangle` shape for `.user` and the loading indicator logic for `.other` when `content` is nil.

### 3.2 State & Data Flow (No API Breakage Strategy)

**The "Push and Pin" Anchor Strategy for Scroll Physics:**
*   To achieve perfect conversational AI scrolling physics when a user taps Send, the layout engine must invalidate in the exact same transaction as the keyboard dismissal.
*   The goal is to let the user's message appear near the bottom, be *pushed up* by the AI's generated response, and then permanently *pin to the top* of the screen once the response grows too long.
*   **Resolution:** `ConversationView` maintains a local `@State private var optimisticUserMessage`. When the user taps send, this local state is populated instantly. It tells the `ScrollView` to target this message with `anchor: .top`. 
*   **The "Happy Accident":** SwiftUI's layout clamping physically refuses to push short content to the top. So, the message naturally rests at the bottom. As the AI streams text, the total height grows, physically pushing the anchored message upwards until it hits the top edge, at which point SwiftUI finally satisfies the `.top` anchor constraint and locks it in place!
*   The actual developer array catches up asynchronously a millisecond later via `onSendMessageAction`, and `displayedMessages` deduplicates it seamlessly.

**Loading Indicator:**
*   The SDK relies on the developer to immediately append a placeholder `Message` (where `participant == .other` and `content == nil`) before starting the async network request.
*   `ConversationView` simply reacts to this state natively to render the loading dots.

**Send/Stop Button & Task Cancellation:**
*   `ConversationView` maintains a `@State private var sendingTask: Task<Void, Never>?`.
*   When a message is sent, the task is captured: `sendingTask = Task { await onSendMessageAction(...) }`.
*   An Environment value (`isGenerating`) is passed down to `MessageComposerView` based on whether `sendingTask` is non-nil.
*   The Stop button triggers `sendingTask?.cancel()`. Because cancellation is cooperative, the `onSendMessage` block must properly utilize `try Task.checkCancellation()` to halt the stream.

### 3.3 Progressive Disclosure API Design

We will introduce new SwiftUI `EnvironmentValues` and corresponding View Modifiers to enable the required customizability.

**3.3.1 Message Actions**
```swift
extension EnvironmentValues {
    @Entry var messageActions: ((any Message) -> AnyView)?
}

public extension View {
    func messageActions<V: View>(@ViewBuilder actions: @escaping (any Message) -> V) -> some View {
        environment(\.messageActions, { message in AnyView(actions(message)) })
    }
}
```
*Usage within ConversationView:* Evaluated inside the loop over `messages`, beneath the message content, specifically when `participant == .other`.

**3.3.2 Disclaimer View**
```swift
extension EnvironmentValues {
    @Entry var conversationDisclaimer: AnyView?
}

public extension View {
    func conversationDisclaimer<V: View>(@ViewBuilder disclaimer: @escaping () -> V) -> some View {
         environment(\.conversationDisclaimer, AnyView(disclaimer()))
    }
}
```
*Usage within ConversationView:* Rendered at the bottom of the `LazyVStack` only if `messages.last?.participant == .other`.

## 4. Implementation Phasing
1.  **Foundation:** Implement new Environment Keys and Modifiers for Actions and Disclaimer.
2.  **Styling:** Update `MessageView` to implement the `UnevenRoundedRectangle` user bubble and the `nil` content loading state.
3.  **Scroll Architecture:** Refactor `ConversationView` to use `ScrollViewReader` and implement the scroll tracking logic.
4.  **Behavior:** Implement the "Push and Pin" anchor logic triggered upon message submission, respecting manual scroll overrides.
5.  **Integration:** Assemble the Action bars and Disclaimer into the updated scroll view layout.
