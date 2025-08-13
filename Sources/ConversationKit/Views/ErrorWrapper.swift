//
//  ErrorWrapper.swift
//  ConversationKit
//
//  Created by Peter Friese on 12.08.25.
//

import Foundation

/// A wrapper that makes any `Error` identifiable.
///
/// This is a common pattern to use with SwiftUI's presentation modifiers like `.sheet(item:)` or `.alert(item:)`,
/// which require the item to conform to `Identifiable`.
public struct ErrorWrapper: Identifiable {
  public let id = UUID()
  public let error: Error
  
  public init(error: Error) {
    self.error = error
  }
}
