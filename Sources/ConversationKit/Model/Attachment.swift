//
// Attachment.swift
// ConversationKit
//
// Created by Peter Friese on 01.09.25.
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

import SwiftUI

public protocol Attachment: Identifiable, Hashable {
  /// Determinate upload progress (`0.0...1.0`), or `nil` when ready/completed.
  var uploadProgress: Double? { get }

  /// Optional error encountered while uploading or preparing the attachment.
  var uploadError: (any Error)? { get }
}

public extension Attachment {
  var uploadProgress: Double? { nil }
  var uploadError: (any Error)? { nil }
}
