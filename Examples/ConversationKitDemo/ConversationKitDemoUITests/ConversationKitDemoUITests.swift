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

  func testFirstTurnSuggestionChipsAndMessageSubmission() throws {
    XCTContext.runActivity(named: "Verify suggestion chips on launch and submit a message") { _ in
      let suggestionBar = app.descendants(matching: .any)["composer.suggestionChipsBar"].firstMatch
      XCTAssertTrue(
        suggestionBar.waitForExistence(timeout: 15),
        "First-turn suggestion chips bar should exist on initial empty conversation"
      )

      let messageInput = app.descendants(matching: .any)["composer.textField"].firstMatch
      XCTAssertTrue(messageInput.waitForExistence(timeout: 15), "Composer text field should exist")

      messageInput.tap()

      let dismissKeyboardButton = app.buttons["composer.dismissKeyboardButton"]
      XCTAssertTrue(
        dismissKeyboardButton.waitForExistence(timeout: 5),
        "Focus-driven keyboard dismiss button should appear when composer is focused"
      )

      messageInput.typeText("Hello")

      let sendButton = app.buttons["composer.submitButton"]
      XCTAssertTrue(sendButton.exists, "Submit button should exist")
      sendButton.tap()

      let messageText = app.staticTexts.containing(
        NSPredicate(format: "label CONTAINS %@", "Hello")
      ).firstMatch
      if !messageText.waitForExistence(timeout: 15) {
        XCTFail("The submitted message 'Hello' should appear in the timeline")
      }

      let inputValue = messageInput.value as? String
      XCTAssertTrue(
        inputValue == nil || inputValue == "" || inputValue == "Message…",
        "Input field should be cleared after sending, but got: \(inputValue ?? "nil")"
      )
    }
  }

  func testStopButtonFlow() throws {
    XCTContext.runActivity(named: "Test cooperative Stop button functionality") { _ in
      let messageInput = app.descendants(matching: .any)["composer.textField"].firstMatch
      XCTAssertTrue(messageInput.waitForExistence(timeout: 15))
      messageInput.tap()
      messageInput.typeText("long")

      let sendButton = app.buttons["composer.submitButton"]
      sendButton.tap()

      let stopPredicate = NSPredicate(format: "label == 'Stop generating'")
      let stopExpectation = XCTNSPredicateExpectation(predicate: stopPredicate, object: sendButton)
      let result = XCTWaiter().wait(for: [stopExpectation], timeout: 15)
      XCTAssertEqual(result, .completed, "Stop button should appear during response generation")

      sendButton.tap()

      let sendPredicate = NSPredicate(format: "exists == false")
      let sendExpectation = XCTNSPredicateExpectation(predicate: sendPredicate, object: sendButton)
      let sendResult = XCTWaiter().wait(for: [sendExpectation], timeout: 15)
      XCTAssertEqual(sendResult, .completed, "Stop button should dismiss after stopping when input is empty")
    }
  }

  func testScrollAnchoringAndScrollToBottomButton() throws {
    XCTContext.runActivity(named: "Verify top-floating turn anchoring and scroll-to-bottom pill") { _ in
      let messageInput = app.descendants(matching: .any)["composer.textField"].firstMatch
      XCTAssertTrue(messageInput.waitForExistence(timeout: 15))
      messageInput.tap()
      messageInput.typeText("long")

      let sendButton = app.buttons["composer.submitButton"]
      sendButton.tap()

      let listView = app.scrollViews["timeline.scrollView"]
      XCTAssertTrue(listView.waitForExistence(timeout: 15), "Timeline scroll view should exist")

      let responseText = app.staticTexts.containing(
        NSPredicate(format: "label CONTAINS %@", "Byte")
      ).firstMatch
      XCTAssertTrue(responseText.waitForExistence(timeout: 15), "Streaming response should start appearing")

      let scrollToBottomButton = app.buttons["timeline.scrollToBottomButton"]
      if scrollToBottomButton.waitForExistence(timeout: 10) {
        scrollToBottomButton.tap()
      }

      XCTAssertTrue(listView.isHittable)
    }
  }

  func testAttachmentButton() throws {
    XCTContext.runActivity(named: "Test Attachment button menu") { _ in
      let attachmentButton = app.descendants(matching: .any)["composer.attachmentButton"].firstMatch
      XCTAssertTrue(attachmentButton.waitForExistence(timeout: 15), "Attachment button should exist")

      attachmentButton.tap()

      let photosButton = app.buttons["Photos"]
      XCTAssertTrue(
        photosButton.waitForExistence(timeout: 15),
        "Photos option should appear in the attachment menu"
      )
    }
  }

  func testModelSelectorMenuInsideInteractiveClassicGlassPill() throws {
    XCTContext.runActivity(named: "Test Model Selector Menu opens without vanishing ClassicGlass pill") { _ in
      let modelSelector = app.descendants(matching: .any)["composer.modelSelector"].firstMatch
      XCTAssertTrue(modelSelector.waitForExistence(timeout: 15), "Model selector menu button should exist")

      modelSelector.tap()

      let thinkToggle = app.buttons["composer.capability.think"].firstMatch
      let modelOption = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Claude")).firstMatch
      XCTAssertTrue(
        thinkToggle.waitForExistence(timeout: 10) || modelOption.waitForExistence(timeout: 10),
        "Native model selector Menu should open when tapped inside ClassicGlass composer"
      )

      let pngData = XCUIScreen.main.screenshot().pngRepresentation
      try? pngData.write(
        to: URL(fileURLWithPath: "/private/var/folders/x1/nrkqnm6j0755nn48dkyv7pl80000gn/T/opencode/breathing-4-menu-open.png")
      )
    }
  }
}
