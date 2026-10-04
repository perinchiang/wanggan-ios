// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WangGanCore",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [.library(name: "WangGanCore", targets: ["WangGanCore"])],
    targets: [
        .target(name: "WangGanCore", path: "Sources/Core"),
        .testTarget(name: "WangGanCoreTests", dependencies: ["WangGanCore"], path: "Tests/CoreTests")
    ]
)
