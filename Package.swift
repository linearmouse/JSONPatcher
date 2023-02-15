// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JSONPatcher",
    products: [
        .library(
            name: "JSONPatcher",
            targets: ["JSONPatcher"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "JSONPatcher",
            dependencies: []
        ),
        .testTarget(
            name: "JSONPatcherTests",
            dependencies: ["JSONPatcher"]
        ),
    ]
)
