//
// PlatformTypes.swift
// ConversationKit
//
// Cross-platform type aliases following the Chameleon pattern:
// centralize platform differences so view code stays clean.

import SwiftUI

#if canImport(UIKit)
  import UIKit
  public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
  import AppKit
  public typealias PlatformImage = NSImage
#endif

// MARK: - Platform Image Construction

extension PlatformImage {
  /// Create a platform image from an SF Symbol name.
  static func systemSymbol(_ name: String) -> PlatformImage? {
    #if canImport(UIKit)
      return UIImage(systemName: name)
    #elseif canImport(AppKit)
      return NSImage(systemSymbolName: name, accessibilityDescription: nil)
    #endif
  }
}

// MARK: - Platform Image → SwiftUI Image

extension Image {
  /// Create a SwiftUI Image from a platform-native image.
  init(platformImage: PlatformImage) {
    #if canImport(UIKit)
      self.init(uiImage: platformImage)
    #elseif canImport(AppKit)
      self.init(nsImage: platformImage)
    #endif
  }
}

// MARK: - Platform Colors

extension Color {
  /// Secondary system background — `.secondarySystemBackground` on iOS,
  /// `.controlBackgroundColor` on macOS.
  static var platformSecondaryBackground: Color {
    #if canImport(UIKit)
      Color(uiColor: .secondarySystemBackground)
    #elseif canImport(AppKit)
      Color(nsColor: .controlBackgroundColor)
    #endif
  }

  /// System gray 4 — `.systemGray4` on iOS, `.systemGray` on macOS.
  static var platformGray4: Color {
    #if canImport(UIKit)
      Color(uiColor: .systemGray4)
    #elseif canImport(AppKit)
      Color(nsColor: .systemGray)
    #endif
  }

  /// Separator color — `.separator` on iOS, `.separatorColor` on macOS.
  static var platformSeparator: Color {
    #if canImport(UIKit)
      Color(uiColor: .separator)
    #elseif canImport(AppKit)
      Color(nsColor: .separatorColor)
    #endif
  }
}
