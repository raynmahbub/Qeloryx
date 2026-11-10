// QELORYX — Models/Library
// PlaylistEntry.swift

import Foundation

/// One row in a playlist. Stored separately from the playlist so entry lists
/// can be edited transactionally and reordered without rewriting the parent.
public struct AstryxPlaylistEntry: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let playlistID: String
    public let trackID: String
    /// Zero-based position within the playlist.
    public var position: Int
    public var addedAt: Date
    /// Set when the entry came from a smart-playlist rule evaluation rather
    /// than a manual add. Manual entries survive re-evaluation.
    public var isRuleDerived: Bool

    public init(
        id: String = UUID().uuidString,
        playlistID: String,
        trackID: String,
        position: Int,
        addedAt: Date = Date(),
        isRuleDerived: Bool = false
    ) {
        self.id = id
        self.playlistID = playlistID
        self.trackID = trackID
        self.position = position
        self.addedAt = addedAt
        self.isRuleDerived = isRuleDerived
    }
}
