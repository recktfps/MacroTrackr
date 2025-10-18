// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacroTrackr",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MacroTrackr",
            targets: ["MacroTrackr"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "MacroTrackr",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Kingfisher", package: "Kingfisher")
            ]),
        .testTarget(
            name: "MacroTrackrTests",
            dependencies: ["MacroTrackr"]),
    ]
)
