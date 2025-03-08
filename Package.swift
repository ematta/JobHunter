// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "JobHunter",
    platforms: [
        .macOS(.v12),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v4)
    ],
    products: [
        .executable(name: "JobHunter", targets: ["JobHunter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "JobHunter",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift"),
                "SwiftSoup",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources",
            swiftSettings: [
                .define("RUNNING_IN_SPM")
            ]),
        .testTarget(
            name: "JobHunterTests",
            dependencies: ["JobHunter"],
            path: "Tests",
            exclude: ["README.md", "UITests"],
            swiftSettings: [
                .define("RUNNING_IN_SPM")
            ]
        ),
        .testTarget(
            name: "JobHunterUITests",
            dependencies: ["JobHunter"],
            path: "Tests/UITests",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .define("RUNNING_IN_SPM")
            ]
        )
    ]
)