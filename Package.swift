// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Magic",
    platforms: [
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
        .target(
            name: "libmagic",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                .define("HAVE_CONFIG_H"),
                .define("MAGIC", to: "\"/usr/share/file/magic.mgc\"")
            ],
            linkerSettings: [
                .linkedLibrary("bz2"),
                .linkedLibrary("z")
            ]
        ),
        .target(
            name: "Magic",
            dependencies: ["libmagic"],
            resources: [
                .process("magic.mgc")
            ]
        ),
        .testTarget(
            name: "MagicTests",
            dependencies: ["Magic"]
        )
    ]
)
