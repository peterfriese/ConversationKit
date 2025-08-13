//
//  ErrorWrapper.swift
//  ConversationKit
//
//  Created by Peter Friese on 12.08.25.
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
