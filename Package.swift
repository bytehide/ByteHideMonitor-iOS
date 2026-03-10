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
            checksum: "bb3f190ddac0a1aed8331c5b63a95f8415826d5edad2faece0723f1fe7073ad8"
        )
    ]
)
