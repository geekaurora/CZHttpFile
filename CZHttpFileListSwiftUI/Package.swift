// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "CZHttpFileListSwiftUI",
  platforms: [.iOS("15.0")],
  products: [
    .library(
      name: "CZHttpFileListSwiftUI",
      type: .dynamic,
      targets: ["CZHttpFileListSwiftUI"]),
  ],
  dependencies: [
    .package(url: "https://github.com/geekaurora/CZUtils.git", from: "4.4.0"),
    .package(url: "https://github.com/geekaurora/CZHttpFile.git", from: "1.8.0"),
    .package(url: "https://github.com/geekaurora/SwiftUIKit.git", from: "1.2.0"),
  ],
  targets: [
    .target(
      name: "CZHttpFileListSwiftUI",
      dependencies: ["CZUtils", "CZHttpFile", "SwiftUIKit"]),
    .testTarget(
      name: "CZHttpFileListSwiftUITests",
      dependencies: ["CZHttpFileListSwiftUI"]),
  ]
)
