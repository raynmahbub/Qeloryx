// QELORYX — Models/Library
// Playlist.swift

import Foundation

public struct AstryxPlaylist: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public var name: String
    public var description: String?
    public var trackIDs: [String]
    public var artworkURL: URL?
    public var dateCreated: Date
    public var dateModified: Date
    public var isSmart: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        trackIDs: [String] = [],
        artworkURL: URL? = nil,
        dateCreated: Date = Date(),
        dateModified: Date = Date(),
        isSmart: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.trackIDs = trackIDs
        self.artworkURL = artworkURL
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.isSmart = isSmart
    }
}
