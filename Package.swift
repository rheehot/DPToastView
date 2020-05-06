// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DPToastView",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(
            name: "DPToastView",
            targets: ["DPToastView"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "DPToastView",
            dependencies: ["objc"],
            path: "Sources",
            exclude: []
        ),
    ]
)
