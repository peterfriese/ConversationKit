# ConversationKit: ConversationView Rewrite PRD & Architecture

## 1. Introduction
This document outlines the Product Requirements and Technical Architecture for rewriting `ConversationKit`'s `ConversationView`. The objective is to closely mimic the scrolling, layout, and interaction paradigms of the Google Gemini iOS application while strictly preserving the existing public API.

## 2. Product Requirements Document (PRD)

### 2.1 Goals
*   **Gemini-like UX:** Implement a smooth, streaming-friendly chat interface with specific scrolling behaviors ("Sticky Top").
*   **Distinct Styling:** Provide strong default visual styles differentiating user inputs from AI responses, matching modern conversational UI standards.
*   **Progressive Disclosure:** Expose flexible, SwiftUI-canonical extension points for developers to inject custom views (actions, disclaimers, FABs) without cluttering the base API.
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

**2.2.2 Scrolling Behavior (The "Sticky Top" Paradigm)**
*   **Send Action:** 
    1.  Keyboard immediately dismisses.
    2.  `ScrollView` automatically scrolls so the *newly sent user message* is anchored to the **top** of the visible area.
*   **Streaming Content:** As the AI response streams in, it renders below the anchored user message. If the AI message grows longer than the screen height, it expands downward out of view. The view does *not* automatically chase the bottom of the text.
*   **Manual Override:** Any manual scrolling gesture by the user instantly breaks the top anchor, allowing free, user-directed scrolling.
*   **Subsequent Turns:** The next user message resets the behavior, anchoring the new message to the top.

**2.2.3 Auxiliary Views (Progressive Disclosure)**
*   **Message Actions:** AI messages must support an optional action bar beneath the text (e.g., Thumbs Up/Down, Regenerate, Copy).
*   **Disclaimer Text:** A customizable disclaimer must appear **only** beneath the most recent AI message in the thread.
*   **Scroll to Bottom FAB:** A small, customizable Floating Action Button appears in the bottom trailing corner when the user is scrolled away from the bottom. Tapping it jumps to the newest content.

---

## 3. Architecture & Design Document

### 3.1 Core Architecture Changes

The internal `body` of `ConversationView` will be restructured to support precise programmatic scrolling and state tracking.

**Components:**
1.  **`ScrollView` + `ScrollViewReader`:** Essential for programmatic anchoring.
2.  **Scroll State Tracking:** We must track whether the user is actively dragging. This prevents the view from snapping back to an anchor when the `messages` array updates during an active manual scroll. 
    *   *Implementation detail:* Depending on minimum iOS version targets, this involves `onScrollPhaseChange` (iOS 18+) or preference keys/geometry readers tracking scroll offset changes.
3.  **`MessageView` (Default Renderer):** Will be updated to handle the `UnevenRoundedRectangle` shape for `.user` and the loading indicator logic for `.other` when `content` is nil.

### 3.2 State & Data Flow (No API Breakage Loading Strategy)

To implement the loading indicator without breaking the `onSendMessageAction` signature:
*   The SDK relies on the developer to immediately append a placeholder `Message` (where `participant == .other` and `content == nil`) before starting the async network request.
*   `ConversationView` simply reacts to this state naturally.

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

**3.3.3 Scroll To Bottom Button Style**
To provide a canonical SwiftUI styling mechanism for the FAB:

```swift
public struct ScrollToBottomButtonConfiguration {
    public let action: () -> Void
}

public protocol ScrollToBottomButtonStyle {
    associatedtype Body: View
    @ViewBuilder func makeBody(configuration: ScrollToBottomButtonConfiguration) -> Body
}

public struct DefaultScrollToBottomButtonStyle: ScrollToBottomButtonStyle {
    public func makeBody(configuration: ScrollToBottomButtonConfiguration) -> some View {
        // Implementation of default circular FAB with downward arrow
    }
}

extension EnvironmentValues {
    @Entry var scrollToBottomButtonStyle: any ScrollToBottomButtonStyle = DefaultScrollToBottomButtonStyle()
}

public extension View {
    func scrollToBottomButtonStyle<S: ScrollToBottomButtonStyle>(_ style: S) -> some View {
        environment(\.scrollToBottomButtonStyle, style)
    }
}
```
*Usage within ConversationView:* Placed as an overlay over the `ScrollView`, visible only when scroll tracking indicates the user is not near the bottom.

## 4. Implementation Phasing
1.  **Foundation:** Implement new Environment Keys and Modifiers for Actions, Disclaimer, and FAB style.
2.  **Styling:** Update `MessageView` to implement the `UnevenRoundedRectangle` user bubble and the `nil` content loading state.
3.  **Scroll Architecture:** Refactor `ConversationView` to use `ScrollViewReader` and implement the scroll tracking logic.
4.  **Behavior:** Implement the "Sticky Top" anchor logic triggered upon message submission, respecting manual scroll overrides.
5.  **Integration:** Assemble the FAB, Action bars, and Disclaimer into the updated scroll view layout.
