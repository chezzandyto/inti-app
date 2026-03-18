// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Inti",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Inti", targets: ["Inti"])
    ],
    targets: [
        .executableTarget(
            name: "Inti",
            path: "Sources"
        )
    ]
)
