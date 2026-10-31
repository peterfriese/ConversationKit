# Chameleon Cross-Platform Architecture

1. Centralize all UIKit / AppKit differences (`PlatformImage`, pasteboard, thumbnail generation via `ImageIO` / `QLThumbnailGenerator`, colors, haptics) inside `Sources/ConversationKit/Platform/`.
2. Domain models and SwiftUI views outside `Platform/` must compile cleanly on both iOS 26+ and macOS 26+ without scattered `#if canImport(UIKit)` blocks where a platform abstraction belongs.
