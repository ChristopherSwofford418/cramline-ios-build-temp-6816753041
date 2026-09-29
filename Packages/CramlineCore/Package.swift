// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CramlineCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v14)
    ],
    products: [
        .library(name: "CramlineCore", targets: ["CramlineCore"])
    ],
    targets: [
        .target(name: "CramlineCore"),
        .testTarget(name: "CramlineCoreTests", dependencies: ["CramlineCore"])
    ]
)
