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
    dependencies: [],
    targets: [
        .executableTarget(
            name: "quotes-cli",
            dependencies: []
        ),
    ]
)
