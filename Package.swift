 // swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "quotes-cli",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "quotes-cli",
            targets: ["quotes-cli"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/swiftpackages/DotEnv.git", from: "3.0.0")
    ],
    targets: [
        .executableTarget(
            name: "quotes-cli",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "DotEnv", package: "DotEnv")
            ]
        ),
    ]
)
