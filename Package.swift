// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-tree",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Tree",
            targets: ["Tree"]
        ),
        .library(
            name: "Tree Standard Library Integration",
            targets: ["Tree Standard Library Integration"]
        ),
        .library(
            name: "Tree Apple Foundation Integration",
            targets: ["Tree Apple Foundation Integration"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-index.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-storage-generational.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-storage.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-queue.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-stack.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Tree",
            dependencies: [
                .product(name: "Index", package: "swift-index"),
                .product(
                    name: "Storage Generational",
                    package: "swift-storage-generational"
                ),
                .product(name: "Store Primitive", package: "swift-storage"),
                .product(name: "Queue", package: "swift-queue"),
                .product(name: "Stack", package: "swift-stack"),
            ]
        ),
        .target(
            name: "Tree Standard Library Integration",
            dependencies: ["Tree"]
        ),
        .target(
            name: "Tree Apple Foundation Integration",
            dependencies: [
                "Tree",
                "Tree Standard Library Integration",
            ]
        ),
        .testTarget(
            name: "Tree Tests",
            dependencies: ["Tree"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = [
        .enableExperimentalFeature("RawLayout")
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
