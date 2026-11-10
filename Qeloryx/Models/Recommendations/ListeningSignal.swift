// QELORYX — Models/Recommendations
// ListeningSignal.swift

import Foundation

/// Where a listening signal came from. Signals from different sources are
/// weighted differently by the recommendation engine.
public enum AstryxListeningSource: String, Sendable, CaseIterable, Codable, Equatable, Hashable {
    case library
    case download
    case search
    case playlist
    case radio
    case import_ = "import"
}

/// One observed listening event. The Taste DNA engine consumes these to
/// evolve the listener's profile; they never leave the device.
public struct AstryxListeningSignal: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let trackID: String
    public let playedAt: Date
    public let durationSeconds: TimeInterval
    /// 0.0 (skipped immediately) … 1.0 (played to the end).
    public let completionRate: Double
    public let source: AstryxListeningSource
    public let wasSkipped: Bool

    public init(
        id: String = UUID().uuidString,
        trackID: String,
        playedAt: Date = Date(),
        durationSeconds: TimeInterval,
        completionRate: Double,
        source: AstryxListeningSource = .library,
        wasSkipped: Bool = false
    ) {
        self.id = id
        self.trackID = trackID
        self.playedAt = playedAt
        self.durationSeconds = durationSeconds
        self.completionRate = min(1.0, max(0.0, completionRate))
        self.source = source
        self.wasSkipped = wasSkipped
    }
}
