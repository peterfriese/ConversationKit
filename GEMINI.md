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
*   **Architectural Patterns**: The component follows standard Swift and SwiftUI conventions. It uses a protocol-based approach for the message data model and makes extensive use of SwiftUI's environment values and view modifiers for customization.

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
