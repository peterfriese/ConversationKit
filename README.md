# ConversationKit

ConversationKit is a SwiftUI library that provides an elegant and easy-to-use chat interface for iOS applications. It offers a complete solution for building conversational UIs with support for text messages, images, markdown rendering, and seamless integration with AI services.

## Features

- 💬 **Ready-to-use chat interface** with built-in message bubbles
- 👤 **Multi-participant support** (user vs other)
- 🖼️ **Image message support** with async loading
- 📝 **Markdown rendering** for rich text messages
- ⚡️ **Async/await support** for message handling
- 🎨 **Customizable message rendering** with custom content closures
- 📱 **Modern iOS design** with glass effects (iOS 17+)
- 🔄 **Real-time message streaming** support
- 📎 **Attachment actions** with customizable menu
- 🎯 **Auto-scrolling** to latest messages
- ⌨️ **Keyboard-aware** input handling

## Requirements

- iOS 17.0+
- Swift 5.10+
- Xcode 15.0+

## Installation

Add ConversationKit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/peterfriese/ConversationKit", from: "1.0.0")
]
```

## Quick Start

### Basic Usage

```swift
import SwiftUI
import ConversationKit

struct ChatView: View {
    @State private var messages: [Message] = []
    
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
    
    func processMessage(_ message: Message) async {
        // Append the user's message to the messages array
        messages.append(message)
        // Simulate async response
        try? await Task.sleep(for: .seconds(1))
        await MainActor.run {
            messages.append(Message(
                content: "You said: \(message.content ?? "")",
                participant: .other
            ))
        }
    }
}
```

### With Initial Messages

```swift
@State private var messages: [Message] = [
    .init(content: "Hello! How can I help you today?", participant: .other),
    .init(content: "I'm doing great, thanks!", participant: .user),
    .init(content: "That's wonderful to hear!", participant: .other)
]
```

## Core Components

### Message

The basic unit of conversation:

```swift
public struct Message: Identifiable, Hashable {
    public let id: UUID = .init()
    public var content: String?
    public let imageURL: String?
    public let participant: Participant
}

public enum Participant {
    case other
    case user
}
```

### ConversationView

The main chat interface with two initializers:

1. **Built-in rendering** (default):
```swift
ConversationView(messages: $messages)
```

2. **Custom rendering**:
```swift
ConversationView(messages: $messages) { message in
    // Your custom message view
    CustomMessageView(message: message)
}
```

## Advanced Usage

### Custom Message Rendering

For complete control over message appearance:

```swift
ConversationView(messages: $messages) { message in
    VStack {
        // Handle images
        if let imageURL = message.imageURL {
            AsyncImage(url: URL(string: imageURL)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 200, maxHeight: 400)
                } else if phase.error != nil {
                    Image(systemName: "icloud.slash")
                } else {
                    ProgressView()
                }
            }
            .cornerRadius(8.0)
        }
        
        // Handle text content
        if let content = message.content {
            HStack {
                if message.participant == .user {
                    Spacer()
                }
                Markdown(content)
                    .padding()
                    .background {
                        Color(uiColor: message.participant == .other
                              ? .secondarySystemBackground
                              : .systemGray4)
                    }
                    .roundedCorner(10, corners: .allCorners)
                if message.participant == .other {
                    Spacer()
                }
            }
        }
    }
}
```

### Message Streaming

Support for real-time streaming responses:

```swift
func streamResponse() async {
    let responseText = "This is a streaming response that appears character by character."
    var message = Message(content: "", participant: .other)
    messages.append(message)
    
    for character in responseText {
        message.content?.append(character)
        messages[messages.count - 1] = message
        try? await Task.sleep(for: .milliseconds(100))
    }
}
```

### Attachment Actions

Add custom attachment functionality:

```swift
ConversationView(messages: $messages)
    .attachmentActions {
        Button(action: { /* handle photo selection */ }) {
            Label("Photos", systemImage: "photo.on.rectangle.angled")
        }
        Button(action: { /* handle camera */ }) {
            Label("Camera", systemImage: "camera")
        }
        Button(action: { /* handle documents */ }) {
            Label("Documents", systemImage: "doc")
        }
    }
```

### Disable Attachments

```swift
ConversationView(messages: $messages)
    .disableAttachments()
```

## AI Integration Examples

### Firebase AI Integration

```swift
import ConversationKit
import FirebaseAI

@Observable
class FirebaseAIChatViewModel {
    var messages: [Message] = []
    private let model: GenerativeModel
    private let chat: Chat
    
    init() {
        let firstMessage = Message(
            content: "Hello! How can I help you today?",
            participant: .other
        )
        self.messages = [firstMessage]
        
        model = FirebaseAI
            .firebaseAI(backend: .googleAI())
            .generativeModel(modelName: "gemini-2.5-flash")
        
        let history = [
            ModelContent(role: "model", parts: firstMessage.content ?? "")
        ]
        chat = model.startChat(history: history)
    }
    
    func sendMessage(_ message: Message) async {
        messages.append(message)
        if let content = message.content {
            var responseText: String
            do {
                let response = try await chat.sendMessage(content)
                responseText = response.text ?? ""
            } catch {
                responseText = "I'm sorry, I don't understand that. Please try again. \(error.localizedDescription)"
            }
            let response = Message(content: responseText, participant: .other)
            messages.append(response)
        }
    }
}

struct FirebaseAIChatView: View {
    @State private var viewModel = FirebaseAIChatViewModel()
    
    var body: some View {
        NavigationStack {
            ConversationView(messages: $viewModel.messages)
                .navigationTitle("AI Chat")
                .navigationBarTitleDisplayMode(.inline)
                .onSendMessage { message in
                    await viewModel.sendMessage(message)
                }
        }
    }
}
```

### Foundation Models Integration

```swift
import ConversationKit
import FoundationModels

struct FoundationModelChatView: View {
    @State private var messages: [Message] = [
        Message(content: "Hello! How can I help you today?", participant: .other)
    ]
    let session = LanguageModelSession()
    
    var body: some View {
        NavigationStack {
            ConversationView(messages: $messages)
                .navigationTitle("AI Chat")
                .navigationBarTitleDisplayMode(.inline)
                .onSendMessage { message in
                    messages.append(message)
                    if let content = message.content {
                        var responseText: String
                        do {
                            let response = try await session.respond(to: content)
                            responseText = response.content
                        } catch {
                            responseText = "I'm sorry, I don't understand that. Please try again. \(error.localizedDescription)"
                        }
                        let response = Message(content: responseText, participant: .other)
                        messages.append(response)
                    }
                }
        }
    }
}
```

## Error Handling

Since the `onSendMessage` action is async, you can handle errors naturally:

```swift
.onSendMessage { userMessage in
    do {
        let response = try await chatService.sendMessage(userMessage.content ?? "")
        await MainActor.run {
            messages.append(Message(content: response, participant: .other))
        }
    } catch {
        await MainActor.run {
            messages.append(Message(
                content: "Error: \(error.localizedDescription)",
                participant: .other
            ))
        }
    }
}
```

## Message Types

### Text Messages

```swift
Message(content: "Hello, how are you?", participant: .user)
```

### Image Messages

```swift
Message(
    content: "Check out this image!",
    imageURL: "https://example.com/image.jpg",
    participant: .other
)
```

### Image-Only Messages

```swift
Message(
    imageURL: "https://example.com/image.jpg",
    participant: .user
)
```

## Environment Values

ConversationKit provides several environment values for customization:

- `onSendMessageAction`: Async closure for handling sent messages
- `onSubmitAction`: Closure for handling message submission
- `disableAttachments`: Boolean to disable attachment functionality
- `attachmentActions`: Custom attachment menu actions

## License

ConversationKit is licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for more details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
