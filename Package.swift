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
            url: "https://github.com/bytehide/ByteHideMonitor-iOS/releases/download/v1.0.6/ByteHideMonitor.xcframework.zip",
            checksum: "c042d4a90397660a9c4455b3e7cc0bf48ed09cb94a4251438a04bcfb8d2dc390"
        )
    ]
)
