// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DRXtoLUT",
    defaultLocalization: "ro",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "DRXtoLUT",
            path: "Sources/DRXtoLUT"
        )
    ]
)
