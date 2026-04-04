// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Facio",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/Juiiceee/SolKit", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "Facio",
            dependencies: [
                .product(name: "SolKit", package: "SolKit"),
                .product(name: "SolKitPay", package: "SolKit"),
            ],
            path: "Facio",
            exclude: ["Resources/AppIcon.icns"],
            resources: [.copy("Resources/solanaLogo.png")]
        )
    ]
)
