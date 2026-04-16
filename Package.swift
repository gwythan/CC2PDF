// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CC2PDF",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "CC2PDF",
            path: "Sources/CC2PDF",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CC2PDFTests",
            dependencies: ["CC2PDF"],
            path: "Tests/CC2PDFTests"
        )
    ]
)
