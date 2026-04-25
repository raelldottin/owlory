// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "OwloryCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "OwloryCore", targets: ["OwloryCore"])
    ],
    targets: [
        .target(
            name: "OwloryCore",
            path: "Owlory/Core",
            sources: [
                "Application",
                "Domain",
                "Persistence"
            ]
        ),
        .testTarget(
            name: "OwloryCoreTests",
            dependencies: ["OwloryCore"],
            path: "OwloryCoreTests"
        )
    ]
)
