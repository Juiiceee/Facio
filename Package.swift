// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Facio",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "Facio",
            path: "Facio",
            exclude: ["Resources/AppIcon.icns", "Config/Secrets.example"]
        )
    ]
)
