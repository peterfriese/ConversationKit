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

### With Initial Messages

```swift
@State private var messages: [DefaultMessage] = [
    .init(content: "Hello! How can I help you today?", participant: .other),
    .init(content: "I'm doing great, thanks!", participant: .user),
    .init(content: "That's wonderful to hear!", participant: .other)
]
```

## Core Components

### The `Message` protocol

The basic unit of conversation is the `Message` protocol. You can use your own types to represent messages, as long as they conform to this protocol.

```swift
public protocol Message: Identifiable, Hashable {
  var content: String? { get set }
  var imageURL: String? { get }
  var participant: Participant { get }
  var error: Error? { get }

  init(content: String?, imageURL: String?, participant: Participant)
}

public enum Participant {
    case other
    case user
}
```

ConversationKit provides a default implementation of this protocol, `DefaultMessage`.

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
    var message = DefaultMessage(content: "", participant: .other)
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
    var messages: [DefaultMessage] = []
    private let model: GenerativeModel
    private let chat: Chat
    
    init() {
        let firstMessage = DefaultMessage(
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
    
    func sendMessage(_ message: any Message) async {
        if let defaultMessage = message as? DefaultMessage {
          messages.append(defaultMessage)
        }
        if let content = message.content {
            var responseText: String
            do {
                let response = try await chat.sendMessage(content)
                responseText = response.text ?? ""
            } catch {
                responseText = "I'm sorry, I don't understand that. Please try again. \(error.localizedDescription)"
            }
            let response = DefaultMessage(content: responseText, participant: .other)
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
    @State private var messages: [DefaultMessage] = [
        .init(content: "Hello! How can I help you today?", participant: .other)
    ]
    let session = LanguageModelSession()
    
    var body: some View {
        NavigationStack {
            ConversationView(messages: $messages)
                .navigationTitle("AI Chat")
                .navigationBarTitleDisplayMode(.inline)
                .onSendMessage { message in
                    if let defaultMessage = message as? DefaultMessage {
                      messages.append(defaultMessage)
                    }
                    if let content = message.content {
                        var responseText: String
                        do {
                            let response = try await session.respond(to: content)
                            responseText = response.content
                        } catch {
                            responseText = "I'm sorry, I don't understand that. Please try again. \(error.localizedDescription)"
                        }
                        let response = DefaultMessage(content: responseText, participant: .other)
                        messages.append(response)
                    }
                }
        }
    }
}
```

## Error Handling

`ConversationKit` provides a robust mechanism for handling and displaying errors that may occur during asynchronous operations, such as fetching a response from an AI service.

### Attaching Errors to Messages

The `Message` protocol includes an optional `error` property. You can create a message with an associated error and display it in the conversation history. `MessageView` will automatically render a default error UI if a message contains an error.

```swift
.onSendMessage { userMessage in
    do {
        let response = try await chatService.sendMessage(userMessage.content ?? "")
        await MainActor.run {
            messages.append(DefaultMessage(content: response, participant: .other))
        }
    } catch {
        await MainActor.run {
            messages.append(DefaultMessage(
                content: "Sorry, an error occurred.",
                participant: .other,
                error: error
            ))
        }
    }
}
```

### Presenting Errors

To handle errors presented by `ConversationKit` views (for example, when a user taps the info button on a message with an error), use the `.onError(perform:)` view modifier. This modifier allows you to catch the error and present it using any standard SwiftUI presentation mechanism.

For convenience when using presentation modifiers like `.sheet(item:)`, `ConversationKit` provides an `ErrorWrapper` struct that makes any `Error` identifiable.

```swift
struct MyChatView: View {
    @State private var messages: [DefaultMessage] = []
    @State private var errorWrapper: ErrorWrapper?

    var body: some View {
        ConversationView(messages: $messages)
            .onSendMessage { message in
                // ... async logic that might throw an error
            }
            .onError { error in
                errorWrapper = ErrorWrapper(error: error)
            }
            .sheet(item: $errorWrapper) { wrapper in
                NavigationStack {
                    VStack {
                        Text("An Error Occurred")
                            .font(.headline)
                            .padding()
                        Text(wrapper.error.localizedDescription)
                        Spacer()
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Dismiss") {
                                errorWrapper = nil
                            }
                            .labelStyle(.titleOnly)
                        }
                    }
                }
            }
    }
}
```

## Message Types

### Text Messages

```swift
DefaultMessage(content: "Hello, how are you?", participant: .user)
```

### Image Messages

```swift
DefaultMessage(
    content: "Check out this image!",
    imageURL: "https://example.com/image.jpg",
    participant: .other
)
```

### Image-Only Messages

```swift
DefaultMessage(
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
- `presentErrorAction`: A closure to present an error to the user.

## License

ConversationKit is licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for more details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
