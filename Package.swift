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
            url: "https://github.com/bytehide/ByteHideMonitor-iOS/releases/download/v1.0.3/ByteHideMonitor.xcframework.zip",
            checksum: "fff0a6706dca2454579e8f4cf505ccf7a6c834a6daf54ede8febe8aefdd147ca"
        )
    ]
)
