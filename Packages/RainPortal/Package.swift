// swift-tools-version: 6.1
import PackageDescription

// RainPortal — the Portal wallet adapter as a standalone package. Depends on rain-core
// (`RainSDK`) and PortalSwift. A Portal app links this; Turnkey is still pulled in transitively
// via rain-core (Turnkey is the baseline provider). During development the core dependency is a
// local path; for publishing it becomes a versioned URL to the rain-core repo.
let package = Package(
  name: "RainPortal",
  platforms: [
    .iOS(.v17)
  ],
  products: [
    .library(
      name: "RainPortal",
      targets: ["RainPortal"]
    ),
  ],
  dependencies: [
    .package(path: "../.."),
    .package(url: "https://github.com/portal-hq/PortalSwift.git", exact: "7.1.0"),
  ],
  targets: [
    .target(
      name: "RainPortal",
      dependencies: [
        .product(name: "RainSDK", package: "rain-sdk-ios"),
        .product(name: "PortalSwift", package: "PortalSwift"),
      ]
    ),
    .testTarget(
      name: "RainPortalTests",
      dependencies: ["RainPortal"]
    ),
  ]
)
