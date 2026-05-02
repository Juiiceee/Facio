// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Facio",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/Juiiceee/SolKit", revision: "9d9c5d3c83d9da3ae85ea760bff2b70120cf052c"),
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
