// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TLDExtract",
    products: [
        .library(
            name: "TLDExtract",
            targets: ["TLDExtract"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TLDExtract",
            dependencies: [],
            resources: [
                .copy("Resources/public_suffix_list.dat")
            ]
        ),
        .testTarget(
            name: "TLDExtractTests",
            dependencies: ["TLDExtract"])
    ]
)
