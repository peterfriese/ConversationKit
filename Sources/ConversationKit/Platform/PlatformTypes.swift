//
// PlatformTypes.swift
// ConversationKit
//
// Cross-platform type aliases following the Chameleon pattern:
// centralize platform differences so view code stays clean.

import ImageIO
import SwiftUI

#if canImport(UIKit)
  import UIKit
  public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
  import AppKit
  public typealias PlatformImage = NSImage
#endif

// MARK: - Platform Pasteboard

public enum PlatformPasteboard {
  @MainActor
  public static func copy(_ text: String) {
    #if canImport(UIKit)
      UIPasteboard.general.string = text
    #elseif canImport(AppKit)
      NSPasteboard.general.clearContents()
      NSPasteboard.general.setString(text, forType: .string)
    #endif
  }
}

// MARK: - Platform Image Construction

extension PlatformImage {
  /// Create a platform image from an SF Symbol name.
  public static func systemSymbol(_ name: String) -> PlatformImage? {
    #if canImport(UIKit)
      return UIImage(systemName: name)
    #elseif canImport(AppKit)
      return NSImage(systemSymbolName: name, accessibilityDescription: nil)
    #endif
  }

  /// Downsamples raw image data using `ImageIO` without decoding the full-resolution bitmap into memory.
  ///
  /// - Parameters:
  ///   - data: The raw encoded image data (e.g., JPEG, PNG, HEIC).
  ///   - maxPixelDimension: Maximum width or height in pixels for the decoded thumbnail (defaults to `1024`).
  /// - Returns: A downsampled `PlatformImage`, or `nil` if `data` is empty or cannot be decoded.
  public static func downsampled(
    from data: Data,
    maxPixelDimension: CGFloat = 1024
  ) -> PlatformImage? {
    guard !data.isEmpty, maxPixelDimension > 0 else { return nil }
    let sourceOptions: [CFString: Any] = [
      kCGImageSourceShouldCache: false
    ]
    guard let imageSource = CGImageSourceCreateWithData(
      data as CFData,
      sourceOptions as CFDictionary
    ) else {
      return nil
    }
    let thumbnailOptions: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: max(1, Int(maxPixelDimension.rounded()))
    ]
    guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
      imageSource,
      0,
      thumbnailOptions as CFDictionary
    ) else {
      return nil
    }
    #if canImport(UIKit)
      return UIImage(cgImage: cgImage)
    #elseif canImport(AppKit)
      return NSImage(
        cgImage: cgImage,
        size: NSSize(width: cgImage.width, height: cgImage.height)
      )
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

  /// Tertiary system background — `.tertiarySystemBackground` on iOS,
  /// `.underPageBackgroundColor` on macOS.
  static var platformTertiaryBackground: Color {
    #if canImport(UIKit)
      Color(uiColor: .tertiarySystemBackground)
    #elseif canImport(AppKit)
      Color(nsColor: .underPageBackgroundColor)
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
