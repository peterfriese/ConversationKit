//
// ConversationKitTests.swift
// ConversationKit
//
// Created by Peter Friese on 04.07.25.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Testing
import SwiftUI
@testable import ConversationKit

struct ConversationKitTests {
  
  // MARK: - Message Tests
  
  @Test("DefaultMessage initialization and properties")
  func defaultMessageInitialization() {
    let message = DefaultMessage(content: "Hello", participant: .user)
    #expect(message.content == "Hello")
    #expect(message.participant == .user)
    #expect(message.imageURL == nil)
    #expect(message.error == nil)
    
    let imageMessage = DefaultMessage(content: "Pic", imageURL: "https://example.com/img.png", participant: .other)
    #expect(imageMessage.content == "Pic")
    #expect(imageMessage.imageURL == "https://example.com/img.png")
    #expect(imageMessage.participant == .other)
    #expect(imageMessage.error == nil)
  }
  
  @Test("DefaultMessage equality ignores error field")
  func defaultMessageEquality() {
    struct DummyError: Error {}
    
    var m1 = DefaultMessage(content: "Hi", participant: .user, error: DummyError())
    let m2 = m1
    #expect(m1 == m2)
    #expect(m1.hashValue == m2.hashValue)
    
    m1.content = "Hello"
    #expect(m1 != m2)
  }
  
  // MARK: - Attachment Tests
  
  @Test("ImageAttachment properties and equatable conformance")
  func imageAttachment() {
    #if canImport(UIKit)
    let nativeImage = UIImage()
    #elseif canImport(AppKit)
    let nativeImage = NSImage()
    #endif
    
    let a1 = ImageAttachment(image: nativeImage)
    let a2 = ImageAttachment(image: nativeImage)
    
    #expect(a1.id != a2.id)
    #expect(a1 != a2)
    
    let a3 = a1
    #expect(a1 == a3)
  }
  
  @Test("EmptyAttachment unique identification")
  func emptyAttachment() {
    let e1 = EmptyAttachment()
    let e2 = EmptyAttachment()
    #expect(e1.id != e2.id)
    #expect(e1 != e2)
  }
  
  // MARK: - Error Handling Tests
  
  @Test("ErrorWrapper encapsulates errors correctly")
  func errorWrapper() {
    struct TestError: Error, Equatable {
      let code: Int
    }
    
    let underlyingError = TestError(code: 42)
    let wrapper = ErrorWrapper(error: underlyingError)
    
    #expect(wrapper.error as? TestError == underlyingError)
    #expect(wrapper.id != UUID())
  }
  
  @Test("PresentErrorAction triggers handler closure")
  func presentErrorAction() {
    struct MyError: Error {}
    var triggeredError: Error?
    
    let action = PresentErrorAction { error in
      triggeredError = error
    }
    
    action(MyError())
    #expect(triggeredError is MyError)
  }
  
  // MARK: - Platform Helpers Tests
  
  @Test("PlatformImage resolves system symbols")
  func platformImageSymbolResolution() {
    let symbol = PlatformImage.systemSymbol("star.fill")
    #expect(symbol != nil)
  }
}
