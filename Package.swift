// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppPoker",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "GameEngine", targets: ["GameEngine"]),
        .library(name: "BotAI", targets: ["BotAI"]),
        .library(name: "TableSession", targets: ["TableSession"]),
    ],
    targets: [
        .target(name: "GameEngine"),
        .target(name: "BotAI", dependencies: ["GameEngine"]),
        .target(name: "TableSession", dependencies: ["GameEngine", "BotAI"]),
        .testTarget(
            name: "GameEngineTests",
            dependencies: ["GameEngine", "BotAI", "TableSession"]
        ),
    ]
)
