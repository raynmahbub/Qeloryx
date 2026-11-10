// QELORYX — Models/Playback
// QueueItem.swift
/// There is deliberately **no** `isCurrent` flag: it was set once when the
/// queue was built and never updated afterwards, so after the first track change
/// it pointed at the wrong item while looking authoritative. The single source
/// of truth for the current entry is `AstryxQueue.currentIndex`.

import Foundation

public struct AstryxQueueItem: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let trackID: String
    public var order: Int
    public var addedAt: Date
    public var source: QueueSource

    public init(
        id: String = UUID().uuidString,
        trackID: String,
        order: Int,
        addedAt: Date = Date(),
        source: QueueSource = .manual
    ) {
        self.id = id
        self.trackID = trackID
        self.order = order
        self.addedAt = addedAt
        self.source = source
    }
}

public enum QueueSource: String, Sendable, Equatable {
    case manual
    case album
    case artist
    case playlist
    case search
    case favorites
    case history
    case shuffle
    case space // Astryx Spaces shared queue
}
