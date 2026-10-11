// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "VisualPaint",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "VisualPaint", path: "Sources/VisualPaint")
    ]
)
