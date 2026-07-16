// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "AppTimezoneLauncher",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "AppTimezoneLauncher", targets: ["AppTimezoneLauncher"])
  ],
  dependencies: [
    .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.9.4")
  ],
  targets: [
    .target(
      name: "AppTimezoneLauncherCore"
    ),
    .executableTarget(
      name: "AppTimezoneLauncher",
      dependencies: [
        "AppTimezoneLauncherCore",
        .product(name: "Sparkle", package: "Sparkle"),
      ]
    ),
    .testTarget(
      name: "AppTimezoneLauncherTests",
      dependencies: ["AppTimezoneLauncherCore"]
    ),
  ]
)
