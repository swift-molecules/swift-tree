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
            name: "Tree Primitive",
            targets: ["Tree Primitive"]
        ),

        .library(
            name: "Tree Index",
            targets: ["Tree Index"]
        ),
        .library(
            name: "Tree Storage",
            targets: ["Tree Storage"]
        ),
        .library(
            name: "Tree Operations",
            targets: ["Tree Operations"]
        ),

        .library(
            name: "Tree",
            targets: ["Tree"]
        ),

        .library(
            name: "Tree Test Support",
            targets: ["Tree Test Support"]
        ),
    ],
    dependencies: [

        .package(
            url: "https://github.com/swift-molecules/swift-index.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-column.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-ownership-shared.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-storage-generational.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-storage.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-buffer-ring.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-queue.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-stack.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-molecules/swift-property.git",
            branch: "main"
        ),
    ],
    targets: [

        .target(
            name: "Tree Primitive"
        ),

        .target(
            name: "Tree Index",
            dependencies: [
                "Tree Primitive",
                .product(name: "Index", package: "swift-index"),
                .product(
                    name: "Storage Generational",
                    package: "swift-storage-generational"
                ),
                .product(name: "Store Primitive", package: "swift-storage"),
            ]
        ),

        .target(
            name: "Tree Storage",
            dependencies: [
                "Tree Primitive",
                "Tree Index",
                .product(name: "Index", package: "swift-index"),
                .product(name: "Column", package: "swift-column"),
                .product(
                    name: "Ownership Shared Primitive",
                    package: "swift-ownership-shared"
                ),
                .product(
                    name: "Storage Generational",
                    package: "swift-storage-generational"
                ),
                .product(name: "Store Primitive", package: "swift-storage"),
            ]
        ),

        .target(
            name: "Tree Operations",
            dependencies: [
                "Tree Primitive",
                "Tree Index",
                .product(name: "Index", package: "swift-index"),
                .product(name: "Column", package: "swift-column"),
                .product(name: "Buffer Ring Primitive", package: "swift-buffer-ring"),
                .product(name: "Queue", package: "swift-queue"),
                .product(name: "Stack", package: "swift-stack"),
                .product(
                    name: "Storage Generational",
                    package: "swift-storage-generational"
                ),
                .product(name: "Store Primitive", package: "swift-storage"),
                .product(name: "Property", package: "swift-property"),
            ]
        ),

        .target(
            name: "Tree",
            dependencies: [
                "Tree Primitive",
                "Tree Index",
                "Tree Storage",
                "Tree Operations",
            ]
        ),

        .target(
            name: "Tree Test Support",
            dependencies: [
                "Tree",
                .product(name: "Index Test Support", package: "swift-index"),
            ],
            path: "Tests/Support"
        ),

        .testTarget(
            name: "Tree Tests",
            dependencies: [
                "Tree",
                "Tree Test Support",

                .product(name: "Index", package: "swift-index"),
            ]
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
