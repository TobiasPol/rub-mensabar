// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "RUBMensaBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "RUBMensaBar", targets: ["RUBMensaBar"]),
        .library(name: "RUBMensaBarCore", targets: ["RUBMensaBarCore"])
    ],
    targets: [
        .target(
            name: "RUBMensaBarCore"
        ),
        .executableTarget(
            name: "RUBMensaBar",
            dependencies: ["RUBMensaBarCore"]
        ),
        .testTarget(
            name: "RUBMensaBarCoreTests",
            dependencies: ["RUBMensaBarCore"]
        )
    ]
)
