swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "quotes-cli",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "quotes-cli",
            targets: ["quotes-cli"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/swift-dotenv/SwiftDotEnv.git", from: "2.0.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.12.2")
    ],
    targets: [
        .executableTarget(
            name: "quotes-cli",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "DotEnv", package: "SwiftDotEnv"),
                .product(name: "SQLite", package: "SQLite.swift")
            ]
        ),
    ]
)
