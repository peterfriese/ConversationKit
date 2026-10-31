// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ConversationKit",
  platforms: [
    .iOS(.v26),
    .macCatalyst(.v26),
    .macOS(.v26)
  ],
  products: [
    .library(
      name: "ConversationKit",
      targets: ["ConversationKit"]
    )
  ],
  targets: [
    .target(
      name: "ConversationKit"
    ),
    .testTarget(
      name: "ConversationKitTests",
      dependencies: ["ConversationKit"]
    )
  ]
)
