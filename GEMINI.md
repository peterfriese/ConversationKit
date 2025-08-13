# Project Overview

This is a SwiftUI library called `ConversationKit` that provides a customizable chat interface for iOS applications. It supports text and image messages, Markdown rendering, and asynchronous message handling.

The library is structured as a Swift package and has a single dependency, `swift-markdown-ui`, for rendering Markdown in messages.

## Building and Running

To use `ConversationKit`, add it as a package dependency to your Xcode project:

```swift
dependencies: [
    .package(url: "https://github.com/peterfriese/ConversationKit", from: "1.0.0")
]
```

The project includes two example applications in the `Examples` directory:

*   `AIChatDemo`: Demonstrates how to integrate `ConversationKit` with AI services like Firebase AI and Foundation Models.
*   `ConversationKitDemo`: A simple example that shows the basic usage of the `ConversationView`.

To run the examples, open the corresponding `.xcodeproj` file in Xcode and run the app on the simulator or a physical device.

## Development Conventions

The codebase follows standard Swift conventions and is well-documented. Key conventions include:

*   **Public API:** The main entry point to the library is the `ConversationView`, which is highly customizable through view modifiers and custom rendering closures.
*   **Data Model:** The library uses a protocol-based approach for the message data model. The `Message` protocol defines the requirements for a message object, and a `DefaultMessage` struct is provided as a default implementation. This allows developers to use their own custom message types.
*   **Data Flow:** The `ConversationView` does not own the `messages` array. Instead, it receives a `Binding` to the array, and the parent view (or its view model) is responsible for creating and managing the array itself. When the user sends a message, the `ConversationView` calls the `onSendMessage` closure, and the parent view is responsible for appending the new message to the array. This ensures a clear and predictable data flow.
*   **Error Handling:** The `Message` protocol includes an optional `error` property, allowing errors to be attached to messages and displayed in the UI. A `presentErrorAction` is provided in the environment to allow for custom error presentation logic. For common use cases, a `.presentsErrorsInSheet()` view modifier is provided to simplify presenting errors in a sheet.
*   **Asynchronous Operations:** The library uses `async/await` for handling message sending and processing.
*   **Customization:** `ConversationKit` makes extensive use of SwiftUI's environment values and view modifiers to allow for deep customization of the chat interface.
*   **Testing:** The project has a dedicated test target, `ConversationKitTests`, for unit tests.