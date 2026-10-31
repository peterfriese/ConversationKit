# Rule: Chameleon Cross-Platform Abstraction & OS Availability

1. **Zero Raw UIKit/AppKit Types in Views**: Never reference `UIImage`, `UIColor`, `NSImage`, or `NSColor` directly inside `Sources/ConversationKit/Views/**`. Always route platform-specific types and color/symbol helpers through `Sources/ConversationKit/Platform/PlatformTypes.swift` (`PlatformImage`, `Color.platform*`).
2. **Compiler & OS Guards for Liquid Glass & FoundationModels**: Guard iOS 26+ APIs (such as `GlassEffectContainer`, `.glassEffect`, or `FoundationModels`) with both `#if compiler(>=6.2)` and `if #available(iOS 26.0, macOS 26.0, *)`, providing graceful material fallbacks for iOS 17+ and macOS 14+.
