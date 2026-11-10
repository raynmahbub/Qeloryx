// QELORYX — Services/Social
// SocialService.swift
//
// Social features (shared queues, live reactions, DJ handoff) plug in behind
// this seam. No social backend is configured in this build, so the default
// implementation reports unavailability and refuses actions honestly.

import Foundation

public protocol SocialServiceProtocol: Sendable {
    var isAvailable: Bool { get }
    /// Shares the currently playing track with the session's room. Throws
    /// `SocialError.unavailable` when no backend is configured.
    func shareNowPlaying(trackID: String) async throws
}

public enum SocialError: Error, LocalizedError, Sendable, Equatable {
    case unavailable

    public var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Social features are not available in this build."
        }
    }
}

/// Default implementation: nothing is configured, so actions refuse.
public final class AstryxUnavailableSocialService: SocialServiceProtocol {
    public init() {}
    public var isAvailable: Bool { false }

    public func shareNowPlaying(trackID: String) async throws {
        throw SocialError.unavailable
    }
}
