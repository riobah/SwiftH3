// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftH3",
    products: [
        .library(
            name: "SwiftH3",
            targets: ["SwiftH3"]),
    ],
    dependencies: [
        .package(url: "https://github.com/bdotdub/Ch3.git", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "SwiftH3",
            dependencies: []),
        .testTarget(
            name: "SwiftH3Tests",
            dependencies: ["SwiftH3"]),
    ]
)
