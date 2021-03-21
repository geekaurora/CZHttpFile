// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "CZWebFileDownloader",
  platforms: [
    .iOS(.v11),
  ],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(
      name: "CZWebFileDownloader",
      type: .dynamic,
      targets: ["CZWebFileDownloader"]),
  ],
  dependencies: [
    .package(url: "https://github.com/geekaurora/CZUtils.git", from: "3.2.7"),
    .package(url: "https://github.com/geekaurora/CZNetworking.git", from: "3.2.2"),
  ],
  targets: [
    .target(
      name: "CZWebFileDownloader",
      dependencies: ["CZUtils", "CZNetworking"]),
    .testTarget(
      name: "CZWebFileDownloaderTests",
      dependencies: ["CZWebFileDownloader"]),
  ]
)
