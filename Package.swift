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
            url: "https://github.com/bytehide/ByteHideMonitor-iOS/releases/download/v1.0.8/ByteHideMonitor.xcframework.zip",
            checksum: "9432129bb8bbab7c16ba7a2b0373d9b8f26a5be9c8149bedd0fc2a6f664652c9"
        )
    ]
)
