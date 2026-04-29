// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "ByteHideMonitor",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "ByteHideMonitor",
            targets: ["ByteHideMonitor"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "ByteHideMonitor",
            url: "https://github.com/bytehide/ByteHideMonitor-iOS/releases/download/v1.0.10/ByteHideMonitor.xcframework.zip",
            checksum: "e4c114b3adf8c4e57e4101aacae187fbd96e11f009ec413d3f5ab84e7cad4860"
        )
    ]
)
