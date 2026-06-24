// swift-tools-version: 6.1
import PackageDescription

// RainPrivy — Privy wallet adapter as a standalone package. Net-new module that proves the
// modular thesis: a new provider costs existing clients nothing. Currently a scaffold — it
// depends only on rain-core (`RainSDK`) and has NO Privy SDK dependency yet; the provider's
// methods throw `.notImplemented` until the Privy embedded-key SDK is integrated.
let package = Package(
  name: "RainPrivy",
  platforms: [
    .iOS(.v17)
  ],
  products: [
    .library(
      name: "RainPrivy",
      targets: ["RainPrivy"]
    ),
  ],
  dependencies: [
    .package(path: "../.."),
  ],
  targets: [
    .target(
      name: "RainPrivy",
      dependencies: [
        .product(name: "RainSDK", package: "rain-sdk-ios"),
      ]
    ),
    .testTarget(
      name: "RainPrivyTests",
      dependencies: ["RainPrivy"]
    ),
  ]
)
