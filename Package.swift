// swift-tools-version: 5.9
// QELORYX — Package.swift
// SPM for portable business logic (cross-platform preservation per spec)

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
        // No external dependencies for foundation — greenfield
    ],
    targets: [
        // MARK: - Core
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
                "DSP",
                "EventBus",
                "CapabilityRegistry",
                "ProviderLayer",
                "Shared"
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        
        // MARK: - DesignSystem
        .target(
            name: "QeloryxDesignSystem",
            dependencies: ["QeloryxCore"],
            path: "DesignSystem",
            swiftSettings: []
        ),
        
        // MARK: - Platform
        .target(
            name: "QeloryxPlatform",
            dependencies: ["QeloryxCore"],
            path: "Platform",
            swiftSettings: []
        ),
        
        // MARK: - Tests
        .testTarget(
            name: "QeloryxCoreTests",
            dependencies: ["QeloryxCore"],
            path: "Tests/CoreTests"
        ),
        .testTarget(
            name: "QeloryxDesignSystemTests",
            dependencies: ["QeloryxDesignSystem"],
            path: "Tests/DesignSystemTests"
        )
    ]
)
