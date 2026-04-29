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
            url: "https://github.com/bytehide/ByteHideMonitor-iOS/releases/download/v1.0.11/ByteHideMonitor.xcframework.zip",
            checksum: "707b8e5bf18fcff399ac9771eca4c6cb1a722594c85520a86ee5c7d67e60c788"
        )
    ]
)
