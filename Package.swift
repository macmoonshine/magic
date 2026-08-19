// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Magic",
    platforms: [
        .iOS(.v15),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "libmagic",
            targets: ["libmagic"]
        ),
        .library(
            name: "Magic",
            targets: ["libmagic", "Magic"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "libmagic",
			path: "Frameworks/libmagic.xcframework"
        ),
        .target(
            name: "Magic",
            dependencies: ["libmagic"],
            resources: [
                .copy("Resources/magic.mgc")
            ]
        ),
        .testTarget(
            name: "MagicTests",
            dependencies: ["Magic"]
        )
    ]
)
