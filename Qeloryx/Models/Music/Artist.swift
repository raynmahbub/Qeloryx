// QELORYX — Models/Music
// Artist.swift

import Foundation

public struct AstryxArtist: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public var name: String
    public var albumCount: Int
    public var trackCount: Int
    public var artworkURL: URL?
    public var dateAdded: Date
    
    public init(id: String = UUID().uuidString, name: String, albumCount: Int = 0, trackCount: Int = 0, artworkURL: URL? = nil, dateAdded: Date = Date()) {
        self.id = id
        self.name = name
        self.albumCount = albumCount
        self.trackCount = trackCount
        self.artworkURL = artworkURL
        self.dateAdded = dateAdded
    }
}
