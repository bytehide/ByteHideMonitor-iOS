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
            url: "https://github.com/bytehide/ByteHideMonitor-iOS/releases/download/v1.0.2/ByteHideMonitor.xcframework.zip",
            checksum: "c24b977b11f90dbf6d2b6516b45e39d8ce00dfceccd798fa81ef3d539455b1d3"
        )
    ]
)
