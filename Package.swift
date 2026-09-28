// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SplitBar",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "SplitBar",
            targets: ["SplitBar"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "SplitBar",
            dependencies: [],
            path: "Sources/SplitBar",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
