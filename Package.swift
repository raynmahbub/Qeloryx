// swift-tools-version: 5.9
// QELORYX — Package.swift
// 1.0.0 Stable — SPM for portable business logic (cross-platform preservation per spec) — All engines production

import PackageDescription

let package = Package(
    name: "Qeloryx",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "QeloryxCore", targets: ["QeloryxCore"]),
        .library(name: "QeloryxDesignSystem", targets: ["QeloryxDesignSystem"]),
        .library(name: "QeloryxPlatform", targets: ["QeloryxPlatform"])
    ],
    dependencies: [
        // No external dependencies — greenfield per Genesis Bible
    ],
    targets: [
        // MARK: - Core — All production engines — 1.0.0 Stable
        .target(
            name: "QeloryxCore",
            dependencies: [],
            path: "Core",
            sources: [
                "AstryxAudioEngine",
                "LibraryEngine",
                "SearchEngine",
                "MetadataEngine",
                "DownloadEngine",
                "TasteDNA",
                "DSP",
                "EventBus",
                "CapabilityRegistry",
                "ProviderLayer",
                "Shared"
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        
        // MARK: - DesignSystem — Midnight Aurora — Production
        .target(
            name: "QeloryxDesignSystem",
            dependencies: ["QeloryxCore"],
            path: "DesignSystem",
            sources: [
                "Theme",
                "Components",
                "Foundations",
                "Animations"
            ],
            swiftSettings: []
        ),
        
        // MARK: - Platform — iOS adapters — Production
        .target(
            name: "QeloryxPlatform",
            dependencies: ["QeloryxCore"],
            path: "Platform",
            sources: [
                "Audio",
                "Persistence",
                "Haptics",
                "System"
            ],
            swiftSettings: []
        ),
        
        // MARK: - Tests — All production — 1.0.0 Stable
        .testTarget(
            name: "QeloryxCoreTests",
            dependencies: ["QeloryxCore"],
            path: "Tests/CoreTests",
            swiftSettings: []
        ),
        .testTarget(
            name: "QeloryxDesignSystemTests",
            dependencies: ["QeloryxDesignSystem"],
            path: "Tests/DesignSystemTests",
            swiftSettings: []
        )
    ]
)
