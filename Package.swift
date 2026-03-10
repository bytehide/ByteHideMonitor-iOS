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
            checksum: "4a048e696db62efd5974903532aec4ea174a764bd35a74f35f68d983561715b4"
        )
    ]
)
