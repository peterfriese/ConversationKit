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
    XCTContext.runActivity(named: "Verify top-floating turn anchoring across Turn 1 and Turn 2+") { _ in
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
        // Stop Turn 1 if still generating, or wait until ready for Turn 2
        if sendButton.exists && sendButton.label == "Stop generating" {
          sendButton.tap()
        }
      } else if sendButton.exists && sendButton.label == "Stop generating" {
        sendButton.tap()
      }

      // Submit Turn 2 after Turn 1's long response and verify Turn 2 user message anchors near the top
      messageInput.tap()
      messageInput.typeText("Turn two top anchor check")
      XCTAssertTrue(sendButton.waitForExistence(timeout: 5))
      sendButton.tap()

      let secondTurnBubble = app.staticTexts.containing(
        NSPredicate(format: "label CONTAINS %@", "Turn two top anchor check")
      ).firstMatch
      XCTAssertTrue(
        secondTurnBubble.waitForExistence(timeout: 10),
        "Second turn user message should be realized and visible"
      )

      // Allow the 150ms multi-pass top-anchor scroll animation to settle
      Thread.sleep(forTimeInterval: 0.6)
      XCTAssertTrue(
        secondTurnBubble.frame.minY < app.frame.height * 0.45,
        "Second turn user message should anchor near the top of the viewport, but minY was \(secondTurnBubble.frame.minY) (screen height: \(app.frame.height))"
      )
      XCTAssertTrue(listView.isHittable)
    }
  }

  func testTurn2TopAnchorDoesNotSlideDownToRevealTurn1ActionBar() throws {
    XCTContext.runActivity(named: "Observe Turn 2 top anchor and Turn 1 action bar across time") { _ in
      let listView = app.scrollViews["timeline.scrollView"]
      XCTAssertTrue(listView.waitForExistence(timeout: 15), "Timeline scroll view should exist")

      // Turn 1: Tap first starter suggestion chip ("Liquid Glass Design")
      let firstChip = app.buttons["composer.suggestionChip.liquid-glass"].firstMatch
      XCTAssertTrue(firstChip.waitForExistence(timeout: 15), "Starter chip should exist")
      firstChip.tap()

      // Wait for Turn 1 to completely finish streaming (so its Copy message action button AND follow-up chips appear)
      let copyButton = app.buttons.matching(
        NSPredicate(format: "identifier BEGINSWITH 'message.action.copy.'")
      ).firstMatch
      XCTAssertTrue(
        copyButton.waitForExistence(timeout: 25),
        "Turn 1 action bar Copy button should appear when Turn 1 finishes streaming"
      )

      let followUpChip = app.buttons["composer.suggestionChip.followup-glass-compare"].firstMatch
      XCTAssertTrue(
        followUpChip.waitForExistence(timeout: 10),
        "Follow-up suggestion chip should appear after Turn 1 finishes"
      )

      print("=== BEFORE TURN 2 ===")
      var logLines: [String] = []
      let t0 = Date()
      func elapsedMs() -> Int {
        Int(Date().timeIntervalSince(t0) * 1000)
      }
      logLines.append("BEFORE TURN 2: scrollView.frame=\(listView.frame) copyButton.frame=\(copyButton.frame) followUpChip.frame=\(followUpChip.frame)")

      // Submit Turn 2 by tapping follow-up suggestion chip ("Compare Classic vs Card Glass")
      followUpChip.tap()
      logLines.append("t=\(elapsedMs())ms: followUpChip.tap() returned")

      let secondTurnBubble = app.staticTexts.containing(
        NSPredicate(format: "label CONTAINS %@", "Compare ClassicGlass")
      ).firstMatch
      XCTAssertTrue(
        secondTurnBubble.waitForExistence(timeout: 10),
        "Turn 2 user message bubble should appear in the timeline"
      )

      var anchoredMinY: CGFloat?
      for i in 0..<12 {
        if i > 0 {
          Thread.sleep(forTimeInterval: 0.15)
        }
        let ms = elapsedMs()
        let turn2Frame = secondTurnBubble.frame
        let copyFrame = copyButton.exists ? copyButton.frame : .zero
        let line = "[sample \(i) at t=\(ms)ms] turn2Bubble.minY=\(String(format: "%.1f", turn2Frame.minY)) maxY=\(String(format: "%.1f", turn2Frame.maxY)) | turn1CopyButton.minY=\(String(format: "%.1f", copyFrame.minY)) maxY=\(String(format: "%.1f", copyFrame.maxY))"
        logLines.append(line)

        // Once the top-anchor spring settles (~sample 2 onwards, t >= 1,200ms), enforce strict top-pinning
        if i >= 2 {
          if anchoredMinY == nil {
            anchoredMinY = turn2Frame.minY
          }
          XCTAssertLessThanOrEqual(
            turn2Frame.minY,
            145.0,
            "Sample \(i) (t=\(ms)ms): Turn 2 user bubble should remain anchored at the top (<= 145pt), but was \(turn2Frame.minY)pt"
          )
          if copyFrame != .zero {
            XCTAssertLessThanOrEqual(
              copyFrame.maxY,
              116.0,
              "Sample \(i) (t=\(ms)ms): Turn 1 Copy button maxY should remain hidden above the navigation bar (<= 116pt), not revealed at \(copyFrame.maxY)pt"
            )
            XCTAssertLessThan(
              copyFrame.maxY,
              turn2Frame.minY,
              "Sample \(i) (t=\(ms)ms): Turn 1 Copy button must stay strictly above Turn 2 user bubble"
            )
          }
        }
      }

      try? logLines.joined(separator: "\n").write(
        to: URL(fileURLWithPath: "/private/var/folders/x1/nrkqnm6j0755nn48dkyv7pl80000gn/T/opencode/turn2-log.txt"),
        atomically: true,
        encoding: .utf8
      )

      let finalMinY = secondTurnBubble.frame.minY
      let finalCopyMaxY = copyButton.exists ? copyButton.frame.maxY : 0
      XCTAssertLessThanOrEqual(
        finalMinY,
        145.0,
        "Turn 2 user bubble should stay anchored at the top (~126pt <= 145pt), not move down to \(finalMinY)pt to reveal Turn 1's action bar"
      )
      if let anchoredMinY {
        XCTAssertLessThanOrEqual(
          abs(finalMinY - anchoredMinY),
          4.0,
          "Turn 2 user bubble should not drift vertically after anchoring (anchoredMinY=\(anchoredMinY), finalMinY=\(finalMinY))"
        )
      }
      if finalCopyMaxY > 0 {
        XCTAssertLessThanOrEqual(
          finalCopyMaxY,
          116.0,
          "Turn 1 Copy button should remain hidden above the navigation bar (maxY <= 116pt), but was \(finalCopyMaxY)pt"
        )
        XCTAssertLessThan(
          finalCopyMaxY,
          finalMinY,
          "Turn 1 Copy button maxY (\(finalCopyMaxY)pt) must remain strictly above Turn 2 user bubble minY (\(finalMinY)pt)"
        )
      }
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
