// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GenerateurFiles",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "GenerateurFiles",
            path: "GenerateurFiles"
        )
    ]
)
