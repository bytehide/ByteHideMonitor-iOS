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
            checksum: "ace36c4fc4fa687c092f19bb5c4db001ad54e57fd4e2dac344e348e993e3a71c"
        )
    ]
)
