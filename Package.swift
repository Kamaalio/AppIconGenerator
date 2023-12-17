// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppIconGenerator",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(
            name: "AppIconGenerator",
            targets: ["AppIconGenerator"]),
    ],
    targets: [
        .target(
            name: "AppIconGenerator",
            resources: [
                .process("Internals/Resources")
            ]
        ),
        .testTarget(
            name: "AppIconGeneratorTests",
            dependencies: ["AppIconGenerator"],
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
