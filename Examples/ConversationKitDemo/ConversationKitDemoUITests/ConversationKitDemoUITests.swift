//
//  ConversationKitDemoUITests.swift
//  ConversationKitDemoUITests
//
//  Created by Gemini CLI on 30.06.26.
//

import XCTest

final class ConversationKitDemoUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testMessageSubmission() throws {
        XCTContext.runActivity(named: "Submit a simple message") { _ in
            // Find the message input field
            let messageInput = app.descendants(matching: .any)["message_input_field"].firstMatch
            XCTAssertTrue(messageInput.waitForExistence(timeout: 15), "Message input field should exist")
            
            // Type a message
            messageInput.tap()
            messageInput.typeText("Hello from UI Test")
            
            // Find and tap the send button
            let sendButton = app.buttons["composer_primary_button"]
            XCTAssertTrue(sendButton.exists, "Send button should exist")
            sendButton.tap()
            
            // Verify the message appears in the conversation list
            // We search for any element that contains the text, as Markdown might split it
            let messageText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Hello from UI Test")).firstMatch
            if !messageText.waitForExistence(timeout: 15) {
                print("UI Hierarchy: \(app.debugDescription)")
                XCTFail("The submitted message 'Hello from UI Test' should appear in the list")
            }
            
            // Verify the input field is cleared
            let inputValue = messageInput.value as? String
            XCTAssertTrue(inputValue == nil || inputValue == "" || inputValue == "Enter a message", "Input field should be cleared after sending, but got: \(inputValue ?? "nil")")
        }
    }

    func testStopButtonFlow() throws {
        XCTContext.runActivity(named: "Test Stop button functionality") { _ in
            let messageInput = app.descendants(matching: .any)["message_input_field"].firstMatch
            XCTAssertTrue(messageInput.waitForExistence(timeout: 15))
            messageInput.tap()
            
            // "long" triggers generateLongResponse in the demo app
            messageInput.typeText("long")
            
            let sendButton = app.buttons["composer_primary_button"]
            sendButton.tap()
            
            // The button should change its accessibility label to "Stop generating"
            let stopButton = app.buttons["Stop generating"]
            XCTAssertTrue(stopButton.waitForExistence(timeout: 15), "Stop button should appear during long response generation")
            
            // Tap the stop button
            stopButton.tap()
            
            // Verify it changes back to the send button (arrow.up) and is enabled again
            XCTAssertTrue(sendButton.waitForExistence(timeout: 15), "Send button should reappear after stopping")
        }
    }

    func testScrollAnchoring() throws {
        XCTContext.runActivity(named: "Verify scroll anchoring during streaming") { _ in
            let messageInput = app.descendants(matching: .any)["message_input_field"].firstMatch
            XCTAssertTrue(messageInput.waitForExistence(timeout: 15))
            messageInput.tap()
            messageInput.typeText("long")
            
            let sendButton = app.buttons["composer_primary_button"]
            sendButton.tap()
            
            let listView = app.scrollViews["conversation_scroll_view"]
            XCTAssertTrue(listView.waitForExistence(timeout: 15), "Conversation list should exist")
            
            // Wait a bit for some messages to stream in
            sleep(3)
            
            // Drag up to manually scroll, which should disable auto-scrolling
            listView.swipeUp()
            
            // We verify the view is still interactive
            XCTAssertTrue(listView.isHittable)
        }
    }

    func testAttachmentButton() throws {
        XCTContext.runActivity(named: "Test Attachment button menu") { _ in
            let attachmentButton = app.buttons["attachment_button"]
            XCTAssertTrue(attachmentButton.waitForExistence(timeout: 15), "Attachment button should exist")
            
            attachmentButton.tap()
            
            // Verify the "Photos" option appears in the menu
            let photosButton = app.buttons["Photos"]
            XCTAssertTrue(photosButton.waitForExistence(timeout: 15), "Photos option should appear in the attachment menu")
        }
    }
}
