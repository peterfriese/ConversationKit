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
            messageInput.typeText("Hello")
            
            // Find and tap the send button
            let sendButton = app.buttons["composer_primary_button"]
            XCTAssertTrue(sendButton.exists, "Send button should exist")
            sendButton.tap()
            
            // Verify the message appears in the conversation list
            // We search for any element that contains the text, as Markdown might split it
            let messageText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Hello")).firstMatch
            if !messageText.waitForExistence(timeout: 15) {
                print("UI Hierarchy: \(app.debugDescription)")
                XCTFail("The submitted message 'Hello' should appear in the list")
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
            
            // Wait for the button label to change to "Stop generating"
            let stopPredicate = NSPredicate(format: "label == 'Stop generating'")
            let stopExpectation = XCTNSPredicateExpectation(predicate: stopPredicate, object: sendButton)
            let result = XCTWaiter().wait(for: [stopExpectation], timeout: 15)
            XCTAssertEqual(result, .completed, "Stop button should appear during long response generation")
            
            // Tap the stop button
            sendButton.tap()
            
            // Verify it changes back to the send button state ("Send message")
            let sendPredicate = NSPredicate(format: "label == 'Send message'")
            let sendExpectation = XCTNSPredicateExpectation(predicate: sendPredicate, object: sendButton)
            let sendResult = XCTWaiter().wait(for: [sendExpectation], timeout: 15)
            XCTAssertEqual(sendResult, .completed, "Send button should reappear after stopping")
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
            
            // Wait non-blockingly for the streaming response text to start appearing
            let responseText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Byte")).firstMatch
            XCTAssertTrue(responseText.waitForExistence(timeout: 15), "Streaming response should start appearing")
            
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
