# ConversationKit

ConversationKit is a Swift package that provides an elegant and easy-to-use chat interface for iOS applications built with SwiftUI.

## Features

- 💬 Ready-to-use chat interface
- 👤 Support for multiple participants in conversations
- ⚡️ Real-time message streaming support
- 🎨 SwiftUI-native implementation
- 🔄 Async/await support for message handling

## Installation

Add ConversationKit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/peterfriese/ConversationKit", from: "1.0.0")
]
```

## Quick Start

1. Import ConversationKit in your SwiftUI view:

```swift
import SwiftUI
import ConversationKit
```

2. Create a view with a conversation:

```swift
struct ChatView: View {
    @State private var messages: [Message] = []
    
    var body: some View {
        ConversationView(messages: $messages)
            .onSendMessage { userMessage in
                // Handle the sent message
            }
    }
}
```

## Core Components

### Message

The basic unit of conversation that includes:
- Content: The text of the message
- Participant: The sender of the message (user or other)

### ConversationView

A SwiftUI view that handles the display and interaction of messages. Features include:
- Message list display
- Built-in send message functionality
- Support for streaming responses

## Example Usage

Here's a complete example showing how to implement a basic chat interface:

```swift
import SwiftUI
import ConversationKit

struct ContentView: View {
    @State var messages: [Message] = []
    
    var body: some View {
        NavigationStack {
            ConversationView(messages: $messages)
                .onSendMessage { userMessage in
                    Task {
                        // Handle the message
                        await generateResponse(for: userMessage)
                    }
                }
                .navigationTitle("Chat")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func generateResponse(for message: Message) async {
        // Implement your response generation logic here
    }
}
```

## Message Streaming

ConversationKit supports streaming responses, allowing for a more dynamic chat experience. You can update message content incrementally:

```swift
func streamResponse() async {
    var message = Message(content: "", participant: .other)
    messages.append(message)
    
    // Stream content updates
    for chunk in responseChunks {
        message.content += chunk
        messages[messages.count - 1] = message
        try? await Task.sleep(nanoseconds: 100_000_000) // Adjust timing as needed
    }
}
```

## License

ConversationKit is licensed under the Apache License, Version 2.0. See the LICENSE file for more details.

## Requirements

- iOS 15.0+
- Swift 5.5+
