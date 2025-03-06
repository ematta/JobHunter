// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "JobHunter",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "JobHunter", targets: ["JobHunter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.4.3"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "JobHunter",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift"),
                "SwiftSoup",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources"),
        .testTarget(
            name: "JobHunterTests",
            dependencies: ["JobHunter"],
            path: "Tests"
        )
    ]
)