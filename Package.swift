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
            url: "https://github.com/bytehide/ByteHideMonitor-iOS/releases/download/v1.0.4/ByteHideMonitor.xcframework.zip",
            checksum: "8fac56c5fbcbec584553e12b42558d8207f77b01764de46c8fc6a0f7d4421c62"
        )
    ]
)
