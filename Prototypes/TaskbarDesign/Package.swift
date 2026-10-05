// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TaskbarDesign",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "TaskbarDesign", targets: ["TaskbarDesign"])
    ],
    targets: [
        .executableTarget(name: "TaskbarDesign")
    ]
)
