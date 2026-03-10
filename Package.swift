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
            checksum: "6a8968c7d1d47e4ee82932b0318df0e3bc38354ffbba5feb335b393ecc3fe5be"
        )
    ]
)
