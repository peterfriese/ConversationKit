# Component: ConversationKitDemo

## Component Overview

This component is a simple example application that demonstrates the basic usage of the `ConversationKit` library. It's a native iOS application built with SwiftUI. The primary technology stack is Swift and SwiftUI.

## Key Files and Structure

*   **`ConversationKitDemoApp.swift`**: The main entry point of the application.
*   **`ContentView.swift`**: This view demonstrates the basic usage of the `ConversationView`, including how to display messages, bind and manage an array of attachments, handle user input, configure photo attachments via `.attachmentActions`, and simulate a streaming response with cancellation support.
*   **`ConversationKitDemo.xcodeproj`**: The Xcode project file for the application.

## Dependencies and Relationships

This component depends on the `ConversationKit` library.

## Technical Details

*   **Building and Running**: To run this example, open the `ConversationKitDemo.xcodeproj` file in Xcode and run the app on the simulator or a physical device.
*   **Attachment Handling**: `ContentView` holds a local array of `attachments` (`ImageAttachment`). It binds this array to `ConversationView` and implements `.attachmentActions` to display a Photos Picker, loading image data as transferables.

## Usage and Integration

This component is a standalone example application and is not meant to be integrated into other applications. It serves as a reference for developers who want to learn how to use the basic features of `ConversationKit`, including text messaging, attachment previews, and generation control.
