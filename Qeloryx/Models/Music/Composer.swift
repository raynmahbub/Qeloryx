// QELORYX — Models/Music
// Composer.swift

import Foundation

/// A named composer credited on one or more tracks. QELORYX credits are
/// additive: importing a file never erases an existing composer attribution.
public struct AstryxComposer: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public var name: String
    public var trackCount: Int
    public var albumCount: Int
    public var dateAdded: Date

    public init(
        id: String = UUID().uuidString,
        name: String,
        trackCount: Int = 0,
        albumCount: Int = 0,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.trackCount = trackCount
        self.albumCount = albumCount
        self.dateAdded = dateAdded
    }
}
