// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftManchu",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "SwiftManchuCore", targets: ["SwiftManchuCore"]),
        .executable(name: "SwiftManchu", targets: ["SwiftManchu"]),
    ],
    targets: [
        .target(
            name: "SwiftManchuCore",
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .executableTarget(
            name: "SwiftManchu",
            dependencies: ["SwiftManchuCore"],
            resources: [.copy("Resources/ManchuDict.SQLite")]
        ),
        .testTarget(
            name: "SwiftManchuCoreTests",
            dependencies: ["SwiftManchuCore"]
        ),
    ]
)
