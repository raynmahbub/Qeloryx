// QELORYX — Models/Providers
// ProviderID.swift

import Foundation

/// Stable identity for a content provider. String-backed (not an enum of
/// known services) so third-party and user-defined providers can register
/// without a model change; well-known cases are provided as `static let`s.
public struct AstryxProviderID: RawRepresentable, Sendable, Hashable, Codable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public static let local: AstryxProviderID = "com.qeloryx.provider.local"
    public static let nas: AstryxProviderID = "com.qeloryx.provider.nas"
    public static let webDAV: AstryxProviderID = "com.qeloryx.provider.webdav"
    public static let cloud: AstryxProviderID = "com.qeloryx.provider.cloud"
    public static let localRecommendation: AstryxProviderID = "com.qeloryx.provider.recommendation.local"
}
