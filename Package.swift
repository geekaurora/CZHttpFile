// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "CZHttpFile",
  platforms: [
    .iOS(.v12),
  ],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(
      name: "CZHttpFile",
      type: .dynamic,
      targets: ["CZHttpFile"]),
  ],
  dependencies: [
    .package(url: "https://github.com/geekaurora/CZUtils.git", from: "4.4.8"),
    .package(url: "https://github.com/geekaurora/CZTestUtils.git", from: "1.1.2"),
    .package(url: "https://github.com/geekaurora/CZNetworking.git", from: "3.4.9"),
  ],
  targets: [
    .target(
      name: "CZHttpFile",
      dependencies: ["CZUtils", "CZNetworking"]),
    .testTarget(
      name: "CZHttpFileTests",
      dependencies: ["CZHttpFile", "CZUtils", "CZNetworking", "CZTestUtils"]),
  ]
)
