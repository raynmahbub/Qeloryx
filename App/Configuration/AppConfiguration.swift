// QELORYX — App
// AppConfiguration.swift

import Foundation

public struct AppConfiguration: Sendable {
    public let appName: String
    public let version: String
    public let buildNumber: String
    public let environment: AppEnvironment
    public let enableLogging: Bool
    public let enableAnalytics: Bool
    
    public static let current = AppConfiguration(
        appName: "QELORYX",
        version: "0.1.0-dev",
        buildNumber: "1",
        environment: .development,
        enableLogging: true,
        enableAnalytics: false
    )
    
    public static let production = AppConfiguration(
        appName: "QELORYX",
        version: "1.0.0",
        buildNumber: "1",
        environment: .production,
        enableLogging: false,
        enableAnalytics: true
    )
}

public enum AppEnvironment: String, Sendable {
    case development
    case staging
    case production
    
    public var isDevelopment: Bool { self == .development }
    public var isProduction: Bool { self == .production }
}

// MARK: - Performance Budget

public struct PerformanceBudget {
    public static let coldLaunch: TimeInterval = 1.5
    public static let warmLaunch: TimeInterval = 0.6
    public static let search: TimeInterval = 0.05 // 50ms
    public static let libraryOpen: TimeInterval = 0.2 // 200ms
}
