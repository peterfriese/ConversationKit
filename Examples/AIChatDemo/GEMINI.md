# Component: AIChatDemo

## Component Overview

This component is an example application that demonstrates how to integrate `ConversationKit` with AI services. It's a native iOS application built with SwiftUI. The primary technology stack is Swift and SwiftUI.

## Key Files and Structure

*   **`AIChatDemoApp.swift`**: The main entry point of the application. It sets up a `TabView` with three different chat examples.
*   **`FirebaseAILogicChatView.swift`**: This view demonstrates how to integrate `ConversationKit` with Firebase AI.
*   **`FirebaseAILogicChatWithMetadataView.swift`**: This is a more advanced example of Firebase AI integration that shows how to use a custom `Message` type to display metadata from the AI service.
*   **`FoundationModelChatView.swift`**: This view demonstrates how to integrate `ConversationKit` with on-device foundation models.
*   **`AIChatDemo.xcodeproj`**: The Xcode project file for the application.

## Dependencies and Relationships

This component depends on the `ConversationKit` library and the following external dependencies:

*   **`FirebaseAI`**: Used for the Firebase AI integration examples.
*   **`FoundationModels`**: Used for the on-device foundation models integration example.

## Technical Details

*   **Building and Running**: To run this example, open the `AIChatDemo.xcodeproj` file in Xcode and run the app on the simulator or a physical device.
*   **Firebase Setup**: This example requires a `GoogleService-Info.plist` file to be added to the project to connect to Firebase.

## Usage and Integration

This component is a standalone example application and is not meant to be integrated into other applications. It serves as a reference for developers who want to use `ConversationKit` with AI services.

## Important Notes

*   The `FoundationModelChatView` is only available on iOS 26.0+ because it uses the `FoundationModels` framework.
