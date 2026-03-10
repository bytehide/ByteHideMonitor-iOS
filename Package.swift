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
            url: "https://github.com/bytehide/ByteHideMonitor-iOS/releases/download/v1.0.7/ByteHideMonitor.xcframework.zip",
            checksum: "bf4d379113dcb480a30453495f3cab89ad22512241ddb7004bd9b9fdbe5660bb"
        )
    ]
)
