//
//  ConversationKitTests.swift
//  ConversationKitTests
//

import Testing
@testable import ConversationKit

@Suite("ConversationKit v2")
struct ConversationKitTests {
  @Test("Package baseline compiles")
  func baseline() {
    #expect(Bool(true))
  }
}
