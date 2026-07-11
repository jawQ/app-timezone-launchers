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
  targets: [
    .target(
      name: "AppTimezoneLauncherCore"
    ),
    .executableTarget(
      name: "AppTimezoneLauncher",
      dependencies: ["AppTimezoneLauncherCore"]
    ),
    .testTarget(
      name: "AppTimezoneLauncherTests",
      dependencies: ["AppTimezoneLauncherCore"]
    ),
  ]
)
