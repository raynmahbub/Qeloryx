// QELORYX — App
// AppEnvironment.swift
// App configuration + the environment enum. Kept together: both describe the
// deployment context, and the app only ever reads them through this one file.

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
