// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DangerPackage",
    products: [
        .library(name: "DangerDeps", type: .dynamic, targets: ["DangerDependencies"])
    ],
    dependencies: [
        .package(url: "https://github.com/danger/swift.git", from: "3.18.0"),
        .package(url: "https://github.com/f-meloni/danger-swift-xcodesummary", from: "1.2.1"),
        .package(url: "https://github.com/f-meloni/danger-swift-coverage", from: "1.2.1")
    ],
    targets: [
        .target(
            name: "DangerDependencies",
            dependencies: [
                .product(name: "Danger", package: "swift"),
                .product(name: "DangerSwiftCoverage", package: "danger-swift-coverage"),
                .product(name: "DangerXCodeSummary", package: "danger-swift-xcodesummary")
            ]
        )
    ]
)
