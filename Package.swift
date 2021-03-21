// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "CZWebFile",
  platforms: [
    .iOS(.v11),
  ],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(
      name: "CZWebFile",
      type: .dynamic,
      targets: ["CZWebFile"]),
  ],
  dependencies: [
    .package(url: "https://github.com/geekaurora/CZUtils.git", from: "3.2.7"),
    .package(url: "https://github.com/geekaurora/CZNetworking.git", from: "3.2.2"),
  ],
  targets: [
    .target(
      name: "CZWebFile",
      dependencies: ["CZUtils", "CZNetworking"]),
    .testTarget(
      name: "CZWebFileTests",
      dependencies: ["CZWebFile"]),
  ]
)