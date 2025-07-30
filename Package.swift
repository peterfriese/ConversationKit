// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ConversationKit",
  platforms: [.iOS(.v17), .macCatalyst(.v17)],
  products: [
    .library(
      name: "ConversationKit",
      targets: ["ConversationKit"]),
  ],
  dependencies: [
    .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.0.2")
  ],
  targets: [
    .target(
      name: "ConversationKit", dependencies: [
        .product(name: "MarkdownUI", package: "swift-markdown-ui")
      ]),
    .testTarget(
      name: "ConversationKitTests",
      dependencies: ["ConversationKit"]),
  ]
)
