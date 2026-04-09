# Component: ConversationKit

## Component Overview

This component is the core of the `ConversationKit` library. It provides a customizable chat interface for iOS applications, built with SwiftUI. It's a native iOS component designed to be easily integrated into any SwiftUI application. The primary technology stack is Swift and SwiftUI.

## Key Files and Structure

The component is organized into two main directories: `Model` and `Views`.

*   **`Model/Message.swift`**: Defines the data model for the chat interface. It includes the `Message` protocol and a default implementation, `DefaultMessage`. This protocol-based approach allows developers to use their own custom message types.
*   **`Views/ConversationView.swift`**: This is the main entry point to the library. It's a SwiftUI view that displays the conversation thread and the message composer. It's highly customizable through view modifiers and custom rendering closures.
*   **`Views/MessageComposerView.swift`**: This view provides the text input field, the send button, and the attachment menu.
*   **`Views/MessageView.swift`**: This is the default view for rendering a single message.
*   **`Views/ErrorWrapper.swift`**, **`Views/OnErrorModifier.swift`**, and **`Views/PresentErrorAction.swift`**: These files provide a robust error handling mechanism.
*   **`Views/Utilities.swift`**: Contains utility extensions and views.

## Dependencies and Relationships

This component has one external dependency:

*   **`swift-markdown-ui`**: Used for rendering Markdown in messages.

It doesn't have any internal dependencies on other components within this project.

## Technical Details

*   **Building and Running**: To use this component, add it as a package dependency to your Xcode project.
*   **Testing**: The project has a dedicated test target, `ConversationKitTests`, for unit tests.
*   **Architectural Patterns**: The component follows standard Swift and SwiftUI conventions. It uses a protocol-based approach for the message data model and makes extensive use of SwiftUI's environment values and view modifiers for customization, adopting a Progressive Disclosure API design for advanced styling like `.messageActions` and `.conversationDisclaimer`.

## SwiftUI Scroll Physics & Concurrency

`ConversationKit` implements a highly specialized, native scrolling UX matching modern conversational AI interfaces. When the user sends a message, it doesn't violently snap to the top. Instead, it rests comfortably above the text input field. As the AI begins generating its response directly below, the new text smoothly *pushes* the user's message upward until it hits the top navigation bar, at which point it securely *pins* in place, allowing the rest of the generated response to flow downwards off the screen.

To achieve this "Push and Pin" behavior entirely within SwiftUI's native declarative layout engine (without fragile `GeometryReader` clutches), we explicitly tell `.scrollPosition` to target the user's message with `anchor: .top`.
**The "Happy Accident":** By default, SwiftUI physically refuses to push short content lists all the way to the top of a ScrollView. So, the `.top` anchor gracefully fails, leaving the short message at the bottom. As the AI response adds tokens and the content height finally exceeds the screen frame, SwiftUI is finally able to satisfy the `.top` anchor constraint, natively pinning the user's message exactly where it should be!

**Concurrency Optimization (Optimistic UI)**
To make this work fluidly, the layout engine must process the new user message in the exact same render transaction as the keyboard dismissal. Because the SDK intentionally *does not own* the messages array, relying on developers to asynchronously append their messages inside the `async` `onSendMessage` closure caused a 1-frame layout micro-delay that completely broke the `.top` physics.

The SDK resolves this conflict via an **Optimistic UI anchor strategy**:
1. `ConversationView` instantly captures the sent message into a local `@State` variable (`optimisticUserMessage`).
2. A computed property (`displayedMessages`) merges this local message with the developer's array, forcing a synchronous layout update that sets up the `.top` target exactly as the keyboard vanishes.
3. A background `@MainActor` `Task` is spawned, yielding execution to allow the layout engine to render the scroll animation, preventing UI deadlocks while the developer performs their async array updates or network calls.
4. As the developer appends the actual message, `displayedMessages` natively deduplicates it against the optimistic copy, resulting in flawless scroll physics while strictly maintaining the "SDK does not own the array" architectural rule.

> **Important API Contract Note:** The deduplication logic in step 4 relies explicitly on the `id` of the user's message. When the developer's `.onSendMessage` closure executes, they *must* append the exact `message` instance provided by the closure, or map it into a new model using the identical `message.id`. If they map the text into a completely new object with a randomly generated UUID, the deduplication engine will fail to recognize them as the same message, causing the message to briefly appear twice on screen before the optimistic placeholder expires.

## Usage and Integration

The main way to use this component is by embedding the `ConversationView` in a SwiftUI view hierarchy. The `ConversationView` takes a `Binding` to an array of `Message` objects and an `onSendMessage` closure to handle user input.

Here's a basic usage example:

```swift
import SwiftUI
import ConversationKit

struct ChatView: View {
    @State private var messages: [DefaultMessage] = []

    var body: some View {
        NavigationStack {
            ConversationView(messages: $messages)
                .onSendMessage { userMessage in
                    // Handle the sent message asynchronously
                    await processMessage(userMessage)
                }
                .navigationTitle("Chat")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    func processMessage(_ message: any Message) async {
        // Append the user's message to the messages array
        if let defaultMessage = message as? DefaultMessage {
          messages.append(defaultMessage)
        }
        // Simulate async response
        try? await Task.sleep(for: .seconds(1))
        await MainActor.run {
            messages.append(DefaultMessage(
                content: "You said: \(message.content ?? "")",
                participant: .other
            ))
        }
    }
}
```

## Important Notes

*   The `ConversationView` does not own the `messages` array. The parent view is responsible for creating and managing the array.
*   The library uses `async/await` for handling message sending and processing.
*   The `Message` protocol includes an optional `error` property, allowing errors to be attached to messages and displayed in the UI.
*   **Loading Indicators:** To display a loading state, simply append an AI (`.other`) message with a `nil` or empty `content`. `ConversationView` natively renders a loading view for this state without API breakage.
*   **Generation State (Send/Stop):** The composer's "Send" button will be disabled if the text field is empty. When `onSendMessage` executes, the "Send" button transforms into a "Stop" button. Tapping it calls `Task.cancel()` on the executing task. End-developers must rely on Swift's cooperative cancellation by checking `try Task.checkCancellation()` within any streaming loops to make the stop button functional.
