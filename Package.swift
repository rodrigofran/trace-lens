// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TraceLens",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "TraceLens", targets: ["TraceLens"])],
    targets: [
        .target(name: "TraceLensCore"),
        .target(name: "TraceLensStorage", dependencies: ["TraceLensCore"]),
        .target(name: "TraceLensMetrics", dependencies: ["TraceLensCore"]),
        .target(name: "TraceLensCapture", dependencies: ["TraceLensCore", "TraceLensStorage"]),
        .target(name: "TraceLensUI", dependencies: ["TraceLensCore", "TraceLensStorage", "TraceLensMetrics"]),
        .target(name: "TraceLens", dependencies: ["TraceLensCore", "TraceLensStorage", "TraceLensMetrics", "TraceLensCapture", "TraceLensUI"]),
        .testTarget(name: "TraceLensCoreTests", dependencies: ["TraceLensCore"]),
        .testTarget(name: "TraceLensStorageTests", dependencies: ["TraceLensStorage", "TraceLensCore"]),
        .testTarget(name: "TraceLensMetricsTests", dependencies: ["TraceLensMetrics", "TraceLensCore"]),
        .testTarget(name: "TraceLensCaptureTests", dependencies: ["TraceLensCapture", "TraceLensStorage", "TraceLensCore"])
    ]
)
