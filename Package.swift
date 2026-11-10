// swift-tools-version: 5.9
// QELORYX — Package.swift
// 1.0.0 Stable — SPM for portable business logic (cross-platform preservation per spec)
// Layout (redesigned architecture):
//   Qeloryx/Models      domain value types (tracks, queues, lyrics, …)
//   Qeloryx/Services    portable engines and services, grouped by domain
//   Qeloryx/Utilities   extensions, diagnostics, event bus, helpers
// The app target (XcodeGen) additionally compiles App/, Views/, ViewModels/,
// DesignSystem/, Platform/ and Resources/.

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
        // MARK: - Core — portable domain + engines — 1.0.0 Stable
        .target(
            name: "QeloryxCore",
            dependencies: [],
            path: "Qeloryx",
            exclude: [
                // SwiftUI environment glue — app target only, not portable core.
                "Utilities/Extensions/EnvironmentValues+Qeloryx.swift"
            ],
            sources: [
                "Models",
                "Services",
                "Utilities"
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
            path: "Qeloryx/DesignSystem",
            swiftSettings: []
        ),

        // MARK: - Platform — iOS adapters — Production
        .target(
            name: "QeloryxPlatform",
            dependencies: ["QeloryxCore"],
            path: "Qeloryx/Platform",
            swiftSettings: []
        ),

        // MARK: - Tests — All production — 1.0.0 Stable
        .testTarget(
            name: "QeloryxCoreTests",
            dependencies: ["QeloryxCore", "QeloryxDesignSystem"],
            path: "QeloryxTests",
            swiftSettings: []
        )
    ]
)
