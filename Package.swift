// swift-tools-version:5.7
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
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "quotes-cli",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
    ]
)
