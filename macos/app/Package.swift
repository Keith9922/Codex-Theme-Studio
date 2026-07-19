// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "CodexDreamSkinApp",
  platforms: [
    .macOS(.v13),
  ],
  products: [
    .executable(name: "CodexDreamSkin", targets: ["CodexDreamSkin"]),
  ],
  targets: [
    .executableTarget(
      name: "CodexDreamSkin",
      path: "Sources/CodexDreamSkin"
    ),
    .testTarget(
      name: "CodexDreamSkinTests",
      dependencies: ["CodexDreamSkin"],
      path: "Tests/CodexDreamSkinTests"
    ),
  ]
)
